---
title: 'DEV and IOMMU: a story of two DMA protection mechanisms'
abstract: 'Both DEV and IOMMU can help with protection against malicious DMA.
          This post roughly describes the difference between those two, as well
          as the impact they have on each other in the context of TrenchBoot'
cover: /covers/trenchboot-logo.png
author: krystian.hebel
layout: post
published: true
date: 2020-07-03
archives: "2020"

tags:
  - trenchboot
  - amd
  - apu2
  - iommu
  - security
  - open-source
categories:
  - Firmware
  - Security

---

This is another post in [TrenchBoot](https://blog.3mdeb.com/tags/trenchboot/)
series. We assume that you are more or less familiar with it, so the definitions
introduced in previous posts will not be repeated here.

## Introduction

An important part of any trust chain is to make sure that the code that is run
is the same code as was measured. This does not mean that the code must always
be read-only, it can be a self-modifying code (and usually is, mostly because
it performs some kind of relocation); it means that no external (as in: not
measured) entity can change it, at least after the measurement is done.

There are two main actors that can try to attack our TCB (Trusted Computing
Base):

* DMA (Direct Memory Access), a mechanism that allows a device to directly
  read/write system memory without CPU intervention
* SMM (System Management Mode), a privileged mode that CPU enters after
  receiving System Management Interrupt (SMI). Privileged means that this mode
  is entered unconditionally after receiving SMI and is unrestricted in its code
  execution. Moreover execution of SMM handler is transparent to the OS or other
  software, because it stops all other actions just to execute the SMM handler's
  code.

Today we will focus on the first one.

> These two can change the code in a predictable way, so they are considered
  useful for potential attackers. There are also different kinds of events that
  can change the content of RAM in random and uncontrollable manner, such as
  damaged hardware, bad power supply or spontaneous bit flips due to radiation.
  Keep the last one in mind especially if you plan to send your platform to the
  outer space :)

## DEV

DEV stands for Device Exclusion Vector. It is used by first implementations of
virtualisation technology in AMD processors, back in days when it was called
[Pacifica](https://www.mimuw.edu.pl/~vincent/lecture6/sources/amd-pacifica-specification.pdf).
In a DEV-capable systems, a northbrigde's host bridge provides a number of
protection domains (at least four in the earliest implementations), and each
domain specifies per-page (4K) access rights of devices in that domain. The
number of devices that can be assigned to a domain is limited (one global limit
for all domains), every unassigned device defaults to domain 0.

The access rights are simple: one bit in DEV controls both permission to read
and to write. A set bit (1) means that reads return all ones and writes are
dropped, a Master Abort error response will be returned in both cases. Crude,
but effective.

DEV is (mostly) no longer supported in newer CPUs, even though it is still
described in the most recent AMD [Architecture Programmer’s Manual](https://www.amd.com/system/files/TechDocs/24593.pdf),
with no indication that it is obsolete. It didn't go out with a bang, it just
slowly faded away giving way to the more all-rounded solution - the IOMMU.

## IOMMU

The I/O Memory Management Unit (IOMMU) started as a generalisation of DEV and
GART (Graphics Address Remapping Table, it was used to make scattered memory
pages look like a continuous memory range from GPU's point of view). It can
remap physical addresses between CPU and peripheral devices, control access to
those memory regions (separate read and write permissions) and remap interrupts.

> It also has additional capabilities relevant for virtualisation, which are out
  of scope for this blog post.

IOMMU is way more powerful than DEV was, but it is also proportionally more
complicated to set up - as a rough estimate, [IOMMU specification](https://developer.amd.com/wp-content/resources/48882_IOMMU_3.05_PUB.pdf)
is 278 pages long, where DEV description fits in less than 9 pages of the
Pacifica specification mentioned earlier. It also needs to be set up by the
firmware, so check your BIOS/UEFI settings.

## SKINIT

As you may know from the previous posts, SKINIT is a processor instruction that
starts DRTM by measuring initial block of code, extending PCR 17 and jumping
into that code. What may not be mentioned, but is important from security point
of view is that it also sets up some forms of hardware protection. One example
is that interrupt delivery is blocked after SKINIT, including NMIs and SMIs.
This does not solve the problem with SMM listed in the foreword, it just delays
it - we have to re-enable interrupts at some point.

Another protection, important for the topic of this post, is protection against
DMA. Both Pacifica and APM under a chapter describing DEV have a section called
`Secure Initialization Support` with identical text, starting with:

> The host bridge contains additional logic that operates in conjunction with
  the SKINIT instruction to provide a limited form of memory protection during
  the secure startup protocol. This provides protection for a Secure Loader
  image in memory, allowing it to, among other things, set up full DEV
  protection. (...)
  The host bridge logic includes a hidden (not accessible to software)
  SL_DEV_BASE address register. SL_DEV_BASE points to a 64KB-aligned 64KB region
  of physical memory. When SL_DEV_EN is 1, the 64KB region defined by
  SL_DEV_BASE is protected from external access (as if it were protected by the
  DEV).

First of all, starting from [AMD Family 15h](https://www.amd.com/system/files/TechDocs/42300_15h_Mod_10h-1Fh_BKDG.pdf)
processors full DEV protection is not implemented, only a single register for
SL_DEV_EN and a few other bits exists (search for D18F3xF4 in that document). In
Family 17h CPUs this register doesn't even exist, the SKINIT protection is
controlled by another register, not described in publicly available
documentation. What's more, this register holds both the enable bit as well as
the base address of protected region, so it *is* accessible to software.

To summarise the state we are in after SKINIT: SLB is protected by DEV-like
protection by DMA accesses, there are no interrupts, no one can touch us and we
can do whatever we like to do, as long as we are operating inside this 64KB
region. But we do not want to stay in this region forever, do we? In order to
jump into the next stage (Linux kernel in this case, but the same steps should
be done for any other piece of code we want to execute) we need to, in the exact
order:

1. protect the memory containing the code from external access (DMA), so there
   is no window for changes between steps 2 and 3 (TOCTOU)
2. measure the code and extend appropriate PCR
3. jump to the code

> Every piece of data that can impact the execution should also be measured. In
  case of LZ, kernel's *zero page*, also known as *boot_params*, is an example
  of such data. We deliberately do not measure it in LZ, as it must be done
  later, in the kernel code on Intel's TXT version of TrenchBoot - the ACM does
  not measure it, and this behaviour cannot be changed because ACM is closed
  source binary signed by Intel. This way we can minimise the amount of
  differences between these two vendors. Memory is already protected by the time
  we access any data from that page, and we use it to obtain the kernel base
  address and size (so any modifications would result in different hash of the
  kernel's code), and its entry point, which must be located inside the measured
  part and it is tested by the LZ code. It shouldn't impact the security because
  of these assertions, but feel free to prove us wrong.

As full DEV protection is not supported on newer platforms, so we have to go
with the IOMMU. The initial protection of SLB is still in place, so it should be
turned off after the memory access permissions are properly set up in the IOMMU.

### Where's the catch?

This comes down to just two sentences, one comes from the [APM](https://www.amd.com/system/files/TechDocs/24593.pdf#G21.1090402):

> When SL_DEV_EN is 1, the 64KB region defined by SL_DEV_BASE is protected from
  external access (as if it were protected by the DEV) (...).

and the second one from the [IOMMU specification](https://developer.amd.com/wp-content/resources/48882_IOMMU_3.05_PUB.pdf#G10.2641308):

> The IOMMU is implemented as an independent PCI Function.

In layman's terms, **from the DEV's point of view the IOMMU is just another**
**device that must be blocked**. IOMMU tables cannot be read from inside SLB as
long as that initial protection is enabled, because IOMMU will receive bus
master abort errors when trying to access them. This is not good...

Two relatively simple solutions come to mind:

1. put the relevant tables outside of SLB, or
2. put the tables inside the SLB and disable DEV before enabling IOMMU.

Both of these ideas leave a time window in which memory holding what will become
the IOMMU tables is not protected against DMA attacks. If during that window a
rogue device manages to overwrite the original tables with its own copy, which
allows that device to have unrestricted access to all RAM, it can basically take
control of the platform. Even if all measurements were valid we cannot be sure
that the code was not changed afterwards.

As neither option is safe, we decided to take a deeper look at another
possibility. We know that IOMMU gets the error when it tries to read the data
from SLB, so we decided to test how this impact its behaviour.

### IOMMU default state and cache

IOMMU caches the translation tables. If they are changed, the cache must be
invalidated. This is done by writing a command to the IOMMU command buffer,
which is one of IOMMU structures in memory, so it should be protected like all
other IOMMU tables. If IOMMU cannot access that command we have to assume that
the cache is not invalidated and cannot be trusted.

The test logic is simple: write some known values to memory, order legacy ISA
DMA engine to overwrite it, read back that memory and compare with initial
values. The memory range we choose is the first 32 bytes (33 actually, because
of too safe `memset` function and implicit +1 added to DMA size) of memory,
which is normally occupied by a real mode Interrupt Vector Table. This region
was chosen because it must be in the first 1MB of memory (legacy DMA does not
support higher addresses) and IVT is no longer used, so nothing bad happens if
it gets corrupted. Initial value was written with `memset(_p(1), 0xcc, 0x20)`,
and it was later overwritten (or not) with zeros by DMA, as apparently this is
the value of the idle bus. The memory after the test is dumped twice to make
sure that DMA engine had enough time to complete the transaction, even though
printing through UART probably delays execution long enough already.

The following tests were run on apu2, Fam17h does not support (or disables?)
legacy ISA DMA. They use a variation of what is described under memory to memory
DMA [here](http://www.osdever.net/tutorials/view/how-to-program-the-dma). Code
for the final test can be found [here](https://github.com/3mdeb/landing-zone/tree/test_iommu).

As a proof that **SLB DEV-like protection works** we took the fact that IOMMU is
unable to read it, it is not possible to test it with the same ISA DMA engine
because LZ is loaded into the higher than 1MB addresses. Unless otherwise
specified, the DMA trial happens between each point below, as well as before and
after the whole test. All of these tests were performed from inside LZ, so after
SKINIT instruction. As a general rule, we tried to do the simplest possible
protection, which is "deny all DMA".

##### Test 1 (pass)

Starting from cold boot, the following sequence was done:

1. enable IOMMU with tables inside SLB, the tables were set to block all DMA,
2. disable SLB protection,
3. enable IOMMU again using the same tables.

DMA was possible only before point 1. We are only concerned with DMA between
points 2 and 3, so this proves that the default IOMMU settings used when it
cannot read the proper ones are safe. This test is a pass.

##### Test 2 (pass)

The same as above, but starting with warm reboot. Results were exactly the same.

##### Test 3 (pass)

Starting either from cold boot or reboot:

1. enable IOMMU with tables inside SLB, the tables were set to **allow** DMA,
2. disable SLB protection,
3. enable IOMMU again using the same tables,
4. reboot and do SKINIT again, with different LZ image,
5. enable IOMMU with tables inside SLB, the tables were set to **block** DMA,
6. disable SLB protection,
7. enable IOMMU again using the same tables.

The critical point in this test is between points 6 and 7. DMA is allowed before
the first point and after points 3 and 4. It is blocked starting with point 5,
so this test is also a pass.

From the above we can conclude that either IOMMU always does a fallback to safe
values when it cannot access its tables or every reboot clears the cache. To
differentiate between those two we need to test it without a reboot in between
the *allow* and *block* settings.

##### Test 4 (fail)

For this test it also doesn't matter whether we start from a cold boot or not.

1. enable IOMMU with tables outside of SLB, tables set to **allow** DMA,
2. enable IOMMU with tables inside SLB, tables set to **block** DMA,
3. disable SLB protection,
4. enable IOMMU again using the same tables.

In this case DMA **is possible** between points 3 and 4. This happens because
cache is invalidated in 1, but not in 2 - the IOMMU is unable to read the
command buffer. This is a fail.

Conclusions from this test:

- this approach does not guarantee the safe initialisation of IOMMU, unless it
  can be proven that the IOMMU was not used before SKINIT
- if there is no DMA access between IOMMU allowing and prohibiting DMA, the
  first set of permissions is not cached and DMA is not possible between
  disabling DEV and invalidating IOMMU
- neither re-enabling IOMMU nor changing the address of Device Table (and other
  data structures) results in cache invalidation

### Manual cache invalidation

[BKDG for Fam16h](https://www.amd.com/system/files/TechDocs/52740_16h_Models_30h-3Fh_BKDG.pdf)
under the IOMMU's registers list D0F2xF0/xF4 and D0F2xF8/xFC, which are two
pairs of index/data registers, for L2 and L1 cache config respectively. L2
config includes software invalidation requests (search for `*SoftInvalidate`
bits), but they do not help, neither does `*Bypass` from the same registers.
Those fields can be successfully written and read back, but they have no visible
effects other than that. The same goes for L1 cache bypass (D0F2xFC_0D). It
seems as if there is no other way to invalidate this cache than through the
IOMMU commands.

## Summary

We know the problem, but unfortunately we can't do much about it. AMD has been
informed about this problem, they have acknowledged and investigated it. This
issue has its roots deep inside the SoC, so either a hardware changes or a
workaround in firmware will be needed for fully secure IOMMU initialisation
after SKINIT.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

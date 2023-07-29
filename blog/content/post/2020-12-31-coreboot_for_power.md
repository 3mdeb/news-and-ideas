---
title: coreboot port for OpenPOWER - why bother?
abstract: 'You may have heard by now that we are working on coreboot port for
          Talos II. OpenPOWER already has, nomen omen, open source firmware, so
          one may ask why bother? We will try to answer that question.'
cover: /covers/coreboot-logo.svg
author: krystian.hebel
layout: post
published: true
date: 2020-12-31
archives: "2020"

tags:
  - coreboot
  - openpower
categories:
  - Firmware

---

You may have heard that we are working on coreboot port for
[Talos II](https://raptorcs.com/TALOSII/). OpenPOWER already has, as the name
suggests, open source firmware, so one may ask why bother? In this blog post we
will try to answer that question.

> There have been rumours that
> [Raptor Computing Systems sells POWER9 hardware with coreboot](https://twitter.com/rozendantz/status/1336113596837720065/retweets/with_comments),
> however this is not true. The confusion probably comes from a fact that Raptor
> Engineering is a licensed coreboot contractor, and they did port the firmware
> for POWER platforms, but this particular firmware was a port of OpenPOWER, not
> coreboot.

## Short introduction to OpenPOWER boot process and its components

Talos II is a server platform managed by a slightly customised (mainly to handle
specific dual-CPU boot synchronisation quirks)
[OpenBMC fork](https://git.raptorcs.com/git/talos-openbmc/). BMC signals the
main (host) platform to start booting.

Next comes the
[Self-Boot Engine](https://wiki.raptorcs.com/wiki/Self-Boot_Engine). This term
is actually used both for a chip (which is part of main CPU, SBE is a reduced
PowerPC core) and its [firmware](https://git.raptorcs.com/git/talos-sbe/). The
code is stored in two redundant copies in SEEPROM - serial EEPROM located in the
CPU module, 4x64 KB for each copy. SBE's tasks are initialisation of main CPU
cores and loading and staring the next component called Hostboot.

We can separate a piece of code called Hostboot bootloader (HBBL). It is located
in SBE SEEPROM, along with secure boot root of trust hash. HBBL can be updated
only by a Hostboot (see note below), and Hostboot won't get started unless it is
positively verified by HBBL when secure boot is in use. This establishes S-CRTM
in the hardware.

> There is a jumper on the mainboard to skip the secure boot. The same jumper
> enables access to flexible service interface (FSI) from BMC, which in turn
> gives access to SEEPROM, so there is a way to recover even when the keys don't
> match, provided you have physical access to the platform.

[Hostboot](https://git.raptorcs.com/git/talos-hostboot/) is the first component
that runs on main cores. It is responsible mainly for the initialisation and
training of main memory and some of the platform buses. This repository holds
also the code for HBBL, even though the binary eventually ends up in a different
place.

[Skiboot](https://git.raptorcs.com/git/talos-skiboot/) is then chainloaded. Its
tasks include initialisation of the rest of the hardware, e.g. PCI Express host
bus controllers. It also implements OPAL
([OpenPOWER Abstraction Layer](https://open-power.github.io/skiboot/doc/opal-spec.html#what-is-opal)),
which is an interface to access firmware services from an OS. This is similar to
the UEFI runtime services or legacy BIOS interrupt calls.

Next link in this chain is [Skiroot](https://github.com/open-power/linux) (a
small set of patches on top of the mainstream Linux kernel) accompanied by
[Petitboot](https://git.raptorcs.com/git/talos-petitboot/) (userspace
application). The latter is a bootloader, it uses kexec to load the final
operating system from any device that can be mounted by Linux, including network
boot.

There are also other pieces of firmware running on different chips. Those are
responsible for thermal and power management or CAPI (coherent accelerator
processor interface) support. Most of them are loaded by the Hostboot.

A list of links to more detailed descriptions of all of the mentioned components
can be found [here](https://wiki.raptorcs.com/wiki/OpenPOWER_Firmware).

## coreboot's place in the OpenPOWER boot chain

OpenPOWER separates individual tasks required in the boot process in a slightly
different manner than coreboot. In coreboot, a great emphasis is placed on the
separation of one-time initialisation (coreboot stages) and runtime services
(payload). Skiboot mixes those two - it does the hardware initialisation usually
performed by a ramstage in coreboot, but it also installs OPAL services, which
is better suited for a payload in a coreboot's world.

With the above in mind we decided that it would be best to start with porting
just the Hostboot part, at least for the time being. Earlier stages are run by a
separate hardware, and dividing Skiboot into "hardware" and "services" parts at
this stage may introduce additional bugs. It is safer to implement one component
at a time than fail trying to do them all in one go.

### Risks

There are many moving parts in the OpenPOWER firmware. Sometimes a simple change
in the firmware for one of the peripheral devices must be accompanied by a
change in the main Hostboot repository as well as in the build tools. As in our
case coreboot takes over the responsibilities of Hostboot, it may also become
dependent on exact versions of other pieces of firmware.

Another issue is that transitions between HBBL and main Hostboot or between
Hostboot and Skiboot is not heavily standardised. There are assumptions about
sizes and locations of the components in memory, as well as the state of the
CPU.

## Benefits

We can define two classes of possible benefits: one is what coreboot and its
community can gain, the other one is what end users get from it.

### For users

**Boot time reduction** was one of the main reasons for doing this port.
Hostboot itself takes more than 1 minute to run. This is mostly spent on
accessing flash memory. It is split into multiple PNOR (Processor NOR, POWER
name for flash) partitions, summing up to just below 32 megabytes. It runs from
cache until it trains main memory, so it is limited to just 10 MB (size of L3
cache) split between two cores. To make it possible to load and execute that
amount of code,
[Hostboot uses on-demand paging](https://youtu.be/fTLsS_QZ8us?t=1559). It is
similar to swap used by operating systems, except that it uses (EEP)ROM instead
of easily writable media, so only code and constant data can be discarded from
memory (L3 cache in this case). Saving temporary variables would require
dedicated partition in PNOR and would introduce many unnecessary writes, which
both reduce the lifetime of flash and slows down the boot process. Only
persistent settings and VPD cache (which would otherwise have to be created with
each boot, producing the same results on each boot) are saved to PNOR.

With reduced boot time Talos II may as well become a board for a PC - it uses
standard peripherals and has an EATX form that fits in most PC cases. It has
decent power consumption and is really quiet. The only thing it lacks is an
integrated sound card, but most graphic cards include HDMI audio anyway. There
is also a
[project for designing a PowerPC notebook](https://www.powerpc-notebook.org/en/).
Many Linux and BSD distributions provide PPC ports, you can even choose between
big and little endian software, the hardware supports both, dynamically changed
without requiring a reboot. This may be, especially when the cost of boards will
be reduced by constantly growing demand, **a good alternative to x86
platforms**, which as of now are virtually impossible to be supported without at
least some binary, non-auditable components (FSP, AGESA, ME, PSP etc).

Another issue was nicely formulated by Timothy Pearson from Raptor CS on one of
the mails we exchanged when discussing the hows and whys:

> Hostboot is a VM to run FSI routines, and the FSI routines are written one by
> one by the hardware engineers designing the silicon itself. This leads to
> overly complex and difficult to understand code, as you can see.

FSI is one of the buses Hostboot has to initialise. By simplifying the code we
can make it **easier to understand** (no need to translate virtual addresses to
the physical ones), **faster** (by discarding a dozen of function calls before
the proper write to the register happens) and **smaller**. Smaller code means
less time spent on reading from flash, but also more space for other components,
like new drivers for Skiroot.

#### For the coreboot community

coreboot would get a **new architecture** supported. Although there are stubs,
cross-compiler and libraries for PPC, the coreboot itself isn't in working state
when it comes to this architecture as of now. It would also get a **new, truly
open**
([unless you want SATA controller](https://wiki.raptorcs.com/wiki/PM8068)),
[RYF-certified](https://www.fsf.org/news/talos-ii-mainboard-and-talos-ii-lite-mainboard-now-fsf-certified-to-respect-your-freedom)
platform. Having usable POWER9 implementation should make an easy transition to
POWER10 when it will reach customers in a year or so.

PowerPC by default uses big endian. It is configurable at runtime, but the
libraries included in coreboot-sdk are compiled for BE. This gives a perfect
opportunity to validate that **coreboot works also for big endian platforms**.
By now we confirmed that there are parts in CBFS and FMAP which need small
fixes. The endianness of fields also needs to be properly documented for those
structures, as they can be used either by a platform it is started on (coreboot
itself or tools like `cbmem`) or an application on a platform it is built on
(e.g. `cbfstool`). Those two do not have to use the same endianness.

The biggest achievement of this port would undoubtedly be bringing support for
**native DDR4 initialisation and training**. Even though the details of
accessing the hardware are platform-specific, the general process stays the
same. One caveat might be that Talos II supports only RDIMM (registered, or
buffered DIMM) and that is the only kind of memory sticks we are able to test,
however even if it won't work out of the box for different DIMM flavours, it
should give a good base to build on. Right now a big part of binary blobs used
by coreboot is responsible for memory initialisation. Having an open
implementation hopefully will bring us one step closer to **blobs-free platforms
for other architectures**.

## Current state of work

We have successfully started the first stage of coreboot (i.e. the bootblock) on
the platform:

[![asciicast](https://asciinema.org/a/JQ1MaBSzGN1L1JcbgTX3G3kt6.svg)](https://asciinema.org/a/JQ1MaBSzGN1L1JcbgTX3G3kt6?speed=1)

Actually, we were starting it much earlier than we knew it, because we used a
wrong address for serial port. Code run properly, it just didn't print anything
on the console. It was caused mostly because of improper analysis of Hostboot's
code, so we ended up converting virtual address to a physical one using a
negative offset compared to what we should have used. This is what you get from
mixing virtual memory management and manual pointer calculations 🙂️

Since then we believe we have
[mostly fixed all of the endianness issues](https://github.com/3mdeb/coreboot/tree/talos_2_support),
so `Couldn't load romstage` became `Payload not loaded`, but without any actual
initialisation code yet. After thorough tests and updates to the documentation
we will begin to upstream these changes.

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

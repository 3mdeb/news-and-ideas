---
title: "TrenchBoot: Open Source DRTM. Multiboot2 support."
abstract: This month we will show that not only Linux kernel can be started by
          TrenchBoot. We also did some drastic changes to the bootloader data
          format, so if you try to redo some older posts in the future and they
          do not seem to work, this is probably the place to look for hints.
cover: /covers/trenchboot-logo.png
author: krystian.hebel
layout: post
published: true
date: 2020-09-07
archives: "2020"

tags:
  - open-source
  - trenchboot
  - xen
categories:
  - Firmware
  - Security

---

If you haven't read previous blog posts from _TrenchBoot_ series, we strongly
encourage to catch up on it. Best way, is to search under
[TrenchBoot](https://blog.3mdeb.com/tags/trenchboot/) tag. This article roughly
describes how to start Multiboot2 kernels on the top of Landing Zone. As an
example we will securely start Xen hypervisor together with measured dom0 kernel
and initramfs, but first let's start with other changes introduced with this
release.

## Warning

This release breaks the compatibility with the previous ones (again). All blocks
of code used in the DRTM launch (that is, bootloader, LZ and kernel) built for
the previous releases will not work with another blocks built for this release,
and vice versa.

## New format of bootloader data

In order to protect ourselves from compatibility issues like the one just
mentioned, we decided to refurbish the format of the data that are passed from
the bootloader to the Landing Zone. We used a simple C structure, which is very
easy to parse, but very hard to update without breaking the existing code. The
only possible non-breaking change would be to add new fields at the end of that
structure. This also forbids the use of variable length fields, unless such
field is the last one in the structure, but this in turn means that we can't add
new fields anymore.

We decided to implement something similar to
[Multiboot2 boot information format](https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#Boot-information-format).
This gives a good compromise between ease of use, relatively low size and
ability to add new features in the future. We also don't have to pass the pieces
of information (tags) that are not relevant for the other boot protocols than
the one used for the current boot. Every tag has its size specified in its
header, so even if for some reason the bootloader passes a tag that the LZ
doesn't know, it can just skip it and parse the next one.

Other than the first and last tag, the order in which they appear isn't fixed.
This gives the bootloader more flexibility when it comes to the order in which
it obtains the information that is put into those tags. The first tag is fixed
to specify the size of the whole list of tags, and the last one is there to ease
parsing and provide additional safety check.

Whole list is measured at once and PCR18 is extended with the hashes of all the
tags, not just the ones known to the LZ.

This is an example of what the LZ tag looks like:

```bashc
struct lz_tag_hdr {
 u8 type;
 u8 len;
} __packed;

struct lz_tag_boot_mb2 {
 struct lz_tag_hdr hdr;
 u32 mbi;
 u32 kernel_entry;
 u32 kernel_size;
} __packed;
```

They can also have a variable length:

```bashc
struct lz_tag_hash {
 struct lz_tag_hdr hdr;
 u16 algo_id;
 u8 digest[];
} __packed;
```

This tag brings us to the next change introduced by this release.

## Landing Zone hashes are now calculated by a bootloader

As the layout of the bootloader data was reworked, we no longer have the
predefined place for LZ hash(es). We decided that they should be calculated by
the bootloader. That way, the bootloader can discover what algorithms are
actually supported by the TPM and pass only those hashes, reducing the amount of
memory required for data.

Event log header is still produced by the LZ. It would be bad idea to give
control over this to presumably insecure bootloader - this header holds the list
of algorithms and their lengths, which is later used for parsing the events.
Unfortunately, this means that only algorithms supported by both the TPM and the
Landing Zone can be written to the event log. It is the only way to ensure
safety of this approach - if you need another algorithm supported, please
implement it and send a pull request, user contributions are welcome!

## Multiboot2 support in LZ

The reason we decided to implement this was to show that it is not specific to
Linux boot protocol. Multiboot2 is relatively simple protocol, but at the same
time it is very powerful. It wasn't created with single OS in mind, it is rather
generic.

There are many hobbyist operating systems using Multiboot2, but what we want to
show is Xen hypervisor using Linux as dom0. That way we can easily use the tools
we used before for obtaining and printing the event log.

### Important parts of Multiboot2 specification

From the Multiboot2 specification we need mostly just two sections. The first
one is
[Machine state](https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#I386-machine-state),
which tells what the CPU registers values should be. It isn't very restrictive,
it just requires that the CPU is in flat protected mode with no paging, where
all segment registers are properly set. Just two general purpose registers have
defined values: EAX holds a magic number `0x36d76289` that specifies Multiboot2
protocol, and EBX holds the pointer to the Multiboot2 information structure.

[Multiboot2 information structure](https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#Boot-information-format)
is the second important section. It holds virtually all the data that bootloader
has to pass to the kernel in Multiboot2 protocol. This includes command line,
list of modules along with their command lines, memory map, framebuffer info,
copies of SMBIOS tables and ACPI RSDP etc. Most of this could be passed without
even parsing in the LZ, except for modules, which are measured. Other than that,
the code tries to obtain the kernel size and entry point if the bootloader
didn't pass that information. These two fields aren't specified directly in that
structure, but they can be obtained if there are ELF headers.

The rest of the specification is mostly implemented in a bootloader and of no
use in the LZ.

### Can we have older Multiboot support?

No.

While Multiboot2 has the **data** in its information structure, the older
[Multiboot information structure](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Boot-information-format)
has **pointers to data**. This would require parsing every pointer **and** every
structure that it points to, at least to know their sizes so they could be
measured.

> This is also problematic for kernels that are started with this protocol.
> Until they parse all of the structures, they cannot assume that any memory
> range is available, otherwise they risk overwriting data they will require
> later.

### Starting Xen

Because of the change to bootloader data format both bootloader and Landing Zone
must be rebuilt. We don't need to bother with rebuilding Linux kernel - Xen
starts it through the usual entry point, not the Secure Launch one. The rebuild
is needed for starting Linux directly, though. Below are the links to the
branches from which the components should be built:

- [iPXE](https://github.com/3mdeb/ipxe)
  ([build instructions](https://blog.3mdeb.com/2020/2020-06-01-ipxe_lz_support/#building-ipxe-binary))
- [GRUB2](https://github.com/3mdeb/grub/tree/lz_tags)
  ([instructions for NixOS](https://blog.3mdeb.com/2020/2020-07-03-trenchboot-grub-cbfs/#grub-package-update))
- [Landing Zone](https://github.com/3mdeb/landing-zone/tree/headers_redesign)
- [Linux kernel](https://github.com/3mdeb/linux/tree/amd_event_log)

All binaries (except for GRUB2) can be found
[here](https://boot.3mdeb.com/tb/mb2/). Initramfs with busybox, `tpm2_pcrread`
and `cbmem` modified as [described below](#obtaining-drtm-event-log) is also
available there. You can save these files on disk or run them directly from
iPXE.

#### iPXE

For the iPXE bootloader, most of the image loading commands are actually aliases
to a different command. As a result, the LZ, Linux kernel and initramfs can all
be loaded with the same command. iPXE discovers what image format it is by
comparing magic numbers specific for given image type. Order of commands _should
not_ matter, but from our experience this is not always true - memory management
in iPXE is poor, it also doesn't take into account that some of the components
are later decompressed in place.

```bash
dhcp                 # or set IP address manually
module http://url/to/lz_header.bin
kernel http://url/to/xen dom0_mem=2048M loglvl=all guest_loglvl=all com1=115200,8n1 console=com1
module http://url/to/bzImage console=hvc0 earlyprintk=xen root=/dev/ram0
module http://url/to/initramfs.cpio
boot
```

You can also
[chainload modified iPXE](https://blog.3mdeb.com/2020/2020-06-01-ipxe_lz_support/#ipxe)
from the unmodified one, using binaries from
[here](https://boot.3mdeb.com/tb/mb2/).

#### GRUB2

```bash
slaunch skinit
slaunch_module path/to/lz_header.bin
multiboot2 path/to/xen dom0_mem=2048M loglvl=all guest_loglvl=all com1=115200,8n1 console=com1
module2 path/to/bzImage console=hvc0 earlyprintk=xen root=/dev/ram0
module2 path/to/initramfs.cpio
boot
```

### Obtaining DRTM event log

Xen clears some memory ranges to provide better security. While the main
coreboot tables (in which DRTM event log is located, along with other tables)
are not cleared, the forwarding table is.

> Forwarding table is a short table containing pointer to the main table. It is
> located in either `0-0x1000` or `0xf0000-0xf1000` memory ranges. This reduces
> the time required to find it, while giving the ability to put the bigger main
> tables somewhere else.

The main tables are near the top of RAM (but below 4 GB so they can be accessed
from 32b operating systems), in the same range as the ACPI tables, just above
them. We added two switches to the `cbmem` utility to allow searching for
coreboot tables in range defined by user. Those options are:

```bash
   -a | --addr address:              set base address
   -s | --size size:                 set table size. Change is applied only if address is also specified
```

Code has been uploaded to the
[develop branch of coreboot](https://github.com/pcengines/coreboot/tree/develop),
it will be included in the following releases. To build `cbmem` run these
commands:

```bash
git clone https://github.com/pcengines/coreboot.git -b develop
cd coreboot
make -C util/cbmem
```

Resulting binary is `util/cbmem/cbmem`.

To know where to search for main coreboot tables we have to consult memory map.
There are many ways to do this, but the easiest and most universal one is
through `dmesg`. Near the beginning of kernel logs we can see something like
this:

```bash
BIOS-provided physical RAM map:
Xen: [mem 0x0000000000000000-0x000000000009efff] usable
Xen: [mem 0x000000000009fc00-0x00000000000fffff] reserved
Xen: [mem 0x0000000000100000-0x00000000cfe89fff] usable
Xen: [mem 0x00000000cfe8a000-0x00000000cfffffff] reserved
Xen: [mem 0x00000000f8000000-0x00000000fbffffff] reserved
Xen: [mem 0x00000000fec00000-0x00000000fec00fff] reserved
Xen: [mem 0x00000000fec20000-0x00000000fec20fff] reserved
Xen: [mem 0x00000000fed40000-0x00000000fed44fff] reserved
Xen: [mem 0x00000000fee00000-0x00000000feefffff] reserved
Xen: [mem 0x0000000100000000-0x000000012effffff] usable
NX (Execute Disable) protection: active
Hypervisor detected: Xen PV

(...)

ACPI: Early table checksum verification disabled
ACPI: RSDP 0x00000000000F3AF0 000024 (v02 COREv4)
ACPI: XSDT 0x00000000CFE9D0E0 000074 (v01 COREv4 COREBOOT 00000000 CORE 20180531)
ACPI: FACP 0x00000000CFE9EE40 000114 (v06 COREv4 COREBOOT 00000000 CORE 20180531)
ACPI: DSDT 0x00000000CFE9D280 001BBA (v02 COREv4 COREBOOT 00010001 INTL 20180531)
ACPI: FACS 0x00000000CFE9D240 000040
ACPI: SSDT 0x00000000CFE9EF60 0001EF (v02 COREv4 COREBOOT 0000002A CORE 20180531)
ACPI: MCFG 0x00000000CFE9F150 00003C (v01 COREv4 COREBOOT 00000000 CORE 20180531)
ACPI: TPM2 0x00000000CFE9F190 00004C (v04 COREv4 COREBOOT 00000000 CORE 20180531)
ACPI: APIC 0x00000000CFE9F1E0 00007E (v03 COREv4 COREBOOT 00000000 CORE 20180531)
ACPI: HEST 0x00000000CFE9F260 0001D0 (v01 COREv4 COREBOOT 00000000 CORE 20180531)
ACPI: SSDT 0x00000000CFE9F430 0048A6 (v02 AMD    AGESA    00000002 MSFT 04000000)
ACPI: SSDT 0x00000000CFEA3CE0 0007C8 (v01 AMD    AGESA    00000001 AMD  00000001)
ACPI: DRTM 0x00000000CFEA44B0 00007C (v01 COREv4 COREBOOT 00000000 CORE 20180531)
ACPI: HPET 0x00000000CFEA4530 000038 (v01 COREv4 COREBOOT 00000000 CORE 20180531)
```

By comparing memory map with ACPI addresses we can see that the memory reserved
for ACPI (and also coreboot tables) is in the `0xcfe8a000-0xcfffffff` range.
Knowing those values we can now try to read the DRTM event log:

```bash
/ # ./cbmem -a 0xcfe8a000 -s 0x176000 -d
DRTM TPM2 log:
        Specification: 2.00
        Platform class: PC Client
        Vendor information:
DRTM TPM2 log entry 1:
        PCR: 17
        Event type: Unknown (0x502)
        Digests:
                 SHA1: fae893a0358c95ff1f5f69a77e27ebe41cddf8f4
                 SHA256: 880f467c3d4853e71d003b1decb06bbea9ad36903f030fc02477e1b0e87d5fa7
        Event data: SKINIT
DRTM TPM2 log entry 2:
        PCR: 18
        Event type: Unknown (0x502)
        Digests:
                 SHA1: f4d014671c3187cb905e9bf62733dfb0c9aa9fcd
                 SHA256: 796ec38ea9fca434609e877e536c91b0c5e73c4c9c0d026d3402e641d71b1ee4
        Event data: Measured bootloader data into PCR18
DRTM TPM2 log entry 3:
        PCR: 18
        Event type: Unknown (0x502)
        Digests:
                 SHA1: 648df2b4c567a49f62c0b4a20b7dbecb23608818
                 SHA256: 7a7ea011293f2fedce38db88cb849c99155c048f9cde7074a68f9513f55ddf90
        Event data: Measured MBI into PCR18
DRTM TPM2 log entry 4:
        PCR: 17
        Event type: Unknown (0x502)
        Digests:
                 SHA1: 900e507c3107bf1ceaa102044207870576900046
                 SHA256: a2348bdf14f506d7e050f1268b3c84b05fe09db28c959b9b0b717c4cd6aa58f2
        Event data: Measured Kernel into PCR17
DRTM TPM2 log entry 5:
        PCR: 17
        Event type: Unknown (0x502)
        Digests:
                 SHA1: 7325ad4d3155e8b35a6b872167159acc06f03fa2
                 SHA256: 6baa1329b17010dc6cde800b0c32ed60881a846c7b83e41884018aeb5a12bcca
        Event data: http://<URL here>/bzImage console=hvc0 earlyprintk=xen root=/dev/ram0
DRTM TPM2 log entry 6:
        PCR: 17
        Event type: Unknown (0x502)
        Digests:
                 SHA1: 8b6c223ca568ca68a666a4acd65373f981ae3493
                 SHA256: 5c3ed9740225b02210b434b810ac45c92a66b5b977f5433d7f98ceac7f40ba82
        Event data: http://<URL here>/initramfs.cpio
```

> This log was for iPXE. GRUB2 handles modules slightly differently - it does
> not write module name (URL in this case), just the command line following the
> name. This does not change PCR17 values, but it changes PCR18; those names are
> part of MBI structure which is measured in entry 3.

## Summary

There are still some things that should be changed on the Xen side - one of the
things done by SKINIT instruction is that it blocks interrupts. For now, we
re-enable the interrupts in the LZ, but it really should be done by the Xen, as
it is Xen that will be handling the interrupts.

We focused mainly on the Xen hypervisor, but those changes should work for other
Multiboot2 kernels, too. In case of problems with different kernels, please let
us know in a comment below.

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. And if you want to stay up-to-date
on all things firmware security and optimization, be sure to sign up for our
newsletter:

{{< subscribe_form "3160b3cf-f539-43cf-9be7-46d481358202" "Subscribe" >}}

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
date: 2020-09-03
archives: "2020"

tags:
  - security
  - open-source
  - trenchboot
  - xen
categories:
  - Firmware
  - Security

---

If you haven't read previous blog posts from *TrenchBoot* series, we strongly
encourage to catch up on it. Best way, is to search under
[TrenchBoot](https://blog.3mdeb.com/tags/trenchboot/) tag. This article roughly
describes how to start Multiboot2 kernels on the top of Landing Zone. As an
example we will securely start Xen hypervisor together with measured dom0 kernel
and initramfs, but first let's start with other changes introduces with this
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

We decided to implement something similar to [Multiboot2 boot information format](https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#Boot-information-format).
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

```
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

```
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
one is [Machine state](https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#I386-machine-state),
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

Because of change to bootloader data format both bootloader and Landing Zone
must be rebuilt. We don't need to bother with rebuilding Linux kernel - Xen
starts it through the usual entry point, not the Secure Launch one. The rebuild
is needed for starting Linux directly, though. Below are the links to the
branches from which the components should be built:

* [iPXE](https://github.com/3mdeb/ipxe/tree/headers_redesign) ([build instructions](https://blog.3mdeb.com/2020/2020-06-01-ipxe_lz_support/#building-ipxe-binary))
* [GRUB2](https://github.com/3mdeb/grub/tree/lz_tags) ([instructions for NixOS](https://blog.3mdeb.com/2020/2020-07-03-trenchboot-grub-cbfs/#grub-package-update))
* [Landing Zone](https://github.com/3mdeb/landing-zone/tree/headers_redesign)
* Linux kernel - TBD

#### iPXE

For the iPXE bootloader, most of the image loading commands are actually aliases
to a different command. As a result, the LZ, Linux kernel and initramfs can all
be loaded with the same command. iPXE discovers what image format it is by
comparing magic numbers specific for given image type. Order of commands
*should not* matter, but from our experience this is not always true - memory
management in iPXE is poor, it also doesn't take into account that some of the
components are later decompressed in place.

```
module http://url/to/lz_header.bin
kernel http://url/to/xen dom0_mem=2048M loglvl=all guest_loglvl=all com1=115200,8n1 console=com1
module http://url/to/bzImage console=hvc0 earlyprintk=xen root=/dev/ram0
module http://url/to/initramfs.cpio
boot
```

#### GRUB2

```
slaunch skinit
slaunch_module path/to/lz_header.bin
multiboot2 path/to/xen dom0_mem=2048M loglvl=all guest_loglvl=all com1=115200,8n1 console=com1
module2 path/to/bzImage console=hvc0 earlyprintk=xen root=/dev/ram0
module2 path/to/initramfs.cpio
boot
```

### Obtaining DRTM event log

TBD

## Summary

TBD

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

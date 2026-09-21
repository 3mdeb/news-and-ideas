---
title: 'Checking DRTM of a Qualcomm laptop'
abstract: 'A case study of DRTM on ARM: Secure Core Windows PCs with
           Qualcomm-specific implementation.  How hijacking the initialization
           sequence on vendor-locked hardware unlocks its features.  And how
           standards and specifications benefit open-source projects and their
           users.'
cover: /covers/trenchboot-arm.png
author: sergii.dmytruk
layout: post
private: false
published: true
date: 2026-09-13
archives: "2026"

tags:
  - trenchboot
  - arm
  - drtm
categories:
  - Firmware
  - Security

---

This publication is a direct successor to the recent [Prospects of TrenchBoot on
ARM](/2026/2026-08-12-trenchboot-on-arm/).  While that post covered DRTM on ARM in
general, here the focus is on a vendor-specific DRTM implementation running on
devices available for purchase in retail.  The laptops in question are those
["Secured Core" PCs][secure-core] running Windows, mentioned last time.

If the DRTM abbreviation doesn't sound familiar, before continuing, take a look
at least at the introduction to [Prospects of TrenchBoot on
ARM](/2026/2026-08-12-trenchboot-on-arm/), where it's described in high-level
terms.

[secure-core]: https://learn.microsoft.com/en-us/windows/security/book/hardware-security-silicon-assisted-security#dynamic-root-of-trust-for-measurement-drtm

## "Secured Core" PCs

While most of the devices in this category are using x86 CPUs, there are a few
running on ARM.

A particular laptop model is [ThinkPad X13s Gen 1][laptop], which by now
is out of production.  The unit is rather minimalistic even as far as laptops go
and only has 2 USB-C ports, an audio jack, and a SIM slot.  It has a Snapdragon
8cx Gen 3 SoC (CPU), also known as Qualcomm SC8280XP (knowing the exact model is
important when it comes to booting Linux).

Devices of this sort tend to be designed with some goal in mind and may not
suit everyone due to the compromises a manufacturer ends up making.  However,
that doesn't matter much for examining DRTM, unless it makes interaction too
inconvenient.  And in a way it was inconvenient.  Not just due to ports, but
because it targets Windows users and isn't well supported by Linux, although
some Linux users are clearly using these devices.

[laptop]: https://psref.lenovo.com/product/ThinkPad/ThinkPad_X13s_Gen_1

## The role of DRTM on these laptops

Windows uses DRTM to lessen dependence of its security measurements on the
firmware, updates to which can otherwise invalidate the measurements.
Hardware-enforced SRTM is also present and prevents replacing firmware that
contains DRTM implementation.

DRTM launch is essentially a stage of the Windows boot process on such devices,
with BIOS participating in setting up DRTM and Windows bootloader initiating
it.  For some reason, DRTM is also a prerequisite for having hardware-assisted
virtualization on the device, which is unavailable at system boot (an unusual
situation for ARM and effectively goes against its normal boot process).

### DRTM in marketing materials

Interestingly enough, DRTM doesn't seem to be mentioned in firmware notes or any
other places but Windows' own documentation explaining "Secured Core".  And
even there one needs to look for Qualcomm being mentioned on a [page dedicated
to the requirements of System Guard][sg-requirements].

It would have been easier to find devices with DRTM if its use in connection
to specific architectures was stated more clearly.

[sg-requirements]: https://learn.microsoft.com/en-us/windows/security/hardware-security/how-hardware-based-root-of-trust-helps-protect-windows#system-requirements-for-system-guard

## How DRTM can be used with Linux

![Results of running sltest.efi](/img/arm-qualcomm-slbounce.jpg)

Despite clearly targeting Windows users, running only Microsoft-approved
operating system isn't enforced via UEFI Secure Boot as it can be disabled.
This permits users to run any EFI code and allowed [Nikita
Travkin][travmurav] to find a way of performing DRTM for Linux and,
potentially, other operating systems.

Without going into the details, [slbounce][slbounce] initiates a boot process
similar to how Windows would do it, makes it fail, and then lets an arbitrary
operating system boot with DRTM on and virtualization available.  This is
covered in greater depth at the [TrenchBoot website][tb-qualcomm-blueprint] in
the context of utilizing slbounce to initiate a DRTM of TrenchBoot-enabled
kernels (Linux and Xen).

After trying to run slbounce on its own and in combination with Linux, the
device turned out not to be a good fit for the TrenchBoot project.  Even going
an extra mile to emulate a behavior described in ARM's specification on top of
slbounce has been judged not to be sufficiently close to be worth it.  But this
hasn't been all in vain; the experiment has provided some needed knowledge of
the state of Linux on ARM and other food for thought that can be found [in the
report][tb-qualcomm-blueprint].

[travmurav]: https://github.com/TravMurav
[slbounce]: https://github.com/TravMurav/slbounce
[tb-qualcomm-blueprint]: https://trenchboot.org/blueprints/Qualcomm_DRTM/

## Linux on ARM

A kernel of any operating system needs to know what devices are available to it.
This information typically comes as a mixture of a static description and
dynamic discovery.  Dynamic discovery itself requires knowledge of what to look
for and how, which is configured statically, but may be enabled based on some
runtime information.  All this configuration knowledge partially comes during
build, when desired components are selected, and from various sources during
the boot process (e.g., kernel parameters and firmware-supplied information).

As stated above, even if support for particular hardware is compiled in,
actually discovering it can have runtime dependencies.  That's rarely limited to
a mere flag indicating a device presence; oftentimes a device driver needs to
know a set of parameters necessary to perform communication.  There are
exceptions, and some interfaces have well-established discovery protocols (like
PCIe; plug-and-play is a different subject), but that may not be enough to boot
a fully-functional system.  In some cases, where discovery is possible, it is
recommended not to be used to avoid confusing the hardware.

So there is no escape from having at least some information provided externally,
and the question is how it's done.  On x86, [Advanced Configuration and Power
Interface (ACPI)][acpi] is used for this purpose.  Firmware, being more aware
of specific hardware than a general-purpose operating system, is supposed to
construct ACPI data describing core available devices for an operating system
to consume.  A lot of this data is dynamically constructed during the boot
process from the static data embedded at build time, but to a kernel this is
essentially all dynamic.

An alternative to ACPI is a more static device tree approach and [the Devicetree
Specification][dt-spec].  That is the approach one generally has to deal with
on ARM devices.  ACPI started supporting ARM platforms in its v5.0 released back
in 2011, but still seems to be underutilized by Linux, possibly because
firmware on ARM devices doesn't always provide ACPI, as its support in Linux is
restricted to UEFI firmware.

The good thing is that Linux [recognizes advantages of ACPI on
ARM][linux-arm-acpi].  The main motivation there is decoupling software
configuration from server hardware, but advances in this regard have the
potential of affecting way more users of client platforms, like this ThinkPad
X13s laptop.  Looking at the slbounce repository, one can see device tree files
patched to support [this SoC][slbounce-dtb].  The firmware of the laptop
even mentions experimental Linux boot support, which may also mean providing
device tree.  Since Windows boots fine using ACPI, there is a suspicion that
Linux could do the same without much effort had its support of ACPI been better
on ARM devices.

[acpi]: https://uefi.org/acpi
[dt-spec]: https://www.devicetree.org/
[linux-arm-acpi]: https://docs.kernel.org/arch/arm64/arm-acpi.html
[slbounce-dtb]: https://github.com/TravMurav/slbounce/blob/main/dtbo/sc8280xp-el2.dtso

## Specifications and standards

This brings us to the discussion of the industry standards and their importance,
which may also help to appreciate why [TrenchBoot][trenchboot] itself defines
[Secure Launch Specification][sl-spec].

Whether it's [ARM's DRTM Specification][den0113], ACPI, UEFI, or something else,
the main goal and benefit is compatibility.  That is compatibility of competing
implementations (like several compilers implementing the same language),
compatibility of products by different vendors (e.g., when a generic USB device
doesn't care what it's connected to), or compatibility as a baseline interface
that can be counted on for the purposes of interoperation.

Of course, that's the theory.  In reality, compatibility doesn't always work out
as one would wish; standards may be slow to develop, put forth unreasonable
requirements, or even fail by spawning a family of incompatible extensions.
However, having some common baseline is typically better than not having one and
ending up in a situation where something gets reinvented by multiple parties
that do not interact with each other.

Also, standards don't guarantee equal treatment.  Vendors can implement an open
standard to the letter and then add a restriction that prevents anyone else
from using it.  This is an actual situation with a modern version of DRTM on AMD
laptops that belong to the same "Secured Core" family of devices.  AMD doesn't
actually restrict anyone from using their DRTM, but Microsoft does, thus
preventing projects like TrenchBoot from running on such hardware.  This is why
open standards aren't always enough; the users of those standards need to be
willing to have an open ecosystem.

[trenchboot]: https://trenchboot.org/
[sl-spec]: https://trenchboot.org/specifications/Secure_Launch/
[den0113]: https://developer.arm.com/documentation/den0113/latest/

## The next steps

The search for an ARM device that can serve as a good TrenchBoot target
continues.  Ideally, the device would fit the hardware requirements of ARM's
DRTM specification, but if that's not possible, compromises can be made to not
wait for the right hardware indefinitely.  Let's take a look at some
potential candidates.

There used to be a [development kit for Windows-on-Arm][devkit], but it's not
known whether it was sold with DRTM or allowed flashing arbitrary firmware.
Other candidates that may have DRTM include Microsoft Surface Pro X and
Microsoft Surface Pro 9, but again not much information is known about their
firmware or presence of DRTM.

There are also newer Qualcomm models like [ThinkPad T14s Gen 7
Snapdragon][x2-laptop], equipped with [Snapdragon X2][x2-cpus] SoCs.  Being a
newer version, they may actually take advantage of the recent DRTM
specification for ARM, but maybe not.  Those devices have virtualization
available without employing hacks like slbounce, so the implementation has
undergone some changes, but whether they affect DRTM much is an open question.

Taking the route of developing firmware, [Rockchip RK3588][rk3588]
([board][rk3588-board]) looks like a somewhat good fit.  It lacks a fully
open-source firmware and the capability to protect memory against DMA accesses,
but could still showcase a DRTM implementation to a large extent.  Even if it
won't check all the boxes, the next platform might and can build on the results
obtained on RK3588.  At least there is an option of tweaking firmware, which
may not be attainable on more off-the-shelf devices targeting office workers.

Looking at other devices supported by [ARM Trusted Firmware][tf-a],
[STMicroelectronics STM32MP2][st-tf-a] looks potentially interesting.  There is
[MYC-LD25X board][st-board] for it, but it needs further evaluation.

There is also open-hardware board [Radxa Orion O6][o6] ([docs][o6-docs]), built
around Cix P1 SoC (codename "sky1") that has [open firmware][sky1-tf-a] as well.
O6 relies on blobs in [for EDKII][o6-edk-blobs] and use of LPDDR5 suggests that
TF-A may also need blobs.  However, as long as they do not impose
restrictions that can get in the way of a DRTM implementation, that is fine.

Honorary mentions go to [NVIDIA DGX Spark][dgx-spark] and [NVIDIA RTX
Spark][rtx-spark].  The first may have DRTM, but there are no indications of it
in the documentation.  The second one has a relation to Windows and, similarly
to Lenovo's laptops, may have DRTM as a security requirement.  Unlikely to see
much of open-source firmware in either case, but there is a chance of a
compatible DRTM implementation nonetheless.

[devkit]: https://learn.microsoft.com/en-us/windows/arm/dev-kit/
[x2-laptop]: https://www.lenovo.com/us/en/p/laptops/thinkpad/thinkpadt/lenovo-thinkpad-t14s-gen-7-14-inch-snapdragon/22a7cto1wwus1
[x2-cpus]: https://en.wikipedia.org/wiki/List_of_Qualcomm_Snapdragon_systems_on_chips#Snapdragon_X2_series
[o6]: https://radxa.com/products/orion/o6/
[o6-docs]: https://docs.radxa.com/en/orion/o6
[o6-edk-blobs]: https://github.com/radxa/edk2-non-osi
[sky1-tf-a]: https://github.com/cixtech/cix_opensource__arm-trusted-firmware/tree/cix_p1_k6.6_2025q3_tfa_open_dev/plat/cix/sky1
[tf-a]: https://github.com/ARM-software/arm-trusted-firmware/
[rk3588]: https://rockchips.net/product/rk3588/
[rk3588-board]: https://shop.geniatech.com/product/rk3588-board/
[st-tf-a]: https://tf-a.docs.trustedfirmware.org/en/latest/plat/st/stm32mp2.html
[st-board]: https://en.myir.cn/STM32MP257/146
[dgx-spark]: https://www.nvidia.com/en-us/products/workstations/dgx-spark/
[rtx-spark]: https://www.nvidia.com/en-eu/products/rtx-spark/

### Boot Security Mastery Conference

If topics like secure boot chains, roots of trust, and owner-controlled
firmware resonate with you, join us at the [Boot Security Mastery
Conference](https://3mdeb.com/events/#_boot-security-mastery-conference).

A **five-day event on September 21-25**, 2026, in Gdańsk, Poland, combining
three days of hands-on training with two days of technical talks, research
presentations, and community networking focused on the full boot chain across
x86, ARM, POWER, and RISC-V.

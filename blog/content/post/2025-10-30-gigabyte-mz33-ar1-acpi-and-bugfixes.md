---
title: 'Gigabyte MZ33-AR1 Porting Update: ACPI and bugfixes'
abstract: 'In this blog post we will explain the effort of porting
 platform-specific ACPI code and show the extent of bugfixes
 required to run operating systems without issues on AMD Turin
 server platform, the Gigabyte MZ33-AR1.'
cover: /covers/gigabyte_mz33_ar1.webp
author:
 - michal.zygowski
layout: post
published: true    # if ready or needs local-preview, change to: true
date: 2025-10-30    # update also in the filename!
archives: "2025"

tags:
 - coreboot
 - firmware
 - AMD
 - Turin
 - MZ33-AR1
 - open-source
categories:
 - Firmware

---

## Introduction

We are slowly approaching the end of AMD Turin porting to coreboot. In the
blog post, we will show how many other patches and bugfixes were required to
properly run standard operating systems, such as Linux-based distros and
Windows, on Gigabyte MZ33-AR1.

If you haven't read the [previous blog
posts](https://blog.3mdeb.com/tags/mz33-ar1/), I encourage you to do so, to
catch up with the overall progress of porting.

## ACPI porting

Advanced Configuration and Power Interface (ACPI) is a standard that defines
an interface between the ACPI-compliant operating system and the platform
firmware. It can be used to provide an abstraction layer for registers,
controlling power management, and also providing system configuration
information to the operating system. It is nearly impossible for modern
platforms to run an operating system without ACPI and still provide complete
functionality.

Microsoft Windows is especially picky about ACPI implementation quality. If
certain information is missing in ACPI or is defined incorrectly, Windows will
quite likely display an [ACPI_BIOS_ERROR
BSOD](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/bug-check-0xa5--acpi-bios-error).
This also happened in the case of booting Windows 11 on the Gigabyte MZ33-AR1:

![Windows 11 ACPI BSOD](/img/win11_acpi_bsod.jpg)

Thankfully, the set of fixes to the ACPI implementation solved the problem,
and Windows could boot without major issues:

![Windows 11 on Gigabyte MZ33-AR with coreboot](/img/win11_mz33-ar1.jpg)

The Device Manager is also not complaining about issues with devices. There
are only a couple of them that do not have a driver yet (however, the same
situation is on the vendor BIOS).

In the very early attempts to boot Linux, we also observed ACPI errors in
dmesg (if Linux succeeded in booting, of course):

```text
ACPI: Unable to map lapic to logical cpu number
...
pcieport 0000:00:00.3: can't derive routing for PCI INT A
pcieport 0000:00:00.3: PCI INT A: not connected
pcieport 0000:40:07.1: can't derive routing for PCI INT C
xhci_hcd 0000:42:00.4: PCI INT C: no GSI
```

This was all a result of incomplete or poor ACPI implementation (lack of
interrupt routing information or incorrect LAPIC entries in the MADT ACPI
table. Now, the number of errors and warnings is reduced to just a couple of
lines:

```text
[    1.659550]   #8  #9 #10 #11 #12 #13 #14 #15
[    2.330388] ACPI: IRQ 9 override to level(!), low(!)
[    4.288025] device-mapper: core: CONFIG_IMA_DISABLE_HTABLE is disabled. Duplicate IMA measurements will not be recorded in the IMA log.
[    4.816593] workqueue: hub_event hogged CPU for >10000us 4 times, consider switching to WQ_UNBOUND
[    5.234516] bnxt_en 0000:a1:00.0 (unnamed net_device) (uninitialized): Device requests max timeout of 100 seconds, may trigger hung task watchdog
[    5.297217] bnxt_en 0000:a1:00.1 (unnamed net_device) (uninitialized): Device requests max timeout of 100 seconds, may trigger hung task watchdog
[    5.319714] workqueue: hub_event hogged CPU for >10000us 5 times, consider switching to WQ_UNBOUND
[    7.365533] sr 33:0:0:0: Power-on or device reset occurred
[    7.396592] sr 33:0:0:1: Power-on or device reset occurred
[    7.415338] sr 33:0:0:2: Power-on or device reset occurred
[    7.434553] sr 33:0:0:3: Power-on or device reset occurred
[    7.630259] sd 34:0:0:0: Power-on or device reset occurred
[    7.643151] sd 34:0:0:1: Power-on or device reset occurred
[    7.649086] sd 34:0:0:2: Power-on or device reset occurred
[    7.661722] sd 34:0:0:3: Power-on or device reset occurred
[   11.837578] nvme nvme0: using unchecked data buffer
[   11.857161] block nvme0n1: No UUID available providing old NGUID
```

Most of them are caused by the BMC Virtual CD-ROM device, which happens to
reset very often, or by the Broadcom Ethernet, which reports a max timeout of
100 seconds. It seems to be the characteristic behavior of these devices
because on the vendor BIOS, one can see identical messages in dmesg regarding
the CD-ROM resets, CPU hog warnings, and Broadcom Ethernet max timeout.

Here is a complete list of patches with ACPI fixes that allow booting Windows
and Linux without ACPI errors:

- [acpi/ivrs: Fill second EFR image value](https://review.coreboot.org/c/coreboot/+/89200)
- [soc/amd/common/block/acpi: Simplify creating the PCI dev ranges in IVHD](https://review.coreboot.org/c/coreboot/+/89201)
- [soc/amd/common/block/acpi/ivrs: Support multi-domain IOMMUs](https://review.coreboot.org/c/coreboot/+/89202)
- [soc/amd/common/block/acpi/ivrs.c: Fix IVRS generation for multiple IOMMUs](https://review.coreboot.org/c/coreboot/+/89111)
- [soc/amd/turin_poc/acpi: Describe PCI domains covered by IOMMUs](https://review.coreboot.org/c/coreboot/+/89203)
- [soc/amd/common/block/acpi/ivrs: Add SoC hook to fill IVHD 40h](https://review.coreboot.org/c/coreboot/+/89204)
- [soc/amd/turin_poc/acpi.c: Describe ACPI devices in IVRS IVHD type 40h](https://review.coreboot.org/c/coreboot/+/89205)
- [soc/amd/turin_poc/acpi: Describe MPDMA devices](https://review.coreboot.org/c/coreboot/+/89206)
- [soc/amd/turin_poc/acpi: Fill FADT fields per SoC requirements](https://review.coreboot.org/c/coreboot/+/89207)
- [soc/amd/turin_poc/acpi.c: Create SLIT ACPI table](https://review.coreboot.org/c/coreboot/+/89208)
- [mainboard/gigabyte/mz33-ar1: Set ACPI_FADT_LEGACY_DEVICES flag in FADT](https://review.coreboot.org/c/coreboot/+/89209)
- [acpi/acpi_apic.c: generate MADT LAPIC entries based on current mode](https://review.coreboot.org/c/coreboot/+/89475)
- [acpi/dsdt_top.asl: Add hook to enable routing in APIC mode](https://review.coreboot.org/c/coreboot/+/89479)
- [soc/amd/turin_poc: Add hook for IOAPIC interrupt routing](https://review.coreboot.org/c/coreboot/+/89480)
- [soc/amd/common/acpi/lpc.asl: Report fixed base addresses](https://review.coreboot.org/c/coreboot/+/89488)
- [soc/amd/common/acpi/lpc.asl: Report ESPI1 fixed resource](https://review.coreboot.org/c/coreboot/+/89489)
- [soc/amd/turin_poc: Implement PCI interrupt routing](https://review.coreboot.org/c/coreboot/+/89490)
- [soc/amd/common/acpi: Add common CXL root bridge device template](https://review.coreboot.org/c/coreboot/+/89792)
- [soc/amd/turin_poc/acpi: Describe CXL devices](https://review.coreboot.org/c/coreboot/+/89793)
- [soc/amd/turin_poc: Add CPPC support [WIP]](https://review.coreboot.org/c/coreboot/+/89794)
- [acpi/acpigen_pci_root_resource_producer.c: Report TPM MMIO in domain 0](https://review.coreboot.org/c/coreboot/+/89807)
- [acpi/acpigen_pci_root_resource_producer.c: Add VGA I/O resource to domain](https://review.coreboot.org/c/coreboot/+/89808)
- [device/pci_device.c: Fix IRQ pin assignment for multi-domain systems](https://review.coreboot.org/c/coreboot/+/89822)
- [amd/common/amd_pci_util: Extend the routing info to include bus number](https://review.coreboot.org/c/coreboot/+/89823)
- [amd/common/block/pci/acpi_prt.c: Add SoC hook to get GSI base](https://review.coreboot.org/c/coreboot/+/89824)
- [mainboard/gigabyte/mz33-ar1: Set system type to server](https://review.coreboot.org/c/coreboot/+/89825)
- [soc/amd/common/block/acpi/ivrsc.: Do not align 4-byte structures](https://review.coreboot.org/c/coreboot/+/89473)

We will not go through all of the separately. If you are curious what has been
changed and why, I encourage you to look into the links and read commit
messages. The above list of patches fulfills the requirements of the
milestone:

- Task 5. Platform-feature enablement - Milestone a. Turin-specific ACPI
 tables

As you may suspect (or not), these changes alone are not sufficient to boot
the OS reliably. The blog post is also about bugfixes, so it is time will dive
into them right now. Those bugfixes complement the ACPI changes to allow the
OSes to run. One should understand that modern server platforms are relatively
new in coreboot. Not so recently coreboot was mainly running on client devices
such as laptops, desktops and SBCs. Also it should be noted that coreboot
never offered value-added features like vendor BIOSes, nor OpenSIL is a
complete rewrite of fully-featured AGESA. OpenSIL is just a minimal rewrite of
core x86 initialization required to boot the platform. It doesn't fully support
advanced hardware features.

## Bug fixes

Every plan, even the best plan, will not predict every minor detail or issues
that can pop up unexpectedly. There are always unknown unknowns. With every
port and every experience, we're getting better. The experience is to leave
enough buffer and margin for those circumstances, like the following
milestone:

- Task 6. Validation & stabilization - Milestone a. Cross-OS boot & bugfix
 campaign

The list of patches with bugfixes is also long. We will not dive into each of
them, and as mentioned previously, I encourage you to look into the links and
read commit messages. I will explain a little bit more about the most critical
bugs.

- [amd/microcode: Add API to obtain address on microcode update block](https://review.coreboot.org/c/coreboot/+/89108)
- [vendorcode/amd/opensil/turin_poc: Pass microcode pointer to OpenSIL](https://review.coreboot.org/c/coreboot/+/89109)
- [soc/amd/common/block/pci/amd_pci_mmconf.c: Support 64bit ECAM MMCONF](https://review.coreboot.org/c/coreboot/+/89112)
- [soc/amd/common/block/cpu/noncar: Add missing TPM_LOG region in memlayout](https://review.coreboot.org/c/coreboot/+/89113)
- [security/vboot/Makefile.mk: Fix building vboot lib with OpenSIL](https://review.coreboot.org/c/coreboot/+/89114)
- [amdblocks/psp_efs: Add Genoa and Turin support](https://review.coreboot.org/c/coreboot/+/89143)
- [soc/amd/common/block/cpu/noncar: Add support for bootblock CRTM init](https://review.coreboot.org/c/coreboot/+/89145)
- [amdblock/lpc: Add SoC hook to set up SPI TPM decoding](https://review.coreboot.org/c/coreboot/+/89191)
- [soc/amd/turin_poc: Add SPI TPM SoC-specific initialization](https://review.coreboot.org/c/coreboot/+/89192)
- [amdblocks/lpc: Avoid decoding already stored resources to eSPI](https://review.coreboot.org/c/coreboot/+/89193)
- [drivers/spi/spi_flash: Add proper support for 32bit address mode](https://review.coreboot.org/c/coreboot/+/89195)
- [soc/amd/common/block/spi: Add support for 32bit address mode](https://review.coreboot.org/c/coreboot/+/89196)
- [soc/amd/turin_poc: Select SOC_AMD_COMMON_BLOCK_SPI_HAS_32B_ADDRESS_MODE](https://review.coreboot.org/c/coreboot/+/89197)
- [cpu/x86/mtrr: Simplify MTRR solution calculation on AMD systems](https://review.coreboot.org/c/coreboot/+/89199)
- [payloads/external/edk2/Makefile: Configure AP wakeup in UEFI payload](https://review.coreboot.org/c/coreboot/+/89210)
- [sb600spi: Check if SPI BAR register has valid value](https://review.coreboot.org/c/flashrom/+/89445)
- [sb600spi: Fix Promontory flash read of chips larger than 16MiB](https://review.coreboot.org/c/flashrom/+/89446)
- [soc/amd/common/block/smn: Add simple SMN I/O accessors](https://review.coreboot.org/c/coreboot/+/89471)
- [vendorcode/amd/opensil/Makefile.mk: Add 0x prefix for BIOS address](https://review.coreboot.org/c/coreboot/+/89472)
- [arch/x86/ioapic.c: Support 8-bit IOAPIC IDs](https://review.coreboot.org/c/coreboot/+/89476)
- [arch/x86.ioapic.c: Add Kconfig option to keep pre-allocated IOAPIC ID](https://review.coreboot.org/c/coreboot/+/89477)
- [soc/amd/turin_poc/Kconfig: Select IOAPIC_PREDEFINED_ID](https://review.coreboot.org/c/coreboot/+/89478)
- [payloads/external/edk2/Makefile: Set SMBIOS to 3.0.0](https://review.coreboot.org/c/coreboot/+/89481)
- [lib/dimm_info_util.c: Handle 16-bit memory bus extension for ECC](https://review.coreboot.org/c/coreboot/+/89482)
- [memory_info: Introduce new fields to memory_info structure](https://review.coreboot.org/c/coreboot/+/89483)
- [drivers/amd/opensil: Add hook to populate CBMEM_ID_MEMINFO](https://review.coreboot.org/c/coreboot/+/89484)
- [vendorcode/amd/opensil/turin_poc: Fill the memory_info data](https://review.coreboot.org/c/coreboot/+/89485)
- [coreboot_tables: Add new CBMEM ID to hold the PCI RB aperture info](https://review.coreboot.org/c/coreboot/+/89486)
- [soc/amd/turin_poc: Fill the CBMEM_ID_RB_INFO](https://review.coreboot.org/c/coreboot/+/89487)

To make things work properly with coreboot, we also needed to contribute
updates and fixes to OpenSIL:

- [xUSL/Nbio/Brh: Fix interrupt routing and swizzling](https://github.com/openSIL/openSIL/pull/30)
- [xSIM/SoC/F1AM00: Add SDXI TP1 initialization](https://github.com/openSIL/openSIL/pull/31)
- [Turin pi 1.0.0.7](https://github.com/openSIL/openSIL/pull/33)

There were two major bugfixes, that directly influenced the reliability of
booting operating systems on Gigabyte MZ33-AR1:

1. The Smart Data Accelerator Interface (SDXI) devices were exposed by default
   by the OpenSIL. They caused [a lot of
   IO_PAGE_FAULTs](https://paste.dasharo.com/?6e074e9b24551987#Hv9XumpBSLHG6mZJ8Z3kTkq5RKggQ3G5zsv314joTU3v)
   in IOMMU when running Linux with Xen hypervisor. It often resulted in a
   system hang or kernel panic. As SDXI is quite a bleeding-edge feature, it
   may not yet have good support in software or firmware. Especially that
   OpenSIL is a slightly feature-reduced reimplementation of AMD's reference
   code (AGESA). Hiding the SDXI devices in [this
   PR](https://github.com/openSIL/openSIL/pull/33) fixed the problem.
2. The CPU bringup and IOAPIC interrupt configuration was the main cause why
   we could not boot any bare metal Linux OS. For a long time, the interrupts
   arriving at the CPUs during the CPU bringup in the Linux kernel were
   causing memory corruption in the page tables mapping the CPU stack. It
   occurred that coreboot programming the southbridge IOAPIC to virtual wire
   mode was the cause of the problem. On the vendor BIOS, only the BSP local
   APIC was programmed to virtual wire mode, as the MP Specification says.
   Routing of PIC INTR through IOAPIC INT0 as a virtual wire is optional. And
   it seems that AMD systems do not like the IOAPIC being programmed in
   virtual wire mode. Thus, it was necessary to [add an option to skip virtual
   wire programming](https://review.coreboot.org/c/coreboot/+/89737) and
   [select it in the Turin SOC
   code](https://review.coreboot.org/c/coreboot/+/89738). With these fixes, we
   could finally boot bare metal Linux reliably without hangs.

These two were the most critical bugs haunting us for weeks. Thankfully we
came up with solutions to those, and now can boot Linux and Windows.

The above list of patches and pull requests fulfills the requirements of the
milestone:

- Task 6. Validation & stabilization - Milestone a. Cross-OS boot & bugfix
 campaign

## Summary

Throughout the whole process of porting a new microarchitecture, a lot of
bugfixes and changes had to be made to coreboot to support a modern server
properly. It would not be possible without AMD's OpenSIL initiative. And
also the NLnet Foundation, of course, for sponsoring the
[project](https://nlnet.nl/project/Coreboot-Phoenix/). Huge kudos to them.

![NLnet](/covers/nlnet-logo.png)

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the
hidden benefits of your hardware. And if you want to stay up-to-date on all
things firmware security and optimization, be sure to sign up for our
newsletter:

{{< subscribe_form "dbbf5ff3-976f-478e-beaf-749a280358ea" "Subscribe" >}}

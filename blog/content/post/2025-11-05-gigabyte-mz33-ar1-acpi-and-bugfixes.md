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
published: true
date: 2025-11-05
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
and Linux without ACPI errors, grouped by logical sets of changes to
subsystems:

1. IOMMU IVRS ACPI table:

    - [soc/amd/common/block/acpi/ivrs.c: Do not align 4-byte structures](https://review.coreboot.org/c/coreboot/+/89473)
    - [acpi/ivrs: Fill second EFR image value](https://review.coreboot.org/c/coreboot/+/89200)
    - [soc/amd/common/block/acpi: Simplify creating the PCI dev ranges in IVHD](https://review.coreboot.org/c/coreboot/+/89201)
    - [soc/amd/common/block/acpi/ivrs: Support multi-domain IOMMUs](https://review.coreboot.org/c/coreboot/+/89202)
    - [soc/amd/common/block/acpi/ivrs.c: Fix IVRS generation for multiple IOMMUs](https://review.coreboot.org/c/coreboot/+/89111)
    - [soc/amd/turin_poc/acpi: Describe PCI domains covered by IOMMUs](https://review.coreboot.org/c/coreboot/+/89203)
    - [soc/amd/common/block/acpi/ivrs: Add SoC hook to fill IVHD 40h](https://review.coreboot.org/c/coreboot/+/89204)
    - [soc/amd/turin_poc/acpi.c: Describe ACPI devices in IVRS IVHD type 40h](https://review.coreboot.org/c/coreboot/+/89205)
    - [soc/amd/turin_poc/acpi: Describe MPDMA devices](https://review.coreboot.org/c/coreboot/+/89206)

    The IVRS ACPI table describes the IOMMU devices in the system and how the
    IOMMUs should be configured in the system. Until now, the common code
    responsible for IVRS ACPI table generation was capable of describing a
    single domain system with a single IOMMU. However, server systems, like
    Turin, [have multiple domains and
    IOMMUs](https://review.coreboot.org/c/coreboot/+/89203). [The
    changes](https://review.coreboot.org/c/coreboot/+/89202) fix the way how
    IOMMUs are generated in the IVRS ACPI table to match the vendor BIOS IVRS
    table structure. Most importantly, IOMMU may cover more than one domain
    since Turin. It was the trickiest part to implement, requiring lots of
    SoC-specific hooks to be added to common code. Then the SoC hooks fill
    platform-specific structures in the IVRS table, like the [MPDMA
    devices](https://review.coreboot.org/c/coreboot/+/89206), or [ACPI devices
    which are not discoverable, unlike
    PCI](https://review.coreboot.org/c/coreboot/+/89205). There are also other
    [minor fixes](https://review.coreboot.org/c/coreboot/+/89473) and
    [improvements](https://review.coreboot.org/c/coreboot/+/89201), that
    simplify the IVRS generation, but also [new EFR
    fields](https://review.coreboot.org/c/coreboot/+/89200) that were added in
    the newer AMD IOMMU specification. All of these changes were needed to
    ensure the IOMMU will operate properly in the OS.

2. PCI interrupt routing:

    - [device/pci_device.c: Fix IRQ pin assignment for multi-domain systems](https://review.coreboot.org/c/coreboot/+/89822)
    - [amd/common/amd_pci_util: Extend the routing info to include bus number](https://review.coreboot.org/c/coreboot/+/89823)
    - [amd/common/block/pci/acpi_prt.c: Add SoC hook to get GSI base](https://review.coreboot.org/c/coreboot/+/89824)
    - [acpi/dsdt_top.asl: Add hook to enable routing in APIC mode](https://review.coreboot.org/c/coreboot/+/89479)
    - [soc/amd/turin_poc: Add hook for IOAPIC interrupt routing](https://review.coreboot.org/c/coreboot/+/89480)
    - [soc/amd/turin_poc: Implement PCI interrupt routing](https://review.coreboot.org/c/coreboot/+/89490)

    Another field of ACPI that required a lot of work was PCI interrupt
    routing reporting. Again, because coreboot is mostly run on client
    devices, a lot of common code pieces have assumptions about PCI topology
    being limited to a single domain. Multiple PCI domains are mainly seen on
    servers, which are relatively new to coreboot. For that reason, the PCI
    interrupt routing API was [not able to locate the parent
    bridges](https://review.coreboot.org/c/coreboot/+/89822) properly, because
    it assumed the system had only a single PCI host bridge (single domain).
    This assumption has propagated even further to [AMD common code used to
    report PCI interrupt routing
    information](https://review.coreboot.org/c/coreboot/+/89823). The data
    only recorded the PCI device and function number along with its IRQ. This
    led to all PCI devices being treated as if they belonged to the domain 0
    with the host bridge on PCI bus 0. However, on the Turin platform, there
    is a total of 8 host bridges/PCI domains per CPU socket, with each host
    bridge starting at multiple of 32 buses or 16 buses (16 PCI buses per
    domain in two socket systems). It became necessary to distinguish devices
    belonging to different PCI domains/host bridges, so the code had to take
    the PCI bus numbers into account.

    Another problem related to the multi-domain systems was the number of
    IOAPICs assigned to them. On AMD platforms, each PCI domain has a GNB
    IOAPIC (northbridge IOAPIC), so the global system interrupt number (GSI)
    for the given device had to be calculated based on the domain number the
    device belongs to. For that purpose, another [SoC-specific hook had to be
    added](https://review.coreboot.org/c/coreboot/+/89824) and then the
    correct PCI interrupt routing could be [provided by Turin SoC
    code](https://review.coreboot.org/c/coreboot/+/89490). Some of the
    interrupt routing registers in the northbridge IOAPICs were not programmed
    properly, so a Pull Request was created to fix it: [xUSL/Nbio/Brh: Fix
    interrupt routing and
    swizzling](https://github.com/openSIL/openSIL/pull/30).

    At last, to enable the interrupt routing through IOAPICs, the platform
    ACPI provides a method `_PIC`, that is evaluated by OS, when it configured
    the interrupts. If OS decides to route interrupts in APIC mode, it calls
      the `_PIC` method with argument equal to 1. The ACPI code generated by
    firmware may perform additional actions in the `_PIC` method to configure
    the system for APIC interrupt routing mode. On AMD systems, the GNB
    IOAPICs (northbridge IOAPICs) need to be programmed to [stop routing
    masked interrupts to FCH IOAPIC (southbridge
    IOAPIC)](https://review.coreboot.org/c/coreboot/+/89480), so effectively
    enabling the GNB IOAPIC operation. The `_PIC` method [needed a hook
    function](https://review.coreboot.org/c/coreboot/+/89479), so that the
    APIC interrupt routing mode could be enabled on AMD systems properly.

3. SoC-specific ACPI:

    - [soc/amd/turin_poc/acpi: Fill FADT fields per SoC requirements](https://review.coreboot.org/c/coreboot/+/89207)
    - [soc/amd/turin_poc/acpi.c: Create SLIT ACPI table](https://review.coreboot.org/c/coreboot/+/89208)
    - [mainboard/gigabyte/mz33-ar1: Set ACPI_FADT_LEGACY_DEVICES flag in FADT](https://review.coreboot.org/c/coreboot/+/89209)
    - [acpi/acpi_apic.c: generate MADT LAPIC entries based on current mode](https://review.coreboot.org/c/coreboot/+/89475)
    - [soc/amd/common/acpi: Add common CXL root bridge device template](https://review.coreboot.org/c/coreboot/+/89792)
    - [soc/amd/turin_poc/acpi: Describe CXL devices](https://review.coreboot.org/c/coreboot/+/89793)
    - [mainboard/gigabyte/mz33-ar1: Set system type to server](https://review.coreboot.org/c/coreboot/+/89825)

    AMD has a special document that describes recommended values for ACPI
    tables for the Turin system. The above changes simply realize what the
    document is saying. But also, there is a small fix for a bug, which went
    unnoticed for a long time. The code responsible for MADT table generation
    has supported x2APIC for quite some time. x2APIC is a newer mode of
    operation of APICs, which allows the APIC ID to be greater than 255, and
    the interface is based on MSRs rather than MMIO. However, coreboot did not
    properly report the x2APIC mode of the CPU LAPICs in MADT. It assumed that
    if the LAPIC ID is greater than 255, the LAPIC runs in x2APIC mode, or in
    older xAPIC mode otherwise. But this does not have to be true. x2APIC mode
    could be active even with LAPIC ID lesser than 255, so [it was necessary
    to look at the actual LAPIC mode currently
    enabled](https://review.coreboot.org/c/coreboot/+/89475), rather than
    assume the mode based on LAPIC ID.

4. ACPI resource conflicts:

    - [soc/amd/common/acpi/lpc.asl: Report fixed base addresses](https://review.coreboot.org/c/coreboot/+/89488)
    - [soc/amd/common/acpi/lpc.asl: Report ESPI1 fixed resource](https://review.coreboot.org/c/coreboot/+/89489)
    - [acpi/acpigen_pci_root_resource_producer.c: Report TPM MMIO in domain 0](https://review.coreboot.org/c/coreboot/+/89807)
    - [acpi/acpigen_pci_root_resource_producer.c: Add VGA I/O resource to domain](https://review.coreboot.org/c/coreboot/+/89808)

    One of the information conveyed by ACPI tables are the resources available
    for device use. There are two types of resources to report: resource
    producers and resource consumers. Consumers are the devices that "consume"
    given resource, i.e., they have some MMIO or IO range assigned to them to
    expose their configuration registers. Resource producers are devices that
    "produce" resources, i.e., specify resource ranges which can be consumed
    by subordinate devices. Typically, host bridges or PCI root buses play the
    role of resource producers. And every device under the given host bridge
    must consume only the resources defined by the given host bridge. Due to
    how TPMs are defined in coreboot, they usually belong to domain 0 (first
    host bridge in the system), so [TPM MMIO has to be defined in domain 0
    resource producer](https://review.coreboot.org/c/coreboot/+/89807),
    otherwise Windows will report an error, unable to find the resources for
    TPM. A similar scenario happens with VGA resources. Although coreboot
    properly handled legacy VGA MMIO range (0xA0000-0xBFFFF), the VGA I/O
    ports (0x3B0-0x3BB and 0x3C0-0x3DF) were not considered at all. Instead,
    they were always assumed to be routed to the domain 0 where the
    southbridge lives (typically, most ports from the 0x000-0xFFF range are
    decoded by the southbridge). However, PCI bridges have a control bit that
    can explicitly enable the routing of the VGA I/O ports downstream of the
    bridge, so domain 0 will not always be the consumer of those ports
    (depending on where the primary VGA device is). And as usual for coreboot,
    the simple desktop and laptop devices have all their devices on the domain
    0, because they are single-domain platforms. But servers? Obviously not,
    as we learned so far. It is possible that the VGA device will be in domain
    0, but there is also a possibility that it will not be in domain 0. So,
    what happens in that case? The VGA I/O ports reported in domain 0 are not
    claimed by a VGA device present in a different domain, e.g. domain 5.
    Windows will gratefully tell us that something is wrong with the I/O
    resources on VGA, the same way it complained about TPM resources. So the
    solution here is to split the I/O resource producers for domain 0 to
    [exclude VGA I/O if the primary VGA device is not on domain 0, then report
    the VGA I/O resource producer on the host bridge/domain, which has the VGA
    I/O port decoding enabled](https://review.coreboot.org/c/coreboot/+/89808)
    (set by coreboot during PCI enumeration).

    Another bugfix was to report the fixed resources of the LPC device
    properly. We noticed that the SPI base address register is not readable
    when the ROM Armor feature is enabled on an AMD system. This would lead to
    reporting 0xffffff00-0x100000f00 range as reserved, which could cover the
    RAM. To avoid this, the code has been changed to [report a fixed SPI base
    address](https://review.coreboot.org/c/coreboot/+/89488) programmed by
    coreboot. Modern AMD systems also have another fixed LPC resource for the
    ESPI bus, which is relative to the SPI base address. Every SPI base
    address-dependent resource would simply be misreported, so everything has
    been changed to a fixed address. Turin systems also have an ESPI1 bus
    resource, also relative to the SPI base address, so in a follow-up patch,
    [ESPI1 has been reserved as well using a hardcoded
    address](https://review.coreboot.org/c/coreboot/+/89489).

5. AMD P-state ACPI structures:

    - [soc/amd/turin_poc: Add CPPC support [WIP]](https://review.coreboot.org/c/coreboot/+/89794)

    The CPPC is an ACPI structure reporting the CPU registers and frequency
    values for controlling CPU P-states. We noticed that the amd_pstate driver
    in Linux complained about a lack of `_CPC` objects and could not load
    properly, despite the fact that CPPC was supported.  Common code in
    coreboot already had an implementation of CPPC structures creation.
    However, [it required the hooks to provide some
    frequencies](https://review.coreboot.org/c/coreboot/+/89794). Those
    frequencies could be provided only by OpenSIL, by querying SMU (System
    Management Unit). But, the SMU did not respond with any values, unless we
    have added a minimal SMU initialization with CPPC feature enabling. It was
    added in the [Pull Request updating OpenSIL to Turin PI
    1.0.0.7](https://github.com/openSIL/openSIL/pull/33). More about this Pull
    Request later.

We did not go through all of the changes separately. If you are curious what
has been changed and why, I encourage you to look into the links and read
commit messages. The above list of patches fulfills the requirements of the
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
core x86 initialization required to boot the platform. It doesn't fully
support advanced hardware features.

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

1. AMD CCX initialization:

    - [amd/microcode: Add API to obtain address on microcode update block](https://review.coreboot.org/c/coreboot/+/89108)
    - [vendorcode/amd/opensil/turin_poc: Pass microcode pointer to OpenSIL](https://review.coreboot.org/c/coreboot/+/89109)
    - [vendorcode/amd/opensil/Makefile.mk: Add 0x prefix for BIOS address](https://review.coreboot.org/c/coreboot/+/89472)

    CCX means a core complex, a unit in CPU structure gathering cores and
    threads that share L3 cache. OpenSIL performs CCX initialization, in other
    words, the CPU cores initialization. This process requires certain
    information to be passed from host firmware to OpenSIL, like: microcode
    address and the address of the reset vector/bootblock module. The former
    required a [new API to be added to locate an appropriate microcode for the
    CPU](https://review.coreboot.org/c/coreboot/+/89108), which could be later
    used to [obtain the address of the microcode and pass it to
    OpenSIL](https://review.coreboot.org/c/coreboot/+/89109). When OpenSIL
    performed CCX initialization, it used the microcode address to perform a
    microcode update on all cores.

    Secondly, the reset vector address or bootblock module address is needed
    by OpenSIL to determine where the non-BSP CPU cores will start fetching
    the code. So that OpenSIL can install its own reset vector with early CPU
    initialization. This reset vector address is dependent on the host
    firmware, i.e., where the host firmware will place its bootblock in flash
    and report it in the PSP directory. This address is configured at the
    OpenSIL build time using Kconfig. coreboot build system patches the
    OpenSIL Kconfig to provide the bootblock address used by the CCX IP
    module. However, the patching did not properly convert the address. The
    [coreboot's OpenSIL Makefile used printf without 0x prefix to convert the
    integer address to hex](https://review.coreboot.org/c/coreboot/+/89472),
    which could cause the Kconfig system and OpenSIL to interpret it as a
    decimal integer. And that could cause the OpenSIL reset vector to be set
    up at an incorrect address, leading to hangs in CCX initialization.

2. TPM measured boot:

    - [soc/amd/common/block/cpu/noncar: Add missing TPM_LOG region in memlayout](https://review.coreboot.org/c/coreboot/+/89113)
    - [security/vboot/Makefile.mk: Fix building vboot lib with OpenSIL](https://review.coreboot.org/c/coreboot/+/89114)
    - [soc/amd/common/block/cpu/noncar: Add support for bootblock CRTM init](https://review.coreboot.org/c/coreboot/+/89145)
    - [amdblock/lpc: Add SoC hook to set up SPI TPM decoding](https://review.coreboot.org/c/coreboot/+/89191)
    - [soc/amd/turin_poc: Add SPI TPM SoC-specific initialization](https://review.coreboot.org/c/coreboot/+/89192)
    - [amdblocks/lpc: Avoid decoding already stored resources to eSPI](https://review.coreboot.org/c/coreboot/+/89193)

    OpenSIL is not a fully featured rewrite of AGESA, which is why it is
    important to make the already available security features work, such as
    TPM and measured boot. There are not many AMD platforms with discrete SPI
    TPMs (maybe even none). Most AMD devices in coreboot are Chromebooks,
    which have their own TPM in a Google security chip. For that reason, the
    support of discrete SPI TPMs for AMD platforms required some work. First
    of all, the measured boot option was not buildable with OpenSIL, because
    it required crypto libraries provided by vboot. Due to [mixed absolute and
    relative include paths added to environment variables by OpenSIL and other
    Makefiles](https://review.coreboot.org/c/coreboot/+/89114), the vboot
    library failed to build. The second problem was the [missing memory area
    reserved for early TPM event
    logging](https://review.coreboot.org/c/coreboot/+/89113). For some reason,
    it was not present in the coreboot stage memory layout. Or maybe the
    measured boot was never enabled on any modern AMD platform in coreboot.
    This area stores the measurements before the TPM initialization happens in
    the ramstage (typically).

    Another result of the measured boot never being used on modern AMD
    platforms was the lack of bootblock CRTM initialization. It always ended
    up in failure, because it was mocked to return a failure (simply not
    implemented). Thus, we added a proper [implementation of CRTM
    initialization for AMD platforms that start execution from RAM
    memory](https://review.coreboot.org/c/coreboot/+/89145).

    Last but not least were the SPI TPM communication issues. The TPM
    communication was being disrupted at various stages of booting coreboot on
    Turin system:

    - before first OpenSIL call in ramstage - **NOT working**
    - after first OpenSIL call and before device init in ramstage -
      **working**
    - after TPM init during device init phase in ramstage - **NOT working**

    As we can see, there was a brief moment where the TPM was functional,
    because OpenSIL programmed some bits in silicon that made it work, and
    coreboot did not manage to break it yet... So the fix is also divided into
    two pieces. First, [bringing the Turin-specific SPI TPM configuration to
    coreboot, to make TPM work beginning with the bootblock
    stage](https://review.coreboot.org/c/coreboot/+/89192) using a freshly
    [added SPI TPM setup
    hook](https://review.coreboot.org/c/coreboot/+/89191). Second, [stop
    coreboot from breaking TPM
    communication](https://review.coreboot.org/c/coreboot/+/89193). It
    occurred that the common AMD ESPI driver tried to enable TPM MMIO decoding
    to the eSPI bus. But wait, the TPM lives on the SPI bus, so we have to
    prevent that. Otherwise, the TPM traffic will go to the wrong bus.

    With all the above changes, the measured boot with the discrete SPI TPM
    started to work properly across all coreboot stages.

3. SPI controller support:

    - [amdblocks/psp_efs: Add Genoa and Turin support](https://review.coreboot.org/c/coreboot/+/89143)
    - [drivers/spi/spi_flash: Add proper support for 32bit address mode](https://review.coreboot.org/c/coreboot/+/89195)
    - [soc/amd/common/block/spi: Add support for 32bit address mode](https://review.coreboot.org/c/coreboot/+/89196)
    - [soc/amd/turin_poc: Select SOC_AMD_COMMON_BLOCK_SPI_HAS_32B_ADDRESS_MODE](https://review.coreboot.org/c/coreboot/+/89197)

    SPI controller support is important if we wish to store any persistent
    data during firmware execution, like variables. For example, the UEFI
    payload requires UEFI variables to operate properly (although they do not
    have to be necessarily persistent). Without a proper back-end to write to
    flash in coreboot, we would not be able to implement any runtime
    configuration options. There were two problems affecting the operation of
    the SPI controller. First, there was a [lack of support for PSP EFS
    configuration for Genoa and Turin
    CPUs](https://review.coreboot.org/c/coreboot/+/89143). EFS (Embedded
    Firmware Structure) is a structure that lives under fixed addresses in
    flash. It is probed by PSP before the main CPU starts to program the SPI
    controller speeds/frequencies. Without it, the SPI speed settings could be
    incorrect or simply undesired.

    The second problem was the flash bigger than 16MB, which required a 32-bit
    addressing mode to access the whole flash. Typically, the flash is 16MB on
    x86 systems, because it is the size limit of flash that can be mapped
    under 4G. However, due to the increasing footprint of firmware code and
    the need to support multiple processor families, AMD created a concept of
    flash pages. Each flash page is 16 MB in size and can support one family
    of processors, i.e. contains a different firmware build for a different
    processor. That way a 32MB flash can have two 16MB images supporting both
    Turin and Genoa processors. Now, to handle such a big flash properly in
    coreboot, the SPI driver has to talk to SPI using 32-bit addressing mode.
    This mode usually uses different command bytes, and naturally, the number
    of bytes sent along with the command differs (24-bit addressing uses 3
    bytes for address, while 32-bit addressing uses 4 bytes for the address.
    So the [SPI driver has been updated with new commands to properly handle
    32bit addressing mode](https://review.coreboot.org/c/coreboot/+/89195).
    But the SPI driver is only assembling the data for commands to be sent via
    SPI controllers. The SPI controllers also need some configuration to treat
    those commands as 32-bit addressing mode commands. It was necessary to
    [implement additional logic in the common AMD SPI controller driver to
    support 32bit addressing
    mode](https://review.coreboot.org/c/coreboot/+/89196). Or rather, the SPI
    controller on the AMD Turin system was automatically assuming 32-bit
    addressing mode if the flash size was bigger than 16MB. The SPI driver in
    coreboot was not aware of it and sent 24-bit addressing mode commands,
    which were not interpreted properly by the SPI controller. This resulted
    in SPI reads and writes to hit the wrong addresses in flash. Finally, the
    [new option for handling 32-bit address mode could be selected by Turin
    Kconfig](https://review.coreboot.org/c/coreboot/+/89197), completing the
    set of fixes for SPI flash. With this, the SMMSTORE started to work
    properly, and the UEFI Payload UEFI variables were functional.

4. 64-bit PCIe MMCONF:

    - [soc/amd/common/block/pci/amd_pci_mmconf.c: Support 64bit ECAM MMCONF](https://review.coreboot.org/c/coreboot/+/89112)
    - [soc/amd/common/block/smn: Add simple SMN I/O accessors](https://review.coreboot.org/c/coreboot/+/89471)

    PCI Express MMCONF is a mechanism for accessing the PCI Express device
    configuration space via MMIO rather than regular 0xcf8/0xcfc I/O cycles.
    This is currently the standard way of configuring the PCI devices.
    However, on modern AMD systems, this mechanism needs a couple of quirks to
    work correctly. Initially, the base MMIO address was configured solely by
    programming a CPU MSR. But on the Turin system, there is a pair of
    registers that specify this MMIO address as well. These registers are used
    to make the SoC route those PCI configuration cycles properly across the
    data fabric. Initially, during the first phases of coreboot development
    for Gigabyte MZ33-AR1, we could not get PCIe MMCONF to work unless the
    address was set identically to the vendor BIOS. Unfortunately, this
    address was above 4GB boundary (so did not fit in 32-bit space). For that
    reason, we had to make the code [support 64-bit MMCONF
    address](https://review.coreboot.org/c/coreboot/+/89112). The final
    solution to select an arbitrary MMIO address for MMCONF was to reprogram
    the pair of registers responsible for routing the MMCONF cycles on the
    data fabric. For that purpose, we needed [the simple System Management
    Network Accessors (SMN)](https://review.coreboot.org/c/coreboot/+/89471)
    using PCI I/O ports, because MMCONF may or may not be functional. Using
    these accessors, it was possible to reprogram the MMCONF decoding register
    pair (see `df_set_pci_mmconf` in [this
    patch](https://review.coreboot.org/c/coreboot/+/88708/7)). With these
    changes, it was possible to use the MMCONF address selected by coreboot
    Kconfig without issues.

5. MTRR programming:

    - [cpu/x86/mtrr: Simplify MTRR solution calculation on AMD systems](https://review.coreboot.org/c/coreboot/+/89199)

    Programming MTRRs plays a crucial role in how the CPU sees the memory
    space. Some ranges must be uncacheable (like MMIO) and some should be
    cacheable with writeback (regular RAM). Setting different caching
    attributes in MTRRs has a huge performance impact. Imagine setting regular
    RAM as uncacheable. It dramatically slows down the CPU due to the
    CPU<->RAM bandwidth bottleneck. To speed up the firmware execution,
    coreboot sets up caching of the flash memory-mapped area, so that the code
    is fetched faster from the flash. However, this caching often causes huge
    fragmentation of the memory space, leading to increased use of MTRR
    registers. Sometimes, caching the flash is impossible because there are
    insufficient MTRRs to cover the whole address space. As a result, coreboot
    may slow down, e.g., loading a bigger payload may take a couple of
    seconds, instead of less than a second. Also, the amount of installed RAM
    plays a huge role in determining the number of needed MTRRs. Thankfully,
    the x86 silicon designers came up with a couple of improvements to the
    process of MTRR calculation. We have a default caching type and
    AMD-specific TOM2WB (Top Of Memory 2 Writeback). The former one allows
    setting a default caching type for memory ranges not covered by MTRRs, so
    that the MTRR calculation algorithm may skip those memory ranges that
    would generate bigger fragmentation of the memory space and require more
    MTRRs. The latter mechanism is AMD-specific and simplifies the assignment
    of regular RAM cacheability. When TOM2WB is enabled, the whole memory
    above 4G up to the address programmed in the TOM2 (Top Of Memory 2)
    register is automatically and unconditionally treated as writeback (WB)
    cacheable. So any MTRRm that would need to describe that range as WB can
    be omitted. When there is a huge amount of RAM installed, this mechanism
    may save a lot of MTRRs. Because of the problem of insufficient MTRRs
    appearing on Gigabyte MZ33-AR1, when coreboot attempted to set up flash
    caching, it was necessary to [add code that will take the TOM2WB into
    account and skip unnecessary
    MTRRs](https://review.coreboot.org/c/coreboot/+/89199), to make space for
    the flash caching MTRR. With this change, loading of the payload has been
    sped up drastically.

6. IOAPIC ID configuration:

    - [arch/x86/ioapic.c: Support 8-bit IOAPIC IDs](https://review.coreboot.org/c/coreboot/+/89476)
    - [arch/x86.ioapic.c: Add Kconfig option to keep pre-allocated IOAPIC ID](https://review.coreboot.org/c/coreboot/+/89477)
    - [soc/amd/turin_poc/Kconfig: Select IOAPIC_PREDEFINED_ID](https://review.coreboot.org/c/coreboot/+/89478)

    Each IOAPIC in the system must have a unique ID programmed to be
    distinguished properly and have the interrupt directed to it properly. In
    the old days, the IOAPICs had only 4-bit-wide IDs. However, modern
    systems, like AMD, support 8-bit IOAPIC IDs. So we had to [enable 8-bit
    IOAPIC IDs in coreboot](https://review.coreboot.org/c/coreboot/+/89476) to
    avoid a situation where 8-bit IOAPIC IDs programmed by OpenSIL would be
    partially overwritten by coreboot. However, only the least significant 4
    bits of the ID would be reprogrammed, leading to a situation where
    coreboot thought the IOAPIC ID is 0x4 (4 decimal), for example, but in
    reality it could be 0xF4 (244 decimal). To maintain the reference settings
    of Turin AGESA/OpenSIL, we also implemented [an option to preserve the
    IOAPIC IDs that were programmed externally by silicon initialization
    modules](https://review.coreboot.org/c/coreboot/+/89477). Then we
    [selected this option in Turin Kconfig so that the IOAPIC IDs would be in
    line between coreboot and
    OpenSIL](https://review.coreboot.org/c/coreboot/+/89478).

7. UEFI Payload build settings:

    - [payloads/external/edk2/Makefile: Configure AP wakeup in UEFI payload](https://review.coreboot.org/c/coreboot/+/89210)
    - [payloads/external/edk2/Makefile: Set SMBIOS to 3.0.0](https://review.coreboot.org/c/coreboot/+/89481)

    There were two minor issues with the UEFI payload build configuration in
    upstream coreboot. First, there was a configuration option added to
    upstream EDKII, which controlled how the APs are started up in the EDKII
    CPU driver. For some reason, the default value of that option was not
    compliant with how x86 CPUs are started. So to make EDKII UEFI Payload
    detect and start all cores properly, it was necessary to [configure the AP
    startup using standard INIT-SIPI-SIPI
    sequence](https://review.coreboot.org/c/coreboot/+/89210). The second
    problem was the mismatch of the SMBIOS tables version created by coreboot
    and exposed later by EDKII UEFI Payload. This mismatch led to OS
    utilities, like Linux dmidecode, to parse the SMBISO structures
    incorrectly. [Setting a matching SMBIOS version for EDKII UEFI payload
    fixes the problem](https://review.coreboot.org/c/coreboot/+/89481).

8. SMBIOS memory information:

    - [lib/dimm_info_util.c: Handle 16-bit memory bus extension for ECC](https://review.coreboot.org/c/coreboot/+/89482)
    - [memory_info: Introduce new fields to memory_info structure](https://review.coreboot.org/c/coreboot/+/89483)
    - [drivers/amd/opensil: Add hook to populate CBMEM_ID_MEMINFO](https://review.coreboot.org/c/coreboot/+/89484)
    - [vendorcode/amd/opensil/turin_poc: Fill the memory_info data](https://review.coreboot.org/c/coreboot/+/89485)

    Having human-readable information about RAM memory is important. SMBIOS is
    one of the sources of such information. The generic SMBIOS code in
    coreboot has support for generating the RAM memory information, but it
    requires input data from the platform code. Thankfully, OpenSIL provides
    all the necessary information coreboot needs. It just simply had to be
    [parsed properly](https://review.coreboot.org/c/coreboot/+/89485). We
    [added a hook to coreboot's OpenSIL
    driver](https://review.coreboot.org/c/coreboot/+/89484) so that any future
    mainboards and platforms with OpenSIL can implement the same mechanism.
    Turin also supports DDR5 memory, which introduces a couple of new fields
    that were not present yet in coreboot. To utilize the OpenSIL memory
    information to the maximum, we [added those missing memory information
    fields to coreboot
    structures](https://review.coreboot.org/c/coreboot/+/89483) and [fixed how
    the DDR5 ECC memory bus extension is
    treated](https://review.coreboot.org/c/coreboot/+/89482). With these
    changes, the SMBIOS memory information structures were populated
    correctly.

9. Root bridge resources:

    - [coreboot_tables: Add new CBMEM ID to hold the PCI RB aperture info](https://review.coreboot.org/c/coreboot/+/89486)
    - [soc/amd/turin_poc: Fill the CBMEM_ID_RB_INFO](https://review.coreboot.org/c/coreboot/+/89487)

    The way resources are assigned to root bridges is different on AMD than on
    Intel systems. Not all resources are discoverable by scanning all PCI
    devices under the given root bridge. EDKII PCI driver needs the PCI
    apertures to be detected properly. Usually, it is done by scanning the
    root bridges. However, it was proven insufficient for AMD server systems.
    For example, domain 0 devices may not always have devices with I/O
    resources, which may lead to a situation where I/O ports from 0x000-0xFFF
    The range will not be assigned to root bridge 0 in the EDKII PCI driver.
    As a result, the serial ports responding in that I/O range will stop
    working once the PCI driver configures root bridge attributes. To fix that
    problem, we have [implemented parsing the data fabric registers to
    calculate the PCI root bridge
    apertures](https://review.coreboot.org/c/coreboot/+/89486) and [expose
    them in new CBMEM tables](https://review.coreboot.org/c/coreboot/+/89486).
    Thankfully, the EDKII UEFI payload already supported a mechanism of
    parsing PCI root bridge aperture information from the host firmware using
    a Universal Payload hand-off block (HOB). So we [reused that HOB format in
    coreboot and simply pass it to the PCI driver in
    EDKII](https://github.com/MrChromebox/edk2/pull/35). With these changes,
    the PCI root bridge apertures were reported correctly, and all devices
    were functioning properly in the payload.

10. Flashrom support:

    - [sb600spi: Check if SPI BAR register has valid value](https://review.coreboot.org/c/flashrom/+/89445)
    - [sb600spi: Fix Promontory flash read of chips larger than 16MiB](https://review.coreboot.org/c/flashrom/+/89446)

    Flashrom is a popular open-source utility for ROM/flash programming. When
    we obtained the Gigabyte MZ33-AR1 hardware, it quickly occurred that
    flashrom is unable to read the firmware flash on the platform. The reason
    was the ROM Armor protection being enabled, which caused the SPI base
    address register to return invalid data. Flashrom did not check the
    validity of the register and tried to map an incorrect MMIO address, which
    resulted in flash probe failure. To avoid that situation in the future, we
    [added a check for the register
    value](https://review.coreboot.org/c/flashrom/+/89445) and printed an
    appropriate error message, instead of writing to a random address.

    While accessing flash with flashrom was not possible on the vendor BIOS,
    it was viable with coreboot. But flashrom programmer supporting AMD
    chipsets and SoCs were not handling flash bigger than 16MB. Sounds
    familiar? When flashrom attempted to read the SPI on a modern AMD
    platform, it used the memory mapping mechanism. However, this mechanism
    can only work for flashes up to 16MB in size, due to legacy x86 flash
    memory mapping limitations. If the flash was bigger than 16MB, flashrom
    calculated the memory-mapped range as follows: `base` = `top 4G` - `flash
    size`. For 16MB flash, the base would be `0xff000000`, which is still
    correct. However, for 32MB flash, the base would be `0xfe000000`. The
    space between `0xfe000000` and `0xff000000` is often used by different
    components in the system, e.g., HPET (`0xfed00000`), LAPICs
    (`0xfee00000`), SPI (`0xfec10000`), ACPI MMIO (`0xfed80000`), TPM
    (`0xfed40000`) and many others. It is basically a space reserved for
    things other than flash. Obviously, flashrom did not account for it and
    blindly mapped the hole `0xfe000000-0xffffffff` range , thinking it was
    flash, and attempted to read it, which resulted in bus errors in Linux.
    The solution was to [not use the memory mapping mechanism for flashes
    bigger than 16MB and use the old way using the SPI read command via SPI
    controller](https://review.coreboot.org/c/flashrom/+/89446) (a bit slower,
    but always works). With these changes, we were able to read and write the
    coreboot builds using flashrom on the Gigabyte MZ33-AR1.

11. Updating OpenSIL to Turin PI 1.0.0.7:

    - [Turin pi 1.0.0.7](https://github.com/openSIL/openSIL/pull/33)

    According to [one of the comments on OpenSIL
    GitHub](https://github.com/openSIL/openSIL/pull/30#issuecomment-3324883466),
    the Turin OpenSIL was developed based on the pre-production version of the
    Turin PI package 0.0.8.0. It means that the code lacked the most recent
    bugfixes and improvements from AMD in silicon initialization. We attempted
    to reduce the difference between the OpenSIL and the newest available
    Turin PI at the time of development (i.e., Turin PI 1.0.0.7). There were
    lots of default values set differently on the production version. We also
    found some missing register programming. The overall effect of this
    operation is not easily measurable, because the changes touch multiple IP
    blocks. However, certain changes added in that Pull Request solved one of
    the critical issues with SDXI devices (see below). We also added the SMU
    initialization required for the CPPC feature mentioned earlier. It is also
    important to note that the changes include recent security fixes for
    various vulnerabilities reported since the release of the Turin CPU.

12. Smart Data Accelerator Interface (SDXI):

    The [Smart Data Accelerator Interface](https://www.snia.org/sdxi) devices
    were exposed by default by the OpenSIL. They caused [a lot of
    IO_PAGE_FAULTs](https://paste.dasharo.com/?6e074e9b24551987#Hv9XumpBSLHG6mZJ8Z3kTkq5RKggQ3G5zsv314joTU3v)
    in IOMMU when running Linux with Xen hypervisor. It often resulted in a
    system hang or kernel panic. As SDXI is a bleeding-edge feature, it may
    not yet have good support in software or firmware. Especially that OpenSIL
    is a slightly feature-reduced reimplementation of AMD's reference code
    (AGESA). Initially, we thought that [missing SDXI
    initialization](https://github.com/openSIL/openSIL/pull/31) is the cause
    of problems Hiding the SDXI devices in [this
    PR](https://github.com/openSIL/openSIL/pull/33) fixed the problem.

13. CPU bringup issue:

    - [arch/x86/ioapic.c: Add option to skip virtual wire mode programming](https://review.coreboot.org/c/coreboot/+/89737)
    - [soc/amd/turin_poc/Kconfig: Skip IOAPIC virtual wire mode programming](https://review.coreboot.org/c/coreboot/+/89738)

    The FCH IOAPIC (southbridge IOAPIC) configuration was the main cause why
    we could not boot any bare metal Linux OS. For a long time, the interrupts
    arriving at the CPUs during the CPU bringup in the Linux kernel were
    causing memory corruption in the page tables mapping the CPU stack. It
    occurred that coreboot programming the southbridge IOAPIC to virtual wire
    mode was the cause of the problem. On the vendor BIOS, only the BSP local
    APIC was programmed to virtual wire mode, as the MP Specification says.
    Routing of PIC INTR through IOAPIC INT0 as a virtual wire is optional. And
    it seems that AMD systems do not like the IOAPIC being programmed in
    virtual wire mode. Thus, it was necessary to [add an option to skip
    virtual wire programming](https://review.coreboot.org/c/coreboot/+/89737)
    and [select it in the Turin SOC
    code](https://review.coreboot.org/c/coreboot/+/89738). With these fixes,
    we could finally boot bare metal Linux reliably without hangs.

The last two issues (SDXI and CPU bringup) were the most critical bugs
haunting us for weeks. Thankfully we came up with solutions to those, and now
can boot Linux and Windows.

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

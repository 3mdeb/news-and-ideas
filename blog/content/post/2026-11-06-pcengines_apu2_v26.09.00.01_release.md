---
title: 'Dasharo (coreboot+SeaBIOS) for PC Engines apu2 Release v26.09.00.01'
abstract: 'The new Dasharo (coreboot+SeaBIOS) release v26.09.00.01 for PC
          Engines apu2 is here. It is rebased on coreboot 26.09 and brings
          measured boot, SBOM generation for all firmware components and
          unique SMBIOS System UUIDs. The release also reworks IOMMU support
          and fixes Linux freezes, CC6 memory reservation and ECC
          configuration issues.'
cover: /img/apu3_overall.jpg
author: michal.zygowski
layout: post
private: false
published: true
date: 2026-11-06
archives: "2026"

tags:
  - dasharo
  - coreboot
  - seabios
  - apu
  - pcengines
  - amd
categories:
  - Firmware
  - Security

---

## Introduction

We are happy to announce the release of Dasharo (coreboot+SeaBIOS) v26.09.00.01
for PC Engines apu2 and its siblings. The full changelog is available in the
[Dasharo documentation](https://docs.dasharo.com/variants/pc_engines/releases_seabios/).

Although the apu2 platform has been on the market for over a decade, it is
still widely used in networking appliances, routers and firewalls. This
release keeps the firmware up to date with upstream coreboot, adds security
features like measured boot and SBOM, and fixes several long-standing issues
related to IOMMU and memory configuration. Let's walk through what's new.

## Added

### Rebased on coreboot 26.09

The firmware has been rebased onto the official coreboot repository commit
`8b0e34f`, tagged as 26.09. This brings all the upstream improvements and
fixes that landed since the previous release. See the [coreboot 26.09 release
notes](https://doc.coreboot.org/releases/coreboot-26.09-relnotes.html) for
details.

### Measured Boot

Measured boot is now enabled. Firmware components are measured into the TPM
PCRs and recorded in the TPM event log, provided a TPM module is attached to
the board. This lets the operating system or a remote verifier check what
firmware actually executed on the platform. Both SHA-1 and SHA-256 PCR banks
are extended. Below is an abbreviated TPM event log from an apu4 with an
Infineon SLB9665 TPM 2.0 module, as reported by `cbmem -L`. coreboot measures
its stages and blobs into PCR 2 and ACPI tables into PCR 1. Then SeaBIOS
continues the chain with its configuration files and the boot process:

```text
TPM2 log entry 1:   PCR 2  FMAP: FMAP
TPM2 log entry 2:   PCR 2  CBFS: bootblock
TPM2 log entry 3:   PCR 2  CBFS: fallback/romstage
TPM2 log entry 4:   PCR 2  CBFS: AGESA
...
TPM2 log entry 8:   PCR 2  CBFS: spd.bin
TPM2 log entry 9:   PCR 2  CBFS: fallback/postcar
TPM2 log entry 10:  PCR 2  CBFS: fallback/ramstage
...
TPM2 log entry 13:  PCR 2  CBFS: fallback/dsdt.aml
TPM2 log entry 14:  PCR 2  CBFS: fallback/payload
TPM2 log entry 16:  PCR 1  ACPI: RSDP
TPM2 log entry 17:  PCR 1  ACPI: RSDT COREBOOT
...
TPM2 log entry 30:  PCR 1  ACPI: HPET COREBOOT
TPM2 log entry 31:  PCR 2  Start Option ROM Scan
TPM2 log entry 32:  PCR 2  CBFS: etc/sercon-port
...
TPM2 log entry 36:  PCR 4  Calling INT 19h
...
TPM2 log entry 45:  PCR 4  Booting BCV device 80h (HDD)
TPM2 log entry 46:  PCR 4  MBR
TPM2 log entry 47:  PCR 5  MBR PARTITION_TABLE
```

The same log is exposed to the operating system and can be parsed with
`tpm2-tools`:

```bash
sudo tpm2_eventlog /sys/kernel/security/tpm0/binary_bios_measurements
```

### SBOM Generation for All Firmware Components

A Software Bill of Materials (SBOM) is now generated for all firmware
components: coreboot, SeaBIOS, sortbootorder, iPXE and others. It makes it
easier to track what exactly is inside the firmware image and verify the
provenance of each component.

We are also making progress with the SBOM and provenance of the firmware
components, as measured and reported in the TPM event log. A new report that
validates the origin, reproducibility and hashes of the firmware components
is now part of the release artifacts. You can find these reports on the
[release page](https://docs.dasharo.com/variants/pc_engines/releases_seabios/).

![Measured boot provenance report for v26.09.00.01](/img/apu_provenance.png)

The report above was generated for v26.09.00.01 on an apu4. The event log is
complete, the firmware PCRs replay correctly from the log, all executable
content is measured, the image is traceable to source and an independent
rebuild reproduces it bit for bit.

The lower root of trust score is expected - apu2 has no hardware root of trust
like Intel Boot Guard, so the measurements start from the coreboot bootblock
itself, which is a software root of trust.

### IOMMU Device in ACPI with Interrupt Routing Information

The IOMMU device was missing in ACPI, along with its interrupt routing
information. It is now properly described, so the operating system can
correctly route the IOMMU interrupts.

### Unique SMBIOS System UUID

The SMBIOS System UUID is now generated from the NIC MAC address, making it
unique for each board and stable across reboots and firmware updates. This is
useful for provisioning and management tools that identify machines by their
UUID. SeaBIOS prints it on boot:

```text
SeaBIOS (version rel-1.16.3.2-0-g1140b280)
Machine UUID 45204350-676e-6e69-6573-000db955c641
```

and it is also visible in the SMBIOS tables:

```bash
$ sudo dmidecode -t 1
System Information
        Manufacturer: PC Engines
        Product Name: apu4
        Version: 1.0
        Serial Number: 1405264
        UUID: 45204350-676e-6e69-6573-000db955c641
```

The last 6 bytes of the UUID (`000db955c641`) are the MAC address of the first
NIC, which makes the UUID unique for each board.

## Changed

### sortbootorder and SeaBIOS Updates

- sortbootorder has been updated to
  [v26.09.00.01](https://github.com/pcengines/sortbootorder/compare/v24.08.00.01...v26.09.00.01).
- SeaBIOS has been updated to
  [rel-1.16.3.2](https://github.com/pcengines/seabios/compare/rel-1.16.3.1...rel-1.16.3.2).

### Builds Are No Longer TIMELESS

Previously, the firmware was built with the `TIMELESS` option to keep the
builds reproducible, at the cost of not having meaningful build timestamps in
the image. The builds no longer use `TIMELESS`, while reproducibility is
preserved thanks to the updated code preparation and git patch application
process. See the [dasharo-pq
documentation](https://github.com/dasharo/dasharo-pq#prepare-code-base) for
details.

### Reworked IOMMU IVRS Table Generation

The IOMMU I/O Virtualization Reporting Structure (IVRS) ACPI table generation
has been reworked to cover the whole PCI root bridge. Combined with the IOMMU
fixes described below, this should improve the experience with PCI
passthrough and virtualization on apu2.

### Larger cbmem Console

The cbmem console size has been increased to 1MB, so that it can fit the debug
logs from SeaBIOS as well. This makes debugging boot issues easier, as the
whole [log can be retrieved with the `cbmem` utility from the operating
system](https://docs.dasharo.com/common-coreboot-docs/dumping_logs/). The new
console size is visible in the CBMEM table of contents:

```bash
$ sudo cbmem -l
CBMEM table of contents:
    NAME                  ID        START     LENGTH
 0. CONSOLE               434f4e53  7eefe000  00100000
...
$ sudo cbmem -c
```

## Fixed

### Linux Freezes Caused by IOMMU Guest APIC

The IOMMU guest virtual APIC feature was enabled, even though the hardware
does not support guest AVIC. This caused Linux to freeze. The feature is now
no longer enabled on the apu2.

### Switching to IOAPIC Mode Moved to ACPI `_PIC` Method

Switching the GNB (Graphics North Bridge) IOAPIC to IOAPIC mode has been moved
to the ACPI `_PIC` method. This way, the interrupt mode is switched only when
the operating system declares it uses the APIC interrupt model, instead of
being forced by the firmware.

### CC6 Save State Area Not Reserved

The memory used by the CPU to save the core state when entering the CC6
(core C6) power state was not reserved in the memory map. The operating
system could use that memory, which could lead to memory corruption when the
cores entered the deep sleep state. The region is now properly reserved.

### Incorrect Reserved Bits Cleared in the ECC Register

The firmware cleared incorrect reserved bits when configuring the ECC
register. This has been fixed, so the ECC configuration no longer touches
bits it should not.

## Summary

This release keeps the PC Engines apu2 firmware current with upstream coreboot
and brings it closer to the security standards of the other Dasharo
platforms, with measured boot, SBOM and provenance reports. The IOMMU rework
and fixes should make the platform more stable for virtualization use cases.

We encourage everyone to update, test, and share your experiences through
[GitHub issues](https://github.com/Dasharo/dasharo-issues/issues/).

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the
hidden benefits of your hardware. And if you want to stay up-to-date on all
things firmware security and optimization, be sure to sign up for our
newsletter:

{{< subscribe_form "dbbf5ff3-976f-478e-beaf-749a280358ea"
    "Subscribe to Dasharo Newsletter" >}}

---
title: 'Gigabyte MZ33-AR1 Dasharo v0.9.0 Released'
abstract: 'Dasharo v0.9.0 for the Gigabyte MZ33-AR1 server board is now
           available, bringing initial open-source firmware support based on
           coreboot 25.12 and AMD openSIL for the Turin processor family.
           This post covers the features included in the release, the known
           issues, testing environment improvements for AMD platforms, and a
           commentary on the platform openness score.'
cover: /covers/gigabyte_mz33_ar1.webp
author: michal.zygowski
layout: post
private: false
published: true
date: 2026-05-15
archives: "2026"

tags:
  - coreboot
  - firmware
  - AMD
  - Turin
  - MZ33-AR1
  - Dasharo
  - open-source
categories:
  - Firmware

---

## Introduction

Dasharo v0.9.0 for the Gigabyte MZ33-AR1 server board was released on May 14,
2026. This marks the culmination of many months of porting work that started
with the very first coreboot bring-up in [Part
1](https://blog.3mdeb.com/2025/2025-08-07-gigabyte_mz33_ar1_part1/) and
progressed through hardware topology discovery, I/O bus configuration, ACPI
porting, upstream contributions, and extensive testing. If you have not been
following the series, all previous posts are tagged
[mz33-ar1](https://blog.3mdeb.com/tags/mz33-ar1/).

The build is based on coreboot 25.12 (revision `b7796125`), EDK II
`edk2-stable202502` (revision `eedcdea6`), iPXE 2026.02 (revision `ad8cbcee`),
and AMD openSIL (revision `df18968a` of the `turin_poc` branch released on
11th April 2025).

## Features in v0.9.0

The release delivers initial Dasharo firmware support for the Gigabyte MZ33-AR1
based on AMD Turin. The feature set is rich and includes:

- **Rebased coreboot repository to 25.12** upstream tag
- **UEFI compatible boot interface** with standard boot order and boot options
  configurability
- **UEFI Secure Boot support**
- Tested **Ubuntu 25.10** and **Windows 11**
- **TPM support with TPM Measured Boot**
- **SMM BIOS write protection with AMD ROM Armor**
- **Setup menu password configuration** to protect unauthorized access to
  firmware setup
- **USB stack and network disable options** in setup menu
- **TPM PPI support** with UEFI variable backend, for platforms that do not
  retain RAM contents after reset
- **Integrated SBOM** in the binary with **extended SBOM information for AMD
  PSP blobs**
- **AMD SME and AMD SEV-SNP support**
- **UEFI Capsule Updarte v1 support with Capsule on Disk** <br>(Note that this
  version of UEFI Capsule Update does not enforce signature verification. See
  [DSB
  002](https://github.com/3mdeb/3mdeb-secpack/blob/master/DSBs/dsb-002-2026.txt)
  for more details.)
- **Rebased iPXE** on last commit of **February 2026**
- **Customizable the SMBIOS Serial Number and UUID**
- **Support for firmware flashing via BMC with RBU files**
- **TCG OPAL and SATA disk password support**
- **Boot manager menu disable option**
- **Early graphical sign of life**
- **Quiet boot/Fast boot options**
- **AMD memory context save/restore support** to speed up subsequent boots
- **SMBIOS 3.8.0 specification support**
- **AMD PSP HSTI reporting** to reach **fwupd HSI2 level** and **fulfill
  HSI4** requirements
- **AMD CPU temperature reporting via ACPI Thermal Zone**

And more...

## Known issues in v0.9.0

The v0.9.0 release documents four known limitations:

1. **UEFI Capsules do not survive resets.** Only immediate Capsule on Disk
   (CoD) updates are supported; a warm reset during a staged capsule update
   will not complete the update. This is a limitation of the modern AMD
   platforms where staged capsule are lost in RAM after reset, likely due to
   memory encryption or PSP memory initialization.

2. **Previous power state restoration does not work for the powered-off
   state.** The ATX power state restore (S5 -> power-on when AC is restored)
   is not functional. Systems that require keeping previous state after a
   power outage cannot rely on this feature in v0.9.0. Only the "always on" or
   "always off" options work reliably.

3. **I3C controller initialization fails in Linux.** The AMD Turin SoC
   includes an I3C (Improved Inter-Integrated Circuit) bus controller, which
   Linux attempts to initialize during boot. The controller initialization
   currently produces errors in the kernel log. Administrators using
   I3C-attached devices (such as certain BMC sensors) should be aware of the
   limitation.

4. **Fast Boot does not reduce boot time.** The Dasharo setup menu option to
   enable Fast Boot has no measurable effect on total firmware boot time in
   this release. The feature flag is present in the menu but the underlying
   optimization path does not improve the boot time in a significant way.
   Still, Dasharo firmware boots much faster than vendor firmware:

   - Dasharo: < 15 seconds (without PSP), or < 55 seconds (with PSP)
   - vendor BIOS: over 2 minutes (without PSP), or over 3 minutes (with PSP)

None of these issues affect core functionality such as OS booting, PCIe
device enumeration, SATA storage, USB peripherals, network access, or secure
boot.

## Testing environment improvements for AMD platforms

Alongside the firmware release, the open-source-firmware-validation framework
has received a set of improvements targeting AMD-based platforms, tracked in
[OSFV repository](https://github.com/Dasharo/open-source-firmware-validation/pull/1269)
on the Dasharo validation repository.

### Temperature monitoring

The sensor library was extended with support for reading CPU temperatures on
AMD systems. Previously, the automated test suite could not collect thermal
data on AMD platforms - a gap that made it harder to verify thermal limits
and detect anomalous temperature behavior during long-running stability tests.

### BIOS menu navigation

Several improvements were made to how the test framework interacts with the
firmware setup menu:

- **Removed delays when pressing Enter** - particularly important for iPXE
  menus, where tight timeouts could cause the test framework to miss the
  entry window
- **Added delays between menu re-entries** - prevents EDK2 from unexpectedly
  traversing back two form levels when a menu is entered twice in rapid
  succession, an issue that caused intermittent test failures on Gigabyte
  MZ33-AR1

### Firmware flashing guards

Flash-related tests now include AMD-specific guards:

- The framework will not attempt to flash an FD image directly on AMD CPU
  platforms, where the flash chip layout and write protection rules differ
  from Intel platforms
- Region-based flashing operations no longer pass region arguments on AMD
  processors, avoiding failures caused by unsupported flash region
  configurations

### Platform configuration for MZ33-AR1

The `gigabyte-mz33-ar1.robot` platform configuration file was updated with
the settings needed for automated testing:

- Intel ME menu options are conditionally disabled (not present on AMD)
- Option ROMs are enabled to support network boot validation
- Non-standard Ethernet naming conventions are configured
- Capsule-on-Disk firmware update flow is enabled
- F10 is set as the boot menu hotkey, matching the MZ33-AR1 firmware

These additions mean the MZ33-AR1 can now be integrated into the same
automated test infrastructure that validates other Dasharo-supported boards,
enabling regression testing to run on every firmware build.

## fwupd HSI

The fwupd HSI tests show a very high security level (HSI2) with all requirements.
for HSI4 met:

```bash
sudo fwupdtool security
```

![fwupd HSI](/img/gigabyte_mz33_ar1_hsi.png)

The `Encrypted RAM` test requires the `mem_encrypt=on` parameter in the Linux command.
line for the test to PASS.

`SPI write protection` requires enabling the `SMM BIOS write protection` in
[Dasharo Security
Options](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options).

`UEFI secure boot` and `Linux kernel lockdown` may be achieved by enabling
[UEFI Secure Boot](https://docs.dasharo.com/dasharo-menu-docs/device-manager/#secure-boot-configuration).

`SPI replay protection` is unfortunately unsupported by the SPI flash chip
used on the Gigabyte MZ33-AR1 board, so the test will not pass. The test is
only shown if running the tool without sudo.

`Suspend-to-idle` test to pass requires fixes from [this
PR](https://github.com/fwupd/fwupd/pull/10163).

There are some tests that can only be passed with superuser privileges, and some
will never pass with superuser privileges. For example:

- `TPM PCR0 Reconstruction` may require sudo, if the user is not in the `tss` group
- `CET OS Support` will always fail with sudo, due to how the test is designed
  and how it works
- `SMM locked down` test will fail without sudo, unable to access required MSR
- `SPI replay protection` does not show up on the list when used with sudo
- `Suspend-to-idle` fails when run with sudo, with changes from [this
  PR](https://github.com/fwupd/fwupd/pull/10163).

If not for the `SPI replay protection` and `Suspend-to-idle` test (and the
sudo caveats), the platform could reach HSI4. `Pre-boot DMA protection` is a
software feature in the firmware that configures the IOMMU during the firmware
POST. It could be implemented in Dasharo in the future.

## Openness score

One of the metrics Dasharo tracks for each supported platform is the openness
score: the fraction of the firmware image that consists of open-source code
vs. closed-source binaries. The Dasharo (coreboot+UEFI) v0.9.0 compatible with
Gigabyte MZ33-AR1 v0.9.0, compared to the vendor firmware image, **reduces the
closed-source footprint by 80%!**. See the [comparison
table](https://docs.dasharo.com/variants/overview/#openness-comparison).

The analysis of the 32 MiB `gigabyte_mz33_ar1_v0.9.0.rom` image gives the
following breakdown:

| Category | Size |
|---|---|
| Open-source code | ~1.57 MiB (24.1%) |
| Closed-source code | ~4.95 MiB (75.9%) |
| Data | ~1.98 MiB |
| Empty space | ~23.5 MiB |

The dominant contributor to the closed-source portion is AMD firmware are the
PSP (Platform Security Processor) binaries - AMD-specific initialization blobs
that ship as pre-compiled binaries. On a server-class platform such as the
MZ33-AR1, these blobs are a hard dependency - the processor will not
initialize without them, and AMD does not publish their source code.

A score of 23.1% open-source is in line with what is typical for modern x86
server platforms where AMD or Intel proprietary firmware is required for
silicon bring-up. The same structural constraint applies to Intel-based
servers that depend on FSP (Firmware Support Package) blobs. The coreboot +
OpenSIL + EDK II combination used in this release maximizes the amount of
open-source code in the host firmware; what remains closed is exclusively the
silicon vendor firmware that has no open-source equivalent.

The full per-region breakdown is available in the [openness score
documentation](https://docs.dasharo.com/variants/gigabyte_mz33-ar1/openness-score/#v090).

## Summary

Dasharo v0.9.0 for the Gigabyte MZ33-AR1 delivers initial open-source firmware
for the AMD Turin server platform, built on coreboot 25.12 and AMD openSIL. It
brings a comprehensive feature set including UEFI Secure Boot, TPM Measured
Boot, AMD SME/SEV-SNP, TCG OPAL disk passwords, full PCIe, SATA, and USB
support, and SMBIOS 3.8.0 compliance. The release is accompanied by an
extended automated test environment for AMD platforms and an openness score of
23.1%.

Four known issues remain for future iterations: UEFI capsule staging across
resets, power state restoration from S5, I3C controller initialization
failures in Linux, and the non-functional Fast Boot option.

The firmware is available as part of the Dasharo Pro Package exclusively
through the [Full Build for Gigabyte MZ33-AR1
bundle](https://shop.3mdeb.com) in 3mdeb's shop.

Huge kudos to the NLnet Foundation for sponsoring the
[project](https://nlnet.nl/project/Coreboot-Phoenix/).

![NLnet](/covers/nlnet-logo.png)

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help. [Schedule
a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the
hidden benefits of your hardware. And if you want to stay up-to-date on all
things firmware security and optimization, be sure to sign up for our
newsletter:

{{< subscribe_form "dbbf5ff3-976f-478e-beaf-749a280358ea"
    "Subscribe to Dasharo Newsletter" >}}

Be sure to join the [Dasharo openSIL integration
status](https://3mdeb.com/events/#_dasharo-opensil-integration-status)
meetings, where the Dasharo team will walk through where open-source firmware
is with openSIL and FSP integration. [Book space in your
calendar](https://calendar.google.com/calendar/event?action=TEMPLATE&tmeid=Mmlnczg4Njdpa2hwazMzaHFta2wxYzNqMXBfMjAyNjA1MTJUMTgwMDAwWiBldmVudHNAM21kZWIuY29t&tmsrc=events%403mdeb.com&scp=ALL)!

Also do not miss the inaugural [Boot Security Mastery Conference
(BSMConf)](https://3mdeb.com/events/#_boot-security-mastery-conference) this
year. A five-day event combining practical education with industry knowledge
exchange around securing the platform boot chain, provisioning roots of trust
and platform hardening.

---
title: 'MSI PRO B850-P WIFI Dasharo v0.9.0 Released'
abstract: 'Dasharo v0.9.0 for the MSI PRO B850-P WIFI is now available,
          marking the first release of open-source firmware for a modern
          AMD Ryzen desktop platform based on coreboot and AMD openSIL.
          This post covers the features delivered in the release, the known
          issues, an openness score comparison against the vendor firmware,
          and answers to the most frequently asked questions from the community.'
cover: /covers/msi-pro-b850-p.jpg
author: michal.zygowski
layout: post
private: false
published: true
date: 2026-07-30
archives: "2026"

tags:
  - coreboot
  - firmware
  - AMD
  - Phoenix
  - PRO B850-P
  - open-source
  - openSIL
  - Dasharo
categories:
  - Firmware

---

## Introduction

Dasharo v0.9.0 for the MSI PRO B850-P WIFI was released on July 30, 2026.
This is a landmark release: it is the first open-source firmware for a modern
**AMD Ryzen desktop platform**, built on coreboot and AMD openSIL for the
Phoenix (Zen 4) processor family. While open-source firmware for AMD server
platforms such as the [Gigabyte MZ33-AR1](https://blog.3mdeb.com/2026/2026-05-15-gigabyte-mz33-ar1-v0.9.0-release/)
has existed for some time, consumer desktop platforms have remained out of
reach until now.

If you have been following the development journey, all previous posts from the
porting series are tagged
[PRO B850-P](https://blog.3mdeb.com/tags/pro-b850-p/). The series
started with USB, SATA, and PCIe bring-up in
[Part 1](https://blog.3mdeb.com/2026/2026-02-09-msi_pro_b850p_part1/),
progressed through openSIL integration, GFX bring-up, TPM support, fast boot,
and cross-OS validation through
[Part 6](https://blog.3mdeb.com/2026/2026-07-02-msi_pro_b850p_part6/).

If you have not read them yet, I highly encourage you to do so.

## Features in v0.9.0

The release delivers initial Dasharo firmware support for the MSI PRO B850-P
WIFI based on AMD Phoenix. The feature set includes:

- **Initial support for the MSI PRO B850-P WIFI board** based on AMD Phoenix
  (Zen 4)
- **UEFI compatible boot interface** with standard boot order and configurable
  boot options
- **UEFI Secure Boot support**
- Tested **Ubuntu 26.04 LTS** and **Windows 11 25H2**
- **AMD fTPM support** with **TPM Measured Boot** - full TPM 2.0 functionality
  through the AMD PSP without a discrete TPM chip
- **SMM BIOS write protection with AMD ROM Armor 3**
- **Setup menu password configuration** to protect unauthorized access to
  firmware setup
- **USB stack and network stack disable options** in setup menu
- **TPM PPI support** with UEFI variable backend
- **TCG OPAL and SATA disk password support**
- **UEFI Capsule Update v1 support** with Capsule on Disk
- **Serial port console redirection**
- **Auto-detection of pre-installed OS boot entries**
- **AMD memory context save/restore support** enabling fast boot on subsequent
  boots
- **Quiet boot and Fast boot options**
- **EFI System Partition scanning** to create boot options automatically
- **EZ Debug LED support** - DRAM and CPU LEDs indicate firmware
  initialization progress. VGA and BOOT LEDs are not currently used.
- **AMD CPU temperature reporting** via ACPI Thermal Zone
- **Integrated SBOM** for AMD PSP blobs, video and LAN drivers

![Ubuntu 26.04](/img/b850_rel_v0.9.0.jpeg)

## Known issues in v0.9.0

The v0.9.0 release documents four known limitations:

1. [**UEFI Capsules do not survive
   resets.**](https://github.com/Dasharo/dasharo-issues/issues/1843) Only
   immediate Capsule on Disk (CoD) updates are supported. A warm reset during
   a staged capsule update will not complete the update. This is a limitation
   of modern AMD platforms where staged capsules are lost in RAM after reset.
   The UEFI Capsule Update topic will be broadly elaborated in a separate
   publication soon. Stay tuned! There is also a lot of activity around
   Capsule Updates on [coreboot's
   gerrit](https://review.coreboot.org/q/topic:capsule_updates) besides the
   Dasharo efforts.

2. [**Previous power state restoration does not work for the powered-off
   state.**](https://github.com/Dasharo/dasharo-issues/issues/1844) The ATX
   power state restore (S5 -> power-on when AC is restored) is not functional.
   Only the "always on" or "always off" options work reliably.

3. [**Ubuntu 26.04 with serial console occasionally halts during
   boot.**](https://github.com/Dasharo/dasharo-issues/issues/1897) Systems
   with serial console redirection enabled may experience intermittent boot
   hangs under Ubuntu 26.04. Disabling serial console redirection in the
   firmware setup menu works around the issue.

4. [**WiFi card intermittently
   disappears.**](https://github.com/Dasharo/dasharo-issues/issues/1896) The
   on-board WiFi adapter may occasionally not appear on the PCI device list
   during boot and is not visible in the operating system. A CMOS reset
   reliably restores brings back the WiFi card. Same issue occurs on the
   vendor BIOS.

## Openness score

One of the metrics Dasharo tracks for each supported platform is the openness
score: the fraction of the firmware image that consists of open-source code
versus closed-source binaries. The formula used is:

> **(Dasharo size - Proprietary size) × 100 / Proprietary size**

The Dasharo (coreboot+UEFI) v0.9.0 compatible with the MSI PRO B850-P WIFI,
compared to the vendor firmware image `E7E56AMSI.2A92`, shows a **79.1%
reduction in closed-source firmware code**. See the full [comparison
table](https://docs.dasharo.com/variants/overview/#openness-comparison). It
looks like the firmware based on coreboot and openSIL for a single processor
family reduces the closed source footprint by about 80% on AMD platforms.
[Similar
result](https://blog.3mdeb.com/2026/2026-05-15-gigabyte-mz33-ar1-v0.9.0-release/#openness-score)
has been achieved on Gigabyte MZ33-AR1.

| Metric | Value | Interpretation |
|---|---|---|
| Closed-source diff | -79.1% | Lower is better: -100% would be fully open-source |
| Data size diff | 167010300.0% | Data content varies, no preference |
| Empty space diff | +377.3% | Higher is better: more free space = smaller TCB |

The dominant contributor to the remaining closed-source portion is the AMD
PSP (Platform Security Processor) firmware - silicon initialization blobs that
the processor requires for bring-up and that AMD does not publish as source
code. This structural constraint applies equally to all modern AMD and Intel
platforms. The coreboot + openSIL + EDK II combination used in this release
maximizes the open-source fraction. What remains closed is exclusively the
silicon vendor firmware for which no open-source equivalent exists.

High percentage of data difference is a result of the tool not finding any
data in the vendor BIOS. To avoid division by zero in the tool, it was assumed
that the size of data is 1 in the vendor BIOS and the formula gave an absurdly
high difference in data size.

## HSI and boot time

The fwupd HSI score was presented in previous blog post in the [HSI
section](https://blog.3mdeb.com/2026/2026-07-02-msi_pro_b850p_part6/#fwupd-hsi).

The boot time vs vendor BIOS was also compared in the [previous blog
post](https://blog.3mdeb.com/2026/2026-07-02-msi_pro_b850p_part6/#fast-boot-disabling-apob-hashing).

## Frequently asked questions

The release generated a number of questions from the community. Here are
answers to the most common ones.

### Is the AMD Ryzen 9 9950X3D supported? What is the current CPU support status?

The MSI PRO B850-P WIFI Dasharo port currently supports **AMD Phoenix Zen 4**
processors - these are the Ryzen™ 8700/8600/8500/8400/8300 Series processors
series AM5 CPUs (processors marked as Phoenix on the [MSI CPU compatibility
list](https://www.msi.com/Motherboard/PRO-B850-P-WIFI/support#cpu)). The
Phoenix SoC is what AMD's openSIL `phoenix_poc` branch targets, and that is
the openSIL revision used in this release. Any other processors are not
supported and will not boot.

The situation with **Zen 4 3D V-Cache** (X3D) variants such as the Ryzen 9
7950X3D is primarily a silicon compatibility question: the X3D die stacking
does not change the openSIL initialization path in a way that would block
support. However, none of Phoenix CPUs have 3D V-Cache, so processors with
3D V-Cache are not supported.

The Ryzen 9000 series (Zen 5 / Granite Ridge) uses a different SoC and is not
supported by the `phoenix_poc` openSIL branch. Supporting it would require AMD
to publish a corresponding openSIL branch for Granite Ridge, but it has not
happened as of this release.

Initially, the openSIL `phoenix_poc` was destined to support only mobile
processors. What 3mdeb did was an addition of Phoenix AM5 processors support.
If you are interested in the Raphael or Granite Ridge CPUs, feel free to
create issue on [openSIL
repository](https://github.com/openSIL/openSIL/issues/new/choose) and raise
interest in those CPUs. Possibly AMD will respond to the request if critical
mass is gathered. Be sure to join the [Dasharo openSIL integration
status](https://3mdeb.com/events/#_dasharo-opensil-integration-status) as
well. The more people will talk about openSIL, the more AMD may engage in
development of openSIL in the future.

### What is the most powerful CPU currently supported?

The most powerful AMD Phoenix Zen 4 desktop CPU for the AM5 socket is the
**Ryzen 7 8700G** (8 cores / 16 threads). Any Ryzen 8000 series AM5 processor
should work with Dasharo v0.9.0, but validation has been performed only on a
Ryzen 5 8600G. If you encounter issues with a specific processor, please
report it on the [Dasharo issue
tracker](https://github.com/Dasharo/dasharo-issues/issues).

To clarify on the Ryzen 9 9950X3D specifically: this is a **Zen 5** processor
(Ryzen 9000 series), not a Zen 4. It requires a different SoC supported by a
different openSIL branch that is not yet publicly available.

### Will memory encryption (SME/TSME) ever be enabled on consumer Ryzen?

AMD restricted memory encryption on non-PRO Ryzen processors at the PSP
firmware level. While AMD has lifted this restriction for certain processors,
they did not do that for Phoenix SKUs, as they did for Ryzen 9000. Whether and
when that happens is AMD's decision. We will not artificially block the
feature on our side.

### What about HEADS and TPM support? Do I need a discrete TPM chip?

**No discrete TPM chip is required.** The v0.9.0 firmware enables the AMD
firmware TPM (fTPM), which is a TPM 2.0 implementation running inside the AMD
PSP. It provides a full CRB interface and supports all standard TPM workflows
including Measured Boot, BitLocker, Windows Hello, and platform attestation.

To support different TPMs such as discrete TPM module or [Pluton
fTPM](https://github.com/Dasharo/dasharo-issues/issues/1901), coreboot will
need to have [support for modifying
APCBs](https://github.com/Dasharo/dasharo-issues/issues/1900) too.

Heads is a coreboot+Linux payload focused on measured and verified boot. It is
a separate payload from the EDK II UEFI payload used in this release and would
require a dedicated porting effort for the MSI PRO B850-P. There is no HEADS
support in v0.9.0, and it is not on the immediate roadmap. If this is
important to you, please open a feature request on the [Dasharo issue
tracker](https://github.com/Dasharo/dasharo-issues/issues). Also, the
integrated graphics initialization is only possible in UEFI environment
currently, so heads would need to operate with a discrete GPU and preferably a
discrete TPM.

### Can features disabled by AGESA (such as memory encryption on consumer CPUs) be re-enabled?

The Phoenix platform uses AMD openSIL rather than AGESA for silicon
initialization, which gives the Dasharo team considerably more visibility into
and control over initialization parameters compared to a conventional
AGESA-based firmware. However, certain features are blocked on the PSP
firmware level, to which nobody except AMD (and possibly their closest
partners) has access to.

Where AMD's policy disables a feature in silicon configuration (such as TSME
on non-PRO Ryzen), re-enabling it requires either AMD lifting the restriction
or finding alternative configuration paths.

Where possible, we will commit to enabling the features, if not blocked by
entities, which we have no control over.

It has to be noted, that currently, coreboot does not have support for
changing any CPU or silicon initialization options. Most of the settings are
hidden in APCB data files, which coreboot does not yet know how to modify.
Everything is fixed configuration and it is not likely to change too soon.

### What are the future development goals for the MSI PRO B850-P?

The immediate next steps after v0.9.0 are:

- **Upstreaming** the Phoenix SoC and MSI PRO B850-P mainboard code to
  coreboot upstream (Gerrit) and contributing the Phoenix-specific openSIL
  changes back to AMD's openSIL project
- **Fixing known issues**: [capsule staging across
  resets](https://github.com/Dasharo/dasharo-issues/issues/1843), [power state
  restoration from G3](https://github.com/Dasharo/dasharo-issues/issues/1844),
  the [Ubuntu 26.04 serial console boot
  hang](https://github.com/Dasharo/dasharo-issues/issues/1897), and the
  [intermittent WiFi
  issue](https://github.com/Dasharo/dasharo-issues/issues/1896)
- [**Pre-boot DMA
  protection**](https://github.com/Dasharo/dasharo-issues/issues/1903):
  configuring the IOMMU during firmware POST, tracked in [Dasharo issue
  #1880](https://github.com/Dasharo/dasharo-issues/issues/1880)
- [**Suspend-to-idle / modern standby**
  support](https://github.com/Dasharo/dasharo-issues/issues/1902), which
  requires significant ACPI work and detailed knowledge of the board GPIO
  topology.

## AMD PSP and APCB configuration

Unlike Intel platforms which configure most of the features via Intel FSP UPD
parameters, AMD platforms have their own design of passing configuration
parameters - the APCB (AGESA PSP Configuration Block). While, openSIL takes a
lot of parameters, many of them are just serving as a proxy to keep the BIOS
code in sync with the APCB contents. In proprietary AGESA and UEFI
implementations basing on AGESA, this is handled by setup variables and EDKII
PCDs. The change in setup variable causes a change in APCB. Then the value of
PCD is synced with the setup variable, and is used to finish configuring
features that were already pre-initialized by PSP or to configure other
features that depend on the current PCD/APCB value.

The aforementioned design makes most of the option depend on APCB and PSP.
Unfortunately, coreboot does not have any means nor code to modify the APCB,
nor it is prepared to do so in a graceful manner. APCB format is not publicly
documented, nor the process to update it on runtime. Community expecting
features, tunable options, and overclocking on AMD platforms, will have to
cool down a bit, because none of this will be available anytime soon. It will
require some redesign how the APCBs are integrated into coreboot.

We are not fond of the design, where so much depends on the PSP. While, this
design let AMD publish so much silicon initialization code for x86, it does
not offer much flexibility in tuning the platform or debugging what goes
wrong. The overclocking is also done by a different entity, the SMU, another
coprocessor living on the SoC beside PSP, responsible for power management.

Some references to the APCB format may be found on
[GitHub](https://github.com/oxidecomputer/amd-apcb) which could be potentially
used to add an implementation in coreboot. We have a tracking issue
[here](https://github.com/Dasharo/dasharo-issues/issues/1900). Some
[overclocking commands for SMU were also revealed for AM4
platforms](https://github.com/amkillam/ryzen_smu/blob/main/docs/rsmu_commands.md),
but their applicability to AM5 is unknown.

## Summary

Dasharo v0.9.0 for the MSI PRO B850-P WIFI is the first open-source firmware
for a modern AMD Ryzen desktop platform, built on coreboot 25.12 and AMD
openSIL for the Phoenix Zen 4 processor family. It delivers a comprehensive
feature set including UEFI Secure Boot, AMD fTPM with ROM Armor 3, TCG OPAL
disk passwords, fast boot via memory context restore, EZ Debug LED support,
and full compatibility with Ubuntu LTS and Windows 11.

Four known issues remain: UEFI capsule staging across resets, power state
restoration from S5, an Ubuntu 26.04 serial console boot hang, and
intermittent WiFi card disappearance. None affect core platform functionality.

The firmware achieves a **79.1% reduction in closed-source code** compared to
the vendor firmware `E7E56AMSI.2A92`, with the remaining proprietary content
limited to AMD PSP blobs for which no open-source alternative exists.

The firmware is available as part of the Dasharo Pro Package through the
[MSI PRO B850-P hardware-firmware
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

Also do not miss the [Boot Security Mastery Conference
(BSMConf)](https://3mdeb.com/events/#_boot-security-mastery-conference) - a
five-day event on September 21-25, 2026 in Gdańsk, Poland, combining
hands-on training with technical talks on securing the platform boot chain.

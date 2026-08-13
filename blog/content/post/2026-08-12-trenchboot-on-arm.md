---
title: 'Prospects of TrenchBoot on ARM'
abstract: 'A look at DRTM on ARM: where it stands compared to Intel TXT/AMD
           SKINIT and what will it take to run TrenchBoot on AArch64.
           How can TrenchBoot support both x86 and ARM architectures at the same
           time.'
cover: /covers/trenchboot-arm.png
author: sergii.dmytruk
layout: post
private: false
published: true
date: 2026-08-12
archives: "2026"

tags:
  - trenchboot
  - arm
  - drtm
  - open-source
categories:
  - Firmware
  - Security

---

DRTM (Dynamic Root of Trust for Measurement; also known as dynamic, late, or
secure launch) is a method of ensuring that the software running on a system
(mainly its operating system) hasn't been altered at rest or while it's being
loaded.  This approach is an alternative to a more common SRTM (Static RTM)
rooted in hardware's configuration, where the same is achieved by restricting
what can be run on the device.  Apart from allowing one to run anything and
verifying what's running as necessary, DRTM has a smaller set of components one
has to trust a priori compared to SRTM.  Another useful property of DRTM is an
ability to establish a secure environment without rebooting a device, which is
how this technology got its name.

TrenchBoot is a project aiming to make DRTM available in a commonly used
software, abstracting away differences of various hardware and enabling its
wider adoption.  This post considers the possibility of extending TrenchBoot to
support ARM architecture and the impact it may have.

## Background

If the above sounds confusing, the following resources can be used to learn more
on those subjects:

- [TrenchBoot FAQ](https://trenchboot.org/FAQ/)
- [TrenchBoot events & talk archive](https://trenchboot.org/events/)
- [FOSDEM 2025 status update](https://archive.fosdem.org/2025/schedule/event/fosdem-2025-5979-trenchboot-project-status-update/)
- [All other blog posts about TrenchBoot](https://blog.3mdeb.com/tags/trenchboot/)

## Is DRTM on ARM of any interest?

While the majority of ARM uses are in embedded and mobile devices, in recent
decade ARM has started moving more towards desktop and even server segments.
You can find lists of [ARM laptops][arm-laptops], [AI
workstations][ai-workstations], and a [few][desktop-1] [desktop][desktop-2]
[options][desktop-3] as well as [servers][arm-server].

This transition was made possible in part through adoption of common industry
standards like UEFI, ACPI, SMBIOS, PCIe, and others by ARM hardware.  Those
standards are typical for x86 systems, but are rare to come by when dealing
with most other architectures.  So despite ARM's origins in the fixed,
small-scale systems, by now this architecture has moved into territory of much
more capable general-purpose devices.

Adding DRTM to the list of supported technologies is another step in the same
direction.  It may not make many headlines even when widely available, but
Windows ["Secured Core" PCs][secure-core] with [System Guard][sys-guard] prove
there is a market for such features.

One specific niche where DRTM has tangible advantages over SRTM is verifying
that remote hardware runs correct software.  This is of interest in the area of
cloud computing where a compromise of a rented server may go unnoticed without
employing appropriate security measures.  In this situation, SRTM can be used to
get a hardware-backed proof of the boot chain.  Still, its dependence on the
perfectly executed boot process not only grows TCB beyond what's under control
of a user but makes the outcome sensitive to minor changes which aren't
necessarily stable (e.g., firmware and its configuration can change).  DRTM, on
the contrary, can start with a system in an untrusted state and switch to a
trusted state largely ignoring anything that preceded it.  Once the system is
online, the behavior is the same for both SRTM and DRTM and can be reused:
values of PCRS are used to prove the system has reached a well-defined state
(i.e., the one that can be trusted with handling certain data).

[arm-laptops]: https://nanoreview.net/en/laptop-list/arm
[ai-workstations]: https://www.arm.com/markets/consumer-technologies/ai-workstations
[desktop-1]: https://system76.com/desktops/thelio-astra
[desktop-2]: https://www.qualcomm.com/snapdragon/laptops-and-tablets/desktop
[desktop-3]: https://www.apple.com/shop/buy-mac/imac
[arm-server]: https://www.gigabyte.com/Enterprise/ARM-Server
[secure-core]: https://learn.microsoft.com/en-us/windows/security/book/hardware-security-silicon-assisted-security#secured-core-pc-and-edge-secured-core
[sys-guard]: https://learn.microsoft.com/en-us/windows/security/hardware-security/how-hardware-based-root-of-trust-helps-protect-windows

## What's the current state

ARM published its version of the [DRTM specification][den0113] in May 2023 and
has made 4 meaningful updates on it so far, with the latest v1.4 published in
February 2026.  Here's a quick summary of requirements and implementation
variability:

- can run only in AArch64
- needs an IOMMU capable of blocking DMA from accessing all or some of RAM
- supports only TPM2.0 with agile log format
- TPM can be of fTPM or dTPM kind
- permits firmware-backed or hardware-backed implementations
- sensible interface: both pre- and post-DRTM interactions are based on a well
  thought-out design, clearly learning from the prior art by Intel and AMD
- capability-based: the specification provides leeway for implementation, which
  then must advertise its preferences at runtime
- configurable: the implementation takes in a set of parameters, keeping things
  flexible for DRTM consumers (e.g., TrenchBoot)

The firmware-backed implementation sounds interesting.  Any hardware with open
firmware that also fulfills the requirements can theoretically support DRTM
despite not being designed with it in mind.  This is even more appealing given
the existence of a reference implementation in [Trusted Firmware-A][tfa]
(TF-A), though it's incomplete even with respect to the initial version of the
specification (it's better than it sounds; v1.4 doesn't add too many new
things compared to v1.0).  As of now, the implementation covers only Fixed
Virtual Platform, thus enabling the use of DRTM in an emulated environment,
which is nice to have for any technology.  There is even [a suite of unit
tests][acs] to validate DRTM implementation against the specification.

The implementation backed by hardware is meant to be more robust from the point
of view of security, yet it must be even rarer than devices supporting
firmware-backed DRTM, so one shouldn't count on it right now.

DRTM isn't on the minds of many customers (individual or corporate), and making
anything available in hardware takes time, so fingers crossed for getting more
suitable devices in retail.  One can already start developing on an emulated
system and later adapt TF-A for some device.  DRTM on ARM won't see much
traction among producers without a demand from potential users and means for
utilizing this functionality, so someone needs to take steps towards that.

[den0113]: https://developer.arm.com/documentation/den0113/f
[tfa]: https://github.com/ARM-software/arm-trusted-firmware/
[acs]: https://github.com/ARM-software/sysarch-acs#drtm-architecture-compliance-suite

## The current and future extent of TrenchBoot

The latest version of TrenchBoot supports the following environments:

- Intel or AMD systems (mostly older ones in both cases, with some unreleased
  developments for newer Intel systems while the newer, PSP-assisted, DRTM on
  AMD is only theoretically supported)
- TPM1.2 or TPM2.0 (fTPM or dTPM is irrelevant for TrenchBoot itself)
- legacy or UEFI firmware
- booting into Linux, MultiBoot2-capable kernels or EFI images (Xen)

TrenchBoot contains modified versions of [GRUB][tb-grub], [Linux][tb-linux] and
[Xen][tb-xen], all of which already support running on AArch64.  ARM-specific
changes for each project can't be avoided, but nothing drastic is needed.
Those interested in knowing more details should take a look at [the closer
examination of ARM's DRTM on TrenchBoot's site][tb-arm-blueprint].

Supporting ARM in TrenchBoot was actually tentatively planned since at least
2021, even though at that time the shape DRTM would have on this architecture
wasn't very clear.  Luckily, ARM's design maps rather well onto TrenchBoot.

[tb-arm-blueprint]: https://trenchboot.org/blueprints/DRTM_On_ARM/

## Porting TrenchBoot to ARM

The basic structure of a dynamic launch is rather simple:

1. Code that runs before the launch (e.g., [GRUB][tb-grub]).
2. A mechanism for initiating the launch (e.g., `GETSEC[SENTER]` on Intel or
   `SKINIT` on AMD).
3. Code that sets up a secure environment (e.g.,
   [secure-kernel-loader][tb-skl]).
4. Code that runs in the secure environment (e.g., [Linux][tb-linux] or
   [Xen][tb-xen]).

The above components may also be referred to as "DCE preamble", "DLE", "DCE"
and "DLME" respectively.  One can only blame [TCG][tcg-drtm] for coming up with
such opaque terminology, which doesn't exactly help make DRTM popular.
Funnily enough, terminology is one of a few things that ARM has taken from TCG.

DRTM on Intel, AMD and ARM follows the same basic structure.  As usual,
vendors and architectures do not agree on the implementation details, which is
what TrenchBoot tries to address.  One part of it is doing things differently
in the code of respective projects (e.g., GRUB), another one is describing the
state of the system before and after a dynamic launch.  The latter is addressed
by the [Secure Launch specification][slaunch], which is meant to be a common
data description for different projects, vendors and architectures, making the
code more generic and simplifying porting.

There are several levels at which Secure Launch can adapt:

1. Versioning.  Evolution of hardware and software systems is taken into
   account by assuming they'll change one day.  This may mean breaking changes,
   but it also means staying relevant in the long run.
2. Using a subset of common entries.  While certain data is highly specific to
   a platform, the rest is fairly generic and may be optional.  For this reason
   only some data is required to be present, and code must be prepared to handle
   absence of the rest gracefully.
3. Vendor- and architecture-specific entries.  Data of this kind is tied to the
   hardware the most and is the main reason specification needs to be updated to
   support new environments.  The changes in this area are small and contained.

Looking at how all of the above plays out with respect to DRTM on ARM validates
the previous design decisions and gives hope that TrenchBoot can be extended to
other targets like POWER (or maybe RISC-V if it ever supports DRTM) in the
future.

[tb-skl]: https://github.com/TrenchBoot/secure-kernel-loader
[slaunch]: https://trenchboot.org/specifications/Secure_Launch/
[tcg-drtm]: https://trustedcomputinggroup.org/resource/d-rtm-architecture-specification/

## What's in it for TrenchBoot

Adding support for ARM architecture will take TrenchBoot from being
multi-vendor (even though it's only 2 vendors so far) to multi-architecture.
Despite still working on initial upstreaming with varying results, this would
be an important milestone and an achievement of sorts.

Initial idea behind TrenchBoot changes was actually to make [tboot][tboot]
support AMD CPUs, but its maintainers just weren't interested (tboot isn't
actively adding features and wasn't meant to support multiple targets from the
start).  So supporting anything other than x86 will further differentiate
between tboot and TrenchBoot in the eyes of upstream project maintainers.

Additionally, the more platforms are supported, the more effective TrenchBoot as
a project is.  The bulk of functionality is shared, and widening support will
further generalize the common code and improve its boundary with
target-specific parts.

This won't be the first time TrenchBoot gets major updates either.  Here are
some resources on adding support for AMD:

- [Intro to AMD project](https://blog.3mdeb.com/2020/2020-03-28-trenchboot-nlnet-introduction/)
- [LZ (landing-zone) basics](https://blog.3mdeb.com/2020/2020-03-31-trenchboot-nlnet-lz/)
- [LZ validation](https://blog.3mdeb.com/2020/2020-04-03-trenchboot-nlnet-lz-validation/)
- [meta-trenchboot image](https://blog.3mdeb.com/2020/2020-04-30-trenchboot-nlnet-release-04/)
- [CI/CD](https://blog.3mdeb.com/2020/2020-05-05-trenchboot-nlnet-ci-cd-system/)
- [UEFI environments](https://blog.3mdeb.com/2020/2020-05-06-trenchboot-uefi-environment/)
- [Starting LZ from iPXE](https://blog.3mdeb.com/2020/2020-06-01-ipxe_lz_support/)
- [DEV vs IOMMU](https://blog.3mdeb.com/2020/2020-07-03-dev_and_iommu/)
- [TPM event log](https://blog.3mdeb.com/2020/2020-08-13-trenchboot-event-log/)
- [Multiboot2](https://blog.3mdeb.com/2020/2020-09-07-trenchboot-multiboot2-support/)
- [Xen support](https://blog.3mdeb.com/2020/2020-10-15-xen-implementation-for-trenchboot/)
- [RATS/CHARRA attestation PoC](https://blog.3mdeb.com/2020/2020-12-14-trenchboot_attestation/)
- [OSFC 2020 slides](https://trenchboot.org/slides/TrenchBoot_DRTM_features_for_AMD_platforms.pdf)
- [HIL harness](https://github.com/3mdeb/testing-trenchboot)

Resources on using TrenchBoot in `antievilmaid` (AEM) component of Qubes OS:

- [Project plan v1](https://docs.dasharo.com/projects/trenchboot-aem/)
- [Project plan v2](https://docs.dasharo.com/projects/trenchboot-aem-v2/)
- [NLnet grant page](https://nlnet.nl/project/Trenchboot-AEM/)
- [AEM for Qubes (intro)](https://blog.3mdeb.com/2023/2023-01-31-trenchboot-aem-for-qubesos/)
- [Qubes guest post](https://www.qubes-os.org/news/2023/01/31/trenchboot-aem-for-qubes-os/)
- [Phase 2 (TPM 2.0)](https://blog.3mdeb.com/2023/2023-09-27-aem_phase2/)
- [Phase 3](https://blog.3mdeb.com/2024/2024-01-12-aem_phase3/)
- [Phase 4 (AMD)](https://blog.3mdeb.com/2024/2024-04-11-aem_phase4/)
- [Phase 4 milestone](https://github.com/TrenchBoot/trenchboot-issues/milestone/4?closed=1)
- [UEFI support (Jun 2025)](https://blog.3mdeb.com/2025/2025-06-10-aem-uefi/)

[tboot]: https://sourceforge.net/projects/tboot/

## Who should care

DRTM is a useful technology that aims to make computer systems less susceptible
to exploitation by reducing the number of components that need to be trusted.
Due to its dependence on hardware configuration and its firmware, SRTM requires
leaving more control over devices to their vendors rather than owners, thereby
partially defeating the purpose of using stricter security mechanisms due to
greater centralization and not always warranted trust.  Running devices with
open-source firmware on hardware that's not vendor-locked improves the
situation, but severely limits hardware choices.

While this applies to both average users and companies providing services
related to computing, be it data processing or renting infrastructure, the
latter typically need more rigorous security measures.  Companies that handle
data sensitive in any respect (e.g., personally identifiable information,
intellectual property) expose themselves to risks if unauthorized access
occurs.  While terms of service can and usually do waive any responsibility for
such incidents, they always incur reputational damage and everything that comes
with it.  If you're looking for ways to reduce such risks by leveraging DRTM
capabilities, be sure to contact 3mdeb in any of the ways indicated below.

## Summary

DRTM on ARM is a practical take on DRTM implementation that has learned its
lessons from Intel TXT and AMD SKINIT, and manages to avoid their mistakes.
It's too early to judge real-life implementations, which may and likely will
have various drawbacks, but that's par for the course.

ARM's DRTM has a few architecture-specific requirements that are new for
TrenchBoot but don't pose any challenges.  The rest of the requirements have
close analogs in Intel- or AMD-specific code.  And the overall structure of
the dynamic launch is the same.

The takeaway so far is that ARM's view of DRTM is not much different from other
vendors and it is very much compatible with TrenchBoot.  Adding ARM support to
TrenchBoot will fulfill a long-standing intent of going beyond x86 with this
project.

### Adding DRTM and other features to devices

DRTM isn't the only way of ensuring authenticity of a device's boot chain or its
operating environment; there are more means for improving security or other
characteristics of devices.  If you want to discuss implementing or improving
such features, [schedule a call with
3mdeb](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t)
or drop us an email at `contact<at>3mdeb<dot>com`.  If you wish to stay
up-to-date on all things firmware security, sign up for our newsletter:

{{< subscribe_form
        "3160b3cf-f539-43cf-9be7-46d481358202"
        "Subscribe to 3mdeb Newsletter"
    >}}

### Boot Security Mastery Conference

If topics like secure boot chains, roots of trust, and owner-controlled
firmware resonate with you, join us at the [Boot Security Mastery
Conference](https://3mdeb.com/events/#_boot-security-mastery-conference).

A **five-day event on September 21-25**, 2026 in Gdańsk, Poland, combining
three days of hands-on training with two days of technical talks, research
presentations, and community networking focused on the full boot chain across
x86, ARM, POWER, and RISC-V.

[tb-grub]: https://github.com/TrenchBoot/grub
[tb-linux]: https://github.com/TrenchBoot/linux
[tb-xen]: https://github.com/TrenchBoot/xen

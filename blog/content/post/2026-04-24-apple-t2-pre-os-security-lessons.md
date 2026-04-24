---
title: 'What Open Source Firmware Can Learn from Apple Pre-OS Security'
abstract: "Apple Platform Security Guide is the most comprehensive platform
          security documentation in the industry. Instead of dismissing it as
          closed-source irrelevance, we read it through a firmware engineer's
          lens and extracted transferable security patterns for x86 and ARM
          open source firmware. Here is what we found about boot chains, Secure
          Enclave architecture, and five opportunities for Dasharo and
          coreboot."
cover: /covers/apple_t2.jpg
author: piotr.krol
layout: post
private: false
published: true
date: 2026-04-24
archives: "2026"

tags:
  - security
  - firmware
  - apple
  - T2
  - secure-boot
  - TPM
  - coreboot
  - dasharo
categories:
  - Firmware
  - Security

---

## Introduction

Apple published the most comprehensive platform security documentation in the
industry. The [Apple Platform Security Guide][apple-psg] (December 2024
edition, covering iOS 18.1) is the version we studied for this article.
Instead of dismissing it because it's closed-source, what if we read it as a
blueprint?

From my perspective, the Apple Platform Security Guide represents
state-of-the-art documentation of platform security. It is really great from
the perspective of explaining to the community what the security features are
and how those are used. We want to endorse Apple's approach of providing such
documentation, despite the fact that many people in the community will say
it's still closed source, still proprietary, still not transparent and not
auditable.

> _"To make the most of the extensive security features built into our
> platforms, organizations are encouraged to review their IT and security
> policies to ensure that they are taking full advantage of the layers of
> security technology offered by these platforms."
> -- [Apple Platform Security Guide][apple-psg], p. 6_

The purpose of the document is mostly for other organizations to maximize
leverage of the features provided by Apple. This may be some marketing, but it
is very to the point. Other organizations could benefit from using this as a
good example and deliver similar documents from their side. We are looking for
organizations that are transparent, trustworthy, and auditable, heading in a
different direction than Apple. But we recognize the design pattern and
recommend the ecosystem follow a similar motivation for explaining their
technology.

At 3mdeb, as part of the Dasharo team, we care deeply about pre-OS security. Our
Zarhus team focuses more on the OS side, but always with the goal of leveraging
Dasharo vertically. So we read this through a firmware engineer's lens. Many of
Apple's security patterns already exist in the open source firmware ecosystem,
or could be leveraged there with synergy between open source firmware, operating
systems, and the broader software ecosystem. One thing evident in the Guide is
that hardware-based security features cannot be disabled by mistake: secure by
design, secure by default, the same mindset present in
[OpenBSD](https://www.openbsd.org/security.html).

## What is Apple T2 and Why Should Firmware Engineers Care?

<figure style="text-align: center">
  <img src="/img/apple_t2.jpg" alt="Apple T2 chip"
    style="max-width: 50%">
  <figcaption>Apple T2 security chip, based on A10 silicon.
    <a href="https://commons.wikimedia.org/wiki/File:Apple_T2_APL1027.jpg">
    Wikimedia Commons</a>, CC0 (Henriok).</figcaption>
</figure>

T2 is a custom SoC security chip for Intel-based Mac computers, essentially
an A10 (the iPhone/iPad application-processor family) embedded in a Mac.
This is important because Apple's documentation states that T2 boot is
analogous to how A-series chips boot securely. Learning about T2 and
understanding how T2 works, we can assume that newer processors boot in
a similar manner.

Apple has not shipped Intel Macs in new designs since 2022, and on Apple
Silicon (M1 and later) the Secure Enclave is integrated directly into the
main SoC instead of living on a discrete chip. T2 is therefore the last
generation where the security coprocessor is physically separate, which
is also why it remains the cleanest reference model for reasoning about
equivalent designs on x86. The same boot-chain principles carry forward
into M-series; only the packaging changes.

T2 contains two processors: an ARMv8.1-A 64-bit application processor and an
ARMv7-A 32-bit Secure Enclave Processor. It has its own AES engine for
decrypting the system SSD on the fly. The encryption keys are derived from
chip-unique UID/GID fuses inside T2 and never leave the Secure Enclave, so
an SSD physically removed from a T2 Mac cannot be decrypted in a PC or in
another Mac even though the drive itself is readable.

### Secure Enclave Architecture

The Secure Enclave is a dedicated secure subsystem integrated into the Apple
system on chip, and the Secure Enclave Processor is the CPU inside of it. That
distinction matters: the Secure Enclave is the entire subsystem, the Secure
Enclave Processor is just one component.

The components within the Secure Enclave subsystem:

- **Random Number Generator** creates entropy
- **Internal AES engine** uses hardware keys derived from the UID
  (unique per device, fused at manufacturing) and GID (shared per
  SoC generation)
- **Public Key Accelerator (PKA)** handles RSA and ECC operations
- **Secure Enclave Processor** is the dedicated CPU that runs
  sepOS, an [L4-based microkernel][l4-microkernel]
- **Memory Protection Engine** encrypts all communication between
  the Secure Enclave and external memory with ephemeral keys
  generated at each boot

There is also an I2C bus which connects to Secure Nonvolatile Storage.
All user data encryption keys are rooted in entropy stored here. This
separate chip survives SoC replacement, preserving critical security
state even if the main processor is swapped during repair.

In the Apple ecosystem, T2 effectively replaced the role that Intel Management
Engine plays on other platforms. This design choice speaks volumes about trust:
if Apple, with their deep Intel partnership, chose to build their own security
coprocessor rather than rely on ME, the open source community should take note.

### A Note on Trusted Execution Technologies

Apple Secure Enclave is treated as a Trusted Execution Environment which is a
composite of a dedicated processor. ARM TrustZone is just a CPU mode separation
in Normal World and Secure World. And then we can also classify x86 SMM
(System Management Mode) as a TEE-like isolated mode. Those are three main
technologies which we can classify in a similar way, and understanding one helps
reason about the others. For a comprehensive treatment of trusted execution
technologies in firmware context, see Jiewen Yao and Vincent Zimmer's _[Building
Secure Firmware][bsf]_ (Apress, 2020).

Notably, Intel Management Engine (ME) and AMD Platform Security Processor (PSP)
serve similar roles as isolated coprocessors, but with a crucial difference in
trust model. In the Apple ecosystem, T2 replaced Management Engine's role
entirely, handling secure boot, disk encryption, and sensor access. Apple did
not trust the existing Intel ME for these functions. If Apple, with their
engineering resources and Intel partnership, chose to replace ME rather than
rely on it, the open source community should ask the same question.
The Dasharo project follows a [binary blob policy][dasharo-blob] that
minimizes unnecessary blobs and supports [disabling Intel ME][dasharo-me]
on every platform where hardware remains stable without it.

## How Apple Boots: Two Parallel Chains of Trust

<figure style="text-align: center">
  <div style="display: flex; gap: 1em; justify-content: center;">
    <img src="/img/tc3028_ap_boot_chain.svg"
      alt="AP Boot Chain" style="max-width: 48%">
    <img src="/img/tc3028_se_boot_chain.svg"
      alt="SE Boot Chain" style="max-width: 48%">
  </div>
  <figcaption>AP boot chain (green, left) and SE boot chain
    (blue, right) running in parallel. 3mdeb diagrams based on
    <a href="https://help.apple.com/pdf/security/en_US/apple-platform-security-guide.pdf">
    Apple Platform Security Guide</a>.</figcaption>
</figure>

Like Intel Management Engine or AMD PSP, the Apple security coprocessor must
boot before the main CPU: on Intel Macs T2 powers on first, verifies its
own chain (Boot ROM -> iBoot -> bridgeOS), then reads the UEFI firmware from
SPI flash, verifies it, and only then releases the Intel CPU from reset.
This ordering is inherent to being the root of trust: whatever verifies the
main CPU's first code must already be running by the time that code is
fetched.

Apple's documentation describes the boot process for iPhone and iPad, and
states that T2 follows the same pattern. We take this at face value and
describe the shared chain below, calling out Intel Mac differences (like
bridgeOS) where they appear.

**The Application Processor chain** starts with Boot ROM. The Apple Platform
Security Guide describes it:

> _"When an iPad and iPhone device is turned on, its Application
> Processor immediately executes code from read-only memory referred
> to as Boot ROM. This immutable code, known as the hardware root of
> trust, is laid down during chip fabrication and is implicitly
> trusted."
> -- [Apple Platform Security Guide][apple-psg], p. 36_

ROM is burned into silicon during manufacturing. It contains a built-in CA
public key for signature verification; if the signature of the loaded firmware
is invalid, it enters
Device Firmware Update mode. From A10 onward, the extra Low-Level Bootloader
stage was eliminated: Boot ROM loads iBoot directly. Fewer stages, smaller
attack surface.

**iBoot** is the first mutable code in the boot chain. It handles hardware
initialization (memory controller, display, storage) and updates Boot
Progress Registers to signal boot mode to the Secure Enclave. It assigns a
memory region for the SE and sends sepOS for verification, then loads and
verifies the kernel.

On iOS 14+, Apple modified the C compiler toolchain to build iBoot with
improved security:

> _"Apple modified the C compiler toolchain used to build the iBoot
> bootloader to improve its security. The modified toolchain implements
> code designed to prevent memory- and type-safety issues that are
> typically encountered in C programs."
> -- [Apple Platform Security Guide][apple-psg], p. 36_

In practice, that covers buffer overflows, heap exploitation, type
confusion, and use-after-free. Boot ROM is not covered because mask
ROM cannot be updated, so only the mutable stage is hardened. iBoot
was historically targeted by exploits. Unlike Boot ROM vulnerabilities,
iBoot issues can be patched via software updates, so they do not
persist across releases.

**The Secure Enclave chain** runs in parallel: SE Boot ROM configures SCIP
(System Coprocessor Integrity Protection), initializes the Memory Protection
Engine, receives sepOS, verifies it, and executes. SCIP is configured before
receiving sepOS, providing coprocessor isolation. When SCIP is configured
and the Application Processor has assigned memory, the Memory Protection Engine
can be initialized. After iBoot sends sepOS, both chains work simultaneously.
Kernel load does not wait for the Secure Enclave. This parallelism is important
for boot performance.

## Boot Progress Registers and Kernel Integrity Protection

Apple defines data protection classes that determine when encrypted data is
accessible. Class A (Complete Protection) discards the key 10 seconds after the
device locks, protecting health data and banking apps. Class B (Protected Unless
Open) allows in-progress writes to finish, like mail attachments downloading in
background. Class C (Protected Until First Authentication) keeps keys available
after the first unlock until reboot, covering most app data. A fourth Class D
(No Protection) exists on iOS for always-accessible system files and is not
used on macOS.

Apple devices have three boot modes: normal boot, recovery mode, and Device
Firmware Update (DFU). Boot Progress Registers tell the Secure Enclave which
mode we are in, and the Secure Enclave decides which encryption keys to
release. In DFU, even Class D is locked, so nothing decrypts. In recovery,
Classes A, B, and C are inaccessible while Class D still reads. In normal
boot, full access after user authentication.

Physical access during recovery or update is a common attack vector: the
attacker forces the device into DFU or recovery and asks the Secure Enclave
to release keys under those semantics. BPR are set by immutable Boot ROM
(for DFU) or verified iBoot (for recovery), so the SE can tell which mode
a given boot actually entered and refuses to release keys for classes that
are out of scope. The x86 equivalent is TPM PCR values: boot state determines
what secrets are accessible. PCR-based LUKS sealing is the direct analog.

**Kernel Integrity Protection (KIP)** is another mechanism set up during boot
before the OS kernel runs. The memory controller provides a protected physical
memory region, and the kernel becomes read-only after boot with no runtime
modification. The Application Processor at some point has to load the kernel,
and this is done by iBoot. Essentially iBoot configures the region in the
memory controller, loads the kernel and kernel extensions (kexts), then locks
the region by denying
any writes, and transfers control. The kernel cannot modify itself because any
attempt to modify kernel code after passing control is denied and causes a
fault.

The security properties are:

- No writable kernel mappings, so even the kernel cannot write to its own code
- No executable code outside the protected region, preventing code injection
- Configuration is locked at boot, and the attacker cannot reconfigure that

In x86, memory controller lock is similar to UEFI DXE image protection, as
both are set at the bootloader stage. There is a signal in UEFI
(`EndOfDxe` and `SmmReadyToLock`) sent at the end of the configuration
phase (see [EDK2 MemoryProtection.c][edk2-memprotect] for implementation).
After this, image sections marked as code become read-only. Making
this mandatory, not optional, across all implementations would be a clear
improvement.

## What Can Go Wrong: The checkm8 Story

The best example of what can go wrong is [checkm8 (CVE-2019-8900)][checkm8],
a use-after-free in the DFU USB handler. DFU mode handles USB directly from
Boot ROM, without an OS underneath and without ASLR. When a USB transfer
was aborted mid-operation, the DFU handler freed the IO buffer but failed
to clear the global pointer, a classical C memory safety bug.

By carefully sequencing about 20-30 USB operations, attackers positioned a
controlled data structure containing a callback function pointer at the freed
buffer's address. When Boot ROM called through the dangling pointer, it executed
attacker-controlled code. Physical USB access was required; no remote
exploitation.

Researchers dumped Boot ROM, analyzed Secure Enclave protocols, and
earned persistence that survives OS updates. It is unfixable because mask ROM is
burned into silicon.

Why does this matter for us? The same class of bugs may exist in UEFI
proprietary BIOS recovery paths. The USB stack in EDK2 is a significant attack
surface, which is why Dasharo provides the ability to
[disable USB stack in firmware][dasharo-usb] for
security-conscious deployments.

## Anti-Rollback: Personalized Signatures vs TPM Sealing

The traditional anti-rollback approach uses a global signature combined with a
Secure Version Number (SVN), which only increments. This breaks if an attacker
can reset the stored version counter, allowing downgrade to vulnerable firmware.
SVN is also present in Intel Authenticated Code Modules (ACMs), making this
problem relevant across platforms.

Apple's solution binds signatures to the device's ECID (Exclusive Chip ID,
a hardware chip identifier burned into silicon). When the device requests a
firmware update, it contacts Apple's signing server, which checks the
current security epoch and produces a signature valid only for that
specific chip. An older firmware version simply will not receive a valid
signature. Since each signature is device-specific, it cannot be
transplanted to another device.

In the x86 ecosystem, `TPM_Seal` with `PCR0` firmware policy achieves a similar
goal. The sealed key only becomes available when boot measurements match the
expected configuration. This is not unique to Apple; it is a common attestation
pattern. The difference is that Apple enforces it at the infrastructure level,
while in open source firmware it remains opt-in.

## Intel Mac with T2: Where Apple Security Meets x86

On Intel Macs, the T2 chip powers on first, runs Boot ROM, verifies iBoot, then
transitions to bridgeOS. BridgeOS reads the UEFI firmware from SPI flash,
verifies it, and memory-maps it over eSPI to the Intel CPU. Only then is the
Intel CPU released from reset. No Intel Boot Guard is needed because T2 is the
entire root of trust.

T2 offers three secure boot policies. Full Security uses ECID-bound signatures.
Medium Security uses global Apple signatures. No Security disables verification
of the host CPU firmware entirely, enabling custom OS installation. The T2 chip
itself always secure-boots; only the Intel side is affected. M1 removed the No
Security option. T2 Macs were the last to offer true boot freedom. On non-Apple
x86 platforms, the platform owner is the decision maker about what boots. The
goal in the open source ecosystem is always full owner control, not control in
the hands of the vendor.

## Five Opportunities for Open Source Firmware

<figure style="text-align: center">
  <img src="/img/firmware-security.png"
    alt="Firmware security layers" style="max-width: 100%">
  <figcaption><a href="https://fwupd.github.io/libfwupdplugin/hsi.html">
    Host Security ID (HSI)</a> from LVFS/fwupd project. HSI
    groups firmware security features into numbered levels
    (HSI-0 through HSI-4), is widely adopted, and shows the
    kind of visibility we need more of.</figcaption>
</figure>

Apple has advantages we don't have. First of all, they're doing custom
silicon. They have very good vertical integration. They have a closed
ecosystem. They have enough margin to hire good engineers, so they can work
on all these features. That's why the open source ecosystem has to do things
differently, because we differ in the resources and the ability to create
that kind of vertical integration. But we should not give up, and we should
not admit that open ecosystem cannot gain the same or similar properties.
And in fact, many principles translate to x86 with TPM and probably the
upcoming ARM ecosystem. In case of x86, it doesn't matter if this is Intel
or AMD, because similar features are provided. So let's look at what we
can actually do.

### Opportunity 1: PCR-Gated Operations

Apple's BPR gates data access by boot state. Our TPM PCRs can do the same, but
we mostly stop at disk encryption. The innovation is using PCR state to gate
other operations, especially firmware update and remote attestation. We can
imagine that we can create PCR-based gates, which gate firmware-related actions
to PCRs.

We can imagine an open source firmware update mode. Currently the flow is that
the user enters the setup menu and enters firmware update mode and the update
proceeds. This firmware update mode through firmware update tools or maybe even
capsule update could warn the user if the PCR
values don't match the expected known-good configuration. Users can still force
the update, but they're informed that the platform may be in an unexpected
state. They can be conscious that maybe someone compromised their system.

A BIOS setup screen could show current PCR values, where the user
can take a photo of it. Maybe even there could be a QR code for easy opening of
the link. Then there is a public API endpoint for remote attestation. Anyone can
verify platform state before trusting it. Essentially, they open the link which
was created and the result tells them that this set of PCRs is good, is
expected for this version of firmware, for example, or this version of firmware
with this configuration. Like GrapheneOS Auditor, but for firmware.

An enterprise version of that feature does the same, but for the fleet. We have
backend introspection into what's going on in my fleet of devices, what's their
state. Platforms submit attestation to the server, the server verifies and
alerts on anomaly.

### Opportunity 2: Forward Sealing for Updates

Forward sealing solves the PCR0-changes-on-update problem. Right now firmware
update changes PCR0, and LUKS keys become inaccessible because of the change.

Before the update, compute expected PCR values for the new firmware
version and seal keys to both current and future PCR. After update, old seal
fails, but new seal works. Then of course, if the system booted and we can
confirm that everything is fine, we can remove the old seals. Or we can simply
forward-seal to the new value and assume that it will reboot correctly. Or if it
will not reboot correctly, we could have some recovery procedures through a PIN
or whatever additional policy for unsealing. As always, the most important point
is make it great UX and do not destroy the feature because of bad UX.

### Opportunity 3: Qubes Boot Modes with Power Transition Hardening

Another use of PCR-gated operations: Qubes boot modes with power transition
hardening. We could imagine dual-mode Qubes where PCR policy determines if
certain private VMs (maybe some VMs which connect to the internet and external
systems like VPN, maybe some VMs which contain some special data) could
be gated.

Modern Standby (S0ix) has a different attack surface. Standby means network
active. This is a different threat model and we could, depending on the various
ways of booting, determine what we expose, what we provide. Unexpected reset
transitions should trigger a security response, for example refuse key
release or require attestation or at least give the user information. Something
is wrong. Some power transition is not exactly expected.

### Opportunity 4: Loaded Image Protection

Apple's Kernel Integrity Protection makes the kernel read-only after boot. In
UEFI, `EndOfDxe` and `SmmReadyToLock` already mark the point after which code
sections become read-only. Making this mandatory, not optional, across all
implementations would close a significant gap.

### Opportunity 5: Self-Hosted Signing with Device Identity

Apple's ECID-bound signing prevents rollback and transplantation. Organizations
could run their own signing server with TPM EK as the device identity anchor,
providing device-bound signatures without vendor lock-in. The
design pattern is common
practice and could be very interesting for open source firmware.

## Acknowledgments

This content was sponsored by
[Power Up Privacy](https://powerupprivacy.com/) and reviewed by
[Kicksecure](https://www.kicksecure.com/).

<div style="display: flex; align-items: center; gap: 2em;
  justify-content: center; margin: 1em 0;">
  <a href="https://powerupprivacy.com/">
    <img src="/img/power-up-privacy-logo-light.png"
      alt="Power Up Privacy" style="height: 90px;"></a>
  <a href="https://www.kicksecure.com/">
    <img src="/img/Kicksecure-logo-text.svg"
      alt="Kicksecure" style="height: 90px;"></a>
</div>

## Conclusion

The open source firmware ecosystem does not have Apple's resources for custom
silicon and vertical integration. But we do not need to replicate their
approach; we need to learn from it. The patterns are transferable: hardware root
of trust through Intel Boot Guard and measured boot, chain of trust through
TPM-based verified boot, boot-state policies through PCR sealing, and
anti-rollback through remote attestation.

What matters is not copying Apple's architecture, but building equivalent
security properties with the tools we have, while preserving what Apple
cannot offer: transparency, auditability, and owner control. Read the
[Apple Platform Security Guide][apple-psg] yourself, and then help us build
these patterns into open firmware.

This article is based on the December 2024 edition of the Apple Platform
Security Guide, and it is only the beginning. We did not cover Apple's
treatment of UEFI firmware on Intel-based Macs, Option ROM security, or
Option ROM sandboxing, all of which have direct implications for open
source firmware. In the next part we will address these remaining pre-OS
topics from the same document. Apple has since updated the guide (January
and March 2026), and we plan to analyze what changed in the areas we
covered. Follow us to stay updated.

## Summary

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

[apple-psg]: https://web.archive.org/web/20241220/https://help.apple.com/pdf/security/en_US/apple-platform-security-guide.pdf
[checkm8]: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8900
[l4-microkernel]: https://en.wikipedia.org/wiki/L4_microkernel_family
[edk2-memprotect]: https://github.com/tianocore/edk2/blob/master/MdeModulePkg/Core/Dxe/Misc/MemoryProtection.c
[bsf]: https://link.springer.com/book/10.1007/978-1-4842-6106-4
[dasharo-me]: https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#intel-management-engine-options
[dasharo-usb]: https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#usb-configuration
[dasharo-blob]: https://docs.dasharo.com/osf-trivia-list/dasharo/#what-is-dasharo-binary-blob-policy

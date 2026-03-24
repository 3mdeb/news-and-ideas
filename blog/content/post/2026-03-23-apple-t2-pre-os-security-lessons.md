---
title: 'What Open Source Firmware Can Learn from Apple Pre-OS Security'
abstract: 'Apple Platform Security Guide is the most comprehensive platform
          security documentation in the industry. Instead of dismissing it as
          closed-source irrelevance, we read it through a firmware engineers
          lens and extracted transferable security patterns for x86 and ARM
          open source firmware. Here is what we found about boot chains, Secure
          Enclave architecture, and three concrete opportunities for Dasharo
          and coreboot.'
cover: /covers/apple_t2.jpg
author: piotr.krol
layout: post
published: true
date: 2026-03-24
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
industry. The Apple Platform Security Guide, released in December 2024, covers
iOS 18.1 and every generation of Apple silicon through the M-series chips.
Instead of dismissing it because it's closed-source, what if we read it as a
blueprint?

From my perspective, the Apple Platform Security Guide represents
state-of-the-art documentation of platform security. It is really great from
the perspective of explaining to the community what the security features are
and how those are used. We want to endorse Apple's approach of providing such
documentation -- despite the fact that many people in the community will say
it's still closed source, still proprietary, still not transparent and not
auditable.

> "To make the most of the extensive security features built into our platforms,
> organizations are encouraged to review their IT and security policies to
> ensure that they are taking full advantage of the layers of security
> technology offered by these platforms."

The purpose of the document is mostly for other organizations to maximize
leverage of the features provided by Apple. This may be some marketing, but it
is very to the point. Other organizations could benefit from using this as a
good example and deliver similar documents from their side.

At 3mdeb, we care about pre-OS. So we read this through a firmware engineer's
lens. Our thesis: many of Apple's security patterns translate directly to
x86+TPM and the open source firmware ecosystem. One thing evident in the Guide
is that hardware-based security features cannot be disabled by mistake -- secure
by design, secure by default, the same mindset present in OpenBSD.

## What is Apple T2 and Why Should Firmware Engineers Care?

![Apple T2 chip](/img/apple_t2.jpg)

T2 is a custom SoC security chip for Intel-based Mac computers -- essentially
an A10 chip embedded in a Mac. This is important because Apple's documentation
states that T2 boot is analogous to how A-series chips boot securely. Learning
about T2 and understanding how T2 works, we can assume that newer processors
boot in a similar manner.

T2 contains two processors: an ARMv8.1-A 64-bit application processor and an
ARMv7-A 32-bit Secure Enclave Processor. It has its own AES engine for
decrypting the system SSD on the fly -- which also makes it impossible to use
the SSD from a Mac in a PC or another Mac. The Secure Enclave inside T2 is a
dedicated subsystem with its own Random Number Generator, crypto engine using
UID and GID fuses that are never exposed, and a Memory Protection Engine that
encrypts all SE-to-memory traffic with ephemeral keys generated at each boot.

For firmware engineers, T2 is the Rosetta Stone: Apple's full security model
running alongside x86 hardware.

## How Apple Boots: Two Parallel Chains of Trust

![T2 Boot Flow -- AP and SE boot chains in parallel](/img/t2_boot_flow.png)

Like Intel Management Engine or AMD PSP, the Apple security coprocessor likely
boots simultaneously with or even before the main CPU.

**The Application Processor chain** starts with Boot ROM. The Apple Platform
Security Guide describes it:

> "When an iPhone or iPad device is turned on, its Application Processor
> immediately executes code from read-only memory known as the Boot ROM.
> This immutable code, known as the hardware root of trust, is laid down during
> chip fabrication."

ROM is burned into silicon during manufacturing. It contains a built-in CA
public key for signature verification -- if the signature is invalid, it enters
Device Firmware Update mode. From A10 onward, the extra Low-Level Bootloader
stage was eliminated: Boot ROM loads iBoot directly. Fewer stages, smaller
attack surface.

**iBoot** is the first mutable code in the boot chain. It handles hardware
initialization -- memory controller, display, storage -- and updates Boot
Progress Registers to signal boot mode to the Secure Enclave. It assigns a
memory region for the SE and sends sepOS for verification, then loads and
verifies the kernel. On iOS 14+, Apple modified the C compiler toolchain to
build iBoot with improved security, preventing classes of vulnerabilities like
type confusion and use-after-free.

**The Secure Enclave chain** runs in parallel: SE Boot ROM configures SCIP
(System Coprocessor Integrity Protection), initializes the Memory Protection
Engine, receives sepOS, verifies it, and executes. After iBoot sends sepOS,
both chains work simultaneously. Kernel load does not wait for the Secure
Enclave. This parallelism is important for boot performance.

## Boot Progress Registers: Data Access by Boot State

Apple devices have three boot modes: normal boot, recovery mode, and DFU. Boot
Progress Registers tell the Secure Enclave which mode we are in, and the Secure
Enclave decides which encryption keys to release. In DFU, all data is locked.
In recovery, Class A/B/C data is inaccessible. In normal boot, full access
after user authentication.

Physical access during recovery or update is a common attack vector -- BPR were
introduced to prevent it. The x86 equivalent is TPM PCR values: boot state
determines what secrets are accessible. PCR-based LUKS sealing is the direct
analog.

## What Can Go Wrong: The checkm8 Story

![Boot ROM -- immutable code burned into silicon](/img/mask_rom.jpg)

The best example of what can go wrong is checkm8 -- a use-after-free in the DFU
USB handler. DFU mode handles USB directly. No OS, no Address Space Layout
Randomization. When a USB transfer was aborted mid-operation, the DFU handler
freed the IO buffer but failed to clear the global pointer -- a classical C
memory safety bug.

By carefully sequencing about 20-30 USB operations, attackers positioned a
controlled data structure containing a callback function pointer at the freed
buffer's address. When Boot ROM called through the dangling pointer, it executed
attacker-controlled code. Physical USB access was required; no remote
exploitation.

The impact: researchers dumped Boot ROM, analyzed Secure Enclave protocols, and
earned persistence that survives OS updates. It is unfixable -- mask ROM burned
into silicon.

Why does this matter for us? The same class of bugs exists in UEFI recovery
paths. The USB stack in EDK2 is attack surface. Memory safety in C firmware is
the fundamental problem. checkm8 proves that a hardware root of trust is only as
good as its implementation.

## Anti-Rollback: Personalized Signatures vs TPM Sealing

The traditional anti-rollback approach -- global signature plus version counter
-- breaks if you can reset the counter. Apple's solution: the signing server
maintains the current security epoch, and since signatures are bound to ECID
(hardware chip ID), they cannot be transplanted between devices. If an older
version is requested, the server simply won't sign it.

In the x86 ecosystem, we could use TPM_Seal with PCR0 firmware policy -- the
key only unseals when boot measurements match the sealed configuration. The
design pattern is not unique to Apple. It is common practice. It is essentially
a form of attestation -- online verification of build identity.

## Intel Mac with T2: Where Apple Security Meets x86

On Intel Macs, the T2 chip powers on first, runs Boot ROM, verifies iBoot, then
transitions to bridgeOS. BridgeOS reads the UEFI firmware from SPI flash,
verifies it, and memory-maps it over eSPI to the Intel CPU. Only then is the
Intel CPU released from reset. No Intel Boot Guard -- T2 is the entire root of
trust.

The critical user-facing difference: T2 offers three secure boot policies. Full
Security uses ECID-bound signatures. Medium Security uses global Apple
signatures. No Security disables Intel CPU verification entirely, enabling
custom OS installation. The T2 chip itself always secure-boots -- only the Intel
side is affected. M1 removed the No Security option. T2 Macs were the last to
offer true boot freedom. If we consider that in the context of open source
firmware, we don't have these kinds of user-facing controls, and that's a
significant gap.

## Three Opportunities for Open Source Firmware

![Firmware security -- defense in depth](/img/firmware-security.png)

Apple has advantages we don't have: custom silicon, vertical integration, closed
ecosystem. But many principles translate to x86 with TPM. We see three main
opportunities.

### Opportunity 1: PCR-Gated Operations

Apple's BPR gates data access by boot state. Our TPM PCRs can do the same, but
we mostly stop at disk encryption. The innovation is using PCR state to gate
other operations -- especially firmware update and remote attestation.

Imagine a Dasharo firmware update mode that warns the user if PCR values don't
match known-good configuration. Users can still force the update, but they are
informed. Take it further: a BIOS setup screen showing PCR values with a QR
code, verified against a known-good database -- like GrapheneOS Auditor, but
for firmware. An enterprise version does the same for the fleet.

Forward sealing solves the PCR0-changes-on-update problem: before updating,
compute expected PCR values for the new firmware and seal keys to both current
and future values. After update, old seal fails, new seal works. As always, the
most important point is make it great UX.

### Opportunity 2: Loaded Image Protection

Apple's Kernel Integrity Protection makes the kernel read-only after boot. In
UEFI, `EndOfDxe` and `SmmReadyToLock` already mark the point after which code
sections become read-only. The opportunity: make this mandatory, not optional,
across all implementations.

### Opportunity 3: Self-Hosted Signing with Device Identity

Apple's ECID-bound signing prevents rollback and transplantation. Organizations
could run their own signing server with TPM EK as the device identity anchor --
device-bound signatures without vendor lock-in. The design pattern is common
practice and could be very interesting for open source firmware.

## Acknowledgments

This content was sponsored by [PUP (Purchasable Upgrade
Program)](https://docs.dasharo.com/) and reviewed by
[Kicksecure](https://www.kicksecure.com/).

![Kicksecure](/img/Kicksecure-logo-text.svg)

<!-- TODO: Add PUP logo when available -->

## Conclusion

Apple's integrated approach provides mandatory, consistent hardware enforcement.
The key insight: what can the open source firmware ecosystem learn from that?
Hardware root of trust maps to Boot Guard and measured boot. Chain of trust maps
to verified boot with TPM. Boot-state key policy maps to PCR-based sealing.
Personalized signatures map to remote attestation and forward sealing.

Read the
[Apple Platform Security Guide](https://support.apple.com/guide/security/)
yourself. Then help us build these patterns into open firmware.

## Summary

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to
[sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).

---
title: 'What Open Source Firmware Can Learn from Apple Pre-OS Security'
abstract: 'Apple Platform Security Guide is the most comprehensive platform
          security documentation in the industry. Instead of dismissing it as
          closed-source irrelevance, we read it through a firmware engineers
          lens and extracted transferable security patterns for x86 and ARM
          open source firmware. Here is what we found about boot chains, Secure
          Enclave architecture, and three concrete opportunities for Dasharo
          and coreboot.'
cover: /covers/secure-app.jpg
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

<!-- DRAFT: This post follows the SemiAnalysis content creation workflow.
     Step 4 (Human Rewrite) is next — use the cleaned transcript and this
     outline to write prose in your authentic voice.

     Source transcript: /tmp/tc3028-cleaned-transcript.md
     Full outline: /tmp/tc3028-blog-outline.md
     Original slides: pages/tc3028/01_introductory_apple_t2.md
-->

## Introduction

<!-- ~500 words
HOOK: Apple published the most comprehensive platform security documentation
in the industry. Instead of dismissing it because it's closed-source, what if
we read it as a blueprint?

Key points to cover:
- Apple Platform Security Guide (Dec 2024) as state-of-the-art documentation
- Quote: "To make the most of the extensive security features built into our
  platforms, organizations are encouraged to review their IT and security
  policies..."
- 3mdeb's perspective: we care about pre-OS, so we read this through firmware
  engineer's lens
- Thesis: many of Apple's security patterns translate to x86+TPM and open
  firmware
- Secure-by-design, secure-by-default mindset (compare to OpenBSD)

FROM TRANSCRIPT:
> From my perspective, this document — the Apple Platform Security Guide —
> represents state-of-the-art documentation of platform security. I think it's
> really great from the perspective of explaining to the community what the
> security features are and how those are used.
>
> In this article, we would like to endorse Apple's approach of providing such
> documentation and provide great explanation of features. Despite the fact that
> many people in the community will say it's still closed source, still
> proprietary, still not transparent and not auditable.
-->

## What is Apple T2 and Why Should Firmware Engineers Care?

<!-- ~600 words
Key points:
- T2 = A10 chip embedded in Intel Macs
- Same Secure Enclave as iPhone — understanding T2 = understanding iPhone boot
- T2 was the last Mac to offer true boot freedom ("No Security" mode)
- Two processors: ARMv8.1-A (64-bit AP) + ARMv7-A (32-bit SEP)
- Own AES engine, Secure Nonvolatile Storage, Memory Protection Engine
- T2 communicates with Intel CPU over eSPI
- SSD encryption on the fly (can't move SSD between machines)

Secure Enclave Architecture:
- Application Processor with OTP (Apple Root CA)
- NAND flash controller through AES engine
- Memory controller → Memory Protection Engine
- SE subsystem: RNG, AES, UID/GID fuses, PKA, SEP running sepOS (L4)
- I²C bus to Secure Nonvolatile Storage (anti-replay, entropy, keys)

FROM TRANSCRIPT:
> So T2 is essentially an A10 chip embedded in the Mac. This is important
> because Apple's documentation states that T2 boot is analogous to how
> A-series chips boot securely. Learning about T2 and understanding how T2
> works — we can assume that newer processors boot in a similar manner.
-->

## How Apple Boots: Two Parallel Chains of Trust

<!-- ~1,000 words
AP Boot Chain:
- Boot ROM (SecureROM): immutable, burned into silicon, contains Apple Root CA
- No ASLR in boot chain (deterministic memory layout)
- A10+ eliminated LLB stage (direct Boot ROM → iBoot)
- x86 comparison: Boot ROM ≈ Intel Boot Guard ACM

iBoot:
- First mutable code in boot chain
- Hardware init, memory controller, display, storage
- Updates Boot Progress Registers
- Coordinates Secure Enclave (assigns memory, sends sepOS)
- Loads and verifies kernel
- Apple modified C compiler for iBoot (iOS 14+) — mitigating type confusion,
  use-after-free
- iBoot CVEs fixable via software updates (unlike Boot ROM)

SE Boot Chain (parallel):
- SE Boot ROM → SCIP → Memory Protection Engine → sepOS
- Independent root of trust
- Both chains work simultaneously (boot performance)

FROM TRANSCRIPT:
> Key takeaways from this diagram: Execution happens in parallel. After iBoot
> sends sepOS, both chains work simultaneously. Kernel load doesn't wait for
> the Secure Enclave to finish. This parallelism is important for boot
> performance.
-->

## Boot Progress Registers: Data Access by Boot State

<!-- ~600 words
Three boot modes:
- DFU: Boot ROM level, all data locked
- Recovery: iBoot level, Class A/B/C locked
- Normal: full access after user auth

BPR tells Secure Enclave which mode → SE decides key release
Hardware-enforced, software can't override

Data Protection Classes:
- Class A (Complete Protection): key discarded 10s after lock
- Class B (Protected Unless Open): ECDH trick for background writes
- Class C (Protected Until First Auth): available until reboot

x86 comparison: TPM PCR values serve similar function — boot state determines
accessible secrets. PCR-based LUKS sealing is the direct analog.

FROM TRANSCRIPT:
> Boot Progress Registers tell the Secure Enclave which mode we are in, and
> the Secure Enclave decides based on that which encryption keys should be
> released — determining which class of data will be available.
-->

## What Can Go Wrong: The checkm8 Story

<!-- ~800 words
CVE-2019-8900: use-after-free in DFU USB handler
- DFU handles USB directly, no OS, no ASLR
- USB abort freed IO buffer but didn't clear global pointer → dangling pointer
- Classical C memory safety bug
- Heap feng shui: ~20-30 USB operations to position controlled data
- Physical USB access required

Impact:
- Boot ROM dump, Secure Enclave protocol analysis
- Persistent jailbreak surviving OS updates
- Unfixable: mask ROM burned into silicon

Why it matters for open source firmware:
- Same class of bugs exists in UEFI DFU/recovery paths
- USB stack in EDK2 is attack surface
- Memory safety in C firmware is the fundamental problem
- Hardware root of trust is only as good as its implementation

Platform Mitigations (A12+):
- Heap hardening, pointer hijacking prevention
- APRR (code injection prevention)
- Improved memory safety via compiler toolchain

FROM TRANSCRIPT:
> By carefully sequencing allocations and frees, they position a controlled
> data structure containing a callback function pointer at the exact address
> where the freed IO buffer was located. Then when Boot ROM uses the dangling
> buffer pointer and calls its callback, it executes attacker-controlled code.
-->

## Anti-Rollback: Personalized Signatures vs TPM Sealing

<!-- ~600 words
Traditional approach fails: global signature + version counter (can be reset)

Apple's solution:
- ECID (hardware chip ID) + server-side signing = device-bound signatures
- Can't transplant between devices, can't install older firmware
- Server checks security epoch before signing
- Requires network for full-security updates

Sealed Key Protection (SKP):
- Key derived from UID + hash of running sepOS
- Binds secrets to hardware identity + exact software version

x86 equivalent:
- EK as device unique ID (TPM)
- PCR values as boot chain measurements
- TPM_Seal with PCR0 firmware policy = analogous implementation
- Can be self-hosted (not vendor-dependent)

FROM TRANSCRIPT:
> We could use TPM_Seal with PCR0 firmware policy, and then say that key would
> only be unsealed when the boot measurements match the sealed configuration.
> This would be an analogous implementation to the Apple one.
-->

## Intel Mac with T2: Where Apple Security Meets x86

<!-- ~600 words
T2 boot flow:
1. T2 powers on → Boot ROM → iBoot → bridgeOS
2. bridgeOS reads UEFI from SPI flash, verifies
3. Memory-mapped over eSPI to Intel CPU
4. Intel CPU released from reset, fetches verified UEFI over eSPI
5. No Intel Boot Guard — T2 is entire root of trust

Secure Boot Policy (user-facing innovation):
- Full Security: ECID-bound, network required, current macOS only
- Medium Security: global Apple signatures, allows older macOS
- No Security: disables Intel CPU verification (T2 still secure-boots)
- M1 removed "No Security" — T2 was last for true boot freedom

Lesson for open firmware: users deserve security policy choices

FROM TRANSCRIPT:
> If we consider that in the context of open source firmware — we don't have
> these kinds of user-facing controls, and that's a significant gap.
-->

## Three Opportunities for Open Source Firmware

<!-- ~1,500 words — THIS IS THE PAYOFF SECTION -->

### Opportunity 1: PCR-Gated Operations

<!-- Apple's BPR → our TPM PCRs, used for more than disk encryption:

1. Firmware update gating: warn if PCRs unexpected before update
   (DTS or capsule update checks PCR state)

2. PCR display + attestation API:
   - BIOS setup shows PCR values
   - QR code → verify against known-good database
   - Like GrapheneOS Auditor, but for firmware

3. Enterprise fleet attestation:
   - Backend introspection for device fleet state
   - Agentic AI context: VMs with attestation via confidential computing

4. Forward sealing for updates:
   - Before update: compute expected PCR for new firmware
   - Seal keys to current + future PCR values
   - After update: old seal fails, new seal works
   - Recovery via PIN or additional policy

5. Qubes boot mode integration:
   - PCR policy determines VM access (network, USB, sensitive data)
   - S0ix threat model: standby = network active

FROM TRANSCRIPT:
> The innovation is using PCR state to gate other operations beyond disk
> encryption — especially firmware update and remote attestation.
-->

### Opportunity 2: Loaded Image Protection

<!-- Apple's KIP/SCIP → UEFI DXE image protection:

- Write-protected PE sections (already in EDK2)
- EndOfDxe/SmmReadyToLock as lock point
- CR0 Write Protect + page table lock
- Opportunity: make this mandatory, not optional

FROM TRANSCRIPT:
> In UEFI, there is the EndOfDxe and SmmReadyToLock signal sent at the end of
> the configuration phase — after this, image sections marked as code become
> read-only. This is used in all implementations of UEFI BIOS.
-->

### Opportunity 3: Self-Hosted Signing with Device Identity

<!-- Apple's ECID signing → self-hosted attestation server:

- Organizations run own signing server
- Device-bound signatures without vendor lock-in
- TPM EK as device identity anchor
- Firmware update validation against organizational policy

FROM TRANSCRIPT:
> The design pattern is not unique to Apple — it's common practice. Many
> companies use this approach. This is essentially a form of attestation —
> online verification of build identity.
-->

## Conclusion

<!-- ~400 words
Apple's advantages: custom silicon, vertical integration, closed ecosystem.
But the principles translate:

| Apple | Open Source Equivalent |
|-------|----------------------|
| Boot ROM | Intel Boot Guard / measured boot |
| Chain of trust | Verified boot with TPM |
| BPR / SKP | PCR-based sealing and gating |
| Personalized signatures | Remote attestation + forward sealing |
| Secure Enclave | TPM + SMM (with better isolation) |

Call to action:
- Read Apple Platform Security Guide: https://support.apple.com/guide/security/
- Try Dasharo with measured boot
- Contribute to open implementations

FROM TRANSCRIPT:
> The key insight is that Apple's integrated approach provides mandatory,
> consistent hardware enforcement. The question is: what can the open source
> firmware ecosystem learn from that?
-->

## Summary

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to
[sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).

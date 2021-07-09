---
post_title: fTPM vs dTPM
author: Bartek Pastudzki
layout: post
published: false
post_date: 2021-07-09 15:00:00

tags:
        -TPM
        -firmware
        -hardware
categories:
        -security
---

# Intro

One of the most important topics in firmware security is TPM. You may have just
heard about them in news recently as Microsoft started requiring a TPM 2.0 for
Windows 11. This has been a source of great confusion as to why it's so
important, some have even theorized it's for DRM and restricting user control.
In this article we'll learn what TPMs are and we'll explore the differences
between the most common implementations: fTPM and dTPM.

# What's a TPM?

TPMs aren't actually all that new. The first implementation of a dedicated chip
resembling a TPM debuted in the IBM ThinkPad T23 in 2001, and implemented
features like password storage and asymmetric cryptography functions. It wasn't
much more functional than a smartcard.

In 2003, IBM joined up with various companies including HP, Intel and Microsoft
and established the Trusted Coputing Group, or TCG for short. The TCG defined
the TPM standard, which has continuously evolved over the years, picking up
adoption especially in enterprise and business use.

The TPM's primary functions are to store secrets in isolation from the host OS
and verify system integrity by storing measurements of the boot proces in PCR
registers. Without going into too much detail, it can verify the integrity of
every component in the boot process and allows the establishment of a trusted
computing platform.

While TPMs began as dedicated security chips, as they picked up adoption,
silicon vendors started implementing them in chipsets and eventually in firmware.
A firmware based implementation is called a Firmware TPM, or fTPM for short,
runs in the CPU's trusted execution environment and is drastically cheaper to
implement than a dedicated chip. A hardware based implementation in a dedicated
chip is now called Discrete TPM, or dTPM.

You may have also heard about sTPM, a software implementation of TPM running in
userspace, but as it's not at all isolated from the host OS (without the use of
technologies like Intel SGX, at least) it doesn't offer any real security
benefits. It's mostly just useful for development purposes.

# HW vs SW

It would be easy to say that dTPM is more secure because it's a dedicated
device, but it's not that simple and what works best for you depends on your
specific threat model. A discrete TPM is designed to be tamper resistant,
provides a higher degree of isolation, and can be certified by TCG (in fact
most of them are). It is, however, slower than other implementations
(though that is by design) and is commonly connected to the LPC bus which can be
sniffed - an issue absent in fTPMs by the virtue of being contained entirely
within the SoC. Side channel attacks are also potentially easier to perform when
the TPM is located on a separate chip.

On the other hand, fTPMs present a different set of security considerations: for
example if the firmware is writable for an attacker it could be replaced with a
backdoored version. A firmware verification scheme like Intel Boot Guard protects
against this for the most part, however, an attacker may still be able to load
a vulnerable firmware version fTPMs are also not TCG cerfified, and share the
attack surface with management coprocessors like Intel ME and AMD PSP.

On the other hand, fTPMs are much less vulnerable to sniffing by being contained
in the CPU package completely. To perform such an attack, one would need
to gain JTAG access or even decap the CPU.

We also have to consider the particular functions provided by TPM. For example,
how is key storage implemented? In fTPMs, they can be stored in the SPI chip,
while discrete TPMs have their own NVRAM.
On different platforms, we have different security facilities, the most
popular are TXT and SGX for Intel, TrustZone for ARM, and Memory Guard for AMD.
They can encrypt the memory, which is crucial to prevent leaking fTPM keys.

That's why if we want to reason about fTPM security we have to consider all
security facilities on the platform. There are few documents which do such
considerations: [on ARM platform](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/msr-tr-2015-84.pdf),
[another](https://www.usenix.org/system/files/conference/usenixsecurity16/sec16_paper_raj.pdf).
The documentation of platform features may be useful to estimate which could
be useful: [TXT](https://www.intel.com/content/www/us/en/architecture-and-technology/trusted-execution-technology/trusted-execution-technology-security-paper.html), [SGX](https://software.intel.com/sites/default/files/managed/48/88/329298-002.pdf),
[TPM in short](https://trustedcomputinggroup.org/wp-content/uploads/TPM-2.0-A-Brief-Introduction.pdf),
[TPM spec](https://trustedcomputinggroup.org/tpm-library-specification/). We
should also always think what do we need fTPM for, some of its shortcomings
may be irrelevant if it doesn't affect functions we use.

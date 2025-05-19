---
title: fTPM vs dTPM
abstract: "An introduction to TPMs.
           Let's explore the differences between common implementations of TPMs
           and how they might matter to you."
cover: /covers/tpm2.png
author:
    - michal.kopec
layout: post
published: true
date: 2021-10-08
archives: "2021"

tags:
  - tpm
categories:
  - Security
  - Hardware
  - Firmware
---

## Intro

One of the most important topics in firmware security is TPM. You may have just
heard about them in news recently as Microsoft started requiring a TPM 2.0 for
Windows 11. This has been a source of great confusion as to why it's so
important, some have even theorized it's for DRM and restricting user control.
In this article, we'll learn what TPMs are and we'll explore the differences
between the most common implementations: fTPM and dTPM.

## What's a TPM?

TPMs aren't actually all that new. The first implementation of a dedicated chip
resembling a TPM debuted in the IBM ThinkPad T23 in 2001 and implemented
features like password storage and asymmetric cryptography functions. It wasn't
much more functional than a smartcard.

In 2003, IBM joined up with various companies including HP, Intel, and Microsoft
and established the Trusted Computing Platform Alliance (TCPA), later known as
the Trusted Computing Group (TCG). The TCPA defined the TPM standard, which has
continuously evolved over the years, picking up adoption especially in
enterprise and business use.

The TPM's primary functions are to store secrets in isolation from the host OS
and verify system integrity by storing measurements of the boot process in PCR
registers. Without going into too much detail, it can verify the integrity of
every component in the boot process and allows the establishment of a trusted
computing platform.

While TPMs began as dedicated security chips, as they picked up adoption,
silicon vendors started implementing them in chipsets and eventually in
firmware. A firmware-based implementation is commonly called a Firmware TPM, or
fTPM for short, runs in the CPU's trusted execution environment, doesn't take up
any extra space on the board which is great for space-constrained boards, and is
drastically cheaper to implement than a dedicated chip. A hardware-based
implementation in a discrete package is now called Discrete TPM, or dTPM.

You may have also heard about sTPM, a software implementation of TPM running in
userspace, but as it's not at all isolated from the host OS (without the use of
technologies like Intel SGX, at least) it's mostly useful for development and
for virtualization purposes as a vTPM. vTPM is an sTPM providing functionality
to virtual machines, and it depends on the hypervisor for adequate isolation.

## HW vs FW

One might be inclined to say that dTPM is more secure because it's a dedicated
device, but it's not that simple and what will work best for you depends on a
variety of factors. A discrete TPM is designed to be tamper-resistant, provides
a higher degree of isolation, and can be certified by TCG (in fact most of them
are). It is, however, slower than other implementations (though that is by
design) and is commonly connected to the LPC bus which can be sniffed.
Side-channel attacks are also potentially easier to perform when the TPM is
located on a separate chip. It's worth mentioning here that the TPM
specification defines a standard for transport encryption, but it is rarely
used.

fTPMs present a different set of security considerations: for example if the
firmware is writable for an attacker it could be replaced with a vulnerable
version. To prevent this, countermeasures such as firmware signing and fTPM
clear on rollback need to be implemented. fTPMs also generally aren't certified
as vendors don't generally let certifying agencies look at their sources.
Lastly, fTPMs may share the attack surface with management coprocessors like
Intel ME and AMD PSP.

On the other hand, fTPMs are much less vulnerable to sniffing by being contained
within the CPU package. There are no exposed connections between the TPM and CPU
like there is with a dTPM, which is connected to the LPC bus, so sniffing keys
would require debugging the CPU with JTAG or even physically decapping it to
access internal traces.

We also have to consider the particular functions provided by TPM. For example,
how is secure storage implemented? dTPMs have tamper-resistant NVRAM, while with
fTPMs there are a couple of possibilities:

- TrustZone relies on trusted storage provisions in eMMC controllers
- Intel PTT can store secrets in an encrypted portion of the SPI flash

Then we have to consider the memory security facilities:

- ARM TrustZone defines a separate region for the "normal world" in which the
  usual software is run and "secure world" which runs security-critical code
- Intel SGX can be used to define protected, encrypted regions (enclaves) with
  restricted access
- AMD has memory encryption and the fTPM itself runs on an ARM coprocessor which
  implements TrustZone

## Summary

Clearly, the answer to the question of whether dTPM or fTPM is more secure is
not as clear-cut as one may think, and we have to take into account a lot of
variables. If you want to explore this topic further, here are some documents to
get you started:

- [fTPM: A Firmware-based TPM 2.0
  Implementation](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/msr-tr-2015-84.pdf),
- [fTPM: A Software-Only Implementation of a TPM
  Chip](https://www.usenix.org/system/files/conference/usenixsecurity16/sec16_paper_raj.pdf).
- [Intel® Trusted Execution Technology: White
  Paper](https://web.archive.org/web/20220317121453/https://www.intel.com/content/www/us/en/architecture-and-technology/trusted-execution-technology/trusted-execution-technology-security-paper.html)
- [Trusted Platform Module (TPM) 2.0: A Brief
  Introduction](https://trustedcomputinggroup.org/wp-content/uploads/TPM-2.0-A-Brief-Introduction.pdf),
- [TPM 2.0 Library
  Specification](https://trustedcomputinggroup.org/tpm-library-specification/),
- [lpnTPM: An Open Source TPM implementation](https://nlnet.nl/project/lpnTPM/),
- [Qubes OS & 3mdeb minisummit 2020: SRTM for Qubes OS
  VMS](https://www.youtube.com/watch?v=Eip5Rts6S2I),
- [Qubes OS & 3mdeb minisummit 2020: D-RTM for Qubes OS
  VMs](https://www.youtube.com/watch?v=pZF-jyJWTE4),
- [Qubes OS-3mdeb mini-summit 2021: Day 1 - S-RTM and Secure Boot for
  VMs](https://www.youtube.com/watch?v=y3V_V0Vllas&t=11447s).

---

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our
newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

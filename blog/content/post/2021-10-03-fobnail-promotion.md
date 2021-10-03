---
title: Fobnail vs other boot security projects
abstract: 'Have you ever thought about securing the boot process of your
           computer? No? This post will compare the available open source boot
           process hardening projects and explain the importance of signing and
           protection the software/operating system you launch. You will also
           get to know how the boot process may be secured even further and with
           the incoming Fobnail security token.'
cover: /covers/usb_token.png
author: michal.zygowski
layout: post
published: true
date: 2021-10-03
archives: "2021"

tags:
  - fobnail
  - firmware
  - security
categories:
  - Firmware
  - Security

---

# Introduction

System boot security has been gaining more and more attention and importance
due to forever increasing complexity of attacks on the software and firmware.
Firmware vendors are incorporating more and more security features into the
BIOS and UEFI, but let's be honest:

- due to UEFI complexity it has been often proved that the implementation of
  such features may be buggy and provide wider attacks surface, e.g.
  BootGuardDxe flaw presented by Alex Matrosov at [BlackHat USA 2017](https://www.blackhat.com/docs/us-17/wednesday/us-17-Matrosov-Betraying-The-BIOS-Where-The-Guardians-Of-The-BIOS-Are-Failing.pdf)
- even if the firmware offers high-level security features it is still pretty
  hard to leverage it out-of-the-box in a user-friendly manner

Because of the above reasons many entities fail to correctly secure the boot
process and protects the consumers hardware from the attackers. That is why
companies like Microsoft are pushing the silicon, hardware and firmware vendors
to enhance the platform security by establishing [Secure Core PC](https://www.microsoft.com/en-us/windowsforbusiness/windows10-secured-core-computers)
standard and for example requiring the TPM in Windows 11. For example one of
the requirements of the Secure Core PC is the use of Dynamic Root of Trust for
Measurement technology in order to measure the operating system software in the
processor trusted execution environment impenetrable from external attack
vectors. With such measurements one may use remote attestation to ensure the
software that is running on the machine has not been tampered with, without
relying on the possibly buggy firmware. What is more important Secured Core PCs
aim to provide such high level security out-of-the-box as much as possible.
This is very important because the security is still hard to achieve in an
easy and straightforward way. To eliminate such hardships and obstacles open
source projects emerged to simplify whole process of boot process hardening:

- [safeboot](https://safeboot.dev/) - leverages firmware Static Root of Trust
  for Measurement to secure the boot process of Linux OS with UEFI Secure Boot
- [heads](https://osresearch.net/) - leverages firmware Static Root of Trust
  for Measurement and Linux kernel as a part of open source boot firmware to
  perform verification of the software components of the operating system with
  the helps of TPM and USB security tokens. Thanks to open source boot firmware
  the risk of buggy firmware implementation is significantly reduced.

But do those projects and solve all the problems? What to do with those
measurements? The short answer is "remote attestation". There is a need of a
trusted entity that will tell the machine owner that the measured software has
the approved cryptographic footprints (measurements). At 3mdeb we aim to create
an open hardware USB security token called [Fobnail](https://fobnail.3mdeb.com/)
which will act as a axiomatically trusted device and provide attestation
services to avoid the use of network and potentially untrusted attestation
servers or man-in-the-middle network attacks. The project became possible thanks
to the sponsorship of the [NLnet Foundation](https://nlnet.nl/project/Fobnail/).

## safeboot

Before we start explaining how Fobnail may improve the security of the boot
process lets' review and compare the open source boot process hardening
projects starting with.

First of all safeboot is a set of scripts and wrappers that help automate and
speed up provisioning of the machine to leverage TPM and UEFI Secure Boot full
potential. In short it packs Linux kernel, initial ramdisk (with safeboot
scripts) and commandline parameters into a single EFI file and creates two
copies of it for normal boot flow and recovery. Additionally the root
filesystem is being encrypted and the password is being sealed to TPM and
Static Root of Trust measurements. The boot flow is presented on the diagram
below:

![](/img/safeboot-boot-flow.png)

So how this works? When UEFI firmware finishes the platform initialization and
is ready to boot the OS it executes EFI file with the packed Linux kernel and
initial ramdisk, but this file is being signed with custom Secure Boot keys
generated during the provisioning process. During the provisioning phase these
keys' certificates are enrolled into the firmware and the private parts are
migrated to a USB HSM key in order to protect the key from leakage. This USB
key is later used for signing the EFI files used in the boot process. Moreover
the operating system root filesystem is protected with disk encryption. The
decryption password is being sealed inside TPM to the pre-calculated
measurements of the firmware and the packed Linux+ramdisk in an EFI file. So
basically if the firmware and Linux components have not been tampered with, the
decryption password will be unsealed automatically, if not then you are forced
to boot recovery mode and resign, recalculate measurements and reseal the
decryption password (which is stored on some backup drive for example). There
are of course safety measures that do not let unseal the decryption password
second time, by extending one of TPM's PCRs once again (the unsealing policy
will fail and the secret is not unsealed by TPM/)

However the whole security model is as secure as the firmware itself. If the
firmware get's compromised or tampered with, it may fake the firmware
measurements and keep a persistent malware module in the firmware storage. That
is why a strong Static Core Root of Trust is needed like Intel Boot Guard, etc.
But where all this leads us? Well at the end of the boot process of course we
would like to attest the firmware and software by sending a set of platform
integrity measurements to the attestation server. But is the attestation server
or the network connection secure? What should one do without a network
connection? The Fobnail USB token can answer all these question, but we will
discuss it later in the post.

## heads

heads is a project that wraps up the build system for the firmware and Linux
kernel together in order to produce a single binary with open source firmware
with hardened Linux kernel containing boot security utilities. The only
supported open source firmware implementation is currently
[coreboot](https://coreboot.org/). Let's have a look at the example boot flow
with the use of USB security token without a pre-boot firmware verification
technology:

![](/img/boot_flow_heads.png)

Similarly as in the safeboot case, the firmware is doing measurements of the
executed components and extends the TPM PCRs. In the coreboot's last stage the
heads Linux kernel is launched where all the checks and decisions are made.
heads uses multiple keys and secrets to protect the machine, e.g. TPM TOTP
secret, LUKS encryption key and disk encryption key. We won't go into much
details how each key is used, what is really important is how TPM TOTP is
related to the firmware. TPM TOTP is a one-time 6 digit code generated from a
secret and a current timestamp. Such a code is typically only valid for 30 or
60 seconds, then a new one is generated with newer timestamp. Alternatively a
HOTP scenario may be used where USB token verifies that its secret and host's
secret is the same and the counters on both sides are the equal (incremented
each time the secret is compared). heads unlocks the secret if and only if the
firmware measurements match the policy to which the secret has been sealed in
TPM. IF all checks are passed and keys are unsealed, the disk is decrypted and
the target operating system kernel is kexeced. Now imagine he malicious
firmware replacement if the bootblock is not protected (so there is no Core
Root of Trust to verify other firmware components):

![](/img/boot_flow_heads_compromised.png)

Malicious firmware has performed the measurement replay attack, by extending TPM
PCRs with the same values as trusted firmware would. In such case the TOTP/HOTP
secret will still be unsealed without the user knowing that the firmware has
been tampered with (TOTP/HOTP does not detect tampering in such case). This is
potentially dangerous since there may be a malware installed on the firmware
storage. One would need a protection on the silicon level like Boot Guard to
ensure that the firmware has really changed.

Instead of trusting the firmware to do the job right, one could simply use
Dynamic Root of Trust for Measurement to let the silicon create the secure
enclave and measure the operating system components. Only based on such
securely created measurements we may be sure (by performing remote attestation)
that the software we want to run is correct. But again the risk of untrusted
network connection or attestation server arises.

## Fobnail

Summing it up we have uncovered a few problems with the current boot hardening
projects and attestation:

- firmware not always may be trusted, usage of D-RTM is highly recommended, but
  how to securely attest the platform state? TOTP/HOTP is not the best case
  where the secret can be unsealed just with replaying the measurements
- attestation server or network connection may not be always trusted, sometimes
  network connection may not be even available, how to perform attestation in
  such case?

The Fobnail Token is a tiny open-source hardware USB device that provides a
means for a user/administrator/enterprise to determine the integrity of a
system. To make this determination, Fobnail functions as an attestor capable of
validating attestation assertions made by the system. As an independent device,
Fobnail provides a high degree of assurance that an infected system cannot
influence Fobnail as it inspects the attestations made by the system. The
architecture is based on the IEFT specification - Remote ATtestation
ProcedureS ([RATS](https://datatracker.ietf.org/doc/draft-ietf-rats-architecture/))
and the attestation procedure on Reference Interaction Model for
Challenge-Response-based Remote Attestation ([CHARRA](https://tools.ietf.org/id/draft-birkholz-rats-reference-interaction-model-00.html)).

So in short, the main principles of Fobnail are:

- to make the attestation as simple as possible (e.g. by using LED indicators
  to inform a user about the decision of trustworthiness)
- act as the axiomatically trusted device (an [iTurtle](https://www.usenix.org/legacy/event/hotsec07/tech/full_papers/mccune/mccune_html/index.html))
  for the attestation process
- provide attestation services without network connection

So how does it improve situation for the mentioned projects? As long as the
firmware is protected the risk is not so high that the components have been
tampered with. But the attestation process over the network may be hijacked or
return untrustworthy result. By using fobnail, whole attestation and decision
process is moved to the tiny USB device so that the user can confirm the result
visually. This solves the problem of untrusted networks or attestation servers.

Secondly if we do not trust that the firmware is bug-free and provides reliable
measurements one may use D-RTM when booting the target Linux kernel and perform
the attestation based on D-TM measurements with Fobnail.

Thirdly when we look at TOTP/HOTP the whole decision process of secret
unsealing is done on the platform, also the platform is responsible to display
or send the 6 digit code to the display or USB token. This creates a potential
risk that the code has been faked and the measurements aren't really reliable.
Fobnail removes such risk by moving the platform state evaluation on the token
side. Before the Fobnail token becomes usable it must be provisioned first with:

- Reference Integrity Measurement (RIM) Database (approved set of platform
  measurements)
- Attestation Policy Database (decision policies used to evaluate the
  trustworthiness of the attestation data)
- Attestation Protected Object (optional secret data that is going to be
  unsealed on successful attestation process)
- Identity and encryption certificates

So Fobnail knows about all the known good platform states. The host
responsibility in the attestation process is to provide the TPM quote (set of
platform integrity measurements, event logs, etc.) signed by the attestation
key to the token for evaluation. Then the decision is returned to the host and
indicated to the platform owner with a physical or digital response. Fobnail is
also a flexible device which allows to perform the attestation of multiple
devices (by using multiple RIMs and policies).

As you can see the decision process is now done in the secure environment
unlike the example heads boot flow. This doesn't however resolve the problem of
reliable measurements if the Static Root of Trust measurements are used. THere
is still the risk that the measurement have been faked because firmware has
been tampered with or was not protected. With the help comes the D-RTM. Imagine
compromised heads boot flow but this time the (Nitrokey) USB token is compliant
with Fobnail architecture:

![](/img/boot_flow_heads_fobnail_compromised.png)

As you can see the firmware measurements may be replayed if the firmware is not
protected and we cannot avoid this, but still we may use D-RTM to securely
perform the measurements of operating system components and use these to
perform attestation to get a trustworthy decision about platform software
state.

## Summary

Fobnail token is the future of the remote attestation attestation. This project
funded by the NLnet is only the beginning. We believe in open source and by
making the Fobnail open hardware and open software we hope it may be improved
by community and integrated by many USB security token vendors. Currently we
are looking for early adopters in area of:

- security hardware companies (USB token providers)
- network appliance manufacturers
- laptop OEMs
- public and private cloud providers

which would like to integrate or offer Fobnail as a part of their
products/services. In return 3mdeb offers commercial support and associated
marketing for the adopters. If you think Fobnail may enhance your products or
security of your devices do not hesitate to contact us. Feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

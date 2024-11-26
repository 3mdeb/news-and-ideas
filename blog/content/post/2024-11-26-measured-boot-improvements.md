---
title: Improving measured boot and TPM support in Dasharo
abstract: 'An overview of recent improvements to TPM and measured boot
 support in open-source firmware, coreboot and Dasharo.'
cover: /covers/tpm2.png
author: michal.zygowski
layout: post
published: true
date: 2024-11-26
archives: "2024"

tags:
 - dasharo
 - coreboot
 - edk2
 - tpm
categories:
 - Firmware
 - Security
---

## Introduction

Firmware security is a complex topic. The industry has come up with many ideas
and mechanisms to protect the devices from attacks and help detect if
something is wrong. One of such mechanisms is measured boot. Measured boot
leverages cryptography to compute hashes of executed firmware components and
save those hashes in a secure device serving as a Root of Trust for Storage. A
typical example of such a secure device is the Trusted Platform Module used on
many personal computers nowadays. This blog post will describe how we improve
the measured boot process in the open-source firmware.

The article is divided into a few sections:

- [Unifying TPM support in coreboot](#unifying-tpm-support-in-coreboot)
- [Adding TCG-compliant event logging to coreboot](#adding-tcg-compliant-event-logging-to-coreboot)
- [TPM event log from coreboot to payload](#tpm-event-log-from-coreboot-to-payload)

## Unifying TPM support in coreboot

Not so long ago, coreboot supported only one TPM type per build. Say, you have
a switchable TPM1.2 and TPM2.0 or dTPM 1.2 and fTPM 2.0. Using one or the
other requires different drivers, but the firmware can't be easily changed.
The way the TPM drivers were written in coreboot, did not allow the TPM 1.2
and TPM 2.0 API to coexist in a single build. So before we approached
improving the measured boot, we had to make TPM support in coreboot more
flexible. We have sent and merged a total of 19 (15 if not counting reverted
commits and their reverts) patches to upstream coreboot, which refactor the
TPM drivers to allow probing for the TPM device and hooking up the correct
driver and API to communicate with it.

The list of the patches can be found
[here](https://review.coreboot.org/q/topic:tpm-unification). A short
statistic of total lines of code changed (reverted commits and their
respected reverts excluded):

- 971 deletions
- 1155 additions

Having the dynamic support for multiple TPM families opened the door to a
flexible TPM event log compliant with TCG specification.

## Adding TCG-compliant event logging to coreboot

There is no point in the event log if the OS and software cannot
use/understand it. Trusted Computing Group (TCG) has defined the format of the
TPM event log for both TPM1.2 and TPM2.0 families. However, coreboot had its
[own format of
logging](https://doc.coreboot.org/security/vboot/measured_boot.html#coreboot-specific-format)
the measurements since the beginning of measured boot support in coreboot. To
extract the value from the measured boot in coreboot, it was necessary to make
the event logging compliant with the specifications used throughout the whole
computer industry. We have sent and merged a total of 10 patches to upstream
coreboot, adding the TCG-compliant event logging to coreboot's TPM drivers.
There were also some inconsistencies in naming the event log, e.g. the term
TCPA, which refers to the TPM 1.2 ACPI table or TPM1.2 event log, was used
throughout the whole coreboot project to refer to the coreboot's custom TPM
event log. Now the event log format can be selected during build time between:

- coreboot-specific format
- TCG TPM1.2 format
- TCG TPM2.0 format

The list of the patches can be found
[here](https://review.coreboot.org/q/topic:tpm-std-logs). A short
statistic of total lines of code changed:

- 360 deletions
- 1675 additions

Having the proper TPM event logging in coreboot made it easier to be parsed
and used by the coreboot payloads.

## TPM event log from coreboot to payload

### Problem statement

coreboot alone does not create a usable solution. It focuses merely on proper
silicon initialization. The functionality to boot an OS is left to the
application called payload. Payload is a piece of software coreboot hands over
the execution to, after it is done with all its jobs to initialize the silicon
and platform. It may take many forms:

- [SeaBIOS](https://www.seabios.org/SeaBIOS) - for legacy BIOS compatibility
- Linux payload/LinuxBoot/heads - a Linux kernel with optional initrd launched
 directly by coreboot
- EDKII UEFI Payload - a payload based on [TianoCore
 EDKII](https://github.com/tianocore/edk2) providing UEFI compatibility
- [u-boot](https://github.com/u-boot/u-boot) - a bootloader more commonly used
 on ARM and embedded systems
- [GRUB2](https://www.gnu.org/software/grub/) - most common bootloader for
 Linux systems and not only Linux
- almost any ELF application

The flexibility in payload choice, however, brings certain problems. There are
still some disputes about the responsibility of coreboot and the
responsibility of payload. Specific actions made by coreboot may prevent the
payload from properly implementing particular features, e.g., locking the
chipset. Sometimes, one may want to skip locking the chipset to allow the
firmware to be updated by the payload (for example, see
[heads](https://github.com/linuxboot/heads/pull/1818)). There are more
situations where some kind of interface between the coreboot and the payload
must be established. Passing the TPM event log is not different in that case
but with a slight difference - the event log alone is just a chunk of memory
that the payload can read and parse however they like. Still, each payload
would have to do the same: interpret coreboot's custom event log to create a
single and complete event log from the reset vector to the OS. The amount of
code duplication it would create is unthinkable. Thankfully, we have already
implemented the TCG standardized event logging, which helps a bit with the
portability of the parsing.

In this article, I will show how we achieved the complete integrity of the TPM
event log across the whole boot process of open-source firmware based on
coreboot and TianoCore EDKII UEFI Payload in Dasharo.

### Solution

We already have many pieces prepared earlier, like unified TPM support and a
TCG-compliant event log. The work required to pass the vent log from coreboot
is not that huge, as EDKII already knows the TCG event log format, so all we
have to do is process each event and create a HandOffBlock (HOB) containing
the measurements made by stages preceding UEFI DXE (Driver Execution
Environment). Using HOBs is a standard mechanism of passing information from
the pre-DXE environment to DXE, where the drivers responsible for publishing
the event log to the OS reside. It is done in [this Pull
Request](https://github.com/Dasharo/edk2/pull/139).

Of course, this is not the end of modifications. Depending on the payload,
some glue may also be required on the coreboot side. We have to teach coreboot
not to publish TPM ACPI tables (TCPA and TPM2) because they contain the
address of the TPM event log in the memory. This task is now left to the
payload, which publishes the respective TPM ACPI table with its own, combined
TPM event log. It is achieved in the [previously linked Pull Request on EDKII
side](https://github.com/Dasharo/edk2/pull/139) and also on [coreboot
side](https://github.com/Dasharo/coreboot/pull/517) (some of the changes here
are already upstream). Besides the TPM ACPI table, coreboot creates an event
log using only one hashing algorithm:

- SHA1 - default for TPM1.2
- SHA256 - default for TPM2.0

TPM2.0 log format supports agile measurements, i.e. there may be multiple
measurements of the same component using multiple hashing algorithms. For
simplicity, coreboot uses only one currently. The choice of the hashing
algorithm must also be passed to the UEFI Payload. It is done by [specifying a
mask of supported hashing algorithms at UEFI Payload build
time](https://github.com/Dasharo/coreboot/pull/517/files#diff-58bb01776a00af5a5d61de00d6ea3008bcd67177fb7991fb41e8976c6b4d046a).

Now that all the pieces are in place, we can enjoy having a consistent and
complete TPM event log in the Dasharo, effectively solving the [issue of not
reproducible PCR2
value](https://github.com/Dasharo/dasharo-issues/issues/455).

## Summary

TPM event log integrity is an excellent achievement for our Dasharo team. While we
did an enormous work to improve it, there are still some aspects not covered
by current implementation:

1. What if the PCR banks are changed?

   The EDKII TPM2 setup menu allows changing PCR banks, effectively
   influencing what measurements (precisely hash algorithms used to measure
   firmware components) may be recorded in the TPM. coreboot is hardcoded to
   use only one hashing algorithm (fixed at build). It may result in PCR banks
   not being properly extended or the PCR values being entirely out of sync
   with the TPM event log. coreboot should query the TPM for currently enabled
   PCR banks and use all algorithms enabled at the time. That, of course, may
   have various implications:

    - Pre-RAM measurements are saved in Cache-as-RAM (CAR) memory, which is
      limited. Calculating more hashes will cause the CAR memory to shrink,
      which effectively limits the amount of cache for silicon initialization
      code. It may not be a big deal for modern platforms with big caches, but
      rather for the old ones.
    - coreboot supports only one algorithm in a single event log entry.
      Support for an agile format would have to be implemented.

2. What about pre-reset vector measurements like Boot Guard measured boot?

   Intel Boot Guard is a hardware Root of Trust feature that allows the
   firmware to be verified (and optionally measured) before the CPU is
   released from reset. It guarantees the integrity and reliable measurement
   of the critical early boot code. Currently, coreboot ignores the fact that
   something may have extended TPM PCRs with measurements before coreboot
   initialized the TPM or started logging measurements. Support for Boot
   Guard-created measurements must also be added to keep the PCR values
   consistent with the TPM event log.

Improving the security of the firmware is a process. What is important is to
take small steps and constantly move forward by improving things, one after
another. So, let's collaborate and work together on the safety of our systems.
Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with
us](https://calendly.com/3mdeb/consulting-remote-meeting) or drop us an email
at `contact<at>3mdeb<dot>com` to start unlocking the hidden benefits of your
hardware. And if you want to stay up-to-date on all things firmware security
and optimization, be sure to [sign up for our
newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6). Don't let
your hardware hold you back, work with 3mdeb to achieve more!

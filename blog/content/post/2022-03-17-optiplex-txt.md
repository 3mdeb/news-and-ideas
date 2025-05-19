---
title: A new source of trust for your platform - Dasharo with Intel TXT support
abstract: 'Do you trust the firmware on your system? No? Then this post is a
           must-read for you. Get to know what Intel Trusted Execution
           Technology (TXT) is and how it may help you securely measure and
           attest your operating system and software running on your machine.
           You will also hear about open-source implementation of Intel TXT
           for Ivy Bridge/Sandy Bridge platforms including Dell OptiPlex
           7010 / 9010.'
cover: /covers/dasharo-sygnet.svg
author: michal.zygowski
layout: post
published: true
date: 2022-03-17
archives: "2022"

tags:
  - coreboot
  - OptiPlex
  - DRTM
categories:
  - Firmware
  - Security

---

## Introduction

Intel Trusted Execution Technology is a feature of Intel CPUs and chipsets to
perform trusted measurement of the operating system software defined in Trusted
Computing Group
[D-RTM architecture specification](https://trustedcomputinggroup.org/wp-content/uploads/TCG_D-RTM_Architecture_v1-0_Published_06172013.pdf).
Dell OptiPlex 7010 / 9010 is Intel TXT capable. All you need is an Intel TXT
capable CPU (you may quickly check the Intel Trusted Execution Technology
capability on
[Intel ARK](https://ark.intel.com/content/www/us/en/ark.html#@Processors) for
your processor).

You may also want to read
[previous blog posts about Dell OptiPlex 7010 / 9010](https://blog.3mdeb.com/tags/optiplex/).

## DRTM rationale

Why do even Trusted Execution Technology and DRTM exist? First of all, we have
to start with the firmware, the inevitable piece of code initializing the CPU
and other hardware. Its responsibility is to prepare the platform to run an
operating system, but also to load it. So basically the owner of the firmware
has control over what operating system can be launched, and what is most
important, how it can be launched. By "how", one should understand whether the
operating system is launched as intended without any undesired actions, like
malware or spyware installation under the hood. In a case where the adversary
has malformed the firmware on your platform, they may install key loggers and
spying software to steal your data, passwords, etc. How to prevent that? How to
ensure the operating system software was not tampered with? The answer is DRTM
(Dynamic Root of Trust for Measurement). It can provide both load-time and
runtime integrity of the software. Load-time integrity is when a trusted entity,
i.e. an entity with assumed integrity takes an action to assess an entity being
loaded into memory before it is used. Runtime integrity is when a trusted entity
makes an assessment of another entity after that entity at an arbitrary time
after execution of the assessed entity has begun. Often the load-time integrity
of an operating system's user-space, or operating environment, is often confused
as runtime integrity since it is an integrity assessment of the "runtime"
software. Since the dynamic launch is not tied to a power event like the static
launch, this enables a dynamic launch to be initiated at any time and multiple
times during a single power life cycle.

## Intel TXT deep dive

The below diagram represents the typical boot flow of an Intel TXT enabled
machine with the measured launch.

![Intel TXT boot timeline](/img/txt_launch1.jpg)

> Source:
> *[A Practical Guide to TPM 2.0](https://link.springer.com/book/10.1007/978-1-4302-6584-9)*

First, the BIOS is starting execution from the reset vector. It is responsible
to initialize the Intel TXT to be used by the operating system bootloader. For
this purpose, it calls the BIOS ACM (Authenticated Code Module) to properly set
up Intel TXT. It must be noted that ACMs are signed by Intel and Intel CPU will
only execute ACMs signed by Intel key. The key hash is burned into CPUs and is
used to authenticate microcode updates and ACM signatures. Such measures ensure
only the authorized code can initialize Intel TXT, which prevents its
misconfiguration. When BIOS is done, it hands over the control to the operating
system bootloader. Now it is the bootloader's responsibility to perform the
measured launch of the operating system by calling the SINIT ACM:

![Breakout of measured launch details](/img/txt_launch2.jpg)

> Source:
> *[A Practical Guide to TPM 2.0](https://link.springer.com/book/10.1007/978-1-4302-6584-9)*

Currently, there are two methods of executing SINIT ACM to perform measured
launch:

- [Trusted Boot (tboot)](https://sourceforge.net/projects/tboot/) - Intel's
  reference implementation of Measured Launch Environment for Intel TXT
- [GRUB2 with TrenchBoot support](https://trenchboot.org/) - GRUB2 is the most
  popular open source bootloader. It can integrate TrenchBoot to perform
  measured launch with Intel TXT or AMD Secure Startup.

The above diagram represents the tboot case. The approach taken by tboot was to
provide an exokernel that could handle the launch protocol implemented by
Intel's special loader, the SINIT ACM and remained in memory to manage the SMX
CPU mode that a dynamic launch would put a system. Tboot is responsible here for
checking all the prerequisites necessary to launch SINIT ACM and whether the
BIOS did properly set up the Intel TXT (otherwise the measured launch will fail
and we may anticipate something is wrong with the machine/firmware in such
case). If all checks pass tboot loads a SINIT ACM, specifies the memory ranges
containing the operating system software to be measured and executed the SINIT
ACM using GETSEC\[SENTER\] instruction. Again the ACM signature is validated and
ACM is being executed in an AC RAM (special secured RAM for ACM execution) to
ensure nothing will tamper with the execution or measurement process. The ACM
calculate the hashes of the operating system software and sends them to the TPM
Platform Configuration Registers (PCRs) which hold the hashes of the measured
software. But they do not hold the hash itself, they combine the current
register value and the hash of the software into a new hash which is saved into
the register as a new value. This prevents easy faking of the PCRs (in order to
achieve the same register value, all the measurements sent to the TPM must be
done in the same order). BIOS does the same with BIOS code/modules, but how it
is different in the case of TXT?

1. There are 24 PCRs inside TPM in total. BIOS can only extend PCRs 0 to 16 and
   PCR 23. PCRs 17 to 22 can be only enabled by hardware, no software code can
   initialize them, e.g. the microcode when launching the Intel TXT. Before the
   PCR 17 to 22 are initialized their values are set to FFs (-1). This is
   achieved by Intel TXT opening the TPM's locality 4, the only locality able to
   reset the PCRs 17-22, which is inaccessible by software.
1. SINIT ACM is being measured into PCR 17 as soon as TPM enters locality 4 via
   GETSEC\[SENTER\] instruction execution. Altering this process is not possible
   without a physical attack on the TPM.
1. PCRs 0-16 can be only reset by system/TPM reset which will zero out these
   PCRs and set the DRTM PCRs 17-22 to FFs (-1). PCRs 17-22 can be only reset by
   GETSEC\[SENTER\] instruction which forces the SINIT ACM to be loaded and
   perform a new measured launch.

Due to the above reasons, the DRTM PCRs are always securely extended by hardware
and thus can be trusted, despite firmware being tampered with. Also Intel TXT is
blocking all interrupts, DMAs, and System Management Interrupts (SMIs) to
provide a safe environment for the operating system software measurement.
Example view of PCRs after tboot execution:

![DRTM PCRs](/img/tboot_pcr.png)

Additionally, Intel TXT offers user policies that can prevent launching software
which measurement isn't approved. It is called a Launch Control Policy a
user-generated structure which defines various requirements to be fulfilled to
consider the software/platform trusted, e.g. define the hashes of the operating
system software that is allowed to boot.

## Intel TXT on Dell OptiPlex 7010 / 9010 with coreboot

Recently I have implemented the support for Intel TXT for Ivy Bridge and Sandy
Bridge platforms in
[coreboot](https://review.coreboot.org/q/topic:sandybridge_txt). There were
several bugs and missing pieces in the Intel TXT driver developed by 9elements:

- Some of them included deprecated APIs which caused the platform to jump to a
  random RAM location: <https://review.coreboot.org/c/coreboot/+/59515>
- Some implied the SINIT ACM is always included in the coreboot image and failed
  to pass the correct information to tboot:
  <https://review.coreboot.org/c/coreboot/+/59519>
- Incorrectly checked information about the production or debug chipset:
  <https://review.coreboot.org/c/coreboot/+/59514/>

It also took some debugging of the registers whether they are set correctly and
fixing any wrong assumptions about the requirements for calling an ACM. When
everything was in place and fixed it took roughly 70 lines of code to add
support for the OptiPlex 7010 / 9010 chipset code.:

- <https://review.coreboot.org/c/coreboot/+/59512>
- <https://review.coreboot.org/c/coreboot/+/59523>

Simple as it may sound, but in fact, it wasn't. My first attempt at enabling
Intel TXT was over a year ago which were also presented on
[QubesOS and 3mdeb minisummit](https://www.youtube.com/watch?v=YE2FbFlszI4).

To use the Intel TXT, you will need the BIOS ACM and the SINIT ACM. The latter
is available for download from
[Intel](https://www.intel.com/content/www/us/en/developer/articles/tool/intel-trusted-execution-technology.html)
while the former can be obtained by NDA only.

In case you have access to both here is a short guide on how to configure
coreboot to use Intel TXT:

[![asciicast](https://asciinema.org/a/449501.svg)](https://asciinema.org/a/449501?speed=1)

One of the most interesting uses of Intel TXT is the
[QubesOS Anti Evil Maid](https://github.com/QubesOS/qubes-antievilmaid/). As the
name suggests it prevents Evil Maid attacks. It is pretty easy to set up using
the guide from the repository. Here is an example of running Anti Evil Maid
tboot to boot QubesOS:

[![asciicast](https://asciinema.org/a/449387.svg)](https://asciinema.org/a/449387?speed=1)

Another interesting case is the remote attestation of the operating system
software. However, there are not many ready to go solutions that could leverage
DRTM to perform the attestation. There is
[CHARRA](https://github.com/Fraunhofer-SIT/charra) the proof-of-concept
implementation of the "Challenge/Response Remote Attestation" interaction model
of the IETF RATS done by Fraunhofer Institute. 3mdeb also works on an
attestation USB token which will free the user from using doubtful attestation
servers and the global network by implementing the attestation services based on
CHARRA inside a USB dongle. For more information please visit the
[Fobnail page](https://fobnail.3mdeb.com/).

## TrenchBoot support

![TrenchBoot](/img/trenchboot_logo.svg)

TrenchBoot is a framework that allows individuals and projects to build security
engines to perform launch integrity actions for their systems. It leverages the
Intel TXT and AMD Secure Startup for this purpose. On the day of writing this
post TrenchBoot support in GRUB2 does not yet implement TPM 1.2 for Intel TXT
path. Dell OptiPlex 7010 / 9010 can use the TPM 1.2 only with the Intel TXT. The
TPM1.2 support will be implemented soon.

Watch my presentation at Linux Secure Launch - TrenchBoot Summit 2021 about
[DRTM as a modern Root of Trust in
OSF](https://www.youtube.com/watch?v=xZoCtNV8Qs0&t=1017s)

## Summary

Intel TXT support will be included in the official releases of Dasharo firmware
Dell OptiPlex 7010 / 9010. It will be fully tested with the automated deployment
procedures to integrate all the features Dasharo has to offer. Join the Dasharo
community on [Dasharo Matrix space](https://matrix.to/#/#dasharo:matrix.org)
where you can find the most recent information about the Dasharo ecosystem and
discussions about open-source firmware. Join the community of hardware and
open-source firmware enthusiasts today!

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of the used hardware platform, feel free to [book a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our
newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

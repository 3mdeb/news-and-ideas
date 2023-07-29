---
title: KGPE-D16 open-source firmware status
abstract: 'This post covers the struggles and efforts behind the revival of
           KGPE-D16. Something that community was waiting for a long time. With
           Dasharo firmware the platform obtained a new life and sees a new
           daylight with more security features and improvements.'
cover: /covers/kgpe_d16.png
author: michal.zygowski
layout: post
published: true
date: 2022-02-03
archives: "2022"

tags:
  - coreboot
  - KGPE-D16
  - Dasharo
categories:
  - Firmware
  - Security

---

## Introduction

Today's computing systems and processors are becoming more and more efficient
but closed as well. Closed in terms of documentation, closed in terms of free
and open-source software and firmware. The x86 silicon vendors are striving for
security by obscurity, falling deeper into the pit they created themselves,
bound by laws that were supposed to protect them. As a result open-source
firmware community has to struggle and push vendors into openness or to provide
means to run open firmware on their products. The openness and possibilities to
run open firmware is gradually decreasing over time as vendors create more and
more binary blobs, offload various operation to another entities (e.g. AMD PSP
or Intel ME). These entities are often fed with more firmware and blobs, often
closed and proprietary with source code being the vendor's restricted secret. In
the light of this threat we turn our eyes to older platforms that were free from
firmware blobs, embedded secondary microcontrollers in chipsets with ring -3
capabilities and were truly user-controllable, respecting the freedom and
privacy. We just hope the days of open specifications and trustworthy computing
on x86 architecture (which were present not so long ago - just over 10 years
ago) will be back once. One of the most performant and still blobfree platforms
you will read in this post is ASUS KGPE-D16, dual socket AMD Opteron
server/workstation board released in 2009, [FSF RYF](https://ryf.fsf.org/)
certified.

## KGPE-D16 history

![img](/img/kgpe_d16.png)

KGPE-D16 is a dual socket, powerful AMD server/workstation board with
SP5100/SR5690 southbridge/northbridge supporting AMD Opteron 6100 (family10h)
and 6200/6300 series (family15h). For example 2nd fastest and blobless CPU
Opteron 6287SE with 16 cores/threads clocks up to 3.5 GHz in turbo is still
impressive, but also energy-hungry as well which may not be acceptable for
current performance per dollar expectations, but there is always some tradeoff.
What is best about these processors is that 6100 and 6200 series Opteron CPUs
run very well without microcode, there is no PSP and the graphics initialization
is done without VBIOS option ROM. Everything in the firmware may be handled by
pure open-source code.

The open-source BIOS for ASUS KGPE-D16 has been implemented by Timothy Pearson
from Raptor Engineering in 2017 by
[crowdfunding](https://review.coreboot.org/q/topic:raptor-asus-kgpe-d16). The
same was done for
[OpenBMC](https://www.raptorengineering.com/coreboot/kgpe-d16-bmc-port-offer.php)
in the same year. The initial source code is still available at
[Raptor Engineering's site](https://www.raptorengineering.com/coreboot/kgpe-d16-bmc-port-status.php).

The platform support lived on the main coreboot branch for 3 years until the
[4.12 release](https://doc.coreboot.org/releases/coreboot-4.12-relnotes.html)
where features like C bootblock, postcar phase and relocatable ramstage support
became mandatory. The coreboot community strives to stabilize the API and
features to enable the modern platform development. As a result the board
support could not be kept on the main branch due to insufficient interest and
maintainership of the platform. Additionally the code upstreamed was not the
best quality, most likely because Raptor did not gather the required funds to
clean up and improve the code. It has been merged as is with insufficient review
which led to a code drop few years later.

## To the rescue of KGPE-D16

It has been a huge blow for the community believing in privacy and liberty of
the hardware. Thus 3mdeb tried to answer on the community requests and needs to
bring back the platform. To prevent the board from dropping (half a year before
the 4.12 release at the end of 2019, where the deprecation has been announced)
3mdeb has applied for funding to [NLnet Foundation](https://nlnet.nl/),
unfortunately the project to improve the quality of board support has been
rejected. The application can be found on
[3mdeb's GitHub](https://github.com/3mdeb/kgpe-osf/blob/master/docs/nlnet-application.md)

The hope was almost lost. In the meantime 3mdeb propagated the need to protect
the libre hardware like KGPE-D16 on various events like, e.g. FOSDEM:

- [FOSDEM'20](https://archive.fosdem.org/2020/schedule/event/coreboot_amd/)
- [FOSDEM'21](https://archive.fosdem.org/2021/schedule/event/firmware_osfsoap2/)

![img](/img/fosdem_logo.png)

And fortunately our screams have been heard... [Vikings](Vikings.net) donated
two KGPE-D16 boards for the development and [Immunefi](https://immunefi.com/)
has offered to sponsor the effort of bringing back the KGPE-D16 to coreboot main
tree. For the details visit
[heads issue on GitHub](https://github.com/osresearch/heads/issues/719).

## KGPE-D16 revival

3mdeb started the code refactoring and improving efforts in September 2021. But
the scope was not only to bring the code quality to coreboot's current
standards, no. We (3mdeb and the sponsors) aimed to create even more secure and
libre platform than it was before (back then in main coreboot branch). Besides
the coreboot requirements 3mdeb has enabled and validated TPM 2.0 and vboot on
the platform using 8 MB and 16 MB SPI flashes (much larger than 2 MB default
ones). 3 months later the finalized firmware has been released under
[Dasharo](https://dasharo.com/) brand with multi-flavored pre-built binaries
ready to use by end users. Now the platform benefits from automated tests and
transparent validation, when test results would be published as well as regular
releases and Dasharo firmware quality. Do not hesitate and try it if you have a
KGPE-D16 board, you will love it. The pre-built binaries can be found on
[Dasharo documentation page](https://docs.dasharo.com/variants/asus_kgpe_d16/releases/)

![img](/img/dasharo-sygnet.svg)

Besides coreboot improvements, the project charter also included upstreaming of
the [flashrom patches](https://review.coreboot.org/c/flashrom/+/59713) for write
protection and OTP memory management. These were especially intended for use
with KGPE-D16 platform and the non-standard flashes to form a Static Root of
Trust with immutable coreboot's bootblock and provide best security possible on
this platform.

The refreshed code for ASUS KGPE-D16 may be found on
[Dasharo GitHub](https://github.com/Dasharo/coreboot/tree/asus_kgpe-d16/develop)
and will be upstreamed to the main coreboot branch soon. If you want to be up to
date with recent news and status please join
[Matrix Dasharo space](https://matrix.to/#/#dasharo:matrix.org) where we publish
the most recent announcements about events or releases and are available for
discussing and supporting the project.

## Summary

If you have an old platform like ASUS KCMA-D8 or Supermicro H8SCM and would like
to have it supported by the most recent coreboot code, do not hesitate to
contact us (drop us email to `contact<at>3mdeb<dot>com`). All we need is some
hardware and funds to quickly bring back those platform to life, because they
use the same chipset and CPU as KGPE-D16.

Be sure to attend this years' FOSDEM'22 where I will be talking about current
[status of AMD platforms](https://fosdem.org/2022/schedule/event/osf_on_amd_3rd/)
(including KGPE-D16) in open source firmware in the Open Source Firmware, BMC
and bootloader devroom.

Also feel invited for the
[FOSDEM'22 after-party](https://3mdeb.com/events/#fosdem-22) organized right
after the devroom track where we will be discussing various aspects of related
to firmware and bootloaders. 3mdeb is also organizing a
[vPub](https://vpub.dasharo.com) on the 17th of February, don't miss this
occasion to talk with us, share your ideas, thoughts and projects.

If you are interested in similar content feel free to
[sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

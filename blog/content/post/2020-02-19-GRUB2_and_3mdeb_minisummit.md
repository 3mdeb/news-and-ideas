---
title: GRUB2 and 3mdeb minisummit 2019
abstract: 'In December 2019 we had pleasure to meet Daniel Kiper #GRUB2
          maintanaer in 3mdeb office in Gdańsk. We discussed various #GRUB2,
          #Xen, #firmware, #coreboot, #security and #TPM related topics. Results
          of that "minisummit" was presented in following blog post in form of
          presentations and videos.'
cover: /covers/grub2_minisummit.png
author: piotr.krol
layout: post
published: true
date: 2020-02-19
archives: "2020"

tags:
  - grub2
  - bootloader
  - trenchboot
categories:
  - Firmware
  - OS Dev
  - Security

---

In December 2019 we had pleasure to meet with
[Daniel Kiper](https://www.linkedin.com/in/dkiper/) GRUB maintainer, Software
Developer, TrenchBoot technical leader at Oracle and conference speaker. Since
we are working with GRUB2 across many commercial projects and our customers
leverage it often we decided to take advantage of this relation and organize a
meeting during which 3mdeb engineers and team leaders presented GRUB related
topics. This blog post summarizes the discussion and creates reference point for
interested parties:

Somehow 'minisummit' name survived since no one offered better title after
publishing
[Qubes OS and 3mdeb 'minisummit' 2019](https://blog.3mdeb.com/2019/2019-08-07-qubes-os-and-3mdeb-minisummit/)
blog post.

What we discussed during our meeting with Daniel:

- [Intro](https://shop.3mdeb.com/wp-content/uploads/2021/06/Intro.pdf) - introduction,
  motivation and agenda presented by me
- [Redundant GRUB2 env file](https://shop.3mdeb.com/wp-content/uploads/2021/06/Redundant-GRUB2-env-file.pdf)
  \- Maciej Pijanowski presented redundant GRUB2 environment file, feature needed
  for power fail safe upgrades, similar mechanism was already implemented in
  U-Boot
- [TPM support in GRUB2 for legacy boot mode](https://shop.3mdeb.com/wp-content/uploads/2021/06/TPM-support-in-GRUB2-for-legacy-boot-mode.pdf)
  - update on
    [talk presented on LPC 2019](https://lpc.events/event/4/contributions/517/)
    in which Michał Żygowski highlights changes made in TrustedGRUB2 and build
    base for discussion about merging changes to GRUB2 mainline
- [GRUB2 security features overview](https://shop.3mdeb.com/wp-content/uploads/2021/06/GRUB2-security-features-overview.pdf)
  \- general talk overviewing security features in GRUB2 presented by me
- [Python 3 support in GRUB2](https://shop.3mdeb.com/wp-content/uploads/2021/06/Python-3-support-in-GRUB2.pdf)
  \- talk in which Michał Żygowski presents how we used Python with GRUB2 and
  starts a discussion about making Python 3 first class citizen in GRUB2
  bootloader
- [AMD TrenchBoot support in GRUB2](https://shop.3mdeb.com/wp-content/uploads/2021/06/AMD-TrenchBoot-support-in-GRUB2-1.pdf)
  \- final talk in which I present status of AMD TrenchBoot support,
  implementation and possible paths to upstream related code

We also published all videos on our
[YouTube channel](https://www.youtube.com/playlist?list=PLuISieMwVBpJ7JyAMGUmxIVjLs1lipKhZ).

## Redundant GRUB2 env file

The key problem mentioned during presentations are lack of integrity check in
the current implementation of GRUB2, what means any corruption of environment
file in GRUB may lead to boot failure that can be recovered only by manual
intervention. Since in most cases GRUB2 is used as a bootloader in general
purpose computers this was not a problem. Even if in reality it happens people
know how to recover either through GRUB command line or live booting Linux
distro.

Unfortunately, if trying to use GRUB2 in the embedded environment there is a
risk of ending up with an unbootable product, which of course leads to all other
problems on the vendor's side.

We all agreed that this feature is needed in GRUB2 and if 3mdeb will get correct
sponsoring from vendors using GRUB2 such support will be developed and
contributed. On the other hand, some vendors assume that file corruption is so
rare that they don't want to spend additional engineering hours on such feature.

Before such support is available, there are still methods to mitigate the impact
of the problem for which reference you can find in the presentation.

## TPM support in GRUB2 for legacy boot mode

The key problem here is the lack of boot process integrity in non-UEFI systems.
Since GRUB2 is in boot process chain also in legacy systems we wanted to
continue discussion started at LPC 2019. General conclusion on Linux Plumbers
Conference was that approach presented in "TCG PC Client Specific Implementation
Specification for Conventional BIOS" is preferred. What in short means that BIOS
should expose legacy interrupt INT 1Ah to legacy operating system for
measurement purposes.

There are couple problems with that:

- this approach is complaint with TPM1.2, no support for TPM2.0
- GRUB2 is neither consumer or producer of INT 1Ah
- at this point GRUB2 supports TPM only through UEFI API
- GRUB2 should preserve interrupt handlers

Because the whole problem seems to not be so important (it affects the limited
amount of hardware) we are thinking about the simplest way of having correct
results. It seems that solution that has most sense is leveraging
[Rhode and Schwarz TrustedGRUB2 implementation](https://github.com/Rohde-Schwarz/TrustedGRUB2).

The key assumption of Rhode and Schwarz project is that BIOS measures MBR and
interrupts for measuring bootloader kernel (`diskboot.img`) is called from MBR.
In that way measurement chain continues. Of course something has to install
those interrupts, in this case it is SeaBIOS, which implemented previously
mentioned TCG specification.

Addressing a lack of support for TPM2.0 through INT 1Ah seems not to be a big
issue since we can hide hardware version behind SeaBIOS implementation.
Bootloader just need to extend PCRs and do not use any sophisticated TPM
features. This approach implies that our stack needs SeaBIOS, since we were not
able to find anyone who can confirm existence of legacy BIOS or CSM with INT 1Ah
support. SeaBIOS of course limit us to coreboot and QEMU based platforms.

Based on previous assumption we have to admit that GRUB2 can be only consumer of
INT 1Ah API. The simplest solution for that would be to port support from
TrustedGRUB2.

In previously described cases, GRUB2 is the second stage bootloader. If we would
like to have GRUB2 as first stage bootloader GRUB2 should be producer of INT 1Ah
API. That implies targets like:

- \*BSD booted from GRUB2 on top of Legacy BIOS/CSM without INT 1Ah
- any system booted from GRUB2 on top of coreboot - here GRUB2 sill can be a
  consumer if coreboot would install INT 1Ah API what would be a little bit
  bizarre in light of already having that in SeaBIOS

Moreover being a producer means providing a driver for TPM communication.
According to minisummit discussion producer scenario is technically possible to
implement things but may be economically not feasible.

## GRUB2 security features overview

During this presentation I complained a little bit about the usability of
various GRUB2 security features and suggested possible extensions that could
help improve the current state of GRUB2 security. Definitely documentation could
be better, but this requires time and community engagement.

Most of the talk focused on how those features help coreboot based platforms.
The overall adoption of security features is slow, mostly because of a lack of
integration across the system components.

## Python 3 support in GRUB2

Whole topic started with our talk about "CHIPSEC as coreboot payload" from
[OSFC2018](https://www.osfc.io/2018/talks/).

[![CHIPSEC as coreboot payload](https://img.youtube.com/vi/P49uLPCXgjo/0.jpg)](https://www.youtube.com/watch?v=P49uLPCXgjo)

Our key concern here was lack of pre-OS firmware validation environment, there
were some attempts in the past like UEFI support for MicroPython, but recently
there seem to be no progress in the area.

We all agreed that support for Python in GRUB would be interesting from various
points of view. One area that would be problematic is ownership and
maintainership since Python is evolving. Keeping it up to date would be required
and probably the cost time of developers. Other mentioned alternative was
MicroPython since it would resolve the same problem but probably with less
maintainer overhead.

## AMD TrenchBoot support in GRUB2

From this presentation you can learn how to run most recent code and test it.
Most of the presentation and discussion was about internals how things should be
implemented and if what we did is acceptable.

General conclusion was that we have to implement DRTM specific relocator as it
was done for other boot options.

This session was more like live code review, but we took the chance to discuss
each aspect of TrenchBoot support for AMD in GRUB project. Most of the mentioned
problems were already implemented and sent for
[review to grub-devel](https://www.mail-archive.com/grub-devel@gnu.org/msg29472.html)
mailing list.

In long run we plan to provide frequent updates related to AMD support in
TrenchBoot project. Next update is planned to
[FOSDEM 2020](https://fosdem.org/2020/schedule/event/firmware_itsoecs/).

### Summary

It was pleasure to whole 3mdeb to meet with Daniel and understand his
perspective and vision of GRUB2 from community and commercial perspective. We
definitely see possible synergies and hope to find resources to support GRUB
bootloader.

Some may ask if GRUB2 existence is justifiable in light of Linux booting
directly from UEFI and growth of projects like
[LinuxBoot](https://www.linuxboot.org/). Our opinion is that we choose solutions
that fits best for outcome we want to achieve. Amount of work, expertise and
features set accumulated over 25 years of development cannot be ignores and
largely simplify our lives in some cases. It may mean that it is faster and
easier to use GRUB2 in some cases and in other leverage LinuxBoot or other
solution.

If you need bootloader support or you think we can help in improving the
security of your firmware or you looking for someone who can boost your product
by leveraging advanced features of used hardware platform, feel free to [book a
call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. And if you want to stay up-to-date
on all things firmware security and optimization, be sure to sign up for our
newsletter:

{{< subscribe_form "3160b3cf-f539-43cf-9be7-46d481358202" "Subscribe" >}}

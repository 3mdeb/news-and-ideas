---
title: Qubes OS and 3mdeb "minisummit" 2019
abstract: 'In May we had pleasure to meet Marek Marczykowski-Górecki #QubesOS
          Project Lead in 3mdeb office in Gdańsk. We dicussed various #QubesOS,
          #Xen, #firmware, #coreboot, #security and #TPM related topics. Results
          of that "minisummit" was presented in following blog post.'
cover: /covers/qubesos_3mdeb_minisummit.png
author: piotr.krol
layout: post
published: true
date: 2019-07-02
archives: "2019"

tags:
  - qubesos
categories:
  - Firmware
  - OS Dev
  - Security

---

In May we had pleasure to meet with [Marek Marczykowski-Górecki](https://www.qubes-os.org/team/) in 3mdeb office in
Gdańsk, Poland. Since we are long term fans of Qubes OS and its approach to
security, as also fans of Joanna Rutkowska security research in area of
firmware and computer architecture, we couldn't miss the opportunity and
decided to organize one day event during which we discussed topics at Qubes OS
and firmware boundary during which we discussed topics at Qubes OS and firmware
boundary.

Humorously we called it "minisummit". Topics discussed and related presentations:

* [Qubes OS certification and open source firmware requirements](https://cloud.3mdeb.com/index.php/s/CJC8qBeMMT6T8oL) - Piotr Król
* Xen and Qubes OS status - discussion
* [Qubes OS and OpenEmbedded/OpenXT/Yocto collaboration](https://cloud.3mdeb.com/index.php/s/obx7qDFic5otR54) - Maciej Pijanowski
* [TPM2.0 in Qubes OS](https://cloud.3mdeb.com/index.php/s/kAQoEBHXAXNEtwL) - Michał Żygowski
* [Lightning talks](https://cloud.3mdeb.com/index.php/s/Si9YXM2ymWQMj7n):
    - DRTM/TrenchBoot - Piotr Król
    - HCL report and its lifecycle (automation, anonimization, maintainance) - Piotr Król
    - fwupd - Piotr Król
* [Status of AEM for Intel and AMD](https://cloud.3mdeb.com/index.php/s/aPYPeSfJPoZ2gPM) - Michał Żygowski

There were also lot of side-talks, but overall agenda was as above. Below I
will elaborate more on presented topics below.

# Qubes OS certification

Various 3mdeb customers are interested in Qubes OS certification. There is
nothing that prevent hardware vendors to certify their hardware, but some
firmware requirements have to be fulfilled:

* hardware should run only open-source boot firmware - there are some technical
  exceptions to that e.g. CPU vendor binary blobs like FSP, AGESA, ME and PSP
* properly exposed advanced hardware features for Intel those are VT-x, VT-d and SLAT
* ACPI tables that expose above features to OS should be constructed correctly
  - DMAR for Intel and IVRS for AMD

Enabling or improving support of above features definitely lay in area of 3mdeb
expertise, so if you looking for someone who can help you in Qubes OS hardware
certification please [contact us](https://calendly.com/3mdeb/consulting-remote-meeting).

As mentioned on slides linked above we discussed also:

* Alternative computer architectures that have potential of being not-harmful
  as x86 (in opposition to [Joanna paper](https://blog.invisiblethings.org/papers/2015/x86_harmful.pdf)).
  Unfortunately we can't see shiny future right now. Qubes OS focus on end-user
  devices, so laptops and workstations. It looks like we would have to wait
  little bit for reasonably performing ARM systems. There is also some hope in
  OpenPOWER and RISC-V, but ports to those architectures would require
  reasonably market demand for which we don't see potential right now.
* It looks like Qubes OS development doesn't face any significant issues from
  firmware level. It's good to know that hardware Qubes OS operate on
  reasonable quality firmware.

# Xen and Qubes OS status

There was no formal presentation about that topic, but discussion drifted to
that topic, so it is definitely worth to mention. Of course we are not
hard-core Xen or Qubes OS developers, so some of those information may be not
complete:

* There are some issues with PCI pass-through. Qubes OS would like to use that
  feature more, but because of complex PCI architecture and design assumptions
  these days it is not so each and Xen should improve need improvements in that
  area
* There is some problem PCI hot-plug since all connected devices automatically
  appear in dom0, which can cause some security issues if malicious device
  would be connected
* USB Type C is another problem since host controller is visible only after
  connecting device, so OS doesn't have control over it before
* It seems that correct support for IOMMU can mitigate most of above problems
* There are very interesting improvement in new microarchitectures like
  Denverton, especially VT-c, but Xen still doesn't have support for that
* There are also know issues in GPU support e.g. Nvidia requires dedicated,
  more expensive hardware, if it would be used in virtualized environment
* Because of above problems and other reasons Qubes OS community consider KVM
  support

We also discussed how 3mdeb can involve in improving Qubes OS and Xen and of
course community activity would be best approach. Of course as for-profit
organization we have to align that with some business activity. We plan to work
on that in 2019. As first step towards that is this blog and following ideas
for contribution.

# Qubes OS build system

According to [documentation](https://www.qubes-os.org/doc/qubes-builder/) Qubes
OS should be build using rpm-based distro like Fedora. According to Marek build
should also work on Debian without big issues. Definitely it is something to
check and maybe improve documentation.

But moving forward discussion about Qubes OS build system, as [Yocto Participants](https://www.qubes-os.org/doc/qubes-builder/),
we advertised OE/Yocto as build system for dom0 in Qubes OS. During that
discussion various problems pop up:

* OE/Yocto not verify hashes or does it in doubtful way.
* We can't freeze dom0, we need flexibility in extending it additional software
  through package manager - as Marek mentioned this statement is valid until
  GUI is in dom0. Goal is definitely to get rid of GUI from dom0.
* We should treat big distros like Debian and Fedora as role models in package
  management, they already use lots of good practice that are not followed by
  OE/Yocto, because of that 3mdeb should understand better how Debian/Fedora
  does package management and help reflect best practice in OE/Yocto to improve
  probability of using it as dom0 build system.
* Build system should not require networking connection, this is question about
  security as well as control over whole building process. If package build
  system download arbitrary code during build process then definitely we
  loosing control over each component verification. Secure build should be
  performed on air-gapped hardware/VM.
* Not all recipes in OE/Yocto are reproducible, Debian solve that issue by
  stripping stuff causing problems, maybe that approach should be adapted in
  OE/Yocto. More details about reproducible builds can be found
  [here](https://reproducible-builds.org/docs/). There is also discussion related to that topic [here](https://lists.reproducible-builds.org/pipermail/rb-general/2019-June/001580.html).
* Toolchain flags for security hardening are not easy to set and use.
* Qubes OS will use Mirage OS as firewall. It is sign of another interesting
  technology in service of security , namely unikernels. Marek mentioned that
  there is big potential for unikernels in Qubes OS e.g. GPG VM, because
  unikernels are in-line with system goals and design.
* It looks unikraft evolve as unikernels build system, we are concerned about
  another build system which would be very hard to integrate. We wondered if it
  would be possible to build unikernels using OE/Yocto Marek commented that it
  would be hard or impossible in practice, because unikernels are assumed to be
  single statically linked binary with libraries and "kernel", what means
  completely different result then OE/Yocto produce by default.

Above claims will be elaborated in following blog post and maybe even some
contribution from 3mdeb. We are very concern about mentioned potential security
flows and would like to help in improving OE/Yocto state as well as spreading
the word about it, since we believe OE/Yocto has many benefits if we want to
achieve long term stable and minimal dom0.

We plan to create OE/Yocto hardening guidelines which hopefully can help rise
probability of using OE/Yocto as build system for Qubes OS dom0.

# TPM2.0

It looks that TPM2.0 is not supported in Qubes OS mostly because nobody had
time to take a look at it. From 3mdeb it would be ideal contribution especially
if can be combined with open-source firmware based hardware like
[Librebox](https://shop.3mdeb.com/product/librebox/).

There are various other ways how TPM2.0 can be leveraged in Qubes OS e.g. PKCS #11, VPN.

# fwdupd

Marek mentioned that he is very interested in fwupd support in Qubes OS. 3mdeb
already contributed to LFSV/fwupd project, by adding flashrom support and
ability to update coreboot-based platforms. LVFS/fwupd is treated by 3mdeb as
strategic project since it exist at OS and firmware boundary.

There is even discussion started in this topic [here](https://github.com/QubesOS/qubes-issues/issues/4855).
Key problem at this point is that dom0 has no networking connection, so fwupd
have to respect other means of getting information from LVFS servers.

Richard (LFVS maintainer) and 3mdeb team will attend [OSFC 2019](https://osfc.io/)
we believe it would be good opportunity to talk more about issues that Qubes OS
may consider.

## Summary

Overall we would like to thank Marek for spending whole day with 3mdeb team and
providing his insights about Qubes OS and its relation to firmware. For us it
was important step to build relation and improve networking. We look for
similar meetings in future and hope to see each other during various security
conferences happen in this year.

If you think we can help in improving Qubes OS support for your hardware, help
you with Qubes OS certification on firmware level or you looking for someone
who can boost your product by leveraging advanced features of used hardware
platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or drop us email to
`contact<at>3mdeb<dot>com`. If you are interested in similar content feel free
to [sing up to our newsletter](http://eepurl.com/gfoekD)

---
title: "3mdeb Insights: A Look into 3mdeb's Open-Source Contributions"
abstract: "We're thrilled to share our team's remarkable open-source
           contributions from 2021 to the first half of 2023 with you.
           We've actively worked on enhancing various projects, including
           coreboot and fwupd, leaving a significant impact on the industry.
           Our involvement has not only boosted the functionality and security
           of these projects but also equipped us with valuable expertise for
           our clients. Stay tuned for an insightful blog post diving into our
           open-source contributions!"

cover: /covers/INSIGHTS.png
author: norbert.kaminski
layout: post
published: true
date: 2023-04-27
archives: "2023"

tags:
  - contribution
  - firmware
  - open-source
  - coreboot
  - fwupd
  - trenchboot
categories:
  - Manufacturing

---

From 2021 to 2022, our team of developers thrived, making significant
contributions to firmware projects. Our primary focus revolved around
[coreboot](https://3mdeb.com/training/#coreboot-for-embedded-linux-developers),
a firmware solution that captured our attention. We also dedicated efforts to
the advancement of fwupd and flashrom firmware update systems. But our
dedication to system security didn't stop there—we actively developed
[Trenchboot](https://blog.3mdeb.com/tags/trenchboot/), enabling dynamic
checksum measurement for system components. And let's not forget our deep
involvement in the intricate world of
[Yocto](https://3mdeb.com/training/#yocto-project-development), where we left
our mark on various Yocto layers.

In addition to contributing to these open-source projects, our team is also
passionate about promoting the benefits of open-source software. We believe
that open-source software offers numerous advantages over proprietary software,
such as greater transparency, flexibility, and security. By contributing to
these projects and advocating for open-source software, we aim to foster
a culture of collaboration, innovation, and inclusivity in the technology
industry. We are committed to making a positive impact on the community
through our work, and we look forward to continuing our open-source
contributions in the future.

## Our contributions

![coreboot logo](/covers/coreboot-logo.svg)

[coreboot](https://3mdeb.com/training/#coreboot-for-embedded-linux-developers)
is an open-source firmware that provides a lightweight, secure,
and fast boot experience for PCs, laptops, servers, and embedded devices.
The changes made by our engineers can be divided into three main groups.

#### Adding support for new platforms and maintaining existing ones

Recently, our engineers have focused on expanding coreboot support for the
latest platforms, it is worth mentioning that Karol Zmyslowski has added
[support for Jasper Lake](https://review.coreboot.org/c/coreboot/+/73934).

Michał Kopeć and Michał Żygowski had a major impact on Alder Lake support in
coreboot. Michał Kopeć has added [support for Alder Lake](https://review.coreboot.org/c/coreboot/+/63374)
and Michał Żygowski in the [set of patches](https://review.coreboot.org/c/coreboot/+/68449/11)
has added improvements huge improvements. Also, Michał Żygowski made a significant
contribution to [Tiger Lake support](https://review.coreboot.org/c/coreboot/+/56171).

In the previous year, our team also added
[support for MSI](https://review.coreboot.org/c/coreboot/+/68078) PRO Z690-A
WIFI and MSI PRO Z690-A in DDR4 and DDR5 versions.

Krystian Hebel, Sergii Dmytruk, and Yaroslav Kurlaev have made major contributions
to developing and maintaining support for Power platforms. Their changes include
[emulation improvements](https://review.coreboot.org/c/coreboot/+/67061),
and fixing ongoing issues related to these platforms.

#### Platform security (TPM, TXT)

Our team also worked on [TPM](https://3mdeb.com/shop/modules/tpm-2-0/) and
[TXT](https://blog.3mdeb.com/2022/2022-03-17-optiplex-txt/) solutions that
could support the security of coreboot-based platforms. Sergii Dmytruk added
quite a few improvements related to
[TPM support](https://review.coreboot.org/c/coreboot/+/68748),
while Michal Zygowski added some
[TXT improvements](https://review.coreboot.org/c/coreboot/+/59519).

#### coreboot documentation improvements

The work of our engineers was not closed only to changes in the code.
It is equally important to make the code readable, clear, and understandable
to everyone. Hence, it is worth highlighting our efforts to keep the coreboot
documentation up to date. In this matter, the main contributors were
[Michał Żygowski](https://review.coreboot.org/c/coreboot/+/65702) and
[Sergii Dmytruk](https://review.coreboot.org/c/coreboot/+/68752)

If you are interested in improving the security of your devices while reducing
your dependence on proprietary firmware, you could benefit from using coreboot.
We can also help you reduce time-to-market by simplifying the firmware
development process. As well as if you want your firmware to be user-friendly
and well-documented user-friendly and well-documented then coreboot is for you.

---

![fwupd-logo](/img/fwupd-logo.svg)

[fwupd](https://3mdeb.com/shop/services/basic-firmware-update-integration/)
is an open-source daemon that manages the firmware updates of various
devices. You will surely benefit from using fwupd if you are interested in
automating the firmware update process on your devices and reducing the risk of
security vulnerabilities. fwupd is compatible with a wide range of devices,
including laptops, desktops, and IoT devices.

Changes to fwupd can be divided into several areas. The first is the addition of
[support for Qubes OS](https://github.com/fwupd/fwupd/pull/2710/commits/295418ef784408503b6a62991a74aa4bc886c4e0).
These changes allow firmware updates from within one of the most
secure operating systems. Norbert Kamiński was responsible for these changes.

The second significant set of changes was the addition of
[support for FreeBSD](https://github.com/fwupd/fwupd/pull/3330). These changes
made it possible to open fwupd to another group of operating systems.
These changes were worked on by Michal Kopeć, Sergii Dmytruk, and Norbert Kamiński.

Another sizable change that our engineers were responsible for was extending
[flashrom support](https://github.com/fwupd/fwupd/commit/2bac03eee1a68becc96712d3a86656cc2e8fa19d)
and adding support for Tuxedo laptops.

Our team can help you seamlessly integrate into the fwupd ecosystem across
a variety of platforms and operating systems. Say goodbye to clunky update
processes and hello to a streamlined, hassle-free experience with fwupd!

---

![yocto logo](/img/YoctoProject_Logo_RGB.jpg)

If you're looking for a tailored Linux-based operating system that perfectly
meets your unique requirements and security needs, Yocto is the open-source
project for you. As a comprehensive suite of tools and templates, Yocto
provides the flexibility and customization you need to create a bespoke
solution for your device.

Our engineers have added some important fixes to some of Yocto's most popular
layers. Tomasz Żyjewski added support for the Dunfell version of
[meta-openwrt](https://github.com/kraj/meta-openwrt/pull/113)
as well as added support for
[python3-binwalk](https://github.com/openembedded/meta-openembedded/commit/7ea0e04aaee19f61e18bf998bb07f02e52d8146e)
and [python3-uefi-firmware](https://github.com/openembedded/meta-openembedded/commit/3e70428db7b48573883aa50de636d93757dd263e)
in the `meta-openembedded` layer.

Cezary Sobczak added support for the
[Nezha Allwinner D1](https://github.com/riscv/meta-riscv/pull/327) in
the `meta-riscv` layer. And Maciej Pijanowski added minor fixes for
the [meta-sunxi](https://github.com/linux-sunxi/meta-sunxi/pull/256) layer.

By partnering with our team, we can help you leverage the power of Yocto and
build a custom Linux distribution that fully aligns with your vision. From
feature-rich IoT devices to mission-critical servers, we've got you covered.
Let us create a personalized solution that meets your exact specifications
and takes your device's capabilities to the next level.

![Trenchboot logo](/img/trenchboot_logo.svg)

[TrenchBoot](https://blog.3mdeb.com/tags/trenchboot/) is a framework that
allows individuals and projects to build security engines to perform launch
integrity actions for their systems. The framework builds upon Boot Integrity
Technologies (BITs) that establish one or more Roots of Trust (RoT) from which
a degree of confidence that integrity actions were not subverted is derived.

The biggest changes took place in the landing-zone component. Worth mentioning
is the addition of [support for the Xen hypervisor](https://github.com/TrenchBoot/landing-zone/pull/60)
and [multiboot2 support for the GRUB2 bootloader](https://github.com/TrenchBoot/landing-zone/pull/64).
The author of these changes is Krystian Hebel.

If you're looking for methods of enhancing boot security for your devices,
Trenchboot is the solution you've been searching for. Our team is equipped
to enable Trenchboot for you so that you can enjoy enhanced protection against
attacks and device security breaches. Let us help you safeguard your devices
with Trenchboot.


## Upcoming events

Don't forget to mark your calendars for
[Dasharo User Group #2](https://vpub.dasharo.com/e/7/dasharo-user-group-2),
which will take place on July 6th, 2023. This is a great opportunity to learn
more about open-source projects and connect with other members of the community.

The Dasharo User Group (DUG) is an important forum for users of Dasharo to
come together, share their knowledge, and stay informed about the latest
developments in the Dasharo ecosystem. The DUG is a platform for users to
connect and learn about new features and updates that are coming to Dasharo.
The first DUG event will take place in early March and will include a variety
of discussions on different topics related to Dasharo. The agenda for the event
will be shared in the next month. The event will be a great opportunity for
Dasharo users to meet other users, learn new things, and share their
knowledge and experience with others.

Dasharo vPub 0x7 is a follow-up event to DUG#2 and will provide a space
to engage in more informal conversations and discussions that may not have
been covered during DUG#2. The vPub is designed to be a less structured, more
relaxed environment where the community can discuss topics that are of interest
to them. This can include off-topic discussions, technical challenges they are
facing, and ideas for new features or improvements.

## Summary

These are just a selection of our contributions to open-source. Since its
inception, 3mdeb has contributed changes to more than 100,000 lines of code
in open-source projects. So if you're looking for expert guidance on open-source
projects such as coreboot, fwupd, Yocto, and Trenchboot, our team is here to
help. We are committed to helping our clients achieve their security and
customization goals through our open-source expertise, and we invite you to
join us on this journey.

[We'd love to discuss the details](https://3mdeb.com/contact/)
of how we can work together to bring your project to the next level.

If you are passionate about these topics, we also welcome you to join our
recruitment process and become a part of our team.
[Check here](https://3mdeb.com/careers/) possible career paths.

---
title: "3mdeb Insights: A Look into 3mdeb's Open-Source Contributions"
abstract: "We're thrilled to share our team's summary of open-source
           contributions from 2021 to the first half of 2023 with you.
           We've actively worked on enhancing various projects, including
           coreboot and fwupd. Our involvement has not only boosted the
           functionality and security of these projects but also equipped
           us with valuable expertise for our clients. Stay tuned for
           an insightful blog post diving into our open-source contributions!"

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
[coreboot](https://blog.3mdeb.com/tags/coreboot/),
a firmware solution that captured our attention. We also dedicated efforts to
the advancement of [fwupd](https://blog.3mdeb.com/tags/fwupd/) and
[flashrom](https://www.flashrom.org/Flashrom) firmware update systems. But our
dedication to system security didn't stop there — we actively developed
[Trenchboot](https://blog.3mdeb.com/tags/trenchboot/), enabling dynamic
checksum measurement for system components. And let's not forget our deep
involvement in the intricate world of
[Yocto](https://blog.3mdeb.com/tags/yocto/), where we left
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

## Our Valued Contributors

To begin with, we want to express our appreciation for the dedicated efforts
of our contributors, who persistently endeavor to improve many open-source
projects:

* [Michał Żygowski](https://twitter.com/_miczyg_)
* [Sergii Dmytruk](https://github.com/SergiiDmytruk)
* [Karol Zmyslowski](https://www.linkedin.com/in/karolzet/)
* [Krystian Hebel](https://www.linkedin.com/in/krystian-hebel-b48424205/)
* [Kacper Stojek](https://www.linkedin.com/in/kacper-stojek-5108a7237/)
* [Michał Kopeć](https://www.linkedin.com/in/micha%C5%82-kope%C4%87-a8b216200)
* [Norbert Kamiński](https://twitter.com/asiderr)
* [Tomasz Żyjewski](https://twitter.com/tomzy_0)
* [Cezary Sobczak](https://www.linkedin.com/in/cezary-sobczak)
* [Maciej Pijanowski](https://twitter.com/macpijan)

## Significant Updates and Features

![coreboot logo](/covers/coreboot-logo.svg)

[coreboot](https://www.coreboot.org/)
is an open-source firmware that provides a lightweight, secure,
and fast boot experience for PCs, laptops, servers, and embedded devices.
The changes made by our engineers can be divided into three main groups.

Most recent coreboot contributions were described in detail in the
[4.20 release blog post](https://blog.3mdeb.com/2023/2023-05-18-our_contribution_to_coreboot_4_20_release/).
If you are interested in improving the security of your devices while reducing
your dependence on proprietary firmware, you could benefit from using coreboot.
We can also help you reduce time-to-market by simplifying the firmware
development process. As well, if you want user-friendly and well-documented
firmware, then coreboot-based
[Dasharo firmware](https://www.dasharo.com/pages/contact/) is a solution
for you.

---

![fwupd-logo](/img/fwupd-logo.svg)

[fwupd](https://fwupd.org/) is an open-source daemon that manages the firmware
updates of various devices. You will surely benefit from using fwupd if you are
interested in automating the firmware update process on your devices and
reducing the risk of security vulnerabilities. fwupd is compatible with a wide
range of devices, including laptops, desktops, and IoT devices.

Changes to fwupd can be divided into several areas:
* **Support for Qubes OS** -
The biggest problem when updating firmware in the case of Qubes OS is the
hard separation of the hardware layer from the network layer. Hence,
to update the firmware, it is necessary to download the update in a virtual
machine that has access to the network and then pass and verify the files
to the virtual machine administrating the system (DOM0). The changes included
in this patch solve these problems and allow firmware updates
from within reasonably secure operating systems.
[Norbert Kamiński](https://twitter.com/asiderr) was responsible for these
changes.
* **Support for FreeBSD** -
These changes made it possible to open fwupd to the group of BSD operating
systems. BSD operating systems are often used in networking applications
(routers, etc.) These changes lay the groundwork for supporting fwupd
in networking applications. Details are described in our earlier
[blog posts](https://blog.3mdeb.com/tags/fwupd-for-bsd/).
These changes were worked on by
[Michał Kopeć](https://www.linkedin.com/in/micha%C5%82-kope%C4%87-a8b216200),
[Sergii Dmytruk](https://github.com/SergiiDmytruk), and
[Norbert Kamiński](https://twitter.com/asiderr).
* **flashrom support for [TUXEDO laptops](https://www.tuxedocomputers.com/en/Linux-Hardware/Linux-Notebooks.tuxedo)** -
These changes were tied to firmware and EC updates. Thanks to them, owners
of TUXEDO laptops enjoy a simple and intuitive firmware update on their hardware.

Our team can help you seamlessly
[integrate into the fwupd](https://3mdeb.com/shop/services/basic-firmware-update-integration/)
ecosystem across a variety of platforms and operating systems. Say goodbye to
clunky update processes and hello to a streamlined, hassle-free experience
with fwupd!

### Contribution details

* [Norbert Kamiński](https://twitter.com/asiderr) (24):
  * [qubes: Add qubes-fwupdmgr.py to src folder and...](https://github.com/fwupd/fwupd/commit/303b39ba9a7f)
  * [trivial: contrib/qubes: Delete test for unexisting method](https://github.com/fwupd/fwupd/commit/66b592993ec2)
  * [fwupd.spec.in: Drop fwupd_usbvm_validate.py from qubes-vm package](https://github.com/fwupd/fwupd/commit/70eb21f764e4)
  * [trivial: contrib/qubes: Add missing import](https://github.com/fwupd/fwupd/commit/4d12239ccbee)
  * [qubes/src/heads: Update Heads versioning](https://github.com/fwupd/fwupd/commit/c81094f0ba69)
  * [qubes/test/fwupdmgr: Update cabinets checksums and URLs](https://github.com/fwupd/fwupd/commit/7e6b77e12c24)
  * [contrib/README.md: Fix Qubes related Docker commands](https://github.com/fwupd/fwupd/commit/b39b66f1dfd4)
  * [fu-uefi-common.h: Fix efivar compatibility with FreeBSD](https://github.com/fwupd/fwupd/commit/7fdf7c60ee68)
  * [freebsd/Makefile: Disable gudev based plugins](https://github.com/fwupd/fwupd/commit/a580de81bad7)
  * [Revert "trivial: Disable FreeBSD CI again"](https://github.com/fwupd/fwupd/commit/b6fac03b57a8)
  * [main.yml: Install protobuf-c as fwupd dependency in the FreeBSD job](https://github.com/fwupd/fwupd/commit/d0af777b1455)
  * [main.yml: Bump GitHub Action freebsd-vm](https://github.com/fwupd/fwupd/commit/30700d52e177)
  * [Revert "trivial: Disable the FreeBSD CI action as it's been failing f…](https://github.com/fwupd/fwupd/commit/ea12ce69b1fe)
  * [build_freebsd_package.sh: Build package with generated pkg-plist](https://github.com/fwupd/fwupd/commit/3fe782cdddd4)
  * [freebsd-ci: Change FreeBSD artifact extension](https://github.com/fwupd/fwupd/commit/c1f06b6b82a0)
  * [Add FreeBSD package to the CI matrix](https://github.com/fwupd/fwupd/commit/dbece574ee91)
  * [meson.build: Change python version check order](https://github.com/fwupd/fwupd/commit/1b396215d939)
  * [fu-smbios.c: Add kenv support](https://github.com/fwupd/fwupd/commit/80ba3f07f26b)
  * [fu-tool.c: Use traditional UNIX record locks if OFD is not available](https://github.com/fwupd/fwupd/commit/58fbbc2939bc)
  * [fu-engine.c: Fix undeclared variable for *BSDs builds](https://github.com/fwupd/fwupd/commit/a863e6a84ef9)
  * [fwupd port for BSD distros](https://github.com/fwupd/fwupd/commit/76e19930a89d)
  * [libxmlb.wrap: Bump revision](https://github.com/fwupd/fwupd/commit/6c8417b5af79)
  * [contrib/qubes: Add Qubes wrapper source and create packages](https://github.com/fwupd/fwupd/commit/60e84c617f79)
  * [contrib/README.md: Update instructions for distribution packages](https://github.com/fwupd/fwupd/commit/ea70435d7202)
* [Michał Kopeć](https://www.linkedin.com/in/micha%C5%82-kope%C4%87-a8b216200) (4):
  * [plugins/flashrom/flashrom.quirk: update NovaCustom GUIDs](https://github.com/fwupd/fwupd/commit/d3ce827f967d)
  * [plugins/flashrom: add quirk for NovaCustom NV4x](https://github.com/fwupd/fwupd/commit/ab06e034c35a)
  * [libfwupdplugin: Implement fu-efivar-freebsd.c](https://github.com/fwupd/fwupd/commit/d678b755d03c)
  * [Obtain firmware major and minor versions from SMBIOS](https://github.com/fwupd/fwupd/commit/0f75f55c72dc)
* [Sergii Dmytruk](https://github.com/SergiiDmytruk) (29):
  * [plugins/flashrom: manage flashrom context at plugin level](https://github.com/fwupd/fwupd/commit/e1d708a4ff21)
  * [plugins/flashrom: create separate device for ME region](https://github.com/fwupd/fwupd/commit/2bac03eee1a6)
  * [plugins/flashrom: enable for 2 Tuxedo laptops](https://github.com/fwupd/fwupd/commit/ddf4e10d7b14)
  * [plugins/flashrom: add flashrom-specific GUIDs](https://github.com/fwupd/fwupd/commit/e65cb98cc833)
  * [plugins/flashrom/fu-flashrom-device.c: create layout on open](https://github.com/fwupd/fwupd/commit/e9f765dc477c)
  * [plugins/flashrom: make region we're flashing a property](https://github.com/fwupd/fwupd/commit/523ed0d7b4d6)
  * [plugins/intel-spi: mark ME region device locked if it's RO](https://github.com/fwupd/fwupd/commit/b678170ee75d)
  * [plugins/superio: don't leak chiplet property of device](https://github.com/fwupd/fwupd/commit/dce73cbffb0a)
  * [trivial: plugins/superio: include prj_name in IT55's to_string](https://github.com/fwupd/fwupd/commit/294bd648ea1e)
  * [fu-util: pull device flags after unlocking](https://github.com/fwupd/fwupd/commit/500dd2c9c475)
  * [trivial: libfwupd,libfwupdplugin: fix typos in several comments](https://github.com/fwupd/fwupd/commit/4795ab3122e8)
  * [trivial: plugins/superio: don't add same flag twice](https://github.com/fwupd/fwupd/commit/028740204be3)
  * [Add support for SuperIO IT5570](https://github.com/fwupd/fwupd/commit/d8a5c7968d21)
  * [Load hwinfo on <code>fwupdtool firmware-dump</code> command](https://github.com/fwupd/fwupd/commit/744e17f68fe3)
  * [Switch from sysctl to ioctl for ESRT on FreeBSD](https://github.com/fwupd/fwupd/commit/c0d0ce4e1ab5)
  * [Depend on libefivar in uefi-capsule](https://github.com/fwupd/fwupd/commit/9c21e4e1358d)
  * [Corrections for fu-efivar-freebsd.c](https://github.com/fwupd/fwupd/commit/c16602d688c3)
  * [Fix formatting in fu_common_get_block_devices ()](https://github.com/fwupd/fwupd/commit/817c3701ae02)
  * [Fix two off-by-one errors in uefi-capsule plugin](https://github.com/fwupd/fwupd/commit/4f8753198e6e)
  * [Correct error msg in fu_common_get_block_devices](https://github.com/fwupd/fwupd/commit/c885fb322500)
  * [Handle bsdisks' UDisks2 implementation on FreeBSD](https://github.com/fwupd/fwupd/commit/080129fc43a0)
  * [Fix formatting in fu_common_get_block_devices ()](https://github.com/fwupd/fwupd/commit/8d5784192f12)
  * [Fix two off-by-one errors in uefi-capsule plugin](https://github.com/fwupd/fwupd/commit/4558e5f317fa)
  * [Correct error msg in fu_common_get_block_devices](https://github.com/fwupd/fwupd/commit/1e5aec4eb157)
  * [Improve error message in fu-uefi-backend-freebsd](https://github.com/fwupd/fwupd/commit/cac4f984205a)
  * [Don't fail if memfd_create() is not available](https://github.com/fwupd/fwupd/commit/d01603c2f966)
  * [Handle missing defaults in fu-uefi-devpath.c](https://github.com/fwupd/fwupd/commit/113a91985bde)
  * [Branch explicitly per OS type](https://github.com/fwupd/fwupd/commit/1a328fd3ad81)
  * [Include &lt;efivar-dp.h&gt; explicitly](https://github.com/fwupd/fwupd/commit/3d0e624ed3f2)

---

![yocto logo](/img/YoctoProject_Logo_RGB.jpg)

If you're looking for a tailored Linux-based operating system that perfectly
meets your unique requirements and security needs,
[Yocto](https://www.yoctoproject.org/) is the open-source project for you.
As a comprehensive suite of tools and templates, Yocto provides the flexibility
and customization you need to create a bespoke solution for your device.

Our engineers have added important fixes to some of Yocto's most popular
layers:

* **Support for the Dunfell version of `meta-openwrt`** -
Those changes allow OpenWrt, a Linux-based router distribution built with Yocto,
to be built and run on the APU2. More details are described in
[Tomasz's presentation](https://www.youtube.com/watch?v=2gACMkjBRyM).
Changes done by [Tomasz Żyjewski](https://twitter.com/tomzy_0).
* **Support for python3-binwalk and python3-uefi-firmware in the
`meta-openembedded` layer** -
Those are the tools needed to develop and debug firmware solutions in Python.
Changes done by [Tomasz Żyjewski](https://twitter.com/tomzy_0).
* **Support for the Nezha Allwinner D1 in the `meta-riscv` layer** -
All of details on porting this platform are presented
in [Cezary's presentation](https://www.youtube.com/watch?v=QdBG6HUeE6w).
Changes done by [Cezary Sobczak](https://www.linkedin.com/in/cezary-sobczak).
* **Minor fixes for the `meta-sunxi` layer** -
  Changes done by [Maciej Pijanowski](https://twitter.com/macpijan).

By partnering with our team, we can help you leverage the power of Yocto and
build a custom Linux distribution that fully aligns with your vision. From
feature-rich IoT devices to mission-critical servers, we've got you covered.
Let us create a personalized solution that meets your exact specifications
and takes your device's capabilities to the next level.

### Contribution details

* [Tomasz Żyjewski](https://twitter.com/tomzy_0) (24):
  * [python3-uefi-firmware: add recipe for version 1.9](https://github.com/openembedded/meta-openembedded/commit/3e70428db7b4)
  * [python3-binwalk: add recipe for version 2.3.3](https://github.com/openembedded/meta-openembedded/commit/7ea0e04aaee1)
  * [ppp: adopt to use with OpenWRT](https://github.com/kraj/meta-openwrt/commit/12f19a196d0d)
  * [collectd: adopt to use with OpenWRT](https://github.com/kraj/meta-openwrt/commit/fe937f1b64f4)
  * [luci: expand cmake patch to install more mods](https://github.com/kraj/meta-openwrt/commit/38abdd8157d0)
  * [hostapd: apply patches from OpenWRT](https://github.com/kraj/meta-openwrt/commit/c910e4fb9fcb)
  * [comgt: add recipe to control gsm interface](https://github.com/kraj/meta-openwrt/commit/91e29428c1c3)
  * [dropbear: adopt to use with OpenWRT](https://github.com/kraj/meta-openwrt/commit/53885307c783)
  * [coova-chilli: add recipe to provide coova-chilli package](https://github.com/kraj/meta-openwrt/commit/6951c41e1c39)
  * [daemon: add recipe as rdepends of coova-chilli](https://github.com/kraj/meta-openwrt/commit/2d8073a14e33)
  * [liblucihttp: add recipe](https://github.com/kraj/meta-openwrt/commit/2460c2f759b0)
  * [haserl: add recipe as rdepends of coova-chilli](https://github.com/kraj/meta-openwrt/commit/0e4b6c8d282d)
  * [luci: set DEPENDS and INSANE_SKIP variables](https://github.com/kraj/meta-openwrt/commit/9d8ef3240409)
  * [luci: add do_configure prepend to copy plural_formula files](https://github.com/kraj/meta-openwrt/commit/f03025cd8589)
  * [luci: add plural_formula files to SRC_URI](https://github.com/kraj/meta-openwrt/commit/7d14d9b08960)
  * [hostapd: correctly set FILES variable](https://github.com/kraj/meta-openwrt/commit/a3f0a2547bc6)
  * [hostapd: install ppp.sh script](https://github.com/kraj/meta-openwrt/commit/3b2b24fb7653)
  * [luci: build from openwrt-19.07 branch](https://github.com/kraj/meta-openwrt/commit/a13ffc02cec0)
  * [luci: add liblucihttp as RDEPENDS](https://github.com/kraj/meta-openwrt/commit/86993d096f32)
  * [netifd: build from openwrt-19.07 branch](https://github.com/kraj/meta-openwrt/commit/fc28e89709ba)
  * [hostpad: install missing mac80211.sh script](https://github.com/kraj/meta-openwrt/commit/529559dffb78)
  * [hostpad: install missing hostapd.sh script](https://github.com/kraj/meta-openwrt/commit/d06611a9278f)
  * [procd: disable warning as error for array-bounds and unused-results](https://github.com/kraj/meta-openwrt/commit/38aef8f68476)
  * [busybox: remove merged patch](https://github.com/kraj/meta-openwrt/commit/0697f29ab2c7)
* [Cezary Sobczak](https://www.linkedin.com/in/cezary-sobczak) (15):
  * [opensbi: add patches for Nezha board](https://github.com/riscv/meta-riscv/commit/03bcb870e7ec)
  * [boot0: add patch for Makefile to fit it with yocto build environment](https://github.com/riscv/meta-riscv/commit/0d1c2fb125ad)
  * [nezha-allwinner-d1.conf: add machine configuration for Nezha board](https://github.com/riscv/meta-riscv/commit/42a5479dbcc4)
  * [u-boot-nezha: add patch which fix build with binutils 2.28](https://github.com/riscv/meta-riscv/commit/c3966f6d9c7c)
  * [nezha.yml: add file used with kas-docker](https://github.com/riscv/meta-riscv/commit/da702b4533b8)
  * [linux-nezha: add patch which fix build with binutils 2.28](https://github.com/riscv/meta-riscv/commit/74162186df1c)
  * [boot0: add patch which fix build with binutils 2.28](https://github.com/riscv/meta-riscv/commit/94a8a881a0c7)
  * [u-boot-nezha: add recipe with patches for Nezha board](https://github.com/riscv/meta-riscv/commit/42384057560d)
  * [boot0: add recipe of the Nezha SPL](https://github.com/riscv/meta-riscv/commit/6192951a5022)
  * [linux-nezha-dev: use custom version of kernel with paches for D1 chip](https://github.com/riscv/meta-riscv/commit/8957d43a659b)
  * [u-boot-nezha: add patch which increase the CONFIF_SYS_BOOTM_LEN](https://github.com/riscv/meta-riscv/commit/3b2a050de629)
  * [opensbi: update mainline with patches to fit Nezha board](https://github.com/riscv/meta-riscv/commit/ff5e85cb6f2a)
  * [nezha.wks: description of SD card image for Nezha D1 dev board](https://github.com/riscv/meta-riscv/commit/812ffc4068a3)
  * [toc.cfg: add configuration file of TOC1 U-Boot image](https://github.com/riscv/meta-riscv/commit/2e545ae6cc26)
  * [uEnv-nezha.txt: U-Boot bootargs for Nezha board](https://github.com/riscv/meta-riscv/commit/863373eae4e7)
* [Maciej Pijanowski](https://twitter.com/macpijan) (24):
  * [u-boot: rebase nanopi_neo_air emmc patch](https://github.com/linux-sunxi/meta-sunxi/commit/58d382d59892)
  * [Revert "u-boot: rebase nanopi_neo_air emmc patch"](https://github.com/linux-sunxi/meta-sunxi/commit/11052ea20e35)
  * [conf: sunxi.inc: add wks file for arm](https://github.com/linux-sunxi/meta-sunxi/commit/9f622c70b898)
  * [machine: nanopi-m1: add config](https://github.com/linux-sunxi/meta-sunxi/commit/9773647ff4c1)
  * [linux-beaglev: sync dts from u-boot](https://github.com/riscv/meta-riscv/commit/62721a1e296b)
  * [beaglev: add 1st on-hardware test results](https://github.com/riscv/meta-riscv/commit/d31a8ed0aefb)
  * [preliminary beaglev support](https://github.com/riscv/meta-riscv/commit/9b31efa4ab7c)
  * [beaglev.md: add basic readme](https://github.com/riscv/meta-riscv/commit/51d571ef99c5)
  * [opensbi-beaglev: w/a for do_deploy failure](https://github.com/riscv/meta-riscv/commit/89d3bfd5d8bf)
  * [beaglev: rename BSP components from -beaglev to -stafive](https://github.com/riscv/meta-riscv/commit/9d3df1e16496)
  * [linux-beaglev: explain dts sync patch](https://github.com/riscv/meta-riscv/commit/562bbf0f7420)
  * [beaglev-starlight-jh7100.conf: add wic.bmap IMAGE_FSTYPE](https://github.com/riscv/meta-riscv/commit/631ea77d4ab2)
  * [linux-starfive: rename LINUX_VERSION_EXTENSION to -starfive](https://github.com/riscv/meta-riscv/commit/f0225ee57ead)
  * [beaglev-starlight-jh7100.conf: remove leftovers from freedom-u540.conf](https://github.com/riscv/meta-riscv/commit/4c4c29aeeb30)
  * [linux-beaglev: update LIC_FILES_CHKSUM](https://github.com/riscv/meta-riscv/commit/643f03b3d08f)
  * [beaglev-starlight-jh7100.conf: remove comment about SBI_PAYLOAD](https://github.com/riscv/meta-riscv/commit/0e5a6d0cc7f2)
  * [hostapd: update 300-noscan.patch to 2.9 version](https://github.com/kraj/meta-openwrt/commit/5762fda5a1f2)
  * [ipset: use BPN in SRC_URI](https://github.com/kraj/meta-openwrt/commit/0aecaa4c1e09)
  * [procd: Inherit update-alternatives](https://github.com/kraj/meta-openwrt/commit/0d3b94439cac)
  * [cdrkit: split into more packages](https://github.com/openembedded/meta-openembedded/commit/167592e6359e)
  * [cdrkit: add native to BBCLASSEXTEND](https://github.com/openembedded/meta-openembedded/commit/586c62727644)
---

![Trenchboot logo](/img/trenchboot_logo.svg)

[TrenchBoot](https://trenchboot.org/) is a framework that
allows individuals and projects to build security engines to perform launch
integrity actions for their systems. The framework builds upon Boot Integrity
Technologies (BITs) that establish one or more Roots of Trust (RoT) from which
a degree of confidence that integrity actions were not subverted is derived.

The biggest changes took place in the landing-zone component:
* **support for the Xen hypervisor** - This change adds support for the
[Xen](https://blog.3mdeb.com/tags/xen/) hypervisor which enables the separation
of the hardware layer from the programs running on the platform. Thanks to this
changes the landing zone can measure all hypervisor components.
* **multiboot2 support for the GRUB2 bootloader** - Support for multiboot in
[GRUB2](https://blog.3mdeb.com/tags/grub2/) allows you to measure all the
components that are used during system boot when using multiboot2.

The author of these changes is
[Krystian Hebel](https://www.linkedin.com/in/krystian-hebel-b48424205/).

Trenchboot and dynamic measurements significantly reduce the possibility
of compromising devices, and therefore support our efforts to increase the
trustworthiness of every computing device. If you're looking for methods of
enhancing boot security for your devices, Trenchboot is the solution you've been
searching for. Our team is equipped to enable Trenchboot for you so that you
can enjoy enhanced protection against attacks and device security breaches.
Let us help you safeguard your devices with Trenchboot.

* [Krystian Hebel](https://www.linkedin.com/in/krystian-hebel-b48424205/) (14):
  * [Parse bootloader data in the form of tags](https://github.com/TrenchBoot/landing-zone/commit/a6f2f98431f6)
  * [main: do not do STGI for MB2, also do not clear VM_CR_R_INIT](https://github.com/TrenchBoot/landing-zone/commit/a83df90dd736)
  * [Add Multiboot2 support](https://github.com/TrenchBoot/landing-zone/commit/681b8b262087)
  * [main: use one entry point for all protocols, implement stack overflow…](https://github.com/TrenchBoot/landing-zone/commit/33e9ef166713)
  * [multiboot2.h: drop unused structures, add ELF headers, clean up typedefs](https://github.com/TrenchBoot/landing-zone/commit/1cbd62824343)
  * [main.c: get proper MBI size, get kernel size from ELF headers](https://github.com/TrenchBoot/landing-zone/commit/dbc30868b2ee)
  * [util: add script for measuring extended PCR values for Multiboot](https://github.com/TrenchBoot/landing-zone/commit/37cdc6721b7d)
  * [extend_multiboot.sh: use section headers instead of program headers](https://github.com/TrenchBoot/landing-zone/commit/b1e0c8da7eef)
  * [iommu.c: fix order of outb() arguments](https://github.com/TrenchBoot/landing-zone/commit/8c6d9e98c9ba)
  * [event_log: add code for initializing and filling the DRTM TPM event log](https://github.com/TrenchBoot/landing-zone/commit/ca49de2d1b2b)
  * [event_log.c: make the log format compatible with TXT](https://github.com/TrenchBoot/landing-zone/commit/c090a7df5fd8)
  * [event_log: add fields for hash of LZ to the lz_header](https://github.com/TrenchBoot/landing-zone/commit/f9deeabb6405)
  * [main: log PCR extend operations in DRTM TPM event log](https://github.com/TrenchBoot/landing-zone/commit/459b2ed40d2d)
  * [iommu: Implementation of early IOMMU](https://github.com/TrenchBoot/landing-zone/commit/d8b79be69103)

## Upcoming events

Don't forget to mark your calendars for
[Dasharo User Group #2](https://vpub.dasharo.com/e/7/dasharo-user-group-2),
which will take place on July 6th, 2023. This is a great opportunity to learn
more about open-source projects and 3mdeb's open-source contributions
and connect with other members of the community.

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

The Dasharo User Group (DUG#1) and vPub 0x6 event achieved great success,
offering insightful presentations and engaging discussions on topics related
to open-source firmware, hardware, and security. Key highlights encompassed
Dasharo's roadmap, the groundbreaking potential of NovaCustom's hardware
and open-source firmware for enhancing the laptop experience, the Dasharo Tool
Suite roadmap, notable Dasharo features like X11 and RPL-S CPU support,
the summary of PC Engines' post EOL firmware survey, and much more.

We express our appreciation to the speakers who shared their expertise and
perspectives during both DUG#1 and vPub vol.6. These remarkable individuals
include Wessel klein Snakenborg from NovaCustom, Dennis ten Hoove
from Slimmer AI, Brian Delgado from Intel Corporation, Dawid Potocki,
Marcin Cieślak, Marek Marczykowski-Górecki from Invisible Things Lab/Qubes OS,
and Thierry Laurion from Insurgo Technologies Libres/Heads.

For those unable to attend the event or interested in revisiting the sessions,
recorded videos are available on YouTube via the
[following link](https://www.youtube.com/watch?v=fUfjWyljKNs).
Furthermore, the event slides can be accessed at:
[vpub.dasharo.com](https://vpub.dasharo.com/e/1/dasharo-user-group-1).

## Summary

These are just a selection of our contributions to open-source. Since its
inception, 3mdeb has contributed changes to more than 100,000 lines of code
in open-source projects. So if you're looking for expert guidance on open-source
projects such as coreboot, fwupd, Yocto, and Trenchboot, our team is here to
help. [We'd love to discuss the details](https://3mdeb.com/contact/)
of how we can work together to bring your project to the next level.

If you are passionate about these topics, we also welcome you to join our
recruitment process and become a part of our team.
[Check here](https://3mdeb.com/careers/) possible career paths.

---
title: 3mdeb contribution 2020'Q1 - coreboot ports all over the place.
abstract: The starter of the new series - 3mdeb contribution summary! First
          quarter of 2020 brings many new merged patches. Check the samples of
          code that we successfully contributed and feel free to use them in your
          own projects.
cover: /covers/combined-logos.png
author: artur.raglis
layout: post
private: false
published: true
date: 2020-04-16
archives: "2020"

tags:
  - contribution
  - open-source

categories:
  - Miscellaneous

---

## Intro

Our mission @3mdeb is to develop secure and maintainable firmware and
applications helping our clients reach their goals. During everyday work
sometimes we struggle with frustrating problems that shouldn't occur in the
first place. When we finally deal with the issues, the first thing we want to do
is to share the good news with the related communities. This is our main
motivation behind our hard work - to share the knowledge by taking part in the
open source community and help developers and enthusiasts with samples of codes.
The positive feedback from the users is the priceless reward that drives us to
spread the habit of contributing to open source projects. This post will start
the series of 3mdeb contribution summary posts that will be released at the end
of each quarter. Let's dive into the world of open code!

## 2020'Q1 - the king of coreboot?

In the first 3 months of 2020, we contributed `7130` lines of code (except the
patches that have not been merged yet) getting in total over `16k`
[SLOC](https://en.wikipedia.org/wiki/Source_lines_of_code) in `34` unique
projects so far.

Let's introduce the new changes:

![coreboot logo](/covers/coreboot-logo.svg)

1. [coreboot](https://coreboot.org/)

   > coreboot is an extended firmware framework that delivers a lightning fast
   > and secure boot experience on modern computers and embedded systems. As an
   > Open Source project it provides auditability and maximum control over
   > technology.

   This project is the unquestioned number one in this overview. To sum up, the
   most significant changes are unification of the AMD coreboot code and support
   for 6 new mainboards (Libretrend Librebox and Protectli Vault FW2B, FW4B,
   FW6A, FW6B and FW6C).

   Full list of 2020'Q1 patches:

    Author             | Category            | Patch | URL
    -------------------|---------------------|-------|----
    Michał Żygowski    | pcengines/apu1      | Add SMBIOS type 16 and 17 entries | [link][11]
    Michał Żygowski    | pcengines/apu1      | Add possibility to redirect output to COM2 | [link][36]
    Michał Żygowski    | pcengines/apu2      | Add SMBIOS type 16 and 17 entries | [link][1]
    Piotr Kleinschmidt | pcengines/apu2      | Use AGESA 1.0.0.4 with adjusted AGESA header | [link][2]
    Michał Żygowski    | pcengines/apu2      | Add GNB IOAPIC to MP Table | [link][16]
    Michał Żygowski    | pcengines/apu2      | Add reset logic for PCIe slots | [link][17]
    Michał Żygowski    | pcengines/apu2      | Enable PCIe power management features | [link][18]
    Michał Żygowski    | pcengines/apu2      | Do not pass enabled PCIe ClockPM to AGESA | [link][23]
    Michał Żygowski    | pcengines/apu2      | Revert "add reset logic for PCIe slots" | [link][27]
    Michał Żygowski    | pcengines/*         | Remove non-existing NCT5104d LDN 0xe | [link][19]
    Piotr Kleinschmidt | pcengines/*         | Enable SuperIO LDN 0xf for GPIO soft reset | [link][29]
    Piotr Kleinschmidt | pcengines/*         | Enable simple IO-based GPIO control | [link][31]
    Michał Żygowski    | amd/common/acpi     | Move thermal zone to common location | [link][21]
    Michał Żygowski    | amd/agesa           | Improve HTC threshold handling | [link][12]
    Michał Żygowski    | amd/agesa           | Add BeforeInitLate hooks | [link][34]
    Michał Żygowski    | amd/pi              | Enable ACS and AER for PCIe ports | [link][4]
    Michał Żygowski    | amd/pi              | Initialize GNB IOAPIC | [link][14]
    Michał Żygowski    | amd/pi              | Unhardcode IOAPIC2 address | [link][15]
    Michał Żygowski    | amd/pi              | Refactor IVRS generation | [link][25]
    Michał Żygowski    | amd/pi              | Add lost options | [link][35]
    Piotr Kleinschmidt | amd/{agesa,pi}      | Change default SATA mode to AHCI | [link][3]
    Michał Żygowski    | amd/{agesa,pi}      | Include thermal zone | [link][13]
    Michał Żygowski    | amd/{agesa,pi}      | Use ACPIMMIO common block wherever possible | [link][33]
    Michał Żygowski    | amdblocks/acpimmio  | Add missing MMIO functions | [link][32]
    Michał Żygowski    | mb/*                | Use ACPIMMIO common block wherever possible | [link][37]
    Michał Żygowski    | acpi                | Correct the processor devices scope | [link][20]
    Michał Żygowski    | x86/acpi            | Add definitions for IVHD type 11h | [link][24]
    Michał Żygowski    | drivers/pc80/tpm    | Change the _HID and_CID for TPM2 device | [link][26]
    Michał Żygowski    | maintainers         | Add 3mdeb as Protectli mainboards maintainers | [link][8]
    Michał Żygowski    | protectli/vault     | Add FW2B and FW4B Braswell based boards support | [link][7]
    Michał Żygowski    | protectli/vault_kbl | Add FW6 support | [link][10]
    Michał Żygowski    | libretrend/lt1000   | Add Libretrend LT1000 mainboard | [link][9]
    Michał Żygowski    | superio/nuvoton     | Add chip config option to reset GPIOs | [link][22]
    Piotr Kleinschmidt | superio/nuvoton     | Add virtual LDN for simple GPIO IO control | [link][30]
    Piotr Kleinschmidt | superio/nuvoton     | Add soft reset GPIO functionality | [link][38]
    Michał Żygowski    | intel/bd82x6x       | Configure CLKRUN_EN according to SKU | [link][28]
    Michał Żygowski    | intel/braswell      | Generate microcode binaries from tree | [link][5]
    Michał Żygowski    | intel/braswell      | Include smbios.h for Type9 Entries | [link][6]

   ---

   ![TrenchBoot logo](/covers/trenchboot-logo.png)

1. [TrenchBoot/landing-zone](https://github.com/TrenchBoot/landing-zone/)

   > TrenchBoot is a framework that allows individuals and projects to build
   > security engines to perform launch integrity actions for their systems. The
   > framework builds upon Boot Integrity Technologies (BITs) that establish one
   > or more Roots of Trust (RoT) from which a degree of confidence that
   > integrity actions were not subverted.

   Full list of 2020'Q1 patches:

    Author          | Category | Patch | URL
    ----------------|----------|-------|----
    Krystian Hebel  | Build    | Move bootloader data out of measured block | [link][39]
    Krystian Hebel  | Build    | Use more hidden symbols to fix 32bit boot | [link][40]
    Michał Żygowski | Security | Add sha256 | [link][41]
    Michał Żygowski | README   | Add basic readme with Travis build status | [link][42]
    Krystian Hebel  | Main     | Move PCR extension logic to a separate function | [link][43]

   ---

   ![ACPICA logo](/img/acpica-logo.png)

1. [acpica](https://github.com/acpica/acpica)

   > The ACPI Component Architecture (ACPICA) project provides an open-source
   > operating system-independent implementation of the Advanced Configuration
   > and Power Interface specification (ACPI)

   Full list of 2020'Q1 patches:

    Author          | Patch | URL
    ----------------|-------|----
    Michał Żygowski | Implement IVRS IVHD type 11h parsing | [link][44]

   ---

   ![Yocto Project Logo](/img/YoctoProject_Logo_RGB.jpg)

1. [meta-virtualization](https://git.yoctoproject.org/cgit/cgit.cgi/meta-virtualization/)

   > This layer enables hypervisor, virtualization tool stack, and cloud
   > support.

   Full list of 2020'Q1 patches:

    Author     | Category | Patch | URL
    -----------|----------|-------|----
    Piotr Król | dev86    | update SRC_URI and associated checksums | [link][45]

## In the near future

We are not going to rest on our laurels. There are still plenty merge and pull
requests that are in the review state or marked as work in progress.

In the TrenchBoot/landing-zone project, 3mdeb's Firmware Team is working on
[Multiboot2][pr1] and [new kernel info structure][pr2]. If you are interested in
this project, check out posts describing our work on Open Source DRTM -
[Project basics](https://blog.3mdeb.com/2020/2020-03-31-trenchboot-nlnet-lz/)
and
[Landing Zone validation](https://blog.3mdeb.com/2020/2020-04-03-trenchboot-nlnet-lz-validation/).

coreboot community is active as always and 3mdeb's team send support patches for
[Dell OptiPlex 9010 SFF][pr3], [SMSC SCH5545][pr4],
[intel/bd82x6x missing power button events][pr5], [SeaBIOS fix][pr6] and
intruder detection system ([patch1][pr7], [patch2][pr8], [patch3][pr9])! Below
you can find a little demonstration what it is all about:

{{< tweet user="3mdeb_com" id="1247072310324080640" >}}

## Last but not least news

Do you want to read more about our contribution? Feeling that you are missing
information about open projects that we are developing and maintaining? Finally,
we can announce that all open source related activities and achievements are
available to visit at newly created subdomain
[opensource.3mdeb.com](https://opensource.3mdeb.com/).

Feel free to comment on which projects missing out there and we will surely look
into the details of pointed technologies. Also, if you have any questions
regarding the basics of the contribution process or simply want to send your
first patches to the world of the open source IT but you lack the courage to do
so, we will be glad to help you out.

## Summary

Do you still hesitate to be a part of the open source community? By contribution
you not only share valuable code but also improve your software through review
of experienced community members. Take part in the act of learning and teaching
by explaining how you do things in the example project and build a reputation
around people who are interested in similar things. Do not wait and join the
open source family!

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of a used hardware platform, feel free to [book a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. And if you want to stay up-to-date
on all things firmware security and optimization, be sure to sign up for our
newsletter:

{{< subscribe_form "3160b3cf-f539-43cf-9be7-46d481358202" "Subscribe" >}}

[1]: https://review.coreboot.org/c/coreboot/+/38342
[2]: https://review.coreboot.org/c/coreboot/+/35906
[3]: https://review.coreboot.org/c/coreboot/+/35891
[4]: https://review.coreboot.org/c/coreboot/+/35313
[5]: https://review.coreboot.org/c/coreboot/+/39320
[6]: https://review.coreboot.org/c/coreboot/+/39351
[7]: https://review.coreboot.org/c/coreboot/+/32076
[8]: https://review.coreboot.org/c/coreboot/+/39418
[9]: https://review.coreboot.org/c/coreboot/+/30360
[10]: https://review.coreboot.org/c/coreboot/+/33839
[11]: https://review.coreboot.org/c/coreboot/+/38343/
[12]: https://review.coreboot.org/c/coreboot/+/39697/
[13]: https://review.coreboot.org/c/coreboot/+/38755/
[14]: https://review.coreboot.org/c/coreboot/+/39700/
[15]: https://review.coreboot.org/c/coreboot/+/39701
[16]: https://review.coreboot.org/c/coreboot/+/39702/
[17]: https://review.coreboot.org/c/coreboot/+/39703/
[18]: https://review.coreboot.org/c/coreboot/+/39704/
[19]: https://review.coreboot.org/c/coreboot/+/38851/
[20]: https://review.coreboot.org/c/coreboot/+/39698
[21]: https://review.coreboot.org/c/coreboot/+/39779
[22]: https://review.coreboot.org/c/coreboot/+/38850
[23]: https://review.coreboot.org/c/coreboot/+/39970
[24]: https://review.coreboot.org/c/coreboot/+/40041
[25]: https://review.coreboot.org/c/coreboot/+/40042
[26]: https://review.coreboot.org/c/coreboot/+/39699
[27]: https://review.coreboot.org/c/coreboot/+/40147
[28]: https://review.coreboot.org/c/coreboot/+/40347
[29]: https://review.coreboot.org/c/coreboot/+/38274
[30]: https://review.coreboot.org/c/coreboot/+/35849
[31]: https://review.coreboot.org/c/coreboot/+/38275
[32]: https://review.coreboot.org/c/coreboot/+/37813
[33]: https://review.coreboot.org/c/coreboot/+/37400
[34]: https://review.coreboot.org/c/coreboot/+/37998
[35]: https://review.coreboot.org/c/coreboot/+/37999
[36]: https://review.coreboot.org/c/coreboot/+/29791
[37]: https://review.coreboot.org/c/coreboot/+/37401
[38]: https://review.coreboot.org/c/coreboot/+/35482
[39]: https://github.com/TrenchBoot/landing-zone/pull/18
[40]: https://github.com/TrenchBoot/landing-zone/pull/21
[41]: https://github.com/TrenchBoot/landing-zone/pull/16
[42]: https://github.com/TrenchBoot/landing-zone/pull/38
[43]: https://github.com/TrenchBoot/landing-zone/pull/37
[44]: https://github.com/acpica/acpica/pull/562
[45]: https://git.yoctoproject.org/cgit/cgit.cgi/meta-virtualization/commit/?id=a200d2be215b20ec846bc4099f7aafd3fdc0e7a7
[pr1]: https://github.com/TrenchBoot/landing-zone/pull/28
[pr2]: https://github.com/TrenchBoot/landing-zone/pull/30
[pr3]: https://review.coreboot.org/c/coreboot/+/40351
[pr4]: https://review.coreboot.org/c/coreboot/+/40350
[pr5]: https://review.coreboot.org/c/coreboot/+/40346
[pr6]: https://review.coreboot.org/c/coreboot/+/40345
[pr7]: https://review.coreboot.org/c/coreboot/+/40342
[pr8]: https://review.coreboot.org/c/coreboot/+/40341
[pr9]: https://review.coreboot.org/c/coreboot/+/40348

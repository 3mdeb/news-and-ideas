---
title: Our contribution to coreboot 4.20 release
abstract: '🎉 Celebrating coreboot 4.20 release! 🚀 Kudos to our contributors
           who have pushed the envelope in firmware security & optimization. Key updates:
           improved SoC support, TPM security, VT-d DMA protection & more. Check out the
           blog for all the details.'

cover: /covers/coreboot-logo.svg
author: piotr.krol
layout: post
published: true
date: 2023-05-18
archives: "2023"

tags:
  - coreboot
  - open-source
  - protectli
categories:
  - Firmware

---

The open-source community is delighted about the latest coreboot release,
version 4.20. It's a great time as we see this open-source firmware framework
continue development and improvement, particularly from the perspective of our
dedicated contributors and Dasharo customers and supporters. Here's what you
need to know about the changes in this release.

## Our Valued Contributors

Firstly, we'd like to acknowledge the hard work of our contributors, who
continuously strive to enhance the coreboot project:

- [Michał Żygowski](https://twitter.com/_miczyg_)
- [Sergii Dmytruk](https://github.com/SergiiDmytruk)
- [Karol Zmyslowski](https://www.linkedin.com/in/karolzet/)
- [Krystian Hebel](https://www.linkedin.com/in/krystian-hebel-b48424205/)
- [Kacper Stojek](https://www.linkedin.com/in/kacper-stojek-5108a7237/)
- [Michał Kopeć](https://www.linkedin.com/in/micha%C5%82-kope%C4%87-a8b216200)

They've made significant contributions to various aspects of this project. Their
input ranges from fine-tuning and debugging existing features to implementing
new ones and revamping core aspects of the firmware. We express our gratitude
for their efforts.

## Significant Updates and Features

While there's a myriad of changes in the coreboot 4.20 release, you can find
details in
[release notes](https://web.archive.org/web/20230203140857/https://doc.coreboot.org/releases/coreboot-4.20-relnotes.html),
a few stand out due to their potential value for the community.

3mdeb has actively contributed to this release as part of
[Dasharo Support Package](https://docs.dasharo.com/osf-trolling-list/jsm_documentation/#dasharo-support-package)
product and
[Dasharo Community Support](https://docs.dasharo.com/osf-trivia-list/dasharo/#dasharo-professional-support)
sponsored through
[Dasharo newsletter subscription](https://3mdeb.com/?s=%22year+Dasharo+Supporters+Entrance%22&post_type=product&dgwt_wcas=1)
and [merchandise](https://shop.3mdeb.com/product-category/merchandise/),
as seen in the number of commits, mainly through our work in:

- Mainboard and SoC Support: We added and improved support for Protectli
  mainboards based on Intel Elkhart Lake, Alder Lake SoCs. Added support to dump
  GPIOs on Jasper Lake SoC.
- Documentation: coreboot's documentation was updated, particularly in the
  Dasharo description and Trusted Platform Module (TPM) options.
- TPM Security: New log formats compliant with the 2.0 and 1.2 specs and
  Kconfig-configurable PCR usage.
- VT-d: The VT-d subsystem now has a new DMA protection API, which we integrated
  into Alder Lake's functionality.
- EDK2 Payload: Users can now clone the edk2-platforms repository.
- Bug Fixes: Multiple fixes in different areas, such as Intel Elkhart Lake's
  GPIO and Makefiles.
- Power9: We refactored the code to enhance readability and maintainability.
- Additional features: A speaker beep function and updated USB port macros.

## Contribution details

- Kacper Stojek (3)
  - [mainboard/protectli/vault_ehl: Add initial structure](https://review.coreboot.org/c/coreboot/+/72407)
  - [Documentation/external_docs.md: Add information about ost2](https://review.coreboot.org/c/coreboot/+/70853)
  - [Documentation/distributions.md: Update Dasharo description](https://review.coreboot.org/c/coreboot/+/70852)
- Karol Zmysłowski (1)
  - [util/inteltool: Add support for Jasper Lake](https://review.coreboot.org/c/coreboot/+/73934)
- Krystian Hebel (1)
  - [arch/ppc64/rom_media.c: move to mainboard/emulation/qemu-power\*](https://review.coreboot.org/c/coreboot/+/67061)
- Michał Kopeć (1)
  - [soc/intel/elkhartlake/fsp_params.c: wire up remaining ddc params](https://review.coreboot.org/c/coreboot/+/72405)
- Michał Żygowski (19)
  - [mb/protectli/vault_cml: Add Comet Lake 6 port board support](https://review.coreboot.org/c/coreboot/+/67940)
  - [intelblocks/vtd: Add VT-d block with DMA protection API](https://review.coreboot.org/c/coreboot/+/68449)
  - [intelblocks/cse: Add functions to check and change PTT state](https://review.coreboot.org/c/coreboot/+/68919)
  - [mb/protectli/vault_cml: Disable PTT and SPI TPM](https://review.coreboot.org/c/coreboot/+/68920)
  - [payloads/external/edk2: Add option to clone edk2-platforms repo](https://review.coreboot.org/c/coreboot/+/68872)
  - [soc/intel/elkhartlake/romstage/fsp_params.c: separate debug params](https://review.coreboot.org/c/coreboot/+/72404)
  - [soc/intel/alderlake/hsphy.c: Handle case with DMA protection](https://review.coreboot.org/c/coreboot/+/68556)
  - [pc80/i8254: Add speaker beep function](https://review.coreboot.org/c/coreboot/+/68100)
  - [mb/msi/ms7d25: Update USB port macros](https://review.coreboot.org/c/coreboot/+/69820)
  - [Makefile.inc: fix multiple jobs build issue](https://review.coreboot.org/c/coreboot/+/69819)
  - [soc/intel/alderlake: Hook up P2SB PCI ops](https://review.coreboot.org/c/coreboot/+/69949)
  - [soc/intel/alderlake: Hook the VT-d DMA protection option](https://review.coreboot.org/c/coreboot/+/68450)
  - [soc/intel/elkhartlake/gpio.c: Fix GPD reset map](https://review.coreboot.org/c/coreboot/+/72406)
  - [soc/intel/alderlake/iomap: Fix the PCR BAR size on ADL-S](https://review.coreboot.org/c/coreboot/+/69948)
  - [soc/intel/elkhartlake: Define DIMM_SPD_SIZE in SoC Kconfig](https://review.coreboot.org/c/coreboot/+/73933)
  - [soc/intel/common/block/graphics: Hook up all ADL-S IGD PCI IDs](https://review.coreboot.org/c/coreboot/+/70101)
  - [soc/intel/alderlake/{chipset.cb,chipset_pch_s.cb}: Set P2SB as hidden](https://review.coreboot.org/c/coreboot/+/69950)
  - [Update vboot submodule to upstream main](https://review.coreboot.org/c/coreboot/+/74401)
  - [soc/intel/elkhartlake: Increase BSP stack size by 1 KiB to 193 KiB](https://review.coreboot.org/c/coreboot/+/73820)
  - [soc/intel/alderlake: Select SOC_INTEL_COMMON_BLOCK_VTD](https://review.coreboot.org/c/coreboot/+/72069)
- Sergii Dmytruk (5)
  - [security/tpm: add TPM log format as per 2.0 spec](https://review.coreboot.org/c/coreboot/+/68748)
  - [security/tpm: add TPM log format as per 1.2 spec](https://review.coreboot.org/c/coreboot/+/68747)
  - [Documentation/measured_boot.md: document new TPM options](https://review.coreboot.org/c/coreboot/+/68752)
  - [Documentation/measured_boot.md: fix SRTM/DRTM explanations](https://review.coreboot.org/c/coreboot/+/68751)
  - [security/tpm: make usage of PCRs configurable via Kconfig](https://review.coreboot.org/c/coreboot/+/68750)
  - [src/cpu/power9: move part of scom.h to scom.c](https://review.coreboot.org/c/coreboot/+/67055)

## Summary

Maximize your hardware's capabilities and secure your firmware with 3mdeb's
expert services. Our team is dedicated to enhancing your product's performance
and safeguarding it from security vulnerabilities. By opting for our services,
you unlock myriad benefits that your hardware holds. Whether it's about firmware
optimization or security, we've got you covered. Don't let your hardware limit
your potential; instead, let's work together to push the boundaries of what's
possible. Ready to take the leap? [Reach out to us](https://3mdeb.com/contact/)
for a consultation and stay informed by subscribing to our newsletter:

{{< subscribe_form
    "dbbf5ff3-976f-478e-beaf-749a280358ea"
    "Subscribe to Dasharo Newsletter"
>}}

Let's revolutionize your firmware security and performance together. Choose
Dasharo, choose 3mdeb. Take the first step today!

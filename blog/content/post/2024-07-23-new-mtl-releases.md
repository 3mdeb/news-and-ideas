---
title: New Dasharo v0.9.0 Meteor Lake releases
abstract: "Dasharo v0.9.0 for 14th gen Intel Meteor Lake has just been released
            bringing numerous new features and improvements. Check out
            what\'s new!"
cover: /covers/image-file.png
author: filip.golas
layout: post
published: true
date: 2024-07-23
archives: "2024"

tags:
  - dasharo
  - coreboot
  - intel
  - meteorlake
  - linux
  - contribution
categories:
  - Firmware
  - Security

---

## Introduction

We are thrilled to announce that the support for newest Intel
Meteor Lake platform has been added to Dasharo in release v0.9.0!
The newest release features numerous new features and improvements
related to security, functionality and quality of life.
Thanks to everyone who contributed to this release!

## Added features

Here is a brief introduction to the changes in Dasharo v0.9.0,
for more details check out:

- [release notes V540TU](<https://docs.dasharo.com/variants/novacustom_v540tu/releases/>)
- [release notes V560TU](<https://docs.dasharo.com/variants/novacustom_v560tu/releases/>)

### Support for NovaCustom Meteor Lake platform (integrated graphics)

Laptop models with integrated graphics based on Meteor Lake platform are now
supported. Hold on tight, because the next release will come with support for
Nvidia dedicated graphics! Here is a brief introduction to the changes in

### [Vboot Verified Boot](https://docs.dasharo.com/guides/vboot-signing/)

Verified Boot is a method of verifying that a firmware component
comes from a trusted source and haven't been tampered with.
The integrity of a firmware component is ensured thanks to cryptographic
signatures. See the link in section title for more details.

### [TPM Measured Boot](https://docs.dasharo.com/unified-test-documentation/dasharo-security/203-measured-boot/)

Measured Boot is another method of measuring the integrity of firmware components
by using Trusted Platform Module to store hashes of each firmware component in
PCR registers. Check the link in the header for more details.

### [Vboot recovery notification in UEFI Payload](https://docs.dasharo.com/unified-test-documentation/dasharo-security/201-verified-boot/)

Booting the device with a firmware component signed using wrong keys
will cause the device to boot into recovery mode. A notification
about that event will be displayed on the screen. For more details
check the link in the header.

![Vboot Verified Boot popup](/img/verified_boot_popup.png)

### [UEFI Shell](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/30P-uefi-shell/)

UEFI Shell is a command line interface that allows for interacting
with the UEFI firmware. It can be used for diagnosing, debugging,
configuring and updating the firmware. Check the link in the header.
![UEFI Shell](/img/uefi_shell_v2.2.png)

### [UEFI Secure Boot](https://docs.dasharo.com/unified-test-documentation/dasharo-security/206-secure-boot/)

Secure Boot is a fundamental security feature of UEFI specification.
Thanks to secure boot, the device will only boot firmware components
which are trusted using cryptographic signatures embedded in the
firmware. Check the link in the header for more details.
![UEFI Secure Boot](/img/secure_boot.png)

### [Automatic Embedded Controller update](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31G-ec-and-superio/#ecr031001-ec-firmware-sync-in-coreboot)

The feature allows updating the Embedded Controller firmware easily
alongside updating the bios firmware.
Check out the link in the section title for more details.

### [Firmware update mode](https://docs.dasharo.com/guides/firmware-update/#firmware-update-mode)

The Firmware Update Mode is a quick way of ensuring your device
is prepared for a firmware update. It temporarily changes the
configuration and returns it to the previous state after
the update is completed. Check the link in the header for more details
and instructions on how to use it.
![Firmware Update Mode Confirmation Screen](/img/setup_menu_fum_confirmation.png)

### [BIOS boot medium write-protection](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

The recovery bios chip on your device is write-protected by default.
Modifying the firmware is only possible by entering the setup menu
and disabling the write protection explicitly or implicitly by using
Firmware Update Mode. Check the link in the header for more details
about Dasharo Security Options.

![BIOS boot medium write-protection](/img/bios_lock.png)

### [SMM BIOS write protection](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

With this option enabled, the BIOS can only be modified by
System Management Mode privileged code. It prevents flashing
the firmware with programs like [flashrom](https://www.flashrom.org/).
![SMM BIOS write protection](/img/smm_bios_write_protection.png)

### [Early boot DMA protection](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

The IOMMU DMA protection enabled early
in the POST process prevents Direct Memory Access attacks.
Leaking secrets and injecting malware using devices such
as PCIe cards and USB4/thunderbolt devices is prevented
thanks to this feature.

### [Early Sign of Life display output](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/347-sign-of-life/)

The Early Sign of Life display is a feature that displays the
firmware version during the boot phase. It is useful for
diagnosing boot issues and verifying that the firmware
is up to date.

### [Current limiting for USB-PD power supplies](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31H-usb-type-c/#utc020001-usb-type-c-pd-current-limiting-ubuntu-2204)

Limiting the current draw from USB-Power Delivery is an
important safety feature that controls the maximum current
that can flow through the USB-PD. This prevents damaging the device
as well as what it is connected to in case of any malfunction
like short circuiting the USB port.

### [Setup menu password configuration](https://docs.dasharo.com/dasharo-menu-docs/overview/#dasharo-menu-guides)

Setting up a password for the setup menu allows for
protecting the configuration from unauthorized changes.

### [Wi-Fi / Bluetooth module disable option in setup menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

### [Built-in webcam disable option in setup menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

### [USB stack disable option in setup menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#usb-configuration)

### [Network stack disable option in setup menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#networking-options)

### [Battery threshold options in setup menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#power-management-options)

### [Intel ME disable option in setup menu](https://docs.dasharo.com/osf-trivia-list/me/)

### [Block boot when battery is too low](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/359-boot-blocking/#test-cases-common-documentation)

### [Power on AC option in setup menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#power-management-options)

### [Keyboard backlight level is restored after suspend or poweroff](https://github.com/Dasharo/dasharo-issues/issues/339)

### [Fan profiles in setup Menu](https://docs.dasharo.com/unified/novacustom/fan-profiles/)

### [Fn lock hotkey feature](https://docs.dasharo.com/unified/novacustom/fn-lock-hotkey/)

### [Throttling temperature adjustment in setup menu](https://docs.dasharo.com/unified/novacustom/features/#cpu-throttling-threshold)

## Test coverage

The tests were performed on NovaCustom V540TU and V560TU platforms.
Checkout the results at our [osfv-results](https://github.com/Dasharo/osfv-results) repo:

- [V540TU](https://github.com/Dasharo/osfv-results/blob/main/boards/NovaCustom/MTL_14th_Gen/V540TU/v0.9.0-results.csv)
- [V560TU](https://github.com/Dasharo/osfv-results/blob/main/boards/NovaCustom/MTL_14th_Gen/V560TU/v0.9.0-results.csv)
The validation procedure is desribed at [laboratory assembly guide](https://docs.dasharo.com/transparent-validation/novacustom/laboratory-assembly-guide/#prerequisites).
Details about specific test cases can be found in our [Dasharo Test Specification]\
(<https://docs.dasharo.com/unified-test-documentation/overview/>)

## Our contributions

While working on the new release we have made multiple contributions
open source projects:

### Coreboot

- <https://review.coreboot.org/c/coreboot/+/82671>
- <https://review.coreboot.org/c/coreboot/+/82672>
- <https://review.coreboot.org/c/coreboot/+/82673>
- <https://review.coreboot.org/c/coreboot/+/82686>
- <https://review.coreboot.org/c/coreboot/+/82685>
- <https://review.coreboot.org/c/coreboot/+/82674>
- <https://review.coreboot.org/c/coreboot/+/82898>

### Linux kernel

- <https://github.com/torvalds/linux/commit/e1c6db864599be341cd3bcc041540383215ce05e>

> any special characters (e.q. hashtags) in the post title and abstract should
> be wrapped in the apostrophes
> avoid using quotation marks in the title, because search-engine will broke
> post abstract in the header is required for the posts summary in the blog list
> and must contain from 3 to 5 sentences, please note that abstract would be
> used for social media and because of that should be focused on
> keywords/hashtags
> post cover image should be located in `blog/static/covers/` directory or may
> be linked to `blog/static/img/` if image is used in post content
> author meta-field MUST be strictly formatted (lowercase, non-polish letters):

## Future plans

The next releases will focus on adding support for Nvidia dedicated graphics
on Meteor Lake. In addition to that we are working on a second variant of
Dasharo for Meteor Lake which will include [Heads](https://osresearch.net/) support.
<!--FIXME look up these "heads" and write something less generic-->

## Summary

## Let's get in touch

Become a part of the vibrant Dasharo community:

- Chat with Us: Join the conversation in the [Dasharo Matrix Workspace](https://matrix.to/#/#dasharo:matrix.org).
- Stay Updated: Don't miss our quarterly [Dasharo Events](https://vpub.dasharo.com/)
featuring:
  - Dasharo User Group (DUG): A forum for Dasharo users to connect,
  share experiences, and stay informed.
  - Dasharo Developers vPub: A relaxed virtual meetup for developers
  and enthusiasts to discuss, share, and connect.

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

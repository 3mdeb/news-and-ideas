---
title: New Dasharo v0.9.0 Meteor Lake releases
abstract: "Dasharo v0.9.0 for 14th gen Intel Meteor Lake has just been released
            bringing numerous new features and improvements. Check out
            what\'s new!"
cover: /covers/novacustom-dasharo-v0.9.0.png
author: filip.golas
layout: post
published: true
date: 2024-08-07
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
The newest release features numerous enhancements and improvements
related to security, functionality, and quality of life.
Thanks to everyone who contributed to this release!

## Added features

Here is a brief introduction to the changes in Dasharo v0.9.0.
For more details check out:

- [Release notes V540TU](<https://docs.dasharo.com/variants/novacustom_v540tu/releases/>)
- [Release notes V560TU](<https://docs.dasharo.com/variants/novacustom_v560tu/releases/>)

### Support for NovaCustom Meteor Lake platform (integrated graphics)

Laptop models with integrated graphics based on Meteor Lake platform are now
supported. Hold on tight, because the next release will come with support for
Nvidia dedicated graphics! Here is a brief introduction to the changes in
release v0.9.0:

### [Verified Boot signing](https://docs.dasharo.com/guides/vboot-signing/)

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
and configuring the firmware. Check the link in the header.
![UEFI Shell](/img/uefi_shell_v2.2.png)

### [UEFI Secure Boot](https://docs.dasharo.com/unified-test-documentation/dasharo-security/206-secure-boot/)

Secure Boot is a fundamental security feature of UEFI specification.
Thanks to secure boot, the device will only boot operating systems
which are trusted using cryptographic signatures embedded in the
firmware. Check the link in the header for more details.
![UEFI Secure Boot](/img/secure_boot.png)

### [Firmware Update Mode](https://docs.dasharo.com/guides/firmware-update/#firmware-update-mode)

The Firmware Update Mode is a quick way of ensuring your device
is prepared for a firmware update. It temporarily changes the
configuration and returns it to the previous state after
the update is completed. Check the link in the header for more details
and instructions on how to use it.
![Firmware Update Mode Confirmation Screen](/img/setup_menu_fum_confirmation.png)

### [BIOS boot medium lock](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

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

### [Early Boot DMA Protection](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

The IOMMU DMA protection enabled early
in the POST process prevents Direct Memory Access attacks.
Leaking secrets and injecting malware using devices such
as PCIe cards and USB4/Thunderbolt devices is prevented
thanks to this feature.

### [Sign of Life](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/347-sign-of-life/)

The Early Sign of Life display is a feature that displays the
firmware version during the boot phase. It is useful for
diagnosing boot issues and verifying that the firmware
is up-to-date.

### [Current limiting for USB-PD power supplies](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31H-usb-type-c/#utc020001-usb-type-c-pd-current-limiting-ubuntu-2204)

Limiting the current draw from USB-Power Delivery is an
important safety feature that controls the maximum current
that can flow through the USB-PD power supply.
With this feature the device will limit how much current it
draws not to exceed the power supplies specifications.
Most chargers would engage overcurrent protection if the
device tried to draw too much current, but triggering
it repeatedly could shorten the lifespan of the charger
or simply damage it.

### [Setup menu password configuration](https://docs.dasharo.com/dasharo-menu-docs/overview/#user-password-management)

Setting up a password for the setup menu allows for
protecting the configuration from unauthorized changes.

### [Wi-Fi / Bluetooth module disable option in Dasharo System Features menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

With this option enabled, the Wi-Fi and Bluetooth modules
are powered off and disabled. Use this when you want to
ensure that the device is not transmitting any data wirelessly.
![Wi-Fi / Bluetooth module disable option](/img/enable_wifi_bt.png)

### [Built-in webcam disable option in Dasharo System Features menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

With this option disabled the power to the integrated webcam
is cut off making it as good as physically removed from the device
until the camera is enabled again.
![Webcam disable option](/img/enable_camera.png)

### [USB stack disable option in Dasharo System Features menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#usb-configuration)

The option controls loading of firmware USB drivers. Disabling
it will prevent the USB devices from working until an OS
with a proper USB driver is loaded.
![Enable USB stack](/img/enable_usb_stack.png)

### [Network stack disable option in setup menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#networking-options)

The option to disable network stack prevents network controller
drivers from being loaded effectively disabling the network
connection until the OS with its own drivers is loaded.
Additionally, disabling the network stack removes the iPXE
network boot option from the boot menu until it is enabled again.
![Enable network stack](/img/enable_network_boot.png)

### [Battery threshold options in Dasharo System Features menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#power-management-options)

Thanks to this feature you can set the Start and Stop thresholds
for charging the battery. Changing these values can change the
percentage at which the device starts and stops charging
of the battery and possibly slow down it's degradation
with time.
Check the link in the header for more details.
![Battery threshold options](/img/battery_threshold.png)

### [Intel ME disable option in Dasharo System Features menu](https://docs.dasharo.com/osf-trivia-list/me/)

This option allows you to disable the Intel Management Engine
which is a subsystem that has full access to the system, including
system memory and network. It is active at any time and
is transparent to the OS. ME is proprietary software and so
it is a potential security risk.
If you don't need it, you can disable it using this option.
![Intel ME disable option](/img/intel_me_enable.png)

### [Block boot when battery is too low](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/359-boot-blocking/#test-cases-common-documentation)

With this feature enabled, the device will not boot if the battery
is below a certain threshold. The reason for this it to prevent
a situation where the charge would become too low
to support the boot process and the device would unexpectedly shut down
which could lead to data loss or corruption.
![Battery block popup](/img/battery_block_popup.jpg)

### [Power on AC option in Dasharo System Features menu](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#power-management-options)

The Power on AC option defines to what state the device should
switch to after the power is returned after a power failure.
![Power state after power failure](/img/power_state_after_power_failure.jpeg)

### [Keyboard backlight level is restored after suspend or power off](https://github.com/Dasharo/dasharo-issues/issues/339)

With this fix the keyboard backlight level is now restored
after powering off or suspending the device saving some
possible annoyance of having to set it up again.

### [Fan profiles in setup Menu](https://docs.dasharo.com/unified/novacustom/features/#fan-profiles)

This option allows you to set the fan speed profile
to suit your needs. You can choose between Silent and Performance
profiles.
![Fan profiles](/img/fan_profile.png)

### [Fn lock hotkey feature](https://docs.dasharo.com/unified/novacustom/features/#fn-lock-hotkey)

By default, using the `F1-F12` keys for additional actions like changing
the screen brightness or volume requires holding the `Fn` key.
Now you can Lock the `Fn` key so that things like muting your
microphone can be done without holding down the `Fn` key.

### [Throttling temperature adjustment in setup menu](https://docs.dasharo.com/unified/novacustom/features/#cpu-throttling-threshold)

By setting the CPU throttling threshold you can specify what
CPU temperatures are acceptable for your device. When the
cooling system does not manage to keep the CPU below this
temperature the CPU will be throttled to prevent overheating.
![Throttling temperature adjustment](/img/cpu_throttling_threshold.png)

## Known issues

There are some issues that were discovered during testing the release.
Here is a list of the issues on which we are working on:

- [No HDMI output in FW on V540TU and V560TU](https://github.com/Dasharo/dasharo-issues/issues/930)
- [Laggy behaviour on Manjaro (KDE) with open drivers](https://github.com/Dasharo/dasharo-issues/issues/911)
- [V540TU: Option Previous power state restoration doesn't work](https://github.com/Dasharo/dasharo-issues/issues/931)
- [Artifacts in video playback in some players using HW acceleration](https://github.com/Dasharo/dasharo-issues/issues/948)
- [Only native resolution listed for internal panel](https://github.com/Dasharo/dasharo-issues/issues/949)

## Test coverage

The tests were performed on NovaCustom V540TU and V560TU platforms.
Checkout the results at our
[osfv-results repo](https://github.com/Dasharo/osfv-results):

- [V540TU](https://github.com/Dasharo/osfv-results/blob/main/boards/NovaCustom/MTL_14th_Gen/V540TU/v0.9.0-results.csv)
- [V560TU](https://github.com/Dasharo/osfv-results/blob/main/boards/NovaCustom/MTL_14th_Gen/V560TU/v0.9.0-results.csv)

Details about specific test cases can be found in our [Dasharo Test Specification](https://docs.dasharo.com/unified-test-documentation/overview/).

## Our contributions

While working on the new release we have made multiple contributions
to open source projects:

### coreboot

- <https://review.coreboot.org/c/coreboot/+/82671>
- <https://review.coreboot.org/c/coreboot/+/82672>
- <https://review.coreboot.org/c/coreboot/+/82673>
- <https://review.coreboot.org/c/coreboot/+/82686>
- <https://review.coreboot.org/c/coreboot/+/82685>
- <https://review.coreboot.org/c/coreboot/+/82674>
- <https://review.coreboot.org/c/coreboot/+/82898>

### Linux kernel

- <https://github.com/torvalds/linux/commit/e1c6db864599be341cd3bcc041540383215ce05e>

### edk2

- [MrChromebox/edk2@7f398d3](https://github.com/MrChromebox/edk2/commit/7f398d3b14928ffecbbe92bd93213db91dad7703)

### systemd

- [systemd/systemd@f5c8dd8](https://github.com/systemd/systemd/commit/f5c8dd85ee13f9308498faf6a0c4837e604f8dcb)

## Future plans

The next releases will focus on adding support for Nvidia dedicated graphics
on Meteor Lake. In addition to that we are working on a second variant of
Dasharo for Meteor Lake which will include
[Heads firmware](https://osresearch.net/) support.

## Summary

Dasharo v0.9.0 for Intel Meteor Lake brings numerous new features and improvements
related to security, functionality and quality of life. We are excited to
be working on this and many other open source projects to
bring even more exciting features in the future.
Stay tuned for more updates!

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

## Sources

- Post thumbnail image based on:
[NovaCustom](https://novacustom.com/storage/NovaCustom-V54-Series-1-1024x712.png)

---
title: New NovaCustom Meteor Lake releases
abstract: 'Dasharo for 14th gen Intel Meteor Lake has just been released
          bringing numerous new features and improvements. Stay tuned for
          more updates!'
          # TODO more info about new features or someting'
cover: /covers/image-file.png
author: filip.golas
layout: post
published: false
date: 2024-07-23
archives: "2024"

tags:
  - dasharo
  - coreboot
  - novacustom
  - meteorlake
categories:
  - Firmware
  - Security

---

## Introduction

The support for newest Intel Meteor Lake platform has been added to Dasharo for
NovaCustom featuring numerous new features and improvements. Thanks to everyone who
contributed to this release!

## Added features

### Support for NovaCustom Meteor Lake platform (integrated graphics)

Laptop models with integrated graphics based on Meteor Lake platform are now
supported. Hold on tight, because the next release will come with support for
Nvidia dedicated graphics!

### [Vboot Verified Boot](https://docs.dasharo.com/guides/vboot-signing/)

### [TPM Measured Boot](https://docs.dasharo.com/unified-test-documentation/dasharo-security/203-measured-boot/)

### [Vboot recovery notification in UEFI Payload](https://docs.dasharo.com/unified-test-documentation/dasharo-security/201-verified-boot/)

### [UEFI Shell](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/30P-uefi-shell/)

### [UEFI Secure Boot](https://docs.dasharo.com/unified-test-documentation/dasharo-security/206-secure-boot/)

### [Automatic Embedded Controller update](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31G-ec-and-superio/#ecr031001-ec-firmware-sync-in-coreboot)

### [Firmware update mode](https://docs.dasharo.com/guides/firmware-update/#firmware-update-mode)

### [BIOS boot medium write-protection]()

### [SMM BIOS write protection](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

### [Early boot DMA protection](https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options)

### [Early Sign of Life display output](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/347-sign-of-life/)

### [Current limiting for USB-PD power supplies](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31H-usb-type-c/#utc020001-usb-type-c-pd-current-limiting-ubuntu-2204)

### [Setup menu password configuration](https://docs.dasharo.com/dasharo-menu-docs/overview/#dasharo-menu-guides)

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

```bash
author: filip.golas
```

> if post has multiple authors, author meta-field MUST be strictly formatted:

```bash
author:
    - name.surname
    - name.surname
```

> remove unused categories
> remember about newlines before lists, tables, quotes blocks (>) and blocks of
> text (\`\`\`)
> copy all post images to `blog/static/img` directory. Example usage:

![alt-text](/img/file-name.jpg)

> example usage of asciinema videos:

[![asciicast](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO.svg)](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO?speed=1)

> embed responsive YouTube player (copy the address after `v=`):

{{< youtube UQ-6rUPhBQQ >}}

> embed vimeo player (extract the `ID` from the video’s URL):

{{< vimeo 146022717 >}}

> embed Instagram post (you only need the photo’s `ID`):

{{< instagram BWNjjyYFxVx >}}

> embed Twitter post (you need the `URL` of the tweet):

{{< tweet user="3mdeb_com" id="1247072310324080640" >}}

## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

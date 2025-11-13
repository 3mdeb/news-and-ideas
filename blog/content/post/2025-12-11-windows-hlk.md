---
title: Windows HLK for Firmware validation
abstract: 'Learn about introducing a new tool to the arsenal of Dasharo testers.
           Windows Hardware Lab Kit - a framework able to perform over 3000 tests
           used to certify hardware and drivers as compatible with Windows'
cover: /covers/image-file.png
author: filip.golas
layout: post
published: true    # if ready or needs local-preview, change to: true
date: 2025-11-01    # update also in the filename!
archives: "2025"

tags:               # check: https://blog.3mdeb.com/tags/
  - Testing
  - Validation
  - Dasharo
categories:         # choose 1 or multiple from the list below
  - Miscellaneous

---

## Table of contents

1. Introduction and Background
1. Why Are We Interested in Windows HLK
2. Windows HLK Overview
3. Setup and Environment Configuration
4. Integration with Open Source Firmware Validation
5. Result Analysis and Product Quality Impact
6. Challenges, Mitigations, and Future Outlook

## Introduction and Background

Windows Hardware Lab Kit is the last iteration of a test automation framework
developed at Microsoft used to certify devices. The tool exists since the
times of Windows XP and has changed its name several times:

- Hardware Compatibility Test - Windows 2000, XP
- Driver Driver Kit - Windows Vista
- Windows Logo Kit / Windows Hardware Certification Kit - Windows 7, 8, 8.1
- Windows Hardware Lab Kit - Windows 10, 11

Windows HLK was quietly used every time you see a Windows sticker on a laptop,
a printer or even a game controller.

![Windows Logo certified sticker](/img/windows-sticker.png)
*https://www.microsoft.com/en-us/howtotell/hardware-pc-purchase*

In fact it contains at least `4659` unique test cases of the currently available
[test lists](https://aka.ms/HLKPlaylist).

Checked by running grep in the downloaded directory:

```bash
grep -RhoP '<Test Id="\K[^"]+' "$PWD" | sort | uniq | wc -l
```

The tests cover functionality like:
- Audio, Video, Ethernet, Wi-Fi, Bluetooth
- GPIO, I2C, USB, NFC, PWM, SPI, UART, SATA, NVME
- Drivers
- TPM

And can be used to certify products like:
- Devices
  - Desktop computers, laptops, phones
  - game controllers, keyboards, mice
  - GPUs, audio, network cards, hard drives
  - proximity, IR, motion sensors, cameras, microphones
  - displays, projectors, scanners, paper and 3d printers
  - network routers, switches
- Software
  - file systems, anti virus software
  - media players

It should leave no room for doubt how HLK is a useful tool.

## Why Are We Interested in Windows HLK

As of writing this post there are `1321` test cases available in
[Open Source Firmware Validation](https://github.com/Dasharo/open-source-firmware-validation)
as well as `78` self tests to validate the OSFV itself. While it's an impressive
number, it's far behind the vast amount of nearly `5000` tests available
in HLK, which was being built since at least year `2000`.

![OSFV tests count per module](/img/osfv_test_counts_13_11_2025.png)

It's only natural that the idea of using this huge collection of test cases
to aid Dasharo developers in finding places for improvement, as well as proving
where Dasharo works well already is very tempting. Especially considering that
new Windows issues not covered by OSFV do spring up like mushrooms

- [Immediate BSOD trying to boot Windows](https://github.com/Dasharo/dasharo-issues/issues/1598)
- [Error when enabling BitLocker](https://github.com/Dasharo/dasharo-issues/issues/1580)
- [Windows Device Manager shows errors even after updates](https://github.com/Dasharo/dasharo-issues/issues/1570)
- [Error while installing Windows 11 via USB drive](https://github.com/Dasharo/dasharo-issues/issues/1569)
- [USB mouse not working in Windows installer (USB pen drive installation)](https://github.com/Dasharo/dasharo-issues/issues/1568)
- [Windows SPM 2x suspend fails](https://github.com/Dasharo/dasharo-issues/issues/1521)

The thing that reels us in the most currently is the
[`Device.TrustedPlatformModule`](https://learn.microsoft.com/en-us/windows-hardware/test/hlk/testref/device-trustedplatformmodule-tests)
category including tests for TPM 2.0 functionality, cryptogtraphic operations,
storage, reliability and even some stress tests. While the tests would only
be run on Windows, as that's the purpose of Windows HLK, their results could
tell us a lot about the TPM functionality in Dasharo Firmware as a whole.

{{< subscribe_form "dbbf5ff3-976f-478e-beaf-749a280358ea" "Subscribe to 3mdeb Newsletter" >}}

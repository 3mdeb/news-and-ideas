---
title: Enabling Secure Boot on RockChip SoCs
abstract: 'A story about enabling Secure Boot on RockChip SoC.'
cover: /covers/image-file.png
author: artur.kowalski
layout: post
published: true
date: 2021-10-28
archives: "2021"

tags:
  - secure-boot
  - firmware
  - rockchip
  - rk3288
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

Intro

## Preparing

RockChip provides proprietary binary-only tools for signing code and burning
eFUSEs, code signing is handled by `rk_sign_tool` (Linux), `Secure Boot Tool`
(Windows), eFUSE burning is done using `eFUSE tool`. Since `eFUSE tool` is
Windows exclusive I had to setup Windows box side-by-side my Linux workstation.

I checked out latest revisions of RockChip [tools](https://github.com/rockchip-linux/tools)
and [rkbin](https://github.com/rockchip-linux/rkbin) repos.

First, I had to generate keys for code signing.

```shell
tools/linux/rk_sign_tool/rk_sign_tool cc --chip 3288
linux/rk_sign_tool/rk_sign_tool kk --out keys
```

## Signing code

eFUSE Tool accepts only a signed binary as its input, so it must be extracting
that public key from that binary, this is the same as `loader.bin` we pass to
`rkdeveloptool`, from now on I will just call it loader.

Loader can be quickly assembled using tools and config files from
`rkbin/RKBOOT`. For example to build loader for RK3288 run following command
(from `rkbin` directory)

```shell
tools/boot_merger RKBOOT/RK3288MINIALL.ini
```

I signed generated loader binary with `rk_sign_tool` without any problems.

```shell
$ ../tools/linux/rk_sign_tool/rk_sign_tool sl --key ../keys/privateKey.pem --pubkey ../keys/publicKey.pem --loader rk3288_loader_v1.09.258.bin
start to sign rk3288_loader_v1.09.258.bin
path = /hdd/rk-secure-boot/tools/linux/rk_sign_tool/temp/loader
unpacking loader start...
loader=rk3288_loader_v1.09.258.bin
output=/hdd/rk-secure-boot/tools/linux/rk_sign_tool/temp/loader/
unpacking UsbDataVRL...
unpacking rk3288_ddr_400MHz_v1...
unpacking rk3288_usbplug_v2...
unpacking FlashData...
unpacking FlashBoot...
unpack loader ok.
packing loader start...
writing entry...
writing /hdd/rk-secure-boot/tools/linux/rk_sign_tool/temp/loader/UsbDataVRL.bin
writing /hdd/rk-secure-boot/tools/linux/rk_sign_tool/temp/loader/rk3288_ddr_400MHz_v1.bin
writing /hdd/rk-secure-boot/tools/linux/rk_sign_tool/temp/loader/rk3288_usbplug_v2.bin
writing /hdd/rk-secure-boot/tools/linux/rk_sign_tool/temp/loader/FlashData.bin
writing /hdd/rk-secure-boot/tools/linux/rk_sign_tool/temp/loader/FlashBoot.bin
writing crc...
pack loader ok.(rk3288_loader_v1.09.258.bin)(0.01)
sign loader ok.
```

But when I tried loading it into eFUSE Tool I've got an error.

IMAGE

Quick analysis of unsigned and signed binary showed that signed version has
different header. This is how unsigned versions looks like.

```
00000000  42 4f 4f 54 66 00 3a 02  00 00 00 00 00 01 e5 07  |BOOTf.:.........|
00000010  0a 1c 10 15 00 41 30 32  33 01 66 00 00 00 39 01  |.....A023.f...9.|
```

And this is the signed version.

```
00000000  4c 44 52 20 66 00 3a 02  00 00 00 00 00 01 e5 07  |LDR f.:.........|
00000010  0a 1c 10 15 24 41 30 32  33 02 66 00 00 00 39 01  |....$A023.f...9.|
```



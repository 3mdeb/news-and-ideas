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

![Firmware loading failed](/img/rk_efuse_tool_error.png)

That explains everything, I've done quick analysis of unsigned and signed binary
and discovered that signed version has different header. This is how unsigned
version looks like.

```
00000000  42 4f 4f 54 66 00 3a 02  00 00 00 00 00 01 e5 07  |BOOTf.:.........|
00000010  0a 1c 10 15 00 41 30 32  33 01 66 00 00 00 39 01  |.....A023.f...9.|
```

And this is the signed version.

```
00000000  4c 44 52 20 66 00 3a 02  00 00 00 00 00 01 e5 07  |LDR f.:.........|
00000010  0a 1c 10 15 24 41 30 32  33 02 66 00 00 00 39 01  |....$A023.f...9.|
```

So I tried signing with Secure Boot Tool instead, I had to dig through RockChip
documentation to find out how to enable advanced panel - by pressing CTRL+R+K.

![Secure Boot Tool](/img/rk_secure_boot_tool.png)

Signing with `Sign Loader` produced valid binary with correct header which loads
into eFUSE Tool.

## Burning eFUSE

This was the most dangerous part as I had only try. At that time I didn't know
how eFUSE Tool operates (and there is no documentation) - it burns only public
key extracted from binary, or burns key and flashes binary onto eMMC? what will
happen if I get stuck with loader flashed onto eMMC but no U-Boot to load? does
this tool work at all? will it burn correct key or some random trash? if fusing
succeeds will be MaskROM mode still available?

RockChip always boots from SPI first, then eMMC, then SD card. There is no way
to alter boot order on these SoCs and the only way to recover from freezing boot
is to prevent BootROM from loading bootloader, this is usually done by shorting
eMMC clock to ground - BootROM is not able to load anything so it enters MaskROM
mode.

Firefly wiki has a page about
[entering MaskROM](https://wiki.t-firefly.com/en/Firefly-RK3288/maskrom_mode.html),
with photos showing where is eMMC clock exposed, the problem is that this does
not match my board.

This is how top part of my boards like, not testpoints here.

![Firefly RK3288 Front](/img/firefly_rk3288_front.jpg)

This is how bottom looks like, still differs from board image posted on wiki.

![Firefly RK3288 Back](/img/firefly_rk3288_back.jpg)

There is one pad which looks like eMMC clock but I couldn't be 100% sure if this
is it, anyway that testpoint was very close to tiny resistors, which I could
accidentially tear apart.

### First attempt

Before loading binary into eFUSE Tool I verified whether that binary works
using.

```
rkdeveloptool db RK3288_Loader_signed.bin
```

Loading went well and DDR init started flooding serial console with useless
messages - so far everything looks good.

So I opened eFUSE tool, note that you can change language to English.

![eFUSE Tool language select](/img/efuse_tool_lang_select.png)

I loaded signed loader binary, clicked `Run` button and connected device.

![eFUSE Tool ready](/img/efuse_tool_green.png)

Unfortunatelly eFUSE burning failed almost instantly.

![eFUSE burn fail](/img/efuse_tool_fail.png)

eFUSE tool didn't say anything useful, actually it didn't say anything at all,
I've got some information dumped on serial console but still nothing useful.

```
EfuseWriteData 0 100 3100d00 0
write efuse: 03100d00 + 0x0:0x00,0x01,0x00,0x01,0x00,0x01,0x00,0x01,0x01,0x01,0x01,0x00,0x01,0x01,0x00,0x00,
write efuse: 03100d00 + 0x10:0x00,0x01,0x00,0x01,0x01,0x01,0x01,0x01,0x01,0x00,0x00,0x01,0x00,0x01,0x00,0x00,
write efuse: 03100d00 + 0x20:0x00,0x01,0x00,0x00,0x01,0x01,0x01,0x00,0x00,0x01,0x01,0x01,0x00,0x00,0x00,0x01,
write efuse: 03100d00 + 0x30:0x01,0x00,0x01,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x01,0x00,0x00,
write efuse: 03100d00 + 0x40:0x00,0x01,0x00,0x01,0x00,0x01,0x01,0x01,0x01,0x00,0x00,0x00,0x00,0x01,0x01,0x01,
write efuse: 03100d00 + 0x50:0x01,0x00,0x00,0x00,0x00,0x01,0x00,0x01,0x01,0x01,0x01,0x01,0x00,0x01,0x00,0x01,
write efuse: 03100d00 + 0x60:0x00,0x00,0x01,0x01,0x01,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
write efuse: 03100d00 + 0x70:0x01,0x01,0x01,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x01,0x01,0x00,0x01,0x00,
write efuse: 03100d00 + 0x80:0x00,0x01,0x01,0x00,0x01,0x01,0x00,0x00,0x01,0x00,0x01,0x01,0x00,0x00,0x00,0x00,
write efuse: 03100d00 + 0x90:0x01,0x00,0x00,0x00,0x01,0x01,0x00,0x01,0x01,0x00,0x01,0x01,0x01,0x00,0x01,0x01,
write efuse: 03100d00 + 0xa0:0x01,0x00,0x01,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x00,0x01,
write efuse: 03100d00 + 0xb0:0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x01,0x00,
write efuse: 03100d00 + 0xc0:0x01,0x00,0x01,0x00,0x01,0x00,0x00,0x01,0x00,0x00,0x01,0x00,0x00,0x01,0x00,0x00,
write efuse: 03100d00 + 0xd0:0x01,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x01,0x01,0x01,0x01,0x00,0x01,0x00,
write efuse: 03100d00 + 0xe0:0x01,0x01,0x01,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x01,0x00,0x01,0x01,0x01,0x00,
write efuse: 03100d00 + 0xf0:0x01,0x01,0x01,0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x01,0x01,0x01,0x00,0x00,0x00,

hash write to OTP: 03343c1c + 0x0:0xaa,0x37,0xfa,0x29,0x72,0x8e,0x25,0x26,0xea,0xe1,0xa1,0xaf,0x9c,0x01,0xc7,0x58,
hash write to OTP: 03343c1c + 0x10:0x36,0x0d,0xb1,0xdd,0x35,0xb0,0x04,0x78,0x95,0x24,0x89,0x5e,0x67,0x74,0x87,0x1f,

EfuseReadData 100 100 3343c58 1
efuse1: 03100010 + 0x0:0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,
efuse1: 03100010 + 0x40:0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,

EfuseProg 8 29fa37aa
EfuseProg 9 26258e72
EfuseProg a afa1e1ea
EfuseProg b 58c7019c
EfuseProg c ddb10d36
EfuseProg d 7804b035
EfuseProg e 5e892495
EfuseProg f 1f877467
EfuseReadData 100 100 3343c58 1
efuse1: 03100010 + 0x0:0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,
efuse1: 03100010 + 0x40:0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,

257 efuse prog error, read = 0 write = 1
```

Board turned out to be still alive and nothing had changed in its behaviour so I
carried on.

### Problem analysis

I started looking for solution and I found document titled `RK3399 Efuse
Operation Instructions`, most interesting is the last section called `Efuse
power up`.

![eFUSE power up](/img/rk_efuse_power_up.png)

I downloaded board schematic from
[Firefly support page](https://en.t-firefly.com/doc/download/4.html), note that
there are two board versions, each download is an zip archive containing
schematic and board component layout. I wanted to compare both layouts to find
out which matches the board I have, but I couldn't see any differences. So I
checked both schematics looking for something that would let me power on eFUSEs
and I found this.

![eFUSE test point](/img/firefly_rk3288_efuse_testpoint.png)

EFUSE_VQPS pin is connected to testpoint T17, which is located on board back
side, behind SoC.

![T17 location](/img/firefly_t17_location.png)

On board it is located here.

![T17 location on board](/img/firefly_t17_location_on_board.jpg)

### Attempt 2

I took an lab power supply, I was looking for some thin probes but I couldn't
find so I used the probes I had with male jumper wires.

![powering eFUSEs](/img/powering_efuses.jpg)

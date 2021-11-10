---
title: Enabling Secure Boot on RockChip SoCs
abstract: 'RockChip Secure Boot is an essential security feature that helps
          tablet, PC, streaming media TV box, and IoT solution vendors secure
          their devices against malware infecting the firmware. In the following
          post, we will tell a story about enabling Secure Boot on the RK32xx
          family, but the lesson learned can be used on other models'
cover: /covers/rockchip-logo.jpg
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

RockChip is a Chinese company manufacturing low-cost ARM SoCs , yet with good
performance. Another advantage is reasonably good support for mainline Linux
with many drivers already mainlined. Documentation for the most popular RockChip
SoCs and schematics of reference boards are publicly available. Unfortunately,
they are severely lacking in the area of Secure Boot, with very unclear
instructions on how to enable it. Besides incomplete official documentation,
there is no meaningful information available on the Internet. We hope the state
of RockChip's documentation will change for the better soon.

## Secure Boot overview

Secure Boot is a feature that prevents a device from running untrusted firmware,
essential for securing IoT devices against persistent malware. Without Secure
Boot, anyone who gains physical access (or remote access by exploiting software
vulnerability) to a device may put malware into its firmware, thus permanently
compromising it. With Secure Boot enabled, BootROM verifies firmware before
executing it - even if an attacker replaces firmware, it won't pass verification
and thus won't boot at all.

Secure Boot is implemented both in software and hardware. Most ARM SoCs
(including RockChip) come with so-called eFUSE's, which are used for storing
various information, including public key used for establishing Root-of-Trust.
eFUSE can be programmed only once, making it impossible to replace or remove the
once written key. When a device powers on, it starts executing BootROM. BootROM
is a small program that is burned onto ROM during SoC's manufacturing process,
and it's responsible for loading a next-stage bootloader (usually U-Boot's SPL).
If Secure Boot is enabled, BootROM verifies loaded bootloader against public key
stored in eFUSE's - execution takes place only when verification is successful.
From now on, Root of Trust gets extended into Chain of Trust - SPL is
responsible for verifying U-Boot, which is responsible for verifying Linux, etc.

To get Secure Boot working, the following things must be done.

- Generate private and public keypair
- Burn public key into eFUSE's
- Sign `idbloader.img` (U-Boot TPL+SPL merged into one file)
- Configure Verified Boot in SPL and U-Boot
- Flash signed firmware.

![RockChip Secure Boot provisioning](/img/rockchip-secure-boot-diagram.svg)

Let's begin.

## Preparing

RockChip provides proprietary binary-only tools for signing code and burning
eFUSEs. Code signing is handled either by `rk_sign_tool` (Linux) or Secure Boot
Tool (Windows), eFUSE burning is done using eFUSE Tool. Since eFUSE Tool is
Windows exclusive, I had to set up Windows box side-by-side my Linux
workstation.

I checked out latest revisions of RockChip [tools](https://github.com/rockchip-linux/tools)
and [rkbin](https://github.com/rockchip-linux/rkbin) repos.

First, I had to generate keys for code signing.

```shell
tools/linux/rk_sign_tool/rk_sign_tool cc --chip 3288
linux/rk_sign_tool/rk_sign_tool kk --out keys
```

This generated a 2048-bit RSA key. Some of the older RockChip SoCs use 1024-bit
RSA instead, while future SoCs may use 4096-bit RSA or even a completely
different algorithm.

## Signing code

eFUSE Tool accepts only a signed binary as its input, from which it extracts
the public key. The binary used here is the same binary we pass to
`rkdeveloptool` when flashing firmware to eMMC. I will call it loader from now
on.

Loader can be quickly assembled using tools and config files from
`rkbin/RKBOOT`. For example, to build loader for RK3288, run the following
command (from `rkbin` directory)

```shell
tools/boot_merger RKBOOT/RK3288MINIALL.ini
```

I signed generated loader binary using `rk_sign_tool` without any problems.

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

That was an extremely helpful message. To find out what's wrong, I've done a
quick analysis of unsigned and signed binary and discovered that the signed
version has a different header - this is how the unsigned version looks like.

```
00000000  42 4f 4f 54 66 00 3a 02  00 00 00 00 00 01 e5 07  |BOOTf.:.........|
00000010  0a 1c 10 15 00 41 30 32  33 01 66 00 00 00 39 01  |.....A023.f...9.|
```

And this is the signed version.

```
00000000  4c 44 52 20 66 00 3a 02  00 00 00 00 00 01 e5 07  |LDR f.:.........|
00000010  0a 1c 10 15 24 41 30 32  33 02 66 00 00 00 39 01  |....$A023.f...9.|
```

Secure Boot Tool has support for signing loader binary, but it is disabled when
program starts. I had to dig through RockChip documentation to find out how to
enable it. Hint: press <kbd>Ctrl</kbd>+<kbd>r</kbd>+<kbd>k</kbd>.

![Secure Boot Tool](/img/rk_secure_boot_tool.png)

Signing with Secure Boot Tool produced binary with a correct header that eFUSE
Tool understands. Note that even though eFUSE Tool cannot load binaries built by
`rk_sign_tool`, `rkdeveloptool` works with them just fine.

## Burning eFUSE

This was the most dangerous part as I had only one try. At that time, I didn't
know how eFUSE Tool operates (as there is no documentation) - it burns only
public key extracted from binary, or burns the key and flashes binary onto eMMC?
What will happen if I get stuck with loader flashed onto eMMC but no U-Boot to
load? Does this tool work at all? Will it burn the correct key or some random
trash? If fusing succeeds, will be MaskROM mode still available?

RockChip always boots from SPI first, then eMMC, SD card, and finally MaskROM.
There is no way to alter the boot order, so the only way to recover (get back
into MaskROM) from freezing boot is to prevent BootROM from loading bootloader
by shorting the eMMC clock to the ground.

Firefly wiki has a page about
[entering MaskROM](https://wiki.t-firefly.com/en/Firefly-RK3288/maskrom_mode.html),
with photos showing where eMMC clock is exposed, but the problem is that this
does not match my board.

This is how the top part of my board looks like - no test points here.

![Firefly RK3288 Front](/img/firefly_rk3288_front.jpg)

The bottom side still differs from the board image posted on wiki.

![Firefly RK3288 Back](/img/firefly_rk3288_back.jpg)

One of the pads looks like an eMMC clock, but I couldn't be 100% sure if this is
it. Anyway, that test point was very close to tiny resistors, which I could
accidentally tear apart.

### First attempt

Before loading binary into eFUSE Tool, I verified whether that binary works by
using:

```
rkdeveloptool db RK3288_Loader_signed.bin
```

Loading went well, and DDR init started flooding my serial console with useless
messages - so far, everything looks good.

So I opened eFUSE Tool. Note that you can change the language to English.

![eFUSE Tool language select](/img/efuse_tool_lang_select.png)

I loaded a signed loader binary, clicked `Run` button, and connected the device.

![eFUSE Tool ready](/img/efuse_tool_green.png)

Unfortunately, eFUSE burning failed almost instantly.

![eFUSE burn fail](/img/efuse_tool_fail.png)

eFUSE Tool didn't say anything useful. Actually, it didn't say anything at all
(no logs either). I've got some information dumped on the serial console, but
still not very helpful.

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
efuse1: 03100010 + 0x0:0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,(...)
efuse1: 03100010 + 0x40:0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,(...)

EfuseProg 8 29fa37aa
EfuseProg 9 26258e72
EfuseProg a afa1e1ea
EfuseProg b 58c7019c
EfuseProg c ddb10d36
EfuseProg d 7804b035
EfuseProg e 5e892495
EfuseProg f 1f877467
EfuseReadData 100 100 3343c58 1
efuse1: 03100010 + 0x0:0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,(...)
efuse1: 03100010 + 0x40:0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,0x00000000,(...)

257 efuse prog error, read = 0 write = 1
```

Board turned out to be still alive, and nothing had changed in its behavior, so
I carried on.

### Problem analysis

I started looking for a solution, and I found a document titled
[RK3399 Efuse Operation Instructions](https://usermanual.wiki/Document/RK3399EfuseOperationInstructionsV10020190214.1448491699/view).
The most interesting is the last section called `Efuse power up`.

![eFUSE power up](/img/rk_efuse_power_up.png)

I downloaded board schematic from the
[Firefly support page](https://en.t-firefly.com/doc/download/4.html) (note that
there are two board versions). Each download is a zip archive containing a
schematic and board component layout. I didn't know which board revision I had.
Also, I couldn't see any differences in schematics or layouts, so I
double-checked that the relevant part is the same on both revisions.

This is what I have found:

![eFUSE test point](/img/firefly_rk3288_efuse_testpoint.png)

EFUSE_VQPS pin is connected to test point T17, located on the backside, behind
the SoC.

![T17 location](/img/firefly_t17_location.png)

On the board, it is located here.

![T17 location on board](/img/firefly_t17_location_on_board.jpg)

### Attempt 2

I took a lab power supply. I tried to find some thin probes without success, so
I used the probes I had, together with male jumper wires.

![powering eFUSEs](/img/powering_efuses.jpg)

It took me a few tries before I succeeded - I was touching a tiny resistor
placed right next to the test point, draining too much power, around 300 mA.
This is very dangerous for the board. Luckily, my board survived. After a few
tries, I got it right, and eFUSE burning succeeded.

![eFUSE burn successful](/img/efuse_tool_success.png)

## What's next

Board got into MaskROM mode, and I successfully ran a signed loader using
`rkdeveloptool db`. Messages from the serial console show that secure mode is
active.

```
DDR Version 1.09 20201119
In
Channel a: DDR3 400MHz
Bus Width=32 Col=10 Bank=8 Row=15 CS=1 Die Bus-Width=16 Size=1024MB
Channel b: DDR3 400MHz
Bus Width=32 Col=10 Bank=8 Row=15 CS=1 Die Bus-Width=16 Size=1024MB
Memory OK
Memory OK
OUT
Boot1 Release Time: Nov 27 2019 15:30:08, version: 2.58
ChipType = 0x8, 248
mmc2:cmd19,100
SdmmcInit=2 0
BootCapSize=1000
UserCapSize=14910MB
FwPartOffset=2000 , 1000
mmc0:cmd5,20
SdmmcInit=0 0
BootCapSize=0
UserCapSize=30436MB
FwPartOffset=2000 , 0
StorageInit ok = 46317
SecureMode = 1
SecureInit read PBA: 0x4
atags_set_pub_key: ret:(0)
SecureInit ret = 0, SecureMode = 1
(...)
```

Loading of unsigned one no longer works - `rkdeveloptool` hangs. MaskROM won't
accept any commands until DDR Init is loaded, thus preventing unauthorized
access to eMMC and data dump. U-Boot from SD card no longer boots. You can see
it for yourself on the following video:

[![asciicast](https://asciinema.org/a/c4J0pRqWL4WlYeqVH04MGLSiC.svg)](https://asciinema.org/a/c4J0pRqWL4WlYeqVH04MGLSiC)

Loader can be flashed onto eMMC using the following commands. Note that this
flashes only loader, without U-Boot itself.

```
rkdeveloptool db RK3288_Loader_signed.bin
rkdeveloptool ul RK3288_Loader_signed.bin
```

## Summary

So far, I have managed to get Secure Boot working on RK3288. Still, we need some
way to sign U-Boot's `idbloader.img`. Also we need support for verifying U-Boot
image from SPL. These two topics will be covered in the next post. If you think
we can help in improving the security of your firmware or you looking for
someone who can boost your product by leveraging advanced features of used
hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to
[sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

---
ID: 62811
title: '0x3: Embedded board bootloader'
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/0x3-embedded-board-bootloader/
published: true
date: 2013-06-07 10:32:00
tags:
  - qemu
  - embedded
  - linux
  - u-boot
  - VDB
categories:
  - Firmware
---
## Table of contents ##

* [What is bootloader ?](/2013/06/07/embedded-board-bootloader/#what-is-bootloader)
* [Why we need bootloader ?](/2013/06/07/embedded-board-bootloader/#why-we-need-bootloader)
* [Which bootloader ?](/2013/06/07/embedded-board-bootloader/#which-bootloader)
* [What is versatilepb ?](/2013/06/07/embedded-board-bootloader/#what-is-versatilepb)
* [Compilation](/2013/06/07/embedded-board-bootloader/#compilation)
* [Where to go from here ?](/2013/06/07/embedded-board-bootloader/#where-to-go-from-here)
* [Kudos](/2013/06/07/embedded-board-bootloader/#kudos)

<a id="what-is-bootloader"></a>
### What is bootloader ? ###
It is a program written to bring up more complex code (eg. kernel).

On very simple system it can even not exist. Bootloader should prepare all
required hardware that kernel or different operating software will need at its
start point. It is hard to create cross platform bootloader because of variety
of system requirements.

<a id="why-we-need-bootloader"></a>
### Why we need bootloader ? ###
The true is that we don't :) because we can simply pass kernel and initramfs as
parameters to QEMU, but it is not common practice for real development environment.  
Usually bootloader is stripped in production environment where boot time is
crucial. Second thing, bootloader is useful to learn how real development
environment for embedded system works. From other side using bootloader we can
create single binary file that contain bootable embedded system, so we can run
it without giving multiple arguments at QEMU startup. I will try to keep in mind
idea about being as close to real development environment as possible.

<a id="which-bootloader"></a>
### Which bootloader ? ###
There are many approaches to this problem. The most popular today is
[U-Boot](http://www.denx.de/wiki/U-Boot) but there are alternatives like [The Barebox Bootloader](http://www.barebox.org/).
I will try to get to know them better in future. Right now I will use U-Boot as
Virtual Development Board bootloader to make the edit-compile-download-test cycle
similar to real world situation. So get the code:
```bash
git clone http://git.denx.de/u-boot.git
```

U-Boot configuration depends on pair cpu-board. So right now we know that our
cpu will be some ARM but what exactly ? It depends on configuration we will use.
In most scenarios presented in Internet the `versatilepb` was used. We can also
think about running different boards.

What pros U-Boot gives us in the light of previous question `Why we need
bootloader ?`:

* simplified process of porting kernel, because low level stuff is handled by
U-Boot
* simplified testing environment in easy way you can grab different version of
  kernel with different version of initrd and test it


<a id="what-is-versatilepb"></a>
### What is versatilepb ? ###
According to [this page](http://www.arm.com/products/tools/development-boards/versatile/index.php)
versatile is highly modular, feature-rich range of development board. `pb`
means `Platform Baseboard` integrated, standalone development system with fixed
CPU. But this is only corporate babble :)

QEMU shows `versatilepb` as Versatile/PB
([ARM926EJ-S](http://www.arm.com/products/processors/classic/arm9/arm926.php)).

<a id="compilation"></a>
### Compilation ###
For `Emdebian` cross-toolchain:
```bash
cd u-boot
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- versatilepb_config
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
```

_Note_: If you wonder what is the convention for cross-toolchain prefix:
```
[arch]-[vendor]-[os]-[abi]
```
`Emdebian` striped vendor probably to keep name short, but for example
`Corsstool-NG` follow convetion and calls toolchain like
`arm-unknown-linux-gnueabi-`.

<a id="where-to-go-from-here"></a>
### Where to go from here ? ###
[Next step](/2013/06/07/linux-kernel-for-embedded-system) will be kernel compilation for our virtual `versatilepb` board.

<a id="kudos"></a>
### Kudos ###

[1] [Introduction to Das U-Boot, the universal open source bootloader](http://www.linuxfordevices.com/c/a/Linux-For-Devices-Articles/Introduction-to-Das-UBoot-the-universal-open-source-bootloader/)</br>
[2] [U-Boot](http://www.denx.de/wiki/U-Boot)</br>
[3] [U-boot for the multi-boot support](http://forum.xda-developers.com/showthread.php?t=2201146)</br>
[4] [Booting Linux with U-Boot on QEMU ARM](http://balau82.wordpress.com/2010/04/12/booting-linux-with-u-boot-on-qemu-arm/)</br>
[5] [Bootloader](http://wiki.osdev.org/Bootloader)</br>

---
ID: 62821
title: '0x4: Linux kernel for embedded system'
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/0x4-linux-kernel-for-embedded-system/
published: true
date: 2013-06-07 10:33:00
year: "2013"
tags:
  - qemu
  - embedded
  - linux
  - kernel
  - VDB
categories:
  - OS Dev
---
## Table of contents ##

* [A little history](/2013/06/07/linux-kernel-for-embedded-system/#a-little-history)
* [Get linux and build it](/2013/06/07/linux-kernel-for-embedded-system/#get-linux-and-build-it)
* [Kudos](/2013/06/07/linux-kernel-for-embedded-system/#kudos)

<a id="a-little-history"></a>
### A little history ###
Thinking about embedded linux probably leads to  first try of porting linux to
different architecture. I did google research (I know I should probably read
mailing list archive) and found that there were few attempt to port linux to
different platform. There is no clear information about which port of linux was
first. This is probably because many hackers didn't report their effort. Arguably
earliest out-of-tree version was probably for Acron A5000 (arm), Motorola 68000
(m68k) around Spring/Summer of 1994. I found also notes about SPARC port in
1993. Some sources also tells story about 1993 Amiga and Atari port. But first
port that get in to official linux tree was DEC Alpha.[[1]](http://digital-domain.net/lug/unix-linux-history.html)[[2]](http://www.arm.linux.org.uk/docs/history.php)

So linux is already 22 years old and first port start when it was 2-3 years old,
so we can assume it is mature enough to support most of non-x86 architectures.

<a id="get-linux-and-build-it"></a>
### Get linux and build it ###

To deal with our _embedded_ board we need operating system or some kind of
software that will allow us to use board features. Right now to boot system we
need at least kernel. So we have to prepare kernel for board of choice
`versatilepb`.

Let's start with cloning Linux repository:
```
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
```
and configure kernel for `versatilepb`.
```
cd linux
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- versatile_defconfig
```

It looks some feature is disabled in `versatile_defconfig`. I mean
`CONFIG_AEABI`. It specifies file format, data types, register usage and other
things. The main difference between EABI and ABI is that privileged instructions
are allowed in application code. More about EABI
[here](http://en.wikipedia.org/wiki/Application_binary_interface#EABI).
To enable this option run:
```
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- menuconfig
```
and go to:
```
Kernel Features -> Use the ARM EABI to compile the kernel
```
We will also need DHCP and NFS support (CONFIG_IP_PNP_DHCP and CONFIG_ROOT_NFS).
First is `IP: DHCP support` and can be found under:
```
-> Networking support (NET [=y])
  -> Networking options
    -> TCP/IP networking (INET [=y])
      -> IP: kernel level autoconfiguration (IP_PNP [=y])
```
Second is :
```
-> File systems
  -> Network File Systems (NETWORK_FILESYSTEMS [=y])  
```
let's build image with U-Boot support.
```
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- uImage
```
We have kernel. How we can provide this kernel to our development environment ?
As I discuss in [previous post](/2013/06/07/embedded-board-bootloader) we
can use bare-metal qemu, but not with uImage kernel. This is special U-Boot
kernel, so easiest way will be using it with bootloader. We will figure out how
to do this in [next section](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board)
about tftp and qemu network configuration.

__TODO__: add picture of configuration in intro - vdb, link it here
Target configuration will consist on providing kernel through tftp server using U-Boot. Also
want to use NFS root filesystem to boot our small distro. As it is in real
development environment.

_NOTE_: During compilation process you can encounter error like this:
```
(...)
  UIMAGE  arch/arm/boot/uImage
  "mkimage" command not found - U-Boot images will not be built
  make[1]: *** [arch/arm/boot/uImage] Error 1
  make: *** [uImage] Error 2
```
Of course it means that we need mkimage to create U-Boot image, so:
```
sudo apt-get install uboot-mkimage
```
_Update_: in Debian jessie/sid this package was replaced by `u-boot-tools`.

We have to use uImage special build because load and execute address differes
from board to board. If we will use vmlinux image then addresses should be
manually modified. So using uImage is easiest

<a id="kudos"></a>
### Kudos ###
[1] [UNIX/Linux History](http://digital-domain.net/lug/unix-linux-history.html)</br>
[2] [The History of ARM Linux](http://www.arm.linux.org.uk/docs/history.php)

---
ID: 62646
title: flashrom and Shuttle AV18E2
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/flashrom-and-shuttle-av18e2/
published: true
date: 2012-01-06 14:31:00
year: "2012"
tags:
  - coreboot
categories:
  - Firmware
---
During Christmas break I found an old unused motherboard in my home, right away
I thought that it maybe useful as learning environment for coreboot. First you
need to do with this kind of board is to check if it is possible to flash its
BIOS with user space tool called [flashrom][1]  List of supported hardware can
be found [here][2]. All you need to do is go through [this HOWTO][3]. Be aware
that these operations can cause you will not be able to run your motherboard if
something goes wrong. Therefore, I suggest protect yourself by supplying checked
programmer or other memory chip for your board containing a working BIOS. For my
[Shuttle board][4] I checked if the Winbond W49F002U chip on it is supported by
flashrom. Fortunately it was. After that I read my BIOS by:

    flashrom -Vr bios_bckp.bin

And write it by:

    flashrom -Vw bios_bckp.bin

At the end I've got VERIFIED message but when I look carefully inside the log
there was something like this:

    Erasing and writing flash chip... Trying erase function 0... 0x000000-0x01ffff:S, 0x020000-0x037fff:S,
    0x038000-0x039fff:S, 0x03a000-0x03bfff:S, 0x03c000-0x03ffff:S Erase/write done. Verifying flash... VERIFIED.

This means that these addresses have not been overwritten but skipped, becuse
the fact that the data which were to be overridden were identical with what we
wanted to write. So if we found such output to properly verify flashrom we need
to clear our memory and write it again with BIOS backup. Correct output should
look like this:

    Erasing and writing flash chip... Trying erase function 0... 0x000000-0x01ffff:W, 0x020000-0x037fff:W,
    0x038000-0x039fff:W, 0x03a000-0x03bfff:W, 0x03c000-0x03ffff:W Erase/write done. Verifying flash... VERIFIED.  

Next post I will try to familiarize you with the process of debugging coreboot
using [QEMU][5].

 [1]: http://www.flashrom.org/
 [2]: http://www.flashrom.org/Supported_hardware
 [3]: http://www.flashrom.org/Board_Testing_HOWTO
 [4]: http://www.shuttle.eu/_archive/older/de/av18.htm
 [5]: http://wiki.qemu.org/Main_Page

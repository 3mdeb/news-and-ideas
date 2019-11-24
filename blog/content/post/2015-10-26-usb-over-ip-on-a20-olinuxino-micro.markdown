---
layout: post
title: "USB over IP on A20-OLinuXino-MICRO and RPi using Buildroot"
date: 2015-10-26 21:00:07 +0100
comments: true
categories: usbip A20 olinuxino linux embedded
---

During last month I see increased interesting with my pretty old article
[Linux, RPi and USB over IP](2014/08/18/linux-rpi-and-usb-over-ip/). There is
even [StackExchange question](http://unix.stackexchange.com/questions/131732/usbip-problem-getting-device-attributes-no-such-file-or-directory)
in "Unix & Linux" section about using USB to RS232 converter over IP. Because
of that I decided to combine this topic with my new member of development board
family.

<a class="fancybox" rel="group" href="/assets/images/dev-boards.jpg"><img src="/assets/images/dev-boards.jpg" alt="" /></a>

BTW who can guess all the names ? :)

The board that joined the team is Olimex "high end" A20 board - [A20-OLinuXino-MICRO-4G](https://www.olimex.com/Products/OLinuXino/A20/A20-OLinuXino-MICRO-4GB/open-source-hardware).


<a class="fancybox" rel="group" href="/assets/images/a20-olinuxino-micro.jpg"><img src="/assets/images/a20-olinuxino-micro.jpg" alt="" /></a>

I assume all that rush maybe related to articles like [this from CNX](http://www.cnx-software.com/2015/10/21/how-to-use-an-esp8266-board-as-a-wifi-to-serial-debug-board/).

### Setup

Setup will be little bit different then in previous article. I will try to show
how to setup kernel on OLinuXino with support for USB over IP using
[sunxi-next](https://github.com/linux-sunxi/linux-sunxi/tree/sunxi-next).
OLinuXino will pass USB traffic, related to captured serial output from
development board, over Ethernet to router then over WiFi to target board which
will be RPi. This will show setup for server and client side of USB over IP method.

<a class="fancybox" rel="group" href="/assets/images/a20-usbip.png"><img src="/assets/images/a20-usbip.png" alt="" /></a>

### A20-OLinuXino-MICRO setup

Fastest way of creating bootable SD card for OLinuXino will be using
[Buildroot](http://buildroot.uclibc.org/). Because at this point Buildroot do
not use most recent version of U-Boot and Linux kernel I pushed branch that
simplify setup on OLinuXino.

```
git clone https://github.com/pietrushnic/buildroot.git -b a20-olinuxino-micro-usbip
cd buildroot
make olimex_a20_olinuxino_micro_defconfig
make -j$(nproc)
```

After building process finish please follow further [setup instructions](https://raw.githubusercontent.com/pietrushnic/buildroot/a20-olinuxino-micro-usbip/board/olimex/a20_olinuxino/readme.txt)
to setup SD card.


### Raspberry Pi setup


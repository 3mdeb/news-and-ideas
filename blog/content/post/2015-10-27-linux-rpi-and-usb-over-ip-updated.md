---
ID: 62921
title: Linux, RPi and USB over IP updated
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/linux-rpi-and-usb-over-ip-updated/
published: true
date: 2015-10-27 12:50:03
tags:
  - embedded
  - linux
  - RaspberryPi
  - Usbip
  - Broadcom
categories:
  - OS Dev
---
Because of increasing interesting in USB over IP topic I decided to refresh my
[old post](2014/08/18/linux-rpi-and-usb-over-ip/). I will focus on doing the
same thing with more recent version of Raspabian. If you need more information
please read my previous post.

## Setup SD card

First get recent version of
[Raspbian](https://www.raspberrypi.org/downloads/raspbian/), then unzip and dd
it to SD card:

```
sudo dd bs=4M if=2015-09-24-raspbian-jessie.img of=/dev/sdc
```

If you are impatient and want to know what happen in background you can use
this method of tracking dd progress:

```
sudo sh -c "while true; do killall -USR1 dd; sleep 1; done"
```

Before removing card we have to be sure that all data were wrote to card:

```
sync
```

If this operation takes time you can watch progress work writeback and dirty
kilobytes using:

```
watch grep -e Dirty: -e Writeback: /proc/meminfo
```

When sync will finish you can remove SD card and sanity check booting on RPi.

## Kernel for RPi

After booting you should be able to ssh to your RPi and check if USBIP was
compiled in your kernel.

```
pi@raspberrypi ~ $ sudo modprobe configs
pi@raspberrypi ~ $ zcat /proc/config.gz |grep USBIP
CONFIG_USBIP_CORE=m
CONFIG_USBIP_VHCI_HCD=m
CONFIG_USBIP_HOST=m
# CONFIG_USBIP_DEBUG is not set
```

Great! It looks like both server and client support was compiled as modules in
recent Raspbian.

## Run server side of usbip

Unfortunately `usbip` user space tools are not available from scratch and have
to be installed:

```
sudo apt-get install usbip
```

Then you can run server:

```
pi@raspberrypi ~ $ sudo modprobe usbip-core
pi@raspberrypi ~ $ sudo modprobe usbip-host
pi@raspberrypi ~ $ sudo usbipd -D
```

Without connecting anything we get only internal Ethernet device  when listing:

```
pi@raspberrypi ~ $ usbip list -l
 - busid 1-1.1 (0424:ec00)
    Standard Microsystems Corp. : SMSC9512/9514 Fast Ethernet Adapter (0424:ec00)
```

Let's put some memory stick and check again:

```
pi@raspberrypi ~ $ usbip list -l
 - busid 1-1.1 (0424:ec00)
   Standard Microsystems Corp. : SMSC9512/9514 Fast Ethernet Adapter (0424:ec00)

 - busid 1-1.2 (0951:1666)
   Kingston Technology : unknown product (0951:1666)
```

Good `usbip` see our storage device. Let's try to bind it:

```
pi@raspberrypi ~ $ sudo usbip --debug bind -b 1-1.2
usbip: debug: /build/linux-tools-06nnfo/linux-tools-3.16/drivers/staging/usbip/userspace/src/usbip.c:141:[run_command] running command: `bind'
usbip: info: bind device on busid 1-1.2: complete
```

### Client side

Let's check if device was correctly exposed by server on RPi. Of course we need
`usbip` package installed.

```
[13:28:50] pietrushnic:~ $ sudo usbip list -r 192.168.0.105
Exportable USB devices
======================
 - 192.168.0.105
      1-1.3: Toshiba Corp. : TransMemory-Mini / Kingston DataTraveler 2.0 Stick (2GB) (0930:6544)
           : /sys/devices/platform/soc/20980000.usb/usb1/1-1/1-1.3
           : (Defined at Interface level) (00/00/00)
```

Information is even more accurate then on RPi. Of course `192.168.0.105` have
to be replaced with you IP address.

Quickly check if client support correct modules:

```
[13:18:36] pietrushnic:~ $ grep USBIP /boot/config-`uname -r`
CONFIG_USBIP_CORE=m
CONFIG_USBIP_VHCI_HCD=m
CONFIG_USBIP_HOST=m
# CONFIG_USBIP_DEBUG is not set
```

Everything looks ok. Let's load hos module:

```
sudo modprobe vhci-hcd
```

Now we can attach remote storage:

```
sudo usbip attach -r 192.168.0.105 -b 1-1.3
```

```
[13:29:15] pietrushnic:~ $ sudo fdisk -l /dev/sdd
GPT PMBR size mismatch (13695 != 3911615) will be corrected by w(rite).
Disk /dev/sdd: 1.9 GiB, 2002747392 bytes, 3911616 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 2164228A-0AD4-43A8-9478-0E94701363B1

Device     Start   End Sectors  Size Type
/dev/sdd1   2048 13662   11615  5.7M EFI System
[13:29:27] pietrushnic:~ $ sudo mount /dev/sdd1 tmp
[13:29:39] pietrushnic:~ $ ls tmp
EFI  shellia32.efi  shellx64.efi  shellx64-refind-signed.efi
```

Let's left some signs:

```
[13:30:55] pietrushnic:~ $ sudo sh -c "echo DEADBEEF > tmp/foobar"
[13:31:08] pietrushnic:~ $ cat tmp/foobar
DEADBEEF
```

Detach and see if we will see this file on server side:

```
[13:33:31] pietrushnic:~ $ sudo usbip port
Imported USB devices
====================
Port 00: <Port in Use> at High Speed(480Mbps)
       unknown vendor : unknown product (0930:6544)
       5-1 -> usbip://192.168.0.105:3240/1-1.3
           -> remote bus/dev 001/005
[13:33:39] pietrushnic:~ $ sudo usbip detach -p 0
```

First let's unbind:

```
pi@raspberrypi ~ $ sudo usbip unbind -b 1-1.3
usbip: info: unbind device on busid 1-1.3: complete
```

Then mount partition on which we placed out test file:

```
pi@raspberrypi ~ $ sudo mount /dev/sda1 tmp/
pi@raspberrypi ~ $ cat tmp/foobar
DEADBEEF
```

## Summary

This is quick refresh for those struggling with running `usbip`. There many
topics to cover in this area I think about writing posts related to below
topics:

- `usbip` on Raspberry Pi 2
- passing frames for RS232 to USB converter using `usbip`
- A20-OLinuXino-MICRO/Cubietruck and `usbip`

If you any other preference or topics that would like to see on this blog
please let me know in comments. If you think this post can be useful for others
please share.

Thanks for reading.

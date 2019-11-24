---
layout: post
title: "OpenWRT in QEMU"
date: 2014-08-10 19:04:17 +0200
comments: true
categories: embedded, openwrt
---

In below article I would like to go through process of configuring, building
and running [OpenWRT](https://openwrt.org/) in
[QEMU](http://wiki.qemu.org/Main_Page) using `realview-eb-mpcore` machine as a
target.

## OpenWRT

We will use latest OpenWRT version from git repository:

```
git clone git://git.openwrt.org/openwrt.git
```

Enter configuration by `make menuconfig` and choose below options:
```
Target System -> ARM Ltd. Realview board (qemu)
```
Compile using simple:
```
make
```
After those operations we are ready to boot OpenWRT:
```
QEMU_AUDIO_DRV=none qemu-system-arm -M realview-eb-mpcore -kernel bin/realview/openwrt-realview-vmlinux-initramfs.elf -net nic -net user -nographic
```
Because of obvious reason `openwrt-realview-vmlinux.elf` will not boot - no rootfs.

## Non-volatile OpenWRT configuration

The main problem with above configuration is that all we can do happens on
`make manuconfig` time. We cannot do a lot inside initramsfsa, because we have
only tmpfs. What are the options for persistent storage:

* SCSI disk - known as `-hda` option in QEMU
* NFS
* SD card

Unfortunately none of those solution works right from the box.

### SCSI disk

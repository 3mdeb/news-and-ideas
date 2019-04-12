---
ID: 62936
title: Emulate Rapberry Pi 2 in QEMU
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/emulate-rapberry-pi-2-in-qemu/
published: true
date: 2015-12-30 23:02:30
tags:
  - qemu
  - embedded
  - linux
categories:
  - OS Dev
  - App Dev
---
In the process of planning system testing for one of my clients I found that
someone from Microsoft published patches with [BCM2836 support](https://lists.gnu.org/archive/html/qemu-arm/2015-12/msg00078.html) to
QEMU mailing list. I thought it is very interesting, because if it is possible
to setup emulated Raspberry Pi many use cases can be tested faster and in more
automatic way. For example checking how application behave when running on more
then one device at once, testing massive deployment process, stress testing and
finally speed up debug-fix-test process.

So it looks like making RPi 2 working in emulated environment can add a lot of
value to some products. In email Andrew mention [github repo](https://github.com/0xabu/qemu), which I would like to try in this post

## Get QEMU and compile

```
git clone https://github.com/0xabu/qemu.git -b raspi
git submodule update --init dtc
./configure
make -j$(nproc)
sudo make install
```

## Prepare to boot

QEMU requires kernel and device tree file to be given as parameters, because of
that we have to extract those pieces from existing Raspbian image.

### Get kernel and device tree

```
wget http://downloads.raspberrypi.org/raspbian/images/raspbian-2015-11-24/2015-11-21-raspbian-jessie.zip
unzip 2015-11-21-raspbian-jessie.zip
[23:35:23] pietrushnic:rpi2_qemu $ sudo /sbin/fdisk -lu 2015-11-21-raspbian-jessie.img
Disk 2015-11-21-raspbian-jessie.img: 3.7 GiB, 3934257152 bytes, 7684096 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xea0e7380

Device                          Boot  Start     End Sectors  Size Id Type
2015-11-21-raspbian-jessie.img1        8192  131071  122880   60M  c W95 FAT32 (LBA)
2015-11-21-raspbian-jessie.img2      131072 7684095 7553024  3.6G 83 Linux
```

Check start of `W95 FAT32 (LBA)` partition. It is `8192`. Sector size is `512`.
So calculate offset in bytes `8192 * 512 = 4194304`.

```
mkdir tmp
sudo mount -o loop,offset=4194304 2015-11-21-raspbian-jessie.img tmp
mkdir 2015-11-21-raspbian-boot
cp tmp/kernel7.img 2015-11-21-raspbian-boot
cp tmp/bcm2709-rpi-2-b.dtb 2015-11-21-raspbian-boot
```

Then if you try to boot `2015-11-21` Rapbian with `0xabu` code:

```
qemu-system-arm -M raspi2 -kernel 2015-11-21-raspbian-boot/kernel7.img \
-sd 2015-11-21-raspbian-jessie.img \
-append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2" \
-dtb 2015-11-21-raspbian-boot/bcm2709-rpi-2-b.dtb -serial stdio
```

You will experience kernel crash:

```
(...)
[    6.021989] Freeing unused kernel memory: 420K (80779000 - 807e2000)
[    7.366232] random: systemd urandom read with 7 bits of entropy available
[    7.383057] Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000004
[    7.383057]
[    7.384366] CPU: 0 PID: 1 Comm: systemd Not tainted 4.1.13-v7+ #826
[    7.384874] Hardware name: BCM2709
[    7.386615] [<80018444>] (unwind_backtrace) from [<80013e08>] (show_stack+0x20/0x24)
[    7.387307] [<80013e08>] (show_stack) from [<8055a188>] (dump_stack+0x98/0xe0)
[    7.387851] [<8055a188>] (dump_stack) from [<80556340>] (panic+0xa4/0x204)
[    7.388515] [<80556340>] (panic) from [<800293c8>] (do_exit+0xa0c/0xa64)
[    7.389074] [<800293c8>] (do_exit) from [<800294b8>] (do_group_exit+0x4c/0xcc)
[    7.389729] [<800294b8>] (do_group_exit) from [<80033f1c>] (get_signal+0x2b0/0x6e0)
[    7.390388] [<80033f1c>] (get_signal) from [<80013190>] (do_signal+0x98/0x3ac)
[    7.391021] [<80013190>] (do_signal) from [<8001368c>] (do_work_pending+0xb8/0xc8)
[    7.391665] [<8001368c>] (do_work_pending) from [<8000f9e4>] (work_pending+0xc/0x20)
[    7.393209] ---[ end Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000004
[    7.393209]
```

To avoid this crash you have to comment `/etc/ld.so.preload`.

### Changing ld.so.preload

First calculate offset in bytes to Raspbian root filesystem partition.
According to fdisk output above partition starts with sector `131072`, so offset
would be `512*131072=67108864`.

```
sudo mount -o loop,offset=67108864 2015-11-21-raspbian-jessie.img tmp
```

Use your favourite editor to change `tmp/etc/ld.so.preload`. Note that you have
to edit as superuser. Content of file should looks like this:

```
#/usr/lib/arm-linux-gnueabihf/libarmmem.so
```

Sync and umount partition:

```
sync
sudo umount tmp
```

### Final booting


```
qemu-system-arm -M raspi2 -kernel 2015-11-21-raspbian-boot/kernel7.img \
-sd 2015-11-21-raspbian-jessie.img \
-append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2" \
-dtb 2015-11-21-raspbian-boot/bcm2709-rpi-2-b.dtb -serial stdio
```

## Summary

There are many problem with existing setup, but from my experience this is best
approach and code that I saw during last years. Also it looks like this code is
backed by huge corporation so it looks like they see value in providing this
code to wide community. Rapid delivery of those patches probably would not be
possible without previous work to which Andrew point in his email. It would be
great to see community engagement in this effort.

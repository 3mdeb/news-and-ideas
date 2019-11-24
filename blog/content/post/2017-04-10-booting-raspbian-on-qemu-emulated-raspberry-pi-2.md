---
author: Piotr Król
layout: post
title: "IoTvity in emulated Raspbian using QEMU Raspberry Pi 2"
date: 2017-04-10 16:56:11 +0200
comments: true
categories: raspberrypi raspbian linux
---

Huge success of my [first post](2015/12/30/emulate-rapberry-pi-2-in-qemu/)
published over 1.5 year ago makes me think I have to revisit previous article
and describe most recent development in area of Raspberry Pi 2 emulation in
QEMU.

I started research with what really happen on qemu-devel mailing lists, but
didn't found anything interesting. It looks like Peter Maydell, who is ARM
maintainer in QEMU, repository contain recent changes for Raspberry Pi
platform. If you look for recent development from Peter please check his
[qemu-arm repository](http://git.linaro.org/people/pmaydell/qemu-arm.git/).
Just to make sure I have most recent version for ARM emulation I used Peter
repository.

Couple git hacks show that recent development related with BCM283x platform
implements SDHOST and GPIO.

What I thought may be interesting is running IoTvity on Raspberry Pi 2 QEMU and
see if I can run any example application. This will give me chance to exercise
recent Raspbian in QEMU.

I used `raspbian-2017-04-10` downloaded from
[here](http://downloads.raspberrypi.org/raspbian/images/raspbian-2017-04-10/).

## QEMU compilation

```
git clone http://git.linaro.org/people/pmaydell/qemu-arm.git/
git checkout -b staging origin/staging
git submodule update --init dtc
git submodule update --init pixman
./configure --target-list=arm-softmmu
make -j$(nproc)
```

## Booting recent Raspbian

```
$ wget http://downloads.raspberrypi.org/raspbian/images/raspbian-2017-04-10/2017-04-10-raspbian-jessie.zip
$ unzip 2017-04-10-raspbian-jessie.zip
$ sudo /sbin/fdisk -lu 2017-04-10-raspbian-jessie.img
Disk 2017-04-10-raspbian-jessie.img: 4 GiB, 4285005824 bytes, 8369152 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x402e4a57

Device                          Boot Start     End Sectors Size Id Type
2017-04-10-raspbian-jessie.img1       8192   92159   83968  41M  c W95 FAT32 (LBA)
2017-04-10-raspbian-jessie.img2      92160 8369151 8276992   4G 83 Linux
```

What is interesting to us is sector size `512` and start of FAT32 partition
which is `8192`. This things not changed since last blog post. Having those
numbers we can calculate offset to extract kernel and device tree `8192 * 512 = 4194304`.

```
mkdir tmp
sudo mount -o loop,offset=4194304 2017-04-10-raspbian-jessie.img tmp
mkdir 2017-04-10-raspbian-boot
cp tmp/kernel7.img 2017-04-10-raspbian-boot
cp tmp/bcm2709-rpi-2-b.dtb 2017-04-10-raspbian-boot
cp tmp/bcm2710-rpi-3-b.dtb 2017-04-10-raspbian-boot
umount tmp
sudo umount tmp
qemu/arm-softmmu/qemu-system-arm -M raspi2 -kernel \
2017-04-10-raspbian-boot/kernel7.img -sd 2017-04-10-raspbian-jessie.img -append \
"rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 \
root=/dev/mmcblk0p2" -dtb 2017-04-10-raspbian-boot/bcm2709-rpi-2-b.dtb -serial \
stdio
```

Both RPi2 and RPi3 device tree booting fine, so there is space for
implementation of Raspberry Pi 3 on QEMU.

```
Raspbian GNU/Linux 8 raspberrypi ttyAMA0

raspberrypi login: pi
Password:
Last login: Mon Apr 10 10:37:06 UTC 2017 on tty1
Linux raspberrypi 4.4.50-v7+ #970 SMP Mon Feb 20 19:18:29 GMT 2017 armv7l

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
pi@raspberrypi:~$ cat /proc/cpuinfo
processor       : 0
model name      : ARMv7 Processor rev 1 (v7l)
BogoMIPS        : 38.40
Features        : half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm
CPU implementer : 0x41
CPU architecture: 7
CPU variant     : 0x2
CPU part        : 0xc0f
CPU revision    : 1

Hardware        : BCM2709
Revision        : 0000
Serial          : 0000000000000000
```

### Power off issue

There is small problem with `poweroff` command - it cause kernel panic:

```
[  810.803169 ] reboot: Power down
[  810.818825 ] Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000000
[  810.818825 ]
[  810.820349 ] CPU: 0 PID: 1 Comm: systemd-shutdow Not tainted 4.4.50-v7+ #970
[  810.820837 ] Hardware name: BCM2709
[  810.823672 ] [<800187c0>] (unwind_backtrace) from [<80014094>] (show_stack+0x20/0x24)
[  810.824347 ] [<80014094>] (show_stack) from [<80321ce4>] (dump_stack+0xd4/0x118)
[  810.825024 ] [<80321ce4>] (dump_stack) from [<800fd8f0>] (panic+0xb0/0x220)
[  810.825605 ] [<800fd8f0>] (panic) from [<80028250>] (do_exit+0xaa8/0xab0)
[  810.826191 ] [<80028250>] (do_exit) from [<800455a0>] (SyS_reboot+0x150/0x1e4)
[  810.826713 ] [<800455a0>] (SyS_reboot) from [<8000fb60>] (ret_fast_syscall+0x0/0x1c)
[  810.828238 ] ---[ end Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000000
[  810.828238 ]]
```

`reboot` hangs machine, so there is also something wrong with implementation.
I'm not sure what QEMU default behavior in that area should be.

## Networking

Key problem with booting RPi 2 in QEMU is networking. We cannot do anything
fancy without that. For real use case original networking configuration would
be needed, but at this point I would be glad with any outside communication for
system upgrade and package installation needs.

There is no easy way to add DWC2 OTG controller support to QEMU. It look like
amount of documentation available is sufficient enough to start some
development, but this may take time.

Some interesting resources that found related to that issue:

[Xvisor](https://groups.google.com/d/msg/xvisor-devel/ppMBc_839KA/Aew7odF3HgAJ)


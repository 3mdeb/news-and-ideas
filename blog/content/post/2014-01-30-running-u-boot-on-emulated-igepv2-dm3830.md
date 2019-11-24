---
author: Piotr Król
layout: post
title: "Running ISSE IGEPv2 (DM3730) in QEMU"
date: 2017-04-14 15:27:05 +0100
comments: true
categories: vdb embedded igepv2 linux dm3730
---

First, you can ask why I choose IGEPv2 for this article ? And I
have to admit that I was strongly influenced by Free Electrons training
materials in 2014 that I studied to improve my embedded skills.

I started this post in 2014 and took a lot of dust. IGEPv5 is on the market and
Free Electrons no longer use IGEPv2 (they now use SAMA5D3 for trainings).
Despite all that changes I decided that blog post should be finished and work I
spent on researching this hardware should not be lost.

It look that there is still [some community around DM3730](https://www.isee.biz/support/tags/dm3730) so there may be value for
people dealing with ISEE platform.

## Initial triage

When I take a close look at [IGEPv2](https://www.isee.biz/products/igep-processor-boards/igepv2-dm3730)
site I found interesting [IGEP QEMU Emulator](https://www.isee.biz/support/downloads/item/qemu-emulator) package.
As a embedded beginner I tried to be frugal and when I found QEMU I treat it
as an opportunity to save 180 EUR for a while and improve my skills in
configuring virtual development environment.

Package contain few interesting things inside:

1. Small patch IGEP QEMU patch
2. igep-nano 512MB OS image
3. few qemu binaries (`qemu-ga`, `qemu-io,` `qemu-nbd,` ...)

To start ASAP lets investigate our image with [`binwalk`]():

```
[14:44:10] pkrol:igepv2-dm3730 git:(master*) $ tar jxvf QEMU-linaro.2012.12.01.tar.bz2
QEMU/
QEMU/0001-IGEP_QEMU_support.path
QEMU/qemu-linaro.tar.gz
QEMU/igep-nano.img.tgz
[14:47:39] pkrol:igepv2-dm3730 git:(master*) $ binwalk igep-nano.img

DECIMAL   	HEX       	DESCRIPTION
-------------------------------------------------------------------------------------------------------------------
1073440   	0x106120  	U-Boot boot loader reference
1170815   	0x11DD7F  	U-Boot boot loader reference
(...)
54525952  	0x3400000 	Linux EXT filesystem, rev 1.0 ext4 filesystem data, UUID=0008119d-9b57-4eb8-9a77-d16828b728b7, volume name "rootfs"
59163909  	0x386C505 	Linux kernel version "2.6.37+ (mcaro@manel-VirtualBox2) (gcc version 4.6.1 (Ubuntu/Li2) (gcc version 4.6.1 (Ubuntu/Linaro 4.6.1-7ubuntu2~ppa3) ) #1 "
(...)
```

From binwalk log we can read a lot of interesting things for example that we
have installed wpasupplicant, filesystem used is ext4 and kernel version is
modified 2.6.37 built inside VirtualBox. ISEE website contain IGEP SDK VM that
I will review below. So we have some disk image but how to connect it ? Quick
look into patch delivered in package show that we can use `-sd` or `-mtdblock`
parameter of Qemu.

NOTE: When I tried to run attached qemu on my x86_64 laptop I get some library
errors, like this below:

```
qemu-linaro/bin/qemu-system-arm: error while loading shared libraries: libbluetooth.so.3: cannot open shared object file: No such file or directory
```

to fix that you have to install i386 packages with the library:

```
sudo apt-get install libbluetooth3:i386
```

Then I tried
```
[18:03:20] pkrol:igepv2-dm3730 git:(master*) $ qemu-system-arm -M igep -sd igep-nano.img -serial stdio
VNC server running on `::1:5900'


IGEP-X-Loader 2.3.0-1 (Jan 10 2012 - 13:08:47)
XLoader: IGEPv2 : kernel boot ...
Uncompressing Linux... done, booting the kernel.
```

Platform booting, but after attaching VNC I had black screen. Redirecting to
serial doesn't help, so I decided to look inside system configuration to reveal
booting information and see what exactly going on with kernel.

My mistake was not looking first through ISEE website. There is [wiki about QEMU](http://labs.isee.biz/index.php/QEMU).
Using suggested command:

```
qemu-system-arm -M igep -m 512 -clock unix -serial stdio \
-drive file=igep-nano.img,if=sd,cache=writeback -usb \
-monitor telnet:localhost:7100,server,nowait,nodelay \
-device usb-kbd -device usb-mouse
```

Worked better:

```
[    2.468750] mmci-omap-hs mmci-omap-hs.1: could not set regulator OCR (-22)
[    2.544097] ------------[ cut here ]------------
[    2.544555] WARNING: at drivers/regulator/core.c:1371 _regulator_disable+0x3c/0x114()
[    2.544891] unbalanced disables for dummy
[    2.545104] Modules linked in:
[    2.545501] [<c0044bf4>] (unwind_backtrace+0x0/0xe0) from [<c00652b8>] (warn_slowpath_common+0x4c/0x64)
[    2.545928] [<c00652b8>] (warn_slowpath_common+0x4c/0x64) from [<c0065350>] (warn_slowpath_fmt+0x2c/0x3c)
[    2.546356] [<c0065350>] (warn_slowpath_fmt+0x2c/0x3c) from [<c0235094>] (_regulator_disable+0x3c/0x114)
[    2.546783] [<c0235094>] (_regulator_disable+0x3c/0x114) from [<c0235198>] (regulator_disable+0x2c/0x68)
[    2.547180] [<c0235198>] (regulator_disable+0x2c/0x68) from [<c032612c>] (omap_hsmmc_23_set_power+0xa4/0xf8)
[    2.547546] [<c032612c>] (omap_hsmmc_23_set_power+0xa4/0xf8) from [<c0325330>] (omap_hsmmc_set_ios+0x70/0x3b0)
[    2.547912] [<c0325330>] (omap_hsmmc_set_ios+0x70/0x3b0) from [<c0318614>] (mmc_power_off+0x44/0x48)
[    2.548278] [<c0318614>] (mmc_power_off+0x44/0x48) from [<c031a004>] (mmc_rescan+0x294/0x2cc)
[    2.548614] [<c031a004>] (mmc_rescan+0x294/0x2cc) from [<c0075d28>] (process_one_work+0x1e0/0x32c)
[    2.548950] [<c0075d28>] (process_one_work+0x1e0/0x32c) from [<c0076614>] (worker_thread+0x1ac/0x2dc)
[    2.549285] [<c0076614>] (worker_thread+0x1ac/0x2dc) from [<c007978c>] (kthread+0x7c/0x84)
[    2.549591] [<c007978c>] (kthread+0x7c/0x84) from [<c0040c48>] (kernel_thread_exit+0x0/0x8)
[    2.549957] ---[ end trace 6fb798c344641c3e ]---
[    2.557159] EXT3-fs (mmcblk0p2): error: couldn't mount because of unsupported optional features (240)
[    2.558593] EXT2-fs (mmcblk0p2): error: couldn't mount because of unsupported optional features (244)
[    2.625762] EXT4-fs (mmcblk0p2): warning: checktime reached, running e2fsck is recommended
[    2.628234] EXT4-fs (mmcblk0p2): recovery complete
[    2.628936] EXT4-fs (mmcblk0p2): mounted filesystem with ordered data mode. Opts: (null)
[    2.629821] VFS: Mounted root (ext4 filesystem) on device 179:2.
[    2.630371] Freeing init memory: 204K

Last login: Wed Jan 11 11:37:23 UTC 2012 on tty1
Welcome to Linaro 11.10 (development branch) (GNU/Linux 2.6.37+ armv7l)

 * Documentation:  https://wiki.linaro.org/
root@linaro-nano:~#
```

### igep-nano image investigation

It is possible to modify image content. First mount boot partition:

```
mkdir tmp
sudo mount -o offset=$[63*512] igep-nano.img tmp
```

You can find there `igep.ini` file which is consumed by x-loader:

```
; Setup the Kernel console params
console=ttyO2,115200n8
; Enable early printk
;earlyprintk=serial,ttyS2,115200
```

This should mean that serial console is configured on port 2. There are also
early printk that can be configured.

You can also investigate root partition:

```
sudo mount -o offset=$[106496*512] igep-nano.img tmp
```

## How to debug X-loader in QEMU

### X-loader compilation

Get toolchain from
[here](https://www.isee.biz/support/downloads/item/igep-sdk-yocto-toolchain-1-2-2-3)
and follow installation steps from
[here](http://labs.isee.biz/index.php/The_IGEP_X-loader#Build_with_ISEE_SDK_Yocto_Toolchain_1.2).

```
git clone git://git.isee.biz/pub/scm/igep-x-loader.git
```

QEMU Emulator from ISEE has X-loader 2.3.0-1 and most recent version is
2.6.0-2.

```
source /opt/poky/1.2/environment-setup-armv7a-vfp-neon-poky-linux-gnueabi
cd igep-x-loader
make igep00x0_config
make
```

### X-loader update

Bootloader is update simply by copying to boot partition:

```
sudo mount -o offset=$[63*512] igep-nano.img tmp
cp MLO tmp/MLO
sudo umount tmp
```

After that you will see:

```
IGEP-X-Loader 2.6.0-2 (May 14 2017 - 18:40:10)
XLoader: Memory Manufacturer: Numonyx
XLoader: Configuration file igep.ini Loaded from MMC
XLoader: kernel zImage loaded from MMC at 0x80008000 size = 3043416
Uncompressing Linux... done, booting the kernel.
```

### Debugging

Very convenient way is to use terminal user interface for GDB as `cgdb`. First
you have to start QEMU in debugging mode with `-s -S` prams which add GDB
server and stop CPU at QEMU start.

```
qemu-system-arm -M igep -m 512 -clock unix -serial stdio \
-drive file=igep-nano.img,if=sd,cache=writeback -usb \
-monitor telnet:localhost:7100,server,nowait,nodelay \
-device usb-kbd -device usb-mouse -s -S
```

Then run `cgdb`:

```
cgdb -d arm-poky-linux-gnueabi-gdb x-load
```


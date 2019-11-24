---
layout: post
title: "Debugging Rasperry Pi 2 kernel in QEMU"
date: 2016-01-01 23:44:48 +0100
comments: true
categories: embedded linux qemu
---

## Debugging Raspbian in QEMU

Very useful notes about Linux kernel debugging using GDB and QEMU can be found
[here](https://www.kernel.org/doc/Documentation/gdb-kernel-debugging.txt).

### Obtain toolchain

Raspberry Pi community provide recommended toolchain in GitHub repository.
Unfortunately Linaro toolchains `gcc-linaro-arm-linux-gnueabihf-raspbian*` were
not compiled with Python support, so if you plan to use Python during debugging
you should use `arm-bcm2708hardfp-linux-gnueabi-`.

```
git clone https://github.com/raspberrypi/tools.git
export PATH=${PWD}/tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin:${PATH}
```

### Obtain Linux kernel config

First let's compile (almost) exact the same kernel as used in Raspbian. To
verify Raspbian kernel flash image on sd card and boot on real hardaware. Then
login and modprobe `configs` module:

```
sudo modprobe configs
```

In procfs you will see new file `/proc/config.gz`. Copy it to machine on which
you will cross-compile Linux kernel.

Running `zcat config.gz|head` will show you:

```
#
# Automatically generated file; DO NOT EDIT.
# Linux/arm 4.1.13 Kernel Configuration
#
CONFIG_ARM=y
CONFIG_SYS_SUPPORTS_APM_EMULATION=y
CONFIG_HAVE_PROC_CPU=y
CONFIG_STACKTRACE_SUPPORT=y
CONFIG_LOCKDEP_SUPPORT=y
CONFIG_TRACE_IRQFLAGS_SUPPORT=y
```

### Compile Raspbian kernel

Then clone Raspberry Pi kernel repository to your workstation:

```
git clone https://github.com/raspberrypi/linux.git
cd linux
```

Check which commit contain `4.1.13` release. I'm doing this by displaying [tree view in console](https://github.com/pietrushnic/dotfiles/blob/master/gitconfig#L10):

```
(...)
* | 3ac4e40bb6ea config: Add FB_TFT_ILI9163 module
* |   bc1669c846b6 (HEAD -> 4.1.13) Merge remote-tracking branch 'stable/linux-4.1.y' into rpi-4.1.y
|\ \  
| |/  
| * 1f2ce4a2e7ae Linux 4.1.13
| * 50eda1546d87 dts: imx6: fix sd card gpio polarity specified in device tree
| * e4338aeff6aa xen: fix backport of previous kexec patch
(...)
```

Based on above I checked out `bc1669c846b6`. Copy configuration obtained from
Raspberry Pi:

```
zcat /path/to/config.gz > .config
```

Enable useful debugging option in menuconfig:

```
ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make menuconfig
```

Options:

```
Kernel hacking > Compile-time checks and compiler options > Compile the kernel with debug info
Kernel hacking > Compile-time checks and compiler options > Provide GDB scripts for kernel debugging
```

Compile:

```
ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make -j$(nproc) zImage dtbs
```

### Execute QEMU

Note that some changes to root filesystem have to be made to boot Raspbian. You
can read about it in my previous
[post](http://blog.3mdeb.com/2015/12/30/emulate-rapberry-pi-2-in-qemu/).

```
qemu-system-arm -M raspi2 -kernel arch/arm/boot/zImage \
-sd path/to/2015-11-21-raspbian-jessie.img \
-append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2" \
-dtb ./arch/arm/boot/dts/bcm2709-rpi-2-b.dtb \
-usbdevice mouse -usbdevice keyboard -serial stdio -s -S
```

### Run gdb

Note that I assume you running `gdb` in Raspberry Pi kernel directory and you
have exported toolchain path.


```
$ arm-linux-gnueabihf-gdb vmlinux
GNU gdb (crosstool-NG linaro-1.13.1+bzr2650 - Linaro GCC 2014.03) 7.6.1-2013.10
Copyright (C) 2013 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "--host=x86_64-build_unknown-linux-gnu --target=arm-linux-gnueabihf".
For bug reporting instructions, please see:
<https://bugs.launchpad.net/gcc-linaro>...
Reading symbols from /home/pietrushnic/projects/substances_actives/linux/vmlinux...done.
(gdb) target remote :1234 
Remote debugging using :1234
__vectors_start () at arch/arm/kernel/entry-armv.S:1219
1219            W(b)    vector_rst
```

Great we are ready to debug Linux kernel.

### Debugging session

Because last valuable output from kernel log was:

```
[    7.366232] random: systemd urandom read with 7 bits of entropy available
```

I greped kernel searching for `entropy available`. It look like this code is in
`drivers/char/random.c` function `urandom_read`. It looks like this is best
place to start.

```

```


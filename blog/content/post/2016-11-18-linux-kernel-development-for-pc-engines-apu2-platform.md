---
author: Piotr Król
layout: post
title: "Linux kernel development for PC Engines APU2 platform"
date: 2016-11-18 22:28:00 +0100
comments: true
categories: apu2 embedded linux pxe
---

Professional development setup can save a lot of time. Unfortunately despite
TFTP+NFS flow is well known and widely used most materials in Google are
outdated and incomplete. This is probably because large variety of possible
configurations starting from tftp and nfs version and ending on target specific
setup.

To not reinvent things it would be best to use some ready to use pieces.
Containers are great for packing those parts of setup and apply in different
places.

## Contenerized PXE server

Some time we published [pxe-server](https://github.com/3mdeb/pxe-server), which
is dockerized PXE server that you can easily setup on your workstation or
server machine.

### Removing tftpd-hpa

First make sure you don't have `tftpd-hpa` or any other tftp server running on
your host since it can clash with container. Using contenerized PXE will give
you TFTP, so host configuration should not be needed. You can of course just
stop host service for purpose of checking below configuration `sudo service tftpd-hpa stop`.
If you want to get rid of `tftpd-hpa`

```
sudo apt-get purge tftpd-hpa
```

### Building pxe-server

This steps assume you have Docker correctly installed and configured.

```
git clone https://github.com/3mdeb/pxe-server.git
cd pxe-server
./init.sh
```

There is no need to add something like `serial 0 11500 0` to
`pxelinux.cfg/default` since output is already correctly redirected for
firmware versions `v4.0.x` series.

### Booting Debian installer using iPXE shell

```
iPXE> dhcp net0  
iPXE> set filename pxelinux.0
iPXE> set next-server <ip_address>
iPXE> chain tftp://${next-server}/${filename}
```

Please note that shortcut `chain tftp://<ip_address>/pxelinux.0` for some
reason will not work. This smells like bug, since chain should set
`next-server` variable if it is not set. Booting without `next-server` set lead
to hang like this:

```
iPXE> chain tftp://<ip_address>/pxelinux.0
tftp://<ip_address>/pxelinux.0... ok

PXELINUX 6.03 PXE 20160618 Copyright (C) 1994-2014 H. Peter Anvin et al
```

Please note that if you want to install Debian you should change kernel booting
parameters to make installer available on serial console. To do that when you screen:

```
                 +---------------------------------------+
                 | Debian GNU/Linux installer boot menu |
                 |---------------------------------------|
                 | Install                               |
                 | Advanced options                    > |
                 | Help                                  |
                 |                                       |
                 |                                       |
                 |                                       |
                 |                                       |
                 |                                       |
                 |                                       |
                 |                                       |
                 +---------------------------------------+

> debian-installer/i386/linux vga=788 initrd=debian-installer/i386/initrd.gz console=ttyS0,115200n8

              Press ENTER to boot or TAB to edit a menu entry 
```

Press `TAB` and modify parameter as on above log (remove `quiet` and add
appropriate `console`).

## Linux kernel booting from TFTP

```
iPXE> kernel tftp://<ip_address>/debian-installer/i386/linux console=ttyS0,115200n8
iPXE> initrd tftp://<ip_address>/debian-installer/i386/initrd.gz
iPXE> boot
```

## Kernel compilation for APU2

### Getting minimal config from Debian

```
sudo apt-get install linux-source
cd /usr/src/
tar xf linux-source-4.8.tar.xz
cd linux-source-4.8
cp /boot/config-`uname -r` .config
```

## coreboot GDB debugging for APU2

Enable below option in `make menuconfig`:

```
Debugging -> GDB debugging support 
Debugging -> Wait for a GDB connection
```

Build and flash new image. Note that it is good to have cross debugger for
APU2. You can build it with coreboot using:

```
make crosstools-i386
```

Disable minicom and boot platform:

```
cgdb -d ./util/crossgcc/xgcc/bin/i386-elf-gdb -nh
(gdb) target remote /dev/ttyUSB1
(gdb) file build/cbfs/fallback/ramstage.elf
```



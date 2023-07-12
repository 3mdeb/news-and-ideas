---
ID: 62836
title: '0x6: Root file system for embedded system'
author: piotr.krol
post_excerpt: ""
layout: post
published: true
date: 2013-06-07 10:40:00
archives: "2013"
tags:
  - embedded
  - linux
  - rootfs
categories:
  - OS Dev
---
## Table of contents ##

* [Introduction](/2013/06/07/root-file-system-for-embedded-system/#intro)
* [Get and build BusyBox](/2013/06/07/root-file-system-for-embedded-system/#get-bb)
* [Fast and simple](/2013/06/07/root-file-system-for-embedded-system/#fast-and-simple)
* [Setting up kernel through NFS](/2013/06/07/root-file-system-for-embedded-system/#setting-up-kernel-through-nfs)
* [Verify Configuration](/2013/06/07/root-file-system-for-embedded-system/#verify-configuration)
* [Embedded filesystem tuning](/2013/06/07/root-file-system-for-embedded-system/#embedded-filesystem-tuning)
* [Summary](/2013/06/07/root-file-system-for-embedded-system/#summary)

<a id="intro"></a>
### Introduction ###
To make our embedded linux work as virtual development platform we need some
environment after booting. There is many approaches to get working root file
system but I will use the easiest one as an exercise. I don't want to create full
embedded distribution (this is good plan for future works). Right now I will be
happy with simple initramfs based on [BusyBox](http://busybox.net/).

For all interested in creating own root filesystem there are few places where
you can find informations:

* [Embedded Linux: Small Root Filesystems](http://lwn.net/Articles/210046/)
* [ramfs-rootfs-initramfs](https://www.kernel.org/doc/Documentation/filesystems/ramfs-rootfs-initramfs.txt)
* [Creating a Root File System for Linux on OMAP35x](http://processors.wiki.ti.com/index.php/Creating_a_Root_File_System_for_Linux_on_OMAP35x)

<a id="get-bb"></a>
### Get and build BusyBox ###
Clone git repository:
```
git clone git://git.busybox.net/busybox
```

<a id="fast-and-simple"></a>
### Fast and simple ###
Of course make sure to use correct toolchain. I made few notes about
Ubuntu/Linaro toolchain in [previous post](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/#ubuntu-issues)
```
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- menuconfig
```
Mark `Busybox Settings -> Build Options -> Build BusyBox as a static binary (no
shared libs)` option. Exit and save.
```
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- install
cd _install/
```
<a id="setting-up-kernel-through-nfs"></a>
### Setting up kernel through NFS ###
[Previously](/2013/06/07/linux-kernel-for-embedded-system) we prepared U-Boot
kenernel image with DHCP and rootfs which we want to expose over NFS. First lets start with NFS
configuration:
```
sudo apt-get install nfs-kernel-server
```
I use simple `/etc/exports` configuration:
```
/srv/homes 192.168.1.0/255.255.255.0(rw,sync,no_subtree_check,no_root_squash)
```
Make sure that `/srv/homes` exist, if no than create it. After editing nfs
configuration file we have to restart NFS server:
```
sudo service nfs-kernel-server restart
```
<a id="verify-configuration"></a>
### Verify configuration ###
I assume that you go through all previous articles in this series.
To verify configuration we have to copy whole BusyBox `_install` directory to
known nfs location:
```
mkdir /srv/homes/rootfs
sudo chmod 777 /srv/homes/rootfs
cd /srv/homes/rootfs
cp -R /path/to/busybox/_install/* .
```
Now we can try our Virtual Development Board:
```
sudo qemu-system-arm -kernel src/u-boot/u-boot -net nic,vlan=0 -net \
tap,vlan=0,ifname=tap0,script=/etc/qemu-ifup -nographic -M versatilepb
```
After U-Boot booting:
```
VersatilePB # setenv autload no
VersatilePB # dhcp
MC91111: PHY auto-negotiate timed out
SMC91111: MAC 52:54:00:12:34:56
BOOTP broadcast 1
DHCP client bound to address 192.168.1.13
VersatilePB # setenv serverip 192.168.1.24
VersatilePB # setenv bootfile uImage
VersatilePB # tftp
```
Note that `192.168.1.24` should be replaced with correct address of TFTP server.
```
VersatilePB # tftp
SMC91111: PHY auto-negotiate timed out
SMC91111: MAC 52:54:00:12:34:56
Using SMC91111-0 device
TFTP from server 192.168.1.20; our IP address is 192.168.1.13
Filename 'uImage'.
Load address: 0x7fc0
Loading: #################################################################
         #################################################################
         #################################################################
         #################################################################
         #################################################################
         ##################################################
         252 KiB/s
done
Bytes transferred = 1917944 (1d43f8 hex)
```
Right now we will set boot arguments for our kernel:
```
setenv bootargs 'root=/dev/nfs mem=128M ip=dhcp netdev=25,0,0xf1010000,0xf1010010,eth0 nfsroot=192.168.1.20:/srv/homes/rootfs console=ttyAMA0'
```
What does it mean:

* `root=/dev/nfs` - following
[kernel.org](https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt):
{% blockquote %}
This is necessary to enable the pseudo-NFS-device. Note that it's not a real device but just a synonym to tell the kernel to use NFS instead of a real device.
{% endblockquote %}
* `mem=128M ip=dhcp` - self-explaining
* `netdev=25,0,0xf1010000,0xf1010010,eth0` - network device configuration
(`Format: <irq>,<io>,<mem_start>,<mem_end>,<name>`), this was provided by
default `U-Boot` bootargs
* `nfsroot=192.168.1.20:/srv/homes/rootfs` - NFS server ip and path to rootfs
* `console=ttyAMA0` - very importanat if you want to see anything in `-nographic` mode

After setting bootargs we can boot our Virtual Development Board:
```
bootm
```
As you can see that's not all, our current configuration end with:
```
(...)
Sending DHCP requests .input: AT Raw Set 2 keyboard as
/devices/fpga:06/serio0/input/input0
, OK
IP-Config: Got DHCP answer from 192.168.1.1, my address is 192.168.1.13
IP-Config: Complete:
     device=eth0, hwaddr=52:54:00:12:34:56, ipaddr=192.168.1.13, mask=255.255.255.0, gw=192.168.1.1
     host=192.168.1.13, domain=, nis-domain=(none)
     bootserver=0.0.0.0, rootserver=192.168.1.20, rootpath=
     nameserver0=192.168.1.1
input: ImExPS/2 Generic Explorer Mouse as
/devices/fpga:07/serio1/input/input1
VFS: Mounted root (nfs filesystem) on device 0:9.
Freeing unused kernel memory: 112K (c034e000 - c036a000)
nfs: server 192.168.1.20 not responding, still trying
nfs: server 192.168.1.20 OK
can't run '/etc/init.d/rcS': No such file or directory
can't open /dev/tty2: No such file or directory
can't open /dev/tty3: No such file or directory
can't open /dev/tty4: No such file or directory
can't open /dev/tty2: No such file or directory
can't open /dev/tty3: No such file or directory
can't open /dev/tty4: No such file or directory
can't open /dev/tty2: No such file or directory
can't open /dev/tty3: No such file or directory
```
try to open ttys loop. This is because of default behavior of `BusyBox` when `inittab`
was not found.

<a id="embedded-filesystem-tuning"></a>
### Embedded filesystem tuning ###
To override above behavior we have to create `/etc/inittab` file:
```
cd /srv/homes/rootfs
mkdir etc
vim etc/inittab
```
Our `inittab` is very simple:
```
::sysinit:/etc/init.d/rcS
::askfirst:/bin/ash
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
::restart:/sbin/init
```
If you want to learn more about inittab - `man inittab` .We need improve out filesystem with few directories:
```
mkdir sys proc etc/init.d
```
In `/etc/init.d/rcS` we will mount sysfs and procfs:
```bash
#! /bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
```
Give executable permission to `rcS` script:
```
chmod +x etc/init.d/rcS
```
We also have to create `dev` directory with `ttyAMA0` block device:
```
mkdir dev
sudo mknod dev/ttyAMA0 c 204 64
sudo mknod dev/null c 1 3
sudo mknod dev/console c 5 1
```

Right now we should be able to boot our Virtual Development Board. Let's try
again:
{% raw %}
```
pietrushnic@eglarest:~$ sudo qemu-system-arm -m 256M -kernel src/u-boot/u-boot -net nic,vlan=0 -net tap,vlan=0,ifname=tap0,script=/etc/qemu-ifup -nographic -M versatilepb -net dump,file=/tmp/dump.pcap
Executing /etc/qemu-ifup
Bringing up tap0 for bridged mode...
Adding tap0 to br0...
oss: Could not initialize DAC
oss: Failed to open `/dev/dsp'
oss: Reason: No such file or directory
oss: Could not initialize DAC
oss: Failed to open `/dev/dsp'
oss: Reason: No such file or directory
audio: Failed to create voice `lm4549.out'
U-Boot 2013.04-00274-ga71d45d (May 27 2013 - 17:36:14)
DRAM:  128 MiB
WARNING: Caches not enabled
Flash: 64 MiB
*** Warning - bad CRC, using default environment
In:    serial
Out:   serial
Err:   serial
Net:   SMC91111-0
Warning: SMC91111-0 using MAC address from net device
VersatilePB # setenv serverip 192.168.1.24
VersatilePB # setenv bootfile uImage
VersatilePB # setenv bootargs 'root=/dev/nfs mem=128M ip=dhcp netdev=25,0,0xf1010000,0xf1010010,eth0 nfsroot=192.168.1.24:/sv/homes/rootfs console=ttyAMA0'
VersatilePB # dhcp
SMC91111: PHY auto-negotiate timed out
SMC91111: MAC 52:54:00:12:34:56
BOOTP broadcast 1
DHCP client bound to address 192.168.1.13
Using SMC91111-0 device
TFTP from server 192.168.1.24; our IP address is 192.168.1.13
Filename 'uImage'.
Load address: 0x7fc0
Loading: *############T #####################################################
	 #################################################################
	 #################################################################
	 #################################################################
	 #################################################################
	 ##################################################
	 0 Bytes/s
done
Bytes transferred = 1917944 (1d43f8 hex)
VersatilePB # bootm
## Booting kernel from Legacy Image at 00007fc0 ...
   Image Name:   Linux-3.10.0-rc3
   Image Type:   ARM Linux Kernel Image (uncompressed)
   Data Size:    1917880 Bytes = 1.8 MiB
   Load Address: 00008000
   Entry Point:  00008000
   XIP Kernel Image ... OK
OK
Starting kernel ...
Uncompressing Linux... done, booting the kernel.
Booting Linux on physical CPU 0x0
Linux version 3.10.0-rc3 (pietrushnic@eglarest) (gcc version 4.7.2 (Debian 4.7.2-4) ) #2 Sun Jun 2 20:25:23 CEST 2013
CPU: ARM926EJ-S [41069265] revision 5 (ARMv5TEJ), cr=00093177
CPU: VIVT data cache, VIVT instruction cache
Machine: ARM-Versatile PB
Memory policy: ECC disabled, Data cache writeback
sched_clock: 32 bits at 24MHz, resolution 41ns, wraps every 178956ms
Built 1 zonelists in Zone order, mobility grouping on.  Total pages: 32512
Kernel command line: root=/dev/nfs mem=128M ip=dhcp netdev=25,0,0xf1010000,0xf1010010,eth0 nfsroot=192.168.1.24:/srv/homes/rootfs console=ttyAMA0
PID hash table entries: 512 (order: -1, 2048 bytes)
Dentry cache hash table entries: 16384 (order: 4, 65536 bytes)
Inode-cache hash table entries: 8192 (order: 3, 32768 bytes)
Memory: 128MB = 128MB total
Memory: 126136k/126136k available, 4936k reserved, 0K highmem
Virtual kernel memory layout:
    vector  : 0xffff0000 - 0xffff1000   (   4 kB)
    fixmap  : 0xfff00000 - 0xfffe0000   ( 896 kB)
    vmalloc : 0xc8800000 - 0xff000000   ( 872 MB)
    lowmem  : 0xc0000000 - 0xc8000000   ( 128 MB)
    modules : 0xbf000000 - 0xc0000000   (  16 MB)
      .text : 0xc0008000 - 0xc034dd58   (3352 kB)
      .init : 0xc034e000 - 0xc036ae8c   ( 116 kB)
      .data : 0xc036c000 - 0xc0391de0   ( 152 kB)
       .bss : 0xc0391de0 - 0xc03ad6cc   ( 111 kB)
NR_IRQS:224
VIC @f1140000: id 0x00041190, vendor 0x41
FPGA IRQ chip 0 "SIC" @ f1003000, 13 irqs
Console: colour dummy device 80x30
Calibrating delay loop... 649.21 BogoMIPS (lpj=3246080)
pid_max: default: 32768 minimum: 301
Mount-cache hash table entries: 512
CPU: Testing write buffer coherency: ok
Setting up static identity map for 0xc0286e90 - 0xc0286ee8
NET: Registered protocol family 16
DMA: preallocated 256 KiB pool for atomic coherent allocations
Serial: AMBA PL011 UART driver
dev:f1: ttyAMA0 at MMIO 0x101f1000 (irq = 44) is a PL011 rev1
console [ttyAMA0] enabled
dev:f2: ttyAMA1 at MMIO 0x101f2000 (irq = 45) is a PL011 rev1
dev:f3: ttyAMA2 at MMIO 0x101f3000 (irq = 46) is a PL011 rev1
fpga:09: ttyAMA3 at MMIO 0x10009000 (irq = 70) is a PL011 rev1
bio: create slab <bio-0> at 0
Switching to clocksource timer3
NET: Registered protocol family 2
TCP established hash table entries: 1024 (order: 1, 8192 bytes)
TCP bind hash table entries: 1024 (order: 0, 4096 bytes)
TCP: Hash tables configured (established 1024 bind 1024)
TCP: reno registered
UDP hash table entries: 256 (order: 0, 4096 bytes)
UDP-Lite hash table entries: 256 (order: 0, 4096 bytes)
NET: Registered protocol family 1
RPC: Registered named UNIX socket transport module.
RPC: Registered udp transport module.
RPC: Registered tcp transport module.
RPC: Registered tcp NFSv4.1 backchannel transport module.
NetWinder Floating Point Emulator V0.97 (double precision)
Installing knfsd (copyright (C) 1996 okir@monad.swb.de).
jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
ROMFS MTD (C) 2007 Red Hat, Inc.
msgmni has been set to 246
Block layer SCSI generic (bsg) driver version 0.4 loaded (major 254)
io scheduler noop registered
io scheduler deadline registered
io scheduler cfq registered (default)
clcd-pl11x dev:20: PL110 rev0 at 0x10120000
clcd-pl11x dev:20: Versatile hardware, VGA display
Console: switching to colour frame buffer device 80x60
brd: module loaded
physmap platform flash device: 04000000 at 34000000
physmap-flash.0: Found 1 x32 devices at 0x0 in 32-bit bank. Manufacturer ID 0x000000 Chip ID 0x000000
Intel/Sharp Extended Query Table at 0x0031
Using buffer write method
smc91x.c: v1.1, sep 22 2004 by Nicolas Pitre <nico@fluxnic.net>
eth0: SMC91C11xFD (rev 1) at c89c8000 IRQ 57 [nowait]
eth0: Ethernet addr: 52:54:00:12:34:56
mousedev: PS/2 mouse device common for all mice
TCP: cubic registered
NET: Registered protocol family 17
VFP support v0.3: implementor 41 architecture 1 part 10 variant 9 rev 0
eth0: link up
Sending DHCP requests ., OK
IP-Config: Got DHCP answer from 192.168.1.1, my address is 192.168.1.13
IP-Config: Complete:
     device=eth0, hwaddr=52:54:00:12:34:56, ipaddr=192.168.1.13, mask=255.255.255.0, gw=192.168.1.1
     host=192.168.1.13, domain=, nis-domain=(none)
     bootserver=0.0.0.0, rootserver=192.168.1.24, rootpath=
     nameserver0=192.168.1.1
input: AT Raw Set 2 keyboard as /devices/fpga:06/serio0/input/input0
input: ImExPS/2 Generic Explorer Mouse as /devices/fpga:07/serio1/input/input1
VFS: Mounted root (nfs filesystem) on device 0:9.
Freeing unused kernel memory: 112K (c034e000 - c036a000)
Please press Enter to activate this console.
/bin/ash: can't access tty; job control turned off
/ #
```
{% endraw %}

<a id="summary"></a>
### Summary ###
This setup need few minor tweaks like adding U-Boot environment variables
storage to not enter it every time or removing annoying message `can't access
tty(...)`. I'm done for now, its time to take care about other challenges. I
hope that I will back to this issues in near future. If you like this series
please share it, if somethings wrong please comment I will try to help if can.

[How to set up a NFS root filesystem for embedded Linux development](http://bec-systems.com/site/418/how-to-set-up-a-nfs-rootfs)

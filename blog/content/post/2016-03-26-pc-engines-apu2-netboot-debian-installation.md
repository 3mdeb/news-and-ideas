---
ID: 62951
title: PC Engines APU2 netboot Debian installation
author: piotr.krol
post_excerpt: ""
layout: post
published: true
date: 2016-03-26 14:27:38
archives: "2016"
tags:
  - coreboot
  - embedded
  - Debian
  - RaspberryPi
  - apu
  - AMD
  - Broadcom
categories:
  - OS Dev
---

In [previous post](https://blog.3mdeb.com/2016/2016-03-12-pxe-server-with-raspberry-pi-1/)
I described how to setup PXE server and boot Debian installer using it.
I mentioned that provided setup is limited and some extensive configuration
is needed to make it useful for real world example. Since that time I learned
that there is [chain command](http://ipxe.org/cmd/chain) in iPXE, which give
ability to use arbitrary TFTP server as boot file source.

## Using RPi PXE server

For example by changing my test network topology from
[previous post](https://blog.3mdeb.com/2016/2016-03-12-pxe-server-with-raspberry-pi-1/)
to something like that:

![img](/img/pxe_srv_apu2.png)

In short Raspberry Pi contain our PXE server configured in previous post.
TL-MR3420 is our DHCP server and PC Engines APU2A4 is our target box where we
want to install Debian.

We need to change `eth0` configuration, so our PXE server will get IP
automatically from DHCP:

```bash
auto eth0
iface eth0 inet dhcp
```

Also disable `udhcpd`:

```bash
sudo update-rc.d udhcpd disable
```

Then reboot PXE server.

## PXE booting

First enter iPXE on APU2 board by pressing `<Ctrl-B>` during boot. You should
see something like that:

```bash
iPXE (http://ipxe.org) 00:00.0 C100 PCI2.10 PnP PMMpmm call arg1=1
pmm call arg1=0
+DFF490B0pmm call arg1=1
pmm call arg1=0
+DFE890B0 C100


iPXE (PCI 00:00.0) starting execution...ok
iPXE initialising devices...ok



iPXE 1.0.0+ (e303) -- Open Source Network Boot Firmware -- http://ipxe.org
Features: DNS FTP HTTP HTTPS iSCSI NFS SLAM TFTP VLAN AoE ELF MBOOT NBI PXE SDI bzImage COMBOOT Menu PXEXT
iPXE>
```

Then obtain DHCP address:

```bash
iPXE> dhcp net0
Configuring (net0 00:0d:b9:3f:9e:58)............... ok
```

Now we can boot over the network using RPi PXE server:

```bash
iPXE> set filename /srv/tftp/pxelinux.0
iPXE> set next-server 192.168.0.100
iPXE> chain tftp://${next-server}/${filename}
```

Note that `192.168.0.100` is RPi PXE server and `/srv/tftp/pxelinux.0` is path
on RPi exposed through TFTP configuration.

## Debian installer modification

Hit `Tab` in the main installer window:

```bash
                 +---------------------------------------+
                 | Debian GNU/Linux installer boot menu |
                 |---------------------------------------|
                 | Install                               |
                 | Advanced options                    > |
                 | Help                                  |
                 | Install with speech synthesis         |
                 |                                       |
                 |                                       |
                 |                                       |
                 |                                       |
                 |                                       |
                 |                                       |
                 +---------------------------------------+



              Press ENTER to boot or TAB to edit a menu entry
```

Change boot command line to print output to serial:

```bash
> debian-installer/i386/linux vga=788 initrd=debian-installer/i386/initrd.gz --- console=ttyS0,115200 earlyprint=serial,ttyS0,115200
```

Then hit `Enter`. You will see complains about video mode like this:

```bash
Press <ENTER> to see video modes available, <SPACE> to continue, or wait 30 sec
```

Follow this instruction by waiting or hitting `Space`. Then you should have
running installer.

## Debian installation

This is typical installation except it happen over serial. As a storage I used
16GB USB stick with guided partitioning. At the end I also installed GRUB on USB
stick MBR.

Be patient if serial console will be blank for some time it happen when
installing over network.

After reboot you should be able to choose USB stick from boot menu (F10) and
your Debian on APU2 should be ready:

```bash
Debian GNU/Linux 8 Maedhros ttyS0

Maedhros login: pietrushnic
Password:
Linux Maedhros 3.16.0-4-686-pae #1 SMP Debian 3.16.7-ckt20-1+deb8u4 (2016-02-29) i686

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
pietrushnic@Maedhros:~$
```

## Summary

Now when you have Debian installed on your system you can think about various
improvements. For example:

- Xen installation
- Putting together automated installation using PXE server
- Setup NFS and TFTP for Linux kernel development and testing

I hope this post was useful. If you think that it can be improved please
comment. Thanks for reading.

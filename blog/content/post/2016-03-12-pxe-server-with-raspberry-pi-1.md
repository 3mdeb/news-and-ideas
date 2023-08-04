---
ID: 62946
title: PXE server with Raspberry Pi 1
author: piotr.krol
post_excerpt: ""
layout: post
published: true
date: 2016-03-12 17:42:42
archives: "2016"
tags:
  - RaspberryPi
  - ipxe
  - Broadcom
categories:
  - App Dev
---

Recent days we get the announcement about releasing Raspberry Pi 3. Those of you
who play with embedded systems or just try to make things probably still got
good old Raspberry Pi (1). Because during time old platforms loose value as
potential candidate for new projects I decided to sacrifice my old RPi and make
test server from it.

One of my customer required testing his software against PXE server with various
configurations. I realized that using my home network with my TP-Link router I
have no way to create such configuration on server machine I usually use. I
would need to connect directly to server and with one Ethernet port this was not
the solution for me. My other platforms like A20 boards, Odroid or RPi2 are
occupied by some projects. I recall that I have old RPi that can be used for
that purpose.

Configuration described below is very limited because it test just PXE booting,
there is no outside world connection. This connection can be added by adding
wifi dongle to Raspberry Pi and modifying iptables and routing.

## Prerequisites

- download recent Raspberry Pi
  [image](https://www.raspberrypi.org/downloads/raspbian/) and flash it to SD
  card. I used Raspbian Jessie Lite.
- if you don't have free keyboard and HDMI monitor use UART to connect serial
  console - you can use [this post](http://elinux.org/RPi_Serial_Connection), if
  you don't know how to connect it
- flash recent iPXE to your hardware or use what is already provided by vendor

## Raspbian Jessie Lite - initial setup

### Setup TFTP

Install server TFTP:

```bash
sudo apt-get install tftpd-hpa
```

Change configuration according to your needs. My looks like that:

```bash
# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS="0.0.0.0:69"
#TFTP_OPTIONS="--secure"
TFTP_OPTIONS=""
```

Download netboot files for Debian, which we will use for testing purposes:

```bash
wget http://ftp.nl.debian.org/debian/dists/jessie/main/installer-i386/current/images/netboot/netboot.tar.gz
```

Unpack netboot package in `/srv/tftp`:

```bash
cd /srv/tftp
sudo tar xvf /path/to/netboot.tar.gz
```

## Setup udhcpd

Install udhcpd and remove conflicting packages:

```bash
sudo apt-get install udhcpd
sudo apt-get remove isc-dhcp-client
```

At the end of `/etc/udhcpd.conf` add:

```bash
siaddr          192.168.0.1
boot_file       /srv/tftp/pxelinux.0
opt     dns     192.168.0.1 192.168.10.10
option  subnet  255.255.255.0
opt     router  192.168.0.1
opt     wins    192.168.0.1
option  dns     129.219.13.81
option  domain  local
option  lease   864000
```

You can also assign client MAC to given IP address by adding:

```bash
#static_lease 00:60:08:11:CE:4E 192.168.0.54
static_lease <mac> <ip>
```

Comment `DHCPD_ENABLE` in `/etc/default/udhcpd`:

```bash
# Comment the following line to enable
# DHCPD_ENABLED="no"

# Options to pass to busybox' udhcpd.
#
# -S    Log to syslog
# -f    run in foreground

DHCPD_OPTS="-S"
```

Change `eth0` configuration to static IP:

```bash
auto eth0
iface eth0 inet static
        address 192.168.0.1
        netmask 255.255.255.0
        gateway 192.168.0.254
```

Then reboot device and connect your PXE client device.

## Testing PXE server

When device boot press `Ctrl-B` to enter iPXE shell. If you cannot enter shell
please replace iPXE with recent version using
[this instructions](https://www.coreboot.org/IPXE).

Entering iPXE you should see something like that:

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

First let's configure interface:

```bash
iPXE> ifconf net0
Configuring (net0 00:0d:b9:3f:9e:58)............... ok
iPXE> dhcp net0
Configuring (net0 00:0d:b9:3f:9e:58)............... ok
```

And boot Debian installer:

```bash
iPXE> autoboot
net0: 00:0d:b9:3f:9e:58 using i210-2 on PCI01:00.0 (open)
  [Link:up, TX:20 TXE:0 RX:8 RXE:2]
  [RXE: 2 x "The socket is not connected (http://ipxe.org/380f6001)"]
Configuring (net0 00:0d:b9:3f:9e:58)............... ok
net0: 192.168.0.194/255.255.255.0 gw 192.168.10.2
net0: fe80::20d:b9ff:fe3f:9e58/64
net1: fe80::20d:b9ff:fe3f:9e59/64 (inaccessible)
net2: fe80::20d:b9ff:fe3f:9e5a/64 (inaccessible)
Next server: 192.168.0.1
Filename: /srv/tftp/pxelinux.0
tftp://192.168.0.1//srv/tftp/pxelinux.0... ok
pxelinux.0 : 42988 bytes [PXE-NBP]
PXELINUX 6.03 PXE 20150819 Copyright (C) 1994-2014 H. Peter Anvin et al+---------------------------------------+
| ^GDebian GNU/Linux installer boot menu |
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
+---------------------------------------+Press ENTER to boot or TAB to edit a menu entry
```

## Summary

It took me some time to put this information together an correctly run this
server, so for future reference and for those confused with udhcpd and other
tools configuration this post should be useful. Thanks for reading and as always
please share if you think this post is valuable. If anything is not clear or I
messed something please let me know in comments.

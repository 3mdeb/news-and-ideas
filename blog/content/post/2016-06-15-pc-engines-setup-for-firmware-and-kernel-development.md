---
layout: post
title: "Network boot setup for firmware and kernel development on PC Engines APU2"
date: 2016-06-15 13:56:38 +0200
comments: true
categories: debian embedded coreboot apu2 linux
---

To verify various features during firmware development process there is need to
have some more sophisticated software or use already available commands and
libraries. Using USB/SD card storage for some systems, like small development
boards like {Raspberry,Banana,Orange}Pi work good, but using network boot
despite being harder to setup is more flexible and can provide much better
experience for developer.

I decided to setup this configuration because had couple features to
debug/test:

* ECC
* Xen
* OpenBSD installation

I hope to reveal more details about those in further posts. Of course whole
setup was target for x86 architecture, so no cross compilation and problems
related with that had to be solved.

## PXE server and company

As I described in other posts ([1](2016/03/12/pxe-server-with-raspberry-pi-1/)
and [2](http://blog.3mdeb.com/2016/03/26/pc-engines-apu2-debian-installation/))
we will need PXE server. I assume it is already done using RPi or any other
Linux box in your network.

## Debian rootfs

```
sudo apt-get install debootstrap
export MY_CHROOT=${PWD}/rootfs/sid-rootfs-20160615
mkdir -p $MY_CHROOT
sudo debootstrap --arch i386 sid $MY_CHROOT http://httpredir.debian.org/debian/
sudo cp /etc/resolv.conf $MY_CHROOT/etc
sudo chroot $MY_CHROOT /bin/bash -i
distro=sid
export LANG=C
cat <<EOT > /etc/apt/sources.list
deb http://httpredir.debian.org/debian $distro main contrib non-free
deb-src http://httpredir.debian.org/debian $distro main contrib non-free
EOT
apt-get update
apt-get install locales dialog
dpkg-reconfigure locales
```

Typically I choose *en_US.UTF-8* but you may use your native language.

```
apt-get install openssh-server ntpdate git vim
passwd # i.e. apu2
cat <<EOT >> /etc/network/interfaces
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
EOT
echo apu2 > /etc/hostname
echo T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100 >> /etc/inittab
exit
sudo rm $MY_CHROOT/etc/resolv.conf
```

This kind of roofs is pretty big because it use 605MB.

## Kernel

```
git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
make i386_defconfig
make -j$(nproc) bzImage modules
```

## NFS

To have modifiable root filesystem it is good to setup NFS:

```
sudo apt-get install nfs-kernel-server
```

`/etc/exports` configuration:

```
/home/pietrushnic/storage/rootfs/sid-rootfs-20160615  *(rw,sync,no_subtree_check)
```

## Dockerized development environment

Thanks to containers we are able to pack everything in script and build image
with server that we want. What are the requirements for this kind of setup ?

* container should expose TFTP server
* pxelinux configuration should expose various operating systems (Debian sid,
  stretch, jessie, Xen, pfSense etc.)
* there should be booting as well as installation option
* there should be support for Linux kernel development at least in Debian

### Preapre Voyage Linux for PXE boot





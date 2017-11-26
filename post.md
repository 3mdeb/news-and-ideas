---
post_title: How to boot Xen over PXE and NFS on PC Engines apu2
author: Piotr Król
post_excerpt: ""
layout: post
published: true
post_date: 2017-11-20 00:21:00
tags:
  - coreboot
  - xen
  - apu2
categories:
  - Firmware
  - OS Dev
---

From time to time we face requests to correctly enable support for various Xen
features on PC Engines apu2 platform. Doing that requires firmware
modification, which 3mdeb is responsible for.

Xen have very interesting requirements from firmware development perspective.
Modern x86 have bunch of features that support virtualization in hardware.
Those features were described in [Xen FAQ](https://wiki.xenproject.org/wiki/Xen_Common_Problems#What_are_the_names_of_different_hardware_features_related_to_virtualization_and_Xen.3F).

It happen that most requesting were IOMMU and SR-IOV. First give ability to
dedicate PCI device to given VM and second enables so called Virtual Functions,
what means on physical device (e.g. Ethernet NIC) can be represented by many
PCI devices. Connecting IOMMU with SR-IOV give ability for hardware assisted
sharing of one device between many VMs.

All those features are very nice and there is work spread on various forums,
which didn't get its way to mainline yet. Starting with this blog post we want
to change that.

To start any work in that area we need reliable setup. I had plan to build
something pretty simple using our automated testing infrastructure.
Unfortunately this have to wait little bit since when I started this work I had
to play with [different configuration)[TBD: blog post about QubesOS, PXE and DHCP].

If you don't have PXE, DHCP (if needed) and NFS set up I recommend to read
above blog post or just use [pxe-server](https://github.com/3mdeb/pxe-server)
and [dhcp-server](https://github.com/3mdeb/dhcp-server).

## Xen installation in Debian stable

I assume you have PXE+NFS boot of our Debian stable. To netboot simply enter
iPXE:

```
PXE> dhcp net0
Configuring (net0 00:0d:b9:43:3f:bc).................. ok
iPXE> chain http://192.168.42.1:8000/menu.ipxe
```

And choose `Debian stable netboot`:

```
---------------- iPXE boot menu ----------------
ipxe shell                                                                  
Debian stable netboot                                                       
Xen
TODO:Debian stable netinst
TODO:Debian testing netinst
TODO:Debian testing netinst (UEFI-aware)
TODO:Voyage
```

After boot you can login with presented credentials `[root:debian]`:

```
Debian GNU/Linux 9 apu2 ttyS0 [root:debian]

apu2 login: root
Password:
Last login: Sat Nov 25 23:09:55 UTC 2017 from 192.168.42.1 on pts/0
Linux apu2 4.8.5 #2 SMP Fri Aug 11 13:48:51 CEST 2017 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
root@apu2:~#
```

Xen installation in Debian is quite easy and there is [community website](https://wiki.debian.org/Xen)
describing process, but to quickly dive in:

```
apt-get update
apt-get install xen-system-amd64 xen-tools xen-linux-system-amd64
```

## Xen over PXE and NFS

Xen installation provide necessary components for setting up boot over PXE and
NFS. First just need correct configuration, in our case in `menu.ipxe`, but
second requires specially crafted kernel. Kernel provided by default in
`xen-linux-system-amd64` lacks NFSv3 built in module, what is necessary to
mount NFS during boot.

### Linux kernel compilation

Kernel provided with my upgrade was oldstable `4.9.51`. You can check that in
apu2 or NFS `/boot` directory. We have to recompile that kernel and enable
NFSv3.

```
cd linux-stable-4.9.51
cp /path/to/pxe-server/debian/debian-stable/boot/config-4.9.0-4-amd64 .config
```

Then edit config and mark `NFSv3` options as `y`:

```
CONFIG_NFS_FS=m
CONFIG_NFS_V2=m
CONFIG_NFS_V3=y
CONFIG_NFS_V3_ACL=y
CONFIG_NFS_V4=m
CONFIG_NFS_SWAP=y
CONFIG_NFS_V4_1=y
CONFIG_NFS_V4_2=y
```

For conveninence we compiled `deb-pkg` version:

```
make -j$(nproc) deb-pkg
```

Let's copy and install results of our compilation:

```

```

### Booting Xen

Components needed for that cofiguration are:

* `xen-4.8-amd64`, which can be get from
  `pxe-server/debian/debian-stable/boot/xen-4.8-amd64.gz` and unpacked using
`zcat xen-4.8-amd64.gz > xen-4.8-amd64`

* ``, which can be get from `pxe-server/debian/debian-stable/boot/vmlinuz-`

We have to adjust `pxe-server/netboot/menu.ipxe` which we use to boot whole syste. We
played little bit with the options before we get to this configuration.

First modify menu:

```
diff --git a/menu.ipxe b/menu.ipxe
index e11e44ac13d3..a610bb2f20b7 100644
--- a/menu.ipxe
+++ b/menu.ipxe
@@ -5,6 +5,7 @@ menu
 item --gap -- ---------------- iPXE boot menu ----------------
 item shell          ipxe shell
 item deb-netboot    Debian stable netboot
+item xen    Xen
 item deb-stable-netinst    TODO:Debian stable netinst
 item deb-testing-netinst    TODO:Debian testing netinst
 item deb-testing-netinst-uefi    TODO:Debian testing netinst (UEFI-aware)
```

Then add blow `deb-netboot`:

```
:xen
kernel xen-4.8-amd64 dom0_mem=512M loglvl=all guest_loglvl=all com1=115200,8n1 console=com1
module console=hvc0 earlyprintk=xen nomodeset root=/dev/nfs rw ip=dhcp nfsroot=<NFS_SRV_IP>:/srv/nfs/debian/debian-stable,vers=3,udp nfsrootdebug
boot
goto MENU
```

Do not forget to replace `<NFS_SRV_IP>`.

This should give us bootable dom0 na neat Xen logs very useful for debugging:

```
```

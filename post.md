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
apt-get install xen-system-amd64
```

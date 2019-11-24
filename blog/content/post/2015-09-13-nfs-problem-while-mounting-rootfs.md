---
layout: post
title: "NFS problem while mounting rootfs on A20"
date: 2015-09-13 00:14:33 +0200
comments: true
categories: linux,cubietruck
---

Today I went above and beyond the call of duty to mount rootfs for my Cubietruck
over NFS. The problem signature was:

```
nfs: server 192.168.0.105 not responding, still trying
```

You may think that this message is self-explanatory but in my case it was not.
I tried to mount this file system from different machine and it worked.
Apparently there was something wrong with Cubietruck kernel. I'm using mainline
kernel [sunxi-next](git clone git://github.com/mripard/linux.git -b sunxi-next)
branch.

I decide to describe my fight as a note for me and others. And put together
some debugging notes.

If you don't know how to set NFS you can try follow my [Quick NFS setup](/linux-development-on-cubietruck-a20-environment-setup/#nfs).

##Quick initial triage

* Make sure your kernel get IP address if you obtain it over DHCP. You
  should get in boot log something similar to this:

```
device=eth0, hwaddr=02:82:0b:42:77:3e, ipaddr=192.168.0.106, mask=255.255.255.0, gw=192.168.0.1
host=192.168.0.106, domain=, nis-domain=(none)
bootserver=0.0.0.0, rootserver=192.168.0.105, rootpath=
nameserver0=192.168.0.1
```

* If you have no such logs it can mean incorrect network configuration in
  kernel parameters or that Ethernet driver was not loaded at point early
  enough to make network interface available. For sunxi devices it can mean
  that Ethernet card driver should be built-in into kernel instead of provided
  as module. Below snippet in kernel source directory can fix problem on sunxi
  board:

```
sed -i 's:CONFIG_SUNXI_GMAC=m:CONFIG_SUNXI_GMAC=y:g' .config
```

##NFS debugging tricks

###Server side debugging

First if you use systemd and you didn't used it (for me debugging is much more
complicated then in pre-systemd era). Couple of tricks were provided in as always useful [Arch Wiki](https://wiki.archlinux.org/index.php/NFS/Troubleshooting#Debugging). Probably most useful hints are:

```
sudo rpcdebug -m nfsd -s all #set all debug flags
```

To see logs real-time:

```
sudo journalctl -fl
```

Make sure you use recent kernel before reporting any problems to mailing lists
or forum.

In my case logs from systemd was completely useless. Mainly because its readability, when I hit my problem nfsd reported:

```
NFSD: laundromat service - starting
NFSD: laundromat_main - sleeping for 60 seconds
```

Googling those strings provide mailing list threads that lead to nothing.

###Client side debugging

For me most useful was `ntfrootdebug` kernel option which enables log messages
to be visible at boot time.

To enable this option you need `CONFIG_NFS_DEBUG=y` in kernel config but this
one depends on `NETWORK_FILESYSTEMS [=y] && NFS_FS [=y] && SUNRPC_DEBUG [=y]`.
Make sure to mark last one which is in `File systems > Network File Systems > Root file system on NFS`.

This log for me reveal something like this:

```

```

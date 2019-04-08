---
ID: 62891
title: 'virtualbox-dkms: fix alloc_netdev problems when compiling with 3.17.0-rcX headers'
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/app-dev/virtualbox-dkms-fix-alloc_netdev-problems-when-compiling-with-3-17-0-rcx-headers/
published: true
date: 2014-09-20 22:55:00
tags:
  - linux
  - Debian
  - VirtualBox
categories:
  - App Dev
---
Intro
-----

Because of my bug hunting approach of using latest kernel I experienced problem
with compiling VirtualBox modules with `3.17.0-rc5` version on my Debian Jessie. Issue is well
known and described for examples [here](https://bugs.launchpad.net/ubuntu/+source/virtualbox/+bug/1358157).
Problem manifest itself with:

```
------------------------------
Deleting module version: 4.3.14
completely from the DKMS tree.
------------------------------
Done.
Loading new virtualbox-4.3.14 DKMS files...
Building only for 3.17.0-rc5+
Building initial module for 3.17.0-rc5+
Error! Bad return status for module build on kernel: 3.17.0-rc5+ (x86_64)
Consult /var/lib/dkms/virtualbox/4.3.14/build/make.log for more information.
Job for virtualbox.service failed. See 'systemctl status virtualbox.service' and 'journalctl -xn' for details.
invoke-rc.d: initscript virtualbox, action "restart" failed.
```

during `virtualbox-dkms` package installation or reconfiguration. In `make.log` you will find compilation error:

```
  CC [M]  /var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp/linux/VBoxNetAdp-linux.o
/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp/linux/VBoxNetAdp-linux.c: In function ‘vboxNetAdpOsCreate’:
/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp/linux/VBoxNetAdp-linux.c:186:48: error: macro "alloc_netdev" requires 4 arguments, but only 3 given
                            vboxNetAdpNetDevInit);
                                                ^
/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp/linux/VBoxNetAdp-linux.c:184:15: error: ‘alloc_netdev’ undeclared (first use in this function)
     pNetDev = alloc_netdev(sizeof(VBOXNETADPPRIV),
               ^
/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp/linux/VBoxNetAdp-linux.c:184:15: note: each undeclared identifier is reported only once for each function it appears in
/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp/linux/VBoxNetAdp-linux.c: At top level:
/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp/linux/VBoxNetAdp-linux.c:159:13: warning: ‘vboxNetAdpNetDevInit’ defined but not used [-Wunused-function]
 static void vboxNetAdpNetDevInit(struct net_device *pNetDev)
             ^
scripts/Makefile.build:257: recipe for target '/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp/linux/VBoxNetAdp-linux.o' failed
make[2]: *** [/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp/linux/VBoxNetAdp-linux.o] Error 1
scripts/Makefile.build:404: recipe for target '/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp' failed
make[1]: *** [/var/lib/dkms/virtualbox/4.3.14/build/vboxnetadp] Error 2
Makefile:1373: recipe for target '_module_/var/lib/dkms/virtualbox/4.3.14/build' failed
make: *** [_module_/var/lib/dkms/virtualbox/4.3.14/build] Error 2
make: Leaving directory '/usr/src/linux-headers-3.17.0-rc5+'
```

For sure we have to wait for some time before new version of kernel and
VirtualBox will catch up each other in Debian.

Fix source code of Debian package
----------------------------

Let's get get virtualbox package source, fix issues rebuild package and install
in the system. Patch to apply can be found [here](https://forums.virtualbox.org/viewtopic.php?p=296650#p296650).

```
apt-get source virtualbox-dkms
cd virtualbox-4.3.14-dfsg
```

Now we can patch the sources with:

```diff
diff --git a/src/VBox/HostDrivers/VBoxNetAdp/linux/VBoxNetAdp-linux.c b/src/VBox/HostDrivers/VBoxNetAdp/linux/VBoxNetAdp-linux.c
index c6b21a9cc199..9ccce6f32218 100644
--- a/src/VBox/HostDrivers/VBoxNetAdp/linux/VBoxNetAdp-linux.c
+++ b/src/VBox/HostDrivers/VBoxNetAdp/linux/VBoxNetAdp-linux.c
@@ -52,6 +52,25 @@

 #define VBOXNETADP_FROM_IFACE(iface) ((PVBOXNETADP) ifnet_softc(iface))

+/*******************************
+source for the 4th parameter alloc_netdev fix for kernel 3.17-rc1 is:
+https://github.com/proski/madwifi/commit/c5246021b7b8580c2aeb0a145903acc07d246ac1
+*/
+#ifndef NET_NAME_UNKNOWN
+#undef alloc_netdev
+#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,23)
+#define alloc_netdev(sizeof_priv, name, name_assign_type, setup) \
+  alloc_netdev(sizeof_priv, name, setup)
+#elif LINUX_VERSION_CODE < KERNEL_VERSION(2,6,38)
+#define alloc_netdev(sizeof_priv, name, name_assign_type, setup) \
+  alloc_netdev_mq(sizeof_priv, name, setup, 1)
+#else
+#define alloc_netdev(sizeof_priv, name, name_assign_type, setup) \
+  alloc_netdev_mqs(sizeof_priv, name, setup, 1, 1)
+#endif
+#endif
+/*******************************/
+
 /*******************************************************************************
 *   Internal Functions                                                         *
 *******************************************************************************/
@@ -183,6 +202,7 @@ int vboxNetAdpOsCreate(PVBOXNETADP pThis, PCRTMAC pMACAddress)
     /* No need for private data. */
     pNetDev = alloc_netdev(sizeof(VBOXNETADPPRIV),
                            pThis->szName[0] ? pThis->szName : VBOXNETADP_LINUX_NAME,
+                           NET_NAME_UNKNOWN,
                            vboxNetAdpNetDevInit);
     if (pNetDev)
     {
diff --git a/src/VBox/Runtime/r0drv/linux/alloc-r0drv-linux.c b/src/VBox/Runtime/r0drv/linux/alloc-r0drv-linux.c
index 21e124bda039..2a046a3b254a 100644
--- a/src/VBox/Runtime/r0drv/linux/alloc-r0drv-linux.c
+++ b/src/VBox/Runtime/r0drv/linux/alloc-r0drv-linux.c
@@ -191,7 +191,7 @@ static PRTMEMHDR rtR0MemAllocExecVmArea(size_t cb)
         struct page **papPagesIterator = papPages;
         pVmArea->nr_pages = cPages;
         pVmArea->pages    = papPages;
-        if (!map_vm_area(pVmArea, PAGE_KERNEL_EXEC, &papPagesIterator))
+        if (!map_vm_area(pVmArea, PAGE_KERNEL_EXEC, papPagesIterator))
         {
             PRTMEMLNXHDREX pHdrEx = (PRTMEMLNXHDREX)pVmArea->addr;
             pHdrEx->pVmArea     = pVmArea;
```

Assuming you save above code in `my_patch` file and you are in `virtualbox`
dpkg source directory:

```sh
patch -p1 < my_patch
```

Install packages required to build:

```
sudo apt-get build-dep virtualbox
```

And build with:

```sh
dpkg-buildpackage -uc -b
```

In result we should get all `virtualbox` packages. We need only `dkms`:

```
sudo dpkg -i ../virtualbox-dkms_4.3.14-dfsg-1_all.deb

(Reading database ... 432638 files and directories currently installed.)
Preparing to unpack .../virtualbox-dkms_4.3.14-dfsg-1_all.deb ...

------------------------------
Deleting module version: 4.3.14
completely from the DKMS tree.
------------------------------
Done.
Unpacking virtualbox-dkms (4.3.14-dfsg-1) over (4.3.14-dfsg-1) ...
Setting up virtualbox-dkms (4.3.14-dfsg-1) ...
Loading new virtualbox-4.3.14 DKMS files...
Building only for 3.17.0-rc5+
Building initial module for 3.17.0-rc5+
Done.

vboxdrv:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/3.17.0-rc5+/updates/dkms/

vboxnetadp.ko:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/3.17.0-rc5+/updates/dkms/

vboxnetflt.ko:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/3.17.0-rc5+/updates/dkms/

vboxpci.ko:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/3.17.0-rc5+/updates/dkms/

sed: -e expression #1, char 6: unknown command: `m'
depmod....

DKMS: install completed.`
```

And we can happily use VirtualBox with `3.17.0-rc5` kernel.

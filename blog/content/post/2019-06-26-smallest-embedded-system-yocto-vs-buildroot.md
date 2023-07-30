---
title: The smallest Embedded Linux System - Yocto vs Buildroot
abstract: Fully working Linux based system below 5 MB. Is it even possible? It
          turns out that yes. What's more, you can get even lower values!
          Comparison of results obtained with Yocto and Buildroot.
cover: /covers/yocto-vs-buildroot.png
author: lukasz.laguna
layout: post
published: true
date: 2019-06-26
archives: "2019"

tags:
  - Yocto
  - Buildroot
  - Linux
categories:
  - OS Dev

---

## Introduction

Recently we had the need to build a really little system image (kernel + rootfs)
for x86 architecture, which will be able to **boot from RAM memory**. We decided
that it would be a good idea to build it with
[**Yocto**](https://www.yoctoproject.org/) and
[**Buildroot**](https://buildroot.org/) and compare the results.

![yocto-vs-buildroot](/covers/yocto-vs-buildroot.png)

In order for the results to be as reliable as possible, the presented
information refer to the **minimal images** build with **default
configurations** without any additional packages and changes in the system. In
both cases, the image was built for **QEMU x86**.

## Minimal image with Yocto

To build the image we have used the latest stable version of **Yocto - 2.7
(Warrior)**.

![yocto-logo](/img/YoctoProject_Logo_RGB.jpg)

The **core-image-minimal** image based on a standard **Poky distribution** was
rejected at the very beginning of consideration. First of all, it doesn't build
the initramfs. Secondly, the size of rootfs and kernel significantly exceeded
the acceptable value. The next most reasonable step was to try the build of
core-image-minimal with **Poky-Tiny**. The results were very satisfying:

```bash
2,8M bzImage.bin
864K rootfs.cpio.gz
3,6M total
```

**The most important information about the built system (default settings):**

- **C standard library** is the musl libc,
- **Linux** version is 5.0.7,
- **BusyBox** version is 1.30.1.

The **elements of the rootfs that use the most of the space** are shown below
(size of files / directories after decompression):

```bash
904K /usr/lib/opkg/alternatives
704K /bin/busybox.nosuid
660K /usr/lib/libc.so
168K /etc
56K  /bin/busybox.suid
```

As expected, a very large part of the file system is **BusyBox** and **LibC**,
but `/usr/lib/opkg/alternatives` was a surprise. This directory contains files
that store information about alternative versions of installed applications.
It's not needed in our case, so we can remove it. If necessary, in the next step
we could reduce the utilities of the BusyBox to get even smaller filesystem.

## Minimal image with Buildroot

To build the image we have used the latest long term support version of
**Buidroot - 2019.02.3**.

![buildroot-logo](/img/buildroot_logo.jpg)

As a base we used the **qemu_x86_defconfig** and added only the necessary
changes. Firstly, we enabled the build of **cpio root filesystem** and **gzip
compression** of output file (as a default ext2 rootfs is built). Secondly, we
set properly TTY port for getty. In this case, the results also met our
expectations:

```bash
720K rootfs.cpio.gz
4,1M bzImage
4,8M total
```

The total size of **Linux + initramfs** is a bit bigger than in case of Yocto,
but **it's still lower than 5 MB**. It is worth to note that rootfs is smaller
than in Yocto, but kernel is relatively large. We didn't check its
configuration, but it would certainly be possible to reduce its size. We also
tried to use together the initramfs built with Buildroot and the kernel built
with Yocto and it worked without a problem.

**The most important information about the built system (default settings):**

- **C standard library** is the uClibc-ng,
- **Linux** version is 4.19.16,
- **BusyBox** version is 1.29.3.

The **elements of the rootfs that use the most of the space** are shown below
(size of files / directories after decompression):

```bash
592K ./bin/busybox
488K ./lib/libuClibc-1.0.31.so
240K ./lib/modules/4.19.16
128K ./etc
```

In this case, the **BusyBox** and **LibC** are **smaller**. A lot of space is
used by kernel modules. Probably most of them are not necessary for us and can
be removed.

Out of curiosity, we decided to change the C standard library to musl libc.
**Size of rootfs increased to 809 KB.**

## Results submit

We'll need to add several packages to our target image and possibly in that form
it will exceed the acceptable size value, but as we described **there are a few
things which can be removed**. If that will not be enough, **we can minimize the
busybox utilities** or try to **match the compiler flags** in order to reduce
the size.

## Yocto or Buildroot - which one to choose?

Of course, **there is no clear answer**. Both tools have their advantages and
disadvantages. **Buildroot** is small, simple and gives quick results. **Yocto**
needs more time to build the image, requires more disk space (in this case about
25 GB, while buildroot used about 5 GB). On the other hand it's a complex build
system, which gives more possibilities and Yocto Layers are definitely better to
maintain. Depending on the specific needs, a specific tool should be chosen.
**The most important** information from our experiment is that in this case, the
resulting system from **Yocto and Buildroot meet the set requirements** and **we
are able to achieve the intended effect with both of them**.

## Summary

If you need a support in **Yocto/Buildroot** or looking for someone who can
boost your product by leveraging advanced features feel free to
[**book a call with us**](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [**sign up to our newsletter**](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).

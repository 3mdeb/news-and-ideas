---
title: Infrastructure for Xen development and debugging
cover: /cover/image-file.png
author: piotr.krol
layout: post
published: false
date: YYYY-MM-DD

tags:
  - xen
  - coreboot
categories:
  - Firmware
  - OS Dev
  - Security

---

# Intro

Last [OSFC](https://2018.osfc.io)  we were presented AMD IOMMU enabling for PC
Engines apuX (GX-412TC) platforms. You can watch presentation video
[here](https://www.youtube.com/watch?v=5JoEuh9qXx0&list=PLJ4u8GLmFVmoRCX_gFXV6fhWmsOQ5cmuj&index=14)
Our hypervisor of choice was Xen and we used it to verify PCI pass-through
feature. Unfortunately, booting process was not exactly stable
and platform from time to time hanged on the same log:

```
(XEN) HVM: SVM enabled
(XEN) HVM: Hardware Assisted Paging (HAP) detected
(XEN) HVM: HAP page sizes: 4kB, 2MB, 1GB
(XEN) HVM: PVH mode not supported on this platform
(XEN) spurious 8259A interrupt: IRQ7.
(XEN) CPU1: No irq handler for vector e7 (IRQ -2147483648)
(XEN) CPU2: No irq handler for vector e7 (IRQ -2147483648)
(
```

Always the same place in code, it seems to start printing `(XEN) Brought up 4
CPUs`, so suspicious code is probably right after [this log](https://xenbits.xen.org/gitweb/?p=xen.git;a=blob;f=xen/arch/x86/setup.c;h=468e51efef7a848f24acab43d69d74ab126b4b0e;hb=4507bb6ae2b778a484394338452546c1e4fc6ae5#l1544).

We started to write that post quite long ago, but because recent Xen 4.12
release we decide to get back to problem and see what is the current state.

# Debugging environment considerations

Because of that I decided to debug Xen, but first I had to get through
compilation and deployment procedure. In general I saw couple options for
compilation:

* Debian package modification - get sources through `apt source xen` and
  continue with Debian-way of building packages - this can be done either on
  host, in rootfs or in Docker container
* directly from Xen source tree using `make debball` - this can be done either
  on host either in container

Internet is not straight forward about best method, [Xen documentation](https://wiki.xenproject.org/wiki/Compiling_Xen_From_Source)
since I couldn't build Xen with `make debball`. More to that both methods can
be applied through frameworks. Debian rootfs can be build using
[isar](https://github.com/ilbers/isar) and there is always way to narrow
everything to OpenEmbedded/Yocto meta layer which should build only what we
need. Last option is good for production, but development may be hard in
limited environment that Yocto produce by default.

## Xen dockerized buidling environment

I chose the second option and for that purpose I have prepared a Docker
container with all required packages. See [3mdeb/xen-docker](https://github.com/3mdeb/xen-docker)

Despite that I still encountered some issues with building:

```
/usr/include/features.h:364:25: fatal error: sys/cdefs.h: No such file or directory
```

It turned out that 32bit verison of `libc6-dev` was required. After updating
Dockerfile and container with `libc6-dev-i386` everything went ok. Here's what
I did:

```
(docker-container)$ cd $XEN_SRC_DIR
(docker-container)$ git checkout <version>
(docker-container)$ ./configure --enable-githttp --enable-systemd
# there is time now to customize .config
(docker-container)$ make debball
```

> Note: `--enable-systemd` requires a `libsystemd-dev` package to be installed
> in container.

Build result will be placed in `$XEN_SRC_DIR/dist` as
`xen-upstream-<version>.deb`. For Debian based systems it is easy to install it
with `dpkg`. Package contains all necessary components for host OS along with
Xen kernel.

> Note that the host OS still will require Dom0 Kernel for Xen

To update the pxe-server with new Xen image, install the
`xen-upstream-<version>.deb` in rootfs which hosts the VMs and copy the Xen
kernel from `/boot/xen-<version>.gz` to tftpboot/httpboot directory (gunzip the
kernel first).

After whole this effort I was able to boot my freshly built Xen on apu2c4 with
Debian host and Debian guest OS. However at first glance I noticed that
`xl pci-assignable` command family hangs when executed. Now that I have prepared
developing procedure I can start narrowing down all the issues.

# Infrastructure

Nature of Embedded Systems Consulting company forced us to build reliable
infrastructure for kernels and rootfses building and deployment. It took quite
a lot of time since there are a lot of options, but not much was working
according to our specs.

Our virtualization platform of choice was Proxmox we had to stick to that, since
transition was not an option. We started to put together our stack:

* Proxmox as virtualization platform
* docker-machine as hosts (VMs) management tool
* [docker-machine-driver-proxmox-ve](https://github.com/lnxbil/docker-machine-driver-proxmox-ve)
  driver required for docker-machine so it can communicate with Proxmox
* [RancherOS](https://rancher.com/rancher-os/) as our container OS
* [isar](https://github.com/ilbers/isar) as rootfs building framework
* [meta-virtualization](https://git.yoctoproject.org/cgit/cgit.cgi/meta-virtualization/) as framework for building Xen from source

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

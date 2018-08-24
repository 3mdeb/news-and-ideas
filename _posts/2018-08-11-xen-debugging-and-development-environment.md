---
post_title: Xen debugging and development environment
author: Piotr Król
layout: post
published: true
post_date: 2018-07-27 16:00:00

tags:
	- xen
	- iommu
	- coreboot
categories:
	- Firmware
    - OS Dev
---

[Recently](TBD) we were focused on AMD IOMMU enabling for PC Engines apuX
(GX-412TC) platforms. Our hypervisor of choice is Xen and we used it to verify
PCI passthrough feature. Unfortunately, booting process was not exactly stable
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

Always the same character, it seems to start printing `(XEN) Brought up 4
CPUs`, so suspicious code is probably right after [this log](https://xenbits.xen.org/gitweb/?p=xen.git;a=blob;f=xen/arch/x86/setup.c;h=468e51efef7a848f24acab43d69d74ab126b4b0e;hb=4507bb6ae2b778a484394338452546c1e4fc6ae5#l1544).

Because of that I decided to debug Xen, but first I had to get through
compilation and deployment procedure. In general I saw couple options for
compilation:

* Debian package modification - get sources through `apt source xen` and
  continue with Debian-way of building packages - this can be done either on
  host, in rootfs or in Docker container
* directly from Xen source tree using `make debball` - this can be done either
  on host either in container

Internet is not straight forward about best method, [Xen documentation](https://wiki.xenproject.org/wiki/Compiling_Xen_From_Source)
since I couldn't build Xen with `make debball`.

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

# Automation

Before taking next step we decided to automate things little bit. We will
combine our Docker container that helps in building and Ansible that helps in
deploying build results. We use our standard configuration which rely on
[pxe-server](https://github.com/3mdeb/pxe-server) and [RTE](TBD: RTE link).

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
seems to be outdated since I can't build `make debball`.

---
author: Piotr Król
layout: post
published: true
post_date: 2018-05-22 15:00:00

tags:
	- coreboot
	- apu2
	- iommu
	- virtualization
categories:
	- Firmware
---

In [last post](TBD) I introduced latest version of `pxe-server` project which
contain all necessary components to boot Xen on PC Engines apu2 over PXE. In
this post I would like to present IOMMU enabling process that I get through.

Base components of this work are [Kyösti Mälkki patches](http://xen.1045712.n5.nabble.com/Enabling-AMD-Vi-IOMMU-panics-Xen-td5731305.html)
and Timothy Pearson patches
[1](https://review.coreboot.org/#/c/coreboot/+/15186/),
[2](https://review.coreboot.org/#/c/coreboot/+/15165/) and
[3](https://review.coreboot.org/#/c/coreboot/+/15164/).

# Kyösti patches

Using first patches I was able to enable IOMMU with some features. `xl dmesg`
give me:

```
(XEN) AMD-Vi: IOMMU Extended Features:
(XEN)  - Peripheral Page Service Request
(XEN)  - Guest Translation
(XEN)  - Invalidate All Command
(XEN)  - Guest APIC supported
(XEN)  - Performance Counters
(XEN) AMD-Vi: IOMMU 0 Enabled.
(XEN) I/O virtualisation enabled
(XEN)  - Dom0 mode: Relaxed
```

It looks like FACS address in FADT is incorrect:

```
(XEN) ACPI: 32/64X FACS address mismatch in FADT - cffae240/0000000000000000, using 32
(XEN) ACPI:             wakeup_vec[cffae24c], vec_size[20]
```

There is also some complain about missing ACPI table for IOMMU:

```
(XEN) 0000:00:00.2 not found in ACPI tables; using same IOMMU as function 0
```

This patch series takes IVRS ACPI table from AGESA. What seems to be completely
different approach from patches published by Timothy where whole table is
created from scratch.


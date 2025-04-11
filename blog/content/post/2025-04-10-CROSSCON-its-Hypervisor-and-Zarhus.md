---
title: "CROSSCON, its Hypervisor, and Zarhus"
abstract: "Learn about CROSSCON, how it's hypervisor works, and why running
          Zarhus on top of it streamlines development and testing on the RPi4."
cover: /covers/crosscon-logo.png
author: wiktor.grzywacz
layout: post
published: true
date: 2025-04-10
archives: "2025"

tags:
  - hypervisor
  - virtualization
  - zarhus
  - arm
categories:
  - Virtualization
  - Security
  - Firmware

---

## Introduction: what is CROSSCON?

Modern IoT systems increasingly require robust security while supporting
various hardware platforms. Enter [**CROSSCON**](https://crosscon.eu/), which
stands for **Cross-platform Open Security Stack for Connected Devices**.
CROSSCON is a consortium-based (part of which is 3mdeb) project aimed at
delivering an open, modular, portable, and vendor-agnostic security stack for
IoT.

Its goal: ensure devices within any IoT ecosystem meet essential security
standards, preventing attackers from turning smaller or more vulnerable
devices into easy entry points.

Here you can find the links to CROSSCON repositories, which contain the software
used to achieve what is mentioned above:

- [this repository](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/)
  contains demos of the CROSSCON stack for various platforms, including `QEMU`
  and the `RPi4`.
- [the CROSSCON Hypervisor](https://github.com/crosscon/CROSSCON-Hypervisor/) is
  probably the most important component - during the default demo for the
  `RPi4`, it is compiled with a config that includes an `OPTEE-OS` VM, and a
  linux VM.

The [CROSSCON project's website](https://crosscon.eu/) is a good resource for
learning about the project's goals. The
[use-cases page](https://crosscon.eu/use-cases) contains a great overview of
the exact features that the stack has, including it's security and quality of
life applications.

The [publications page](https://crosscon.eu/publications)
has interesting papers from members of the consortium about the project and the
challenges it will face - I recommend reading
[this one](https://crosscon.eu/sites/crosscon/files/public/content-files/2024-12/CROSSCON_White_Paper.pdf),
which gives a good overview of the whole project. This image illustrates how
the whole stack interacts together:

![CROSSCON stack overview](/img/crosscon-stack-overview.png)

---

## The CROSSCON Hypervisor

The
[**CROSSCON Hypervisor**](https://github.com/crosscon/CROSSCON-Hypervisor/tree/main)
is a key piece of CROSSCON’s open security stack. It
builds upon the [Bao hypervisor](https://github.com/bao-project/bao-hypervisor),
a lightweight static-partitioning hypervisor offering strong isolation
and real-time guarantees. Below are some highlights of its architecture and
capabilities:

### Static Partitioning and Isolation

The Bao foundation provides **static partitioning** of resources - CPUs, memory,
and I/O - among multiple virtual machines (VMs). This approach ensures that
individual VMs do not interfere with one another, improving fault tolerance and
security. Each VM has dedicated hardware resources:

- **Memory:** Statically assigned using two-stage translation.
- **Interrupts:** Virtual interrupts are mapped one-to-one with physical interrupts.
- **CPUs:** Each VM can directly control its allocated CPU cores without a
  conventional scheduler.

### Dynamic VM Creation

To broaden applicability in IoT scenarios, CROSSCON Hypervisor introduces a
**dynamic VM creation** feature. Instead of being fixed at boot, new VMs can be
instantiated during runtime using the **VM-stack mechanism** and a hypervisor call
interface. A host OS driver interacts with the Hypervisor to pass it a
configuration file, prompting CROSSCON Hypervisor to spawn the child VM. During
this process, resources - aside from the CPUs - are reclaimed from the parent VM
and reassigned to the newly created VM, ensuring isolation between VMs.

### Per-VM Trusted Execution Environment (TEE)

CROSSCON Hypervisor also supports **per-VM TEE** services by pairing each guest
OS with its own trusted environment. This approach leverages OP-TEE (both on
Arm and RISC-V architectures) so that even within the “normal” world, multiple
trusted OS VMs can run safely in isolation.

---

## Why it's Convenient to Have Zarhus on the Hypervisor

During our time working with the
[default demo for the RPi4](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws),
our team ran into a couple of problems, mainly relating to the bare-bones nature
of the provided `Buildroot` initramfs environment - while handy for
proof-of-concept, that environment lacks many essential development tools,
such as compilers, linkers, and other utilities that embedded engineers often
need. Any time we wanted to:

- Execute tests
- Gather logs
- Change the configuration of the build

it required cross-compiling the tools and assets that we need, which is
cumbersome. The lack of a `rootfs` can make working with trusted apps difficult,
especially when it comes to making sure that they interact with the `OPTEE-OS`
(in the second VM) properly.

It was then we realized that we could combine the existing process for booting
the CROSSCON Hypervisor on the `RPi4` with our Yocto-based OS, Zarhus. This
would eliminate our previous problems, and speed up testing and working with
the Hypervisor, due to the immediate availability of compilers, linkers and
other tools, as well as having a `rootfs` at our disposal.

Bringing **Zarhus** to the CROSSCON Hypervisor significantly boosts development
and testing convenience, especially on the Raspberry Pi 4:

- ***Full Toolchain Availability:** With Zarhus, we would gain out-of-the-box
  compilers, linkers, and more. This would be a major
  improvement over the limited `Buildroot` initramfs environment.

- **Faster Iteration:** We could build and test software entirely within the
  guest environment - without a need to rely on external cross-compilation or
  complicated host setups.

- **Complete Rootfs Mounting:** With Zarhus mounting a full filesystem,
  we could easily install additional tools through `Yocto`, manage
  logs, and run services in ways that would be impossible or extremely
  cumbersome in a minimal initramfs environment.

---

## How to Build Zarhus for the CROSSCON Hypervisor

The initial idea was simple: the Hypervisor is built based on a
[config file](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/blob/master/rpi4-ws/configs/rpi4-single-vTEE/config.c),
that specifies things like:

- How many VM's there are
- What their interrupts are
- The VM's access to memory
- Shared memory addresses
- etc...

In that file we can see, that each VM has an image on which it is built. The
linux VM (the one that interests us) is specified here:

```c
// Linux Image
VM_IMAGE(linux_image, "../lloader/linux-rpi4.bin");
```

That path points to an image built with `lloader`, and that image contains
the linux kernel and the device tree file. This is done during
[step 9](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws#step-9-bind-linux-image-and-device-tree)
of the demo.

We realized that we could swap that linux kernel for one automatically generated
in our `Yocto` build environment. This initially didn't work - `Yocto` by
default builds a `zImage` - a compressed version of the kernel that is
self-extracting, where we needed an `Image` kernel - the generic binary image.

This was a quick fix in the `Yocto` build environment, with this line added:

```bitbake
KERNEL_IMAGETYPES = "Image"
```

So we have our kernel already - but what about the rest? Well I figured out
that thanks to
[this commit](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/commit/6fd4db8571839e35f593a4a983c4a6e862254f75),
the whole SD card is already exposed - we just have to put our `rootfs` there
and give the kernel info on how to mount it.

The demo relies on a
[manually partitioned SD card](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws#prepare-sdcard),
which contains one partition - with everything needed to run the demo.

Since Yocto provides us with `.wic.bmap` and `.wic.gz` files already, I have
decided to use them. By flashing our SD card with those files, we would have
an SD card with two partitions, `/boot` and `/root` - all we have to do is
after flashing, remove everything from the `/boot` partition and replace it
with the firmware and the Hypervisor file (that already contains our kernel).

It was at this point where I thought I had done everything, and that the
configuration should work. But I quickly ran into many problems that I had to
fix, some of them being:

<!-- TBD:
write about:
* serial problems (8250.nr_uarts=8, console=ttyS1,115200)
* problems mounting the rootfs (root=/dev/mmcblk1p2 rw rootwait)
* magic printk issue
* having to edit /etc/fstab to make the rootfs be able to mount

I will add info here on how I came across these problems, and how I figured
out the solution. I assume this will end up being around 100 lines
 -->

The result of all this debugging is a
[ready-to-follow](https://docs.zarhus.com/guides/rpi4-crosscon-hypervisor/)
guide on how this can be achieved.

It takes the user step-by-step on what changes need to be make in order to
get this setup to work.

There are still things to be added - right now we are working on recipes
inside `Yocto`, that will provide us with utilities such as `xtest`, a
`tee-supplicant` service, and custom drivers that will let us interact with
the `OPTEE-OS` VM properly. This will be the next big step in integrating
Zarhus and the CROSSCON Hypervisor together.

---

## Conclusion

The successful port of Zarhus to the CROSSCON hypervisor on the RPi4 marks
a milestone in our quest to simplify and streamline embedded development.
Where once we had to rely on a basic buildroot environment, we can now enjoy a
fully featured Linux distribution with all the trimmings - a huge leap forward
in flexibility and productivity.

If you've been using the CROSSCON Hypervisor demo on the RPi and trying to
test something on the Linux VM, there's a high chance you found the minimal
initramfs environment limiting. We suggest giving
[our setup](https://docs.zarhus.com/guides/rpi4-crosscon-hypervisor/) a try -
we are excited to see how developers might use this, and we remain committed to
expanding this solution.

For any questions or feedback, feel free to contact us at
<contact@3mdeb.com> or hop on our community channels:

- [Dasharo Matrix Workspace](https://matrix.to/#/#dasharo:matrix.org)
- join our quarterly [Dasharo Events related to Zarhus](https://vpub.dasharo.com/o/1)

to join the discussion.

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

## Introduction

When working with the CROSSCON Hypervisor on the `RPi4`, we found ourselves
needing a more stable and reliable setup for building the CROSSCON stack.
In it's simplest form, the
[provided demo](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws)
relies on a Buildroot initramfs.

We quickly realized that a lot of the things that we want to do with
the stack (for example building and testing TA-related applications, or
security tests of the Hypervisor) would be a lot easier if we had full rootfs
access.

It would also make reproduction, future integration and adding new tools easier,
if we based the demo off of our existing OS, [Zarhus](https://docs.zarhus.com/).

This is where the idea for Zarhus integration into the CROSSCON stack was born.

> Note: This content is mostly geared toward junior-mid level embedded systems
> developers. If you are a senior, there's a high chance that a good portion
> of the content might seem trivial to you.
>
> Also, if you already know what CROSSCON and it's Hypervisor are, feel free to
> jump ahead to
> [this section](#why-its-convenient-to-have-zarhus-on-the-hypervisor), where
> I delve deeper into the reasons for this integration, or even straight ahead
> into [this section](#how-to-build-zarhus-for-the-crosscon-hypervisor) if
> you're more interested in the technical challenges and how I solved them.

---

## What is CROSSCON?

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

If you've worked with [OpenXT](https://openxt.org/) before, you might notice
some similarities between it and CROSSCON. They're both open-source, and aim
to provide security and isolation.

That being said, they're trying to achieve this in different environments -
OpenXT is primarily geared toward `x86` hardware and relies on the `Xen`
hypervisor, whereas CROSSCON builds on the
[Bao hypervisor](https://github.com/bao-project/bao-hypervisor), with a strong
emphasis on ARM. CROSSCON is also designed with
**Trusted Execution Environments** in mind - something which OpenXT doesn't go
out of its way to support. While there is a conceptual overlap between
these two projects, they operate in entirely different ecosystems.

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
need. Any time I wanted to:

- Execute tests
- Gather logs
- Change the configuration of the build

it required cross-compiling the tools and assets that I need, which is
cumbersome. The lack of a `rootfs` can make working with trusted apps difficult,
especially when it comes to making sure that they interact with the `OPTEE-OS`
(in the second VM) properly.

This was especially true when working on TA's - development of TA's required
many different libraries, all of which required either cross compilation, or
manual implementation of the provided standard. This was very cumbersome and
slowed down progress a lot.

We also have limited operational familiarity with Buildroot. Our team has a lot
of day-to-day experience customizing and extending Yocto based systems.
Although it would be possible to expand the existing Buildroot setup, we thought
we would find ourselves spending a significant amount of time integrating
each needed tool or library. In contrast, working with Yocto (Zarhus in
particular) would let us leverage existing recipes and a development model we
already know inside-out, allowing us to focus on improving/testing the CROSSCON
stack, rather than wrestling with the build environment.

It was then I realized that I could combine the existing process for booting
the CROSSCON Hypervisor on the `RPi4` with our Yocto-based OS, Zarhus. This
would eliminate our previous problems, and speed up testing and working with
the Hypervisor, due to the immediate availability of compilers, linkers and
other tools, as well as having a `rootfs` at our disposal.

Bringing **Zarhus** to the CROSSCON Hypervisor significantly boosts development
and testing convenience, especially on the Raspberry Pi 4:

- **Full Toolchain Availability:** With Zarhus, I would gain out-of-the-box
  compilers, linkers, and more. This would be a major
  improvement over the limited `Buildroot` initramfs environment.

- **Faster Iteration:** I could build and test software entirely within the
  guest environment - without a need to rely on external cross-compilation or
  complicated host setups.

- **Complete Rootfs Mounting:** With Zarhus mounting a full filesystem,
  I could easily install additional tools through `Yocto`, manage
  logs, and run services in ways that would be impossible or extremely
  cumbersome in a minimal initramfs environment.

With Zarhus, we could have a recipe for the TA's, that has access to all of the
needed libraries, and the dependencies of that app can be easily added to the
environment.

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

In that file I could see that each VM has an image on which it is built. The
linux VM (the one that interests me) is specified here:

```c
// Linux Image
VM_IMAGE(linux_image, "../lloader/linux-rpi4.bin");
```

That path points to an image built with `lloader`, and that image contains
the linux kernel and the device tree file. This is done during
[step 9](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws#step-9-bind-linux-image-and-device-tree)
of the demo.

I realized that I could swap that linux kernel for one automatically generated
in our `Yocto` build environment. This initially didn't work - `Yocto` by
default builds a `zImage` - a compressed version of the kernel that is
self-extracting, whereas I needed an `Image` kernel - the generic binary image.

This was a quick fix in the `Yocto` build environment, with this line added:

```bitbake
KERNEL_IMAGETYPES = "Image"
```

So I have my kernel already - but what about the rest? Well I figured out
that thanks to
[this commit](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/commit/6fd4db8571839e35f593a4a983c4a6e862254f75),
the whole SD card is already exposed - I just have to put my `rootfs` there
and give the kernel info on how to mount it.

The demo relies on a
[manually partitioned SD card](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws#prepare-sdcard),
which contains one partition - with everything needed to run the demo.

Since Yocto provides us with `.wic.bmap` and `.wic.gz` files already, I have
decided to use them. By flashing our SD card with those files, I would have
an SD card with two partitions, `/boot` and `/root` - all I have to do is
after flashing, remove everything from the `/boot` partition and replace it
with the firmware and the Hypervisor file (that already contains our kernel).

It was at this point where I thought I had done everything, and that the
configuration should work. But I quickly ran into many problems that I had to
fix, some of them being:

### Picking the wrong Yocto build target

When building Zarhus for this setup, it's important to note that there are two
very similar targets for the `RPi4`:

- `raspberrypi4` - builds a 32-bit version of the system
- `raspberrypi4-64` - builds a 64-bit version of the system

When initially trying to get all of this to work, I made an oversight which
cost me a couple of hours of painstaking debugging - I mistakenly was choosing
a target which builds a 32-bit version of the system, whereas the CROSSCON
Hypervisor setup is designed to work on 64-bit systems.

Trying to get a 32-bit version to work here results in getting an abort
error from the Hypervisor, after it's done assigning interrupts:

```logs
CROSSCONHYP ERROR: no handler for abort ec = 0x20 iss: 0x6
```

This error wasn't very informative, and it gave us a hard time trying to find
the solution, which came seemingly out of nowhere. I was trying to recompile
the kernel manually within the `Yocto` build environment using `devtool`, when
I noticed that the appropriate toolchains weren't there.

That gave me a clue that this could be a 32-bit system instead of 64, and a
quick search online confirmed this.

### Problems with serial output

After fixing the system to be a 64-bit version, I finally managed to get some
logs from the kernel booting:

```logs
U-Boot> fatload mmc 0 0x200000 crossconhyp.bin; go 0x200000
27927040 bytes read in 1186 ms (22.5 MiB/s)
## Starting application at 0x00200000 ...

   _____ _____   ____   _____ _____  _____ ____  _   _
  / ____|  __ \ / __ \ / ____/ ____|/ ____/ __ \| \ | |
 | |    | |__) | |  | | (___| (___ | |   | |  | |  \| |
 | |    |  _  /| |  | |\___ \\___ \| |   | |  | | . ` |
 | |____| | \ \| |__| |____) |___) | |___| |__| | |\  |
  \_____|_|  \_\\____/|_____/_____/ \_____\____/|_| \_|
  _    _                             _
 | |  | |                           (_)
 | |__| |_   _ _ __    ___ _ ____   ___ ___  ___  _ __
 |  __  | | | | '_ \ / _ \ '__\ \ / / / __|/ _ \| '__|
 | |  | | |_| | |_) |  __/ |   \ V /| \__ \ (_) | |
 |_|  |_|\__, | .__/ \___|_|    \_/ |_|___/\___/|_|
          __/ | |
         |___/|_|

CROSSCONHYP INFO: Initializing VM 1
CROSSCONHYP INFO: VM 1 adding memory region, VA 0x20000000 size 0x40000000
CROSSCONHYP INFO: VM 1 adding MMIO region, VA: 0xfc000000 size: 0xfc000000 mapped at 0xfc000000
CROSSCONHYP INFO: VM 1 adding MMIO region, VA: 0x600000000 size: 0x600000000 mapped at 0x600000000
CROSSCONHYP INFO: VM 1 adding MMIO region, VA: 0x0 size: 0x0 mapped at 0x0
CROSSCONHYP INFO: VM 1 assigning interrupt 32
CROSSCONHYP INFO: VM 1 assigning interrupt 33
CROSSCONHYP INFO: VM 1 assigning interrupt 214
CROSSCONHYP INFO: VM 1 assigning interrupt 215
CROSSCONHYP INFO: VM 1 adding MMIO region, VA: 0x7d580000 size: 0x7d580000 mapped at 0x7d580000
CROSSCONHYP INFO: VM 1 assigning interrupt 0
CROSSCONHYP INFO: VM 1 assigning interrupt 4
CROSSCONHYP INFO: VM 1 assigning interrupt 157
CROSSCONHYP INFO: VM 1 assigning interrupt 158
CROSSCONHYP INFO: VM 1 adding MMIO region, VA: 0x0 size: 0x0 mapped at 0x0
CROSSCONHYP INFO: VM 1 assigning interrupt 27
CROSSCONHYP INFO: VM 1 adding IPC for shared memory 0 at VA: 0x8000000  size: 0x200000
CROSSCONHYP INFO: VM 1 adding memory region, VA 0x8000000 size 0x200000
CROSSCONHYP INFO: VM 1 is sdGPOS (normal VM)
[    0.000000] Booting Linux on physical CPU 0x0000000000 [0x410fd083]
[    0.000000] Linux version 6.6.22-v8 (oe-user@oe-host) (aarch64-zarhus-linux-gcc (GCC) 13.2.0, GNU ld (GNU Binutils) 2.42.0.20240216) #1 SMP PREEMPT Tue Mar 19 17:41:59 UTC 2024
[    0.000000] KASLR disabled due to lack of seed
[    0.000000] Machine model: Raspberry Pi 4 Model B
[    0.000000] earlycon: bcm2835aux0 at MMIO32 0x00000000fe215040 (options '115200n8')
[    0.000000] printk: bootconsole [bcm2835aux0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] [Firmware Bug]: Kernel image misaligned at boot, please fix your bootloader!
[    0.000000] Reserved memory: created CMA memory pool at 0x0000000030000000, size 256 MiB
[    0.000000] OF: reserved mem: initialized node linux,cma, compatible id shared-dma-pool
[    0.000000] OF: reserved mem: 0x0000000030000000..0x000000003fffffff (262144 KiB) map reusable linux,cma
[    0.000000] Zone ranges:
[    0.000000]   DMA      [mem 0x0000000020000000-0x000000003fffffff]
[    0.000000]   DMA32    [mem 0x0000000040000000-0x000000005fffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000020000000-0x000000005fffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000020000000-0x000000005fffffff]
[    0.000000] percpu: Embedded 31 pages/cpu s86632 r8192 d32152 u126976
[    0.000000] Detected PIPT I-cache on CPU0
[    0.000000] CPU features: detected: Spectre-v2
[    0.000000] CPU features: detected: Spectre-v3a
[    0.000000] CPU features: detected: Spectre-v4
[    0.000000] CPU features: detected: Spectre-BHB
[    0.000000] CPU features: detected: ARM erratum 1742098
[    0.000000] CPU features: detected: ARM errata 1165522, 1319367, or 1530923
[    0.000000] alternatives: applying boot alternatives
[    0.000000] Kernel command line: earlycon clk_ignore_unused ip=192.168.42.15 carrier_timeout=0
[    0.000000] Dentry cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Inode-cache hash table entries: 65536 (order: 7, 524288 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 258048
[    0.000000] mem auto-init: stack:all(zero), heap alloc:off, heap free:off
[    0.000000] software IO TLB: area num 1.
[    0.000000] software IO TLB: mapped [mem 0x000000002c000000-0x0000000030000000] (64MB)
[    0.000000] Memory: 672052K/1048576K available (14400K kernel code, 2248K rwdata, 4684K rodata, 5120K init, 1095K bss, 114380K reserved, 262144K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] ftrace: allocating 46620 entries in 183 pages
[    0.000000] ftrace: allocated 183 pages with 6 groups
[    0.000000] trace event string verifier disabled
[    0.000000] rcu: Preemptible hierarchical RCU implementation.
[    0.000000] rcu:     RCU event tracing is enabled.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=256 to nr_cpu_ids=1.
[    0.000000]  Trampoline variant of Tasks RCU enabled.
[    0.000000]  Rude variant of Tasks RCU enabled.
[    0.000000]  Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=1
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] Root IRQ handler: gic_handle_irq
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] arch_timer: cp15 timer(s) running at 54.00MHz (virt).
[    0.000000] clocksource: arch_sys_counter: mask: 0xffffffffffffff max_cycles: 0xc743ce346, max_idle_ns: 440795203123 ns
[    0.000000] sched_clock: 56 bits at 54MHz, resolution 18ns, wraps every 4398046511102ns
[    0.008334] Console: colour dummy device 80x25
[    0.012844] printk: console [tty0] enabled
[    0.017000] printk: bootconsole [bcm2835aux0] disabled
```

but that was the end of the output - it seemed to freeze. Once I noticed where
it was freezing:

```logs
[    0.017000] printk: bootconsole [bcm2835aux0] disabled
```

I knew there was some sort of serial console issue. I suspected that the system
was booting normally and without errors, and just not printing the output
because of an unconfigured console.

Adding this `console=ttyS1,115200` to `bootargs` in the device tree file used in
[step 9](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws#step-9-bind-linux-image-and-device-tree)
fixed the issue, but another one arose:

```logs
[    1.953218] bcm2835-aux-uart fe215040.serial: error -EINVAL: unable to register 8250 port
```

This is was an easy fix, again adding to `bootargs`, but this time
`8250.nr_uarts=8`. This line tells the `8250` serial driver to allocate up to 8
ports - the number doesn't really matter that much here, but by default it is
one, and that's not enough for the serial setup that I have.

### Mounting the rootfs

It was only after fixing the serial console issues, that I could uncover the
real issues - the kernel was panicking after all, I just couldn't see it
because of the lack of serial output:

```logs
[    2.898654] Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
[    2.907033] CPU: 0 PID: 1 Comm: swapper/0 Not tainted 6.6.22-v8 #1
[    2.913298] Hardware name: Raspberry Pi 4 Model B (DT)
[    2.918502] Call trace:
[    2.920974]  dump_backtrace+0x9c/0x100
[    2.924776]  show_stack+0x20/0x38
[    2.928133]  dump_stack_lvl+0x48/0x60
[    2.931842]  dump_stack+0x18/0x28
[    2.935197]  panic+0x328/0x390
[    2.938291]  mount_root_generic+0x26c/0x348
[    2.942530]  mount_root+0x17c/0x348
[    2.946062]  prepare_namespace+0x74/0x2b8
[    2.950123]  kernel_init_freeable+0x374/0x3d8
[    2.954537]  kernel_init+0x2c/0x1f8
[    2.958070]  ret_from_fork+0x10/0x20
[    2.961693] Kernel Offset: 0x80000 from 0xffffffc080000000
[    2.967250] PHYS_OFFSET: 0x0
[    2.970162] CPU features: 0x0,80000200,3c020000,0000421b
[    2.975543] Memory Limit: none
[    2.978634] ---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0) ]---
```

This was an oversight on my part - the rootfs was definitely there on the second
partition, but I hadn't properly instructed the kernel where to find it. As a
result, the kernel failed to locate the rootfs and triggered a panic.

This was fixed in the device tree file, by specifying the correct partition.
All it took was to add `root=/dev/mmcblk1p2 rw rootwait` to `bootargs` - this
way the kernel knows where the rootfs is, and will wait until it is mounted.

I thought that was the end of it for the rootfs mounting, but quickly realized
that it was never going to be this easy - turns out that this location must
also be specified on the rootfs itself, in `/etc/fstab`.

`/etc/fstab` is a Linux filesystem table - it's a configuration table that's
used by utilities such as `mount` and `findmnt`, and it's also processed by
`systemd-fstab-generator` for automatic mounting during boot. `/etc/fstab`
lists all available disk partitions, and indicates how they are supposed to be
initialized/integrated into the filesystem.

Our Yocto environment generates this `fstab` file automatically. When using
Zarhus "normally" (aka. without the CROSSCON Hypervisor), the partitions
specified within line up with what the kernel expects.

But the process of integrating the CROSSCON Hypervisor changes a lot of files
on the first partition, and I suspect that those changes (specifically
combining our kernel with the device tree file with `lloader`) cause a mismatch
in what the kernel expects, and what's actually in `/etc/fstab`.

All that needs to be done is to change `/dev/mmcblk0p1` to `/dev/mmcblk1p1`
in the last line:

```bash
user in ~ λ cat /mnt/etc/fstab
# stock fstab - you probably want to override this with a machine specific one

/dev/root            /                    auto       defaults              1  1
proc                 /proc                proc       defaults              0  0
devpts               /dev/pts             devpts     mode=0620,ptmxmode=0666,gid=5      0  0
tmpfs                /run                 tmpfs      mode=0755,nodev,nosuid,strictatime 0  0
tmpfs                /var/volatile        tmpfs      defaults              0  0

# uncomment this if your device has a SD/MMC/Transflash slot
#/dev/mmcblk0p1       /media/card          auto       defaults,sync,noauto  0  0

/dev/mmcblk1p1  /boot   vfat    defaults    0   0
user in ~ λ
```

and the root filesystem gets mounted properly.

### Issues logging in

I really thought it was the end of weird fixes by then, but there was one final
one. I was running into problems when the kernel was booting without any errors,
but suddenly freezing at some point. Initially I expected it to be a login
issue, so I was looking at the login service and other related things.

This turned out to not be the cause after all - I
[got info](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/issues/8#issuecomment-2702293550)
that repeatedly printing a message in a specific abort handler within the
Hypervisor fixes the issue of freezing and not being able to log in.

This is a Hypervisor related issue, and this is just a temporary workaround -
but it allows us to use the setup with `rootfs` and Zarhus. Any future
follow-ups regarding this will be in the corresponding
[GitHub issue](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/issues/8#issuecomment-2810046951).

### Summary

The result of all this debugging is a
[ready-to-follow](https://docs.zarhus.com/guides/rpi4-crosscon-hypervisor/)
guide on how a Zarhus setup with rootfs on the CROSSCON Hypervisor can be
achieved.

It takes the user step-by-step on what changes need to be make in order to
get this setup to work.

There are still things to be added - right now I am working on recipes
inside `Yocto`, that will provide us with utilities such as `xtest`, a
`tee-supplicant` service, and custom drivers that will let us interact with
the `OPTEE-OS` VM properly. This will be the next big step in integrating
Zarhus and the CROSSCON Hypervisor together.

---

## Conclusion

The successful port of Zarhus to the CROSSCON hypervisor on the RPi4 will make
life a lot easier when working with TA's on the Hypervisor, or trying to
execute security tests, or run any custom program. I hope that this will be
a big leap forward in flexibility and productivity - quite a big part of the
CROSSCON project is testing the whole stack, and it will be useful to be able
to do that straight from the linux VM itself, including compilation and
tweaking.

Also, since this is now a `Yocto` based setup, adding any new packages or
tools should be a breeze.

If you've been using the CROSSCON Hypervisor demo on the RPi and trying to
test something on the Linux VM, there's a high chance you found the minimal
initramfs environment limiting. I suggest giving
[our setup](https://docs.zarhus.com/guides/rpi4-crosscon-hypervisor/) a try -
I am excited to see how developers might use this, and 3mdeb remains committed
to expanding this solution.

For any questions or feedback, feel free to contact us at
<contact@3mdeb.com> or hop on our community channels:

- [Zarhus Matrix Workspace](https://matrix.to/#/#zarhus:matrix.3mdeb.com)
- join our [Zarhus Developers Meetup](https://events.dasharo.com/event/4/zarhus-developers-meetup-0x1)

to join the discussion.

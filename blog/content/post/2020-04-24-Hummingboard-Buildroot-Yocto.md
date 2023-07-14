---
title: HummingBoard Pulse with Yocto and Buildroot
abstract: 'In this article, I will show you how to build and run the image from
           Yocto Project and SolidRun at HummingBoard Pulse. Furthermore, you
           can find here examples of which tools and configurations were used.'
cover: /covers/yocto-vs-buildroot.png
author: cezary.sobczak
layout: post
published: true
date: 2020-04-24
archives: "2020"

tags:
  - Buildroot
  - HummingBoard
  - Yocto
  - u-boot
categories:
  - Miscellaneous
  - OS Dev

---

## Introduction

In this article, I will describe differences between two types of system
images, i.e. Buildroot and Yocto. I was using a HummingBoard Pulse as a
platform for my work. Wide description of a board you can found on
[this](https://developer.solid-run.com/knowledge-base/hummingboard-pulse-getting-started/)
website. After reading this, you will better understand which basics components
are important for building own Linux distribution and how to use tools to do it.

![hummingboard](/covers/hummboard.jpg)

## Start work with a HummingBoard

It's several things you need to possess:

* Linux at your PC (because this way is easier)
* 16GB Micro SD card
* 12V Power adapter (the board has wide-range input of 7V-36V but 12V is
recommended)
* MicroUSB to USB for the console because the HummingBoard Pulse has an onboard
FTDI chip, which means that there is no need to use external UART/USB converter
* HummingBoard with SOM of course

## Build and run a Buildroot image

Buildroot was adopted by a SolidRun company as a target platform for their devices.
For iMX8M includes a custom config pre-configured to pull in the latest
U-Boot and Linux kernel from the SolidRun BSP.

Before explaining a build process have a closer look at needed tools:

* C/C++ compiler
* GNU Make

You can download and check it like this:

  ```bash
  sudo apt-get install build-essential
  gcc -v
  make -v
  ```

Now follow these steps:

1. First thing to do is clone a github repository at your computer.

    ```bash
    git clone https://github.com/SolidRun/buildroot.git --branch sr-latest
    ```

2. Change a directory.

    ```bash
    cd buildroot
    ```

3. Make a default configuration for our HummingBoard then build an image.

    ```bash
    make solidrun_imx8mq_hbpulse_defconfig
    make
    ```

    It will seem something like this:

    ```bash
    >>>   Finalizing target directory
    # Check files that are touched by more than one package
    ./support/scripts/check-uniq-files -t target /home/csobczak/Documents/buildroot/output/build/packages-file-list.txt
    ./support/scripts/check-uniq-files -t staging /home/csobczak/Documents/buildroot/output/build/packages-file-list-staging.txt
    ./support/scripts/check-uniq-files -t host /home/csobczak/Documents/buildroot/output/build/packages-file-list-host.txt
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/gsyslimits.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/gcc-rich-location.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/internal-fn.def" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/ansidecl.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/tree-scalar-evolution.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/gimple-predict.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./libexec/gcc/aarch64-buildroot-linux-uclibc/7.4.0/install-tools/mkheaders" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/langhooks.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/lra.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/dbxout.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./bin/aarch64-buildroot-linux-uclibc-gcc.br_real" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/profile.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/highlev-plugin-common.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/tree-hasher.h" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    Warning: host file "./lib/gcc/aarch64-buildroot-linux-uclibc/7.4.0/plugin/include/cfg-flags.def" is touched by more than one package: [u'host-gcc-initial', u'host-gcc-final']
    ```

4. Now our image has to be flashed at SD card.

    ```bash
    sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M conv=fsync
    ```

     > `/dev/sdX` means a USB adapter device with SD card for example `sdc`

5. Check how it looks like at a HummingBoard

    ```bash
    sudo minicom -b 115200 -D /dev/ttyUSBx
    ```

    > Note: you need to connect a MicroUSB port with PC first

## Build and run a Yocto image

SolidRun does not provide Yocto support for **imx8**.
For this purpose repository `3mdeb/meta-imx8` was created. It contains
BSP layer for **HummingBoard Pulse** now only, but support for
other **imx8** could be available in the future. We might also push support
for this board to one of the already existing Yocto meta-layers.

As you may know, Yocto Project is using a `bitbake`, so for easier
management and update components, we are using a tool named `kas`. In more
detail, it is described in an earlier [blog](https://blog.3mdeb.com/2019/2019-02-07-kas/)
and [documentation](https://kas.readthedocs.io/en/1.0/).

For HummingBoard Pulse this layers was used:

* meta-freescale
* meta-freescale-distro
* meta-imx8
* meta-openembedded

`meta-imx8` is our custom layer, where we made modifications. You can find
here machines, layers and kernel configurations, BSP and kernel recipes.
We create or modify a BSP recipes for few elements:

* ARM Trusted Firmware for secure boot
* U-Boot as a bootloader
* make image

We forked SolidRun Buildroot repository and on that we based own
bootloader and Linux distribution. Whereas for **ATF** newest version was
adopted, than for `meta-freescale`, because of a problem with kernel booting.

### Prerequisites
If you want the process of building executed properly, you have to install and
update the tools below:

* [docker](https://docs.docker.com/engine/install/ubuntu/)
* [kas-docker 1.0](https://github.com/siemens/kas/blob/1.0/kas-docker) script
  downloaded and available in [PATH](https://en.wikipedia.org/wiki/PATH_(variable))

  ```bash
  wget -O ~/bin/kas-docker https://raw.githubusercontent.com/siemens/kas/1.0/kas-docker
  ```
* [bmaptool](https://source.tizen.org/documentation/reference/bmaptool)

  ```bash
  sudo apt install bmap-tools
  ```

  > You can also use `bmap-tools`
  > [from github](https://github.com/intel/bmap-tools) if it is not available
  > in your distro.

Next thing is repository:

* [meta-imx8](https://github.com/3mdeb/meta-imx8) repository cloned

  ```bash
  mkdir bsp-imx8 && cd bsp-imx8
  git clone https://github.com/3mdeb/meta-imx8.git
  ```

### Building

After an installation and update phase, it's time for building Yocto image.
For this purpose, I used the `kas-docker` script.

  ```bash
  kas-docker build meta-imx8/kas.yml
  ```

  > Note: It will take a while

You will see something like this:

  ```bash
  2020-04-08 07:51:39 - INFO     - kas 2.0 started
  2020-04-08 07:51:39 - INFO     - /repo$ git rev-parse --show-toplevel
  2020-04-08 07:51:40 - INFO     - /repo$ git rev-parse --show-toplevel
  2020-04-08 07:51:40 - INFO     - Using /repo as root for repository meta-imx8
  2020-04-08 07:51:40 - INFO     - /work/poky$ git remote set-url origin https://git.yoctoproject.org/git/poky
  2020-04-08 07:51:40 - INFO     - /work/meta-openembedded$ git remote set-url origin http://git.openembedded.org/meta-openembedded
  2020-04-08 07:51:40 - INFO     - /work/meta-freescale$ git remote set-url origin https://github.com/Freescale/meta-freescale.git
  2020-04-08 07:51:40 - INFO     - /work/meta-freescale-distro$ git remote set-url origin https://github.com/Freescale/meta-freescale-distro.git
  2020-04-08 07:51:40 - INFO     - /work/poky$ git cat-file -t fe857e4179355bcfb79303c16baf3ad87fca59a4
  2020-04-08 07:51:40 - INFO     - /work/meta-openembedded$ git cat-file -t e855ecc6d35677e79780adc57b2552213c995731
  2020-04-08 07:51:40 - INFO     - /work/meta-freescale$ git cat-file -t 3a3b13bef12c3a46da976fbf3b666310f8b694a7
  2020-04-08 07:51:40 - INFO     - /work/meta-freescale-distro$ git cat-file -t ca27d12e4964d1336e662bcc60184bbff526c857
  2020-04-08 07:51:40 - INFO     - Repository poky already contains fe857e4179355bcfb79303c16baf3ad87fca59a4 as commit
  2020-04-08 07:51:40 - INFO     - Repository meta-freescale already contains 3a3b13bef12c3a46da976fbf3b666310f8b694a7 as commit
  2020-04-08 07:51:40 - INFO     - Repository meta-freescale-distro already contains ca27d12e4964d1336e662bcc60184bbff526c857 as commit
  2020-04-08 07:51:40 - INFO     - Repository meta-openembedded already contains e855ecc6d35677e79780adc57b2552213c995731 as commit
  2020-04-08 07:51:40 - INFO     - /repo$ git rev-parse --show-toplevel
  2020-04-08 07:51:40 - INFO     - Using /repo as root for repository meta-imx8
  2020-04-08 07:51:40 - INFO     - /work/poky$ git status -s
  2020-04-08 07:51:40 - INFO     - /work/poky$ git rev-parse --verify HEAD
  2020-04-08 07:51:40 - INFO     - fe857e4179355bcfb79303c16baf3ad87fca59a4
  2020-04-08 07:51:40 - INFO     - Repo poky has already been checked out with correct refspec. Nothing to do.
  2020-04-08 07:51:40 - INFO     - /work/meta-openembedded$ git status -s
  2020-04-08 07:51:40 - INFO     - /work/meta-openembedded$ git rev-parse --verify HEAD
  2020-04-08 07:51:40 - INFO     - e855ecc6d35677e79780adc57b2552213c995731
  2020-04-08 07:51:40 - INFO     - Repo meta-openembedded has already been checked out with correct refspec. Nothing to do.
  2020-04-08 07:51:40 - INFO     - /work/meta-freescale$ git status -s
  2020-04-08 07:51:40 - INFO     - /work/meta-freescale$ git rev-parse --verify HEAD
  2020-04-08 07:51:40 - INFO     - 3a3b13bef12c3a46da976fbf3b666310f8b694a7
  2020-04-08 07:51:40 - INFO     - Repo meta-freescale has already been checked out with correct refspec. Nothing to do.
  2020-04-08 07:51:40 - INFO     - /work/meta-freescale-distro$ git status -s
  2020-04-08 07:51:40 - INFO     - /work/meta-freescale-distro$ git rev-parse --verify HEAD
  2020-04-08 07:51:40 - INFO     - ca27d12e4964d1336e662bcc60184bbff526c857
  2020-04-08 07:51:40 - INFO     - Repo meta-freescale-distro has already been checked out with correct refspec. Nothing to do.
  2020-04-08 07:51:40 - INFO     - /repo$ git rev-parse --show-toplevel
  2020-04-08 07:51:40 - INFO     - Using /repo as root for repository meta-imx8
  2020-04-08 07:51:40 - INFO     - /work/poky$ /tmp/tmpyoicsymr /work/build
  2020-04-08 07:51:40 - INFO     - /repo$ git rev-parse --show-toplevel
  2020-04-08 07:51:40 - INFO     - Using /repo as root for repository meta-imx8
  2020-04-08 07:51:40 - INFO     - /repo$ git rev-parse --show-toplevel
  2020-04-08 07:51:40 - INFO     - Using /repo as root for repository meta-imx8
  2020-04-08 07:51:40 - INFO     - /work/build$ /work/poky/bitbake/bin/bitbake -k -c build core-image-minimal
  ```

### Flashing

For this purpose use a `bmaptool`. This tool allows fast flashing, because of
the creation maps of blocks which improve all process.

  ```bash
  sudo bmaptool copy --bmap core-image-minimal-hummingboard-pulse.wic.bmap core-image-minimal-hummingboard-pulse.wic.gz /dev/sdX
  ```

  > First parameter after `--bmap` is file map then our image. As you can see
  > at the end is the target device.

### Running image at HummingBoard

From now you have `u-boot` and `kernel image` at your SD card.
Next thing you have to do is connect MicroUSB at the board with your PC and
run this line like before:

  ```bash
  sudo minicom -b 115200 -D /dev/ttyUSBx
  ```

In the console, you will see information about `u-boot` at first then a kernel
will start.

  ```
  Starting kernel ...

  [    0.000000] Booting Linux on physical CPU 0x0
  [    0.000000] Linux version 4.14.166-solidrun+ga33b5bfc5cc1 (oe-user@oe-host) (gcc version 9.2.0 (G0
  [    0.000000] Boot CPU: AArch64 Processor [410fd034]
  [    0.000000] Machine model: SolidRun i.MX8MQ HummingBoard Pulse
  [    0.000000] earlycon: ec_imx6q0 at MMIO 0x0000000030860000 (options '115200')
  [    0.000000] bootconsole [ec_imx6q0] enabled
  [    0.000000] efi: Getting EFI parameters from FDT:
  [    0.000000] efi: UEFI not found.
  [    0.000000] cma: Reserved 320 MiB at 0x00000000ec000000
  [    0.000000] psci: probing for conduit method from DT.
  [    0.000000] psci: PSCIv1.1 detected in firmware.
  [    0.000000] psci: Using standard PSCI v0.2 function IDs
  [    0.000000] psci: MIGRATE_INFO_TYPE not supported.
  [    0.000000] psci: SMC Calling Convention v1.1
  [    0.000000] percpu: Embedded 20 pages/cpu s43288 r8192 d30440 u81920
  [    0.000000] Detected VIPT I-cache on CPU0
  [    0.000000] CPU features: enabling workaround for ARM errata 826319, 827319, 824069
  [    0.000000] CPU features: enabling workaround for ARM erratum 845719
  [    0.000000] Speculative Store Bypass Disable mitigation not required
  [    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 773120
  [    0.000000] Kernel command line: console=ttymxc0,115200 earlycon=ec_imx6q,0x30860000,115200 root=0
  [    0.000000] log_buf_len individual max cpu contribution: 4096 bytes
  [    0.000000] log_buf_len total cpu_extra contributions: 12288 bytes
  [    0.000000] log_buf_len min size: 16384 bytes
  [    0.000000] log_buf_len: 32768 bytes
  [    0.000000] early log buf free: 14396(87%)
  [    0.000000] PID hash table entries: 4096 (order: 3, 32768 bytes)
  [    0.000000] Dentry cache hash table entries: 524288 (order: 10, 4194304 bytes)
  [    0.000000] Inode-cache hash table entries: 262144 (order: 9, 2097152 bytes)
  [    0.000000] Memory: 2742008K/3141632K available (10364K kernel code, 948K rwdata, 3712K rodata, 5)
  [    0.000000] Virtual kernel memory layout:
  [    0.000000]     modules : 0xffff000000000000 - 0xffff000008000000   (   128 MB)
  [    0.000000]     vmalloc : 0xffff000008000000 - 0xffff7dffbfff0000   (129022 GB)
  [    0.000000]       .text : 0xffff000008080000 - 0xffff000008aa0000   ( 10368 KB)
  [    0.000000]     .rodata : 0xffff000008aa0000 - 0xffff000008e50000   (  3776 KB)
  [    0.000000]       .init : 0xffff000008e50000 - 0xffff000008ee0000   (   576 KB)
  [    0.000000]       .data : 0xffff000008ee0000 - 0xffff000008fcd200   (   949 KB)
  [    0.000000]        .bss : 0xffff000008fcd200 - 0xffff00000900d4a0   (   257 KB)
  [    0.000000]     fixed   : 0xffff7dfffe7fb000 - 0xffff7dfffec00000   (  4116 KB)
  [    0.000000]     PCI I/O : 0xffff7dfffee00000 - 0xffff7dffffe00000   (    16 MB)
  [    0.000000]     vmemmap : 0xffff7e0000000000 - 0xffff800000000000   (  2048 GB maximum)
  [    0.000000]               0xffff7e0000000000 - 0xffff7e0003000000   (    48 MB actual)
  [    0.000000]     memory  : 0xffff800000000000 - 0xffff8000c0000000   (  3072 MB)
  [    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
  [    0.000000] Preemptible hierarchical RCU implementation.
  [    0.000000]  RCU restricting CPUs from NR_CPUS=64 to nr_cpu_ids=4.
  [    0.000000]  Tasks RCU enabled.
  [    0.000000] RCU: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=4
  [    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
  [    0.000000] GICv3: GIC: Using split EOI/Deactivate mode
  [    0.000000] GICv3: no VLPI support, no direct LPI support
  [    0.000000] ITS: No ITS available, not enabling LPIs
  [    0.000000] GICv3: CPU0: found redistributor 0 region 0:0x0000000038880000
  [    0.000000] i.MX8MQ clock driver init done
  [    0.000000] arch_timer: cp15 timer(s) running at 8.33MHz (phys).
  [    0.000000] clocksource: arch_sys_counter: mask: 0xffffffffffffff max_cycles: 0x1ec0311ec, max_ids
  [    0.000003] sched_clock: 56 bits at 8MHz, resolution 120ns, wraps every 2199023255541ns
  [    0.008045] system counter timer init
  [    0.011613] sched_clock: 56 bits at 8MHz, resolution 120ns, wraps every 2199023255541ns
  [    0.019528] clocksource: imx sysctr: mask: 0xffffffffffffff max_cycles: 0x1ec0311ec, max_idle_ns:s
  [    0.029946] Console: colour dummy device 80x25
  [    0.034149] Calibrating delay loop (skipped), value calculated using timer frequency.. 16.66 Bogo)
  [    0.044331] pid_max: default: 32768 minimum: 301
  [    0.048976] Security Framework initialized
  [    0.053013] Mount-cache hash table entries: 8192 (order: 4, 65536 bytes)
  [    0.059634] Mountpoint-cache hash table entries: 8192 (order: 4, 65536 bytes)
  [    0.082768] ASID allocator initialised with 32768 entries
  [    0.090768] Hierarchical SRCU implementation.
  [    0.099162] CPU identified as i.MX8MQ, silicon rev 2.0
  [    0.101506] EFI services will not be available.
  [    0.113951] smp: Bringing up secondary CPUs ...
  [    0.142077] Detected VIPT I-cache on CPU1
  [    0.142100] GICv3: CPU1: found redistributor 1 region 0:0x00000000388a0000
  [    0.142117] CPU1: Booted secondary processor [410fd034]
  [    0.170120] Detected VIPT I-cache on CPU2
  [    0.170136] GICv3: CPU2: found redistributor 2 region 0:0x00000000388c0000
  [    0.170150] CPU2: Booted secondary processor [410fd034]
  [    0.198182] Detected VIPT I-cache on CPU3
  [    0.198198] GICv3: CPU3: found redistributor 3 region 0:0x00000000388e0000
  [    0.198211] CPU3: Booted secondary processor [410fd034]
  [    0.198274] smp: Brought up 1 node, 4 CPUs
  [    0.247466] SMP: Total of 4 processors activated.
  [    0.252127] CPU features: detected: GIC system register CPU interface
  [    0.258527] CPU features: detected: 32-bit EL0 Support
  [    0.264478] CPU: All CPU(s) started at EL2
  [    0.267704] alternatives: patching kernel code
  [    0.273031] devtmpfs: initialized
  [    0.280811] random: get_random_u32 called from bucket_table_alloc+0x104/0x268 with crng_init=0
  [    0.286946] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 764504178s
  [    0.296226] futex hash table entries: 1024 (order: 5, 131072 bytes)
  [    0.310301] pinctrl core: initialized pinctrl subsystem
  [    0.313325] NET: Registered protocol family 16
  [    0.321113] cpuidle: using governor menu
  [    0.322763] vdso: 2 pages (1 code @ ffff000008aa6000, 1 data @ ffff000008ee4000)
  [    0.329529] hw-breakpoint: found 6 breakpoint and 4 watchpoint registers.
  [    0.341793] DMA: preallocated 256 KiB pool for atomic allocations
  [    0.345236] imx rpmsg driver is registered.
  [    0.352919] imx8mq-pinctrl 30330000.iomuxc: initialized IMX pinctrl driver
  [    0.362467] MU is ready for cross core communication!
  [    0.366071] virtio_rpmsg_bus virtio0: rpmsg host is online
  [    0.381002] HugeTLB registered 2.00 MiB page size, pre-allocated 0 pages
  [    0.392085] vgaarb: loaded
  [    0.392307] SCSI subsystem initialized
  [    0.395947] usbcore: registered new interface driver usbfs
  [    0.401138] usbcore: registered new interface driver hub
  [    0.407079] usbcore: registered new device driver usb
  [    0.412188] i2c i2c-0: IMX I2C adapter registered
  [    0.416065] i2c i2c-0: can't use DMA, using PIO instead.
  [    0.421630] i2c i2c-1: IMX I2C adapter registered
  [    0.425998] i2c i2c-1: can't use DMA, using PIO instead.
  [    0.431605] i2c i2c-2: IMX I2C adapter registered
  [    0.435973] i2c i2c-2: can't use DMA, using PIO instead.
  [    0.441315] media: Linux media interface: v0.10
  [    0.445711] Linux video capture interface: v2.00
  [    0.450345] pps_core: LinuxPPS API ver. 1 registered
  [    0.455186] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.>
  [    0.464280] PTP clock support registered
  [    0.468499] Advanced Linux Sound Architecture Driver Initialized.
  [    0.474663] Bluetooth: Core ver 2.22
  [    0.477751] NET: Registered protocol family 31
  [    0.482144] Bluetooth: HCI device and connection manager initialized
  [    0.488452] Bluetooth: HCI socket layer initialized
  [    0.493289] Bluetooth: L2CAP socket layer initialized
  [    0.498312] Bluetooth: SCO socket layer initialized
  [    0.503857] clocksource: Switched to clocksource arch_sys_counter
  [    0.509293] VFS: Disk quotas dquot_6.6.0
  [    0.513125] VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)
  [    0.525603] NET: Registered protocol family 2
  [    0.527436] TCP established hash table entries: 32768 (order: 6, 262144 bytes)
  [    0.534517] TCP bind hash table entries: 32768 (order: 7, 524288 bytes)
  [    0.541356] TCP: Hash tables configured (established 32768 bind 32768)
  [    0.547382] UDP hash table entries: 2048 (order: 4, 65536 bytes)
  [    0.553368] UDP-Lite hash table entries: 2048 (order: 4, 65536 bytes)
  [    0.559843] NET: Registered protocol family 1
  [    0.564261] RPC: Registered named UNIX socket transport module.
  [    0.569883] RPC: Registered udp transport module.
  [    0.574540] RPC: Registered tcp transport module.
  [    0.579200] RPC: Registered tcp NFSv4.1 backchannel transport module.
  [    0.586332] hw perfevents: enabled with armv8_pmuv3 PMU driver, 7 counters available
  [    0.596382] audit: initializing netlink subsys (disabled)
  [    0.598998] audit: type=2000 audit(0.479:1): state=initialized audit_enabled=0 res=1
  [    0.599373] workingset: timestamp_bits=46 max_order=20 bucket_order=0
  [    0.618775] squashfs: version 4.0 (2009/01/31) Phillip Lougher
  [    0.622285] NFS: Registering the id_resolver key type
  [    0.626774] Key type id_resolver registered
  [    0.630919] Key type id_legacy registered
  [    0.634880] nfs4filelayout_init: NFSv4 File Layout Driver Registering...
  [    0.641697] jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
  [    0.647980] 9p: Installing v9fs 9p2000 file system support
  [    0.657751] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 246)
  [    0.662277] io scheduler noop registered
  [    0.666257] io scheduler cfq registered (default)
  [    0.670827] io scheduler mq-deadline registered
  [    0.675336] io scheduler kyber registered
  [    0.679454] io scheduler bfq registered
  [    0.686141] imx-sdma 30bd0000.sdma: no iram assigned, using external mem
  [    0.693608] imx-sdma 30bd0000.sdma: Falling back to user helper
  [    0.697011] imx-sdma 302c0000.sdma: no iram assigned, using external mem
  [    0.712017] Bus freq driver module loaded
  [    0.714272] Config NOC for VPU and CPU
  [    0.717874] pfuze100-regulator 0-0008: Full layer: 2, Metal layer: 1
  [    0.723508] pfuze100-regulator 0-0008: FAB: 0, FIN: 0
  [    0.728253] pfuze100-regulator 0-0008: pfuze100 found.
  [    0.743938] Serial: 8250/16550 driver, 4 ports, IRQ sharing disabled
  [    0.749303] 30860000.serial: ttymxc0 at MMIO 0x30860000 (irq = 39, base_baud = 1562500) is a IMX
  [    0.759006] console [ttymxc0] enabled
  [    0.759006] console [ttymxc0] enabled
  [    0.763472] bootconsole [ec_imx6q0] disabled
  [    0.763472] bootconsole [ec_imx6q0] disabled
  [    0.772500] 30880000.serial: ttymxc2 at MMIO 0x30880000 (irq = 40, base_baud = 5000000) is a IMX
  [    0.784039] 30890000.serial: ttymxc1 at MMIO 0x30890000 (irq = 41, base_baud = 1562500) is a IMX
  [    0.793293] 30a60000.serial: ttymxc3 at MMIO 0x30a60000 (irq = 43, base_baud = 5000000) is a IMX
  [    0.810977] [drm] Supports vblank timestamp caching Rev 2 (21.10.2013).
  [    0.817609] [drm] No driver support for vblank timestamp query.
  [    0.823663] imx-drm display-subsystem: bound imx-dcss-crtc.0 (ops dcss_crtc_ops)
  [    0.831212] [drm] CDN_API_General_Test_Echo_Ext_blocking - APB(ret = 0 echo_resp = echo test)
  [    0.839756] [drm] CDN_API_General_getCurVersion - ver 13196 verlib 13062
  [    0.846504] [drm] Pixel clock frequency: 594000 KHz, character clock frequency: 594000, color dep.
  [    0.856437] [drm] Pixel clock frequency (594000 KHz) is supported in this color depth (8-bit). Se7
  [    0.867226] [drm] VCO frequency is 5940000
  [    0.871336] [drm] VCO frequency (5940000 KHz) is supported. Settings found in row 14
  [    0.903139] [drm] CDN_API_General_Write_Register_blocking LANES_CONFIG ret = 0
  [    0.910388] [drm] Failed to get HDCP config - using HDCP 2.2 only
  [    0.916556] [drm] Failed to initialize HDCP
  [    0.921078] [drm] hdmi-audio-codec driver bound to HDMI
  [    0.926324] imx-drm display-subsystem: bound 32c00000.hdmi (ops imx_hdp_imx_ops)
  [    0.933777] [drm] Cannot find any crtc or sizes
  [    0.938626] [drm] Initialized imx-drm 1.0.0 20120507 for display-subsystem on minor 0
  [    0.951477] loop: module loaded
  [    0.955270] slram: not enough parameters.
  [    0.959937] libphy: Fixed MDIO Bus: probed
  [    0.964045] tun: Universal TUN/TAP device driver, 1.6
  [    0.970540] fec 30be0000.ethernet: 30be0000.ethernet supply phy not found, using dummy regulator
  [    0.982524] pps pps0: new PPS source ptp0
  [    0.991230] libphy: fec_enet_mii_bus: probed
  [    0.996363] fec 30be0000.ethernet eth0: registered PHC device 0
  [    1.002963] e1000e: Intel(R) PRO/1000 Network Driver - 3.2.6-k
  [    1.008811] e1000e: Copyright(c) 1999 - 2015 Intel Corporation.
  [    1.014793] igb: Intel(R) Gigabit Ethernet Network Driver - version 5.4.0-k
  [    1.021768] igb: Copyright (c) 2007-2014 Intel Corporation.
  [    1.027394] igbvf: Intel(R) Gigabit Virtual Function Network Driver - version 2.4.0-k
  [    1.035237] igbvf: Copyright (c) 2009 - 2012 Intel Corporation.
  [    1.041201] sky2: driver version 1.30
  [    1.050294] ehci_hcd: USB 2.0 'Enhanced' Host Controller (EHCI) Driver
  [    1.056844] ehci-pci: EHCI PCI platform driver
  [    1.061344] ehci-platform: EHCI generic platform driver
  [    1.066745] ohci_hcd: USB 1.1 'Open' Host Controller (OHCI) Driver
  [    1.072950] ohci-pci: OHCI PCI platform driver
  [    1.077435] ohci-platform: OHCI generic platform driver
  [    1.083188] Can't support > 32 bit dma.
  [    1.087070] xhci-hcd xhci-hcd.0.auto: xHCI Host Controller
  [    1.092585] xhci-hcd xhci-hcd.0.auto: new USB bus registered, assigned bus number 1
  [    1.105648] xhci-hcd xhci-hcd.0.auto: hcc params 0x0220fe6c hci version 0x110 quirks 0x00000000010
  [    1.115100] xhci-hcd xhci-hcd.0.auto: irq 231, io mem 0x38100000
  [    1.121632] hub 1-0:1.0: USB hub found
  [    1.125419] hub 1-0:1.0: 1 port detected
  [    1.129588] xhci-hcd xhci-hcd.0.auto: xHCI Host Controller
  [    1.135094] xhci-hcd xhci-hcd.0.auto: new USB bus registered, assigned bus number 2
  [    1.142772] xhci-hcd xhci-hcd.0.auto: Host supports USB 3.0  SuperSpeed
  [    1.149828] hub 2-0:1.0: USB hub found
  [    1.153616] hub 2-0:1.0: 1 port detected
  [    1.157809] Can't support > 32 bit dma.
  [    1.161694] xhci-hcd xhci-hcd.1.auto: xHCI Host Controller
  [    1.167199] xhci-hcd xhci-hcd.1.auto: new USB bus registered, assigned bus number 3
  [    1.180208] xhci-hcd xhci-hcd.1.auto: hcc params 0x0220fe6c hci version 0x110 quirks 0x00000000010
  [    1.189656] xhci-hcd xhci-hcd.1.auto: irq 232, io mem 0x38200000
  [    1.196126] hub 3-0:1.0: USB hub found
  [    1.199914] hub 3-0:1.0: 1 port detected
  [    1.204077] xhci-hcd xhci-hcd.1.auto: xHCI Host Controller
  [    1.209582] xhci-hcd xhci-hcd.1.auto: new USB bus registered, assigned bus number 4
  [    1.217254] xhci-hcd xhci-hcd.1.auto: Host supports USB 3.0  SuperSpeed
  [    1.224313] hub 4-0:1.0: USB hub found
  [    1.228093] hub 4-0:1.0: 1 port detected
  [    1.232458] usbcore: registered new interface driver usb-storage
  [    1.238519] usbcore: registered new interface driver usb_ehset_test
  [    1.248049] rtc-abx80x 2-0069: model 1805, revision 2.3, lot 15, wafer 14, uid 17b1
  [    1.256796] rtc-abx80x 2-0069: Enabling trickle charger: 05
  [    1.265076] rtc-abx80x 2-0069: Oscillator failure, data is invalid.
  [    1.271494] rtc-abx80x 2-0069: rtc core: registered abx8xx as rtc0
  [    1.278223] snvs_rtc 30370000.snvs:snvs-rtc-lp: registered as rtc1
  [    1.284526] i2c /dev entries driver
  [    1.288368] IR NEC protocol handler initialized
  [    1.292916] IR RC5(x/sz) protocol handler initialized
  [    1.297976] IR RC6 protocol handler initialized
  [    1.302515] IR JVC protocol handler initialized
  [    1.307053] IR Sony protocol handler initialized
  [    1.311678] IR SANYO protocol handler initialized
  [    1.316390] IR Sharp protocol handler initialized
  [    1.321107] IR MCE Keyboard/mouse protocol handler initialized
  [    1.326948] IR XMP protocol handler initialized
  [    1.332828] imx2-wdt 30280000.wdog: timeout 60 sec (nowayout=0)
  [    1.338825] Bluetooth: HCI UART driver ver 2.3
  [    1.343281] Bluetooth: HCI UART protocol H4 registered
  [    1.348480] usbcore: registered new interface driver btusb
  [    1.354031] usbcore: registered new interface driver ath3k
  [    1.360304] sdhci: Secure Digital Host Controller Interface driver
  [    1.366494] sdhci: Copyright(c) Pierre Ossman
  [    1.370890] sdhci-pltfm: SDHCI platform and OF driver helper
  [    1.424419] mmc0: SDHCI controller on 30b40000.usdhc [30b40000.usdhc] using ADMA
  [    1.433441] mmc1: CQHCI version 0.00
  [    1.437078] sdhci-esdhc-imx 30b50000.usdhc: Got CD GPIO
  [    1.493081] mmc1: SDHCI controller on 30b50000.usdhc [30b50000.usdhc] using ADMA
  [    1.507570] ledtrig-cpu: registered to indicate activity on CPUs
  [    1.514149] caam 30900000.caam: ERA source: CCBVID.
  [    1.520241] caam 30900000.caam: device ID = 0x0a16040100000000 (Era 9)
  [    1.526790] caam 30900000.caam: job rings = 3, qi = 0, dpaa2 = no
  [    1.535775] caam_jr 30901000.jr0: Entropy delay = 3200
  [    1.541040] caam_jr 30901000.jr0: Entropy delay = 3600
  [    1.552388] usb 3-1: new high-speed USB device number 2 using xhci-hcd
  [    1.573563] mmc1: host does not support reading read-only switch, assuming write-enable
  [    1.606074] mmc0: new HS400 MMC card at address 0001
  [    1.611617] mmcblk0: mmc0:0001 8GTF4R 7.28 GiB
  [    1.616167] caam_jr 30901000.jr0: Instantiated RNG4 SH0.
  [    1.621841] mmcblk0boot0: mmc0:0001 8GTF4R partition 1 4.00 MiB
  [    1.628128] mmcblk0boot1: mmc0:0001 8GTF4R partition 2 4.00 MiB
  [    1.634177] mmcblk0rpmb: mmc0:0001 8GTF4R partition 3 512 KiB, chardev (244:0)
  [    1.681567] caam_jr 30901000.jr0: Instantiated RNG4 SH1.
  [    1.701886] caam algorithms registered in /proc/crypto
  [    1.708245] random: fast init done
  [    1.712736] caam_jr 30901000.jr0: registering rng-caam
  [    1.718126] caam 30900000.caam: caam pkc algorithms registered in /proc/crypto
  [    1.726606] caam-snvs 30370000.caam-snvs: can't get snvs clock
  [    1.732507] caam-snvs 30370000.caam-snvs: violation handlers armed - non-secure state
  [    1.740575] hub 3-1:1.0: USB hub found
  [    1.741349] usbcore: registered new interface driver usbhid
  [    1.749938] hub 3-1:1.0: 4 ports detected
  [    1.754016] usbhid: USB HID core driver
  [    1.770237] mmc1: new ultra high speed SDR104 SDHC card at address aaaa
  [    1.777409] mmcblk1: mmc1:aaaa SC16G 14.8 GiB
  [    1.784221] imx-wm8524 sound-wm8524: wm8524-hifi <-> 308b0000.sai mapping ok
  [    1.791342]  mmcblk1: p1 p2
  [    1.797107] imx-spdif sound-spdif: snd-soc-dummy-dai <-> 30810000.spdif mapping ok
  [    1.806640] imx-spdif sound-hdmi-arc: snd-soc-dummy-dai <-> 308a0000.spdif mapping ok
  [    1.816186] imx-cdnhdmi sound-hdmi: i2s-hifi <-> 30050000.sai mapping ok
  [    1.823464] NET: Registered protocol family 26
  [    1.828023] NET: Registered protocol family 17
  [    1.832555] Bluetooth: RFCOMM TTY layer initialized
  [    1.837451] Bluetooth: RFCOMM socket layer initialized
  [    1.839918] usb 4-1: new SuperSpeed USB device number 2 using xhci-hcd
  [    1.842610] Bluetooth: RFCOMM ver 1.11
  [    1.852881] Bluetooth: BNEP (Ethernet Emulation) ver 1.3
  [    1.858200] Bluetooth: BNEP filters: protocol multicast
  [    1.863438] Bluetooth: BNEP socket layer initialized
  [    1.868411] Bluetooth: HIDP (Human Interface Emulation) ver 1.2
  [    1.874340] Bluetooth: HIDP socket layer initialized
  [    1.879351] lib80211: common routines for IEEE802.11 drivers
  [    1.885057] 9pnet: Installing 9P2000 support
  [    1.889385] Key type dns_resolver registered
  [    1.894658] registered taskstats version 1
  [    1.906271] cpu cpu0: registered imx8mq-cpufreq
  [    1.911151] imx6q-pcie 33800000.pcie: 33800000.pcie supply epdev_on not found, using dummy regular
  [    1.912062] hub 4-1:1.0: USB hub found
  [    1.924274] hub 4-1:1.0: 4 ports detected
  [    1.960537] OF: PCI: host bridge /pcie@0x33800000 ranges:
  [    1.965945] OF: PCI:   No bus range found for /pcie@0x33800000, using [bus 00-ff]
  [    1.967919] [drm] Cannot find any crtc or sizes
  [    1.973441] OF: PCI:    IO 0x1ff80000..0x1ff8ffff -> 0x00000000
  [    1.983894] OF: PCI:   MEM 0x18000000..0x1fefffff -> 0x18000000
  [    1.990592] imx6q-pcie 33800000.pcie: pcie phy pll is locked.
  [    2.240443] imx6q-pcie 33800000.pcie: phy link never came up
  [    2.246119] imx6q-pcie 33800000.pcie: failed to initialize host
  [    2.252042] imx6q-pcie 33800000.pcie: unable to add pcie port.
  [    2.258542] imx6q-pcie: probe of 33800000.pcie failed with error -110
  [    2.265426] imx6q-pcie 33c00000.pcie: 33c00000.pcie supply epdev_on not found, using dummy regular
  [    2.274751] OF: PCI: host bridge /pcie@0x33c00000 ranges:
  [    2.280162] OF: PCI:   No bus range found for /pcie@0x33c00000, using [bus 00-ff]
  [    2.287656] OF: PCI:    IO 0x27f80000..0x27f8ffff -> 0x00000000
  [    2.293587] OF: PCI:   MEM 0x20000000..0x27efffff -> 0x20000000
  [    2.300356] imx6q-pcie 33c00000.pcie: pcie phy pll is locked.
  [    2.319442] imx6q-pcie 33c00000.pcie: Link: Gen2 disabled
  [    2.324845] imx6q-pcie 33c00000.pcie: Link up, Gen1
  [    2.332017] imx6q-pcie 33c00000.pcie: PCI host bridge to bus 0000:00
  [    2.338409] pci_bus 0000:00: root bus resource [bus 00-ff]
  [    2.343936] pci_bus 0000:00: root bus resource [io  0x10000-0x1ffff] (bus address [0x0000-0xffff])
  [    2.352923] pci_bus 0000:00: root bus resource [mem 0x20000000-0x27efffff]
  [    2.373023] pci 0000:00:00.0: BAR 0: assigned [mem 0x20000000-0x200fffff 64bit]
  [    2.380390] pci 0000:00:00.0: BAR 14: assigned [mem 0x20100000-0x201fffff]
  [    2.387304] pci 0000:00:00.0: BAR 6: assigned [mem 0x20200000-0x2020ffff pref]
  [    2.394566] pci 0000:00:00.0: BAR 13: assigned [io  0x10000-0x10fff]
  [    2.400955] pci 0000:01:00.0: BAR 0: assigned [mem 0x20100000-0x2011ffff]
  [    2.407796] pci 0000:01:00.0: BAR 3: assigned [mem 0x20120000-0x20123fff]
  [    2.414627] pci 0000:01:00.0: BAR 2: assigned [io  0x10000-0x1001f]
  [    2.420950] pci 0000:00:00.0: PCI bridge to [bus 01-ff]
  [    2.426207] pci 0000:00:00.0:   bridge window [io  0x10000-0x10fff]
  [    2.432504] pci 0000:00:00.0:   bridge window [mem 0x20100000-0x201fffff]
  [    2.439969] pcieport 0000:00:00.0: Signaling PME with IRQ 268
  [    2.445929] pcieport 0000:00:00.0: AER enabled with IRQ 268
  [    2.451968] igb 0000:01:00.0: enabling device (0000 -> 0002)
  [    2.457676] Can't support > 32 bit dma.
  [    2.695382] pps pps1: new PPS source ptp1
  [    2.700410] igb 0000:01:00.0: added PHC on eth1
  [    2.704968] igb 0000:01:00.0: Intel(R) Gigabit Ethernet Network Connection
  [    2.711864] igb 0000:01:00.0: eth1: (PCIe:2.5Gb/s:Width x1) d0:63:b4:01:e3:15
  [    2.719017] igb 0000:01:00.0: eth1: PBA No: FFFFFF-0FF
  [    2.724172] igb 0000:01:00.0: Using MSI-X interrupts. 4 rx queue(s), 4 tx queue(s)
  [    2.733443] hantrodec: module inserted. Major = 243
  [    2.742360] rtc-abx80x 2-0069: Oscillator failure, data is invalid.
  [    2.748643] rtc-abx80x 2-0069: hctosys: unable to read the hardware clock
  [    2.756219] usb1_vbus: disabling
  [    2.759570] usbh1_vbus: disabling
  [    2.763203] SW1AB: disabling
  [    2.766373] VGEN1: disabling
  [    2.769528] VGEN6: disabling
  [    2.772682] ALSA device list:
  [    2.775651]   #0: wm8524-audio
  [    2.778716]   #1: imx-spdif
  [    2.781518]   #2: imx-hdmi-arc
  [    2.784580]   #3: imx-audio-hdmi
  [    2.819711] EXT4-fs (mmcblk1p2): recovery complete
  [    2.829184] EXT4-fs (mmcblk1p2): mounted filesystem with ordered data mode. Opts: (null)
  [    2.837313] VFS: Mounted root (ext4 filesystem) on device 179:98.
  [    2.847302] devtmpfs: mounted
  [    2.850570] Freeing unused kernel memory: 576K
  [    2.983748] systemd[1]: System time before build time, advancing clock.
  [    3.018590] NET: Registered protocol family 10
  [    3.024206] Segment Routing with IPv6
  [    3.040854] systemd[1]: systemd 243.2+ running in system mode. (+PAM -AUDIT -SELINUX +IMA -APPARM)
  [    3.062879] systemd[1]: Detected architecture arm64.

  Welcome to FSLC Wayland 3.0 (zeus)!

  [    3.091799] systemd[1]: Set hostname to <hummingboard-pulse>.
  [    3.103123] random: systemd: uninitialized urandom read (16 bytes read)
  [    3.109767] systemd[1]: Initializing machine ID from random generator.
  [    3.299299] systemd[1]: /lib/systemd/system/dbus.socket:5: ListenStream= references a path below .
  [    3.393586] random: systemd: uninitialized urandom read (16 bytes read)
  [    3.400361] systemd[1]: system-getty.slice: unit configures an IP firewall, but the local system .
  [    3.412748] systemd[1]: (This warning is only shown for the first unit using IP firewalling.)
  [    3.425855] systemd[1]: Created slice system-getty.slice.
  [  OK  ] Created slice system-getty.slice.
  [    3.443956] random: systemd: uninitialized urandom read (16 bytes read)
  [    3.451288] systemd[1]: Created slice system-serial\x2dgetty.slice.
  [  OK  ] Created slice system-serial\x2dgetty.slice.
  [    3.477886] systemd[1]: Created slice User and Session Slice.
  [  OK  ] Created slice User and Session Slice.
  [  OK  ] Started Dispatch Password …ts to Console Directory Watch.
  [  OK  ] Started Forward Password R…uests to Wall Directory Watch.
  [  OK  ] Reached target Paths.
  [  OK  ] Reached target Remote File Systems.
  [  OK  ] Reached target Slices.
  [  OK  ] Reached target Swap.
  [  OK  ] Listening on Syslog Socket.
  [  OK  ] Listening on initctl Compatibility Named Pipe.
  [  OK  ] Listening on Journal Audit Socket.
  [  OK  ] Listening on Journal Socket (/dev/log).
  [  OK  ] Listening on Journal Socket.
  [  OK  ] Listening on Network Service Netlink Socket.
  [  OK  ] Listening on udev Control Socket.
  [  OK  ] Listening on udev Kernel Socket.
           Mounting Huge Pages File System...
           Mounting POSIX Message Queue File System...
           Mounting Kernel Debug File System...
           Mounting Temporary Directory (/tmp)...
           Starting Journal Service...
           Mounting Kernel Configuration File System...
           Starting Remount Root and Kernel File Systems...
           Starting Apply Kernel Variables...
  [    3.903620] EXT4-fs (mmcblk1p2): re-mounted. Opts: (null)
           Starting udev Coldplug all Devices...
  [  OK  ] Started Journal Service.
  [  OK  ] Mounted Huge Pages File System.
  [  OK  ] Mounted POSIX Message Queue File System.
  [  OK  ] Mounted Kernel Debug File System.
  [  OK  ] Mounted Temporary Directory (/tmp).
  [  OK  ] Mounted Kernel Configuration File System.
  [  OK  ] Started Remount Root and Kernel File Systems.
  [  OK  ] Started Apply Kernel Variables.
           Starting Flush Journal to Persistent Storage...
           Starting Create[    4.111789] systemd-journald[1483]: Received client request to flush runt.
   System Users...
  [  OK  ] Started Flush Journal to Persistent Storage.
  [  OK  ] Started Create System Users.
           Starting Create Static Device Nodes in /dev...
  [  OK  ] Started Create Static Device Nodes in /dev.
  [  OK  ] Started udev Coldplug all Devices.
  [  OK  ] Reached target Local File Systems (Pre).
           Mounting /var/volatile...
           Starting udev Kernel Device Manager...
  [  OK  ] Mounted /var/volatile.
           Starting Load/Save Random Seed...
  [  OK  ] Reached target Local File Systems.
           Starting Rebuild Dynamic Linker Cache...
           Starting Create Volatile Files and Directories...
  [  OK  ] Started udev Kernel Device Manager.
           Starting Network Service...
  [  OK  ] Started Create Volatile Files and Directories.
           Starting Run pending postinsts...
           Starting Rebuild Journal Catalog...
           Starting Network Time Synchronization...
           Starting Update UTMP about System Boot/Shutdown...
  [  OK  ] Started Network Service.
  [  OK  ] Started Rebuild Dynamic Linker Cache.
  [  OK  ] Started Rebuild Journal Catalog.
  [  OK  ] Started Update UTMP about System Boot/Shutdown.
           Starting Network Name Resolution...
           Starting Update is Completed...
  [  OK  ] Started Network Time Synchronization.
  [  OK  ] Started Run pending postinsts.
  [  OK  ] Started Update is Completed.
  [    4.896872] Atheros 8031 ethernet 30be0000.ethernet-1:04: attached PHY driver [Atheros 8031 ether)
  [    4.925921] IPv6: ADDRCONF(NETDEV_UP): eth0: link is not ready
  [    4.945269] igb 0000:01:00.0 enp1s0: renamed from eth1
  [  OK  ] Reached target Sound Card.
  [  OK  ] Reached target System Initialization.
  [  OK  ] Started Daily Cleanup of Temporary Directories.
  [    5.051753] IPv6: ADDRCONF(NETDEV_UP): enp1s0: link is not ready
  [  OK  ] Reached target System Time Set.
  [  OK  ] Reached target System Time Synchronized.
  [  OK  ] Reached target Timers.
  [  OK  ] Listening on D-Bus System Message Bus Socket.
  [  OK  ] Reached target Sockets.
  [  OK  ] Reached target Basic System.
  [  OK  ] Listening on Load/Save RF …itch Status /dev/rfkill Watch.
  [  OK  ] Started Kernel Logging Service.
  [  OK  ] Started System Logging Service.
  [  OK  ] Started D-Bus System Message Bus.
           Starting Login Service...
  [  OK  ] Started Network Name Resolution.
  [  OK  ] Reached target Network.
  [  OK  ] Reached target Host and Network Name Lookups.
           Starting Permit User Sessions...
  [  OK  ] Started Permit User Sessions.
  [  OK  ] Started Getty on tty1.
  [  OK  ] Started Serial Getty on ttymxc0.
  [  OK  ] Reached target Login Prompts.
  [  OK  ] Started Login Service.
  [  OK  ] Reached target Multi-User System.
           Starting Update UTMP about System Runlevel Changes...
  [  OK  ] Started Update UTMP about System Runlevel Changes.

  FSLC Wayland 3.0 hummingboard-pulse ttymxc0

  hummingboard-pulse login: root
  [   40.429032] audit: type=1006 audit(1583407507.443:2): pid=2364 uid=0 old-auid=4294967295 auid=0 t1
  root@hummingboard-pulse:~# uname -a
  Linux hummingboard-pulse 4.14.166-solidrun+ga33b5bfc5cc1 #1 SMP PREEMPT Thu Mar 5 11:51:27 UTC 2020 x
  ```

## Summary

From now on, you will be able to build and run many other images from Yocto
Project, not only at HummingBoard but many others. If you are interested in
this subject follow our social media for more information!

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

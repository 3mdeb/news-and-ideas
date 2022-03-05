---
title: Introduction of Yocto meta layer for Nezha D1
abstract: 'Presentation of current progress status with the support of the
Nezha board in Yocto Project'
cover: /img/nezha-logo.png
author: cezary.sobczak
layout: post
published: true
date: 2022-03-07
archives: "2022"

tags:
  - risc-v
  - sbc
  - linux
  - u-boot
  - boot0
  - opensbi
  - bootloader
  - logs
  - SoC
  - sdcard
  - yocto
  - layer
  - meta
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

## Introduction

As it was mentioned in first [post](https://blog.3mdeb.com/2021/2021-11-19-nezha-riscv-sbc-first-impression/)
We are interested in support for this board in Yocto Project, and this post will
show you what we have achieved in this field.

Previous blog post made a lot of noise and was appreciated by people from RISC-V
International. Now it is also available on their [site](https://riscv.org/news/2022/01/first-impression-on-nezha-risc-v-sbc-3mdeb/).

Whole code of the meta layer you can find at [github](https://github.com/Cezarus27/meta-nezha).
It should be mentioned that `meta-nezha` is really early support so
the recipe's code isn't that clear and for now, it isn't prepared to be
upstreamed.

## Nezha D1 meta layer

### What is a Yocto meta layer?

First of all, it is important to say what exactly the Yocto Project and it's
meta layers are. Yocto is a project which is hosted by the Linux Foundation
and gives you templates, methods, and set of interoperable tools for creating OS
images for embedded Linux systems. Secondly, the Yocto project is used by many
mainstream embedded Linux providers and offers thousands of packages that are
available through layers. What are they?

Yocto project can be used by itself or be extended by meta layers, which are
repositories with instructions (recipes) telling the build system what it should
do. By separating the instructions into layers, we can reuse them and share for
other users. Thirdly, with Yocto Project you can bring to life exactly the Linux
you want and need. The project lets you choose your CPU architecture, select
footprint size, and remove and/or add components to get the features you want.

### Construction of meta-nezha

Nezha D1 layer is using the following Yocto Project meta layers in `hardknott`
version:

* [poky](https://git.yoctoproject.org/git/poky)

* [meta-openembedded](https://git.openembedded.org/meta-openembedded)

* [meta-riscv](https://github.com/riscv/meta-riscv.git)

The structure of a `meta-nezha` is divided into two main parts:

![nezha layers structure](/img/meta-nezha-structure.png)

* `meta-nezha-bsp` - this layer contains recipes for `boot0`, `u-boot`,
  `OpenSBI` and `linux kernel`. It also contains machine configuration which
  set/unset or enable/disable the key features of the board,

* `meta-nezha-distro` - contain a recipe for the minimal image, configuration of the
  system eg. what init manager is used and `wks` file which is used to create
  image file which can be flashed to the SD card.

This layer was splitted because it is nice to separate the **Board Support
Package (BSP)** from application layer. BSP layer is a collection of information
that defines how to support a particular hardware device, set of devices, or
hardware platform.

Key repositories used by `meta-nezha-bsp` recipes are forks of repositories
patched / created by **[smaeul](https://github.com/smaeul)**:

* [OpenSBI](https://github.com/Cezarus27/opensbi/tree/d1-wip): `d1-wip` branch

* [u-boot](https://github.com/Cezarus27/u-boot/tree/d1-wip): `d1-wip` branch

* [Linux](https://github.com/Cezarus27/linux/tree/riscv/d1-wip): `riscv/d1-wip`
  branch

* [boot0](https://github.com/Cezarus27/sun20i_d1_spl): `mainline` branch

> Note: It was decided to fork the `smaeul` repositories because the original
> repos are often updated and rebased to the newest branches from upstream
> repositories and it often caused problems with the proper build of the yocto
> image.

Main work to do was to adopt the bootflow of Nezha to the Yocto Project which
was described in [previous](https://blog.3mdeb.com/2021/2021-11-19-nezha-riscv-sbc-first-impression/)
blog post. In this process, the `boot0` recipe was created from the ground.
That wasn't so smooth to integrate its compilation flow with the Yocto build
engine due to missing some headers in `workdir`. So the patch for `boot0`
Makefile was provided also and it is applied during the building process.

It wasn't enough because a lot of work had to be done to compile `U-Boot` for
the D1 chip. `u-boot-nezha` recipe contains procedures of creating the TOC1
image from binaries described in `toc.cfg`. This configuration file contains
information about which files are included in TOC1 image and address of a memory
where they should be loaded. Creating the TOC image is different than others
because this image contains three binaries which one is from `OpenSBI`. So it
was necessary to add a dependency for `U-Boot` on `OpenSBI` during the
compilation task. The `tftp-mmc-boot.txt` script which is used by `U-Boot`
during boot to set up environment variables was also modified to provide
`bootargs` specific for the Nezha.

The situation with Linux kernel recipe isn't different. Due to the "work in
progress" status of the support for D1 chip in Linux kernel, We decided to
create a separate recipe of the kernel for the Nezha board. It provides to the
building system two configuration files with kernel options that enable
`autofs4` and `cgroups`. Enabling these options was necessary because, without
them, kernel can not be booted which is signaled with the following error:

```log
[    3.293088] systemd[1]: System time before build time, advancing clock.
[    3.324933] systemd[1]: Failed to look up module alias 'autofs4': Function not implemented
[    3.336302] systemd[1]: Failed to mount tmpfs at /sys/fs/cgroup: No such file or directory
[    3.346366] systemd[1]: Failed to mount cgroup at /sys/fs/cgroup/systemd: No such file or directory
[!!!!!!] Failed to mount API filesystems.
```

## System structure

Below image shows the SD card structure after flashing the image:

![nezha sd card structure](/img/nezha-sd-structure.png)

As you can see the `boot0` SPL and `u-boot.toc1` image are in an area of raw
disk space which means it isn't a partition. After boot, the program is loaded
from ROM and this program reads SC card to find the `boot0` first, and then the
`boot0` load the `u-boot.toc1` which start the `u-boot` etc.

In `meta-nezha` you can find a formal description of the structure in
**[nezha.wks](https://github.com/Cezarus27/meta-nezha/blob/master/meta-nezha-distro/wic/nezha.wks)**
file.

> Note: More information about it you can find [here](https://linux-sunxi.org/Allwinner_Nezha).

## Nezha Yocto system startup

[![asciicast](https://asciinema.org/a/450212.svg)](https://asciinema.org/a/450212)

So it really works!

## Known issues

### rng-tools

This package contains many tools. One of them is *Random Numbers Generator
daemon* - `rngd`. This daemon feeds data from a random number generator to the
kernel's random number entropy pool, after first checking the data to ensure
that it is properly random.

For some reason it crushes during start with `SIGSEGV` in `libc-2.33.so`:
```log
[   10.792295] rngd[139]: unhandled signal 11 code 0x2 at 0x0000003fc72e1378 in libc-2.33.so[3fc727e000+fd000]
[   10.948096] CPU: 0 PID: 139 Comm: rngd Not tainted 5.14.0-rc4-nezha #1
```

This problem doesn't exist when the `haveged` random number generator is used in
the build.

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of a used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

---
title: Building coreboot for RISC-V and running it in Qemu
abstract: 'In this article, I will briefly explain what is RISC-V and why it is
so exciting, then I`ll show you step by step how to build coreboot for this
architecture and run it in QEMU emulator'
cover: /covers/coreboot-logo.svg
author: wojciech.niewiadomski
layout: post
published: true
date: 2020-09-28
archives: "2020"

tags:
  - Firmware
  - coreboot
  - RISC-V
categories:
  - Firmware
  - Miscellaneous

---


# Building coreboot for RISC-V and running it in Qemu

#### 1. What is RISC-V?

RISC-V is relatively fresh and growing in popularity open standard ISA based on
RISC principles. The fact that ISA is free to use and everyone can see every
processors move makes it easier to work on security bugs such as Meltdown and
Spectre which are huge flaws of other architectures. The other reason it is
getting so successful is while x86 or ARM require a license to be used, RISC-V
can be implemented by anyone for free and companies can modify it to fit their
needs, which makes them independent from the main providers and may lead to
increase of competitiveness in the aspect of innovation.  
While getting more and more attention, RISC-V is also getting more support. It
is supported architecture for coreboot. In the next steps, I will explain how to
build coreboot for RISC-V and run it in Qemu emulator.


#### 2. Build Docker image

Docker container is a recommended choice to build coreboot as it has already
built cross toolchains. You can set up environment with these commands:

```sh
docker pull coreboot/coreboot-sdk:65718760fa
docker run -u root --rm -it -v $PWD:/home/coreboot/coreboot -w /home/coreboot/coreboot coreboot/coreboot-sdk:65718760fa /bin/bash
```

#### 3. Download coreboot source tree

```sh
git clone https://review.coreboot.org/coreboot
cd coreboot
git checkout 9cc2a6a0c316f9cbf39af6c04fd65512b8e17b11
```

#### 4. Configure the build

Configure your mainboard in coreboot directory
```sh
make menuconfig
```

Inside `menuconfig` follow these steps:
```
   select 'Mainboard' menu
   select '(Emulation)' in 'Mainboard vendor'
   select 'QEMU RISC-V rv64' in 'Mainboard model'
   select `10240 KB (10 MB)` in ROM chip size
   select < Exit >
   (optionally) select your Payload in `Payload` menu
                select < Exit >
   select < Exit >
   select < Yes >
```

> NOTE: Unfortunately using demonstration payloads such as `coreinfo` or `tint`
is not possible as they use `libpayload` library which does not support RISC-V
architecture yet. However, there is a [WIP
branch](https://review.coreboot.org/c/coreboot/+/31356) working on adding
initial support for RISC-V you can check out. You can also try compiling linux
kernel and use it as a payload.

(Optionally) You can check your configuration by these commands:
```sh
make savedefconfig
cat defconfig
```

The output should look like this:
```
CONFIG_BOARD_EMULATION_QEMU_RISCV_RV64=y
```

#### 5. Build coreboot

```sh
make
```

At the end of the process, you can see the following output:
```
FMAP REGION: COREBOOT
Name                           Offset     Type           Size   Comp
cbfs master header             0x0        cbfs header        32 none
fallback/romstage              0x80       stage           14131 none
fallback/ramstage              0x3800     stage           23269 none
config                         0x9340     raw               107 none
revision                       0x9400     raw               681 none
(empty)                        0x9700     null          4023960 none
header pointer                 0x3dfdc0   cbfs header         4 none
    HOSTCC     cbfstool/rmodtool.o
    HOSTCC     cbfstool/rmodtool (link)
    HOSTCC     cbfstool/ifwitool.o
    HOSTCC     cbfstool/ifwitool (link)

Built emulation/qemu-riscv (QEMU RISCV)
```

#### 6. Test image in QEMU

If you do not have Qemu installed you cant do it via this command
```sh
apt-get install qemu-system
```

Now you can run your image in Qemu
```sh
qemu-system-riscv64 -M virt -m 1024M -nographic -kernel build/coreboot.elf
```

You should see coreboot booting with your payload if you chose one,
otherwise you should see booting coreboot alone with ending info `Paylod not
loaded`.

## Summary

It is definitely worth focusing our attention on this architecture, as the
innovative business model behind it may lead us to RISC-V being standard ISA for
all computer devices and might be the only way to provide safe and secure
future.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

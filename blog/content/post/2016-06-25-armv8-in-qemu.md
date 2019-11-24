---
layout: post
title: "ARMv8 in QEMU"
date: 2016-06-25 13:54:56 +0200
comments: true
categories: arm armv8 qemu embedded
---

Since makers community start to be flooded with ARMv8 development boards it is
highly probable that next years we will start to see lot of products based on
new ARM architecture. There are many interesting thing to learn for Embedded
Systems Consultants in this not-so-new architecture. There is open source [ARM Trusted Firmware](https://github.com/ARM-software/arm-trusted-firmware) and
UEFI specification already contain support for ARMv8.

Goal of this post is to setup ARMv8 emulated environment for further learning
and development purpose.

QEMU
----

After code comparison for Linaro and upstream version of QEMU I decide that
upstream contain much more commits related to ARMv8.

```
git clone git://git.qemu.org/qemu.git
```

### Python requirement

If you faced message like this:

```
ERROR: Cannot use 'python', Python 2.6 or later is required.
       Note that Python 3 or later is not yet supported.
       Use --python=/path/to/python to specify a supported Python.
```

you can use `virtualenv` to avoid problem:

```
virtualenv -p /usr/bin/python2.7 ~/local/py2.7-venv
source ~/local/py2.7-venv/bin/activate
```

### Initialize submodules

```
git submodule update --init pixman
git submodule update --init dtc
```

### Configure and build

Below command five us only required AArch64 (ARMv8 or ARM 64 bit) emulators.

```
./configure --target-list=aarch64-softmmu
make -j$(nproc)
```

AARCH64 for QEMU
----------------

```
git clone git@github.com:tianocore/edk2.git
make -C BaseTools
```

### ArmVirtQemu vs ArmVirtQemuKernel

There is only one difference between QEMU platforms in edk2 - different place
of code execution. First take `-bios`, which imply 0x0 (ARM reset vector) as
starting point and second `-kernel` through Linux kernel boot protocol.

### Getting toolchain

Easiest method is to download from [Linaro site](https://releases.linaro.org/components/toolchain/binaries/). Below
instructions use `gcc-linaro-5.3-2016.02-x86_64_aarch64-linux-gnu`.

### Building

```
source edksetup.sh
export GCC5_AARCH64_PREFIX=${PWD}/../toolchain/gcc-linaro-5.3-2016.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
build -a AARCH64 -t GCC5 -b DEBUG -p ArmVirtPkg/ArmVirtQemu.dsc
```

### Running

```
../qemu/aarch64-softmmu/qemu-system-aarch64 -m 1024 \
-cpu cortex-a57 -M virt \
-bios Build/ArmVirtQemu-AARCH64/DEBUG_GCC5/FV/QEMU_EFI.fd \
-serial stdio
```

---
layout: post
title: "Build and run OVMF under Qemu"
date: 2013-06-14 23:22
comments: true
categories: 
published: false
keywords: qemu ovmf edk2
description:
---

### What the OVMF is ?
__OVMF__ (_Open Virtual Machine Firmware_) is a firmware actively developed as a 
__EDK2__(_EFI Developer Kit_) package. It is a packed that aims to support 
firmware for virtual machines like Qemu. 

### Simplified build process

First of all lets get latest version of the code. For some time [EFI and 
Framework Open Source Community](http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=Welcome) share edk2 code also on [github](https://github.com/tianocore/edk2) mirror.

```
git clone https://github.com/tianocore/edk2.git
```

Building process was simplified by OvmfPkg contributors. But I found that 
toolchain for latest gcc compilers is not ready in main repository. So I suggest 
to remove `BaseTools` directory and clone up to date git repository in this 
place:

```
cd edk2
rm -rf BaseTools
git clone https://github.com/tianocore/buildtools-BaseTools.git BaseTools
. edksetup.sh
```

So to build firmware we need only one command:

```

```
You may need some additional packages like `uuid-dev`, `iasl` or `g++`.

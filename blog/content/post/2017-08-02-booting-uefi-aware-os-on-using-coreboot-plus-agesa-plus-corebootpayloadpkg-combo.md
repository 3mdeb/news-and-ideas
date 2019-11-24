---
author: Piotr Król
layout: post
title: "Booting UEFI-aware OS using coreboot+AGESA+CorebootPayloadPkg combo"
date: 2017-08-02 14:15:02 +0200
comments: true
categories: agesa coreboot uefi edk2 debian
---

After publishing [blog post about enabling UEFI Shell on apu2]() I decided to
take next step and try to install UEFI-aware operating system like recent
Debian 9.

Enabling UEFI Shell left firmware in state in which most commands work
correctly, but no device except serial was detected. Obviously it would be
great to have some storage or at least diskless installation that we can boot
on apu2. Speaking about diskless network interfaces were also not visible.

Because all important devices are connected on PCIe bus I decided to figure out
why I can't see anything. Quick check revealed that root bright is not
detected.

## Enabling PCI on apu2

I started with investigation of memory ranges disabled during work on UEFI
Shell booting. Call to reserve LAPIC memory range hardcoded to `0xfee00000`
caused assert what was the reason for disabling this code initially.

## coreboot bisection with coreboot-sdk

After getting information that mainline coreboot may contain extended support
for UEFI payload I decided to try recent code. Unfortunately it happen to not
boot on apu2. I knew that recent release on `coreboot-4.6.x` boot fine, so I
wanted to try coreboot version where we forked. It was tag `4.6` SHA:
`db508565d248`.

After checking out I wanted to utilize `coreboot-sdk` to build toolchain for
that commit. Unfortunately hit complains about lack of `gnat1` ADA compiler.

```
Welcome to the coreboot cross toolchain builder v1.44 (March 3rd, 2017)

Building toolchain using 4 thread(s).

Target architecture is now i386-elf

warning: Building GCC 6.3 with a different major version (7.2).
         Bootstrapping (-b) is recommended.

ERROR: Missing tool: Please install 'gnat'. (eg using your OS packaging system)
Makefile:26: recipe for target 'build_gcc' failed
make[2]: Leaving directory '/root/coreboot/util/crossgcc'
make[2]: *** [build_gcc] Error 1
Makefile:48: recipe for target 'build-i386' failed
make[1]: Leaving directory '/root/coreboot/util/crossgcc'
make[1]: *** [build-i386] Error 2
make: *** [all_without_gdb] Error 2
Makefile:16: recipe for target 'all_without_gdb' failed
The command '/bin/sh -c cd /root &&     git clone http://review.coreboot.org/coreboot &&        cd coreboot/util/crossgcc &&    git checkout db508565d248 &&    make all_without_gdb            BUILD_LANGUAGES=c,ada CPUS=$(nproc) DEST=/opt/
xgcc &&         cd /root &&     rm -rf coreboot' returned a non-zero code: 2
Makefile:49: recipe for target 'coreboot-sdk' failed
make: *** [coreboot-sdk] Error 2
```

First thing that I realized is that `coreboot-sdk` use Debian `sid` which is
moving target and probably not good for building toolchain. It happen that
default compiler was GCC 7 without ADA support installed (Dockerfile installed
`gant-6` package).

Interestingly this is not a problem on recent `master` branch (SHA: `e9b862eb2c59`).

Unfortunately despite fixing that error I faced other issues and then decided
to use recent `coreboot-sdk` (at that point 1.47) for compilation of 4.6 stable
tag. Further problems appeared with that approach:

```
/home/coreboot/coreboot/util/cbfstool/lz4/lib/lz4frame.c: In function 'LZ4F_decompress':
/home/coreboot/coreboot/util/cbfstool/lz4/lib/lz4frame.c:1092:33: error: this statement may fall through [-Werror=implicit-fallthrough=]
                 dctxPtr->dStage = dstage_storeHeader;                                                   
                 ~~~~~~~~~~~~~~~~^~~~~~~~~~~~~~~~~~~~
/home/coreboot/coreboot/util/cbfstool/lz4/lib/lz4frame.c:1095:9: note: here
         case dstage_storeHeader:       
         ^~~~                         
cc1: all warnings being treated as errors     
util/cbfstool/Makefile.inc:133: recipe for target 'build/util/cbfstool/lz4frame.o' failed
make: *** [build/util/cbfstool/lz4frame.o] Error 1
make: *** Waiting for unfinished jobs.... 
```

Patch for that exist [here](https://groups.google.com/a/chromium.org/d/msg/chromium-os-checkins/0Ilkoak5A0M/068xefpOCAAJ)
and was applied in coreboot master branch. After applying that patch I was able
to bisect my issue. Recent apu2 code missed innovation introduced by Kyösti
Mälkki, which was related with Cache-as-RAM and AGESA cleanup. Unfortunately I
was not able to understand what is really missing and how I should introduce
support of this new code. Problem was fixed easily with [this patch](https://review.coreboot.org/#/c/21840/2/src/cpu/amd/pi/Makefile.inc) right after being reported.


## DuetPkg PCI no enumeration code

After above I learned lesson that I should use recent `coreboot-sdk` whenever I
have to. It also happen that applying one of coreboot's tianocore patches lead
to correct PCI enumeration, what I announced [here](https://twitter.com/3mdeb_com/status/915105643933175808):

On screenshot you can see USB detected and part of SMBIOS table proving this is
PC Engines platform.

Key question was: what is the difference between PCI enumeration from
`MdeModulePkg` and `DuetPkg` ?

Exact name of `DuetPkg` drivers used were `PciRootBridgeNoEnumeration` and
`PciBusNoEnumeration`.

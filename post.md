---
post_title: Booting UEFI-aware OS using coreboot+AGESA+CorebootPayloadPkg combo
author: Piotr Król
layout: post
published: true
post_date: 2017-11-06 14:31:00
tags:
  - UEFI
  - coreboot
  - debian
  - linux
  - AGESA
  - edk2
  - apu2
  - pc-engines
categories:
  - Firmware
  - Security

---
author: Piotr Król
layout: post
title: "Booting UEFI-aware OS using coreboot+AGESA+CorebootPayloadPkg combo"
date: 2017-08-02 14:15:02 +0200
comments: true
categories: agesa coreboot uefi edk2 debian
---

After publishing [blog post about enabling UEFI Shell on apu2](https://3mdeb.com/firmware/uefiedk-ii-corebootpayloadpkg-on-pc-engines-apu2/) I decided to
take next step and try to install UEFI-aware operating system like recent
Debian 9 and try couple interesting tools like CHIPSEC.

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
boot on apu2. I knew that recent release on `coreboot-4.6.x` on PC Engines for
boot fine, so I wanted to try coreboot version where we forked. It was tag
`4.6` SHA: `db508565d248`.

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

The answer to above question was use of MMIO vs IO access to PCI config space.
I figured this out by playing with `PCIE_BASE` address, which when set to `0`
cause use of different `PciLib`.

```
!if $(PCIE_BASE) == 0
  PciLib|MdePkg/Library/BasePciLibCf8/BasePciLibCf8.inf
  PciCf8Lib|MdePkg/Library/BasePciCf8Lib/BasePciCf8Lib.inf
!else
  PciLib|MdePkg/Library/BasePciLibPciExpress/BasePciLibPciExpress.inf
  PciExpressLib|MdePkg/Library/BasePciExpressLib/BasePciExpressLib.inf
!endif
```

Apparently `BasePciLibPciExpress` have some problems with correctly finding PCI
root bridge.

### Trying different PCIE_BASE

I tried to play with some values in mentioned variable, which is passed into
code through `gEfiMdePkgTokenSpaceGuid.PcdPciExpressBaseAddress`. I found in
coreboot log information about PCIe BAR:

```
...
BS: BS_DEV_ENUMERATE times (us): entry 0 run 133877 exit 0
Allocating resources...
Reading resources...
fx_devs = 0x1
Adding PCIe enhanced config space BAR 0xf8000000-0xfc000000.
Done reading resources.
Setting resources...
...
```

Based on above I set `0xF8000000` as `PCIE_BASE`, what triggered DXE assert:

```
InitRootBridge: populated root bus 255, with room for 0 subordinate bus(es)
ScanForRootBridges:587 RootBridges: -813834216
RootBridge: PciRoot(0x0)
  Support/Attr: 10063 / 10063
    DmaAbove4G: No
NoExtConfSpace: No
     AllocAttr: 0 ()
           Bus: 0 - 3
            Io: 1000 - 4FFF
           Mem: F7A00000 - F7FFFFFF
    MemAbove4G: FFFFFFFFFFFFFFFF - 0
          PMem: FFFFFFFFFFFFFFFF - 0
   PMemAbove4G: FFFFFFFFFFFFFFFF - 0
Split - 0xCF7E5000
RootBridge: PciRoot(0x6B)
  Support/Attr: 0 / 0
    DmaAbove4G: No
NoExtConfSpace: No
     AllocAttr: 0 ()
           Bus: 6B - 6B
            Io: FFFFFFFFFFFFFFFF - FFFFFFFFFFFFFFFF
           Mem: FFFFFFFFFFFFFFFF - FFFFFFFFFFFFFFFF
    MemAbove4G: FFFFFFFFFFFFFFFF - 0
          PMem: FFFFFFFFFFFFFFFF - 0
   PMemAbove4G: FFFFFFFFFFFFFFFF - 0

DXE_ASSERT!: .../Pci/PciHostBridgeDxe/PciRootBridgeIo.c (100): Bridge->Mem.Limit < 0x0000000100000000ULL
```

This assert looks like some kind of overflow. Unfortunately we didn't have time
to figure out why this is triggered.

## Booting UEFI-aware OS and UEFI Shell

Luckily setting `PCIE_BASE` to `0` works with `MdeModulePkg` and truly no
additional patches were required. Having that configuration I booted Debian 9
installer from USB and installed system to mSATA disk.

```
root@debian:~# efibootmgr -v
BootCurrent: 0002
Timeout: 3 seconds
BootOrder: 0000,0001,0002
Boot0000* UiApp MemoryMapped(11,0x830000,0xc0ffff)/FvFile(462caa21-7614-4503-836e-8ab6f4662331)
Boot0001* UEFI SanDisk SSD i110 16GB 150901101579       PciRoot(0x0)/Pci(0x11,0x0)/Ata(0,0,0)N.....YM....R,Y.
Boot0002* UEFI Shell    MemoryMapped(11,0x830000,0xc0ffff)/FvFile(7c04a583-9e3e-4f1c-ad65-e05268d0b4d1)

root@debian:~# uname -a
Linux debian 4.9.0-4-amd64 #1 SMP Debian 4.9.51-1 (2017-09-28) x86_64 GNU/Linux
```

## Trying CHIPSEC - UEFI-aware OS

After playing little bit with solving dependencies I managed to run CHIPSEC
`1.3.5`.

Of course at this point PC Engines platform was not supported, so we had to
force execution with `-i`. Despite that result was interesting:

```
################################################################
##                                                            ##
##  CHIPSEC: Platform Hardware Security Assessment Framework  ##
##                                                            ##
################################################################
[CHIPSEC] Version 1.3.5
[CHIPSEC] Arguments: -i
[*] Ignoring unsupported platform warning and continue execution
****** Chipsec Linux Kernel module is licensed under GPL 2.0
[CHIPSEC] API mode: using CHIPSEC kernel module API
ERROR: Unsupported Platform: VID = 0x1022, DID = 0x1566
ERROR: Platform is not supported (Unsupported Platform: VID = 0x1022, DID = 0x1566).
WARNING: Platform dependent functionality is likely to be incorrect
[CHIPSEC] OS      : Linux 4.9.0-4-amd64 #1 SMP Debian 4.9.51-1 (2017-09-28) x86_64
[CHIPSEC] Platform: UnknownPlatform
[CHIPSEC]      VID: 1022
[CHIPSEC]      DID: 1566

[*] loading common modules from ".-venv/local/lib/python2.7/site-packages/chipsec-1.3.5-py2.7-linux-x86_64.egg/chipsec/modules/common" ..
[+] loaded chipsec.modules.common.bios_smi
[+] loaded chipsec.modules.common.ia32cfg
[+] loaded chipsec.modules.common.bios_kbrd_buffer
[+] loaded chipsec.modules.common.bios_wp
[+] loaded chipsec.modules.common.spi_access
[+] loaded chipsec.modules.common.rtclock
[+] loaded chipsec.modules.common.spi_desc
[+] loaded chipsec.modules.common.spi_lock
[+] loaded chipsec.modules.common.bios_ts
[+] loaded chipsec.modules.common.spi_fdopss
[+] loaded chipsec.modules.common.smrr
[+] loaded chipsec.modules.common.smm
[+] loaded chipsec.modules.common.uefi.s3bootscript
[+] loaded chipsec.modules.common.uefi.access_uefispec
[+] loaded chipsec.modules.common.secureboot.variables
[*] No platform specific modules to load
[*] loading modules from ".-venv/local/lib/python2.7/site-packages/chipsec-1.3.5-py2.7-linux-x86_64.egg/chipsec/modules" ..
[+] loaded chipsec.modules.memconfig
[+] loaded chipsec.modules.smm_dma
[+] loaded chipsec.modules.remap
[*] running loaded modules ..

[*] running module: chipsec.modules.common.bios_smi
[x][ =======================================================================
[x][ Module: SMI Events Configuration
[x][ =======================================================================
[+] SMM BIOS region write protection is enabled (SMM_BWP is used)

[*] Checking SMI enables..
    Global SMI enable: 1
    TCO SMI enable   : 1
[+] All required SMI events are enabled

[*] Checking SMI configuration locks..
[+] TCO SMI configuration is locked (TCO SMI Lock)
[+] SMI events global configuration is locked (SMI Lock)

[+] PASSED: All required SMI sources seem to be enabled and locked

[*] running module: chipsec.modules.common.ia32cfg
[x][ =======================================================================
[x][ Module: IA32 Feature Control Lock
[x][ =======================================================================
[*] Verifying IA32_Feature_Control MSR is locked on all logical CPUs..
Segmentation fault
```

At leas SMI configuration seems to be correct. When CHIPSEC started to play
with MSRs it hit segfault. Kernel also complain:

```
[  954.540265] Chipsec module loaded
[  954.543920] ** This module exposes hardware & memory access, **
[  954.550032] ** which can effect the secure operation of      **
[  954.556283] ** production systems!! Use for research only!   **
[  968.613544] Chipsec module loaded
[  968.617096] ** This module exposes hardware & memory access, **
[  968.623315] ** which can effect the secure operation of      **
[  968.629548] ** production systems!! Use for research only!   **
[  968.865050] general protection fault: 0000 [#1] SMP
[  968.870145] Modules linked in: chipsec(O) fuse btrfs xor raid6_pq ufs qnx4 hfsplus hfs minix ntfs msdos jfs xfs libcrc32c dm_mod nls_ascii nls_cp437 vfat fat evdev amd64_edac_mod edac_mce_amd edac_core kvm_amd kvm irqbypass crct10dif_]
[  968.938339] CPU: 0 PID: 9096 Comm: chipsec_main Tainted: G           O    4.9.0-4-amd64 #1 Debian 4.9.51-1
[  968.948523] Hardware name: PC Engines apu2/apu2, BIOS 4.6-2004-gc12d7541d0 11/05/2017
[  968.956680] task: ffff9f6da79080c0 task.stack: ffffae4687f88000
[  968.962942] RIP: 0010:[<ffffffffc065ae5b>]  [<ffffffffc065ae5b>] _rdmsr+0xf/0x1e [chipsec]
[  968.971700] RSP: 0018:ffffae4687f8bd28  EFLAGS: 00010246
[  968.977244] RAX: ffffae4687f8bdd0 RBX: 00007ffe58d76bd0 RCX: 000000000000003a
[  968.984742] RDX: ffffae4687f8bde0 RSI: ffffae4687f8bde8 RDI: 000000000000003a
[  968.992148] RBP: ffffae4687f8be90 R08: 00007f491fd40bdc R09: 0000000000000000
[  968.999608] R10: ffffae4687f8bde8 R11: ffffae4687f8bde0 R12: 00007ffe58d76bd0
[  969.007180] R13: ffff9f6da51058d8 R14: 00007ffe58d76bd0 R15: 00007f49211c2d28
[  969.014627] FS:  00007f492333f700(0000) GS:ffff9f6daec00000(0000) knlGS:0000000000000000
[  969.023091] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[  969.029055] CR2: 00007f4920355ae0 CR3: 00000001279aa000 CR4: 00000000000406f0
[  969.036436] Stack:
[  969.038556]  ffffae4687f8bde0 ffffae4687f8bdd0 ffff9f6da79080c0 000000000000003a
[  969.046351]  ffffffffc065a2aa 0000000000000000 ffff9f6daec18240 ffff9f6da79080c0
[  969.054239]  ffff9f6da5682800 0000000000000000 0000000000000001 000000e194d76928
[  969.062146] Call Trace:
[  969.064803]  [<ffffffffc065a2aa>] ? d_ioctl+0xa1a/0x1480 [chipsec]
[  969.071245]  [<ffffffffa49b3e55>] ? handle_mm_fault+0x8a5/0x12d0
[  969.077443]  [<ffffffffa4a16f1f>] ? do_vfs_ioctl+0x9f/0x600
[  969.083289]  [<ffffffffa4a174f4>] ? SyS_ioctl+0x74/0x80
[  969.088707]  [<ffffffffa4e085bb>] ? system_call_fast_compare_end+0xc/0x9b
[  969.095747] Code: 0f 01 0f c3 0f 01 1f c3 0f 01 07 c3 0f 01 17 c3 0f 00 07 c3 c3 0f 01 07 0f 01 17 c3 41 52 41 53 50 52 48 89 f9 49 89 f2 49 89 d3 <0f> 32 41 89 02 41 89 13 5a 58 41 5b 41 5a c3 50 51 48 89 f9 48
[  969.117154] RIP  [<ffffffffc065ae5b>] _rdmsr+0xf/0x1e [chipsec]
[  969.123307]  RSP <ffffae4687f8bd28>
[  969.127075] ---[ end trace a2150a12883cbcb3 ]---
```

I assume for now this is expected behavior.

## Trying CHIPSEC - UEFI Shell

Unfortunately CHIPSEC won't work from UEFI Shell for now and it seems to be
problem with Python application file. Issue were reported in [GitHub](https://github.com/chipsec/chipsec/issues/300#issuecomment-342021274)

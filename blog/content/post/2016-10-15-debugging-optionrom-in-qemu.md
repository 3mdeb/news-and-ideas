---
layout: post
title: "Debugging OptionROM in QEMU"
date: 2016-10-15 01:24:12 +0200
comments: true
categories: BIOS OpROM x86 QEMU coreboot
---

Below I describe my experience with debugging custom ROM using using QEMU and
coreboot. There are many reason why this maybe needed.

This post was inspired by work made by [Darmawan Salihun](http://bioshacking.blogspot.com/2011/10/pci-option-rom-debugging-with-seabios.html).

I used QEMU from Debian sid repository and coreboot compiled from scratch for QEMU (``).

To add ROM binary to image:

```
./build/cbfstool build/coreboot.rom add -f test.rom -n genroms/test.rom -t raw
```


Is this approach really needed ? It looks like without problems I should be
able to inject OpROM directly to QEMU, but uysing bewlo command doesn't load
anything:

```
../qemu/x86_64-softmmu/qemu-system-x86_64 -option-rom test.rom -hda system.img \
-monitor telnet:127.0.0.1:4321,server,nowait -chardev stdio,id=serial \
-device isa-debugcon,iobase=0x3f8,chardev=serial -m 512 -device
e1000,netdev=net0,mac=FE:ED:BE:EF:42:42 -netdev user,id=net0 -d guest_errors
```

* Interesting thing are on [plpbtrom website](https://www.plop.at/en/bootmanager/rom.html) - it work fine with qemu

* What does `BIOS (ia32) ROM Ext. (0*512)` exactly mean (this is output of file
  command) - my rom have mentioned output, but `plpbt.rom` return `plpbt.rom:
  BIOS (ia32) ROM Ext. (87*512)`, what does 0 vs 87 mean ? - this is length of
  Option ROM and is retreived from 3rd byte of binary

* important attributes of Option ROM file
  * 512b aligned
  * correct size byte
  * checksum of whole file should be 0

* It is good to generate some scripts that will do this every time for you, of
  course there is need for program that will extend binary and add correct check
  sum, example can be found in pinczakko's post about ROM hacking

## Debugging in real mode

GDB for i386 and [specific gdbinit](https://github.com/mhugo/gdb_init_real_mode) maybe useful.

## Useful documentation

* [Low Cost Embedded x86 Teaching Tool](https://sites.google.com/site/pinczakko/low-cost-embedded-x86-teaching-tool-2)
* [Plug and Play BIOS Specification](http://download.intel.com/support/motherboards/desktop/sb/pnpbiosspecificationv10a.pdf)
* [PnP BIOS Spec - Dr.Dobb's post](http://www.drdobbs.com/embedded-systems/plug-and-play-oproms-and-the-bios-boot-s/184410189)
* [BIOS Boot Specification](http://www.scs.stanford.edu/05au-cs240c/lab/specsbbs101.pdf)
* [various interesting slides](http://xvilka.me/h2hc2014-reversing-firmware-radare-slides.pdf)
* [explanation of QEMU character devices](http://nairobi-embedded.org/qemu_character_devices.html)

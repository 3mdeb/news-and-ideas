---
title:   Debugging coreboot in qemu environment - part 2
abstract: In previous post coreboot was configured and installed. Here we try
          to establish good debugging environment for it. To create a good
          emulated environment to debug, research and learn coreboot few tricks
          are required. First of all we need to know how to run our emulated
          environment (qemu). What I mean by that?
author: piotr.krol
layout: post
published: true
date: 2012-04-18
archives: "2012"

tags:
  - coreboot
  - qemu
categories:
  - Firmware
---
In [previous post][1] `coreboot` was configured and installed. Here we try to
establish good debugging environment for it. To create a good emulated
environment to debug, research and learn `coreboot` few tricks are required.
First of all we need to know how to run our emulated environment (qemu). What I
mean by that?

*   load coreboot image (-bios option),
*   freeze CPU at startup (-S),
*   get appropriate feedback about virtual machine state (-d in_asm,cpu),
*   set up remote gdb server to run qemu step by step (-s). So finally we get:

```
    qemu -bios src/coreboot/build/coreboot.rom -s -S -d in_asm,cpu -nographic
```

We don't need graphics so it also could be disable (-nographic). Run above
command and prepare debugging environment as described below.

*   load bootblock file in gdb:

```
    file path/to/coreboot/build/bootblock.elf
```

*   use objdump to find out at what address .text, .bss and .data sections are:

```
    objdump -h src/coreboot/build/coreboot_ram|grep -E "text|bss|.data"
```

my output looks like that:

```
    0 .text 00010810 00100000 00100000 00001000 2**2 3 .data 000004d8 001174e8
    001174e8 000184e8 2**2 4 .bss  0000080c 001179c0 001179c0 000189c0 2**3
```

*   use above addresses to load symbols from `coreboot_ram` file in gdb:

```
    add-symbol-file src/coreboot/build/coreboot_ram 0x00100000 -s .data
    0x001174e8 -s .bss 0x001179c0
```

*   In another terminal or screen window

```
    vim /tmp/qemu.log
```

(use :e to reload qemu.log file after every instruction), in this file we will
get information about all registers of virtual machine

* target remote :1234

* Run next instruction (ni command in gdb) and refresh qemu.log, if you get something like:

```
    EAX=00000000 EBX=00000000 ECX=00000000 EDX=00000633
    ESI=00000000 EDI=00000000 EBP=00000000 ESP=00000000
    EIP=0000fff0 EFL=00000002 [-------] CPL=0 II=0 A20=1 SMM=0 HLT=0
    ES =0000 00000000 0000ffff 00009300
    CS =f000 ffff0000 0000ffff 00009b00
    SS =0000 00000000 0000ffff 00009300
    DS =0000 00000000 0000ffff 00009300
    FS =0000 00000000 0000ffff 00009300
    GS =0000 00000000 0000ffff 00009300
    LDT=0000 00000000 0000ffff 00008200
    TR =0000 00000000 0000ffff 00008b00
    GDT= 00000000 0000ffff
    IDT= 00000000 0000ffff
    CR0=60000010 CR2=00000000 CR3=00000000 CR4=00000000
    DR0=00000000 DR1=00000000 DR2=00000000 DR3=00000000
    DR6=ffff0ff0 DR7=00000400
```

it means that your debugging environment was set correctly.

 [1]: /2012/03/12/debugging-coreboot-in-qemu-enviroment

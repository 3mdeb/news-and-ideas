---
ID: 62876
title: >
  Coreboot for QEMU armv7 (vexpress-a9)
  emulated mainboard
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/coreboot-for-qemu-armv7-vexpress-a9-emulated-mainboard/
published: true
date: 2014-08-07 23:08:39
tags:
  - coreboot
  - qemu
categories:
  - Firmware
---
Recently I came back to look into coreboot. Mainly because low level is fun and skills related to firmware (even coreboot) starting get attention on freelance portals ([first odesk job][1], [second odesk job][2]). I was surprised that under the wings of Google coreboot team start to support ARM (BTW ARM programming is IMHO next great skill to learn). So I cloned latest, code compiled QEMU armv7 mainboard model and tried to kick it in latest qemu-system-arm. Unfortunately it didn't boot. Below you can find my TL;DR debugging story. 
## coreboot qemu-armv7 mainboard compilation - very quick steps

    git clone http://review.coreboot.org/p/coreboot
    cd coreboot
    git submodule update --init --checkout
    make menuconfig
     Set: 

`Mainboard -> Mainboard model -> QEMU armv7 (vexpress-a9)` NOTE: To prevent annoying warning about XML when running gdb from coreboot crossgcc utilities: 
    warning: Can not parse XML target description; XML support was disabled at compile time
    

`libexpat1-dev` should be installed. 
    sudo apt-get install libexpat1-dev
    cd util/crossgcc
    ./buildgcc -y -j 8 -p armv7 -G
    cd ../..
    make
    

`buildgcc` will provide armv7 toolchain with debugger (`-G`) and compilation will use 8 parallel jobs. 
## qemu-system-arm compilation - very quick steps

    git clone git://git.qemu.org/qemu.git
    cd qemu
    git submodule update --init --checkout
    make clean && ./configure --target-list=arm-softmmu && make -j8
    sudo make install
    

## Debugging hint Use good gdbinit, so with every instruction executed gdb will automatically provide most useful informations. IMHO good choice is 

`fG!` gdbinit shared on [github][3]. It contain support for ARM and x86. To switch to ARM mode inside gdb simple use `arm` command. Output looks pretty awesome: ![gdbinit][4] 
## Noob dead end Command for running qemu that I found in early qemu-armv7 commit log: 

    qemu-system-arm -M vexpress-a9 -m 1024M -nographic -kernel build/coreboot.rom
     It ends with qemu error: 

    qemu: fatal: Trying to execute code outside RAM or ROM at 0x04000000
    
    R00=00000002 R01=00000000 R02=00000000 R03=00000000
    R04=00000000 R05=00000000 R06=00000000 R07=00000000
    R08=00000000 R09=00000000 R10=00000000 R11=00000000
    R12=00000000 R13=0007fed0 R14=6001032f R15=04000000
    PSR=600000d3 -ZC- A svc32
    (...)
     At the beginning I thought that it is a mistake so I tried: 

    qemu-system-arm -M vexpress-a9 -m 1024M -nographic -bios build/coreboot.rom
     What ends with: 

    qemu: fatal: Trying to execute code outside RAM or ROM at 0xfffffffe
    
    R00=00000002 R01=ffffffff R02=ffffffff R03=ffffffff
    R04=ffffffff R05=ffffffff R06=ffffffff R07=ffffffff
    R08=00000000 R09=ffffffff R10=ffffffff R11=ffffffff
    R12=00000000 R13=0007fed0 R14=0000032f R15=fffffffe
    PSR=600000f3 -ZC- T svc32
     Obviously qemu complains on value in R15 (PC - Program Counter), which is the address of current instruction (like EIP in x86). Stepping through assembler instructions using cross-compiled debugger (

`util/crossgcc/xgcc/bin/armv7-a-eabi-gdb`) points to: 
    0x6001024f:  ldmia.w sp!, {r2, r3, r4, r5, r6, r7, r9, r10, r11, pc}
    

`ldmia` will load from stack values of all given registers. This cause that PC goes to 0x0 and then run instruction from zeroed memory, which in ARM instructions means: 
    andeq   r0, r0, r0
     It happens till PC reach 0x4000000 which is out of 'RAM or ROM' for qemu. Unfortunately there is no sign about 

`ldmia` instruction with above range of registers in coreboot and qemu code. 
## Bisection I knew that at some point qemu worked with coreboot. I tried few versions and it leads me to some commit between 

`v2.1.0-rc1` and `v2.1.0-rc0`. For `-kernel` switch I was able to narrow down problem to one commit that change `VE_NORFLASHALIAS` option for vexpress-a9 to 0 ([6ec1588][5]). It looks like for vexpress-a9 qemu place kernel at 0x60000000 (vexpress.highmem), which is aliased to range 0x0-0x3ffffff. `VE_NORFLASHALIAS=0` cause mapping of vexpress.flash0 to the same region as kernel and because flash (`-bios`) was not added we have empty space (all zeros) what gives `andeq r0, r0, r0`. Right now I have working version of coreboot but only with `-kernel` and `VE_NORFLASHALIAS=-1` set in hw/arm/vexpress.c. The main questions are: 
*   what is the correct memory map for qemu-armv7 and how coreboot should be mapped ?
*   what's going on with coreboot or qemu that I can't go through bootblock ?

## Debugging I tried to debug coreboot executed from flash: 

    qemu-system-arm -M vexpress-a9 -m 1024M -nographic -bios build/coreboot.rom -s -S
     Coreboot as UEFI has few phases. For UEFI we distinguish SEC, PEI, DXE and BDS (there are also TSL, RT and AL, but not important for this considerations). On coreboot side we have bootblock, romstage, ramstage and payload. 

### qemu-armv7 bootblock failure qemu-armv7 booting procedure start from 

`_rom` section which contain hardcoded jump to `reset` procedure. After that go through few methods like on below flow: 
    _rom
    |-> reset
        |-> init_stack_loop
            |-> call_bootblock
                |-> main
                    |-> armv7_invalidate_caches
                        |-> icache_invalidate_all
                        |-> dcache_invalidate_all
                          |-> dcache_foreach
     At the end of 

`dcache_foreach` we experience failure because `ldmia` instruction tries to restore registers from stack, which should be stored at the beginning of `dcache_foreach`, by: 
    stmdb  sp!, {r0, r1, r4, r5, r6, r7, r9, sl, fp, lr}
     Unfortunately for some reason stack doesn't contain any reasonable values (all 0xffffffff) after 

`stmdb`. Why is that ? 
### Obvious things are not so obvious As I point above everything seems to be related with memory map for vexpress-a9. I wrote question to qemu developers mailing list describing all the problems. You can read it 

[here][6]. So the answer is that ARM Versatile Express boards in general have two different memory maps. First is legacy with RAM in low memory and second is modern with flash in low memory instead of RAM. Since qemu `v2.1.0` modern memory map was used. That's why I saw change in behavior. Obviously flash in qemu is read only, so no matter what pushing on stack didn't work. 
### coreboot stack location fix I though that fix would be easy. One thing that I have to do is change stack address. The question is where to place the stack ? So I took a look at qemu memory map: 

    (qemu) info mtree
    (...)
    0000000040000000-0000000043ffffff (prio 0, R-): vexpress.flash0
    0000000044000000-0000000047ffffff (prio 0, R-): vexpress.flash1
    0000000048000000-0000000049ffffff (prio 0, RW): vexpress.sram
    000000004c000000-000000004c7fffff (prio 0, RW): vexpress.vram
    000000004e000000-000000004e0000ff (prio 0, RW): lan9118-mmio
    0000000060000000-000000009fffffff (prio 0, RW): vexpress.highmem
     SRAM is temporary storage where I decide to put stack. The change in coreboot looks like below: \``\`c src/mainboard/emulation/qemu-armv7/Kconfig config STACK_TOP hex default 0x4803ff00 config STACK_BOTTOM hex default 0x48000000 config STACK_SIZE hex default 0x0003ff00 

    I changed STACK_TOP and STACK_BOTTOM.
    
    Unfortunately still I was unable to boot coreboot on vexpress-a9. Situation
    improved because stack start to work correctly and accept push and pop data
    to/from, but next problem occurs in `init_default_cbfs_media`.
    
    ### init_default_cbfs_media problem
    
    As CBFS specification explains:
    {% blockquote Jordan Crouse http://review.coreboot.org/gitweb?p=coreboot.git;a=blob;f=documentation/cbfs.txt;h=7ecc9014a1cb2e0a86bbbf514e17f6b0360b9c0c;hb=HEAD %}
    CBFS is a scheme for managing independent chunks of data in a system ROM.
    {% endblockquote %}
    
    Default CBFS media initialization for qemu-armv7 leads to
    `init_emu_rom_cbfs_media` that fills `cbfs_media` structures with function
    pointers that help to operate on CBFS.
    
    ```c src/mainboard/emulation/qemu-armv7/media.c
    int init_emu_rom_cbfs_media(struct cbfs_media *media)
    {
        media->open = emu_rom_open;
        media->close = emu_rom_close;
        media->map = emu_rom_map;
        media->unmap = emu_rom_unmap;
        media->read = emu_rom_read;
        return 0;
    }
    </code></pre>
    
    The problem was that pointers were relative to bootblock base address
    <code>0x00010000</code> and <code>-bios</code> option maps coreboot.rom from address <code>0x0</code>. This
    leads to change in bootblock base address to <code>0x0</code>:
    
    ```c src/mainboard/emulation/qemu-armv7/Kconfig
    config BOOTBLOCK_BASE
        hex
        default 0x00000000
    
    <pre><code><br />This solve other issue not mentioned till now. I didn't know why I can't load
    symbols for bootblock using `add-symbol-file` in gdb. Of course reason was
    bootblock didn't start at 0x0 but at 0x10000. Since this moment I could debug
    bootblock using lines of C code, by simply:
    
    ```text
    gdb$ add-symbol-file build/cbfs/fallback/bootblock.debug 0x0
     It was not the end because another error popped up: 

    Bad ram pointer 0x3b8
    

### memcpy during CBFS decompression Problem was with storing registers </code>

`stmia` during memcpy. Backtrace: </pre>
    #0  memcpy () at src/arch/armv7/memcpy.S:64
    #1  0x000015b2 in cbfs_decompress (algo=<optimized out>, src=<optimized out>, dst=<optimized out>, len=0x3310) at src/lib/cbfs_core.c:227
    #2  0x00001702 in cbfs_load_stage (media=media@entry=0x0 <_start>, name=name@entry=0x2260 "fallback/romstage") at src/lib/cbfs.c:137
    #3  0x00002236 in main () at src/arch/armv7/bootblock_simple.c:63
     For some reason R0 (to which we store), contain strange address 0x10000. No value was stored in this memory range, because again it was read only flash. Address is passed from upper layers - 

`cbfs_get_file_content`. During debugging I realize that this address means `ROMSTAGE_BASE`. So I changed `ROMSTAGE_BASE` to somewhere in SRAM. `c src/mainboard/emulation/qemu-armv7/Kconfig
config ROMSTAGE_BASE
    hex
    default 0x48040000` What I saw when trying to boot coreboot with this fix was wonderful log proved that coreboot boots without problems. 
## Conclusion Above debugging session was all about memory map. It was really fun to experience all those issues because I had to understand lot of ARM assembly instructions, track memory, read the spec, read coreboot and qemu code. It gave me a lot of good experience. If you have any questions or comments please let me know. And finally what is most important it was next thing done on my list. I think next challenge could be experiment with Linux kernel booting. Coreboot can boot kernel directly or through payload with bootloader. Thanks for reading.

 [1]: http://bit.ly/1sBSybZ
 [2]: http://bit.ly/1sBSR6F
 [3]: https://github.com/gdbinit/Gdbinit
 [4]: https://3mdeb.com/wp-content/uploads/2017/07/gdbinit.png
 [5]: http://git.qemu.org/?p=qemu.git;a=commit;h=6ec1588e09770ac7e9c60194faff6101111fc7f0
 [6]: http://lists.nongnu.org/archive/html/qemu-devel/2014-08/msg02599.html
---
title: 'Trying to fix ESXi 6.7.0 boot issue, part one'
abstract: "First mentions that updated versions of VMware's ESXi 6.7.0 installer
          doesn't start on PC Engines platforms come from the beginning of 2019.
          Older versions of ESXi worked fine. 'Shutting down firmware
          services...' is the last line printed before hang or reboot."
cover: /covers/vmware-logo.png
author: krystian.hebel
layout: post
published: true
date: 2020-01-03
archives: "2020"

tags:
  - pc-engines
  - hypervisor
  - virtualization
  - x86-assembly
  - reverse-engineering
  - syslinux
categories:
  - Firmware
  - OS Dev

---

[First mentions](http://pcengines.info/forums/?page=post&id=511E5F7D-AD74-4041-8C0C-72FBADD95504&fid=DF5ACB70-99C4-4C61-AFA6-4C0E0DB05B2A&pageindex=3)
that updated versions of VMware's ESXi 6.7.0 installer doesn't start on PC
Engines platforms come from the beginning of 2019. We were aware of that issue
since April ([1](https://twitter.com/mibosshard/status/1118229143819362304),
[2](http://pcengines.info/forums/?page=post&id=4C472C95-E846-42BF-BC41-43D1C54DFBEA&fid=6D8DBBA4-9D40-4C87-B471-80CB5D9BD945&pageindex=6)).
Older versions of ESXi worked fine.

There were fixes from other firmware vendors for Intel NUC platforms, but
apparently those dealt with UEFI memory map problems, as mentioned [here](https://www.virtuallyghetto.com/2018/11/update-on-running-esxi-on-intel-nuc-hades-canyon-nuc8i7hnk-nuc8i7hvk.html).
Release notes for 0051 linked in that article (you have to open BIOS Update
page, direct link to release notes is no longer valid) mention that it fixes
versions 6.7 and 6.5, so this probably is different issue altogether.

## Symptoms

For older firmware versions, boot process hanged at:

```
<6>Loading /vsanmgmt.v00
<6>Loading /tools.t00
<6>Loading /xorg.v00
<6>Loading /imgdb.tgz
<6>Loading /imgpayld.tgz
<6>Shutting down firmware services...
```

This changed to reboot in newer versions of coreboot:

```
<6>Loading /vsanheal.v00
<6>Loading /vsanmgmt.v00
<6>Loading /tools.t00
<6>Loading /xorg.v00
<6>Loading /imgdb.tgz
<6>Loading /imgpayld.tgz
<6>Shutting down firmware services..PC Engines apu2
coreboot build 20190304
BIOS version v4.9.0.4
SVI2 Wait completion disabled
```

This happens before kernel is even started, in bootloader. This stage of
bootloader is in `mboot.c32` on the installation medium.

## Different versions of mboot.c32

File with this name is a part of [SYSLINUX](https://wiki.syslinux.org/wiki/index.php?title=Mboot.c32).
It is responsible for loading images using Multiboot specification. During our
research, we tried to use `mboot.c32` from different versions of SYSLINUX.

ESXi uses its own version, which implements Mutiboot (we first though that this
is a typo, but apparently it's not) protocol. As the name suggests, it is a
mutated variant of Multiboot :) Do not try to start ESXi with SYSLINUX's
modules as they will not work.

## Source code and debug info

There are sources for vSphere available on the [VMware website](https://my.vmware.com/en/web/vmware/info/slug/datacenter_cloud_infrastructure/vmware_vsphere/6_7#open_source).
Code for `esxboot` is included in _Open Source Disclosure package for VMware vSphere Hypervisor (ESXi)_.
It can be downloaded as an ISO image containing all open source components.
There is also a stale [Github repo](https://github.com/vmware/esx-boot) with
older code.

One of the most useful information found there is [list of mboot.c32 options](https://github.com/vmware/esx-boot/blob/master/mboot/mboot.c).
This allowed us to gather more verbose output. From SYSLINUX menu press Tab and
change command line to:

```
> mboot.c32 -c boot.cfg -D -S 1 -H
```

Lines that were printed without additional flags will be printed twice,
sometimes intertwined. This is output with most unimportant (for this issue)
lines removed:

```
COM32 v4.7 (syslinux)
mboot __executable_start is at 0x160000
Logging initial memory map
e820[0]: 0x0 - 0x9fbff  len=654336, type=1, no attr
e820[1]: 0x9fc00 - 0x9ffff  len=1024, type=2, no attr
e820[2]: 0xf0000 - 0xfffff  len=65536, type=2, no attr
e820[3]: 0x100000 - 0xdfe88fff  len=3755511808, type=1, no attr
e820[4]: 0xdfe89000 - 0xdfffffff  len=1536000, type=2, no attr
e820[5]: 0xf8000000 - 0xfbffffff  len=67108864, type=2, no attr
e820[6]: 0xfed40000 - 0xfed44fff  len=20480, type=2, no attr
e820[7]: 0x100000000 - 0x11effffff  len=520093696, type=1, no attr
COM32 sysargs 9, memsize (valid) 3756560384
Malloc arena:
  (used) address 0x18c300, size 64
  (used) address 0x18c340, size 48
  (used) address 0x18c370, size 32
  (free) address 0x18c390, size 3746511860
Config: /boot.cfg
Prefix: (None)
<6>Loading /b.b0Loading /b.b00
0
recdCRC 0xf580346e, calcCRC 0xf580346e, tSize 130556, eSize 2109835
b.b00 (MD5: 20eceefbd0f39dd272a4a414d4efe7aa): transferred 127Kb (130595 bytes)
b.b00 (MD5: 2baee9a39a0b1712e61a958bc04c3e3e): extracted 2Mb (2109835 bytes)
<6>Loading /jumpstrt.gLoading /jumpstrt.gz
jumpstrt.gz (MD5: 897d2051d32d7e0d5b918c2ccd02f872): transferred 20 bytes
jumpstrt.gz (MD5: d41d8cd98f00b204e9800998ecf8427e): extracted 0 bytes
z

...
               more modules
...

<6>Loading /imgpayld.tgLoading /imgpayld.tgz
z
recdCRC 0x28b8674e, calcCRC 0x28b8674e, tSize 6314280, eSize 6389760
imgpayld.tgz (MD5: 43f5fc393d1abed5f8cc470aa76545e1): transferred 6Mb (6314297 bytes)
imgpayld.tgz (MD5: 60f278f106d94e0365893aa9c401716f): extracted 6Mb (6389760 bytes)
Loaded 161/161 modules
Total transferred: 305Mb (320564213 bytes)
Total extracted: 452Mb (474157065 bytes)
Initializing Mutiboot standard...
e820[0]: 0x0 - 0x9fbff  len=654336, type=1, no attr
e820[1]: 0x9fc00 - 0x9ffff  len=1024, type=2, no attr
e820[2]: 0xf0000 - 0xfffff  len=65536, type=2, no attr
e820[3]: 0x100000 - 0xdfe88fff  len=3755511808, type=1, no attr
e820[4]: 0xdfe89000 - 0xdfffffff  len=1536000, type=2, no attr
e820[5]: 0xf8000000 - 0xfbffffff  len=67108864, type=2, no attr
e820[6]: 0xfed40000 - 0xfed44fff  len=20480, type=2, no attr
e820[7]: 0x100000000 - 0x11effffff  len=520093696, type=1, no attr
E820 count estimate: 8+20 slack
<6>Shutting down firrmware services..Shutting down firmware services...
e820[0]: 0x0 - 0x9fbff  len=654336, type=1, no attr
e820[1]: 0x9fc00 - 0x9ffff  len=1024, type=2, no attr
e820[2]: 0xf0000 - 0xfffff  len=65536, type=2, no attr
e820[3]: 0x100000 - 0xdfe88fff  len=3755511808, type=1, no attr
e820[4]: 0xdfe89000 - 0xdfffffff  len=1536000, type=2, no attr
e820[5]: 0xf8000000 - 0xfbffffff  len=67108864, type=2, no attr
e820[6]: 0xfed40000 - 0xfed44fff  len=20480, type=2, no attr
e820[7]: 0x100000000 - 0x11effffff  len=520093696, type=1, no attr
Scanning system tables...
SMBIOS: entry point structure found @ 0xf3b20 (31 bytes)
SMBIOS: table found @ 0xdfe8c020 (541 bytes)
Scanning system memory (8 entries)...
Registering Mutiboot info...
ELF link address range is [0x400000:0x600000)
[k] 1b1f60 - 1b2f60 -> 400000 - 401000 (4096 bytes)
[k] 1b2f60 - 211f60 -> 401000 - 460000 (389120 bytes)
[k] 211f60 - 2816a8 -> 460000 - 4d9648 (497224 bytes)
[k] 2825a8 - 3a8f60 -> 4d9648 - 600000 (1206712 bytes)
Calculating relocations...
[s] 11fc3e20 - 11fc6009 -> 600000 - 6021e9 (8682 bytes)
[s] 11fc62c0 - 11fc632d -> 6021ea - 602257 (110 bytes)
[s] 11fc6340 - 11fc634c -> 602258 - 602264 (13 bytes)

...
               about 300 relocations in total ([s] and [m])
...

[s] 11fc7700 - 11fc770a -> 602a75 - 602a7f (11 bytes)
[s] 11fc7720 - 11fc772d -> 602a80 - 602a8d (14 bytes)
[s] 18c1b0 - 18c1b5 -> 602a8e - 602a93 (6 bytes)
[m] 7b2110 - 1410d26 -> 603000 - 1261c16 (12971031 bytes)
[m] 3b9110 - 3c8533 -> 1262000 - 1271423 (62500 bytes)
[m] 44c960 - 62d77b -> 1272000 - 1452e1b (1969692 bytes)

...

[m] 11dfce10 - 11fc3e0f -> 1c09c000 - 1c262fff (1863680 bytes)
[m] 125c9830 - 12be182f -> 1c263000 - 1c87afff (6389760 bytes)
Converting e820 map to Mutiboot format...
E820 count before final merging: 8
E820 count after final merging: 8
Setting up Mutiboot runtime references...
Finalizing relocations validation...
Allocation table count=8, max=4096
...moving 0x1584150 (size 0x2dda58) temporarily to 0x25f2e000
...moving 0x1861bc0 (size 0x284580) temporarily to 0x2620ba58

...
               about 100 similar lines
...

...moving 0x125c9830 (size 0x618000) temporarily to 0x2930388c
...moving 0x44c960 (size 0x1e0e1c) temporarily to 0x2991b88c
Allocation table count=8, max=4096
Preparing a safe environment...
Allocation table count=8, max=4096
[t] 1771dc - 17b5af -> 29afc6b0 - 29b00a83 (17364 bytes)
[t] 170ce6 - 170dd2 -> 29b00a90 - 29b00b7c (237 bytes)
Installing a safe environment...
```

This is the place where it hangs or reboots. It is a few hundred lines below the
`<6>Shutting down firmware services...` line. It is printed by the code in
`install_trampoline()` function in [reloc.c](https://github.com/vmware/esx-boot/blob/master/mboot/reloc.c#L828).
With reverse engineering we established that `only_em64t` was not defined, so
only `do_reloc()` is called before returning from this function.

`install_trampoline()` is called from `main()` in [mboot.c](https://github.com/vmware/esx-boot/blob/master/mboot/mboot.c#L431),
followed by `Log()`, both for success and for failure, so we can assume that
`install_trampoline()` does not return, right? Well, not quite.

![https://9gag.com/gag/aKwbpgg/theres-a-dog-behind-you](/img/inception.webp)

## We need to go deeper

Binary built by us would most likely be different than the one included on
installation image, because it would use different toolchain. To have 100%
identical machine code (up to a certain point) we decided to go with binary
patching instead of dealing with different compilers and dependency hell.

It basically came to disassembling original image (which was already done to
check if `only_em64t` was defined) and inserting new code, in the point we were
trying to test, using hexeditor. This code was (Intel syntax):

```
mov    dx, 0x3f8    /* UART port */
mov    al, 'x'
out    dx, al
jmp    short $      /* dead loop, we do not want to continue execution because
                       part of the code was overwritten */
```

To write this in machine code, we can either make a dummy file and compile it
(sometimes requires cross-compilation), write it by hand with information from
[Intel SDM Vol. 2](https://software.intel.com/en-us/download/intel-64-and-ia-32-architectures-sdm-combined-volumes-2a-2b-2c-and-2d-instruction-set-reference-a-z)
or, after a while, from memory (can be tedious), or use online tools like
[this one](https://defuse.ca/online-x86-assembler.htm). Code above translates to
byte sequence: `66 ba f8 03 b0 78 ee eb fe`.

This code has been put in important places as a checkpoints in the flow.
**It must overwrite the code, and not be inserted** because offsets to other
functions and structures must not change.

Those checkpoints revealed that not only `do_reloc()` and `install_trampoline()`
returned, but also the first `Log()` after that. Apparently it printed empty
string which is, let's say, _less intolerable_ than printing random bytes.

This seems like a broken relocation - call to `Log()` points to a string that is
no longer there. At least `mboot.c32` read-only data section was relocated and
overwritten, code might also be relocated but apparently it isn't overwritten
because our checkpoint executed. There is a [warning](https://github.com/vmware/esx-boot/blob/master/mboot/reloc.c#L238)
before `do_reloc()` code about it being position-independent. Trampoline code
and data are objects of type `[t]` (see top of the file for description of
types), and because of that they are handler with special care, but `main()`'s
code and data isn't.

#### Relocation - why is it needed?

Not all of the code is position-independent. An example of such code is the
kernel (at least its initial part). It must be loaded at the address for which
it was linked, as printed in log:

```
ELF link address range is [0x400000:0x600000)
[k] 1b1fa0 - 1b2fa0 -> 400000 - 401000 (4096 bytes)
[k] 1b2fa0 - 211fa0 -> 401000 - 460000 (389120 bytes)
[k] 211fa0 - 2816e8 -> 460000 - 4d9648 (497224 bytes)
[k] 2825e8 - 3a8fa0 -> 4d9648 - 600000 (1206712 bytes)
```

If this address is not available, i.e. not marked as free RAM in e820 map
(type=1), boot fails. Base address is written in kernel file, it is not known to
the bootloader before this file is loaded, extracted and parsed. It is very
unlikely that it will be loaded to the correct address on the first write to the
memory. Also, sections can have different sizes in file than in memory, usually
padding is added after file is read.

Bootloader loads all modules at once, before any checks for address ranges are
made. In most cases, those modules are initially loaded in the range required by
the kernel. This can be deducted from `mboot __executable_start is at 0x160000`
and `Total extracted: 477Mb (500775353 bytes)`. Therefore, some juggling is
required to make space for kernel. It is (relatively) easy for the modules, they
were not run yet so there is little difference between code and data. Relocating
binary that was already started is a different story altogether.

#### PIC

`mboot.c32` is compiled as a **position independent code** (PIC). It means that
there are no hardcoded addresses, all of them are calculated relatively to the
program counter - EIP register. This involves a trick with reading return
address from the stack on x86; it is much easier for x86_64 as there is support
for RIP relative addressing.

There are some rules that must be followed during relocation. First of all, code
responsible for relocation shouldn't return to the code that called it, if the
caller or the stack was being relocated. In that case, there should be
**no plain return statements**, because they read return address from the stack
(which might have been relocated), which holds the pointer to the old code
(which also might have been relocated). Return address could be patched and
stack could be protected, but that's not all.

Even worse issue is that when the flow returns to the calling function (assuming
its code was not overwritten), **it still has old pointer values** saved in
local variables, be it on the stack or in registers. There is no easy way of
patching such addresses.

It is much easier to relocate global data. When any global variable is accessed,
its value is not loaded directly, instead a _pointer_ to that variable (or any
other symbol) is read from a _relatively-addressed_ table containing _absolute_
addresses to all such symbols. This table is called **the Global Offset Table**
(GOT). It is present in the file, where it contains relative offsets to the
data, just as if it were loaded at a base address 0. Pointers in that table are
updated (real base address is added to them) by the binary itself - the loader
doesn't know enough about layout of sections of binary. It happens during
self-initialization of a module, but nothing prevents us from doing something
similar again after a relocation.

> Global Offset Table and PIC in general is described in [Eli Bendersky's article](https://eli.thegreenplace.net/2011/11/03/position-independent-code-pic-in-shared-libraries/),
> with examples. It is focused on shared libraries, but the main principles are
> still the same.

In this particular case on every function entry compiler adds a call to function
that copies EIP to EBX. Then some value is added to it, different for each
function, depending on its relative (to the base of image) entry point address.
The resultant EBX always holds the address to the same place in binary - GOT.

> Note that it may be any register, but most compilers will pick EBX - it is one
> of the least used registers for other tasks (e.g. multiplication and division
> is wired to use EAX/EDX, loops use ECX, ESI/EDI are used for string operations
> etc.). It is also one of the few callee-save registers for virtually every
> widely used calling convention, which means that the caller doesn't have to
> save it for every function.

All global and/or static data is accessed through GOT. Local variables are saved
on the stack, and accessed relative to ESP or EBP. Functions are called relative
to EIP, return address is saved on the stack, from where it is read when
returning from the function. With all of these, program should be able to run
without any assumptions for any absolute address.

## Workaround for booting problem

There is a way to boot ESXi 6.7U3 (perhaps older updates as well, not tested).
It comes down to marking the memory as reserved for the range where `mboot.c32`
(and other c32 files such as `menu.c32`) are loaded.

Keep in mind that **this is not a solution**. It allows ESXi installer to boot.
It was **not tested** against booting other OSes or installed version of ESXi.
**Use at your own risk**.

```
diff --git a/src/lib/bootmem.c b/src/lib/bootmem.c
index 8ca3bbd3f633..66c37c05843d 100644
--- a/src/lib/bootmem.c
+++ b/src/lib/bootmem.c
@@ -98,6 +98,17 @@ static void bootmem_init(void)
 
        bootmem_arch_add_ranges();
        bootmem_platform_add_ranges();
+
+       const struct range_entry *r;
+       size_t start = 0x100000;
+       size_t end = 0x400000;
+       memranges_each_entry(r, bm) {
+               if (start >= range_entry_base(r) && end <= range_entry_end(r)
+                       && range_entry_tag(r) == BM_MEM_RAM) {
+                       bootmem_add_range(start, end-start, BM_MEM_RESERVED);
+                       return;
+               }
+       }
 }
 
 void bootmem_add_range(uint64_t start, uint64_t size,
```

The log produced after applying the above change starts with:

```
COM32 v4.7 (syslinux)
mboot __executable_start is at 0x160000
Logging initial memory map
e820[0]: 0x0 - 0x9fbff  len=654336, type=1, no attr
e820[1]: 0x9fc00 - 0x9ffff  len=1024, type=2, no attr
e820[2]: 0xf0000 - 0x3fffff  len=3211264, type=2, no attr
e820[3]: 0x400000 - 0xdfe88fff  len=3752366080, type=1, no attr
e820[4]: 0xdfe89000 - 0xdfffffff  len=1536000, type=2, no attr
e820[5]: 0xf8000000 - 0xfbffffff  len=67108864, type=2, no attr
e820[6]: 0xfed40000 - 0xfed44fff  len=20480, type=2, no attr
e820[7]: 0x100000000 - 0x11effffff  len=520093696, type=1, no attr
COM32 sysargs 9, memsize (valid) 3756523520
Malloc arena:
  (free) address 0x18c300, size 3746446468
  (used) address 0xdfe80000, size 64
  (used) address 0xdfe80040, size 48
  (used) address 0xdfe80070, size 32
  (free) address 0xdfe80090, size 36720
Config: /boot.cfg
Prefix: (None)
```

In these lines we can see that the specified region was appended to the previous
reserved range, `e820[2]`, because there is no need to use two separate fields
when one would suffice. There are other worrisome lines, however.

One of those is `mboot __executable_start is at 0x160000` - it is well within
the part of memory where we told it not to be. It was loaded at this address by
the previous module - `menu.c32` in this case - so it suggests that it is not a
bug in `mboot.c32`, as we [initially thought](https://github.com/vmware/esx-boot/issues/4).

The second visible problem is in malloc arena - it also reports that a part of
the memory in the reserved range is free to use by the module. This issue is a
direct result of the previous one. Both are caused by the way SYSLINUX scans
memory.

## [To be continued...](https://en.wikipedia.org/wiki/Cliffhanger)

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

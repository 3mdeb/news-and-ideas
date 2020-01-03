---
title: 'Template post title'
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: name.surname
layout: post
published: false
date: 2020-01-03
archives: "2020"

tags:
  - tag 1
  - tag 2
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

First mentions that updated versions of VMware's ESXi 6.7.0 installer doesn't
start on PC Engines platforms come from the beginning of 2019. We were aware of
that issue since April. Older versions of ESXi work fine.

TBD: links
http://pcengines.info/forums/?page=post&id=511E5F7D-AD74-4041-8C0C-72FBADD95504&fid=DF5ACB70-99C4-4C61-AFA6-4C0E0DB05B2A&pageindex=3   Installation ESXi APU 2c4
http://pcengines.info/forums/?page=post&id=4C472C95-E846-42BF-BC41-43D1C54DFBEA&fid=6D8DBBA4-9D40-4C87-B471-80CB5D9BD945&pageindex=6   PC Engines firmware release thread
https://twitter.com/mibosshard/status/1118229143819362304

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

File with this name is a part of [Syslinux](https://wiki.syslinux.org/wiki/index.php?title=Mboot.c32).
It is responsible for loading images using Multiboot specification. During our
research, we tried to use `mboot.c32` from different versions of Syslinux.

ESXi uses its own version, which implements Mutiboot (we first though that this
is a typo, but it isn't) protocol. As the name suggests, it is a mutated variant
of Multiboot :) Do not try to start ESXi with Syslinux's modules as they will
not work.

## Source code and debug info

There are sources for vSphere available on the [VMware website](https://my.vmware.com/en/web/vmware/info/slug/datacenter_cloud_infrastructure/vmware_vsphere/6_7#open_source).
Code for `esxboot` is included in _Open Source Disclosure package for VMware vSphere Hypervisor (ESXi)_.
It can be downloaded as an ISO image containing all open source components.
There is also a stale [Github repo](https://github.com/vmware/esx-boot) with
older code.

One of the most useful information found there is [list of mboot.c32 options](https://github.com/vmware/esx-boot/blob/master/mboot/mboot.c).
We haven't found such list on the VMware website. This allowed us to gather more
verbose output. From Syslinux menu press Tab and change command line to:

```
> mboot.c32 -c boot.cfg -D -S 1
```

Lines that were printed without additional flags will be printed twice,
sometimes intertwined. This is output with most unimportant (for this issue)
lines removed:

```
COM32 v4.7 (syslinux)
'apu2' by 'PC Engines', firmware version 'v4.11.0.1', built on '12/09/2019'
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
  (used) address 0x18c480, size 64
  (used) address 0x18c4c0, size 48
  (used) address 0x18c4f0, size 32
  (free) address 0x18c510, size 3746511476
Config: /boot.cfg
Prefix: (None)
<6>Loading /b.b0Loading /b.b00
0
recdCRC 0x5badc031, calcCRC 0x5badc031, tSize 130645, eSize 2109835
b.b00 (MD5: f8c1baa7aefb3125ea033084fd1164aa): transferred 127Kb (130684 bytes)
b.b00 (MD5: 99810fe11a9c2d65f7c3f37d2390cb67): extracted 2Mb (2109835 bytes)
<6>Loading /jumpstrt.gLoading /jumpstrt.gz
jumpstrt.gz (MD5: b4dbe2daceb5cdda5f70961b4afc63aa): transferred 20 bytes
jumpstrt.gz (MD5: d41d8cd98f00b204e9800998ecf8427e): extracted 0 bytes
z

...
               more modules
...

<6>Loading /imgpayld.tgLoading /imgpayld.tgzz

recdCRC 0x99d619e9, calcCRC 0x99d619e9, tSize 6158284, eSize 6225920
imgpayld.tgz (MD5: 5486add7d17fe7a266740f849e12ffc3): transferred 5Mb (6158301 bytes)
imgpayld.tgz (MD5: ba51bd658fcba18b40cc0c67034289f2): extracted 5Mb (6225920 bytes)
Loaded 160/160 modules
Total transferred: 329Mb (345263482 bytes)
Total extracted: 477Mb (500775353 bytes)
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
<6>Shutting down firmware services..Shutting down firmware services...
e820[0]: 0x0 - 0x9fbff  len=654336, type=1, no attr
e820[1]: 0x9fc00 - 0x9ffff  len=1024, type=2, no attr
e820[2]: 0xf0000 - 0x.
fffff  len=65536, type=2, no attr
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
[k] 1b1fa0 - 1b2fa0 -> 400000 - 401000 (4096 bytes)
[k] 1b2fa0 - 211fa0 -> 401000 - 460000 (389120 bytes)
[k] 211fa0 - 2816e8 -> 460000 - 4d9648 (497224 bytes)
[k] 2825e8 - 3a8fa0 -> 4d9648 - 600000 (1206712 bytes)
Calculating relocations...
[s] 120dc240 - 120de3f9 -> 600000 - 6021b9 (8634 bytes)
[s] 120de6a0 - 120de6ba -> 6021ba - 6021d4 (27 bytes)
[s] 120de6d0 - 120de6dc -> 6021d5 - 6021e1 (13 bytes)

...
               about 300 relocations in total ([s] and [m])
...

[s] 120dfa70 - 120dfa7a -> 6029e6 - 6029f0 (11 bytes)
[s] 120dfa90 - 120dfa9d -> 6029f1 - 6029fe (14 bytes)
[s] 18c330 - 18c335 -> 6029ff - 602a04 (6 bytes)
[m] 7b5950 - 141c549 -> 603000 - 1269bf9 (13003770 bytes)
[m] 3b9150 - 3c8573 -> 126a000 - 1279423 (62500 bytes)
[m] 44c7a0 - 62d0a3 -> 127a000 - 145a903 (1968388 bytes)
[m] 3ca7a0 - 3d06a3 -> 145b000 - 1460f03 (24324 bytes)

...

[m] 11f0b230 - 120dc22f -> 1da1c000 - 1dbecfff (1904640 bytes)
[m] 126bba50 - 12caba4f -> 1dbed000 - 1e1dcfff (6225920 bytes)
Converting e820 map to Mutiboot format...
E820 count before final merging: 8
E820 count after final merging: 8
Setting up Mutiboot runtime references...
Finalizing relocations validation...
Allocation table count=8, max=4096
...moving 0x1565970 (size 0x2dda58) temporarily to 0x28dff000
...moving 0x18433e0 (size 0x284580) temporarily to 0x290dca58

...
               about 100 similar lines
...

...moving 0x126bba50 (size 0x5f0000) temporarily to 0x2c3c72c8
...moving 0x44c7a0 (size 0x1e0904) temporarily to 0x2c9b72c8
Allocation table count=8, max=4096
Preparing a safe environment...
Allocation table count=8, max=4096
[t] 17735c - 17b6f7 -> 2cb97bd0 - 2cb9bf6b (17308 bytes)
[t] 170e86 - 170f72 -> 2cb9bf70 - 2cb9c05c (237 bytes)
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
                       some of the code was overwritten */
```

To write this in machine code, we can either make a dummy file and compile it
(sometimes requires cross-compilation), write it by hand with information from
[Intel SDM Vol. 2](https://software.intel.com/en-us/download/intel-64-and-ia-32-architectures-sdm-combined-volumes-2a-2b-2c-and-2d-instruction-set-reference-a-z)
or, after a while, from memory (can be tedious), or use online tools like
[this one](https://defuse.ca/online-x86-assembler.htm). This code resulted in
byte sequence: `66 ba f8 03 b0 78 ee eb fe`.

This code has been put in important places as a checkpoints in the flow.
**It must overwrite the code, and not be inserted** because offsets to other
functions and structures must not change.

Those checkpoints revealed that not only `do_reloc()` and `install_trampoline()`
returned, but also the first `Log()` after that. Apparently it printed empty
string which is, let's say, less intolerable than printing random bytes. This
was the last logical place to put such checkpoint.

This seems like a broken relocation - call to `Log()` points to a string that is
no longer there. At least `mboot.c32` read-only data section was relocated and
overwritten, code might also be relocated but apparently it isn't overwritten
because our checkpoint executed. There is a [warning](https://github.com/vmware/esx-boot/blob/master/mboot/reloc.c#L238)
before `do_reloc()` code about it being position-independent. Trampoline code
and data are objects of type `[t]` (see top of the file for description of
types), and because of that they are handler with special care, but `main()`'s
code and data isn't. After returning to `main()`, both registers and local
variables hold pointers to data that is no longer in that place.


TBD
https://github.com/vmware/esx-boot/issues/4


## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

---
title: Building coreboot for RISC-V and running it in Qemu
abstract: 'In this article, I will show you step by step how to build coreboot for RISC-V and run it in QEMU emulator'
cover: /covers/coreboot-logo.svg
author: wojciech.niewiadomski
layout: post
published: true
date: 2020-08-26
archives: "2020"

tags:
  - Firmware
  - coreboot
  - RISC-V
categories:
  - Firmware
  - Miscellaneous

---

Your post content

# Building coreboot for RISC-V and running it in Qemu

#### 1. Install required tools and libraries

On Debian:

```sh
$ sudo apt-get install -y bison build-essential curl flex git gnat libncurses5-dev m4 zlib1g-dev qemu-system
```
On Arch Linux:

```sh
$ sudo pacman -S base-devel curl git gcc-ada ncurses zlib
```

On Fedora:

```sh
$ sudo dnf install git make gcc-gnat flex bison xz bzip2 gcc g++ ncurses-devel wget zlib-devel
```

#### 2. Download coreboot source tree

```sh
$ git clone https://review.coreboot.org/coreboot
$ cd coreboot
```

#### 3. Build coreboot toolchain

You can use CPUS= to specify the number of threads you want to use for building
toolchain.

```sh
$ make crossgcc-riscv CPUS=4
```
> NOTE: This will take a while

At the end of the process, you should get the info that your cross toolchain is
built

```
You can now run riscv64-elf cross GCC from /your/path/to/coreboot/util/crossgcc/xgcc.
```

#### 5. Configure the build

Configure your mainboard

```sh
$ make menuconfig
```

Inside `menuconfig` follow these steps:

```
   select 'Mainboard' menu
   select '(Emulation)' in 'Mainboard vendor'
   select 'QEMU RISC-V rv64' in 'Mainboard model'
   select < Exit >
   select < Exit >
   select < Yes >
```

(Optionally) You can check your configuration by these commands:

```sh
$ make savedefconfig
$ cat defconfig
```

The output should look like this:

```
CONFIG_BOARD_EMULATION_QEMU_RISCV_RV64=y
```

#### 6. Build coreboot


```sh
$ make
```

At the end of the process, you can see the following output

```
FMAP REGION: COREBOOT
Name                           Offset     Type           Size   Comp
cbfs master header             0x0        cbfs header        32 none
fallback/romstage              0x80       stage           14126 none
fallback/ramstage              0x3800     stage           23260 none
config                         0x9340     raw               101 none
revision                       0x9400     raw               675 none
(empty)                        0x9700     null          4023960 none
header pointer                 0x3dfdc0   cbfs header         4 none
    HOSTCC     cbfstool/rmodtool.o
    HOSTCC     cbfstool/rmodtool (link)
    HOSTCC     cbfstool/ifwitool.o
    HOSTCC     cbfstool/ifwitool (link)

Built emulation/qemu-riscv (QEMU RISCV)
```


#### 7. Test image in QEMU

Firstly you need to convert `coreboot.rom` to an ELF that Qemu can load
```sh
$ util/riscv/make-spike-elf.sh build/coreboot.rom build/coreboot.elf
```

Now you can run your image in Qemu

```sh
$ qemu-system-riscv64 -M virt -m 1024M -nographic -kernel build/coreboot.elf
```

You should see similar output ending with `Payload not loaded`

```
coreboot-4.12-2423-g4c44108423 Wed Aug 26 08:52:53 UTC 2020 bootblock starting (log level: 7)...
FMAP: Found "FLASH" version 1.1 at 0x20000.
FMAP: base = 0x0 size = 0x400000 #areas = 4
FMAP: area COREBOOT found @ 20200 (4062720 bytes)
CBFS: Locating 'fallback/romstage'
CBFS: Found @ offset 80 size 372e
BS: bootblock times (exec / console): total (unknown) / 0 ms


coreboot-4.12-2423-g4c44108423 Wed Aug 26 08:52:53 UTC 2020 romstage starting (log level: 7)...
RAMDETECT: Found 1020 MiB RAM
CBMEM:
IMD: root @ 0xbffff000 254 entries.
IMD: root @ 0xbfffec00 62 entries.
FMAP: area COREBOOT found @ 20200 (4062720 bytes)
CBFS: Locating 'fallback/ramstage'
CBFS: Found @ offset 3800 size 5adc
BS: romstage times (exec / console): total (unknown) / 0 ms


coreboot-4.12-2423-g4c44108423 Wed Aug 26 08:52:53 UTC 2020 ramstage starting (log level: 7)...
Enumerating buses...
RAMDETECT: Found 1020 MiB RAM
CBMEM:
IMD: root @ 0xbffff000 254 entries.
IMD: root @ 0xbfffec00 62 entries.
Root Device scanning...
CPU_CLUSTER: 0 enabled
scan_bus: bus Root Device finished in 0 msecs
done
Allocating resources...
Reading resources...
CPU_CLUSTER: 0 missing read_resources
Done reading resources.
Done setting resources.
Done allocating resources.
Enabling resources...
done.
Initializing devices...
Devices initialized
Finalize devices...
Devices finalized
Writing coreboot table at 0xbffdc000
 0. 0000000080400000-0000000080431fff: RAM
 1. 0000000080432000-0000000080446fff: RAMSTAGE
 2. 0000000080447000-0000000081431fff: RAM
 3. 0000000081432000-0000000081432fff: RAMSTAGE
 4. 0000000081433000-00000000bffdbfff: RAM
 5. 00000000bffdc000-00000000bfffffff: CONFIGURATION TABLES
FMAP: area COREBOOT found @ 20200 (4062720 bytes)
Wrote coreboot table at: 0xbffdc000, 0x168 bytes, checksum f756
coreboot table: 384 bytes.
IMD ROOT    0. 0xbffff000 0x00001000
IMD SMALL   1. 0xbfffe000 0x00001000
CONSOLE     2. 0xbffde000 0x00020000
COREBOOT    3. 0xbffdc000 0x00002000
IMD small region:
  IMD ROOT    0. 0xbfffec00 0x00000400
FMAP: area COREBOOT found @ 20200 (4062720 bytes)
CBFS: Locating 'fallback/payload'
CBFS: 'fallback/payload' not found.
Payload not loaded.

```


## Summary


If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

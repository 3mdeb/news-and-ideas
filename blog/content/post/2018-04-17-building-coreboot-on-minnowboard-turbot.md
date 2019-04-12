---
author: bartek.pastudzki
cover: /covers/turbot-quad-board.png
layout: post
title: "Building UEFI based firmware on MinnowBoard"
date: 2018-03-28 22:14:55 +0200
published: true

tags:
    - uefi
    - minnowboard
    - microcode
categories:
    - firmware

---

Building coreboot on well supported platform such as Bay Trail is quite
straightforward task, however we need to remember about some things in
order to have coreboot working. First of all we need to provide up-to-date
microcode and FSP (Firmware Support Package), which are not included in
coreboot source tree and coreboot build system won't complain about it.
Second thing is that Bay Trail has TXE firmware on the same ROM as boot firmware
so we have to make sure that we won't corrupt it because it would brick the
platform. Except those we have standard procedure, we need to get a toolchain.

Microcode
---------

Newest microcode can be found on https://cloud.3mdeb.com/index.php/s/0z5R4zMp605s7WK/download
We have to provide it because it's a condition for warranty for CPU.
It is provided as Intel-syntax assembly file with microcode as though
it was ordinary data:

```asm
dd 000000001h ; Header Version
dd 000000321h ; Patch ID
dd 001142014h ; DATE
dd 000030673h ; CPUID
dd 0984d6012h ; Checksum
dd 000000001h ; Loader Version
dd 000000001h ; Platform ID
dd 00000cbd0h ; Data size
dd 00000cc00h ; Total size
dd 000000000h ; reserved
dd 000000000h ; reserved
dd 000000000h ; reserved
dd 000000000h
dd 0000000a1h
dd 000020001h
dd 000000321h
```

details of it's structure are confidential. However for coreboot we need to
provide it as comma separated list of values in C-style format, like this:

```C
0x000000001,
0x00000021d,
0x008122013,
0x000030672,
0x0a565e78c,
0x000000001,
0x000000002,
0x00000cbd0,
0x00000cc00,
0x000000000,
0x000000000,
0x000000000,
0x000000000,
0x0000000a1,
```

We can easly download and convert it using simple script:

```bash
wget 'http://intel.ly/2yStb2e' -O MM-firmware.zip
unzip MM-firmware.zip
cd MinnowBoard_MAX-0.97-Binary.Objects/Vlv2MiscBinariesPkg/Microcode
for f in *.inc ; do
    name=${f%.inc}
    awk '{gsub( /h.*$/, "", $2 ); print "0x" $2 ","; }' $f \
        > $name.h
done
cp *.h ../../../
```

FSP (Firmware Support Package)
---

FSP is binary package from Intel dedicated to firmware developers containing
most important platform initialization (including IP). However there is non-FSP
version of coreboot for Bay Trail however it won't work without MRC (Memory
Reference Code) which is confidential (available for trusted vendors) so we won't
cover this option.

Intel sites redirect to https://github.com/IntelFsp/FSP (branch BayTrail) where
you can find it. We are interested mostly in BayTrailFspBinPkg/FspBin/BayTrailFSP.fd
which is file we have to provide to coreboot. FSP can be configured using BCT
(Binary Configuration Tools), which is optional — needed to enable Secure boot
and FastBoot. The tool is available only as Windows application, but works well
using Wine too.

In the same package you can find VgaBIOS which can be used too if you want to
use graphic card: BayTrailFspBinPkg/Vbios/Vga.dat

ME region
---------

Despite the name, ME region contains TXE firmware, as mentioned, we must not
corrupt it. The simplest way to avoid that is to read ROM layout from
original firmware image. In `utils/ifdtool` of coreboot source tree we can
find program for reading layout from ROM image. The image can be taken from
firmware package or read using flashrom, using SPI interface:

```sh
sudo flashrom -p dediprog -r minnow.rom
```

Note that you may need to adjust `-p` option according to used SPI programmer.
Use `-p internal` if you use MinnowBoard's internal programmer.

```sh
~/code/coreboot> cd util/ifdtool/
~/code/coreboot/util/ifdtool> make
~/code/coreboot/util/ifdtool> ./ifdtool -f ../../mb.layout minnow.rom
File minnow.bin is 8388608 bytes
Wrote layout to ../../mb.layout
~/code/coreboot/util/ifdtool> cat ../../mb.layout
00000000:00000fff fd
00400000:007fffff bios
00001000:003fffff me
00000000:00000fff gbe
```

While flashing coreboot we should inform flashrom only to write `bios` region

```sh
sudo flashrom -l mb.layout -i bios -p dediprog -w build/coreboot.rom
```

Be careful because this layout may vary between versions, so we should check it
for each version separately. For mass reproduction it could be usefull to read
original firmware, apply coreboot on that image and flash it as a whole on each
device.

In case of using wrong layout resulting in bricked platform flash stock firmware
(or backup), reread layout and flash coreboot again.

Toolchain
---------

coreboot needs specific versions of toolchain components, we have to take care
of this. Makefile has rule for building toolchain:

```sh
# make sure, we have all dependencies:
apt-get install git build-essential gnat flex bison libncurses5-dev wget zlib1g-dev

make crossgcc-i386
```

Despite the fact that that we usualy want to boot 64-bit OS, coreboot code is
compiled for 32-bit. Moreover we have noticed that there's problem with libpayload
on 64-bit toolchain.

However this procedure may be problematic. It may take much time on older machine
and compilation may fail on some GCC versions. It's much easier to use docker,
there is dedicated docker image with toolchain for coreboot:

```
sudo docker pull coreboot/coreboot-sdk:1.50
```

If you don't have intalled docker, please folow official guide:
https://docs.docker.com/install/

There is also our image with additional FSP package (under default path):
`3mdeb/coreboot-trainings-sdk:latest`.

To run shell in docker environment:

```sh
docker run -u root -it -v $PWD:/home/coreboot/coreboot --rm  \
    coreboot/coreboot-sdk:1.50 /bin/bash
```
NOTE: remember that it works as root, so you may want to change owner of new files
after build. This command must be ran in coreboot direcotory (there is `$PWD` in
mount parameter `-v`).

Configuration
-------------

coreboot is configured using `make menuconfig` similar to Linux Kernel (needs
ncurses library). First in `Mainboard` menu we set platform:

```
Mainboard vendor (Intel)  --->
Mainboard model (Minnow Max)  --->
```

Except of this we have to configure microcode and enable FSP in `Chipset` menu:

```
Include CPU microcode in CBFS (Include external microcode header files)  --->
(M0130673321.h  M0130679901.h  M023067221D.h) List of space separated microcode header

[*] Use Intel Firmware Support Package
(../intel/fsp/baytrail/BAYTRAIL_FSP.fd) Intel FSP binary path and filename (NEW)
```

If we want to use VgaBIOS, we can configure it in `Devices`:

```
 [*] Add a VGA BIOS image
(../intel/cpu/baytrail/vbios/Vga.dat) VGA BIOS path and filename (NEW)
```

On x86 by default, coreboot chooses `SeaBIOS` as a payload so that it provides
legacy BIOS interface. You may want to use one of other options: GRUB (well
known, robust Open Source boot loader), Tianocore (UEFI), etc.

This is minimal configuration for MinnowBoard. However you probably want
to decrease log level (defualt 8:SPEW is much too verbose) in `Console`
menu:

```
Default console log level (5: NOTICE)  --->
```

Build & Flash
-------------

When configuration is complete, we can save it and run:

```
make
```

If everything goes well, output should end like this:

```
    CBFSPRINT  coreboot.rom

Name                           Offset     Type           Size   Comp
cbfs master header             0x0        cbfs header        32 none
fallback/romstage              0x80       stage           30204 none
cpu_microcode_blob.bin         0x7700     microcode           0 none
fallback/ramstage              0x7780     stage           58614 none
config                         0x15cc0    raw               118 none
revision                       0x15d80    raw               582 none
cmos_layout.bin                0x16000    cmos_layout      1208 none
fallback/dsdt.aml              0x16500    raw             12528 none
fallback/payload               0x19640    payload         68158 none
payload_config                 0x2a0c0    raw              1593 none
payload_revision               0x2a740    raw               239 none
(empty)                        0x2a880    null          2969432 none
bootblock                      0x2ff800   bootblock        1720 none
    HOSTCC     cbfstool/ifwitool.o
    HOSTCC     cbfstool/ifwitool (link)

Built intel/minnowmax (Minnow Max)
```

So we can flash it. If you are using docker image, remember that it doesn't
contain `flashrom` so you have to do that outside container:

```
sudo flashrom -l mb.layout -i bios -p dediprog -w build/coreboot.rom
```

Conclusion
----------

This procedure is pretty straightforward, but in practice turns out to cause
much trouble at first time. It also covers only most basic options. We are
open to help if you have problem with that. Also if you don't want to do that
we provide such a service.

Building EDK2 based firmware for MinnowBoard
============================================

There are some options to build firmware for MinnowBoard, a Bay-Trail-based
SBC (Single Board Computer) from Intel. We usually prefer coreboot as simplest
and fastest, open source solution, but sometimes we want to have UEFI
interface.

UEFI itself doesn't cover whole boot procedure, so its open source reference
implementation, EDK2 is not enough to build firmware for hardware plafrorms so
we need to provide PI (Platform Initialization) phase implementation. In EDK2
repository we can find only implementation for virtualization (OVMF), this
option is covered in [this article](https://3mdeb.com/firmware/uefi-application-development-in-ovmf/#.WsOfOkuxVuE).

coreboot could be used to provide PI phase, but this procedure is mostly covered
in [the article on building coreboot for MinnowBoard](#Umiescic_link_tutaj), but we
need to choose Tianocore payload. In this article we cover building UEFI
firmware using binary objects from Intel. Whole procedure can be done using
following script:


```
#!/bin/sh -xe

if [[ "$1" == "init" ]]; then
    docker pull 3mdeb/edk2
    git clone https://github.com/tianocore/edk2.git -b vUDK2017
    git clone https://github.com/tianocore/edk2-platforms.git -b devel-MinnowBoardMax-UDK2017
    wget https://firmware.intel.com/sites/default/files/MinnowBoard_MAX-0.97-Binary.Objects.zip
    unzip MinnowBoard_MAX-0.97-Binary.Objects.zip
    cd edk2/CryptoPkg/Library/OpensslLib
    git clone -b OpenSSL_1_1_0-stable https://github.com/openssl/openssl openssl
    cd ../../../..
fi

docker run --rm -it -w /home/edk2 -v $PWD/edk2:/home/edk2/edk2 \
    -v $PWD/edk2-platforms:/home/edk2/edk2-platforms \
    -v $PWD/MinnowBoard_MAX-0.97-Binary.Objects:/home/edk2/silicon \
    -v $PWD/ccache:/home/edk2/.ccache \
    3mdeb/edk2 /bin/bash -c 'cd edk2-platforms/Vlv2TbltDevicePkg/ &&
        source Build_IFWI.sh MNW2 Debug'
```

in edk2-platforms repository we find open-source part of PI for various
platforms including MinnowBoard. However, we need also some closed code from
Intel's site, which contains IP (Intelectual Property). Finally we have to
fetch OpenSSL, which is another dependecy.

When all those components are ready, we can build. We use dedicated docker
images to avoid toolchain compatibility problems. So running docker we mount
`edk2` (main repository), `edk2-platforms` and cache directory to respective
mount points in the image (build script assume that they are all located in
the same directory). So we enter `edk2-platforms/Vlv2TbltDevicePkg/` and run
`source Build_IFWI.sh MNW2 Debug` (for DEBUG version). If the build is successfully
complete, we can find the image in
`edk2-platforms/Vlv2TbltDevicePkg/Stitch/MNW2MAX_X64_D_0097_01_GCC.bin`.

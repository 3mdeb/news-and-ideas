---
author: Bartek Lew
layout: post
title: Building EDK2 based firmware for MinnowBoard
date: 2018-04-03 22:14:55 +0200
comments: true
categories:
    - minnowboard
    - firmware
---

Building EDK2 based firmware for MinnowBoard
============================================

There are some options to build firmware for MinnowBoard, a Bay Trail based
SBC (Single Board Computer) from Intel. We prefer usually coreboot as simplest
and fastest, open source solution, but sometimes we want to have UEFI
interface.

UEFI itself doesn't cover whole boot procedure, so its open source reference
implementation, EDK2 is not enough to build firmware for hardware plafrorm,
we need to provide PI (Platform Initialization) phase implementation. In EDK2
repository we can find only implementation for virtualization (OVMF), this
option is covered in [this article](https://3mdeb.com/firmware/uefi-application-development-in-ovmf/#.WsOfOkuxVuE).

coreboot could be used to provide PI phase, but this procedure is mostly covered
in [article on building coreboot for MinnowBoard](#Umiescic_link_tutaj), only we
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
platforms including MinnowBoard. However we need also some closed code from
Intel's site, which contains IP (Intelectual Property). Finaly we have to
fetch OpenSSL, which is another dependecy.

When all those components are ready, we can build. We use dedicated docker
images to avoid toolchain compatibility problems. So running docker we mount
`edk2` (main repository), `edk2-platforms` and cache directory to respective
mount points in the image (build script assume that they are all located in
the same directory). So we enter `edk2-platforms/Vlv2TbltDevicePkg/` and run
`source Build_IFWI.sh MNW2 Debug` (for DEBUG version). If build is successfully
complete, we can find the image in
`edk2-platforms/Vlv2TbltDevicePkg/Stitch/MNW2MAX_X64_D_0097_01_GCC.bin`.

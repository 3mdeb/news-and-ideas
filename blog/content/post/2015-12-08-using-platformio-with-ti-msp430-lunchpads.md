---
ID: 62931
title: Using PlatformIO with TI MSP430 LunchPads
author: piotr.krol
post_excerpt: ""
layout: post
published: true
date: 2015-12-08 13:16:36
archives: "2015"
tags:
  - embedded
  - MSP430
categories:
  - Firmware
  - IoT
---


[PlatformIO](http://platformio.org/) is very interesting project that aim to
solve very important problem of configuring deployment environment for embedded
systems. IMHO good approach is to focus on modularity (various IDE can be used,
even Vim) and simplicity (in best case 2 command should be enough to deploy
first code).

Recent years we have explosion of bootstrapping applications (ie.vagrant,
puppet). Most of them seems to follow git-like command line interface and
getting a lot of attention from programmers community. PlatformIO is promising
project for all Embedded Software developers who in the era of IoT came from
Linux systems.

It take some time to try PlatformIO using real hardware. Luckily on my desk
there are 2 supported boards gathering dust, which I would like to try in this
post.

![img](/img/msp430.jpg)

`MSP-EXP430F5529LP` on the left and `MSP-EXP430FR5969` on the right.

## Installation on Debian

I highly recommend using
[virtualenv](https://virtualenv.readthedocs.org/en/latest/) for any custom
python application.

At the beginning I simply follow
[Getting Started](http://platformio.org/#!/get-started) page.

```bash
pip install -U pip setuptools
pip install -U platformio
```

What configuration I should use for my boards ?

```bash
[13:38:34] pietrushnic:msp430 $ platformio boards|grep 5969
lpmsp430fr5969        msp430fr5969   8Mhz      64Kb    1Kb    TI LaunchPad w/ msp430fr5969
[13:38:41] pietrushnic:msp430 $ platformio boards|grep 5529
lpmsp430f5529         msp430f5529    16Mhz     128Kb   1Kb    TI LaunchPad w/ msp430f5529 (16MHz)
lpmsp430f5529_25      msp430f5529    25Mhz     128Kb   1Kb    TI LaunchPad w/ msp430f5529 (25MHz)
```

So it looks like `5529` have 2 flavours. According to `Energia` 16MHz option is
for backward compatibility. Let's use recent 25MHz config.

```bash
mkdir msp430
cd msp430
platformio init --board=lpmsp430fr5969 --board=lpmsp430f5529_25
```

PlatformIO first ask if we want auto-uploading successfully built project, so I
answered y. Then inform about creating some directories and `platformio.ini`
file. After confirming toolchain, downloading starts.

## Problems with MSP430F5529LP

### Lack of main.cpp

If you run PlatformIO without any source code in `src` directory you will get
error message like this:

```bash
.pioenvs/lpmsp430f5529_25/libFrameworkEnergia.a(main.o): In function `main':
/home/pietrushnic/projects/3mdeb/msp430/.pioenvs/lpmsp430f5529_25/FrameworkEnergia/main.cpp:7: undefined reference to `setup'
/home/pietrushnic/projects/3mdeb/msp430/.pioenvs/lpmsp430f5529_25/FrameworkEnergia/main.cpp:10: undefined reference to `loop'
collect2: ld returned 1 exit status
scons: *** [.pioenvs/lpmsp430f5529_25/firmware.elf] Error 1
```

Of course adding main.cpp to src directory fix this issue. As sample code you
may use
[MSP430F55xx_1.c](http://dev.ti.com/tirex/api/download?file=mspware%2Fmspware__2.30.00.49%2Fexamples%2Fdevices%2FMSP430F5xx_6xx%2FMSP430F55xx_Code_Examples%2FC%2FMSP430F55xx_1.c&source=content)

### libmsp430.so: cannot open shared object file

Next problem is with `libmsp430.so` which is not visible by `mspdebug`, but was
installed by PlatformIO in
`$HOME/.platformio/packages/toolchain-timsp430/bin/libmsp430.so`.

Running:

```bash
export LD_LIBRARY_PATH=$HOME/.platformio/packages/toolchain-timsp430/bin/
```

before calling `platformio` fix problem. For some users even better would be to
make `libmsp430.so` accessible system wide:

```bash
sudo cp $HOME/.platformio/packages/toolchain-timsp430/bin/libmsp430.so /usr/lib
```

### tilib: device initialization failed

If you didn't use your MSP430 for a while there can be problem like this:

```bash
$HOME/.platformio/packages/tool-mspdebug/mspdebug tilib --force-reset "prog .pioenvs/lpmsp430f5529_25/firmware.hex"
MSPDebug version 0.20 - debugging tool for MSP430 MCUs
Copyright (C) 2009-2012 Daniel Beer <dlbeer@gmail.com>
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

MSP430_GetNumberOfUsbIfs
MSP430_GetNameOfUsbIf
Found FET: ttyACM0
MSP430_Initialize: ttyACM0
FET firmware update is required.
Re-run with --allow-fw-update to perform a firmware update.
tilib: device initialization failed
scons: *** [upload] Error 255
```

Fix for that according to error log should be like this:

```bash
$HOME/.platformio/packages/tool-mspdebug/mspdebug tilib --allow-fw-update
```

But this can cause additional problems that I reported
[here](https://e2e.ti.com/support/development_tools/code_composer_studio/f/81/p/456610/1710377#1710377).
I finally managed to fix problem using hints from
[Agla Blog](http://www.aglaglobal.com/content/recover-broken-fet-msp430f5529-launchpad-after-ccs-crashes-during-firmware-update).

Because `gcc-msp430` was removed from Debian Sid we have to use compiler
delivered by `platformio` to test blinky example from Agla blog:

```bash
$HOME/.platformio/packages/toolchain-timsp430/bin/msp430-gcc -mmcu=msp430f5529 -mdisable-watchdog blink.c
```

## Problems with MSP430FR5969

I experienced very similar problems with `FR5969`. Unfortunately above procedure
led me to:

```bash
MSPDebug version 0.23 - debugging tool for MSP430 MCUs
Copyright (C) 2009-2015 Daniel Beer <dlbeer@gmail.com>
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
Chip info database from MSP430.dll v3.3.1.4 Copyright (C) 2013 TI, Inc.

Using old API
MSP430_GetNumberOfUsbIfs
MSP430_GetNameOfUsbIf
Found FET: ttyACM0
MSP430_Initialize: ttyACM0
Firmware version is 30301004
MSP430_VCC: 3000 mV
MSP430_OpenDevice
tilib: MSP430_OpenDevice: Unknown device (error = 5)
tilib: device initialization failed
```

### Building libmsp430.so

This probably means that default `libmsp430.so`, downloaded probably from
`Energia` project, doesn't support `FR5969`. So I tried build `libmsp430.so` by
myself:

```bash
sudo apt-get install libboost-system-dev libboost-filesystem-dev
git clone https://github.com/pietrushnic/MSPDebugStack_OS_Package.git -b libmsp430-fr5969
git clone https://github.com/signal11/hidapi.git
cd hidapi
./bootstrap
./configure --with-pic
make
cp ./libusb/hid.o ../MSPDebugStack_OS_Package/ThirdParty/lib64
cp ./hidapi/hidapi.h ../MSPDebugStack_OS_Package/ThirdParty/include
cd ../MSPDebugStack_OS_Package
make
sudo cp libmsp430.so /usr/lib
```

This improved situation, but give:

```bash
MSPDebug version 0.23 - debugging tool for MSP430 MCUs
Copyright (C) 2009-2015 Daniel Beer <dlbeer@gmail.com>
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
Chip info database from MSP430.dll v3.3.1.4 Copyright (C) 2013 TI, Inc.

Using new (SLAC460L+) API
MSP430_GetNumberOfUsbIfs
MSP430_GetNameOfUsbIf
Found FET: ttyACM0
MSP430_Initialize: ttyACM0
FET firmware update is required.
Starting firmware update (this may take some time)...
Initializing bootloader...
Programming new firmware...
    75 percent done
    84 percent done
    84 percent done
    91 percent done
    96 percent done
    99 percent done
   100 percent done
   100 percent done
Initializing bootloader...
Programming new firmware...
     4 percent done
    20 percent done
    36 percent done
    52 percent done
    68 percent done
    84 percent done
   100 percent done
Update complete
Done, finishing...
tilib: MSP430_FET_FwUpdate: MSP-FET / eZ-FET legacy module update failed (error = 75)
tilib: device initialization failed
```

I'm not sure why this message appear, but when tried 2nd time I finally get
debugger prompt, what means that process finished correctly and we can access
`FR5969`.

## Final test

### MSP430F5529LP

Please download
[MSP430F55xx_1.c](http://dev.ti.com/tirex/api/download?file=mspware%2Fmspware__2.30.00.49%2Fexamples%2Fdevices%2FMSP430F5xx_6xx%2FMSP430F55xx_Code_Examples%2FC%2FMSP430F55xx_1.c&source=content)
and save it as `src/main.c`. Then run:

```bash
platformio run -e lpmsp430f5529_25
```

If you see blinking red `P1.0 LED1` then everything works as expected.

### MSP430FR5969

Please download
[msp430fr59xx_1.c](http://dev.ti.com/tirex/api/download?file=mspware%2Fmspware__2.30.00.49%2Fexamples%2Fdevices%2FMSP430FR5xx_6xx%2FMSP430FR596x_MSP430FR595x_MSP430FR594x_MSP430FR586x_MSP430FR585x_MSP430FR584x_Code_Examples%2FC%2Fmsp430fr59xx_1.c&source=content)
and save it as `src/main.c`. Then run:

```bash
platformio run -e lpmsp430fr5969
```

If you see blinking green `LED2` then everything works as expected.

## Summary

I hope that this post was useful for you and you learn some things. If you feel
that this knowledge was valuable please share, if you experienced some other
problems please let me know, so I can improve content of this post.

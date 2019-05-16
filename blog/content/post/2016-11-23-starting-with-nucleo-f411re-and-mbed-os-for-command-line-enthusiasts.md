---
ID: 63026
title: >
  Starting with Nucleo-F411RE and mbed OS
  for command line enthusiasts
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/starting-with-nucleo-f411re-and-mbed-os-for-command-line-enthusiasts/
published: true
date: 2016-11-23 16:01:48
year: "2016"
tags:
  - embedded
  - linux
  - Mbed
  - Nucleo
  - Cortex-M4
categories:
  - Firmware
  - IoT
---
When I first time read about mbed OS I was really sceptical, especially idea of
having web browser as my IDE and compiler in the cloud seems to be very scary
to me. ARM engineers proved to provide high quality products, but this was not
enough to me. Then I heard very good words about mbed OS IDE from Jack Ganssle,
this was still not enough. Finally customers started to ask about this RTOS and
I had to look deeper.

There are other well known OSes, but most of them have issues:

* FreeRTOS - probably most popular, GPL license with exceptions and
restrictions, doesn't have drivers provided this is mostly filled by MCU vendor
in SDK. This can lead to problems ie. lack of well supported DTLS library or
specific communication protocol. It often happen that MCU vendors doesn't
maintain community, so code base grows internally and is not revealed.

* RIoT - well known and popular, LGPL 2.1 license what is typically problematic
when your work affect system core. Contain lot of features, but number of
supported platforms is limited. Targeted at academics and hobbyists.

* Zephyr - great initiative backed by Linaro, Linux Foundation,
Qualcomm/NXP/Freescale and Intel. License Apache 2.0, which IMO is much better
for embedded then (L)GPL. Unluckily this is brand new and support is very
limited. For sure porting new platform to Zephyr can be great fun and
principles are very good, but support is very limited and it will take time to
make it mature enough to seriously consider in commercial product.

* mbed OS - this one looks really great. Apache 2.0. Tons of drivers, clean
environment, huge, good-looking and well written documentation. Wide range of
hardware is already supported and it came from designed of most popular core in
the world. Community is big but it is still not so vibrant as ie. RIoT.

Below I want to present Linux user experience from my first contact with mbed
OS on Nucleo-F411RE platform.

{% img center /assets/images/nucleo-F411RE.jpg 640 400 'image' 'images' %}

## First contact

I have to say that at first glance whole system is very well documented with
great look and feel. [Main site](https://www.mbed.com/en/) requires 2 clicks to
be in correct place for Embedded System Engineer. In general we have 3 main
path when we choose developer tools: Online IDE, mbed CLI and 3rd party. Last
covers blasting variety of IDEs including Makefile and Eclipse CDT based GCC
support.

Things that are annoying during first contact we web page:

* way to contribute documentation is not clear
* there is no description how to render documentation locally
* can't upload avatar on forum - no information what format and resolution is
  supported

But those are less interesting things. Going back to development environment
for me 2 options where interesting mbed CLI and plain Makefile.

## mbed CLI

I already have setup vitrualenv for Python 2.7:

```
pip install mbed-cli
```

First thing to like in `mbed-cli` is that it was implemented in Python. Of
course this is very subjective since I'm familiar with Python, but it good to
know that I can hack something that doesn't work for me. Is is [Open Source](https://github.com/ARMmbed/mbed-cli).

I also like the idea of mimicking git subcommands. More information about mbed
CLI can be found in
[documentation](https://docs.mbed.com/docs/mbed-os-handbook/en/5.2/dev_tools/cli/#using-mbed-cli).

It is also great that mbed CLI tries to manage whole program dependencies in
structured way, so no more hassle with external libraries versioning and trying
to keep sanity when you have to clone your development workspace. Of course
this have to be checked on battlefield, since documentation promise may be not
enough.

So first thing that hit me when trying to move forward was this message:

```
$ mbed new mbed-os-program                                                  
[mbed] Creating new program "mbed-os-program" (git)
[mbed] Adding library "mbed-os" from "https://github.com/ARMmbed/mbed-os" at branch latest
[mbed] Updating reference "mbed-os" -> "https://github.com/ARMmbed/mbed-os/#d5de476f74dd4de27012eb74ede078f6330dfc3f"
[mbed] Auto-installing missing Python modules...
[mbed] WARNING: Unable to auto-install required Python modules.
---
[mbed] WARNING: -----------------------------------------------------------------
[mbed] WARNING: The mbed OS tools in this program require the following Python modules: prettytable, intelhex, junit_xml, pyyaml, mbed_ls, mbed_host_tests, mbed_greentea, beautifulsoup4, fuzzywuzzy
[mbed] WARNING: You can install all missing modules by running "pip install -r requirements.txt" in "/home/pietrushnic/tmp/mbed-os-program/mbed-os"
[mbed] WARNING: On Posix systems (Linux, Mac, etc) you might have to switch to superuser account or use "sudo"
```

This appeared to be some problem with my distro:

```
(...)
    ext/_yaml.c:4:20: fatal error: Python.h: No such file or directory
     #include "Python.h"
                        ^
    compilation terminated.
(...)
```

This indicate lack of `python2.7-dev` package, so:

```
sudo aptitude update && sudo aptitude dist-upgrade
sudo aptitude install python2.7-dev
```

After verifying that you can create program, let's try to get well known
hello world for embedded:

```
mbed import https://github.com/ARMmbed/mbed-os-example-blinky
```

## Toolchain

To compile example we need toolchain. The easiest way would be to get distro package:

```console
sudo apt-get install gcc-arm-none-eabi
```

Now you should set toolchain configuration, if you won't error like this may
pop-up:

```console
$ mbed compile -t GCC_ARM -m NUCLEO_F411RE
Building project mbed-os-example-blinky (NUCLEO_F411RE, GCC_ARM)
Scan: .
Scan: FEATURE_BLE
Scan: FEATURE_UVISOR
Scan: FEATURE_LWIP
Scan: FEATURE_COMMON_PAL
Scan: FEATURE_THREAD_BORDER_ROUTER
Scan: FEATURE_LOWPAN_ROUTER
Scan: FEATURE_LOWPAN_BORDER_ROUTER
Scan: FEATURE_NANOSTACK
Scan: FEATURE_THREAD_END_DEVICE
Scan: FEATURE_NANOSTACK_FULL
Scan: FEATURE_THREAD_ROUTER
Scan: FEATURE_LOWPAN_HOST
Scan: FEATURE_STORAGE
Scan: mbed
Scan: env
Compile [  0.4%]: AnalogIn.cpp
[ERROR] In file included from ./mbed-os/drivers/AnalogIn.h:19:0,
                 from ./mbed-os/drivers/AnalogIn.cpp:17:
./mbed-os/platform/platform.h:22:19: fatal error: cstddef: No such file or directory
compilation terminated.

[mbed] ERROR: "python" returned error code 1.
[mbed] ERROR: Command "python -u /home/pietrushnic/tmp/mbed-os-example-blinky/mbed-os/tools/make.py -t GCC_ARM -m NUCLEO_F411RE --source . --build ./BUILD/NUCLEO_F411RE/GCC_ARM" in "/home/pietrushnic/tmp/mbed-os-example-blinky"
---
```

Toolchain configuration is needed:

```console
mbed config --global GCC_ARM_PATH "/usr/bin"
```

But then we get another problem:

```console
$ mbed compile -t GCC_ARM -m NUCLEO_F411RE    
Building project mbed-os-example-blinky (NUCLEO_F411RE, GCC_ARM)
Scan: .
Scan: FEATURE_BLE
Scan: FEATURE_UVISOR
Scan: FEATURE_LWIP
Scan: FEATURE_COMMON_PAL
Scan: FEATURE_THREAD_BORDER_ROUTER
Scan: FEATURE_LOWPAN_ROUTER
Scan: FEATURE_LOWPAN_BORDER_ROUTER
Scan: FEATURE_NANOSTACK
Scan: FEATURE_THREAD_END_DEVICE
Scan: FEATURE_NANOSTACK_FULL
Scan: FEATURE_THREAD_ROUTER
Scan: FEATURE_LOWPAN_HOST
Scan: FEATURE_STORAGE
Scan: mbed
Scan: env
Compile [  1.9%]: main.cpp
[ERROR] In file included from ./mbed-os/rtos/Thread.h:27:0,
                 from ./mbed-os/rtos/rtos.h:28,
                 from ./mbed-os/mbed.h:22,
                 from ./main.cpp:1:
./mbed-os/platform/Callback.h:21:15: fatal error: new: No such file or directory
compilation terminated.

[mbed] ERROR: "python" returned error code 1.
[mbed] ERROR: Command "python -u /home/pietrushnic/tmp/mbed-os-example-blinky/mbed-os/tools/make.py -t GCC_ARM -m NUCLEO_F411RE --source . --build ./BUILD/NUCLEO_F411RE/GCC_ARM" in "/home/pietrushnic/tmp/mbed-os-example-blinky"
---
```

I'm not sure what is the reason but I expect lack of `g++-arm-none-eabi` but it
is not provided by Debian at this point. So its time to switch to toolchain
downloaded directly from [GNU ARM Embedded Toolchain page](https://launchpad.net/gcc-arm-embedded).

```console
wget https://launchpadlibrarian.net/287101520/gcc-arm-none-eabi-5_4-2016q3-20160926-linux.tar.bz2
tar xvf gcc-arm-none-eabi-5_4-2016q3-20160926-linux.tar.bz2
```

Then change your global mbed configuration:

```console
mbed config --global GCC_ARM_PATH "/path/to/gcc-arm-none-eabi-5_4-2016q3/bin"
```

Now compilation works without problems:

```console
$ mbed compile -t GCC_ARM -m NUCLEO_F411RE
Building project mbed-os-example-blinky (NUCLEO_F411RE, GCC_ARM)
Scan: .
Scan: FEATURE_BLE
Scan: FEATURE_UVISOR
Scan: FEATURE_LWIP
Scan: FEATURE_COMMON_PAL
Scan: FEATURE_THREAD_BORDER_ROUTER
Scan: FEATURE_LOWPAN_ROUTER
Scan: FEATURE_LOWPAN_BORDER_ROUTER
Scan: FEATURE_NANOSTACK
Scan: FEATURE_THREAD_END_DEVICE
Scan: FEATURE_NANOSTACK_FULL
Scan: FEATURE_THREAD_ROUTER
Scan: FEATURE_LOWPAN_HOST
Scan: FEATURE_STORAGE
Scan: mbed
Scan: env
Compile [  1.9%]: BusIn.cpp
Compile [  2.3%]: AnalogIn.cpp
Compile [  2.7%]: BusInOut.cpp
(...)
Compile [ 99.2%]: serial_api.c
[Warning] serial_api.c@333,35: unused variable 'tmpval' [-Wunused-variable]
[Warning] serial_api.c@821,27: unused variable 'tmpval' [-Wunused-variable]
[Warning] serial_api.c@823,27: unused variable 'tmpval' [-Wunused-variable]
[Warning] serial_api.c@825,27: unused variable 'tmpval' [-Wunused-variable]
[Warning] serial_api.c@827,27: unused variable 'tmpval' [-Wunused-variable]
[Warning] serial_api.c@954,23: unused variable 'tmpval' [-Wunused-variable]
Compile [ 99.6%]: stm_spi_api.c
Compile [100.0%]: test_env.cpp
Link: mbed-os-example-blinky
Elf2Bin: mbed-os-example-blinky
+--------------------+-------+-------+------+
| Module             | .text | .data | .bss |
+--------------------+-------+-------+------+
| Fill               |   130 |     4 |    5 |
| Misc               | 21471 |  2492 |  100 |
| drivers            |   118 |     4 |  100 |
| hal                |   536 |     0 |    8 |
| platform           |  1162 |     4 |  269 |
| rtos               |    38 |     4 |    4 |
| rtos/rtx           |  5903 |    20 | 6870 |
| targets/TARGET_STM |  5950 |     4 |  724 |
| Subtotals          | 35308 |  2532 | 8080 |
+--------------------+-------+-------+------+
Allocated Heap: unknown
Allocated Stack: unknown
Total Static RAM memory (data + bss): 10612 bytes
Total RAM memory (data + bss + heap + stack): 10612 bytes
Total Flash memory (text + data + misc): 37840 bytes

Object file test_env.o is not unique! It could be made from: ./mbed-os/features/frameworks/greentea-client/source/test_env.cpp /home/pietrushnic/tmp/mbed-os-example-blinky/mbed-os/features/unsupported/tests/mbed/env/test_env.cpp
Image: ./BUILD/NUCLEO_F411RE/GCC_ARM/mbed-os-example-blinky.bin
```

So we have binary now we would like to deploy it to target.

## Test real hardware

To test build binary on Nucleo-F411RE the only thing is to connect board
through mini USB and copy build result to mounted directory. In my case it was
something like this:

```console
cp BUILD/NUCLEO_F411RE/GCC_ARM/mbed-os-example-blinky.bin /media/pietrushnic/NODE_F411RE/
```

This is pretty weird interface for programming, but simplified to the maximum.

## Serial console example

Modify your `main.cpp` with something like:

```c
#include "mbed.h"

DigitalOut led1(LED1);
Serial pc(USBTX, USBRX);

// main() runs in its own thread in the OS
// (note the calls to Thread::wait below for delays)
int main() {
    int i = 0;

    while (true) {
        pc.printf("%d\r\n", i);
        i++;
        led1 = !led1;
        Thread::wait(1000);
    }
}
```

Recompile and copy result as it was described above. To connect to device
please check your dmesg:

```console
$ dmesg|grep tty
[    0.000000] console [tty0] enabled
[    0.935792] 00:05: ttyS0 at I/O 0x3f8 (irq = 4, base_baud = 115200) is a 16550A
[    3.219884] systemd[1]: Created slice system-getty.slice.
[    4.058666] usb 3-1: FTDI USB Serial Device converter now attached to ttyUSB0
[10721.756835] ftdi_sio ttyUSB0: FTDI USB Serial Device converter now disconnected from ttyUSB0
[10727.552536] cdc_acm 3-1:1.2: ttyACM0: USB ACM device
```

This means that your Nucleo registered `/dev/ttyAMA0` device and to connect you
can use `minicom`:

```console
minicom -b 9600 -o -D /dev/ttyACM0
```

Summary
-------

I hope this tutorial add something or help resolving some issue that you may
struggle with. As you can see mbed is not perfect, but it looks like it may
serve as great replacement for previous environments ie. custom IDE from
various vendors. What would be useful to verify is for sure OpenOCD with STLink
to see if whole development stack is ready to use under Linux. In next post I
will try to start work with Atmel SAM G55 and mbed OS.

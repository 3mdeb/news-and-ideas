---
ID: 63041
title: >
  Zephyr initial triage on Nucleo-64
  STM32F411RE
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/zephyr-initial-triage-on-nucleo-64-stm32f411re/
published: true
date: 2017-01-14 22:14:10
year: "2017"
tags:
  - embedded
  - linux
  - Zephyr
  - STM32
  - STMicroelectronics
categories:
  - Firmware
  - IoT
---
As I mention in [previous post](2016/11/23/starting-with-mdeb-os-for-linux-and-command-line-enthusiast)
[Zephyr RTOS](https://www.zephyrproject.org/) is an interesting initiative
started by Intel, NXP and couple other strong organizations. With so well
founded background future for this RTOS should look bright and I think it will
quickly became important player on IoT arena.

Because of that it is worth to dig little bit deeper in this RTOS and see what
problems we faced when trying to develop for some well known development board.
I choose STM32 F411RE mainly because it start to gather dust and some customers
ask about it recently. As always I will present perspective of Linux enthusiast
trying to use Debian Linux and command line for development as I did for [mbed OS](2016/11/23/starting-with-mdeb-os-for-linux-and-command-line-enthusiast).

## Let's start

To not repeat documentation here please first follow [Getting Started Guide](https://www.zephyrproject.org/doc/doc/getting_started/installation_linux.html).

After setting up environment and running Hello World example we are good to go
with trying Nucleo-64 STM32F411RE. This is pretty new thing, so you will need
recent `arm` branch:

```
git fetch origin arm
git checkout arm
```

Then `make help` should show `f411re`:

```
$ make help|grep f411
  make BOARD=nucleo_f411re            - Build for nucleo_f411re
```

Let's try to compile that (please note that I'm still in `hello_world` project):

```
$ make BOARD=nucleo_f411re
(...)
  AR      libzephyr.a
  LINK    zephyr.lnk
  HEX     zephyr.hex
  BIN     zephyr.bin
```

### OpenOCD and flashing

To flash binaries OpenOCD was needed:

```
git clone git://git.code.sf.net/p/openocd/code openocd-code
cd openocd-code
./bootstrap
./configure
make -j$(nproc)
sudo make -j$(nproc) install
```

It would be great to have mbed way of flashing Nucleo-64 board.

Using OpenOCD I get libusb access error:

```
$ make BOARD=nucleo_f411re flash
make[1]: Entering directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project'
make[2]: Entering directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project/samples/hello_world/outdir/nucleo_f411re'
  Using /home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project as source for kernel
  GEN     ./Makefile
  CHK     include/generated/version.h
  CHK     misc/generated/configs.c
  CHK     include/generated/offsets.h
  CHK     misc/generated/sysgen/prj.mdef
Flashing nucleo_f411re
Flashing Target Device
Open On-Chip Debugger 0.9.0-dirty (2016-08-02-16:04)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Info : The selected transport took over low-level target control. The results might differ compared to plain JTAG/SWD
adapter speed: 2000 kHz
adapter_nsrst_delay: 100
none separate
srst_only separate srst_nogate srst_open_drain connect_deassert_srst
Info : Unable to match requested speed 2000 kHz, using 1800 kHz
Info : Unable to match requested speed 2000 kHz, using 1800 kHz
Info : clock speed 1800 kHz
Error: libusb_open() failed with LIBUSB_ERROR_ACCESS
Error: open failed
in procedure 'init'
in procedure 'ocd_bouncer'

Done flashing
```

I added additional udev rules from OpenOCD project:

```
sudo cp contrib/99-openocd.rules /etc/udev/rules.d
```

And added my username to `plugdev` group:

```
sudo usermod -aG plugdev $USER
```

The result was:

```
[0:39:48] pietrushnic:hello_world git:(arm) $ make BOARD=nucleo_f411re flash
make[1]: Entering directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project'
make[2]: Entering directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project/samples/hello_world/outdir/nucleo_f411re'
  Using /home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project as source for kernel
  GEN     ./Makefile
  CHK     include/generated/version.h
  CHK     misc/generated/configs.c
  CHK     include/generated/offsets.h
  CHK     misc/generated/sysgen/prj.mdef
Flashing nucleo_f411re
Flashing Target Device
Open On-Chip Debugger 0.9.0-dirty (2016-08-02-16:04)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Info : The selected transport took over low-level target control. The results might differ compared to plain JTAG/SWD
adapter speed: 2000 kHz
adapter_nsrst_delay: 100
none separate
srst_only separate srst_nogate srst_open_drain connect_deassert_srst
Info : Unable to match requested speed 2000 kHz, using 1800 kHz
Info : Unable to match requested speed 2000 kHz, using 1800 kHz
Info : clock speed 1800 kHz
Info : STLINK v2 JTAG v27 API v2 SWIM v15 VID 0x0483 PID 0x374B
Info : using stlink api v2
Info : Target voltage: 3.234714
Info : stm32f4x.cpu: hardware has 6 breakpoints, 4 watchpoints
    TargetName         Type       Endian TapName            State
--  ------------------ ---------- ------ ------------------ ------------
 0* stm32f4x.cpu       hla_target little stm32f4x.cpu       running
target state: halted
target halted due to debug-request, current mode: Thread
xPSR: 0x01000000 pc: 0x0800203c msp: 0x20000750
auto erase enabled
Info : device id = 0x10006431
Info : flash size = 512kbytes
target state: halted
target halted due to breakpoint, current mode: Thread
xPSR: 0x61000000 pc: 0x20000042 msp: 0x20000750
wrote 16384 bytes from file /home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project/samples/hello_world/outdir/nucleo_f411re/zephyr.bin in 0.727563s (21.991 KiB/s)
target state: halted
target halted due to debug-request, current mode: Thread
xPSR: 0x01000000 pc: 0x0800203c msp: 0x20000750
verified 12876 bytes in 0.118510s (106.103 KiB/s)
shutdown command invoked
Done flashing
make[2]: Leaving directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project/samples/hello_world/outdir/nucleo_f411re'
make[1]: Leaving directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project'
```

## Hello world verification

Unfortunately I was not able to verify if `hello_world` example works at first
time. I posted my experience on [mailing list](https://lists.zephyrproject.org/archives/list/devel@lists.zephyrproject.org/thread/3U5SX62HCTJFTQEAJX6DR6P5T45PZXUH/)
and after couple days I received information that there was bug in clock
initialisation and fix was pushed to gerrit.

So I tried one more time:

```
git checkout master
git fetch origin
git branch -D arm
git checkout arm
source zephyr-env.sh
cd samples/hello_world
make BOARD=nucleo_f411re
```

Unfortunately `arm` branch seems to rebase or change in not linear manner, so
just pulling it cause lot of conflicts.

After correctly building I flashed binary to board:

```
make[1]: Entering directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project'
make[2]: Entering directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project/samples/hello_world/outdir/nucleo_f411re'
  Using /home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project as source for kernel
  GEN     ./Makefile
  CHK     include/generated/version.h
  CHK     misc/generated/configs.c
  CHK     include/generated/offsets.h
Flashing nucleo_f411re
Flashing Target Device
Open On-Chip Debugger 0.9.0-dirty (2016-08-02-16:04)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Info : The selected transport took over low-level target control. The results might differ compared to plain JTAG/SWD
adapter speed: 2000 kHz
adapter_nsrst_delay: 100
none separate
srst_only separate srst_nogate srst_open_drain connect_deassert_srst
Info : Unable to match requested speed 2000 kHz, using 1800 kHz
Info : Unable to match requested speed 2000 kHz, using 1800 kHz
Info : clock speed 1800 kHz
Info : STLINK v2 JTAG v27 API v2 SWIM v15 VID 0x0483 PID 0x374B
Info : using stlink api v2
Info : Target voltage: 3.232105
Info : stm32f4x.cpu: hardware has 6 breakpoints, 4 watchpoints
    TargetName         Type       Endian TapName            State
--  ------------------ ---------- ------ ------------------ ------------
 0* stm32f4x.cpu       hla_target little stm32f4x.cpu       running
target state: halted
target halted due to debug-request, current mode: Thread
xPSR: 0x01000000 pc: 0x080020a0 msp: 0x20000750
auto erase enabled
Info : device id = 0x10006431
Info : flash size = 512kbytes
target state: halted
target halted due to breakpoint, current mode: Thread
xPSR: 0x61000000 pc: 0x20000042 msp: 0x20000750
wrote 16384 bytes from file /home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project/samples/hello_world/outdir/nucleo_f411re/zephyr.bin in 0.663081s (24.130 KiB/s)
target state: halted
target halted due to debug-request, current mode: Thread
xPSR: 0x01000000 pc: 0x08001c84 msp: 0x20000750
verified 11900 bytes in 0.109678s (105.956 KiB/s)
shutdown command invoked
Done flashing
make[2]: Leaving directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project/samples/hello_world/outdir/nucleo_f411re'
make[1]: Leaving directory '/home/pietrushnic/storage/wdc/projects/2016/acme/zephyr_support/src/zephyr-project'
```

Log looks the same as previously, but this time on `/dev/ttyACM0` I found some
output by using `minicom`:

```
minicom -b 115200 -o -D /dev/ttyACM0
```

Result was:

```
***** BOOTING ZEPHYR OS v1.6.99 - BUILD: Jan 14 2017 22:03:14 *****
Hello World! arm
```

The same method worked with `basic/blinky` example.

## Summary

This was short introduction, which took couple weeks to publish. I will
continue Zephyr research and as initial project I choose to add i2c driver for
F411RE development board.

Overall Zephyr looks very promising with lot of documentation. Community could
me more responsive, because at this point I think it is pushed more by
corporation related then deeply engaged enthusiasts.

Important think to analyze for Zephyr is cross platform verification on
application level. By that I mean exercising proposed abstraction model to see
if for example I can run the same application on emulation and on target
platform. Giving that ability would be huge plus.

Also what would be interesting to see is some general approach to application
validation. This could shift verification from target hardware to emulated
environment, what would be very interesting for future embedded developers.

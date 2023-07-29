---
ID: 63046
title: nRF51822 programming with OpenOCD under Linux
author: kamil.wcislo
post_excerpt: ""
layout: post
published: true
date: 2017-01-22 00:13:00
archives: "2017"
tags:
  - STM32
  - linux
  - toolchain
categories:
  - Firmware
  - IoT
---

Some time ago we bought [BLE400 from Waveshare] as probably one of the cheapest
option to enter nRF51822 market. As our readers know, we prefer to use the Linux
environment for embedded systems development. Because of that, we're following
the guide for using Waveshare nRF51822 Eval Kit: [icarus-sensors]. Kudos due to
great post that helped us enter nRF51822 and mbed OS land under Linux.

BLE400 is pretty cheap, because it hasn't got integrated debugger/programmer.
Key is to realize, that you can use BLE400 eval kit and STM32 development board
ie. Discovery or any Nucleo (only for its stlink integrated
debugger/programmer), which are also cheap. Of course other boards or standalone
ST-Link could be used.

## Hardware connections

On the Nucleo board both jumpers from `CN2` connector should be removed. Thanks
to this ST-LINK could be used in stand-alone mode.

Connection should be made this way:

```bash
Nucleo CN2 connector             BLE400 SWD connector
-----------------+               +------------------
VCC     (pin 1)  |-x             | .
SWD CLK (pin 2)  |---------------| (pin 9) SWD CLK
GND     (pin 3)  |---------------| (pin 4) GND
SWD IO  (pin 4)  |---------------| (pin 7) SWD IO
RST     (pin 5)  |-x             | .
SWO     (pin 6)  |-x             | .
-----------------+               +------------------
```

![img][3]

Both boards should be connected to host's USB ports. USB port on BLE400 is used
for power supply and debug UART connection (`cp210x` converter should be
detected and `ttyUSBx` exposed).

## OpenOCD basic test

No `stlink` tools are needed. Only OpenOCD.

OpenOCD version we're using:

```bash
$ openocd -v
Open On-Chip Debugger 0.9.0 (2016-04-27-23:18)
Licensed under GNU GPL v2
For bug reports, read
 http://openocd.org/doc/doxygen/bugs.html
```

### Enable user access to Debugger

First we need to check, that our debugger is detected. There should be line like
this:

```bash
$ lsusb
...
Bus 003 Device 015: ID 0483:3748 STMicroelectronics ST-LINK/V2
...
```

Note the `ID's: 0483:3748`. Create rule in `/etc/udev/rules.d` (as `root`):

```bash
$ cat > /etc/udev/rules.d/95-usb-stlink-v2.rules << EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3748", GROUP="users", MODE="0666"
EOF
```

Reload `udev` rules (as `root`):

```bash
udevadm control --reload
udevadm trigger
```

Reconnect the st-link. After that, debugger should be accessible by user.

### Test the OpenOCD connection

Run this command to connect the debugger to the target system (attaching example
output). `cfg` files location depend on your setup, if you compiled OpenOCD from
source those files should be in `/usr/local/share/openocd/scripts`:

```bash
$ openocd -f interface/stlink-v2.cfg  -f target/nrf51.cfg
Open On-Chip Debugger 0.9.0 (2016-04-27-23:18)
Licensed under GNU GPL v2
For bug reports, read
 http://openocd.org/doc/doxygen/bugs.html
Info : auto-selecting first available session transport "hla_swd". To override use 'transport select <transport>'.
Info : The selected transport took over low-level target control. The results might differ compared to plain JTAG/SWD
adapter speed: 1000 kHz
Info : Unable to match requested speed 1000 kHz, using 950 kHz
Info : Unable to match requested speed 1000 kHz, using 950 kHz
Info : clock speed 950 kHz
Info : STLINK v2 JTAG v14 API v2 SWIM v0 VID 0x0483 PID 0x3748
Info : using stlink api v2
Info : Target voltage: 2.935549
Info : nrf51.cpu: hardware has 4 breakpoints, 2 watchpoints
```

If you see error like this:

```bash
censed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Info : auto-selecting first available session transport "hla_swd". To override use 'transport select <transport>'.
Info : The selected transport took over low-level target control. The results might differ compared to plain JTAG/SWD
adapter speed: 1000 kHz
Info : Unable to match requested speed 1000 kHz, using 950 kHz
Info : Unable to match requested speed 1000 kHz, using 950 kHz
Info : clock speed 950 kHz
Error: open failed
in procedure 'init'
in procedure 'ocd_bouncer'
```

This means you may have `STLink v2.1`, so your command should look like this:

```bash
$ openocd -f interface/stlink-v2-1.cfg  -f target/nrf51.cfg
Open On-Chip Debugger 0.10.0-dev-00395-g674141e8a7a6 (2016-10-20-15:01)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Info : auto-selecting first available session transport "hla_swd". To override use 'transport select <transport>'.
Info : The selected transport took over low-level target control. The results might differ compared to plain JTAG/SWD
adapter speed: 1000 kHz
Info : Unable to match requested speed 1000 kHz, using 950 kHz
Info : Unable to match requested speed 1000 kHz, using 950 kHz
Info : clock speed 950 kHz
Info : STLINK v2 JTAG v27 API v2 SWIM v15 VID 0x0483 PID 0x374B
Info : using stlink api v2
Info : Target voltage: 0.000000
Error: target voltage may be too low for reliable debugging
Info : nrf51.cpu: hardware has 4 breakpoints, 2 watchpoints
```

After that `OpenOCD` is waiting for incoming telnet connections on port _4444_.
This sample connection, to check everything is ok:

```bash
$ telnet 127.0.0.1 4444
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
Open On-Chip Debugger
> halt
target state: halted
target halted due to debug-request, current mode: Thread
xPSR: 0x61000000 pc: 0x00011434 msp: 0x200022a8
> reg
===== arm v7m registers
(0) r0 (/32): 0x20000093
(1) r1 (/32): 0x0000003B
(2) r2 (/32): 0xE000E200
(3) r3 (/32): 0x0000003B
(4) r4 (/32): 0x0001CEB8
(5) r5 (/32): 0x00000001
(6) r6 (/32): 0x0001CEB8
(7) r7 (/32): 0xFFFFFFFF
(8) r8 (/32): 0xFFFFFFFF
(9) r9 (/32): 0xFFFFFFFF
(10) r10 (/32): 0xFFFFFFFF
(11) r11 (/32): 0xFFFFFFFF
(12) r12 (/32): 0xFFFFFFFF
(13) sp (/32): 0x200022A8
(14) lr (/32): 0x0000114F
(15) pc (/32): 0x00011434
(16) xPSR (/32): 0x61000000
(17) msp (/32): 0x200022A8
(18) psp (/32): 0xFFFFFFFC
(19) primask (/1): 0x00
(20) basepri (/8): 0x00
(21) faultmask (/1): 0x00
(22) control (/2): 0x00
===== Cortex-M DWT registers
(23) dwt_ctrl (/32)
(24) dwt_cyccnt (/32)
(25) dwt_0_comp (/32)
(26) dwt_0_mask (/4)
(27) dwt_0_function (/32)
(28) dwt_1_comp (/32)
(29) dwt_1_mask (/4)
(30) dwt_1_function (/32)
> reset
> exit
Connection closed by foreign host.
```

### Testing the example program

First we need proper SDK for out device. ICs that we tested were revision 2 and
3 (`QFAA` and `QFAC` code, see the print on the NRF chip). You can check the
[revision table] and [compatibility matrix] to determine SDK version. We used
[SDK v.12.1.0] for the rev3 chip.

After downloading and uncompressing the SDK. We can find the `blinky` example in
`examples/peripheral/blinky/hex/blinky_pca10028.hex`. Now we can try to program
it:

```bash
$ telnet 127.0.0.1 4444
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
Open On-Chip Debugger
> halt
target state: halted
target halted due to debug-request, current mode: Handler HardFault
xPSR: 0xc1000003 pc: 0xfffffffe msp: 0xffffffd8
> program /home/mek/work/nrf51/sdk/examples/peripheral/blinky/hex/blinky_pca10028.hex
target state: halted
target halted due to debug-request, current mode: Thread
xPSR: 0xc1000000 pc: 0xfffffffe msp: 0xfffffffc
** Programming Started **
auto erase enabled
using fast async flash loader. This is currently supported
only with ST-Link and CMSIS-DAP. If you have issues, add
"set WORKAREASIZE 0" before sourcing nrf51.cfg to disable it
target state: halted
target halted due to breakpoint, current mode: Thread
xPSR: 0x61000000 pc: 0x2000001e msp: 0xfffffffc
wrote 2048 bytes from file /path/to/nrf51/sdk/examples/peripheral/blinky/hex/blinky_pca10028.hex in 0.114289s (17.499 KiB/s)
** Programming Finished **
> reset
> exit
Connection closed by foreign host.
```

During that procedure you may face this problem:

```bash
> program /path/to/work/nrf51/sdk/examples/peripheral/blinky/hex/blinky_pca10028.hex
nrf51.cpu: target state: halted
target halted due to debug-request, current mode: Thread
xPSR: 0xc1000000 pc: 0x00012b98 msp: 0x20001c48
** Programming Started **
auto erase enabled
Cannot erase protected sector at 0x0
failed erasing sectors 0 to 1
embedded:startup.tcl:454: Error: ** Programming Failed **
in procedure 'program'
in procedure 'program_error' called at file "embedded:startup.tcl", line 510
at file "embedded:startup.tcl", line 454
```

To solve that please issue `nrf51 mass_erase` and retry program command. This
have to be done only once.

After that, `LED3` and `LED4` should start blinking on the target board.

### Sample script for flashing

I've created this script to simplify the flashing operation:

```bash
#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 BINARY_HEX"
    exit 0
fi

if [ ! -f $1 ]; then
    echo "$1: file not found"
    exit 1
fi

openocd -f interface/stlink-v2.cfg -f target/nrf51.cfg \
-c "init" \
-c "halt" \
-c "nrf51 mass_erase" \
-c "program $1" \
-c "reset" \
-c "exit"
```

Note: `openocd` does not accept filenames containing space in path.

## Summary

As you can see, it's possible to work with nRF51822 under Linux using only
OpenOCD. Whole workflow can be scripted to match your needs. With this
knowledge, we can start to deploy mbed OS and Zephyr, which both have great
support for Linux through command line interface.

[3]: /img/nrf51822_stlink.jpg
[ble400 from waveshare]: http://www.waveshare.com/nrf51822-eval-kit.htm
[compatibility matrix]: http://infocenter.nordicsemi.com/index.jsp?topic=%2Fcom.nordic.infocenter.nrf51%2Fdita%2Fnrf51%2Fcompatibility_matrix%2FnRF51422_nRF51822_ic_rev_sdk_sd_comp_matrix.html&cp=3_0_4
[icarus-sensors]: http://icarus-sensors.github.io/general/starting-with-nRF51822.html
[revision table]: http://infocenter.nordicsemi.com/index.jsp?topic=%2Fcom.nordic.infocenter.nrf51%2Fdita%2Fnrf51%2Fcompatibility_matrix%2FnRF51822_ic_revision_overview.html&cp=3_0_1
[sdk v.12.1.0]: https://developer.nordicsemi.com/nRF5_SDK/nRF5_SDK_v12.x.x/nRF5_SDK_12.1.0_0d23e2a.zip

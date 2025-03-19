---
title: The Bit Bang Theory with RTE
abstract: RTE used to control tested devices could be used as a programmer.
          But RTE doesn't have SWD interface, which is crucial.
          We tried to walk around this using Bit Banging method.
cover: /covers/bit_bang_cover.jpg
author: lukasz.wcislo
layout: post
published: true
date: 2019-05-08
archives: "2019"

tags:
  - RTE
  - toolchain
  - stm32
  - arm
categories:
  - Firmware
  - Miscellaneous
  - Manufacturing

---

## Why?

When you are working with firmware and embedded systems usually you flash some
microchips at least several times a day. Often you use SWD (Serial Wire Debug)
interface to do so. It is fast and simple but requires an additional device, a
programmer, which sometimes tend to crash. RTE (Remote Testing Environment),
which we use to control devices under tests, is equipped with many interfaces to
contact with our device in any possible way. But not SWD. The whole idea is to
emulate it with dedicated software and make use of the state of RTE pins for all
parameters of the signal: timing, levels, synchronization, etc. and use it to
flash microchip.

This technique is called **The Bit Banging**.

So, let's assume, that we have some board with a chip, i.e. STM32 series, which
is very popular, and a binary image, which will be used for firmware upgrade. To
do it, at the very beginning we need some software that provides us a way to
manipulate the state of RTE pins as if they were pins of a programmer. As we
prefer open source we used OpenOCD (Open-On-Chip-Debbuger). This is a
well-developed tool for such jobs, but, unfortunately, it doesn't support Orange
Pi Zero. And this is our microcomputer attached to RTE.

It doesn't support it YET.

## How?

After compiling OpenOCD and all the required libraries on Orange Pi Zero we've
compared pinout of it with the pinout of Raspberry Pi 1, which on the first
sight has been similar. It was the same similarity as between a dolphin and a
shark, as we get close to it appeared to be much different. The only thing the
same was a number of pins.

After studying of RTE and Orange Pi Zero pins usage and accessibility we've
chosen three sets of pins, that we considered being our candidates. SWD
interface requires three connected routes (SWDIO - data in and out, SWCLK -
clock synchronization and NRST - reset signal) and ground connection. Our pins
had to be connected directly with Orange Pi pins and shouldn't be used for any
other important purposes. Next step was to create a configuration file to
translate OpenOCD which pins we want to be used and in what purpose. It also had
to be described what OpenOCD should try to pretend to be (it can emulate many
interfaces).

We tested RTE expander pin header, which turned out to be too slow, next was OC
buffer pin header pins 1-3, which doesn't support such action at all. Finally,
it appeared, that header responsible originally for reading a device under test
Power LED value, though it was directed **in** by default, fits our needs.

```bash
interface sysfsgpio
reset_config srst_only srst_push_pull
sysfsgpio_swd_nums 11 12
sysfsgpio_srst_num 6
```

![Final set of pins](/img/rte_bang.jpg)

But it was still required to create a file for configuring flashing action
(well, it can be done with a console, but in our case, it would be a bit long).

After creating directory `~/bootloader` and copying there an example binary
image, we created file `openocd.cfg` which was filled with:

```bash
source [find interface/orangepi.cfg]
transport select swd
set CHIPNAME STM32L432KC
source [find target/stm32l4x.cfg]
adapter_nsrst_delay 100
adapter_nsrst_assert_width 100
adapter_khz 480
init
targets
reset halt
program vitroio-node-1.1.1-demo-dht.bin verify 0x8000000
reset
shutdown
```

Which means :

- Take interface config file for Orange Pi
- use swd to communicate
- set a name for chip
- take chip config file
- set reset properties
- set speed
- start
- find suitable connected chip
- stop that chip
- flash with file (which is in our directory `~/bootloader/`) starting at
  0x8000000 address, then verify if flashing was successful
- reset device
- close bit banging procedure

Then we typed `openocd` in bootloader directory. There is no need to add any
more, everything is in the config file we created.

![Flashing MC using Bit Banging](https://asciinema.org/a/zOmYCl5EIMkepDEvXhiubPLGT)

## But there were some errors

Yes, sometimes there are some errors thrown:

```bash
Error: Translation from khz to jtag_speed not implemented
embedded:startup.tcl:244: Error:
in procedure 'ocd_process_reset'
in procedure 'ocd_process_reset_inner' called at file "embedded:startup.tcl",
line  244
```

But in OpenOCD documentation, this is described as more or less irrelevant. All
in all our microchip has been flashed, and this action has been verified.

## Summary

Bit Banging method means emulating some hardware interfaces using software
operations on other interfaces. Popular software in this matter is OpenOCD. This
article shows an example of how to do it with an Orange Pi Zero, that is not
currently supported by OpenOCD. And, in consequence, how to become a better
person.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up for our newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

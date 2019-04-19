---
title: USB Sniffing With OpenVizsla
abstract: OpenVizsla allows to passively monitor the communication between a USB
          host and USB peripheral.
          It is a tool for developers working with USB and especially those who
          are using USB in embedded designs.
          We have tested its possible use cases and see it is really valuable,
          and has a lot of potential for further development.
cover: /covers/sniffing_usb_cover.jpg
author: lukasz.wcislo
layout: post
published: false
date: 2019-04-18

tags:
  - USB
  - USB sniffing
  - OpenVizsla
categories:
  - Miscellaneous
  - Security

---

### Background

**"OpenVizsla is a project to design a device that will allow the capture and
inspection of USB traffic that will help with the reverse engineering and
debugging of proprietary USB devices, and will also be an invaluable tool for
developers working with USB and especially those who are using USB in
embedded designs."**

This is the first sentence of a Kickstarter project which was funded in 2010.
It was donated with over 80.000 USD (what was much more then it was expected)
(and what turned out to be less than really was needed) in a month.
A pair of enthusiasts (bushing and pytey) with their friends put a lot of effort
to create small, cheap and open sourced USB sniffer.

After over two years of struggle, while no working prototype was ready,
people over the Internet were really nervous. Many of them were calling
project maintainers to give them back their money. One of the founders
(pytey) wanted to support local businesses in Hungary, and he said he could get
them a good deal on assembly there. He took most of the parts, and after he
left the US it was more and more difficult to contact him.

After two months without any sign of life from pytey, bushing realized, that
he was left alone. With no parts left enough to assembly working boards for
people who donated their money. With not enough money to buy missing parts.
And not enough money to give it back to donators. He rearranged the design,
using entirely parts that he could buy off-the-shelf with the money he had
access to.  

At the beginning of 2014 first working boards were sent to premium donators.
People who donated less received bare PCB's with parts to assemble it on their
own a few months later. Kickstarter project was closed on Aug 27 2014. Every
man who donated money on it received what was agreed.

Ben “bushing” Byer died Feb 8 2016.

![OpenVizsla v3.2 board](/img/OpenVizsla.jpg)

### A Brief Description

Since there is no (affordable, at least) silicon that out-of-the-box provides
USB sniffing features, the heart of the OpenVizsla is an [FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array), Xilinx Spartan 6 LX FPGA to be exact.
Board has Micron MT48LC16M16A2P-xx SDRAM (256MB), FTDI FT2232H High-Speed USB
converter with FIFO interface, and SMSC USB3343 ULPI PHY Hi-Speed USB 2.0
transceiver.

It has two USB 2.0 B ports (for a host and for a server) and one USB 2.0 A port
for a target device, which is going to be analyzed. It provides no USB 3.0
support. As there was very little support last few years, there are a lot
of known [limitations](https://github.com/openvizsla/ov_ftdi/wiki/limitations).

The device itself is Open Source Hardware, all the [schematics](http://openvizsla.org/images/ov_3.2_schematics_BOM.pdf) are open,
and anyone is free to build it on his own. [Firmware](https://github.com/openvizsla/ov_ftdi/wiki/building) is also free.

### Sniffing USB devices

OpenVizsla is a sniffer and analyzer. It allows you to **passively** monitor the
communication between a USB host and USB peripheral. It supports USB low-speed,
full-speed and high-speed. To show that it works we started with something
simple. Low-speed USB devices are i.e. keyboards and mouses. For the first test
we used a keyboard, because it is easy to [interpret](https://wiki.osdev.org/USB_Human_Input_Devices#USB_keyboard).

 ![Keyboard test](https://asciinema.org/a/3dgnIPRaGmyLHAOWZOHI08YBz)

As we can see, though there are a lot of frames going, most of them are
basically empty. USB protocol throws frames even if there is no info to
send. Some times there can be some information detected, like i.e.:

```
[        ]   3.899367 d=  0.002974 [   .0 +3899367.117] [  3] IN   : 21.1
[        ]   3.901367 d=  0.002000 [   .0 +3901367.117] [  3] IN   : 4.1
[        ]   3.903368 d=  0.002001 [   .0 +3903367.783] [  3] IN   : 27.1
[        ]   3.903393 d=  0.000025 [   .0 +3903393.117] [  1] NAK
[        ]   3.907368 d=  0.003975 [   .0 +3907367.783] [  3] IN   : 21.1
[        ]   3.909368 d=  0.002001 [   .0 +3909368.450] [  3] IN   : 4.1
[        ]   3.911368 d=  0.002000 [   .0 +3911368.450] [  3] IN   : 27.1
[        ]   3.911394 d=  0.000025 [   .0 +3911393.783] [ 11] DATA1: 00 00 1e 00 00 00 00 00 29 88
[        ]   3.911462 d=  0.000069 [   .0 +3911462.450] [  1] ACK
[        ]   3.915368 d=  0.003906 [   .0 +3915368.450] [  3] IN   : 21.1
[        ]   3.917369 d=  0.002001 [   .0 +3917369.117] [  3] IN   : 4.1
[        ]   3.919369 d=  0.002000 [   .0 +3919369.117] [  3] IN   : 27.1
[        ]   3.919395 d=  0.000026 [   .0 +3919395.117] [  1] NAK
```

In `DATA1: 00 00 1e 00 00 00 00 00 29 88` we've got something to read.
According to USB keyword specification, the 3rd byte of a report applies to
the first button pressed. And `1e` is hexadecimal representation of [keycode](https://www.win.tue.nl/~aeb/linux/kbd/scancodes-14.html)
of '1'. (Which actually has been pressed).

Let's try an USB mouse instead.

![Mouse test](https://asciinema.org/a/EBqH5GAiqSy2EsTsSUzjCdtHv)

After the sniffing started for a while we did nothing. Then, we started to move
the mouse in random directions. Stopped. And started again.

```
[        ]   5.570812 d=  0.000027 [   .0 +5570812.050] [  7] DATA1: 00 01 ff 00 ef eb
[        ]   5.570861 d=  0.000049 [   .0 +5570861.383] [  1] ACK
[        ]   5.575785 d=  0.004924 [   .0 +5575785.383] [  3] IN   : 21.1
[        ]   5.577785 d=  0.002000 [   .0 +5577785.383] [  3] IN   : 4.1
[        ]   5.578785 d=  0.001000 [   .0 +5578785.383] [  3] IN   : 26.1
[        ]   5.578813 d=  0.000027 [   .0 +5578812.717] [  7] DATA0: 00 f9 fe 00 6f 8a
[        ]   5.578862 d=  0.000049 [   .0 +5578862.050] [  1] ACK
[        ]   5.583786 d=  0.004924 [   .0 +5583786.050] [  3] IN   : 21.1
[        ]   5.585786 d=  0.002000 [   .0 +5585786.050] [  3] IN   : 4.1
[        ]   5.586787 d=  0.001001 [   .0 +5586786.717] [  3] IN   : 26.1
[        ]   5.586813 d=  0.000027 [   .0 +5586813.383] [  7] DATA1: 00 f8 fe 00 3e 4a
[        ]   5.586863 d=  0.000049 [   .0 +5586862.717] [  1] ACK
[        ]   5.591787 d=  0.004924 [   .0 +5591786.717] [  3] IN   : 21.1
[        ]   5.593787 d=  0.002001 [   .0 +5593787.383] [  3] IN   : 4.1
[        ]   5.594787 d=  0.001000 [   .0 +5594787.383] [  3] IN   : 26.1
[        ]   5.594815 d=  0.000027 [   .0 +5594814.717] [  7] DATA0: 00 fb 00 00 8e 2a
```

The second and the third byte represents movement in consequently X and Y axis.
The first (it should be properly called '0') byte represents mouse buttons
status.

Ok, that's fun, may be nice to check once or even twice if it works as
described in a specification. But is that what this device is designed for?
Well, maybe. If You are a USB peripherals engineer.

**Let's do something more interesting.**

In examples above we showed how intense is low-speed communication over USB.
Signals flew so quickly, that it was hard to notice a single data frame. And
that was low-speed. Devices like USB memory sticks run on a high-speed.
Unfortunately, this is so fast, that in the real time the amount of
information makes it totally unreadable for a man.

Instead of showing a movie, we'll show a set of frozen frames from the output.

```
[        ]  37.224731 d=  0.000022 [ 15.1 +  0.583] [  3] IN   : 4.1
[        ]  37.224740 d=  0.000009 [ 15.1 +  9.667] [  3] IN   : 4.1
[        ]  37.224742 d=  0.000003 [ 15.1 + 12.317] [  3] IN   : 4.1
[        ]  37.224748 d=  0.000005 [ 15.1 + 17.600] [  3] IN   : 4.1
[        ]  37.224750 d=  0.000003 [ 15.1 + 20.250] [  3] IN   : 4.1
[        ]  37.224756 d=  0.000006 [ 15.1 + 25.767] [  3] IN   : 4.1
[        ]  37.224773 d=  0.000017 [ 15.1 + 42.683] [  3] IN   : 4.1
```

These are frames from a connected USB stick, that does absolutely nothing.
The last square bracket represents a number of bytes send, after that you can
read a packet identifier. `IN` means a `TOKEN` `IN` signal.
`ACK` is a `handshake` signal, which you can observe in examples above.

Now, let's connect to OpenVisla some real thing. Our choice was a stick with
live system, which should try to be recognized by the PC.

After a second we've had:

```
[        ]   1.836409 d=  0.000000 [135.1 + 39.783] [ 16] DATA0: 55 53 42 53 60 00 00 00 00 00 00 00 00 f1 b0
[        ]   1.836634 d=  0.000000 [135.3 + 14.400] [ 34] DATA0: 55 53 42 43 61 00 00 00 00 00 00 00 00 00 06 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 aa 90
[        ]   1.836790 d=  0.000000 [135.4 + 45.050] [ 16] DATA1: 55 53 42 53 61 00 00 00 00 00 00 00 00 fc 20
[        ]   1.836985 d=  0.000000 [135.5 +114.817] [ 34] DATA1: 55 53 42 43 62 00 00 00 00 10 00 00 80 00 0a 28 00 00 00 00 00 00 00 08 00 00 00 00 00 00 00 49 3f
[        ]   1.837871 d=  0.000000 [136.5 +  1.033] [515] DATA0: eb 3c 00 00 00 00 00 00 00 00 00 00 02 00 00 00 00 00 00 00 00 00 00 00 12 00 02 00 00 00 00 00 00 00 00 00 00 16 1f 66 6a 00 51 50 06 53 31 c0 88 f0 50 6a 10 89 e5 e8 c0 00 8d 66 10 cb fc 31 c9 8e c1 8e d9 8e d1 bc 00 7c 89 e6 bf 00 07 fe c5 f3 a5 be ee 7d 80 fa 80 72 2c b6 01 e8 60 00 b9 01 00 be be 8d b6 01 80 7c 04 a5 75 07 e3 19 f6 04 80 75 14 83 c6 10 fe c6 80 fe 05 72 e9 49 e3 e1 be a2 7d eb 4b 31 d2 89 16 00 09 b6 10 e8 2e 00 bb 00 90 8b 77 0a 01 de bf 00 c0 b9 00 ae 29 f1 f3 a4 fa 49 74 14 e4 64 a8 02 75 f7 b0 d1 e6 64 e4 64 a8 02 75 fa b0 df e6 60 fb e9 50 13 bb 00 8c 8b 44 08 8b 4c 0a 0e e8 5a ff 73 2a be 9d 7d e8 1c 00 be a7 7d e8 16 00 30 e4 cd 16 c7 06 72 04 34 12 ea f0 ff 00 f0 bb 07 00 b4 0e cd 10 ac 84 c0 75 f4 b4 01 f9 c3 2e f6 06 b0 08 80 74 22 80 fa 80 72 1d bb aa 55 52 b4 41 cd 13 5a 72 12 81 fb 55 aa 75 0c f6 c1 01 74 07 89 ee b4 42 cd 13 c3 52 b4 08 cd 13 88 f5 5a 72 cb 80 e1 3f 74 c3 fa 66 8b 46 08 52 66 0f b6 d9 66 31 d2 66 f7 f3 88 eb 88 d5 43 30 d2 66 f7 f3 88 d7 5a 66 3d ff 03 00 00 fb 77 9d 86 c4 c0 c8 02 08 e8 40 91 88 fe 28 e0 8a 66 02 38 e0 72 02 b0 01 bf 05 00 c4 5e 04 50 b4 02 cd 13 5b 73 0a 4f 74 1c 30 e4 cd 13 93 eb eb 0f b6 c3 01 46 08 73 03 ff 46 0a d0 e3 00 5e 05 28 46 02 77 88 c3 52 65 61 64 00 42 6f 6f 74 00 20 65 72 72 6f 72 0d 0a 00 80 90 90 90 90 90 90 90 90 90 90 90 90 90 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 80 00 01 00 a5 fe ff ff 00 00 00 00 50 c3 00 00 55 aa b8 c4
```

What we can convert from hexadecimal to ASCII and obtain:

```
USBS`        �

USBCa                         ��

USBSa        �

USBCb      � 
(              I?

�<                                fj QPS1���Pj���� �f��1Ɏ��َѼ |�� ����}���r,��` � �����|�u���u���ƀ�r�I�ᾢ}�K1҉ 	��. � ��w
޿ �� �)���It�d�u����d�d�u����`��P� ��D�L
�Z�s*��}� ��}� 0���r4��� � �����u����.���t"���r��UR�A�Zr��U�u��t��B��R����Zrˀ�?t��f�FRf��f1�f����C0�f���Zf=�  �w������@���(��f8�r�� �^P��[s
Ot0�������Fs�F
�� ^(Fw��Read Boot  error
 ��������������                                                �  ����    P�  U���
```

This is only an example, chosen arbitrarily from many, many signals we received.

Speed of data transfer with all the logged information was such, that the log
the file we wanted to be created (plain text) was 200MB in a few seconds.

We had to interrupt it, but all the computer memory was busy making logs.
The only way to stop it was to disconnect the USB device manually.

## Summary

OpenVisla was invented 10 years ago, created almost 6 years ago and to be fair,
it was very unlucky. Many people have forgotten about it, but it still can be
very useful. It has a lot of potential for being used in security development.
We are going to continue our research and maybe, maybe in some time, we will
show what this small and relatively cheap board is capable of.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

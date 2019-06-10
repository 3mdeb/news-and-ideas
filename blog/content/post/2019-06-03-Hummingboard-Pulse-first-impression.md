---
title: Hummingboard Pulse - first impression.
abstract: In this post, we will take a look at one of the SolidRun product -
          the HummingBoard Pulse. After power up the board we will try to boot
          operating system on it.
cover: /covers/hummboard.jpg
author: tomasz.zyjewski
layout: post
published: false
date: 2019-06-10
archives: "2019"

tags:
  - HummingboardPulse
  - SOM
  - i.MX8
  - u-boot
  - linux
categories:
  - Firmware

---

### Introduction

SolidRun is a global leading developer of embedded systems and provides
a lot of powerful products. One of them I want to describe in this post
is the HummingBoard Pulse. You can see it in the picture below.

![HummingBoardPulse picture](/img/hummboard.jpg)

Hummingboard Pulse has the powerful i.MX8M SOM with a quad ARM Cortex A53 processor
(up to 1.5 GHz) with ARM M4. The i.MX8M family of processors provides industry-leading
audio, voice and video processing for applications that scale from consumer home
audio to industrial building automation and mobile computers. More information can
be found at the official website of the producer of these processors [there](https://www.nxp.com/products/processors-and-microcontrollers/arm-based-processors-and-mcus/i.mx-applications-processors/i.mx-8-processors/i.mx-8m-family-armcortex-a53-cortex-m4-audio-voice-video:i.MX8M).

The HummingBoard Pulse provides a lot of hardware interfaces from which I can
mention:
* USB type C
* Micro USB
* RJ45 Ethernet
* 2x USB 3.0
* HDMI 2.0
* Audio Headset
* MicroSD

All of them are nicely shown on the pictures which can be found
on [this](https://developer.solid-run.com/knowledge-base/hummingboard-pulse-getting-started/) website.

### Getting started with the board.

To start using the HummingBoard Pulse you will need a couple of things:
* Linux or Windows PC (it will be easier if you'll have Linux PC),
* 16GB Micro SD card,
* 12V Power adapter (the board has wide range input of 7V-36V but 12V is recommended),
* MicroUSB to USB for the console because the HummingBoard Pulse has an onboard FTDI
chip, which means that there is no need to use external UART/USB converter,
* and of course the HummingBoard Pulse with SOM.

OK, assuming you have everything that's needed, now it's time to flash our SD card
with U-Boot and Debian. Let me help you with that. As I mentioned earlier, the whole
installation is easier when using Linux PC so all commands will be given for users
of Linux.

#### Building ARM Trusted Firmware and U-Boot

Let's start with a toolchain. You can download a ready-to-use-toolchain. When
writing this post following toolchain was used: http://releases.linaro.org/components/toolchain/binaries/7.4-2019.02/aarch64-linux-gnu/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz. After you download and extract your, just type
commands which are shown below in the terminal. Just remember that CROSS_COMPILE environment
variables need to be set to the path of the toolchain prefix.
```shell
export ARCH=arm64
export CROSS_COMPILE=$PWD/toolchain/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz/bin/aarch64-linux-gnu
```

Source and firmware can be downloaded from the GitHub repos and sites listed below.
You can copy and execute those commands in your terminal.

```shell
git clone https://github.com/SolidRun/arm-trusted-firmware.git -b imx-atf-v1.6
git clone https://github.com/SolidRun/u-boot.git -b v2018.11-solidrun
wget https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/firmware-imx-7.9.bin
```

Building ATF is as follows.

```shell
cd arm-trusted-firmware
make PLAT=imx8mq bl31
cp build/imx8mq/release/bl31.bin ../u-boot/
```

After you extract NXP firmware you will need to accept the end user agreement.

```shell
chmod +x firmware-imx-7.9.bin
./firmware-imx-7.9.bin
cp firmware-imx-7.9/firmware/hdmi/cadence/signed_hdmi_imx8m.bin u-boot/
cp firmware-imx-7.9/firmware-imx-7.9/firmware/ddr/synopsys/lpddr4*.bin u-boot/
```

OK, so now you can change directory to the U-Boot directory, then build
U-Boot and generate the image.

```shell
make imx8mq_hb_defconfig
make flash.bin
```

Doing that you may need to install two programs named bison and flex. In this
case, you just need to type those commands in your terminal.

```shell
sudo apt-get install bison
sudo apt-get install flex
```
After all of that, you can flash U-Boot on to your SD card.

Firstly, after you plug-in your sd card to PC, you need to unmount it using:

```shell
umount /dev/sd[x]
```
Then you can easily flash your SD card with u-boot simply typing:

```shell
sudo dd if=flash.bin of=/dev/sd[x] bs=1024 seek=33
```
Where [x] stands for your SD card attached to PC. For me it was sdb.

From now you will have working U-Boot on your SD card. If you want to check how
it looks on HummingBoard Pulse you need to connect your PC with the board using
MicroUSB to USB cable and minicom on the terminal. Just type:

```shell
sudo minicom -b 115200 -D /dev/ttyUSB[x]
```

This time [x] stands for the USB port you use to communicate. For me, it was 0.

You should receive something like this:

```shell
-Boot SPL 2018.11-00078-g0dd51748c2a (Dec 16 2018 - 18:35:18 +0100)
PMIC:  PFUZE100 ID=0x10
Normal Boot
Trying to boot from MMC2
NOTICE:  Configureing TZASC380
NOTICE:  BL31: v1.6(release):v1.6-110-g0eb2df45
NOTICE:  BL31: Built : 13:56:07, Nov 29 2018
NOTICE:  sip svc init


U-Boot 2018.11-00078-g0dd51748c2a (Dec 16 2018 - 18:35:18 +0100)

CPU:   Freescale i.MX8MQ rev2.0 at 1000 MHz
Reset cause: POR
Model: SolidRun i.MX8MQ HummingBoard Pulse
DRAM:  3 GiB
MMC:   FSL_SDHC: 0, FSL_SDHC: 1
Loading Environment from MMC... *** Warning - bad CRC, using default environment

In:    serial
Out:   serial
Err:   serial
Net:
Error: ethernet@30be0000 address not set.

Error: ethernet@30be0000 address not set.
eth-1: ethernet@30be0000
Hit any key to stop autoboot:  0
```

OK, so now you need to copy the kernel image and .dtb file. Unfortunately, I was not
able to compile image following instructions given by SolidRun. Happily, there is
another way to run Linux on the HummingBoard Pulse.

#### Installing Debian on HummingBoard Pulse

SolidRun gives instructions on how to install Debian on HummingBoard Pulse. Debian
is well-documented GNU/Linux distribution and images of it are easily available
at https://images.solid-build.xyz/IMX8/Debian/. When you will be choosing one for
you please check the log of changes at the bottom. You will read there that only
versions released after 07.12.2018 supports booting from SD card.

After you download and extract an image of Debian you need to flash it on SD card.

```Shell
dd bs=4k conv=fsync if=<image name>.img of=/dev/sdb
```

Below you can watch log from booting Debian on HummingBoard Pulse. I,ve captured it
using asciinema.

[![asciicast](https://asciinema.org/a/250003.svg)](https://asciinema.org/a/250003?speed=1&t=14&autoplay=0)

## Summary

This post describes the HummingBoard Pulse and attempts of booting a Linux on it.
If you are looking for more detailed information about the board you are welcome
to check [this](https://developer.solid-run.com/products/hummingboard-pulse/) or
[that](https://www.nxp.com/products/processors-and-microcontrollers/arm-based-processors-and-mcus/i.mx-applications-processors/i.mx-8-processors/i.mx-8m-family-armcortex-a53-cortex-m4-audio-voice-video:i.MX8M). We hope to work with this platform much more and write many more
posts about i.MX8 series. Please let us know which i.MX8 features you like the
most and what kind of content would you expect in the next posts.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

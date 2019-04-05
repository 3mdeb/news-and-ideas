---
ID: 62966
title: >
  FWTS on ARMv8 platform (HiKey LeMaker
  version) from scratch
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/fwts-on-armv8-platform-hikey-lemaker-version-from-scratch/
published: true
date: 2016-07-25 14:13:02
tags:
  - embedded
  - UEFI
  - EDK2
  - ARMv8
  - HiSilicon
categories:
  - Firmware
---
This is second post from series about LeMaker version of HiKey board from
96boards Customer Edition family. [Previous](2016/05/19/powering-on-96boards-compatible-lemaker-hikey-armv8-for-uefi-development/)
post focused on describing hardware part. In this post I would like to show how
to setup firmware development and testing environment.

This post highly rely on [96boards documentation](https://github.com/96boards/documentation/wiki/HiKeyUEFI),
so kudos to 96boards and LeMaker for providing lot of information for developers.

## Obtain pre-compiled binaries

```
wget https://builds.96boards.org/snapshots/hikey/linaro/uefi/latest/l-loader.bin
wget https://builds.96boards.org/snapshots/hikey/linaro/uefi/latest/fip.bin
wget https://builds.96boards.org/snapshots/hikey/linaro/uefi/latest/ptable-linux-8g.img
wget https://builds.96boards.org/snapshots/hikey/linaro/uefi/latest/nvme.img
wget https://builds.96boards.org/releases/hikey/linaro/debian/latest/boot-fat.uefi.img.gz
wget http://builds.96boards.org/snapshots/hikey/linaro/debian/latest/hikey-jessie_developer_20160225-410.emmc.img.gz
gunzip *.img.gz
```

Clone eMMC flashing tool:

```
git clone https://github.com/96boards/burn-boot.git
```

Follow [flashing instructions](https://github.com/96boards/documentation/wiki/HiKeyUEFI#flash-binaries-to-emmc-).
For Debian-based systems you may need:

```
sudo apt-get install python-serial android-tools-fastboot
```

On my Debian I see in `dmesg`:

```
[21174.122832] usb 3-2.2: USB disconnect, device number 15
[21343.166870] usb 3-2.1.1: new full-speed USB device number 17 using xhci_hcd
[21343.268348] usb 3-2.1.1: New USB device found, idVendor=12d1, idProduct=3609
[21343.268352] usb 3-2.1.1: New USB device strings: Mfr=1, Product=4, SerialNumber=0
[21343.268353] usb 3-2.1.1: Product: \xffffffe3\xffffff84\xffffffb0㌲㔴㜶㤸
[21343.268355] usb 3-2.1.1: Manufacturer: 䕇䕎䥎
[21343.269159] option 3-2.1.1:1.0: GSM modem (1-port) converter detected
[21343.269271] usb 3-2.1.1: GSM modem (1-port) converter now attached to ttyUSB2
```

Correct command and UART log should look similar to this:

```
[17:11:36] pietrushnic:images $ sudo python ../src/burn-boot/hisi-idt.py --img1=l-loader.bin -d /dev/ttyUSB2
+----------------------+
(' Serial: ', '/dev/ttyUSB2')
(' Image1: ', 'l-loader.bin')
(' Image2: ', '')
+----------------------+

('Sending', 'l-loader.bin', '...')
Done
```

```
usb reset intr
reset device done.
start enum.
enum done intr
Enum is starting.
usb reset intr
enum done intr
NULL package
NULL package
USB ENUM OK.
init ser device done....
USB:: Err!! Unknown USB setup packet!
NULL package
USB:: Err!! Unknown USB setup packet!
NULL package
USB:: Err!! Unknown USB setup packet!
NULL package
USB:: Err!! Unknown USB setup packet!
NULL package
uFileAddress=ss=f9800800
uFileAddress=ss=f9800800

Switch to aarch64 mode. CPU0 executes at 0xf9801000!
```

As result I saw that green LED on board is on, then I proceed with fastboot
commands.

If above steps finish without the problems, then you know working procedure for
flashing all required components. Now let's proceed with fast boot and flashing
remaining components:

```
sudo fastboot flash ptable ptable-linux-8g.img
sudo fastboot flash fastboot fip.bin
sudo fastboot flash nvme nvme.img
sudo fastboot flash boot boot-fat.uefi.img
sudo fastboot flash system hikey-jessie_developer_20160225-410.emmc.img
```

Output should look like this:

```
$ sudo fastboot flash ptable ptable-linux-8g.img
target reported max download size of 268435456 bytes
sending 'ptable' (17 KB)...
OKAY [  0.001s]
writing 'ptable'...
OKAY [  0.004s]
finished. total time: 0.006s
$ sudo fastboot flash fastboot fip.bin
target reported max download size of 268435456 bytes
sending 'fastboot' (1383 KB)...
OKAY [  0.060s]
writing 'fastboot'...
OKAY [  0.135s]
finished. total time: 0.196s
$ sudo fastboot flash nvme nvme.img
target reported max download size of 268435456 bytes
sending 'nvme' (128 KB)...
OKAY [  0.006s]
writing 'nvme'...
OKAY [  0.007s]
finished. total time: 0.014s
$ sudo fastboot flash boot boot-fat.uefi.img
target reported max download size of 268435456 bytes
sending 'boot' (65536 KB)...
OKAY [  2.645s]
writing 'boot'...
OKAY [  3.258s]
finished. total time: 5.903s
$ sudo fastboot flash system hikey-jessie_developer_20160225-410.emmc.img
target reported max download size of 268435456 bytes
sending sparse 'system' (262140 KB)...
OKAY [ 10.692s]
writing 'system'...
OKAY [ 11.868s]
sending sparse 'system' (262140 KB)...
OKAY [ 10.786s]
writing 'system'...
OKAY [ 11.838s]
sending sparse 'system' (262140 KB)...
OKAY [ 10.791s]
writing 'system'...
OKAY [ 11.812s]
sending sparse 'system' (262140 KB)...
OKAY [ 10.720s]
writing 'system'...
OKAY [ 11.803s]
sending sparse 'system' (262140 KB)...
OKAY [ 10.833s]
writing 'system'...
OKAY [ 11.830s]
sending sparse 'system' (116064 KB)...
OKAY [  4.854s]
writing 'system'...
OKAY [  5.219s]
finished. total time: 123.047s
```

Remove Boot Select jumper (link 3-4) and power on platform.

### System configuration

Wireless network can be easily configured using [this instructions](https://github.com/96boards/documentation/wiki/HiKeyGettingStarted#wireless-network).
It is also required to setup DNS in `/etc/resolv.conf` ie.:

```
nameserver 8.8.8.8
```

### Bug hunting

There was time when I asked myself what I can do ? Where to start ? Good way to
analyze system compatibility (and find bugs) from firmware perspective is
[FirmwareTestSuit](https://wiki.ubuntu.com/FirmwareTestSuite/). It can be
cloned using:

```
git clone git://kernel.ubuntu.com/hwe/fwts.git
```

To compile:

```
apt-get update
apt-get install autoconf automake libglib2.0-dev libtool libpcre3-dev libjson0-dev flex bison dkms
autoreconf -ivf
./configure
make -j$(nproc)
```

To run:

```
./src/fwts
```

At point of writing this post only 13 tests passed. Most of testes (243) were
aborted since no support for given feature was detected. This results show that
there is plenty to do before getting well-supported firmware on HiKey.

```
Test           |Pass |Fail |Abort|Warn |Skip |Info |
---------------+-----+-----+-----+-----+-----+-----+
acpiinfo       |     |     |     |     |     |    2|
acpitables     |     |     |    1|     |     |     |
asf            |     |     |    1|     |     |     |
aspm           |     |     |     |     |    1|     |
aspt           |     |     |    1|     |     |     |
bert           |     |     |    1|     |     |     |
bgrt           |     |     |    1|     |     |     |
bmc_info       |     |     |     |     |    1|     |
boot           |     |     |    1|     |     |     |
checksum       |     |     |     |     |     |     |
cpep           |     |     |    1|     |     |     |
cpufreq        |    5|     |     |     |    2|     |
csrt           |     |     |    1|     |     |     |
dbg2           |     |     |    1|     |     |     |
dbgp           |     |     |    1|     |     |     |
dmicheck       |     |    1|     |     |    2|     |
drtm           |     |     |    1|     |     |     |
ecdt           |     |     |    1|     |     |     |
einj           |     |     |    1|     |     |     |
erst           |     |     |    1|     |     |     |
facs           |     |     |    1|     |     |     |
fadt           |     |     |    6|     |     |     |
fpdt           |     |     |    1|     |     |     |
gtdt           |     |     |    1|     |     |     |
hest           |     |     |    1|     |     |     |
iort           |     |     |    1|     |     |     |
klog           |     |     |     |     |     |     |
lpit           |     |     |    1|     |     |     |
madt           |     |     |    5|     |     |     |
maxreadreq     |    1|     |     |     |     |     |
mchi           |     |     |    1|     |     |     |
method         |     |     |  192|     |     |     |
mpst           |     |     |    1|     |     |     |
msct           |     |     |    1|     |     |     |
msdm           |     |     |    1|     |     |     |
mtd_info       |     |     |     |     |    1|     |
nfit           |     |     |    1|     |     |     |
olog           |     |     |     |     |    1|     |
oops           |    2|     |     |     |     |     |
pcct           |     |     |    1|     |     |     |
pmtt           |     |     |    1|     |     |     |
prd_info       |     |     |     |     |    1|     |
rsdp           |     |     |    1|     |     |     |
rsdt           |     |     |    1|     |     |     |
sbst           |     |     |    1|     |     |     |
securebootcert |     |     |    1|     |     |     |
slic           |     |     |    1|     |     |     |
slit           |     |     |    1|     |     |     |
spcr           |     |     |    1|     |     |     |
spmi           |     |     |    1|     |     |     |
srat           |     |     |    1|     |     |     |
stao           |     |     |    1|     |     |     |
syntaxcheck    |     |     |     |     |     |     |
tcpa           |     |     |    1|     |     |     |
tpm2           |     |     |    1|     |     |     |
uefi           |     |     |    1|     |     |     |
uefibootpath   |     |     |     |     |    1|     |
version        |     |     |     |     |    1|    3|
waet           |     |     |    1|     |     |     |
wakealarm      |    5|    1|     |     |     |     |
wdat           |     |     |    1|     |     |     |
wpbt           |     |     |    1|     |     |     |
xenv           |     |     |    1|     |     |     |
xsdt           |     |     |    1|     |     |     |
---------------+-----+-----+-----+-----+-----+-----+
Total:         |   13|    2|  248|    0|   11|    5|
---------------+-----+-----+-----+-----+-----+-----+
```

## Summary

As presented above HiKey developement process is not so simple. Using
precompiled binaries is very useful for presentation purposes, but adding
features to EDK2 will requires recompilation some of mentioned components.
Documentation is not easy to search as well as forum, key probablem is that it
needs more order, because various information (sometimes unrelated) are spread
actoss directories and repositories.

Nevertheless hacking ARMv8 firmware may be fun and there huge undiscovered area
to explore. Key question is what valid use cases may lead to extensive firmware
development in this area ? First I would look into features that have to be
exposed to operating system ie. verify boot for Linux OS use of TEE module in
Linux.

As always please share if you feel this is valuable and comment if you have any
questions or something is unclear.

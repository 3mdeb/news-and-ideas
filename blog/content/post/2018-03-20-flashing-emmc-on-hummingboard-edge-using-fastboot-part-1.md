---
ID: 64327
title: Flashing eMMC on Hummingboard Edge using fastboot? part 1
cover: /covers/hummingboard-edge.jpg
author: maciej.pijanowski
post_excerpt: ""
layout: post
published: true
date: 2018-03-20 11:06:44
archives: "2018"

tags:
  - u-boot
  - fastboot
  - i.MX6
categories:
  - Firmware
  - App Dev
---

## Introduction

Flashing an eMMC of produced board is one of the crucial manufacturing
procedures. This post series presents how one can take advantage of i.MX6
features and open source tools to prepare themselves with quite robust and easy
to use process.

Target reference platform is
[Hummingboard Edge](https://www.digikey.ch/htmldatasheets/production/1923179/0/0/1/srmx6sowt1d512e008e00ch.html).

## General concept

The general concept is inspired by
[this great bootlin (former FreeElectrons) post:](https://bootlin.com/blog/factory-flashing-with-u-boot-and-fastboot-on-freescale-i-mx6/)
I've run into some issues while trying to do something similar on Hummingbard
Edge, so decided to share my experience.

The general flow looks like:

- Load `U-Boot` to DDR using Serial Download Protocol
- `U-Boot` enters fastboot mode
- Pull in the image via fastboot protocol

In the first post, we will focus on loading `U-Boot` to DDR using SDP.

## Hardware preparation

Before we start, we need to prepare hardware first. HB Edge has USBOTG signals
connected to the upper back USB-A connector:

![hb usb back](/img/hb_edge_usb_back.png)

To utilize it we should prepare cable as suggested by the
[SolidRun wiki](http://web.archive.org/web/20160523073603/https://wiki.solid-run.com/doku.php?id=products%3Aimx6%3Amicrosom%3Aimx6-fuse)

They suggest cutting two USB cables in half to create USB-A male-male cable. To
make things easier we can buy one of those directly. An example of such is
[this one](https://www.amazon.com/UGREEN-Transfer-Enclosures-Printers-Cameras/dp/B00P0E394U/ref=sr_1_1?s=pc&ie=UTF8&qid=1516106592&sr=1-1&refinements=p_n_feature_eight_browse-bin%3A15562492011)

We still need one more rework:

- Remove the main insulation from the middle of the cable,
- Cut the power wire (usually the read one),
- Solder it back with additional series resistance. SolidRun suggest to use 1-10
  Ohms. I am using 2x10 Ohm resistors in parallel which gives me around 5 Ohms.

Resistors soldered on prototype board:

![resistors on prototype board](/img/hb_host_to_host_top.png)

Additional series resistance in power wire path:

![power cable soldered to resistors](/img/hb_host_to_host_bottom.png)

Connect USB A host to host cable to USB OTG port (upper port of U5 USB connector
on HB Edge board).

Now we should check whether the cable was prepared correctly. If it is, the USB
device should be detected as Freescale SoC in Recovery Mode:

```bash
Bus 002 Device 002: ID 15a2:0061 Freescale Semiconductor, Inc. i.MX 6Solo/6DualLite SystemOnChip in RecoveryMode
```

It may be convenient to set up an `udev` rule right away, so we can have access
to device as a user later:

```bash
echo &#039;SUBSYSTEM ==&quot;usb&quot;, ATTRS{idVendor}==&quot;15a2&quot;, ATTRS{idProduct}==&quot;0061&quot; , MODE=&quot;0666&quot;&#039;
| sudo tee /etc/udev/rules.d/51-fsl-flashing.rules
```

## imx-usb-loader

This is an open-source alternative to NXP `mfgtool`, which allows sending
binaries over UART or USB.

Getting `imx_usb_loader`:

```bash
sudo apt-get install libusb-dev libusb-1.0
git clone git@github.com:boundarydevices/imx_usb_loader.git
cd imx_usb_loader
make
```

Output are 2 files: `imx_uart` and `imx_usb` that allow to send files to
platform using UART or USB respectively.

`imx_usb_loader` is able to download a single file `u-boot.imx`. In case of
boards with `SPL` support, we have 2 binaries: `SPL` and `u-boot.img`. Loading
of both of them is possible using `imx_usb_loader`, but it is required to take
advantage of the
[U-Boot Serial Download Protocol support](https://github.com/u-boot/u-boot/blob/master/doc/imx/misc/sdp.txt)

U-Boot SDP support was introduced in October 2017. So we need at least v2017.11
release. I'm using the most recent v2018.01.

Following additional configuration options have to be selected to enable SDP
support in U-Boot:

```bash
CONFIG_SPL_USB_HOST_SUPPORT=y
CONFIG_SPL_USB_GADGET_SUPPORT=y
CONFIG_SPL_USB_SDP_SUPPORT=y
CONFIG_USB_GADGET=y
CONFIG_USB_GADGET_DOWNLOAD=y
CONFIG_USB_FUNCTION_SDP=y
```

### Load SPL and u-boot.img separately

- Copy `SPL` and `u-boot.img` output files to the root directory of the
  `imx_usb_loader` tool
- Send `SPL` via USB:

```bash
./imx_usb SPL
```

output:

```bash
config file &lt;.//imx_usb.conf&gt;
vid=0x066f pid=0x3780 file_name=mx23_usb_work.conf
vid=0x15a2 pid=0x004f file_name=mx28_usb_work.conf
vid=0x15a2 pid=0x0052 file_name=mx50_usb_work.conf
vid=0x15a2 pid=0x0054 file_name=mx6_usb_work.conf
vid=0x15a2 pid=0x0061 file_name=mx6_usb_work.conf
vid=0x15a2 pid=0x0063 file_name=mx6_usb_work.conf
vid=0x15a2 pid=0x0071 file_name=mx6_usb_work.conf
vid=0x15a2 pid=0x007d file_name=mx6_usb_work.conf
vid=0x15a2 pid=0x0080 file_name=mx6_usb_work.conf
vid=0x1fc9 pid=0x0128 file_name=mx6_usb_work.conf
vid=0x15a2 pid=0x0076 file_name=mx7_usb_work.conf
vid=0x1fc9 pid=0x0126 file_name=mx7ulp_usb_work.conf
vid=0x15a2 pid=0x0041 file_name=mx51_usb_work.conf
vid=0x15a2 pid=0x004e file_name=mx53_usb_work.conf
vid=0x15a2 pid=0x006a file_name=vybrid_usb_work.conf
vid=0x066f pid=0x37ff file_name=linux_gadget.conf
vid=0x1b67 pid=0x4fff file_name=mx6_usb_sdp_spl.conf
vid=0x0525 pid=0xb4a4 file_name=mx6_usb_sdp_spl.conf
config file &lt;.//mx6_usb_work.conf&gt;
parse .//mx6_usb_work.conf
Trying to open device vid=0x15a2 pid=0x0061
Interface 0 claimed
HAB security state: development mode (0x56787856)
== work item
filename SPL
load_size 0 bytes
load_addr 0x00000000
dcd 1
clear_dcd 0
plug 1
jump_mode 2
jump_addr 0x00000000
== end work item
No dcd table, barker=402000d1

loading binary file(SPL) to 00907400, skip=0, fsize=ac00 type=aa

&lt;&lt;&lt;44032, 44032 bytes&gt;&gt;&gt;
succeeded (status 0x88888888)
jumping to 0x00907400
```

- HB serial console output will show:

```bash
U-Boot SPL 2018.01-00001-gceb4ce4f78fb-dirty (Jan 16 2018 - 15:04:11)
Trying to boot from USB SDP
SDP: initialize...
SDP: handle requests...
```

Notice that once `SPL` is loaded, and target board enters `SDP` handler state,
the USB device seen by host PC will change.

In my case it changed from:

```bash
Bus 003 Device 013: ID 15a2:0061 Freescale Semiconductor, Inc. i.MX 6Solo/6DualLite SystemOnChip in RecoveryMode
```

to:

```bash
Bus 003 Device 014: ID 0000:0fff
```

It does not look like a proper USB device VID / PID pair. Even if we set those
in `imx_usb.conf`:

```bash
echo &#039;0x0000:0x0fff, mx6_usb_sdp_spl.conf&#039; &gt;&gt; imx_usb.conf
```

We are getting following error message from the tool:

```bash
vid/pid cannot be 0: mx6_usb_sdp_spl.conf
[0x0000:0x0fff, mx6_usb_sdp_spl.conf
]
no matching USB device found
```

The
[U-Boot SDP documentation](https://github.com/u-boot/u-boot/blob/master/doc/imx/misc/sdp.txt#L47)
states that those values should be set by configuration options:
`CONFIG_G_DNL_(VENDOR|PRODUCT)_NUM` and it should default to:

```bash
0x1b67:0x4fff, mx6_usb_sdp_spl.conf
```

Grepping `U-Boot` sources shows only a few of those options in some of the board
config files:

```bash
./configs/chromebook_minnie_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/fennec-rk3288_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/rock2_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/tinker-rk3288_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/phycore-rk3288_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/evb-rk3288_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/chromebit_mickey_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/chromebook_jerry_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/popmetal-rk3288_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/miqi-rk3288_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/vyasa-rk3288_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x2207
./configs/firefly-rk3288_defconfig:CONFIG_G_DNL_VENDOR_NUM=0x220
```

Quick search through configuration options shows that gadget USB VID / PID is
set through following options:

```bash
config USB_GADGET_VENDOR_NUM
 hex &quot;Vendor ID of the USB device&quot;
 default 0x1f3a if ARCH_SUNXI
 default 0x0
 help
 Vendor ID of the USB device emulated, reported to the host device.
 This is usually the board or SoC vendor&#039;s, unless you&#039;ve registered
 for one.

config USB_GADGET_PRODUCT_NUM
 hex &quot;Product ID of the USB device&quot;
 default 0x1010 if ARCH_SUNXI
 default 0x0
 help
 Product ID of the USB device emulated, reported to the host device.
```

The strange thing to me is that PID defaults to 0x0, while in my case it is
detected as `0x0000:0x0fff`.

Setting those to the ones as described in the documentation:

```bash
CONFIG_USB_GADGET_VENDOR_NUM=0x1b67
CONFIG_USB_GADGET_PRODUCT_NUM=0x4fff
```

Gives us following results:

- `lsusb` output gives following output:

```bash
Bus 003 Device 010: ID 1b67:5ffe
```

Note that in this case the PID is also different than specified in the
configuration.

I have also used the
[recent master branch](https://github.com/u-boot/u-boot/commit/3759df0c0810636b31fe64c56868aa831514e509)
and above information applies there as well.

In this case, we are able to flash `u-boot.img` via SDP.

On more thing to do before flashing `u-boot.img` is to add VID / PID pair to
`imx_usb` config:

```bash
echo &#039;0x1b67:0x5ffe, mx6_usb_sdp_spl.conf&#039; &gt;&gt; imx_usb.conf
```

Now we can download `SPL` and `u-boot.img` with command below:

```bash
./imx_usb SPL &amp;&amp; sleep 1 &amp;&amp; ./imx_usb u-boot.img
```

output of `u-boot.img` booting:

```bash
U-Boot SPL 2018.01-00272-g0434429f989d (Jan 18 2018 - 12:56:59)
Trying to boot from USB SDP
SDP: initialize...
SDP: handle requests...
Downloading file of size 357536 to 0x177fffc0... done
Jumping to the header at 0x177fffc0
Header Tag is not an IMX image


U-Boot 2018.01-00272-g0434429f989d (Jan 18 2018 - 12:56:59 +0100)

CPU:   Freescale i.MX6DL rev1.3 996 MHz (running at 792 MHz)
CPU:   Commercial temperature grade (0C to 95C) at 60C
Reset cause: POR
Board: MX6 Hummingboard2
DRAM:  1 GiB
MMC:   FSL_SDHC: 0
Card did not respond to voltage select!
mmc_init: -95, time 58
*** Warning - MMC init failed, using default environment

No panel detected: default to HDMI
Display: HDMI (1024x768)
In:    serial
Out:   serial
Err:   serial
Net:   FEC
Hit any key to stop autoboot:  0
Card did not respond to voltage select!
mmc_init: -95, time 58
** Bad device mmc 0 **
Card did not respond to voltage select!
mmc_init: -95, time 57

Device 0: Model:  Firm:  Ser#:
Type: Hard Disk
Capacity: not available
... is now current device
** Bad device size - sata 0 **
starting USB...
USB0:   Port not available.
USB1:   USB EHCI 1.00
scanning bus 1 for devices... 2 USB Device(s) found
scanning usb for storage devices... 0 Storage Device(s) found

Device 0: device type unknown
... is now current device
** Bad device usb 0 **
** Bad device usb 0 **
FEC Waiting for PHY auto negotiation to complete.
```

The interesting thing is that whenever we enter `U-Boot` prompt and enter `SDP`
mode:

```bash
=&gt; sdp
sdp - Serial Downloader Protocol

Usage:
sdp &lt;USB_controller&gt;
- serial downloader protocol via &lt;USB_controller&gt;

=&gt; sdp 0
SDP: initialize...
SDP: handle requests...
```

The USB PID seen by my host PC changes to the one set in the configuration:

```bash
Bus 003 Device 025: ID 1b67:4fff
```

### Load SPL and u-boot.img in one run

It is possible to download both `SPL` and `u-boot.img` with one `imx_usb`
command execution. To do that, we need to create configuration files with
following content:

- `imx_usb.conf`:

```bash
cat &lt;&lt; EOF &gt; imx_usb.conf
#vid:pid, config_file
0x15a2:0x0061, mx6_usb_rom.conf, 0x1b67:0x5ffe, mx6_usb_sdp_spl.conf
EOF
```

- `mx6_usb_rom.conf`

```bash
cat &lt;&lt; EOF &gt; mx6_usb_rom.conf
mx6_qsb
hid,1024,0x910000,0x10000000,1G,0x00900000,0x40000
SPL:jump header2
EOF
```

- `mx6_usb_sdp_spl.conf`:

```bash
cat &lt;&lt; EOF &gt; mx6_usb_sdp_spl.conf
mx6_spl_sdp
hid,uboot_header,1024,0x10000000,1G,0x00907000,0x31000
u-boot.img:jump header2
EOF
```

Above configuration files are also present in
[3mdeb fork of imx_usb_loader](https://github.com/3mdeb/imx_usb_loader/commit/f720ad599c2b1f4e7d90f7e5c5378e97172db185)

With such configuration in place, calling `./imx_usb` gives following output:

```bash
config file &lt;.//imx_usb.conf&gt;
vid=0x15a2 pid=0x0061 file_name=mx6_usb_rom.conf
-&gt; vid=0x1b67 pid=0x5ffe file_name=mx6_usb_sdp_spl.conf
config file &lt;.//mx6_usb_rom.conf&gt;
parse .//mx6_usb_rom.conf
Trying to open device vid=0x15a2 pid=0x0061
Interface 0 claimed
HAB security state: development mode (0x56787856)
== work item
filename SPL
load_size 0 bytes
load_addr 0x13f00000
dcd 0
clear_dcd 0
plug 0
jump_mode 3
jump_addr 0x00000000
== end work item

loading binary file(SPL) to 00907400, skip=0, fsize=dc00 type=aa

&lt;&lt;&lt;56320, 56320 bytes&gt;&gt;&gt;
succeeded (status 0x88888888)
jumping to 0x00907400
config file &lt;.//mx6_usb_sdp_spl.conf&gt;
parse .//mx6_usb_sdp_spl.conf
Trying to open device vid=0x1b67 pid=0x5ffe.
Interface 0 claimed
HAB security state: development mode (0x56787856)
== work item
filename u-boot.img
load_size 0 bytes
load_addr 0x03f00001
dcd 0
clear_dcd 0
plug 0
jump_mode 3
jump_addr 0x00000000
== end work item

loading binary file(u-boot.img) to 177fffc0, skip=0, fsize=574a0 type=aa

&lt;&lt;&lt;357536, 358400 bytes&gt;&gt;&gt;
succeeded (status 0x88888888)
jumping to 0x177fffc0
```

and the board boots with `U-Boot` as shown previously.

## Summary

- `imx_usb_loader` is really handy tool for downloading binaries (especially the
  bootloader) directly into memory.
- I've run into some strange behavior of `U-Boot` USB Gadget device `PID`. I
  will try to track down what really happens in the code there.
- I've run into some outdated `U-Boot` documentation. I can try updating it.
- Configuration files for `imx_usb_loader` can be found at
  [3mdeb fork](https://github.com/3mdeb/imx_usb_loader/commit/f720ad599c2b1f4e7d90f7e5c5378e97172db185)
- Final configuration of `U-Boot` target for Hummingboard Edge which adds `SDP`
  support can be found on
  [3mdeb fork](https://github.com/3mdeb/u-boot/commit/5f34b679439978f7eeb29a2f52b9c81a68766b82)
- I am going to present next steps towards our goal in an upcoming post from
  this series.

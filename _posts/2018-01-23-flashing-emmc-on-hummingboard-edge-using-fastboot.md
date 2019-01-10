---
post_title: Flashing eMMC on Hummingboard Edge using fastboot
author: Maciej Pijanowski
post_excerpt: ""
layout: post
published: true
post_date: 2018-01-23 12:00:00
tags:
  - U-Boot
  - fastboot
  - eMMC
  - Hummingboard
  - i.MX6
categories:

---

# Introduction

Flashing an eMMC of produced board is one of the crucial manufacturing
procedures. This post presents how one can take advantage of i.MX6 features and
open source tools to prepare themselves with quite robust and easy to use
process.

Target reference platform is
[Hummingboard Edge](https://www.solid-run.com/product/hummingboard-edge-imx6d-0c-e/https://www.solid-run.com/product/hummingboard-edge-imx6d-0c-e/).

# General concept

The general concept is inspired by
[great FreeElectros post:](https://free-electrons.com/blog/factory-flashing-with-u-boot-and-fastboot-on-freescale-i-mx6/)
I've run into some issues while trying to do something similar on Hummingbard
Edge, so decided to share my experience.

The general flow looks like:

* Load `U-Boot` to RAM using Serial Download Protocol

* `U-Boot` enters fastboot mode

* Pull in image via fastboot protocol

Let's break those one by one.

# Hardware preparation

Before we start, we need to prepare hardware first. HB Edge has USBOTG signals
connected to the upper back USB-A connector:

![hb usb back](images/hb_edge_usb_back.png)

To utilize it we should prepare cable as suggested by the
[SolidRun wiki](https://wiki.solid-run.com/doku.php?id=products:imx6:microsom:imx6-fuse)

They suggest to cut two USB cables in half to create USB-A male-male cable.
To make things easier we can buy one of those directly. An example of such is
[this one](https://www.amazon.com/UGREEN-Transfer-Enclosures-Printers-Cameras/dp/B00P0E394U/ref=sr_1_1?s=pc&ie=UTF8&qid=1516106592&sr=1-1&refinements=p_n_feature_eight_browse-bin%3A15562492011)

We still need one more rework:

* Remove the main insulation from the middle of the cable,

* Cut the power wire (usually the read one),

* Solder it back with additional series resistance. SolidRun suggest to use
  1-10 Ohms. I am using 2x10 Ohm resistors in parallel which gives me around 5
  Ohms.

Resistors soldered on prototype board:

![resistors on prototype board](images/hb_host_to_host_top.png)

Additional series resistance in power wire path:

![power cable soldered to resistors](images/hb_host_to_host_bottom.png)

Connect USB A host to host cable to USB OTG port (upper port of U5 USB connector
on HB Edge board).

Now we should check whether cable was prepared correctly. If if is, the USB
device should be detected as Freescale SoC in Recovery Mode:

  ```
  Bus 002 Device 002: ID 15a2:0061 Freescale Semiconductor, Inc. i.MX 6Solo/6DualLite SystemOnChip in RecoveryMode
  ```

It may be convenient to set up an `udev` rule right away, so we can have access
to device as a user later:

  ```
  echo 'SUBSYSTEM =="usb", ATTRS{idVendor}=="15a2", ATTRS{idProduct}=="0061" , MODE="0666"' | sudo tee /etc/udev/rules.d/51-fsl-flashing.rules
  ```

# imx-usb-loader

This is an open-source alternative to NXP `mfgtool`, which allows to send
binaries over UART or USB.

Getting `imx_usb_loader`:

  ```
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
[U-Boot Serial Download Protocol support](https://github.com/u-boot/u-boot/blob/master/doc/README.sdp)

U-Boot SDP support was introduced in October 2017. So we need at least v2017.11
release. I'm using the most recent v2018.01.

Following additional configuration options have to be selected to enable SDP
support:

  ```
  CONFIG_SPL_USB_GADGET_SUPPORT=y
  CONFIG_SPL_USB_SDP_SUPPORT=y
  CONFIG_CMD_USB_SDP=y
  ```

## Load SPL and u-boot.img separately

* Copy `SPL` and `u-boot.img` output files to the root directory of the
  `imx_usb_loader` tool

* Send `SPL` via USB:

  ```
  ./imx_usb SPL
  ```

output:

  ```
  config file <.//imx_usb.conf>
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
  config file <.//mx6_usb_work.conf>
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

  <<<44032, 44032 bytes>>>
  succeeded (status 0x88888888)
  jumping to 0x00907400
  ```

* HB serial console output will show:

  ```
  U-Boot SPL 2018.01-00001-gceb4ce4f78fb-dirty (Jan 16 2018 - 15:04:11)
  Trying to boot from USB SDP
  SDP: initialize...
  SDP: handle requests...
  ```

Notice that once `SPL` is loaded, and target board enters `SDP` handler state,
the USB device seen by host PC will change.

In my case it changed from:

  ```
  Bus 003 Device 013: ID 15a2:0061 Freescale Semiconductor, Inc. i.MX 6Solo/6DualLite SystemOnChip in RecoveryMode
  ```

to:

  ```
  Bus 003 Device 014: ID 0000:0fff
  ```

It does not look like a proper USB device VID / PID pair.
Even if we set those in `imx_usb.conf`:

  ```
  echo '0x0000:0x0fff, mx6_usb_sdp_spl.conf' >> imx_usb.conf
  ```

We are getting following error message from the tool:

  ```
  vid/pid cannot be 0: mx6_usb_sdp_spl.conf
   [0x0000:0x0fff, mx6_usb_sdp_spl.conf
  ]
  no matching USB device found
  ```

The
[U-Boot SDP documentation](https://github.com/u-boot/u-boot/blob/master/doc/README.sdp#L47)
states that those values should be set by configuration options:
`CONFIG_G_DNL_(VENDOR|PRODUCT)_NUM` and it should default to:

  ```
  0x1b67:0x4fff, mx6_usb_sdp_spl.conf
  ```

Grepping `U-Boot` sources shows only a few of those options in some of the
board config files:

  ```
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

  ```
  config USB_GADGET_VENDOR_NUM
  	hex "Vendor ID of the USB device"
  	default 0x1f3a if ARCH_SUNXI
  	default 0x0
  	help
  	  Vendor ID of the USB device emulated, reported to the host device.
  	  This is usually the board or SoC vendor's, unless you've registered
  	  for one.

  config USB_GADGET_PRODUCT_NUM
  	hex "Product ID of the USB device"
  	default 0x1010 if ARCH_SUNXI
  	default 0x0
  	help
  	  Product ID of the USB device emulated, reported to the host device.
  ```

The strange thing to me is that PID defaults to 0x0, while on my case it is
detected as `0x0000:0x0fff`.

Setting those to the ones as described in the documentation:

  ```
  CONFIG_USB_GADGET_VENDOR_NUM=0x1b67
  CONFIG_USB_GADGET_PRODUCT_NUM=0x4fff
  ```

Gives us following results:

* `lsusb` output gives following output:

  ```
  Bus 003 Device 010: ID 1b67:5ffe
  ```

Note that in this case the PID is also different than specified in the
configuration.

I have also used the
[recent master branch](https://github.com/u-boot/u-boot/commit/3759df0c0810636b31fe64c56868aa831514e509)
and above information applies there as well.

In this case, we are able to flash `u-boot.img` via SDP.

On more thing to do before flashing `u-boot.img` is to add VID / PID pair
to `imx_usb` config:

  ```
  echo '0x1b67:0x5ffe, mx6_usb_sdp_spl.conf' >> imx_usb.conf
  ```

Now we can download `SPL` and `u-boot.img` with command below:

  ```
  ./imx_usb SPL && sleep 1 && ./imx_usb u-boot.img
  ```

output of `u-boot.img` booting:

  ```
  U-Boot SPL 2018.01-00272-g0434429f989d (Jan 18 2018 - 12:56:59)
  Trying to boot from USB SDP
  SDP: initialize...
  SDP: handle requests...
  Downloading file of size 357536 to 0x177fffc0... done
  Jumping to header at 0x177fffc0
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

  ```
  => sdp
  sdp - Serial Downloader Protocol

  Usage:
  sdp <USB_controller>
    - serial downloader protocol via <USB_controller>

  => sdp 0
  SDP: initialize...
  SDP: handle requests...
  ```

The USB PID seen by my host PC changes to the one set in the configuration:

  ```
  Bus 003 Device 025: ID 1b67:4fff
  ```

## Load SPL and u-boot.img in one run

It is possible to download both `SPL` and `u-boot.img` with one `imx_usb`
command execution. To do that, I had to create configuration files with
following content:

* `imx_usb.conf`:

```
cat << EOF > imx_usb.conf
#vid:pid, config_file
0x15a2:0x0061, mx6_usb_rom.conf, 0x1b67:0x5ffe, mx6_usb_sdp_spl.conf
EOF
```

* `mx6_usb_rom.conf`

```
cat << EOF > mx6_usb_rom.conf
mx6_qsb
hid,1024,0x910000,0x10000000,1G,0x00900000,0x40000
SPL:jump header2
EOF
```

* `mx6_usb_sdp_spl.conf`:

```
cat << EOF > mx6_usb_sdp_spl.conf
mx6_spl_sdp
hid,uboot_header,1024,0x10000000,1G,0x00907000,0x31000
u-boot.img:jump header2
EOF
```

Above configuration files are also present in
[3mdeb fork of imx_usb_loader](git@github.com:3mdeb/imx_usb_loader.git)

With such configuration in place, calling `./imx_usb` gives me following output:

  ```
  config file <.//imx_usb.conf>
  vid=0x15a2 pid=0x0061 file_name=mx6_usb_rom.conf
  -> vid=0x1b67 pid=0x5ffe file_name=mx6_usb_sdp_spl.conf
  config file <.//mx6_usb_rom.conf>
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

  <<<56320, 56320 bytes>>>
  succeeded (status 0x88888888)
  jumping to 0x00907400
  config file <.//mx6_usb_sdp_spl.conf>
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

  <<<357536, 358400 bytes>>>
  succeeded (status 0x88888888)
  jumping to 0x177fffc0
  ```

and the board boots with `U-Boot` as shown previously.

## Summary

* `imx_usb_loader` is really handy tool

* I've run into some strange behavior of `U-Boot` USB Gadget device `PID`. I
  will try to track down what really happens in the code there.

* I've run into some outdated `U-Boot` documentation. I can try updating it.

* Configuration files for `imx_usb_loader` can be found at
  [3mdeb fork](https://github.com/3mdeb/imx_usb_loader/commit/f720ad599c2b1f4e7d90f7e5c5378e97172db185)

* Final configuration of `U-Boot` target for Hummingboard Edge which add `SDP`
  support can be found on
  [3mdeb fork](https://github.com/3mdeb/u-boot/commit/5f34b679439978f7eeb29a2f52b9c81a68766b82)

# fastboot

[FastBoot protocol](https://android.googlesource.com/platform/system/core/+/2ec418a4c98f6e8f95395456e1ad4c2956cac007/fastboot/fastboot_protocol.txt)
is a tool developed for Android, which allows for communicating with
bootloaders over USB or Ethernet.

## U-Boot configuration

[U-Boot fastboot documentation](https://github.com/u-boot/u-boot/blob/master/doc/README.android-fastboot#L36)
suggests to set `CONFIG_USB_GADGET_(VENDOR_NUM|PRODUCT_NUM|MANUFACTURER)`.

> Note that `USB_GADGET_VENDOR_NUM` and `USB_GADGET_PRODUCT_NUM` is not related
> to your actual board, rather it is some dummy id of device which is
> compatible with fastboot. In this case it is
> [CelkonA88 device from Google](https://www.phonearena.com/phones/Celkon-A88_id7307).

## Fastboot client

Install fastboot:

On Debian-based distros:

  ```
  sudo apt install fastboot
  ```

Installation for other popular distros should be straightforward as well.

## First test - U-Boot from SD card

The purpose is to confirm that `fastboot` command is there and that we can
establish a connection with fastboot client.

[U-Boot fastboot Documentation](https://github.com/u-boot/u-boot/blob/master/doc/README.android-fastboot#L102)
suggests that we only need to execute `fastboot` command in U-Boot prompt.
Notice that now this command requires a parameter:

  ```
  => fastboot
  Command failed, result=-1
  fastboot - use USB Fastboot protocol

  Usage:
  fastboot <USB_controller>
      - run as a fastboot usb device
  ```

`USB_controller` parameter is not that well documented, but it looks like that
it is USB controller number.

What is odd is that providing any character as this parameter results in no
error message and allows to establish successful connection:

  ```
  fastboot 0
  fastboot 1
  fastboot -
  fastboot qwerty
  etc.
  ```

After running fastboot on HB, you should see new USB device enumerated on
host:

  ```
  Bus 003 Device 075: ID 18d1:0d02 Google Inc. Celkon A88
  ```

We can add another `udev` rule at this point in order to use `fastboot` command
without the need of root privileges:

  ```
  echo 'SUBSYSTEM =="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="0d02" , MODE="0666"' | sudo tee -a /etc/udev/rules.d/51-fsl-flashing.rules
  ```

Following command should return available fastboot devices:

  ```
  fastboot devices
  ```

output:

  ```
  ????????????	fastboot
  ```

This one should return bootloader version:

  ```
  fastboot getvar bootloader-version
  ```

output:

  ```
  bootloader-version: U-Boot 2018.01-00272-g0434429f989d-dirty
  finished. total time: 0.000s
  ```

## Second test - U-Boot from DRAM

In order to enable `fastboot` support I needed to change USB_GADGET VID / PID
in `U-boot` configuration. It means that our `imx_usb_loader` configuration
files needs an adjustment.

`imx_usb.conf` file needs following content:

  ```
  #vid:pid, config_file
  0x15a2:0x0061, mx6_usb_rom.conf, 0x18d1:0x1d01, mx6_usb_sdp_spl.conf
  ```

Above change is introduced in
[this commit](https://github.com/3mdeb/imx_usb_loader/commit/76f0b35911474a3bb1989f2fa03ea8bb61ae29c4)

Notice that PID in the second entry is not the same as was set in `U-Boot`
configuration. This is the same issue as presented in case of `SDP` USB gadget
device: detected PID in SPL mode is a little bit different than the one set in
the configuration.

However, once `U-boot` gets loaded and we enter `fastboot 0` in prompt, it gets
back to the correct one:

  ```
  Bus 003 Device 040: ID 18d1:0d02 Google Inc. Celkon A88
  ```

Let's try if communication over fastboot protocol is working in this case as well:

  ```
  fastboot getvar bootloader-version
  ```

output:

  ```
  bootloader-version: U-Boot 2018.01-00272-g0434429f989d-dirty
  finished. total time: 0.000s
  ```

## Enter fastboot mode by default

To automate things, we should force `U-Boot` to enter fastboot mode
automatically on boot.

At first, fast and easy way that came to mind mind was to edit `distro_bootcmd`
variable content:

```
diff --git a/include/config_distro_bootcmd.h b/include/config_distro_bootcmd.h
index 5c469a23fa70..4dde1cf18967 100644
--- a/include/config_distro_bootcmd.h
+++ b/include/config_distro_bootcmd.h
@@ -389,10 +389,7 @@
        \
        BOOT_TARGET_DEVICES(BOOTENV_DEV)                                  \
        \
-       "distro_bootcmd=" BOOTENV_SET_SCSI_NEED_INIT                      \
-               "for target in ${boot_targets}; do "                      \
-                       "run bootcmd_${target}; "                         \
-               "done\0"
+       "distro_bootcmd= fastboot 0\0"

```

A more elegant way would be to set `BOOTCOMMAND` config options in
`configs/mx6cuboxi_fastboot_defconfig` instead:

  ```
  CONFIG_BOOTCOMMAND="fastboot 0"
  ```

To speed things up, it is worth to reduce boot delay to 0 by setting
configuration option:

  ```
  CONFIG_BOOTDELAY=0
  ```

## Using `fastboot flash` command

By default `fastboot` uses GPT partition name as a parameter. Antoine from
FreeElectrons in
[his post](https://free-electrons.com/blog/factory-flashing-with-u-boot-and-fastboot-on-freescale-i-mx6/)
provides an
[U-Boot patch with workaround](https://bootlin.com/pub/2015/imx-flash/0001-fastboot-allow-to-flash-at-a-given-address.patch)
which allows to pass eMMC offset address instead.

It's been a while since it was published and it no longer applies due to the
changes in `U-Boot` source code. I have decided to update it and it can be
found in the
[3mdeb fork of U-Boot](https://github.com/3mdeb/u-boot/commit/13e621b09bfeea05e51079a80cb85f1027de657f)

## Summary

* I've also run into some inconsistencies in `U-Boot` code vs documentation. I
  will try to see what's going in the code and update the doc if possible.

* `U-Boot` target configuration for Hummingboard Edge with fastboot support as
  described above is available in
  [3mdeb fork of U-Boot](https://github.com/3mdeb/u-boot/commit/517c2b14b89cec42e5bfb42dd2cfddb04629d96c)

# Booting from eMMC

## eFUSE settings

Note that, in order to boot from eMMC, you need either unfused SoM or fused to
boot from eMMC.  Jumper settings for boot selection can be found at `Edge/Gate
Boot Jumpers` section of
[SolidRun Hummingboard wiki page](https://wiki.solid-run.com/doku.php?id=products:imx6:hummingboard)

Fusing instructions to boot from eMMC can be found at `Blowing fuses to from
eMMC (HummingBoard2 eMMC or MicroSOM rev 1.5 on-SOM eMMC)` section of
[SolidRun wiki eFuses page](https://wiki.solid-run.com/doku.php?id=products:imx6:microsom:imx6-fuse-developers)

You can check fusing settings with:

  ```
  HummingBoard2 U-Boot > fuse read 0 5
  Reading bank 0:

  Word 0x00000005: 00002840

  HummingBoard2 U-Boot > fuse read 0 6
  Reading bank 0:

  Word 0x00000006: 00000010
  ```

In above example, it is fused to boot from uSD card, and cannot be overwritten
by GPIO settings. It means that this particular SoM cannot be set to boot from
eMMC anymore.

In my case SoM on HummingBoard2 is fused to boot from uSD card, so I will not
be able to present booting from eMMC on HummingBoard2 at the moment, but we
have [Vitro Crystal](https://vitro.io/vitro-crystal.html) boards, which is based
on the same SoC. It's not fused, so I will continue with this board, but process
is the same on HummingBoard2. As I said, this board is not fused and below
values confirms it.

  ```
  => fuse read 0 5
  Reading bank 0:

  Word 0x00000005: 00000000
  => fuse read 0 6
  Reading bank 0:

  Word 0x00000006: 00000000
  ```

## Image flashing

I'm mostly using `Yocto` for the builds. Thanks to
[wic](http://www.yoctoproject.org/docs/current/dev-manual/dev-manual.html#creating-partitioned-images-using-wic)
I can get one output image file with already created desired partition layout.

We should also keep in mind that a single file send via `fastboot` protocol
cannot be larger that the buffer size. Size of the buffer is set via
`CONFIG_FASTBOOT_BUF_SIZE` `U-Boot` configuration option. In our case it was
set to 512 MB. Of course it needs to fit into device's memory.

Regarding that we have modified `fastboot` to take eMMC offset as an argument,
I can see two potential ways of flashing an image.

### Image decomposition

We can send each of the components one by one. An example could look like:
* MBR sector,
* bootloader,
* boot partition,
* rootfs 1,
* data partition.

We can extract MBR from image file:

  ```
  gzip -cdk core-image-minimal.rootfs.wic.gz | sudo dd of=mbr.img bs=512 count=1
  ```

We can verify it's MBR by looking at it's hexdump:

  ```
  hexdump mbr.img
  ```

dump output:

  ```
  0000000 b8fa 1000 d08e 00bc b8b0 0000 d88e c08e
  0000010 befb 7c00 00bf b906 0200 a4f3 21ea 0006
  0000020 be00 07be 0438 0b75 c683 8110 fefe 7507
  0000030 ebf3 b416 b002 bb01 7c00 80b2 748a 8b01
  0000040 024c 13cd 00ea 007c eb00 00fe 0000 0000
  0000050 0000 0000 0000 0000 0000 0000 0000 0000
  *
  00001b0 0000 0000 0000 0000 5c4e 60a8 0000 0080
  00001c0 1001 030c 0f60 0800 0000 8000 0000 0000
  00001d0 1041 0383 ffe0 8800 0000 d9c4 0011 0000
  00001e0 0000 0000 0000 0000 0000 0000 0000 0000
  00001f0 0000 0000 0000 0000 0000 0000 0000 aa55
  ```

For example, in this case the fist partition is marked as boot partition (`0x80`
as first byte of partition description):

  ```
  00001b0 0000 0000 0000 0000 5c4e 60a8 0000 0080
  ```

The others are not (`0x00` instead).

Each MBR should also end with two bytes (`0x55AA`):

  ```
  00001f0 0000 0000 0000 0000 0000 0000 0000 aa55
  ```

Let's check the partition table on the eMMC by booting from uSD card before
flashing the `mbr.img`:

```
root@vitroTV:~# fdisk -l /dev/mmcblk1
Disk /dev/mmcblk1: 7.3 GiB, 7818182656 bytes, 15269888 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

Like you can see above, there are no partitions yet. Let's flash `mbr.img` on
eMMC using `fastboot`:

  ```
  fastboot flash 0x0 mbr.img
  ```

host output:

  ```
  target reported max download size of 536870912 bytes
  sending '0x0' (0 KB)...
  OKAY [  0.003s]
  writing '0x0'...
  OKAY [  0.050s]
  finished. total time: 0.054s
  ```

target output:

  ```
  Starting download of 512 bytes

  downloading of 512 bytes finished
  GUID Partition Table Header signature is wrong: 0x0 != 0x5452415020494645
  part_get_info_efi: *** ERROR: Invalid GPT ***
  GUID Partition Table Header signature is wrong: 0x0 != 0x5452415020494645
  part_get_info_efi: *** ERROR: Invalid Backup GPT ***
  bad MBR sector signature 0x0000
  Flashing Raw Image
  ........ wrote 512 bytes to 0x0
  ```

Now let's verify the partition table on the eMMC again:

  ```
  root@vitroTV:~# fdisk -l /dev/mmcblk1
  ```

We can see that `MBR` was flashed correctly to eMMC:

  ```
  root@vitroTV:~# fdisk -l /dev/mmcblk1
  Disk /dev/mmcblk1: 7.3 GiB, 7818182656 bytes, 15269888 sectors
  Units: sectors of 1 * 512 = 512 bytes
  Sector size (logical/physical): 512 bytes / 512 bytes
  I/O size (minimum/optimal): 512 bytes / 512 bytes
  Disklabel type: dos
  Disk identifier: 0x60a85c4e

  Device         Boot Start     End Sectors   Size Id Type
  /dev/mmcblk1p1 *     2048   34815   32768    16M  c W95 FAT32 (LBA)
  /dev/mmcblk1p2      34816 1204675 1169860 571.2M 83 Linux
  ```

Now we should continue with flashing `U-Boot` and partitions. The drawbacks I
can see are:

* We would need to decompose disk image which is already assembled by the build
  system.

* We would need to compute offset of each component to pass as a `fastboot`
  command argument. They may change over time.

* Partitions size may be grater than possible buffer size.

### Image splitting and flashing

The other idea is to split whole image file into data chunks of size not grater
than the fastboot buffer size. This way we can keep all the image layout
information exclusively in the build system. We can use `split` tool for this:

  ```
  split -b 512M -d core-image-minimal.wic image_split_dir/image.
  ```

In this case, size of core-image-minimal.wic is about 620M, so there will be two
chunks only: `image.00` and `image.01`

- flash first chunk:

  ```
  fastboot flash 0x0 image.00
  ```

target output:

  ```
  WARNING: unknown variable: partition-type:0x0
  Starting download of 536870912 bytes
  downloading of 536870912 bytes finished
  GUID Partition Table Header signature is wrong: 0x0 != 0x5452415020494645
  part_get_info_efi: *** ERROR: Invalid GPT ***
  GUID Partition Table Header signature is wrong: 0x0 != 0x5452415020494645
  part_get_info_efi: *** ERROR: Invalid Backup GPT ***
  bad MBR sector signature 0x0000
  Flashing Raw Image
  ........ wrote 536870912 bytes to 0x0
  ```

host output:

  ```
  target reported max download size of 536870912 bytes
  sending '0x0' (524288 KB)...
  OKAY [ 28.703s]
  writing '0x0'...
  OKAY [ 15.578s]
  finished. total time: 44.282s
  ```

- flash second chunk:

  ```
  fastboot flash 0x20000000 image.01
  ```

target output:

  ```
  WARNING: unknown variable: partition-type:0x20000000
  Starting download of 79923200 bytes
  downloading of 79923200 bytes finished
  GUID Partition Table Header signature is wrong: 0x0 != 0x5452415020494645
  part_get_info_efi: *** ERROR: Invalid GPT ***
  GUID Partition Table Header signature is wrong: 0x0 != 0x5452415020494645
  part_get_info_efi: *** ERROR: Invalid Backup GPT ***
  Flashing Raw Image
  ........ wrote 79923200 bytes to 0x20000000
  ```

host output:

  ```
  target reported max download size of 536870912 bytes
  sending '0x20000000' (78050 KB)...
  OKAY [  4.233s]
  writing '0x20000000'...
  OKAY [  2.346s]
  finished. total time: 6.579s
  ```

### System booting from eMMC

Booting from eMMC has been successfully completed :) Like you can see below
root filesystem is mounted on /dev/mmcblk1p2:

```
root@vitroTV:~# mount
/dev/mmcblk1p2 on / type ext4 (rw,relatime,data=ordered)
```

## Issues

I've run into following error a few times during downloading `U-Boot` over
SDP. Power cycle of the board solved the issue.

host log:

  ```
  loading binary file(SPL-fastboot) to 00907400, skip=0, fsize=dc00 type=aa

  <<<56320, 56320 bytes>>>
  succeeded (status 0x88888888)
  jumping to 0x00907400
  config file <.//mx6_usb_sdp_spl.conf>
  parse .//mx6_usb_sdp_spl.conf
  Trying to open device vid=0x18d1 pid=0x1d01.
  Interface 0 claimed
  HAB security state: development mode (0x56787856)
  == work item
  filename u-boot-fastboot.img
  load_size 0 bytes
  load_addr 0x03f00001
  dcd 0
  clear_dcd 0
  plug 0
  jump_mode 3
  jump_addr 0x00000000
  == end work item

  loading binary file(u-boot-fastboot.img) to 177fffc0, skip=0, fsize=575f8 type=aa

  <<<357880, 358400 bytes>>>
  report 3 in err=-7, last_trans=0  00 00 00 00
  report 4 in err=-7, last_trans=0  00 00 00 00
  failed (status 0x00000000)
  jumping to 0x177fffc0
  ```

target log:

  ```
  U-Boot SPL 2018.01-00273-gb7859c51bb57-dirty (Jan 22 2018 - 11:37:03)
  Trying to boot from USB SDP
  SDP: initialize...
  SDP: handle requests...
  Downloading file of size 357880 to 0x177fffc0... EP0/in FAIL info=48080 pg0=18300840
  EP0/out FAIL info=4018080 pg0=18300840
  Unexpected report 4EP0/out FAIL info=4018080 pg0=18300840
  Unexpected report 40Jumping to header at 0x177fffc0
  Header Tag is not an IMX image
  ```

## Summary

* eMMC flashing with imx_usb_loader required some work, required some work, but
finally ended successfully

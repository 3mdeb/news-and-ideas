---
title: Flashing eMMC on Hummingboard Edge using fastboot? part 2
abstract: Second part of the HummingBoard Edge flashing guide with the help of
          fastboot tool. In this post we will get acquainted with U-Boot
          configuration and fastboot client and try to boot our platform from
          DRAM, SD card and finally EMMC.
cover: /covers/hummingboard-edge.jpg
author: maciej.pijanowski
layout: post
published: true
date: 2019-03-08
archives: "2019"

tags:
  - u-boot
  - fastboot
  - i.MX6
categories:
  - Firmware
  - App Dev
---


## fastboot

[FastBoot protocol](https://android.googlesource.com/platform/system/core/+/2ec418a4c98f6e8f95395456e1ad4c2956cac007/fastboot/fastboot_protocol.txt)
is a tool developed for Android, which allows for communicating with bootloaders
over USB or Ethernet.

### U-Boot configuration

[U-Boot fastboot documentation](https://github.com/u-boot/u-boot/blob/master/doc/android/fastboot.rst#client-installation)
suggests to set `CONFIG_USB_GADGET_(VENDOR_NUM|PRODUCT_NUM|MANUFACTURER)`.

> Note that `USB_GADGET_VENDOR_NUM` and `USB_GADGET_PRODUCT_NUM` is not related
> to your actual board, rather it is some dummy id of device which is compatible
> with fastboot. In this case it is
> [CelkonA88 device from Google](https://www.phonearena.com/phones/Celkon-A88_id7307).

### Fastboot client

Install fastboot:

On Debian-based distros:

```bash
sudo apt install fastboot
```

Installation for other popular distros should be straightforward as well.

### First test - U-Boot from SD card

The purpose is to confirm that `fastboot` command is there and that we can
establish a connection with fastboot client.

[U-Boot fastboot Documentation](https://github.com/u-boot/u-boot/blob/master/doc/android/fastboot.rst#raw-partition-descriptors)
suggests that we only need to execute `fastboot` command in U-Boot prompt.
Notice that now this command requires a parameter:

```bash
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

```bash
fastboot 0
fastboot 1
fastboot -
fastboot qwerty
etc.
```

After running fastboot on HB, you should see new USB device enumerated on host:

```bash
Bus 003 Device 075: ID 18d1:0d02 Google Inc. Celkon A88
```

We can add another `udev` rule at this point in order to use `fastboot` command
without the need of root privileges:

```bash
echo 'SUBSYSTEM =="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="0d02" , MODE="0666"' | sudo tee -a /etc/udev/rules.d/51-fsl-flashing.rules
```

Following command should return available fastboot devices:

```bash
fastboot devices
```

output:

```bash
???????????? fastboot
```

This one should return bootloader version:

```bash
fastboot getvar bootloader-version
```

output:

```bash
bootloader-version: U-Boot 2018.01-00272-g0434429f989d-dirty
finished. total time: 0.000s
```

### Second test - U-Boot from DRAM

In order to enable `fastboot` support I needed to change USB_GADGET VID / PID in
`U-boot` configuration. It means that our `imx_usb_loader` configuration files
needs an adjustment.

`imx_usb.conf` file needs following content:

```bash
#vid:pid, config_file
0x15a2:0x0061, mx6_usb_rom.conf, 0x18d1:0x1d01, mx6_usb_sdp_spl.conf
```

Above change is introduced in
[this commit](https://github.com/3mdeb/imx_usb_loader/commit/76f0b35911474a3bb1989f2fa03ea8bb61ae29c4).

Notice that PID in the second entry is not the same as was set in `U-Boot`
configuration. This is the same issue as presented in case of `SDP` USB gadget
device: detected PID in SPL mode is a little bit different than the one set in
the configuration.

However, once `U-boot` gets loaded and we enter `fastboot 0` in prompt, it gets
back to the correct one:

```bash
Bus 003 Device 040: ID 18d1:0d02 Google Inc. Celkon A88
```

Let's try if communication over fastboot protocol is working in this case as
well:

```bash
fastboot getvar bootloader-version
```

output:

```bash
bootloader-version: U-Boot 2018.01-00272-g0434429f989d-dirty
finished. total time: 0.000s
```

### Enter fastboot mode by default

To automate things, we should force `U-Boot` to enter fastboot mode
automatically on boot.

At first, fast and easy way that came to mind mind was to edit `distro_bootcmd`
variable content:

```bash
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

```bash
CONFIG_BOOTCOMMAND="fastboot 0"
```

To speed things up, it is worth to reduce boot delay to 0 by setting
configuration option:

```bash
CONFIG_BOOTDELAY=0
```

### Using `fastboot flash` command

By default `fastboot` uses GPT partition name as a parameter. Antoine from
Bootlin in
[his post](https://bootlin.com/blog/factory-flashing-with-u-boot-and-fastboot-on-freescale-i-mx6/)
provides an
[U-Boot patch with workaround](https://bootlin.com/pub/2015/imx-flash/0001-fastboot-allow-to-flash-at-a-given-address.patch)
which allows to pass eMMC offset address instead.

It's been a while since it was published and it no longer applies due to the
changes in `U-Boot` source code. I have decided to update it and it can be found
in the
[3mdeb fork of U-Boot](https://github.com/3mdeb/u-boot/commit/13e621b09bfeea05e51079a80cb85f1027de657f).

### Summary - U-Boot from DRAM

- I've also run into some inconsistencies in `U-Boot` code vs documentation. I
  will try to see what's going in the code and update the doc if possible.

- `U-Boot` target configuration for Hummingboard Edge with fastboot support as
  described above is available in
  [3mdeb fork of U-Boot](https://github.com/3mdeb/u-boot/commit/517c2b14b89cec42e5bfb42dd2cfddb04629d96c).

## Booting from eMMC

### eFUSE settings

Note that, in order to boot from eMMC, you need either unfused SoM or fused to
boot from eMMC. Jumper settings for boot selection can be found at
`Edge/Gate Boot Jumpers` section of
[SolidRun Hummingboard wiki page](https://wiki.solid-run.com/doku.php?id=products:imx6:hummingboard).

Fusing instructions to boot from eMMC can be found at
`Blowing fuses to from eMMC (HummingBoard2 eMMC or MicroSOM rev 1.5 on-SOM eMMC)`
section of
[SolidRun wiki eFuses page](https://wiki.solid-run.com/doku.php?id=products:imx6:microsom:imx6-fuse-developers).

You can check fusing settings with:

```bash
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

In my case SoM on HummingBoard2 is fused to boot from uSD card, so I will not be
able to present booting from eMMC on HummingBoard2 at the moment, but we have
[Vitro Crystal](https://shop.3mdeb.com/product/vitrobian-crystal/) boards, which
is based on the same SoC. It's not fused, so I will continue with this board,
but process is the same on HummingBoard2. As I said, this board is not fused and
below values confirms it.

```bash
=> fuse read 0 5
Reading bank 0:

Word 0x00000005: 00000000
=> fuse read 0 6
Reading bank 0:

Word 0x00000006: 00000000
```

### Image flashing

I'm mostly using `Yocto` for the builds. Thanks to
[wic](http://www.yoctoproject.org/docs/current/dev-manual/dev-manual.html#creating-partitioned-images-using-wic)
I can get one output image file with already created desired partition layout.

We should also keep in mind that a single file send via `fastboot` protocol
cannot be larger that the buffer size. Size of the buffer is set via
`CONFIG_FASTBOOT_BUF_SIZE` `U-Boot` configuration option. In our case it was set
to 512 MB. Of course it needs to fit into device's memory.

Regarding that we have modified `fastboot` to take eMMC offset as an argument, I
can see two potential ways of flashing an image.

#### Image decomposition

We can send each of the components one by one. An example could look like:

- MBR sector,
- bootloader,
- boot partition,
- rootfs 1,
- data partition.

We can extract MBR from image file:

```bash
gzip -cdk core-image-minimal.rootfs.wic.gz | sudo dd of=mbr.img bs=512 count=1
```

We can verify it's MBR by looking at it's hexdump:

```bash
hexdump mbr.img
```

dump output:

```bash
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

```bash
00001b0 0000 0000 0000 0000 5c4e 60a8 0000 0080
```

The others are not (`0x00` instead).

Each MBR should also end with two bytes (`0x55AA`):

```bash
00001f0 0000 0000 0000 0000 0000 0000 0000 aa55
```

Let's check the partition table on the eMMC by booting from uSD card before
flashing the `mbr.img`:

```bash
root@vitroTV:~## fdisk -l /dev/mmcblk1
Disk /dev/mmcblk1: 7.3 GiB, 7818182656 bytes, 15269888 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

Like you can see above, there are no partitions yet. Let's flash `mbr.img` on
eMMC using `fastboot`:

```bash
fastboot flash 0x0 mbr.img
```

host output:

```bash
target reported max download size of 536870912 bytes
sending '0x0' (0 KB)...
OKAY [  0.003s]
writing '0x0'...
OKAY [  0.050s]
finished. total time: 0.054s
```

target output:

```bash
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

```bash
root@vitroTV:~## fdisk -l /dev/mmcblk1
```

We can see that `MBR` was flashed correctly to eMMC:

```bash
root@vitroTV:~## fdisk -l /dev/mmcblk1
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

- We would need to decompose disk image which is already assembled by the build
  system.

- We would need to compute offset of each component to pass as a `fastboot`
  command argument. They may change over time.

- Partitions size may be grater than possible buffer size.

#### Image splitting and flashing

The other idea is to split whole image file into data chunks of size not grater
than the fastboot buffer size. This way we can keep all the image layout
information exclusively in the build system. We can use `split` tool for this:

```bash
split -b 512M -d core-image-minimal.wic image_split_dir/image.
```

In this case, size of core-image-minimal.wic is about 620M, so there will be two
chunks only: `image.00` and `image.01`

- flash first chunk:

  ```bash
  fastboot flash 0x0 image.00
  ```

target output:

```bash
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

```bash
target reported max download size of 536870912 bytes
sending '0x0' (524288 KB)...
OKAY [ 28.703s]
writing '0x0'...
OKAY [ 15.578s]
finished. total time: 44.282s
```

- flash second chunk:

  ```bash
  fastboot flash 0x20000000 image.01
  ```

target output:

```bash
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

```bash
target reported max download size of 536870912 bytes
sending '0x20000000' (78050 KB)...
OKAY [  4.233s]
writing '0x20000000'...
OKAY [  2.346s]
finished. total time: 6.579s
```

#### System booting from eMMC

Booting from eMMC has been successfully completed :) Like you can see below root
filesystem is mounted on /dev/mmcblk1p2:

```bash
root@vitroTV:~## mount
/dev/mmcblk1p2 on / type ext4 (rw,relatime,data=ordered)
```

The flashing and booting output log you can see below:

<https://asciinema.org/a/oLztFyKymiTEMn57d2nhEvcRk>

### Issues

I've run into following error a few times during downloading `U-Boot` over SDP.
Power cycle of the board solved the issue.

host log:

```bash
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

```bash
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

## Summary - System booting from eMMC

- eMMC flashing with imx_usb_loader required some work, but finally ended
  successfully

If you need support in U-Boot, fastboot or eMMC feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us email `contact@3mdeb.com`. If you enjoying this type of content feel
free to [sign up to our newsletter](http://eepurl.com/doF8GX)!

## Leave a comment

Did you like this post? Do you have any questions? Please leave a comment and if
you find the article valuable - share it with your friends 🙂 It would be nice if
more people read it. See you on our social media:

[facebook](https://www.facebook.com/3mdeb/)
[twitter](https://twitter.com/3mdeb_com)
[linkedin](https://www.linkedin.com/company/3mdeb)

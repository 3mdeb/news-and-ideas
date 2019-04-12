---
ID: 62911
title: >
  Setup for Linux kernel development on
  Cubietruck
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/setup-for-linux-kernel-development-on-cubietruck/
published: true
date: 2015-09-01 21:48:55
tags:
  - embedded
  - linux
  - Cubietruck
  - A20
  - Allwinner
categories:
  - OS Dev
---
During last couple of months I see quite big interest in building products on
[A20](http://linux-sunxi.org/A20) SoC. This chip can be bought for 6USD in
quantity. Most important features are:

* Dual-Core ARM Cortex-A7 (ARMv7)
* Mali-400 MP2
* HDMI, VGA and LCD
* MMC and NAND
* OTG and 2 Host ports

Tracking media related to low-end mobile market IMHO the hottest SoCs are
Allwinner A20 and Rockchip RK3288.

A20 ship with dozen development boards like Cubieboard or pcDuino series,
Banana Pi, MarsBoard or Hummingbird. About a year ago I choose to buy
Cubietruck and this led to couple interesting projects from porting
[USBSniffer](http://elinux.org/BeagleBoard/GSoC/2010_Projects/USBSniffer) to
writing bare-metal bootloader based on U-boot code. Below setup is not
complicated but contain many pieces and looking for correct procedure for each one
is headache. Especially I felt that when I did it once couple months ago and
was not able to recover my setup without over a day of googling. Because I
of that I decided to write this post and leave notes for me and
others who want bootstrap Cubietruck setup.

Some configs and scripts can be found on [github repo](https://github.com/pietrushnic/ct-dev-setup).

![](/img/ct-dev.jpg)

## Table of contents

* [General approach](#general)
* [Quick TFTP setup](#tftp)
* [Quick NFS setup](#nfs)
* [Toolchain](#toolchain)
* [U-Boot](#uboot)
* [Linux kernel](#linux)
* [Rootfs](#rootfs)
* [Let's put it all together](#sdcard)
* [Known issues](#issues)

## Prerequisites

* Linux development workstation (I use Debian stretch/sid)
* USB to TTL serial adapter - best would be with original FT232RL, but Chinese
  substitutes also works
* microSD card
* Ethernet cable - to connect your CT to router
* good power supply 5V/2.5A - USB should also work when taking care about power
  budget of whole setup
* HDMI or VGA monitor - nice to have

<a name="general"></a>
## General approach

Bootloader (U-Boot) obtain IP address dynamically then using hard coded
information about TFTP server it downloads script which contain instruction
about next steps. Usually next steps include downloading kernel over TFTP and
passing to it parameter indicating that rootfs should be mounted over NFS and
pointing to server location.

Because different U-Boot scripts are required for `sunxi-3.4` and `mainline`
kernel I toggle config on tftp server.

Below I put together various pieces spread across network to have it in one
place.

<a name="tftp"></a>
## Quick TFTP setup

```
sudo apt-get install tftpd-hpa
```

To check if TFTP listen:

```
[23:12:39] pietrushnic:~ $ netstat -an|grep :69
udp        0      0 0.0.0.0:69              0.0.0.0:*
```

It would be useful to have separate directory if in future setup will be enhanced for other boards:

```
sudo mkdir -p /srv/tftp/ct/{ml,sunxi}
```

<a name="nfs"></a>
## Quick NFS setup

```
sudo apt-get install nfs-kernel-server
sudo mkdir /srv/nfs
sudo vim /etc/exports
```

Add line like this:
```
/srv/nfs       *(rw,sync,no_root_squash,no_subtree_check)
```

Create direcrtory for root filesystems:

```
sudo mkdir -p /srv/nfs/ct
```

Restart NFS:

```
sudo service nfs-kernel-server restart
```

<a name="toolchain"></a>
## Toolchain

I'm using Linaro toolchain based on GCC4.9 you can download package
[here](http://releases.linaro.org/15.05/components/toolchain/binaries/arm-linux-gnueabihf/).

```
tar xf gcc-linaro-4.9-2015.05-x86_64_arm-linux-gnueabihf.tar.xz
export PATH=${PATH}:${PWD}/gcc-linaro-4.9-2015.05-x86_64_arm-linux-gnueabihf/bin/
```

To verify this step you can try:

```
[23:24:01] pietrushnic:~ $ arm-linux-gnueabihf-gcc   
arm-linux-gnueabihf-gcc: fatal error: no input files
compilation terminated.
```

<a name="uboot"></a>
## U-Boot (2015.10-rc2)

```
git clone git://git.denx.de/u-boot.git
cd u-boot
make CROSS_COMPILE=arm-linux-gnueabihf- Cubietruck_defconfig
make CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
```

To boot `sunxi-3.4` setting `ARM architecture -> Enable workarounds for booting
old kernels` is required.

```
make CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
```

Log like this:

```
[23:42:38] pietrushnic:u-boot git:(master) $ make CROSS_COMPILE=arm-linux-gnueabihf- -j8
make: arm-linux-gnueabihf-gcc: Command not found
/bin/sh: 1: arm-linux-gnueabihf-gcc: not found
dirname: missing operand
Try 'dirname --help' for more information.
scripts/kconfig/conf  --silentoldconfig Kconfig
  CHK     include/config.h
  UPD     include/config.h
  GEN     include/autoconf.mk
/bin/sh: 1: arm-linux-gnueabihf-gcc: not found
  GEN     include/autoconf.mk.dep
/bin/sh: 1: arm-linux-gnueabihf-gcc: not found
scripts/Makefile.autoconf:47: recipe for target 'include/autoconf.mk.dep' failed
make[1]: *** [include/autoconf.mk.dep] Error 1
make[1]: *** Waiting for unfinished jobs....
scripts/Makefile.autoconf:72: recipe for target 'include/autoconf.mk' failed
make[1]: *** [include/autoconf.mk] Error 1
  GEN     spl/include/autoconf.mk
/bin/sh: 1: arm-linux-gnueabihf-gcc: not found
scripts/Makefile.autoconf:75: recipe for target 'spl/include/autoconf.mk' failed
make[1]: *** [spl/include/autoconf.mk] Error 1
make: *** No rule to make target 'include/config/auto.conf', needed by 'include/config/uboot.release'.  Stop.
```
means that you incorrectly set [toolchain](#toolchain).

<a name="linux"></a>
## Linux kernel

### sunxi-3.4 kernel

```
git clone -b sunxi-3.4 --depth 1 https://github.com/linux-sunxi/linux-sunxi.git
cd linux-sunxi
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- sun7i_defconfig
```

Ethernet driver have to be built-in, because when included as module do not
start early enough to mount rootfs over NFS.

```
sed -i 's:CONFIG_SUNXI_GMAC=m:CONFIG_SUNXI_GMAC=y:g' .config
make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=output modules_install
cd ..
```

#### script.bin

```
git clone git://github.com/linux-sunxi/sunxi-tools.git
git clone git://github.com/linux-sunxi/sunxi-boards.git
cd sunxi-tools
make fex2bin
cd ..
cd sunxi-boards
vim sys_config/a20/cubietruck.fex
```

```
diff --git a/sys_config/a20/cubietruck.fex b/sys_config/a20/cubietruck.fex
index 7f8ec02911d6..d86dc5cb23a0 100644
--- a/sys_config/a20/cubietruck.fex
+++ b/sys_config/a20/cubietruck.fex
@@ -960,3 +960,5 @@ LV6_volt = 1100
 LV7_freq = 144000000
 LV7_volt = 1050

+[dynamic]
+MAC = "FEEDDEADBEEF"
```

To generate MAC you can use [this tool](http://www.miniwebtool.com/mac-address-generator/) or you can give your
Cubietruck MAC if you know it. One way to figure it out is flash only U-boot and run

```
printenv ethaddr
```

To generate `script.bin`:

```
../sunxi-tools/fex2bin sys_config/a20/cubietruck.fex script.bin
```

### Mainline kernel (sunxi-next 387a2c191af6 4.2.0-rc4)

```
git clone git://github.com/mripard/linux.git -b sunxi-next
cd linux
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- sunxi_defconfig
make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage dtbs
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=output modules modules_install
```

<a name="rootfs"></a>
## Rootfs

Based on [Olimex guide](https://olimex.wordpress.com/2014/07/21/how-to-create-bare-minimum-debian-wheezy-rootfs-from-scratch/).

```
sudo apt-get install qemu-user-static
targetdir=rootfs
distro=wheezy
mkdir $targetdir
sudo debootstrap --arch=armhf --foreign $distro $targetdir
sudo cp /usr/bin/qemu-arm-static $targetdir/usr/bin/
sudo cp /etc/resolv.conf $targetdir/etc
sudo chroot $targetdir /bin/bash -i
distro=wheezy
export LANG=C
/debootstrap/debootstrap --second-stage
cat <<EOT > /etc/apt/sources.list
deb http://httpredir.debian.org/debian $distro main contrib non-free
deb-src http://httpredir.debian.org/debian $distro main contrib non-free
EOT
apt-get update
apt-get install locales dialog
dpkg-reconfigure locales
```

In this place I prefer to use en_US.UTF-8 as a _lingua franca_ of Linux world.
Next we will install couple of tools that are almost always useful.

```
apt-get install openssh-server ntpdate git vim
passwd
cat <<EOT >> /etc/network/interfaces
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
EOT
echo cubietruck > /etc/hostname
echo T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100 >> /etc/inittab
exit
sudo rm $targetdir/etc/resolv.conf
sudo rm $targetdir/usr/bin/qemu-arm-static
```

At this point it is good to make a backup copy. Time consuming but with very
small output:

```
sudo XZ_OPT=-9 tar cJf rootfs.tar.xz rootfs
```


<a name="sdcard"></a>
## Let's put it all together

### Prepare SD card

Assuming your SD card is on `/dev/sdc`

```
sudo umount /dev/sdc1 #umount any automatically mounted partitions
card=/dev/sdc
sudo dd if=/dev/zero of=${card} bs=1M count=1 #clean partition table
```

Partitioning:

```
cat << EOT | sudo sfdisk ${card}
2048,1024,c
EOT
```

Flash U-Boot image:

```
sudo dd if=u-boot-sunxi-with-spl.bin of=${card} bs=1024 seek=8
```

Format and mount boot partition:

```
sudo mkfs.vfat ${card}1
sudo mount ${card}1 /mnt
```

Below script add flexibility to booting process by allowing user to replace on
server `boot.scr`. This makes Cubietruck able to dual boot `sunxi-3.4` and
`mainline` kernel. Please replace `<my_tftp_server_ip>` with your TFTP address.

```
cat <<EOT > boot.cmd
# this file should be placed on boot SD card partition
setenv serverip <my_tftp_server_ip>
setenv autoload no
dhcp
tftp 0x44000000 ct/boot.scr
source 0x44000000
EOT
```

Make U-Boot readable image:

```
mkimage -C none -A arm -T script -d boot.cmd boot.scr
sudo cp boot.scr /mnt
sudo umount /mnt
```

Now you can put your SD card into Cubietruck.

### Prepare NFS and TFTP content

Copy kernel and files required to boot:
```
sudo cp linux-sunxi/arch/arm/boot/zImage /srv/tftp/ct/sunxi
sudo cp sunxi-boards/script.bin /srv/tftp/ct/sunxi
sudo cp linux/arch/arm/boot/zImage /srv/tftp/ct/ml
sudo cp linux/arch/arm/boot/dts/sun7i-a20-cubietruck.dtb /srv/tftp/ct/ml
```


Copy filesystem to NFS server directory:

```
sudo cp -r rootfs /srv/nfs/ct
```

Copy modules:

```
sudo cp -r linux-sunxi/output/lib /srv/nfs/ct/rootfs
sudo cp -r linux/output/lib /srv/nfs/ct/rootfs
```

#### Create U-Boot scripts for sunxi and mainline

Sunxi script will look like this:
```
cat <<EOT > boot.cmd.sunxi
setenv bootm_boot_mode sec
tftp 0x43000000 ct/sunxi/script.bin
tftp 0x48000000 ct/sunxi/zImage
setenv bootargs "root=/dev/nfs init=/sbin/init \
nfsroot=\${serverip}:/srv/nfs/ct/rootfs rw ip=dhcp console=ttyS0,115200 \
rootwait sunxi_ve_mem_reserve=0 sunxi_g2d_mem_reserve=0 \
sunxi_no_mali_mem_reserve sunxi_fb_mem_reserve=16 hdmi.audio=EDID:0 \
disp.screen0_output_mode=EDID:1280x720p60 panic=10 consoleblank=0 debug"
bootz 0x48000000
EOT
```

Make U-Boot readable image:

```
mkimage -C none -A arm -T script -d boot.cmd.sunxi boot.scr.sunxi
sudo cp boot.scr.sunxi /srv/tftp/ct/sunxi
```

Mainline script will look like this:
```
cat <<EOT > boot.cmd.ml
tftp 0x46000000 ct/ml/zImage
tftp 0x49000000 ct/ml/sun7i-a20-cubietruck.dtb
setenv bootargs "root=/dev/nfs init=/sbin/init \
nfsroot=\${serverip}:/srv/nfs/ct/rootfs rw ip=dhcp console=ttyS0,115200 \
rootwait panic=10 consoleblank=0 debug"
env set fdt_high ffffffff
bootz 0x46000000 - 0x49000000
EOT
```

Make U-Boot readable image:

```
mkimage -C none -A arm -T script -d boot.cmd.ml boot.scr.ml
sudo cp boot.scr.ml /srv/tftp/ct/ml
```

<a name="issues"></a>
## Known issues

### TFTP error: 'Unsupported option(s) requested' (8)

This problem was discussed [here](http://lists.denx.de/pipermail/u-boot/2015-August/225129.html).
You can fix it by changing TFTP  `TIMEOUT`:

```
diff --git a/net/tftp.c b/net/tftp.c
index 18ce84c20214..33fe4e47a616 100644
--- a/net/tftp.c
+++ b/net/tftp.c
@@ -19,7 +19,7 @@
 /* Well known TFTP port # */
 #define WELL_KNOWN_PORT        69
 /* Millisecs to timeout for lost pkt */
-#define TIMEOUT                100UL
+#define TIMEOUT                1000UL
 #ifndef        CONFIG_NET_RETRY_COUNT
 /* # of timeouts before giving up */
 # define TIMEOUT_COUNT 1000
```

Recompile U-boot and flash it on SD card again.

## Summary

You can boot to `sunxi-3.4` kernel by simply:

```
sudo cp /srv/tftp/ct/sunxi/boot.scr.sunxi /srv/tftp/ct/boot.scr
```

And switch to mainline kernel using:

```
sudo cp /srv/tftp/ct/ml/boot.scr.ml /srv/tftp/ct/boot.scr
```

Hopefully above shell history drop is readable for you, most of above content
can be googled - I just needed place to store notes from scratchpad. If you hit
some problems do not bother to ask in comments. If you like this post or think
it can be helpful for others please share.

Thanks for reading.

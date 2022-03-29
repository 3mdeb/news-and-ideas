---
title: Secure Boot on Xavier NX
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/nvidia-logo.png
author: michal.kotyla
layout: post
published: true
date: 2022-03-25
archives: "2022"

tags:
  - nvidia
  - xavier nx
  - secure boot
categories:
  - Firmware
  - Security
  - Manufacturing

---

## Introduction

Secure Boot is feature that is typically used on desktop devices as well as in
embedded systems - based on both SoC's and microcontrollers.
It was generally described in our previoust post -
[Enabling Secure Boot on RockChip SoCs](https://blog.3mdeb.com/2021/2021-12-03-rockchip-secure-boot/).
Theory of working is similar. Implementation is more complex, but we do not need
to use closed software based only on Windows devices like in RockChip case.

## Secure Boot overview

Whole signing and setting up process is very well described in
[NVIDIA documentation](https://docs.nvidia.com/jetson/l4t/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/bootloader_secure_boot.html). This process does not looks complicated, but you
do not have to look so far to find
[posts](https://forums.developer.nvidia.com/t/jetson-xavier-nx-devkit-secureboot-enabled/158361)
where someone bricks his device. Secure Boot with key must be burned in fuse
bits and it is irreversible operation. You should make sure that your device
(and `chip_id`) is able to work with Secure Boot. Production or development
version of device and eMMC memory size is also relevant here.

Generally, to set Secure Boot on Jetson platform you need to generate RSA
key. Using that, image can be signed and key to verifiy source of system can
be burned into fuses. There is a chanche to extend that to fully Secure Boot -
including secure kernel starting and signed applications. We make here
minimalistic version with only verified bootloader.

![zzz](/img/secureboot_workflow.png)

From now, only system with bootloader signed with generated key can be booted on
device.

## Requirements

* **RSA private key**

it will be used to sign files and burn fuses

`$ openssl genrsa -out rsa_priv.pem 3072`

* **L4T Driver Package**

download latest version of NVIDIA BSP from
[here](https://developer.nvidia.com/embedded/linux-tegra) and extract archive
anywhere you want

* **Sample Root Filesystem**

your filesystem should be placed in previously extracted BSP folder structure -
`Linux_for_Tegra/rootfs/`. There should by only one `README.txt`. You can use
your own rootfs, or use basic version by downloading this from
[linux-tegra download page](https://developer.nvidia.com/embedded/linux-tegra)

* **Jetson Platform Fuse Burning and Secure Boot Documentation and Tools**

this package will be required to burning fuses. Download that from already
mentioned [site](https://developer.nvidia.com/embedded/linux-tegra) and extract
that in this same directory where is L4T BSP


## Signing image

It is more safe to prepare signed image at first. If you fail that phase, not
fused yet device still will be work with any image.

Inside directory where you extracted NVIDIA archives you can find `flash.sh`
script. We will use that for signing image. To do that, type command:

`$ sudo ./flash.sh --no-flash --sign -u rsa_priv.pem jetson-xavier-nx-devkit-emmc mmcblk0p1`

After that you should see similar output:

```
saving flash command in flashcmd.txt

*** no-flash flag enabled. Exiting now... *** 

User can run above saved command in factory environment without 
providing pkc and sbk keys to flash a device

Example:

    $ cd bootloader 
    $ sudo bash ./flashcmd.txt
```
> There can be problem with not found `extlinux.conf`. In this case try with
copying that from downloaded Fuse Burning tool to path:
`Linux_for_Tegra/rootfs/boot/extlinux/extlinux.conf`

Also it is good idea to try first signing and flashing system with zero-key
signing. It will make you sure that you are familiar with signing and flashing
procedure before burning fuses. It is possible to do that in one command:

`$ sudo ./flash.sh jetson-xavier-nx-devkit-emmc mmcblk0p1`

After a few minutes device should be flashed and ready to reboot:

```
[ 466.0731 ] Flashing completed

[ 466.0732 ] Coldbooting the device
[ 466.0755 ] tegrarcm_v2 --ismb2
[ 466.3880 ] 
[ 466.3909 ] tegradevflash_v2 --reboot coldboot
[ 466.3917 ] Bootloader version 01.00.0000
[ 466.5493 ] 
*** The target t186ref has been flashed successfully. ***
Reset the board to boot from internal eMMC.
```

You can verify that by connect with Jetson via serial port. There should be here
Ubuntu message (if you use rootfs from NVIDIA):

```
Ubuntu 18.04.6 LTS localhost.localdomain ttyTCU0

localhost login: 

```

## Setting up on device

By using previously generated RSA key we can burn fuses with:

`$ sudo ./odmfuse.sh -i 0x19 -p -k rsa_priv.pem --KEK2 kek2.key -S sbk.key jetson-xavier-nx-devkit-emmc mmcblk0p1`

## Summary

In these times various of SoC producents offers some important security
features. We can imagine more trustworhly devices but Xavier and others from
releated NVIDIA series are a good compromise between safety and gigantic
performance. Adding to that disabling JTAG port (this is available on Xavier
too!) you can create pretty save device - definetly more safe than most of 
endpoint devices that you can find at any time in your life. Secure Boot is
available in different devices too (and we have a experience in that!) - e.g
i.MX series and Rockchip.

Secure Boot is only one of many safety features that we can implement in your
solution. We have full head of ideas how to make our lives safier - and we do it
every day. If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

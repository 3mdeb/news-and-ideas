---
title: Blog post - odświeżenie "Minimal Image, Fastest Rpi, Quick Tutorial"
abstract: 'So far, to build even a minimal image on th raspberry pi the downloading of sources and then configuration had to be done by hand.
	  Instead Yocto kas is using a project configuration file and does the download and configuration phase.
	  Kas tool provides an easy mechanism to setup bitbake based projects.
          Kas makes the setup of a Yocto build environment super simple and super fast.'
cover: /covers/Cover_Yocto_kas_RPI4.png
author: ewa.kujawska
layout: post
published: true
date: 2023-06-23
archives: "2023"

tags:
  - yocto
  - poky
  - kas
  - rpi
  - linux
  - meta-raspberrypi
  - minimal_image
  - u-boot
  - open-source
  - mickledore
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev

---


# A brief description of the hardware platform

Raspberry Pi is a small computer to which you can connect a keyboard,
monitor, or mouse and use it as you would a normal desktop computer.
This credit card-sized device, equipped with the right system and drivers,
allows you to use the Internet, play games, use word editors,
calculation sheets or play multimedia. It is used in many projects,
whether for beginners, learning programming, or more advanced projects
that can take full advantage of the functionalities offered by Raspberry PI.

![Raspberry Pi 4](/img/raspberry-pi-4.png)

# Building minimal image with Ycto

The blog post shows how to currently build an image for the RPI 4,
with the UART enabled, while using the U-Boot bootloader.
We will build the project using the _kas_ tool.
The previous version of the article
[Minimal Image, Fastest Rpi, Quick Tutorial](https://blog.3mdeb.com/2020/2020-10-30-rpi4_yocto/)
showed how to build a minimal image on a Raspberry Pi 4
using Ubuntu 18.04 with Yocto. There were described various steps:
cloning the Yocto repository, selecting the appropriate branch, and
changing the configuration files _bblayers.conf_, _local.conf_,
flashing the image to the correct location on the SD card
on the basis of the built image.
If you need to perform these actions or read a more detailed description, 
be sure to visit the indicated article before continuing.

## Usage of "kas" and the latest Yocto release: mickledore

In this article, we will extend the image-building process
using the _kas-container_ tool and the latest release of Yocto _(Mickledore)_.
In addition, let's build an image using the U-Boot bootloader.
You can familiarise yourself with the kas tool on a blog post,
which is a bit dated but still explains things well:
[Quick start guide to kas - best tool for setting up the Yocto projects](https://blog.3mdeb.com/2019/2019-02-07-kas/).
One difference is that the script now used is _kas-container_ and not _kas-docker_.
To start, set up the environment - create a folder called _Yocto_,
for example, and clone the following repo:

```zsh
mkdir Yocto
cd Yocto
```

```zsh
git clone https://github.com/agherzan/meta-raspberrypi.git
git clone https://github.com/siemens/kas.git
```

The _meta-raspberrypi_ repository contains a _kas-poky-rpi.yml_ file,
which needs a slight modification to use the Mickledore branchy,
instead of the master. Just check if mickledore exists in the linked repositories
and then replace _refspec: master_ with _refspec: mickledore_.  

```zsh
poky:
    url: https://git.yoctoproject.org/git/poky
    path: layers/poky
    refspec: master
    layers:
      meta:
      meta-poky:
      meta-yocto-bsp:

  meta-openembedded:
    url: http://git.openembedded.org/meta-openembedded
    path: layers/meta-openembedded
    refspec: master
    layers:
      meta-oe:
      meta-python:
      meta-networking:
      meta-perl:

  meta-qt5:
    url: https://github.com/meta-qt5/meta-qt5/
    path: layers/meta-qt5
    refspec: master
```

In case of errors during the build, communicated as
_Has a restricted licence 'synaptics-killswitch' which is not listed in your LICENSE_FLAGS_ACCEPTED"
the kas-poky-rpi.yml file can be extended with an additional line:
LICENSE_FLAGS_ACCEPTED += " synaptics-killswitch_.
Here [Yocto project](https://docs.yoctoproject.org/4.0.10/singleindex.html#term-LICENSE_FLAGS_ACCEPTED)
is more information about the variables.

```zsh
standard: |
    CONF_VERSION = "2"
    PACKAGE_CLASSES = "package_rpm"
    SDKMACHINE = "x86_64"
    USER_CLASSES = "buildstats"
    PATCHRESOLVE = "noop"
    LICENSE_FLAGS_ACCEPTED += " synaptics-killswitch"
```

## Adding a U-boot and UART

Once the environment has been put together
and the kas-container script downloaded and the changes made,
an image should be created from the Yocto directory created earlier:

`kas/kas-container build meta-raspberrypi/kas-poky-rpi.yml`

Time to include the U-Boot bootloader and UART interface.
Documentation of the meta-raspberrypi layer can be found [here]
(<https://meta-raspberrypi.readthedocs.io/en/latest/extra-build-config.html#boot-to-u-boot>).
For u-boot to load the kernel image,
the following must be set in local.conf (file kas-poky-rpi.yml):  

`RPI_USE_U_BOOT = "1"`

Users who want serial console support should explicitly set in local.conf:

`ENABLE_UART = "1"`

# Flashing

At this stage, the image should already be built. In the location
`Yocto/build/tmp/deploy/images/raspberrypi4` there are many files,
among them two important ones to be uploaded to the SD card.
A simple way to find these files is to use the command
`ls *wic*` as shown in the code below.

```zsh
Yocto_kas/build/tmp/deploy/images/raspberrypi4 λ ls -a *wic* 
core-image-base-raspberrypi4-20230703064507.rootfs.wic.bmap  
core-image-base-raspberrypi4-20230703064507.rootfs.wic.bz2  
core-image-base-raspberrypi4.wic.bmap  
core-image-base-raspberrypi4.wic.bz2
```

You will need these two files:
`core-image-base-raspberrypi4.wic.bmap` and `core-image-base-raspberrypi4.wic.bz2`.
You can now insert the SD card into the PC
and check its location using the command, for example:

```zsh
sudo fdisk -l
```

The result will be a similar output to this one:

```
Disk /dev/sdc: 28.89 GiB, 31016878080 bytes, 60579840 sectors
Disk model: MassStorageClass
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xfc7fa3b0
```

The location must be right. Otherwise, flashing the image to the wrong 
location can cause serious damage.
We will use the `bmap-tools` to upload the above files.
It is a tool that works with files of any size,
creating and manipulating files in blocks and mapping them
from one location to another. It offers secure transfer,
checks data integrity with SHA256, and uses authentication with the OpenPGP tool.

```zsh
sudo dnf install -y bmap-tools
```

In the next step unmount the SD card (X can be replaced by c,
but you need to check the proper location of Your SD cart):

```zsh
sudo umount /dev/sd[X]
```

Then, at the _raspberrypi4_ location, upload the image using the `bmaptool` command:

```zsh
sudo bmaptool copy --bmap core-image-base-raspberrypi4.wic.bmap core-image-base-raspberrypi4.wic.bz2 /dev/sdc
```

To check the correctness of the results, let us use the _Minicom_ programme:

```zsh
sudo minicom -D /dev/ttyUSB0 -b115200
```

You can also use the -s flag and manually adjust the settings.

# Boot time measurement in the bootloader

Measuring boot time can be an important way of assessing system resources.

In general, start-up time should be divided into bootloader,
Linux kernel and userspace software loading time.
The time spent in the bootloader is assumed to be the time
from the appearance of the U-Boot SPL logs on the debug console,
to the display of the Starting kernel log .....
Of course, before the SPL, the Boot ROM is started, which loads it,
but the time required for this is negligibly small.

The following sections show the boot time measurement,
and modifications to the bootloader configuration
to reduce `CONFIG_BOOTDELAY` to zero. `CONFIG_BOOTDELAY` sets the value
of `bootdelay` and the `bootdelay` contains the number of seconds that U-Boot pauses
to determine whether the user wants to interrupt the boot sequence.
To eliminate the delay, set it to 0. Next, a re-measurement of boot time
shows that booting has been improved and accelerated.
Timestamping can be performed in the _Minicom_ software
by running the timestamp registration option.
After connecting to the Raspberry Pi 4 using the minicom software,
the timing option can be selected. Simply press Ctrl-A Z and then
select N (Timestamp toggle). This will enable you to check the duration
of commands and processes being executed.

The first measurement of the boot time shows that the boot process takes about 3 seconds:

```zsh
[2023-07-14 11:30:38] U-Boot 2023.01 (Jan 09 2023 - 16:07:33 +0000)
...
[2023-07-14 11:30:41] Starting kernel ...
```

To modify the variable responsible for the start-up time,
access the u-boot prompt. To do this, you need to reboot the system and
immediately after the _U-boot_ is displayed, press any characters on the keyboard.

Now, we can set:

```zsh
[2023-07-14 14:49:36] U-Boot> setenv bootdelay '0'
[2023-07-14 14:50:15] U-Boot> saveenv
[2023-07-14 14:50:20] Saving Environment to FAT... OK
```

As a result, it was possible to reduce this time from 3 seconds to 1 second.

```zsh
[2023-07-14 14:53:35] U-Boot 2023.01 (Jan 09 2023 - 16:07:33 +0000)
... 
[2023-07-14 14:53:36] Starting kernel ...
```

```
author: ewa.kujawska
```

## Summary

I hope this short but informative blog will help you get started
with your new Raspberry Pi 4, learn about a useful tool such as the Yocto
or Kas project and thus build a correct minimum image.
If you are interested in more technology and projects from the embedded world,
I highly recommend taking a look at more blogs from 3mbed [more blogs](https://blog.3mdeb.com).

---
title: Blog post - odświeżenie "Minimal Image, Fastest Rpi, Quick Tutorial"
abstract: 'So far, to build even a minimal image on th raspberry pi the downloading of sources and then configuration had to be done by hand.
	  Instead Yocto kas is using a project configuration file and does the download and configuration phase.
	  Kas tool provides an easy mechanism to setup bitbake based projects.
          Kas makes the setup of a Yocto build environment super simple and super fast.'
cover: /covers/image-file.png
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

Your post content

# A brief description of the hardware platform

Raspberry Pi is a small computer to which you can connect a keyboard,
monitor or mouse and use it as you would a normal desktop computer.
This credit card-sized device, equipped with the right system and drivers,
allows you to use the Internet, play games, use word editors,
calculation sheets or play multimedia. It is used in many projects,
whether for beginners, learning programming or more advanced projects
that can take full advantage of the functionalities offered by Raspberry PI.

![Raspberry Pi 4](/img/raspberry-pi-4.png)

# Building minimal image with Ycto

The blog post shows how to currently build an image for the RPI 4,
with the UART enabled, while using the U-Boot bootloader.
We will build the project using the _kas_ tool.
The previous version of the article
[Minimal Image, Fastest Rpi, Quick Tutorial](https://blog.3mdeb.com/2020/2020-10-30-rpi4_yocto/)
showed how to build a minimal image on a Raspberry Pi 4
using Ubuntu 18.04 with Yocto. There was described the various steps:
cloning the Yocto repository, selecting the appropriate branch,
changing the configuration files _bblayers.conf_, _local.conf_,
flashing the image to the correct location on the SD card
on the basis of the built image.

## Usage of "kas" and the latest Yocto release: Mickledore

In this article, we will extend the image building process
using the _kas-cointainer_ tool and the latest release of Yocto _(Mickledore)_.
In addition, let's build an image using the U-Boot bootloader.
You can familiarise yourself with the kas tool on blogpost,
which is a bit dated but still explains things well:
[Quick start guide to kas - best tool for setting up the Yocto projects](https://blog.3mdeb.com/2019/2019-02-07-kas/).
One difference is that the script now used is _kas-container_ and not _kas-docker_.
To start, set up the environment - create a foder called _Yocto_,
for example, and clone the following repo:

```
mkdir Yocto
cd Yocto
```

```
git clone https://github.com/agherzan/meta-raspberrypi.git
git clone https://github.com/siemens/kas.git
```

The _meta-raspberrypi_ repository contains a _kas-poky-rpi.yml_ file,
which needs a slight modification to actually use the Mickledore branchy,
instead of on the master. Just check if mickledore exists in the linked repositories
and then replace _refspec: master_ with _:refspec: mickledore_.  

```
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

In case of errors during the build, communicated as:
_Has a restricted licence 'synaptics-killswitch' which is not listed in your LICENSE_FLAGS_ACCEPTED"
the kas-poky-rpi.yml file can be extended with an additional line:
LICENSE_FLAGS_ACCEPTED += " synaptics-killswitch_.
Here [Yocto project](https://docs.yoctoproject.org/4.0.10/singleindex.html#term-LICENSE_FLAGS_ACCEPTED)
is more information about the variables.

```
standard: |
    CONF_VERSION = "2"
    PACKAGE_CLASSES = "package_rpm"
    SDKMACHINE = "x86_64"
    USER_CLASSES = "buildstats"
    PATCHRESOLVE = "noop"
    LICENSE_FLAGS_ACCEPTED += " synaptics-killswitch"
```

## Adding an U-boot and UART

Once the environment has been put together
and the kas-container script downloaded and the changes made,
an image should be created from the Yocto directory created earlier:

`kas/kas-container build meta-raspberrypi/kas-poky-rpi.yml`

Time to include the U-Boot bootloader and UART interface.
Documentation of the meta-raspberrypi layer can be found [here]
(<https://meta-raspberrypi.readthedocs.io/en/latest/extra-build-config.html#boot-to-u-boot>).
In order for u-boot to load the kernel image,
the following must be set in local.conf (file kas-poky-rpi.yml):  

`RPI_USE_U_BOOT = "1"`

Users who want serial console support should explicitly set in local.conf:

`ENABLE_UART = "1"`

# Boot time measurement in the bootloader

Measuring boot time can be an important way of assessing system resources.
The following sections show the boot time measurement,
modifications to the bootloader configuration
to reduce CONFIG_BOOTDELAY to zero. Next a re-measurement of boot time
showing that booting has been improved and accelerated.
Timestamping can be performed in the minicom software
by running the timestamp registration option. In general,
start-up time should be divided into bootloader,
Linux kernel and userspace software loading time.
The time spent in the bootloader is assumed to be the time
from the appearance of the U-Boot SPL logs on the debug console,
to the display of the Starting kernel log .....
Of course, before the SPL, the Boot ROM is started, which loads it,
but the time required for this is negligibly small.

At this stage, the image should already be built. In the location
`Yocto/build/tmp/deploy/images/raspberrypi4` there are many files,
among them two important ones to be uploaded to the SD card.
A simple way to find these files is to use the command
`ls *wic*` as shown in the code below.

```
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

```
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

It is very important that this location is right.
Otherwise, flashing the image to the wrong location can cause serious damage.
We will use the `bmap-tools` to upload the above files.
It is a tool that works with files of any size,
creating and manipulating files in blocks and mapping them
from one location to another. It offers secure transfer,
checks data integrity with SHA256, uses authentication with the OpenPGP tool.

```
sudo dnf install -y bmap-tools
```

In the next step unmount the SD card (X can be replaced by c,
but you need to check the proper location of Your SD cart):

```
sudo umount /dev/sd[X]
```

Then, at the _raspberrypi4_ location, upload the image using the `bmaptool` command:

```
sudo bmaptool copy --bmap core-image-base-raspberrypi4.wic.bmap core-image-base-raspberrypi4.wic.bz2 /dev/sdc
```

To check the correctness of the results, let us use the _minicom_ programme.

```
sudo minicom -D /dev/ttyUSB0 -b115200
```

You can also use the -s flag and manually adjust the settings.

```
author: ewa.kujawska
```

## Summary

I hope this short but informative blog will help you get started
with your new Raspberry Pi 4, learn about a useful tool such as the Yocto
or kas project and thus build a correct minimum image.
If you are interested in more technology and projects from the embedded world,
I highly recommend taking a look at more blogs from 3mbed [more blogs](https://blog.3mdeb.com).

OPTIONAL ending (may be based on post content):

Unlock the full potential of your hardware and secure your firmware with
the experts at 3mdeb! If you're looking to boost your product's performance
and protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the
hidden benefits of your hardware. And if you want to stay up-to-date on all
things firmware security and optimization, be sure to
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

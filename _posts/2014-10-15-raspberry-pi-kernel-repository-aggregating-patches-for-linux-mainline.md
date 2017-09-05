---
ID: 62896
post_title: >
  Raspberry Pi kernel repository
  aggregating patches for Linux mainline
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/raspberry-pi-kernel-repository-aggregating-patches-for-linux-mainline/
published: true
post_date: 2014-10-15 23:23:11
tags:
  - linux
  - RaspberryPi
  - Broadcom
categories:
  - OS Dev
---
Since several months I'm trying to find my way to embedded Linux programming.
My hardware set was very limited I had only one board that can be called
"embedded" and it was Raspberry Pi. Because I am more interested in firmware/OS
level then hardware I tried to figure out what is going on with RPi kernel.
After taking brief review of
[raspberrypi/linux](https://github.com/raspberrypi/linux) GitHub repository I
realized that close to my heart is upstreaming effort. So with noob attitude I
contacted RPi Upstreaming wiki page author ([notro](https://github.com/notro))
and we started to create some foundation.

_Disclaimer: These are for testing purposes and considered unstable. Use at your own risk._
_Edit: 20/10/2014:_ minor typo, clone instructions moved to "How to use it ?" section

What we have now ?
------------------

We created set of repositories to handle upstreaming process.

First there is [rpi-dt-linux](https://github.com/pietrushnic/rpi-dt-linux.git)
it is Linux kernel based on
[linux-stable](https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/)
with patches on top of every branch. This repository aims to aggregate all
patches required for Raspberry Pi support in upstream kernel. `rpi-dt-linux`
use `bcm2835_defconfig` with device tree support. We want to introduce every
driver that supports device tree. Right now a lot of stuff is missing, but I
will dive into it later.

After consulting with
[popcornmix](https://github.com/raspberrypi/linux/issues/698) we decide to
rebase all patches to keep them on top of every branch. This of course mean
that repository will be broken, but patches will be more visible in history.

Second [rpi-dt-firmware](https://github.com/pietrushnic/rpi-dt-firmware) is ready
to use firmware files for Raspberry Pi with already built modules and kernel.
If you are familiar with [Hexxeh](https://github.com/Hexxeh)
[rpi-update](https://github.com/Hexxeh/rpi-update) and his repository
[rpi-firmware](https://github.com/Hexxeh/rpi-firmware) this should not be
anything new for you.

Third [rpi-bcm2835](https://github.com/notro/rpi-bcm2835) which simplifies
build and release process of `rpi-dt-linux`.

How to use it ?
---------------

## User

If you simply want to try new kernel on your RPi then install `rpi-update`, by:

```
sudo apt-get install rpi-update
```

on Raspbian or follow instruction from
[Readme.md](https://github.com/Hexxeh/rpi-update) for other distributions.


To install latest release of `rpi-dt-firmware` use `rpi-update` on RPi:

```
sudo REPO_URI=https://github.com/pietrushnic/rpi-dt-firmware rpi-update
```

After update simply reboot your Pi and enjoy our upstream kernel :).

## Developer

If you want to play with the code I have few hints that can help. 


First please clone `rpi-dt-linux` and `rpi-bcm2835` mentioned above. 

```
git clone https://github.com/pietrushnic/rpi-dt-linux.git
git clone https://github.com/notro/rpi-bcm2835.git
```

Then install [rpi-build](https://github.com/notro/rpi-build) following
instructions on [wiki](https://github.com/notro/rpi-build/wiki). Then you can
do few things:

Build `rpi-dt-linux` locally. This will download latest snapshot of
`rpi-dt-linux` and other dependencies like `u-boot` and cross-compiler.

```
cd path/to/rpi-bcm2835
rpi-build rpi-dt-linux clean build
```

You can install already built kernel on your machine over ssh (replace
`<RPI_IP>` with your Pi IP address):

```
rpi-build rpi-dt-linux install SSHIP=&lt;RPI_IP&gt;
```

If you want to use your own kernel repository just use `rpi-bcm2835` with local
path:

```
RPI_DT_LINUX_LOCAL=../../rpi-dt-linux rpi-build rpi-dt-linux clean build
```

NOTE: that additional level of `../` was added because rpi-build creates
workdir which is reference directory for it.

It is also possible to release your own firmware repository. To help with
process there are two commands:

```
FW_REPO=/home/pietrushnic/src/rpi-dt-firmware FW_BRANCH=master rpi-build rpi-dt-linux commit
FW_REPO=/home/pietrushnic/src/rpi-dt-firmware FW_BRANCH=master rpi-build rpi-dt-linux push
```

Obviously `FW_REPO` is a directory with firmware git repository.


Changelog
---------

At the point of writing this post there were 3 releases of `rpi-dt-firmware`. We
applied v10 of [mailbox API](http://lwn.net/Articles/607424/) and Lubomir
Rintel `bcm2835-mbox`, `bcm2835-cpufreq` and `bcm2835-thermal` drivers from his
[repository](https://github.com/hackerspace/rpi-linux/commits/lr-raspberry-pi-new-mailbox).
All updates are published in
[README.md](https://github.com/pietrushnic/rpi-dt-firmware/blob/master/README.md)
with every release.

Summary
-------

Of course we are happy with every contribution small and big, critique and
process improvement hints. Let us know what you think about this effort.
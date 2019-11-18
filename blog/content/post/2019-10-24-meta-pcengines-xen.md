---
title: 'XEN on the PC Engines apu2 - why you want to use it'
abstract: 'Xen Project creates a software system that allows the execution of multiple virtual guest operating systems simultaneously on a single physical machine. In this case, it is a PC Engines apu2 platform. '
cover: /covers/3mdeb-logo_simple-color.png
author: norbert.kaminski
layout: post
published: false
date: 2019-10-24
archives: "2019"

tags:
  - XEN
  - meta-pcengines
  - apu2
  - PC engines
categories:
  - OS Dev
  - Security
  - Manufacturing

---
# What is the Xen Project?

Xen Project creates a software system that allows the execution of multiple virtual guest operating systems simultaneously on a single physical machine.
It is valuable when you want to create a complex security software system.
None of the guest operating systems have direct access to the host hardware.

A Xen hypervisor manages the virtual machine guests known as domains.
It is controlled by a special domain called domain0 (dom0). Only the hypervisor
has access to the physical outputs of the platform. Depending on the guest type
(HVM or PV) hypervisor allows unprivileged domains (domUs) to use virtual
hardware devices or passes the links to the physical hardware. To know more look
at the Xen Project [wiki site](https://wiki.xenproject.org/wiki/Xen_Project_Beginners_Guide).

<i>
    <h2><p align=center>Xen Project architecture </p>
</i>

![Diagram](https://cloud.3mdeb.com/index.php/s/HNmc8yqbcCQzCje/preview)

# How to build the dom0 on the PC Engines APU2?

For this purpose, we will use the [meta-pcengines repository](https://github.com/pcengines/meta-pcengines.git).
This is the yocto layer, which allows creating a minimal image of the dom0.
The meta-pcengines needs a kas tool to construct the dom0 build.
Installation and configuration of that tool were described in detail in the
previous [blog](https://blog.3mdeb.com/2019/2019-02-07-kas/).

Once you have got the kas, clone the [meta-pcengines repository](https://github.com/pcengines/meta-pcengines.git).
In the main directory, you can see the config directory, the kas configuration,
and the recipes. The config files of the layer are responsible for setting up
the platform and distro configuration. The `conf/layer.conf` passes on the
information where to find the recipes. The kas configuration file contains
details, how to create the build and. It also inform about repositories that the
image is based on. 


To create the build, enter the command:
```
SHELL=bash kas-docker --ssh-dir ~/ssh-keys build meta-pcengines/kas.yml
```

Building the dom0 image can take several hours. At the end of the build, you
should see a similar log:

```
NOTE: Executing Tasks
NOTE: Setscene tasks completed
NOTE: Tasks Summary: Attempted 2871 tasks of which 0 didn't need to be rerun and all
 succeeded.
```

At that point you have to flash a bootable drive. On this spot  I will use the
dd command. Check a directory of the drive to be flashed:

```
sudo fdisk -l
```

Change the directory to `<build-dir>/build/tmp/deploy/images/pcengines-apu2` and
flash the drive:

```
sudo dd if=xen-dom0-image-pcengines-apu2.hddimg of=/dev/<drive_dir>
```

If everything went well, you should see the bootlog:

[![asciicast](https://asciinema.org/a/mzfBdiDWNiWPOEEkev2F6CxwX.svg)](https://asciinema.org/a/mzfBdiDWNiWPOEEkev2F6CxwX?t=95)

# VM guest configuration

Once you have created the dom0 on your APU platform, it is time to place a VM
guest. To boot up a simple guest, you have to write the configuration file. For
example:

```
name = "ndvm"
type = "hvm"
vcpus = 2
memory = 256
nographics = 1
serial = "pty"
vga="none"
disk=[ '/mnt/xen-ndvm-image-1.hddimg,,sda,rw' ]
```

It is required to name your new guest domain and define the boot image
directory. A detail description of each variable is given on the [xenbits website](https://xenbits.xen.org/docs/unstable/man/xl.cfg.5.html).

To create the VM guest, write the command:

```
xl create <config file directory>\<config file name>.cfg
```

If the dom0 works well, you should see the boot log of domU:

[![asciicast](https://asciinema.org/a/U17JbsCqhTHdT30tjTg9gjrPf.svg)](https://asciinema.org/a/U17JbsCqhTHdT30tjTg9gjrPf?t=174)

## Conclusions

In answer to the question asked in the title, I will point out that
meta-pcengines layer represents a simple, quick to use base for xen builds. It
provides the stability and safety for tests and security applications, thanks to
vm guest isolation from the host hardware. 
In future blogs, we will show the examples of the application, so if you are
interested in similar content, feel free to [sing up to our newsletter](http://eepurl.com/gfoekD).

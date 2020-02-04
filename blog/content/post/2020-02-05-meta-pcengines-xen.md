---
title: 'Easy way to stay secure - XEN on the PC Engines apu2'
abstract: 'Xen Project creates a software system that allows the execution of
  multiple virtual guest operating systems simultaneously on a single physical machine.
  In this case, it is a PC Engines apu2 platform.'
cover: /covers/3mdeb-logo_simple-color.png
author: norbert.kaminski
layout: post
published: false
date: 2020-02-05
archives: "2020"

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
### What is the Xen Project?

Xen Project creates a software system, that allows the execution of multiple
virtual guest environments simultaneously on a single physical machine.
It is valuable when you want to create a complex security software system
consisting of several operating systems. The unprivileged domains
(domUs), such as virtual operating systems have no direct access to the
hardware.

Between software and hardware is a hypervisor. It allocates resources for
new domains (the virtual operating systems) and schedules the existing ones.
To learn more about hypervisor see the official
[documentation](https://wiki.xenproject.org/wiki/Hypervisor).

### What is Domain0?

<i>
    <h2>
      <p align=center>Xen Project architecture </p>
    </h2>
</i>

![Diagram](https://cloud.3mdeb.com/index.php/s/HNmc8yqbcCQzCje/preview)

As shown in the diagram, Domain0 (Dom0) is the privileged domain and it manages
unprivileged domains (domUs). Dom0 is started by the hypervisor on boot and
ensures its usability. Therefore it is the Domain that has direct access to the
hardware. The Domain0 provides hardware connections to DomUs. Dom0 allows full
virtualized guests to use the virtual hardware and passes the physical links
paravirtualized domains.

### How to build Dom0 on the PC Engines apu2?

To build the special domain for the PC Engines apu2 board, We will use the
[meta-pcengines repository](https://github.com/3mdeb/meta-pcengines/tree/c4ee98ab390b073807173584107c09f49ac1e390).
The repository contains the yocto layer, that allows you to create a
minimal image of the dom0. To build a usable version of the dom0 image, the
meta-pcengines needs a [kas tool](https://kas.readthedocs.io/en/0.19.0/index.html).
Installation, configuration, and some more information about that tool
you can find in the previous [blog](https://blog.3mdeb.com/2019/2019-02-07-kas/).

Once you have installed the kas, clone the
[meta-pcengines repository](https://github.com/3mdeb/meta-pcengines/tree/c4ee98ab390b073807173584107c09f49ac1e390).
To reproduce my results, check if the source commit matches shown above.
The source consists of configuration files, a kas script, and recipe files.
The layer configuration specifies settings for the platform and distro.
It points out where the recipes are placed. The kas script is used by the kas
tool to clone and checkout `bitbake` layers. It also allows kas to create a
default `bitbake` variables such as MACHINE, DISTRO, etc.

Now it is time to create the build. Stay in the meta-pcengines parent directory
and enter the command:

```
SHELL=bash kas-docker --ssh-dir ~/ssh-keys build meta-pcengines/kas.yml
```

The Dom0 image build process can take several hours. Once the build is finished,
you will see a similar output:

```
NOTE: Executing Tasks
NOTE: Setscene tasks completed
NOTE: Tasks Summary: Attempted 2871 tasks of which 0 didn't need to be rerun and all
 succeeded.
```

At this point, create a bootable USB drive. Change the directory to
`<build-dir>/build/tmp/deploy/images/pcengines-apu2` and replace sdx in below
command with the device node of your USB flash drive.

```
sudo dd bs=4M if=xen-dom0-image-pcengines-apu2.hddimg of=/dev/sdx
```

Once you have created the bootable drive, try to boot your platform.
The following video shows the correct bootlog:

[![asciicast](https://asciinema.org/a/Tr4hhF9sBKC0C9YO5GkwHUrcJ.svg)](https://asciinema.org/a/Tr4hhF9sBKC0C9YO5GkwHUrcJ?t=16)

### Guest VM configuration

Once you have booted the dom0 on your apu2 platform, it is time to launch a VM
guest. At first write the config file, where you will set up the guest domain
optins. Here is the example:

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

You have to set the `name` of your new guest domain. In the `disk` variable,
point the path of the image guest image. A detailed description of each variable
is given on the [xenbits website](https://xenbits.xen.org/docs/unstable/man/xl.cfg.5.html).

Create the VM guest whit the command:

```
xl create <config_file_directory>\<config_file_name>.cfg
```

The following out shows the boot process:

[![asciicast](https://asciinema.org/a/aQfr4P7HneRxkzIN42iHFX3Sd.svg)](https://asciinema.org/a/aQfr4P7HneRxkzIN42iHFX3Sd?t=10)

### Conclusions

The main goal of the meta-pcengines is to enable Yocto builds for pcengines
(apu2) boards. It provides a good base for various use cases such as Xen.
IIn future blogs we will show more application examples.
So if you are intrested [sign up to our newsletter](http://eepurl.com/gfoekD).

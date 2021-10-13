---
title: 'Easy way to stay secure - XEN on the PC Engines apu2'
abstract: 'Xen Project creates a software system that allows the execution of
  multiple virtual guest operating systems simultaneously on a single physical machine.
  In this case, it is a PC Engines apu2 platform.'
cover: /covers/3mdeb-logo_simple-color.png
author: norbert.kaminski
layout: post
published: true
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
consisting of several operating systems. Unprivileged domains
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

![Diagram](/img/xen-architecture.jpg)

As shown in the figure, domain0 (dom0) is the privileged domain, which manages
unprivileged domUs. Dom0 is started by the hypervisor at the boot and
ensures its usability. Therefore the dom0 has direct access to the
hardware. The Domain0 provides hardware connections to domUs. Depending on the
guest type, dom0 allows hardware virtualized guests (HVM) to use emulated
hardware. In the case of paravirtualized domains (PV), the dom0 connects
the domUs with the hardware via backend and the drivers. Here is more
information about [Virtualization Spectrum](https://wiki.xenproject.org/wiki/Understanding_the_Virtualization_Spectrum)

### How to build Dom0 on the PC Engines apu2?

We will use the [meta-pcengines repository](https://github.com/3mdeb/meta-pcengines/tree/c4ee98ab390b073807173584107c09f49ac1e390).
to build the special domain for the PC Engines apu2 board.
The repository contains the yocto layer, that allows you to create a
minimal image of the dom0. The meta-pcengines uses a
[kas tool](https://kas.readthedocs.io/en/1.0/) to build the dom0 image.
Installation, configuration, and some more information about this tool
you can find in the previous [blog](https://blog.3mdeb.com/2019/2019-02-07-kas/).

Once you have installed the kas, clone the
[meta-pcengines repository](https://github.com/3mdeb/meta-pcengines/tree/c4ee98ab390b073807173584107c09f49ac1e390).
To reproduce my results, check if the source commit matches shown above.
The source consists of configuration files, a kas configuration file,
and recipe files. The layer configuration specifies settings for the platform
and distro It points out where the recipes are placed. The kas configuration
file is used by the kas tool to clone and checkout Yocto layers. It also
allows kas to create default BitBake variables such as MACHINE, DISTRO, etc.

Now it is time to create the build. Move to the meta-pcengines parent directory
and enter the command:

```
SHELL=bash kas-docker build meta-pcengines/kas.yml
```

The dom0 image build process can take several hours, so you can take a coffee
break. Once the build is finished, you will see a similar output:

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
options. Here is an example:

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

Create the VM guest with the command:

```
xl create <config_file_directory>\<config_file_name>.cfg
```

The following output shows the boot process of the domU:

[![asciicast](https://asciinema.org/a/aQfr4P7HneRxkzIN42iHFX3Sd.svg)](https://asciinema.org/a/aQfr4P7HneRxkzIN42iHFX3Sd?t=10)

### Conclusions

The main goal of the meta-pcengines is to enable Yocto builds for pcengines
(apu2) boards. It provides a good base for various use cases such as Xen.
In future blogs, we will show more application examples.
So if you are interested [sign up to our newsletter](http://eepurl.com/doF8GX).

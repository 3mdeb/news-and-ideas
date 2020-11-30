---
title: coreboot port for OpenPOWER - why bother?
abstract: 'You may have heard by now that we are working on coreboot port for
          Talos II. OpenPOWER already has, nomen omen, open source firmware, so
          one may ask why bother? We will try to answer that question.'
cover: /covers/coreboot-logo.svg
author: krystian.hebel
layout: post
published: true
date: 2020-11-30
archives: "2020"

tags:
  - firmware
  - coreboot
  - openpower
categories:
  - Firmware

---

You may have heard by now that we are working on coreboot port for [Talos II](https://raptorcs.com/TALOSII/).
OpenPOWER already has, nomen omen, open source firmware, so one may ask why
bother? In this blog post we will try to answer that question.

## Short introduction to OpenPOWER boot process and its components

Talos II is a server platform managed by a slightly customised (mainly to handle
specific dual-CPU boot synchronisation quirks) [OpenBMC fork](https://git.raptorcs.com/git/talos-openbmc/).
BMC signals the main (host) platform to start booting.

Next comes the [Self-Boot Engine](https://wiki.raptorcs.com/wiki/Self-Boot_Engine).
This term is actually used both for a chip (which is part of main CPU, it is a
reduced PowerPC core) and its [firmware](https://git.raptorcs.com/git/talos-sbe/).
SBE's tasks are initialisation of main CPU cores and loading and staring the
next component called Hostboot.

[Hostboot](https://git.raptorcs.com/git/talos-hostboot/) is the first component
running on main cores. It is responsible mainly for the memory initialisation
and training, it also initialises some of the platform buses.

[Skiboot](https://git.raptorcs.com/git/talos-skiboot/) is then chainloaded. Its
tasks include initialisation of the rest of the hardware, e.g. PCI Express host
bus controllers. It also implements OPAL ([OpenPOWER Abstraction Layer](https://open-power.github.io/skiboot/doc/opal-spec.html#what-is-opal)),
which is an interface to access firmware services from an OS. This is similar to
the UEFI runtime services or legacy BIOS interrupt calls.

Next link in this chain is [Skiroot](https://github.com/open-power/linux) (a
small set of patches on top of the mainstream Linux kernel) accompanied by
[Petitboot](https://git.raptorcs.com/git/talos-petitboot/) (userspace
application). The latter is a bootloader, it uses kexec to load the final
operating system from any device that can be mounted by Linux, including network
boot.

There are also other pieces of firmware running on different chips. Those are
responsible for thermal and power management or CAPI (coherent accelerator
processor interface) support. Most of them are loaded by the Hostboot.

A list of links to more detailed descriptions of all of the mentioned components
can be found [here](https://wiki.raptorcs.com/wiki/OpenPOWER_Firmware).

## coreboot's place in the OpenPOWER boot chain

OpenPOWER separates individual tasks required in the boot process in a slightly
different manner than coreboot. In coreboot, a great emphasis is placed on the
separation of one-time initialisation (coreboot stages) and runtime services
(payload). Skiboot mixes those two - it does the hardware initialisation usually
performed by a ramstage in coreboot, but it also installs OPAL services, which
is better suited for a payload in a coreboot's world.

With the above in mind we decided that it would be best to start with porting
just the Hostboot part, at least for the time being. Earlier stages are run by a
separate hardware, and dividing Skiboot into "hardware" and "services" parts at
this stage may introduce additional bugs. It is safer to implement one component
at a time than fail trying to do them all in one go.

## Benefits

We can define two classes of possible benefits: one is what coreboot and its
community can gain, the other one is what end users get from it.

#### For users

Boot time reduction was one of the main reasons for doing this port. Hostboot
itself takes more than 1 minute to run. This is mostly spent on accessing flash
memory. It is split into multiple PNOR (Processor NOR, POWER name for flash)
partitions, summing up to just below 32 megabytes. It runs from cache until it
trains main memory, so it is limited to just 10 MB (size of L3 cache) split
between two cores. To make it possible to load and execute that amount of code,
[Hostboot uses on-demand paging](https://youtu.be/fTLsS_QZ8us?t=1559). It is
similar to swap used by operating systems, except that it uses ROM instead of
writable media, so only code and constant data can be discarded from memory (L3
cache in this case).

Another issue was nicely formulated by Timothy Pearson from Raptor CS:

> Hostboot is a VM to run FSI routines, and the FSI routines are written one by
> one by the hardware engineers designing the silicon itself.  This leads to
> overly complex and difficult to understand code, as you can see.

FSI is one of the buses Hostboot has to initialise. By simplifying the code we
can make it **easier to understand** (no need to translate virtual addresses to
the physical ones), **faster** (by discarding a dozen of function calls before
the proper write to the register happens) and **smaller**. Smaller code means
less time spent on reading from flash, but also more space for other components,
like new drivers for Skiroot.

#### For the coreboot community

coreboot would get a **new architecture** supported. Although there are stubs,
cross-compiler and libraries for PPC, the coreboot itself isn't in working state
when it comes to this architecture as of now. It would also get a **new, truly
open** ([unless you want SATA controller](https://wiki.raptorcs.com/wiki/PM8068))
platform.

PowerPC by default uses big endian. It is configurable at runtime, but the
libraries included in coreboot-sdk are compiled for BE. This gives a perfect
opportunity to validate that **coreboot works also for big endian platforms**.
By now we confirmed that there are parts in CBFS and FMAP which need small
fixes. The endianness of fields also needs to be properly documented for those
structures, as they can be used both by a platform it is started on, as well as
an application on a platform it is built on. Those two do not have to use the
same endianness.

The biggest achievement of this port would undoubtedly be bringing support for
**native DDR4 initialisation and training**. Even though the details of
accessing the hardware are platform-specific, the general process stays the
same. One caveat might be that Talos II supports only RDIMM (registered, or
buffered DIMM) and that is the only kind of memory sticks we are able to test,
however even if it won't work out of the box for different DIMM flavours, it
should give a good base to build on.

## Current state of work

We have successfully started coreboot on the platform:

[![asciicast](https://asciinema.org/a/JQ1MaBSzGN1L1JcbgTX3G3kt6.svg)](https://asciinema.org/a/JQ1MaBSzGN1L1JcbgTX3G3kt6?speed=1)

Actually, we were starting it much earlier than we knew it, because we used a
wrong address for serial port. It was caused mostly because of improper analysis
of Hostboot's code, so we ended up converting virtual address to a physical one
using a negative offset compared to what we should have used. This is what you
get from mixing virtual memory management and manual pointer calculations 🙂️

Since then we believe we have [mostly fixed all of the endianness issues](https://github.com/3mdeb/coreboot/commits/fmap_cbfs_endian),
so `Couldn't load romstage` became `Payload not loaded`, without any actual
initialisation code. After thorough tests and updates to the documentation we
will begin to upstream these changes.

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

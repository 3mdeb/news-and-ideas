---
title: "ZarhusBMC: The second encounter - Porting OpenBMC to X11SSH part II"
abstract: 'In this blog post we share current progress of ZarhusBMC and porting
           OpenBMC to the x11ssh platform. We also give some insides on the
           caveats that come with preparing configuration for proprietary
           platform.'
cover: /covers/x11ssh_se_cover.jpg
author: mateusz.kusiak
layout: post
published: true
date: 2025-07-31
archives: "2025"

tags:
  - zarhus
  - insights
  - supermicro
  - BMC
categories:
  - Firmware
  - Miscellaneous
  - OS Dev

---

## Introduction - the struggle continues

This is the second part (or a second edition) of the blog post series regarding
ZarhusBMC and porting OpenBMC to the Supermicro `x11ssh` platform. In this
blog post, I'll share the progress we made since the last time, where we
currently stand, and what the future plans are for the platform.

### Up to speed

If you want to get up to speed with the first ZarhusBMC and `x11ssh` related
blog post, here's a link for your convenience:
[blog.3mdeb.com/2025/2025-04-28-zarhusbmc/](https://blog.3mdeb.com/2025/2025-04-28-zarhusbmc/)[^last-post]

In the first blog post, I provided a general overview of what OpenBMC is and the
role it takes in the world of proprietary, unauditable solutions. I also
showcased the effort it took to run custom-built OpenBMC on the `x11ssh`
platform.

I have since managed to build OpenBMC with serial console access. During the
[Last Zarhus Developers meetup](https://cfp.3mdeb.com/zarhus-developers-meetup-0x1-2025/talk/WQC7LP/)[^last-meetup],
I showcased that we were able to access the web UI of OpenBMC, but because
I compiled the solution without user management setup, we could not access the
admin console.

The fact that software is running does not necessarily mean it is working.
...and this is where we start this blog post.

## The second encounter

Not long after the presentation, I found myself working on porting OpenBMC once
again. I have recompiled the custom OpenBMC, but this time, instead of disabling
user management, I disabled logging (who would need that, right?) and managed
to enter the OpenBMC admin panel via Web UI.

![OpenBMC Admin Panel](/img/obmc-admin-panel.png)

...but it looks a bit empty, innit?

### The real issue

While the system (OpenBMC) is running, there is no communication with the host,
and the task was to establish why.

TL;DR: The issue narrows down to two major service failing as shown in the below
snippet (I'm ignoring LEDs for now).

```log
root@x11ssh:~# systemctl list-units --type=service | grep failed
* obmc-led-group-start@bmc_booted.service                                     loaded failed failed  Assert bmc_booted LED
* phosphor-ipmi-kcs@ipmi-kcs3.service                                         loaded failed failed  Phosphor IPMI KCS DBus Bridge
* xyz.openbmc_project.Chassis.Control.Power@0.service                         loaded failed failed  Intel Power Control for the Host 0
```

The `ipmi-kcs` is a main service that controls communication with the host. The
IPMI (Intelligent Platform Management Interface) is a protocol for independent
hardware management, while the KCS (Keyboard Controller Style) is a transport
layer between the host and the BMC for communication. This component is crucial
for OpenBMC to work properly, but I'll share the reason why it isn't working
later in this post.

The second `Control.Power` service, as the name suggests, is responsible for
controlling platform power states. It too is a crucial component, and due to it
not working, we could not even control the host power state from the Web-UI.

#### The issue with KCS

The BMC firmware is essentially just another ARM Linux distribution. Like on
most ARM-based systems, hardware is described via the device tree, which
includes physical interfaces such as KCS. The device tree structures can come
from various sources: delivered by SoC Vendors, created based on schematics and
data sheets, or made by reverse engineering. It is not something one would want
to create from the beginning.

The fact is, the `dts/dtsi` files for Aspeed AST2400 embedded into `x11ssh`
motherboard do not have the KCS interfaces defined. This is how the KCS
definition could look.

```log
    kcs3: kcs@2c {
     compatible = "aspeed,ast2500-kcs-bmc-v2";
     reg = <0x2c 0x1>, <0x38 0x1>, <0x44 0x1>;
     interrupts = <8>;
     clocks = <&syscon 8>;
     status = "disabled";
    };
```

Source:
[linux-aspeed](https://github.com/AMDESE/linux-aspeed/blob/integ_sp7/arch/arm/boot/dts/aspeed/aspeed-g5.dtsi#L474)[^aspeed-gh]

This definition comes from a newer, Aspeed AST2500 device structure. Since we're
missing this definition, the KCS device is not created, and thus the service
fails.

```log
root@x11ssh:~# systemctl start phosphor-ipmi-kcs@ipmi-kcs3.service
Job for phosphor-ipmi-kcs@ipmi-kcs3.service failed because the control process exited with error code.
See "systemctl status phosphor-ipmi-kcs@ipmi-kcs3.service" and "journalctl -xeu phosphor-ipmi-kcs@ipmi-kcs3.service" for details.
root@x11ssh:~# systemctl status phosphor-ipmi-kcs@ipmi-kcs3.service
x phosphor-ipmi-kcs@ipmi-kcs3.service - Phosphor IPMI KCS DBus Bridge
     Loaded: loaded (8;;file://x11ssh/usr/lib/systemd/system/phosphor-ipmi-kcs@.service/usr/lib/systemd/system/phosphor-ipmi-kcs@.service8;;; enabled; preset: 5:185mdisabled)
     Active: failed (Result: exit-code) since Thu 2024-12-19 22:03:08 UTC; 16s ago
 Invocation: 498e04833e5e4183bdecb22273fd34bd
    Process: 381 ExecStart=/usr/libexec/kcsbridged -c ipmi-kcs3 (code=exited, status=1/FAILURE)
   Main PID: 381 (code=exited, status=1/FAILURE)
[...]
root@x11ssh:~# /usr/libexec/kcsbridged -c ipmi-kcs3
FAILED: open `/dev/ipmi-kcs3`: No such file or directory
[...]
root@x11ssh:~# ls /dev/ | grep "ipmi\|kcs"
root@x11ssh:~#
```

The good news, however, is that these (KCS) addresses seem to be standardized
between various Aspeed models and can also be found in the SoC datasheet. I just
haven't had a chance to test if adding it would work, but I don't see why it
wouldn't.

#### GPIO issue

The second issue is also related to the device tree structure and missing
definitions, but this case is different. While multiple vendors can use the same
BMC SoC, and each deployment will use the same set of KCS addresses, it's up to
the OEM to decide how to "wire up" the BMC. This makes each deployment specific.

This is important as BMCs feature a set of GPIO pins that probe or set up
various endpoints on the motherboard. This might seem like it isn't really an
issue. How many GPIOs can such a BMC have, right?

The answer is 216 (as stated in documentation), which is too high a number for
a trial-and-error approach. For base operation, we should not require a full
subset of pins, but still, we are missing definitions that are required for power
state managers.

```log
root@x11ssh:~# systemctl status xyz.openbmc_project.Chassis.Control.Power@0.service  -l
x xyz.openbmc_project.Chassis.Control.Power@0.service - Intel Power Control for the Host 0
     Loaded: loaded (8;;file://x11ssh/usr/lib/systemd/system/xyz.openbmc_project.Chassis.Control.Power@.service/usr/lib/systemd/system/xyz.openbmc_project.Chassis.Control.Power@.service8;;; static5:185m)
     Active: failed (Result: exit-code) since Wed 2025-05-28 07:47:23 UTC; 31s ago
   Duration: 221ms
 Invocation: 61954bed677f4eaf968da173a1076bb5
    Process: 433 ExecStart=/usr/bin/power-control 0 (code=exited, status=255/EXCEPTION)
   Main PID: 433 (code=exited, status=255/EXCEPTION)
[...]
root@x11ssh:~# /usr/bin/power-control 0
<6> Start Chassis power control service for host : 0
<3> BiosMux is not a recognized power-control signal name
<3> Host0: Error in Parsing...
<6> SIO control GPIOs not defined, disable SIO support.
<3> PowerOk name should be configured from json config file
```

_Note: I later switched to x86 power control._

The GPIO definitions for `x11ssh` for
[u-bmc](https://github.com/osresearch/u-bmc/blob/kf/x11/platform/supermicro-x11ssh-f/pkg/gpio/platform.go)[^keno-ubmc],
[HardenedVault's attempt](https://github.com/hardenedvault/openbmc/blob/x11ssh-f/meta-supermicro/meta-x11ssh/recipes-kernel/linux/linux-aspeed/0001-add-aspeed-bmc-supermicro-x11ssh-dts.patch)[^hw-attempt],
or our attempts, all use the work of [Keno Fisher](https://github.com/keno)[^keno]
for those definitions. While the subset for pins might have been sufficient for
`u-bmc` in the past (the x11ssh development has been abandoned), it is not
sufficient for now. I've got to admit, it's still a mystery to me how Keno
managed to come up with those definitions; however, I'll touch on one possible
approach later in this post.

## The effort

The "damage control" isn't the only thing we were focusing on since the last
time. Although we have not yet been successful in addressing the previously
mentioned issues, as many other projects come in the way, we still managed to
progress a lot thanks to the community effort. Let's discuss what we managed to
achieve.

### Open discussions

Let's start with something different, non-technical. We've launched
[ZarhusBMC discussions](https://github.com/zarhus/zarhusbmc/discussions)[^dscsns],
where anyone interested in the project can check out what we are currently
working on in the BMC space. In true open-source spirit, we want to be as
transparent as possible, and we encourage taking an active part in the
discussion.

We've already hosted two such discussions. These aim for these to be a more
streamlined form of live coding. Every time we're working on something, a
discussion is made, and we update statuses as we go. This has two upsides that
are partially related. First of all, we're closer to the community, and
secondly, in case we require any 3rd party or community input, the results and
steps we tried are in the commonplace and publicly available.

Speaking of commonplace, we've chosen GitHub discussions as a place to host
these. True, you'll still need an account to take part in the discussion, but
at least the information is publicly accessible.

As a side note, being so open also has its downsides. One being the free
(as in free will) content is a
"[free real estate](https://i.imgflip.com/24r48o.jpg?a486960)[^meme]" for AI
bot farms, which we
[already had a taste of](https://youtu.be/kK6Dz1gnmmY)[^bots] 😉.

### Probing stock firmware p. I - QEMU, binwalk, gdb, and stock firmware sources

In order to resolve the previously mentioned issues, mainly the GPIO pins
definitions, we decided to give a stock firmware probing a chance. The attempt
can be summarized in 4 steps:

#### Disassembling the firmware image

First, we decided to have a go at disassembling the firmware binary. The
`binwalk` utility has been used in the process, and it successfully extracted
the "partition layout". This way, we could go through most of the files
comfortably. We were hoping we could find device tree binaries (DTBs) for a
further attempt at decompilation. Unfortunately, due to the age of the Linux
kernel used, it was not possible, but more on that later.

#### Booting stock firmware under QEMU

1. As a second take, we've "booted" the stock firmware under QEMU, same as we
previously did with our custom-built OpenBMC image. This gave us a peek inside
the running system, but due to the missing hardware, many services were failing,
thus it was hard to assess how reliable scoping would be. We were, however, able
to gain some insight this way: the firmware runs on an ancient, custom Linux
kernel version `2.6.28.19`, there was no `/proc/devicetree` nor a `sysfs`
interface for controlling GPIOs. ...and this brings us to the next point.

#### ATAGs

1. Due to the age of the kernel, we suspected the Linux kernel uses a
pre-device-tree mechanism known as
[ATAGs](https://stackoverflow.com/questions/21014920/arm-linux-atags-vs-device-tree)[^atags].
ATAGs provide only basic platform information, so the running image can verify
it, and all the hardware support is built directly into the "kernel". We used
`gdb` to verify that's indeed the case.

```log
boot# imls
Legacy Image at 21400000:
Image Name:   21400000
Image Type:   ARM Linux Kernel Image (gzip compressed)
Data Size:    1536834 Bytes =  1.5 MB
Load Address: 40008000
Entry Point:  40008000
Verifying Checksum ... OK
boot# bdinfo
arch_number = 0x00000385
env_t       = 0x00000000
boot_params = 0x40000100
DRAM bank   = 0x00000000
-> start    = 0x40000000
-> size     = 0x08000000
ethaddr     = 00:00:00:00:00:00
ip_addr     = 192.168.0.188
baudrate    = 115200 bps
boot# md.b 0x40000100 64
```

```log
(gdb) break *0x40008000
Breakpoint 1 at 0x40008000
(gdb) c
Continuing.

Breakpoint 1, 0x40008000 in ?? ()
(gdb) info registers r0
r0             0x0                 0
(gdb) info registers r1
r1             0x385               901
(gdb) info registers r2
r2             0x40000100          1073742080
(gdb) info registers r3
r3             0x9007a             589946
(gdb) info registers r4
r4             0x0                 0
(gdb) info registers r5
r5             0x4052fd0c          1079180556
(gdb) info registers r6
r6             0x404cffb8          1078788024
(gdb) info registers r7
r7             0x385               901

[...]

(gdb) x/12wx 0x40000100
0x40000100:     0x00000005      0x54410001      0x00000000      0x00000000
0x40000110:     0x00000000      0x00000004      0x54410002      0x08000000
0x40000120:     0x40000000      0x00000000      0x00000000      0x00000000
```

The `r2` register confirms the presence of the ATAG mechanism.

#### Sources

Our last chance at that moment was scoping the source files for the stock
firmware. How obtainable are these, you might ask? As previously stated, the
BMC firmware is basically yet another ARM Linux distribution, and the Linux
GPL license requires publishing the source code of the solution. Moreover,
the GPL is a "viral" license. If you incorporate part of a GPL solution into
your software, it must be licensed under the same license. This ensures any
interested 3rd party shall have access to the sources if requested.
Corporations try to comply with those requirements, but use other "developer
access prevention methods" (joke) like burying the sources deep into
the tree of the download page so they're not indexed by search engines and
are a bit harder to find. Luckily, we managed to find
[the sources for stock BMC firmware](https://www.supermicro.com/wdl/GPL/SMT/X10_GPL_Release_20150819.tar.gz)[^fw-srcs]
on our own. Unfortunately, all the interesting stuff in the form of
proprietary kernel modules in said repo is already precompiled, thus the
information cannot be easily extracted. Generally, the approach of supplying
prebuilt kernel modules is a gray zone. It is discouraged, but it is
acceptable[^torvalds-on-prop-mod].

### Notice me senpai - accessing UART on stock firmware

Since we temporarily ran out of easy-to-execute ideas for probing the stock
firmware via hardware emulation, we decided to play with a stock firmware
running on real hardware. You'd be right to doubt it's that easy, and you'd
be correct. Thankfully, due to community effort, this was much easier.

We wanted to gain UART access to the BMC. We knew this was possible, as such a
successful attempt has been made in the past. Keno Fisher, the same guy who
did the majority of the work for running `U-BMC` on `x11ssh` platform, did
[a blog post](https://github.com/Keno/bmcnonsense/blob/master/blog/03-serial2.md)[^keno-blog]
in which he described finding the UART `TX` (transmit) pin by probing the board.
This gave him one-way (read) access to BMC UART, but for our case, that wasn't
enough.

Thankfully, shortly after our previous post on ZarhusBMC was published,
[Tim Ansell](https://github.com/mithro)[^tim] reached out offering the Gerber files
for the `x11ssh` platform. These are publicly available on
[his repo](https://github.com/mithro/x11ssh-f-pcb)[^grbrs].

The combination of Keno's and Tim's work allowed us to trace the pin Keno
found back to the Aspeed SoC, figure out the corresponding `RX` (receive) pin
with the help of
[AST2400](https://gitcode.com/Open-source-documentation-tutorial/69bbb)[^aspd-doc]
documentation, we managed to find and trace where said pin ends up on the
motherboard.

![x11ssh gerber](/img/x11ssh_grbr.gif)

The trace ended up on an unpopulated pad, and then it was a matter of soldering
jumper wires to the motherboard.

![hackjob](/img/x11ssh_hackjob.jpg)

Then, a one "hardware-flow control disabling" later, and bada bing bada boom,
we've got the UART access to the stock firmware running on real hardware.

![x11ssh stock UART access](/img/x11ssh_stock_uart.png)

The cool part is this is the first public discussion we've shared and got
massive positive feedback, check out
[the discussion](https://github.com/zarhus/zarhusbmc/discussions/3)[^uart-d] to learn
more. What's even cooler is that
[Keno himself responded on the Hacker News thread](https://news.ycombinator.com/item?id=44387904)[^hnws]
(thus the title of that subsection 😅).

### Probing stock firmware p. II - hardware

The last thing we've managed to do until other projects came in was perform
scoping of stock firmware, but this time on a firmware running on real
hardware.

We've confirmed that, even with all services starting properly, we did not have
access to any of the interfaces (like `sysfs`) for controlling or probing the
GPIO pins. The precompiled binaries were also checked if they could be of any
use, but besides those clearly marked as "tool", most of them just ended up
segfaulting, as I suppose they expect some kind of input stream.

What we have managed to do, though, is learning how to probe GPIOs. The
developers conveniently left us the devmem binary. This, along with the
documentation, enabled us to take a peek at the GPIO registers (direction,
state, etc.). By putting the host into different states (on, off), we could
observe the register values getting changed.

![Register values comp.](/img/x11ssh_gpio_regs.png)

The output is kind of useful. What it allows us to do is, instead of tracing back
all 216 GPIOs, we can reduce this number to the number of bits that got flipped
during the state change. There's a high possibility the "Power OK" pin is
among those that got flipped. What's left is correlating those register values
with the physical pin locations on the SoC with the help of the previously
mentioned data sheet, tracing them with the Gerber files we've got, and
understanding their role. It is a complex task, but it at least gives some
options for further development in this area.

## What's next

Now you should have an idea of where we currently stand with porting OpenBMC
to the `x11ssh` platform. Having said that...

> "I've experiments to run. There is research to be done" - GLaDOS

Jokes aside, we've got plenty of ideas on the next steps. We still have to
verify the KCS addresses theory, we want to try probing the BMC from the host
side, and we're thinking of making automated tooling for easier porting of
OpenBMC, but that last one will rather target newer platforms (wink wink). If
you want to keep track of what we're currently working on, check out
[ZarhusBMC discussions pane](https://github.com/zarhus/zarhusbmc/discussions)[^pane],
catch us [on Matrix Zarhus Space](https://matrix.to/#/#zarhus:matrix.3mdeb.com)[^matrix],
or for serious offers, drop us an email at `contact<at>3mdeb<dot>com`.

## References and resources

Additional resources:

- [Previous ZarhusBMC blogpost](https://blog.3mdeb.com/2025/2025-04-28-zarhusbmc/)
- [Last Zarhus meetup](https://cfp.3mdeb.com/zarhus-developers-meetup-0x1-2025/talk/WQC7LP/)
- [Incoming Zarhus meetup](https://cfp.3mdeb.com/zarhus-developers-meetup-2-2025/talk/QRDX8S/)
- [ZarhusBMC discussions](https://github.com/zarhus/zarhusbmc/discussions)
- [ZarhusBMC UART thread](https://github.com/zarhus/zarhusbmc/discussions/3)
- [ZarhusBMC stock firmware probing thread](https://github.com/zarhus/zarhusbmc/discussions/4)
- [Keno Fisher](https://github.com/keno)
- [Tim Ansell](https://github.com/mithro)
- [Keno Fisher's blog post](https://github.com/Keno/bmcnonsense/blob/master/blog/03-serial2.md)
- [x11ssh Gerbers (Tim Ansell)](https://github.com/mithro/x11ssh-f-pcb)
- [HardenedVault OpenBMC port](https://github.com/hardenedvault/openbmc/tree/x11ssh-f)
- [Keno Fisher's u-bmc port](https://github.com/osresearch/u-bmc/tree/kf/x11)
- [AST2400 datasheet](https://gitcode.com/Open-source-documentation-tutorial/69bbb)
- [x11ssh stock firmware sources](https://www.supermicro.com/wdl/GPL/SMT/X10_GPL_Release_20150819.tar.gz)
- [X11ssh stock firmware binary](https://www.supermicro.com/en/support/resources/downloadcenter/firmware/SYS-5019S-M/BMC)

References:
[^last-post]: <https://blog.3mdeb.com/2025/2025-04-28-zarhusbmc/>
[^last-meetup]: <https://cfp.3mdeb.com/zarhus-developers-meetup-0x1-2025/talk/WQC7LP/>
[^aspeed-gh]: <https://github.com/AMDESE/linux-aspeed/blob/integ_sp7/arch/arm/boot/dts/aspeed/aspeed-g5.dtsi#L474>
[^keno-ubmc]: <https://github.com/osresearch/u-bmc/blob/kf/x11/platform/supermicro-x11ssh-f/pkg/gpio/platform.go>
[^hw-attempt]: <https://github.com/hardenedvault/openbmc/blob/x11ssh-f/meta-supermicro/meta-x11ssh/recipes-kernel/linux/linux-aspeed/0001-add-aspeed-bmc-supermicro-x11ssh-dts.patch>
[^keno]: <https://github.com/keno>
[^dscsns]: <https://github.com/zarhus/zarhusbmc/discussions>
[^meme]: <https://i.imgflip.com/24r48o.jpg?a486960>
[^bots]: <https://youtu.be/kK6Dz1gnmmY>
[^atags]: <https://stackoverflow.com/questions/21014920/arm-linux-atags-vs-device-tree>
[^fw-srcs]: <https://www.supermicro.com/wdl/GPL/SMT/X10_GPL_Release_20150819.tar.gz>
[^torvalds-on-prop-mod]: <http://linuxmafia.com/faq/Kernel/proprietary-kernel-modules.html>
[^keno-blog]: <https://github.com/Keno/bmcnonsense/blob/master/blog/03-serial2.md>
[^tim]: <https://github.com/mithro>
[^grbrs]: <https://github.com/mithro/x11ssh-f-pcb>
[^aspd-doc]: <https://gitcode.com/Open-source-documentation-tutorial/69bbb>
[^uart-d]: <https://github.com/zarhus/zarhusbmc/discussions/3>
[^hnws]: <https://news.ycombinator.com/item?id=44387904>
[^pane]: <https://github.com/zarhus/zarhusbmc/discussions>
[^matrix]: <https://matrix.to/#/#zarhus:matrix.3mdeb.com>

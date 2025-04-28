---
title: "ZarhusBMC: The Beginning - Porting OpenBMC to the X11SSH Platform"
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: mateusz.kusiak
layout: post
published: true
date: 2025-04-28
archives: "2025"

tags:
  - zarhus
  - insights
  - supermicro
  - BMC
categories:
  - Firmware
  - OS Dev

---

## Introduction - Reclaim your server

BMCs (Baseboard Management Controllers) are the backbone of
remote server management. They allow for monitoring platform health, performing
recoveries, troubleshooting, and general management of your platform directly
from your web browser. But the issue is, **is the platform yours** when such a
crucial component runs unauditable code? **Can one trust such a component**?

That's exactly what OpenBMC tries to solve. **OpenBMC is an open-source firmware
alternative for BMCs**. It offers more flexibility and customization, and above
all, it's more secure since its source code can be audited and kept up to date.

In this blog post, I'll discuss our current effort in **porting OpenBMC to the
Supermicro x11ssh** platform. I'll go over some caveats of compiling OpenBMC
for a not (yet) supported platform, the current state of upstream, how to test
the built image under QEMU, and where we are currently at with executing the
code on real hardware. This post isn't about what **BMCs** are, but if the topic
sounds interesting to you, and you want to get up to speed on BMCs, check out
[this article](https://www.supermicro.com/en/glossary/baseboard-management-controller)
from the OEM whose firmware we'll be replacing (oh the irony).

---

## State of the upstream

Before I dive into the caveats of compiling OpenBMC for an unsupported
platform, let's discuss the current state of OpenBMC upstream.

### Latest release

As of today (28/04/2025), the newest OpenBMC release is
[`2.14.0`](https://github.com/openbmc/openbmc/releases/tag/2.14.0) dated
16/05/2023. This means it has been almost two years since last release, yet
there's active development happening.

### Platform support and CI

The platform I aim to build OpenBMC for is
[Supermicro x11ssh-f](https://www.supermicro.com/en/products/motherboard/x11ssh-f)
for which, there's no official configuration. I intentionally used
"no configuration" rather than "no support" as in practice, for OpenBMC these
are two different things. It's easier to explain it in an example. While the
official OpenBMC repository contains configuration for a similar `x11spi`
platform, saying it is supported would be an overstatement (although
[the readme](https://github.com/openbmc/openbmc?tab=readme-ov-file#will-openbmc-run-on-my-acme-server-corp-xyz5000-motherboard)
might have a different opinion). OpenBMC has
[public CI](https://jenkins.openbmc.org/job/ci-openbmc/), but this platform in
particular is not being tested there. The thing is, if a platform is not
regularly tested in CI, you can't be certain that it actually works. ...and that
was exactly the case but more on that later.

In case you're wondering, here's the
[list of platforms](https://github.com/openbmc/openbmc/blob/master/meta-phosphor/docs/supported-machines.md)
OpenBMC claims to support.

### Repository architecture

A thing worth noting about the architecture of OpenBMC repository structure is
that all meta-layers are stored directly inside the OpenBMC repository, rather
than being configured as submodules. This is quite uncommon for a Yocto-based
project.

---

## Building OpenBMC for X11SSH

Let's go through what it took to build OpenBMC for the Supermicro X11SSH
platform.

### Building (or not) the X11SPI configuration

When starting to work on a project rather than start modifying things blindly,
it's a good practice to build and briefly test the base configuration. As a
reminder, the configuration for X11SPI (we target X11SSH) is available in the
upstream OpenBMC repo, and assuming it was the closest to my target I decided
to build it first. How that went? If you read the previous section, you should
already know the answer to that, but let's go through it in detail.

I decided to attempt to build the image from the master branch as the last
release was seriously long ago. I was aware I shouldn't trust master branches
to be bug-free, yet it seemed like the reasonable thing to do, especially if I
would have needed help from the developers.

First I attempted to build the image locally. I installed the necessary packages
and started the build. The issue was that my development machine with i7-1260P
and 16GB of RAM was running out of RAM and the process was either getting
killed or the machine simply froze, even if no other applications were running
at the moment.

Then I changed the approach to create a build environment in the form of a
docker container and attempt to build OpenBMC on much "beefier" machine that we
refer to as "The Builder". After setting up environment properly, and many many
minutes of wait time, I was finally able to build the X11SPI configuration.
...well, not really.

Remember what I said, what can happen when the configuration is not regularly
tested? The build was failing on one of the last steps: the packaging. The issue
was that the resulting `squashfs` image was too big to fit within available
flash memory. I didn't want to spend time debugging what should have been a
working configuration and since now I had a brief idea of the build system, I
switched to making X11SSH configuration.

### Baking the X11SSH configuration

To build the OpenBMC for the certain platform we need to create a configuration,
or a layer to be exact, for it. I've got to say, I had it much easier if I were
to create a layer for a totally unsupported configuration. I had the X11SPI I
could reference and out-of-date configuration from when we (I wasn't part of the
team yet) attempted to build
[OpenBMC for the X11SSH in the past](https://3mdeb.com/events/#_yocto-project-dev-days).
After a longer while of resolving: not applying patches, deprecated variables,
names, or syntax... I ended up at the same point as for the X11SPI layer, which I
consider
[an absolute win](https://i.kym-cdn.com/photos/images/newsfeed/001/490/511/148.jpg).

### Too many features

To make the image fit within available flash memory and make the image build
successfully I needed to remove a bunch of functionality that OpenBMC offers. I
created a simple `.bbappend` file to remove a bunch of features, the content of
the file was as follows.

```text
# Remove some features so image fits in available flash size
IMAGE_FEATURES:remove = "obmc-telemetry"
IMAGE_FEATURES:remove = "obmc-devtools"
IMAGE_FEATURES:remove = "obmc-debug-collector"
IMAGE_FEATURES:remove = "obmc-user-mgmt-ldap"
IMAGE_FEATURES:remove = "obmc-user-mgmt"
BMC_IMAGE_BASE_INSTALL:remove = "packagegroup-obmc-apps-extras"
```

With features removed, I managed to successfully build the image.

---

## Running the image

Rather than flashing the image to the board and crossing fingers, it
is a much better approach to run as a VM. The X11SSH platform has BMC based on
Aspeed AST2400 SoC, which can be
[emulated under QEMU](https://www.qemu.org/docs/master/system/arm/aspeed.html).
This could be done with one simple command.

```bash
qemu-system-arm -machine supermicrox11-bmc \
  -drive file="$IMAGE_PATH",format=raw,if=mtd \
  -m 256 \
  -nographic \
  -net nic \
  -net user,hostfwd=:127.0.0.1:2222-:22,hostfwd=:127.0.0.1:2443-:443,hostfwd=udp:127.0.0.1:2623-:623,hostname=qemu
```

...which unfortunately proved there are issues with the image.

---

## Running ain't working

While the image technically runs under QEMU, I wouldn't exactly call it a
successful deployment.

```text
Welcome to Phosphor OpenBMC (Phosphor OpenBMC Project Reference Distro) 2.18.0-dev!

[    4.023644] systemd[1]: Hostname set to <x11ssh>.
[    4.281004] systemd[1]: Using hardware watchdog 'aspeed_wdt', version 0, device /dev/watchdog0
[    4.282264] systemd[1]: Watchdog running with a hardware timeout of 2min.
[    4.283095] systemd[1]: Watchdog: reading from /sys/dev/char/249:0/pretimeout_governor
[    4.284304] systemd[1]: Watchdog: failed to read pretimeout governor: No such file or directory
[    4.284882] systemd[1]: Watchdog: setting pretimeout_governor to 'panic' via '/sys/dev/char/249:0/pretimeout_governor'
[    4.285767] systemd[1]: Failed to set watchdog pretimeout_governor to 'panic': No such file or directory
[    4.286178] systemd[1]: Failed to set watchdog pretimeout governor to 'panic', ignoring: No such file or directory
[    5.525139] systemd[1]: /usr/lib/systemd/system/bmcweb.service:13: Failed to parse WatchdogSec=s, ignoring: Invalid argument
[    5.805716] systemd[1]: Failed to put bus name to hashmap: File exists
[    5.806428] systemd[1]: xyz.openbmc_project.State.Host@0.service: Two services allocated for the same bus name xyz.openbmc_project.State.Host0, refusing operation.
[    7.253479] systemd[1]: /usr/lib/systemd/system/phosphor-ipmi-net@.socket:6: Invalid interface name, ignoring: sys-subsystem-net-devices-%i.device
[    7.379465] systemd[1]: Failed to isolate default target: Unit xyz.openbmc_project.State.Host@0.service failed to load properly, please adjust/correct and reload service manager: File exists
[!!!!!!] Failed to isolate default target.
[    7.507281] systemd[1]: Freezing execution.
```

Two issues needed to be resolved, or at that time I thought so.

### bmcweb.service issue

The first issue that seemed major, but now I know it probably wasn't, was the
issue with `bmcweb.service`.

```text
[    5.525139] systemd[1]: /usr/lib/systemd/system/bmcweb.service:13: Failed to parse WatchdogSec=s, ignoring: Invalid argument
```

The issue here was that the value for `WatchdogSec` argument was omitted for
some reason. I eventually found out what
[the issue](https://github.com/openbmc/bmcweb/issues/306) was. The variable in
`bmcweb.service.in` for the `WatchdogSec` parameter was named `WATCHDOG_TIMEOUT`
while the rest of the code set up `WATCHDOG_TIMEOUT_SECONDS`.

```text
[...]
WatchdogSec=@WATCHDOG_TIMEOUT@s
[...]
```

A classic mistake, that can make one cry when figured out. To my knowledge this
bug was present upstream for at least 3 weeks, I can't wrap my head around it
that it has not been discovered earlier.

A small anecdote, I initially read:

> bmcweb.service:13: Failed to parse WatchdogSec=s, ignoring: Invalid argument

...as if the service failed to start (was ignored), when in reality the systemd
simply failed to parse the parameter and ignored the parameter itself. The
lesson? Read error messages carefully, although I'm sure it ain't the last time
I trick myself with something similar. In my defense, I could not see if the
service was running due to the execution being frozen.

### System managers issue

The second issue, was much more serious but a search through the past OpenBMC
issues helped to have it eliminated. The prepared X11SSH configuration inherited
a setup in which both `phosphor-state-manager` and `x86-power-control`, despite
being
[mutually exclusive](https://github.com/openbmc/phosphor-state-manager/issues/20)
were being installed on the same system.

```text
[    5.801024] systemd[1]: xyz.openbmc_project.State.Host@0.service: Two services allocated for the same bus name xyz.openbmc_project.State.Host0, refusing operation.
[    7.248189] systemd[1]: /usr/lib/systemd/system/phosphor-ipmi-net@.socket:6: Invalid interface name, ignoring: sys-subsystem-net-devices-%i.device
[    7.372546] systemd[1]: Failed to isolate default target: Unit xyz.openbmc_project.State.Host@0.service failed to load properly, please adjust/correct and reload service manager: File exists
[!!!!!!] Failed to isolate default target.
[    7.506780] systemd[1]: Freezing execution.
```

Both of the services serve similar purposes and implement interfaces like
switching the system on and off.

A simple `.bbappend` file:

```text
# Remove x86-power-controll
# https://github.com/openbmc/phosphor-state-manager/issues/20
RDEPENDS:${PN}-chassis:remove = "x86-power-control"
```

...resolved the issue.

### It's alive

When the change from the last paragraph was applied the system successfully
booted.

```text
[  OK  ] Finished Phosphor Sysfs - Add LED.
[  OK  ] Finished Phosphor Sysfs - Add LED.
[  OK  ] Finished Wait for /xyz/openbmc_project/control/host0/auto_reboot.
[  OK  ] Started Hostname Service.
[  OK  ] Finished Wait for /xyz/openbmc_project/control/host0/boot/one_time.
[  OK  ] Finished Wait for /xyz/openbmc_project/control/host0/boot.
[  OK  ] Finished Wait for /xyz/openbmc_pro…control/host0/power_restore_policy.
[  OK  ] Finished Wait for /xyz/openbmc_project/control/host0/restriction_mode.
[  OK  ] Finished Wait for /xyz/openbmc_project/state/chassis0.
[  OK  ] Finished Wait for /xyz/openbmc_project/time/sync_method.
[  OK  ] Started Entity Manager.

Phosphor OpenBMC (Phosphor OpenBMC Project Reference Distro) nodistro.0 x11ssh ttyS4

x11ssh login:
```

The system booted without any noticeable issues under QEMU, but we have yet to
test its functionality. There are other, more important things to do like...

---

## Running the image on HW

I think we can agree that seeing the fruit of your labor running on real
hardware is a nice feeling. So since we've got a supposedly working replacement
image for the BMC, let's try flashing it.

### The flash storage

The BMC firmware is stored on Macronix MX25L25635F 32MB flash storage in SOP 16L
format. Its safe voltage range is from 2.7V to 3.6V for all operations. The
photo of the actual chip is shown below.

![Macronix MX25L25635F](/img/x11ssh_macronix.jpg)

Here is the chip location on the board.

![X11SSH partial board view](/img/x11ssh_memory_location.jpg)

The chip marked as "Winbond" is a flash storage for UEFI/BIOS.

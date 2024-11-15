---
title: 'Increasing the security of iMX platforms - JTAG fusing'
abstract: 'JTAG helps a lot of engineers during product development. It also may
          be helpful for adversaries. We tell you why and how to increase JTAG
          security in your product'
cover: /img/secure_jtag_cover.png
author: michal.kotyla
layout: post
published: true
date: 2021-12-14
archives: "2021"

tags:
  - toolchain
  - nxp
  - i.mx6
categories:
  - Security
  - Manufacturing

---

## Introduction

JTAG port is an important feature that helps a lot of engineers during product
development. It also may be helpful for adversaries while performing a
reverse-engineering process - e.g. is a chance to dump the memory of your
firmware and get access to strictly confidential information. In this article,
we show how to lock JTAG access for users who don't have a special key. We will
use Secure JTAG feature which is implemented on i.MX SoC's. In our lab, we
tested Secure JTAG settings on i.MX6 but this same feature is available on a lot
more NXP platforms. Unfortunately, some part of NXP documentation is not
publicly available.

## Requirements

- **Development board**: Any i.MX6 devkit with available JTAG port. It can be
  [Sabre lite i.MX6](https://eu.mouser.com/ProductDetail/Boundary-Devices/BD-SL-iMX6?qs=rR5xxs6mnkwfzDTJZE5SUg%3D%3D)
  from Boundary Devices (218,66 EUR).

- **SoC reference manual**: Setting JTAG in secure mode is a dangerous operation
  \- if you miss something or will be wrong with any fusebit name or the address
  you can enable unexcepted options. Always work with documentation - here is
  [application note](http://web.archive.org/web/20210305000904/https://www.nxp.com/docs/en/application-note/AN4686.pdf)
  about JTAG modes.

- **crucible tool**: JTAG mode and access key are saved in fuse bits - we need
  software to manipulate fuses in userspace.
  [crucible](https://github.com/f-secure-foundry/crucible/) tool can be used for
  that - it is the best of free and open-source tools with a huge database of
  fuse fields. With that tool we can burn fuses using their names - it is more
  safety than counting banks and words.

- **JTAG compatible with OpenOCD**: On
  [NXP sites](http://web.archive.org/web/20210305000904/https://www.nxp.com/docs/en/application-note/AN4686.pdf) we can
  read that Secure JTAG is supported only by the Lauterbach environment and
  ARM-DS5 IDE with DSTREAM debugger. In 3mdeb we are always trying to use
  open-source software. Unfortunately, OpenOCD doesn't officially support Secure
  JTAG in i.MX SoC's, but we found not accepted yet
  [patch](https://review.openocd.org/c/openocd/+/2148/) from 2014 which adds
  support for work with SJC (System JTAG controller) in a secure mode. Required
  patch work on OpenOCD from
  [official repository](git://git.code.sf.net/p/openocd/code) if you checkout
  code with `970a12aef` hash. There is a chance to apply patch in the actual
  version of OpenOCD, but it needs some code changes. As hardware, we used
  [ARM-USB-OCD-H](https://www.olimex.com/Products/ARM/JTAG/ARM-USB-OCD-H/)
  (54,95 EUR) from Olimex.

The simplest way to use OpenOCD with SJC patch is to use our fork. You only need
clone our repository, build and install OpenOCD:

```bash
git clone https://github.com/3mdeb/openocd.git
cd openocd
./bootstrap
./configure
make -j$(nproc)
sudo make install
```

- **System image**: Any Linux image for your i.MX6 platform with kernel module
  `nvmem-imx-ocotp` for modifying OTP memory. You can add this module in
  menuconfig by enabling the option `CONFIG_NVMEM`. NVMEM driver can be built as
  a module and loaded only when you want to burn fuses.

## How it works

SoC's from i.MX family offers JTAG in three modes

- **No debug** - security on the highest level, but after disabling debug
  possibilities development and debugging via JTAG port will be unavailable
  permanently on used device

- **Secure JTAG** - mode described in this article, the best compromise between
  security and development possibilities - only person with an access key can
  use JTAG

- **Enabled JTAG** - default mode, enabled for anyone who has physical access to
  JTAG pins

Secure JTAG mode is based on a challenge/response mechanism. SoC has a unique
challenge key saved during manufacturing. User can generate their response
56-bit key and burn it in JTAG fuse named `SJC_RESP`. While trying to access the
JTAG port, SJC gives a unique for any device challenge key. Now user should pass
the response key which is compared with the response stored in SoC fuse bits. If
keys are the same, JTAG is enabled. Below, you can see a diagram describing the
challenge/response mechanism.

![Secure JTAG - how it works](/img/secure_jtag.png)

JTAG mode can be set in `JTAG_SMODE` fuse by values

| Mode | JTAG_SMODE | |-------------|------------| | JTAG enable | 0x0 | | JTAG
secure | 0x1 | | No debug | 0x2 |

These fuses still can be overwritten until we do not block this possibility -
the response key can be locked by writing `0x1` to `SJC_RESP_LOCK`, and JTAG
mode with all other fuses from `BOOT` group by writing `0x3` to `BOOT_CFG_LOCK`.
Now JTAG fuses should be protected from writing and overriding. There is an
option to set this to locking only override - look at the reference manual or
[application note](https://usermanual.wiki/m/bb676916d740bdd5d4e8ba43c1ba41673c242f2cefc59f03e014ea7314314f62.pdf)
for more information about fuse overriding feature.

## Setting up

### Using crucible

Get the latest prebuild release from
[official project page](https://github.com/f-secure-foundry/crucible/releases/download/v2021.12.17/crucible)
(on the day of writing our article it is `v2021.12.17`). You can also download
source code and build it by yourself - this process is described in
[readme](https://github.com/f-secure-foundry/crucible#installing). `Crucible`
program doesn't require any specific installation procedure - just remember to
give access to execute binary file.

Run `crucible` on your target and check that you have access to fuse bits from
userspace

```bash
# ./crucible -m IMX6UL -r 1 -b 16 read JTAG_SMODE
soc:IMX6UL ref:1 otp:JTAG_SMODE op:read addr:0x18 off:22 len:2 val:0x0
```

We can see that JTAG is set in default mode - JTAG enabled for everyone. Now
let's try to set secure mode. We generate a random response key:
`0x00574c200308fad77` and save it into `SJC_RESP`

```bash
# ./crucible -m IMX6UL -r 1 -b 16 -e big blow SJC_RESP 0x00574c200308fad77

�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█

                                **  WARNING  **

Fusing SoC OTPs is an **irreversible** action that permanently fuses values on
the device. This means that any errors in the process, or lost fused data such
as cryptographic key material, might result in a **bricked** device.

The use of this tool is therefore **at your own risk**.

�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█

soc:IMX6UL ref:1 otp:SJC_RESP op:blow reg:SJC_RESP base:16 val:00574c20308fad77 big-endian

Would you really like to blow this fuse? Type YES all uppercase to confirm:
YES
soc:IMX6UL ref:1 otp:SJC_RESP op:blow
addr:0x80 off:0 len:56 val:0x00574c20308fad77 res:0x77a0
```

Now we can change the mode to secure JTAG

```bash
# ./crucible -m IMX6UL -r 1 -b 16 -e big blow JTAG_SMODE 0x1

�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█

                                **  WARNING  **

Fusing SoC OTPs is an **irreversible** action that permanently fuses values on
the device. This means that any errors in the process, or lost fused data such
as cryptographic key material, might result in a **bricked** device.

The use of this tool is therefore **at your own risk**.

�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█

soc:IMX6UL ref:1 otp:JTAG_SMODE op:blow reg:JTAG_SMODE base:16 val:1 big-endian

Would you really like to blow this fuse? Type YES all uppercase to confirm:
YES
soc:IMX6UL ref:1 otp:JTAG_SMODE op:blow
addr:0x18 off:22 len:2 val:0x1 res:0x00004000
```

OpenOCD with i.MX secure SJC patch use `imx6_sjcauth.txt` file to store access
keys. We can get the challenge key during the first try of connection. Let's try

```bash
$ sudo openocd -f interface/ftdi/olimex-arm-usb-ocd-h.cfg -f target/imx6.cfg
Open On-Chip Debugger 0.9.0-dev-00019-g970a12aef-dirty (2021-10-11-14:19)
Licensed under GNU GPL v2
For bug reports, read
    http://openocd.sourceforge.net/doc/doxygen/bugs.html
Info : only one transport option; autoselect 'jtag'
Warn : imx6.sdma: nonstandard IR value
adapter speed: 10 kHz
Info : clock speed 10 kHz
SJC  : Using database tcl/target/imx6_sjcauth.txt
SJC  : Challenge 0x0e81d4eacb3785
SJC  : Response  0x574c20308fad77
SJC  : Using database tcl/target/imx6_sjcauth.txt
SJC  : Challenge 0x0e81d4eacb3785
SJC  : Response  0x574c20308fad77
SJC  : Using database tcl/target/imx6_sjcauth.txt
SJC  : Challenge 0x0e81d4eacb3785
SJC  : Response  0x574c20308fad77
Info : JTAG tap: imx6.dap tap/device found: 0x4ba00477 (mfg: 0x23b, part: 0xba00
, ver: 0x4)
Info : TAP imx6.sdma does not have IDCODE
Info : JTAG tap: imx6.sjc tap/device found: 0x1891a01d (mfg: 0x00e, part: 0x891a
, ver: 0x1)
Info : imx6.cpu.0: hardware has 6 breakpoints, 4 watchpoints
Info : number of cache level 1
Info : imx6.cpu.0 cluster 0 core 0 multi core
```

Works fine, now a response key is required to access JTAG. It looks like we can
lock JTAG related fuses: mode and key. They should be unavailable to override
now.

```bash
# ./crucible -m IMX6UL -r 1 -b 16 -e big blow JTAG_SMODE 0x3
# ./crucible -m IMX6UL -r 1 -b 16 -e big blow BOOT_CFG_LOCK 0x3
```

It is time to verify our solution - remove line with key from `imx6_sjcauth.txt`
and try to connect again:

```bash
$ sudo openocd -f interface/ftdi/olimex-arm-usb-ocd-h.cfg -f target/imx6.cfg
Open On-Chip Debugger 0.9.0-dev-00019-g970a12aef-dirty (2021-10-11-14:19)
Licensed under GNU GPL v2
For bug reports, read
  http://openocd.sourceforge.net/doc/doxygen/bugs.html
Info : only one transport option; autoselect 'jtag'
Warn : imx6.sdma: nonstandard IR value
adapter speed: 10 kHz
Info : clock speed 10 kHz
SJC  : Using database tcl/target/imx6_sjcauth.txt
SJC  : Challenge 0x0e81d4eacb3785
SJC  : Device not in database, not authenticating
SJC  : Using database tcl/target/imx6_sjcauth.txt
SJC  : Challenge 0x0e81d4eacb3785
SJC  : Device not in database, not authenticating
SJC  : Using database tcl/target/imx6_sjcauth.txt
SJC  : Challenge 0x0e81d4eacb3785
SJC  : Device not in database, not authenticating
Error: JTAG scan chain interrogation failed: all ones
Error: Check JTAG interface, timings, target power, etc.
Error: Trying to use configured scan chain anyway...
Error: imx6.dap: IR capture error; saw 0x0f not 0x01
SJC  : Using database tcl/target/imx6_sjcauth.txt
SJC  : Challenge 0x0e81d4eacb3785
SJC  : Device not in database, not authenticating
Warn : Bypassing JTAG setup events due to errors
Warn : Invalid ACK 0x7 in JTAG-DP transaction
```

JTAG access is disabled now if you do not have a file with the correct response
key. In OpenOCD output, we can see that debugger sees the challenge key but
cannot authenticate and connect to the SoC.

### Using U-boot

There is a possibility to fuse JTAG from U-boot shell - for that `fuse prog`
command can be used. You will need to build bootloader with enabled
`CONFIG_CMD_FUSE` config. More description of fuse functionality is
[here](https://source.denx.de/u-boot/u-boot/-/blob/master/doc/README.fuse). It
is a more common solution, but you need to use banks and words numbers instead
of fields names. If you enter incorrect numbers you may brick device, so we
recommend using `crucible`.

## Summary

Secure JTAG mode is a very useful feature, which should be implemented in every
device where security is important. JTAG can be an open door for whole system
architecture: while debugging device adversary can dump memory of program which
can be critical for your system infrastructure. If you do not pay attention to
encryption and other safeguards someone can read important and confidential data
like passwords and addresses.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to
[sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

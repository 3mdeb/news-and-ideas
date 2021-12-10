---
title: 'Increasing the security of iMX platforms - JTAG fusing'
abstract: 'JTAG helps a lot of engineers during product development.
          It also may be helpful for hackers.
          I tell you why and how to increase JTAG security in your product'
cover: /covers/secure-jtag.png
author: michal.kotyla
layout: post
published: true
date: 2021-10-28
archives: "2021"

tags:
  - security
  - jtag
  - fuse
  - bit
  - fusebit
  - fusebits
  - fusing
  - fuses
  - nxp
  - imx
  - i.mx
  - imx6
  - i.mx6
categories:
  - Firmware
  - Miscellaneous
  - OS Dev
  - Security
  - Manufacturing

---
## Introduction

JTAG port is an important feature that helps a lot of engineers during product
development. It also may be helpful for hackers while reverse-engineering
process - e.g. they can dump the memory of your firmware and get access to
strictly confidential information. In this article, I show you how to lock JTAG
access for users who don't have a special key (password). I use for that Secure
JTAG feature which is implemented on i.MX SoC's. In our lab, we tested this
solution on i.MX6. This same feature is available on a lot more NXP platforms
but they have missing public documentation.

## Requirements

- **Development board**: Any devkit with i.MX6,

- **SoC reference manual**: Setting JTAG in secure mode is a dangerous
operation - if you miss something or will be wrong with any fusebit name or
address you can enable unexcepted options. Here is an example: system is
prepared to boot from SD card but you were wrong while fusemap understanding and
now SoC always will be trying to boot from not existing eMMC memory. Read chip
documentation and check twice that everything is correct,

- **crucible tool**: JTAG mode and access key are saved in fuse bits - we need
software to manipulate this in userspace. I used
[crucible](https://github.com/f-secure-foundry/crucible/) for that, let's show
how to do it from U-Boot and crucible,

- **JTAG compatible with OpenOCD**: On NXP sites we can read that Secure JTAG is
supported only by the Lauterbach environment and ARM-DS5 IDE with DSTREAM
debugger. In 3mdeb we are always trying to use open-source software.
Unfortunately, OpenOCD doesn't officially support Secure JTAG in i.MX SoC's,
but I found not accepted yet patch from 2014 which add support for work with SJC
(System JTAG controller) in a secure mode. This patch work on OpenOCD from
[official repository](git://git.code.sf.net/p/openocd/code) if you checkout this
with `970a12aef` hash. Is a chance to apply this in the actual version of
OpenOCD, but it needs some code changes. As a hardware, i used `ARM-USB-OCD-H`
from Olimex,

- **System image**: Any Linux image for your target with kernel module
`nvmem-imx-ocotp` for modify OTP memory.

## How it works

SoC's from i.MX family offers JTAG in three modes:

- **No debug** - security on the highest level, but after setting that
development and debugging by JTAG port will be unavailable permanently on this
device,

- **Secure JTAG** - mode described in this article, the best compromise between
security and development possibilities - only person with access key can use
JTAG,

- **Enabled JTAG** - default mode, enabled for anyone who has physical access to
JTAG pins or even only device (is a chance to connect to the JTAG pins if the
connector isn't soldered).

Secure JTAG mode based on challenge/response mechanism. SoC has saved during
manufacturing a unique challenge key. User can generate their response 56-bit
key and burn it in JTAG fuse `SJC_RESP`. While trying to access the JTAG port,
SJC gives a challenge key. We can simplify this to the JTAG controller ID. Now
user should pass the response key. It is compared with the response stored in
SoC fuse bits. If keys are the same, JTAG is enabled. Bellow, you can see
schemat described this mechanism:

![Secure JTAG - how it works](/img/secure_jtag.png)

JTAG mode can be set in `JTAG_SMODE` fuse by values:

| Mode        | JTAG_SMODE |
|-------------|------------|
| JTAG enable | 0x0        |
| JTAG secure | 0x1        |
| No debug    | 0x2        |

These fuses still can be overwritten until we do not block this possibility -
the response key can be locked by writing `0x1` to `SJC_RESP_LOCK`, and JTAG
mode with all other fuses from `BOOT` group by writing `0x3` to `BOOT_CFG_LOCK`
now they should be protected from writing and overwriting. There is an option to
set this to locking only override - look at the reference manual for more
information (or
[application note](https://usermanual.wiki/m/bb676916d740bdd5d4e8ba43c1ba41673c242f2cefc59f03e014ea7314314f62.pdf)
about this feature)

## Setting up

### Using cruible

Run `cruible` on your target and check that you have access to fuse bits from
userspace:
```
user@machine:~# ./crucible -m IMX6UL -r 1 -b 16 read JTAG_SMODE 
soc:IMX6UL ref:1 otp:JTAG_SMODE op:read addr:0x18 off:22 len:2 val:0x0
```

If you try to burn fuses on i.MX8MM there can be problems with available of
these fields in `crucible` (latest release v20121.05.03) fuse map. This was
added [here](https://github.com/f-secure-foundry/crucible/issues/6) but it is
not released as a pre-compiled binary. You need to build it by yourself.

We can see JTAG mode is set in default mode - JTAG enabled for everyone. Now try
to set secure mode. I generate my random response key and save it into
`SJC_RESP`:
```
user@machine:~# ./crucible -m IMX6UL -r 1 -b 16 -e big blow SJC_RESP 0x00574c200308fad77

�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�                              █

                                **  WARNING  **

Fusing SoC OTPs is an **irreversible** action that permanently fuses values on
the device. This means that any errors in the process, or lost fused data such
as cryptographic key material, might result in a **bricked** device.

The use of this tool is therefore **at your own risk**.

�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�                              █

soc:IMX6UL ref:1 otp:SJC_RESP op:blow reg:SJC_RESP base:16 val:00574c20308fad77 big-endian

Would you really like to blow this fuse? Type YES all uppercase to confirm: 
YES
soc:IMX6UL ref:1 otp:SJC_RESP op:blow addr:0x80 off:0 len:56 val:0x00574c20308fad77 res:0x77a0

```

Now I can change the mode to secure JTAG:

```
root@machine:~# ./crucible -m IMX6UL -r 1 -b 16 -e big blow JTAG_SMODE 0x1

�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�                              █

                                **  WARNING  **

Fusing SoC OTPs is an **irreversible** action that permanently fuses values on
the device. This means that any errors in the process, or lost fused data such
as cryptographic key material, might result in a **bricked** device.

The use of this tool is therefore **at your own risk**.

�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�█�                              █

soc:IMX6UL ref:1 otp:JTAG_SMODE op:blow reg:JTAG_SMODE base:16 val:1 big-endian

Would you really like to blow this fuse? Type YES all uppercase to confirm: 
YES
soc:IMX6UL ref:1 otp:JTAG_SMODE op:blow addr:0x18 off:22 len:2 val:0x1 res:0x00004000


```
OpenOCD with i.MX secure SJC patch use `imx6_sjcauth.txt` file to store access
keys. Challenge key we can get during the first try of connection. Let's try:

```
user@machine:~/openocd-code/tcl$ sudo openocd -f interface/ftdi/olimex-arm-usb-ocd-h.cfg -f target/imx6.cfg
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

Works fine, now a response key is required to access JTAG. Remember to lock mode
and key overriding by burning relevant fuses.

Different case, different device - suppose that I finish development and this
product never be debugged. Now I permanently disable this possibility:

```
# ./crucible -m IMX6UL -r1 -b 16 -e big blow JTAG_SMODE 0x3
```

```
# ./crucible -m IMX6UL -r 1 -b 16 -e big blow BOOT_CFG_LOCK 0x3
```

When I try to get access by JTAG port I can see that i.MX doesn't allow for
that:

```
user@machine:~$ sudo openocd -f interface/ftdi/olimex-arm-usb-ocd-h.cfg -f target/imx6.cfg
Open On-Chip Debugger 0.11.0
Licensed under GNU GPL v2
For bug reports, read
    http://openocd.org/doc/doxygen/bugs.html
Info : auto-selecting first available session transport "jtag". To override use 'transport select <transport>'.
Warn : imx6.sdma: nonstandard IR value
Info : Listening on port 6666 for tcl connections
Info : Listening on port 4444 for telnet connections
Info : clock speed 10 kHz
Error: JTAG scan chain interrogation failed: all zeroes
Error: Check JTAG interface, timings, target power, etc.
Error: Trying to use configured scan chain anyway...
Error: imx6.cpu: IR capture error; saw 0x00 not 0x01
Warn : Bypassing JTAG setup events due to errors
Error: Invalid ACK (0) in DAP response
```

### Using U-boot

Is a possibility to fuse it from U-boot shell - for that is prepared `fuse prog`
command. You need to build bootloader with enabled `CONFIG_CMD_FUSE` config.
More description of this functionality is
[here](https://source.denx.de/u-boot/u-boot/-/blob/master/doc/README.fuse)
It is a more common solution, but you need to use banks and words numbers
instead of fields names. If you enter incorrect numbers you may brick device, so
we recommend using `crucible`.

## Summary

Secure JTAG mode is a very useful feature, which should be implemented in every
device where security is important. JTAG can be an open door whole system
architecture: while debugging device hacker can dump memory of program
which can be critical for your system infrastructure. If you do not pay
attention to encryption and other safeguards someone can read important and not
confidential data like passwords and addresses.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to
[sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

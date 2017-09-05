---
ID: 63554
post_title: >
  OpenOCD and development environment for
  Zephyr on NXP FRDM-K64F
author: Karol Rycio
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/openocd-and-development-environment-for-zephyr-on-nxp-frdm-k64f/
published: true
post_date: 2017-03-18 15:27:23
tags:
  - embedded
  - Zephyr
  - Openocd
  - NXP
  - FRDM-K64F
  - Segger
  - NXP/Freescale
categories:
  - Firmware
  - IoT
---
In this post I would like to describe process of setting up NXP FRDM-K64F
development environment under Linux and start Zephyr development using it.

Why NXP FRDM-K64F ? I choose this platform mostly because of ready to use guide
about using 802.15.4 communication by attaching TI CC2520, which was presented
[here](https://wiki.zephyrproject.org/view/TI_CC2520#Use_case:_CC2520_on_NXP_FRDM-K64F).

Typical wireless stack starts with 802.15.4, then 6LoWPAN adaptation and then
IPv6, which carries application protocols. 6LoWPAN compress IPv6 so it can fit
BLE and 802.15.4 and it is dedicated for embedded systems with very limited
stack. Using IPv6 is very important for IoT market because scalability,
security and simplified application implementation in comparison to custom
stack also it can provide known protocols like UDP on transport layer.

I tried to evaluate Zephyr networking stack for further use in customer applications.
But having even greatest idea for project requires development environment and
ability to debug your target platform that's why I wrote this tutorial.

## NXP FRDM-K64F setup

![frdm-k64f](http://3mdeb.com/wp-content/uploads/2017/07/frdm-k64f.jpg)

I started with initial triage if my NXP FRDM-K64F board works:

```
git clone https://gerrit.zephyrproject.org/r/zephyr &amp;&amp; cd zephyr &amp;&amp; git checkout tags/v1.7.0
cd zephyr
git checkout net
source zephyr-env.sh
cd $ZEPHYR_BASE/samples/hello_world/
make BOARD=frdm_k64f
cp outdir/frdm_k64f/zephyr.bin /media/pietrushnic/MBED/
```

On `/dev/ttyACM0` I get:

```
**** BOOTING ZEPHYR OS v1.7.99 - BUILD: Mar 18 2017 14:14:37 *****                                                                    |
Hello World! arm   
```

So it works great out of the box. Unfortunately  it is not possible to flash
using typical Zephyr OS command:

```
[15:16:13] pietrushnic:hello_world git:(k64f-ethernet) $ make BOARD=frdm_k64f flash
make[1]: Entering directory &#039;/home/pietrushnic/storage/wdc/projects/2017/acme/src/zephyr&#039;
make[2]: Entering directory &#039;/home/pietrushnic/storage/wdc/projects/2017/acme/src/zephyr/samples/hello_world/outdir/frdm_k64f&#039;
  Using /home/pietrushnic/storage/wdc/projects/2017/acme/src/zephyr as source for kernel
  GEN     ./Makefile
  CHK     include/generated/version.h
  CHK     misc/generated/configs.c
  CHK     include/generated/generated_dts_board.h
  CHK     include/generated/offsets.h
make[3]: &#039;isr_tables.o&#039; is up to date.
Flashing frdm_k64f
Flashing Target Device
Open On-Chip Debugger 0.9.0-dirty (2016-08-02-16:04)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Info : only one transport option; autoselect &#039;swd&#039;
Info : add flash_bank kinetis k60.flash
adapter speed: 1000 kHz
none separate
cortex_m reset_config sysresetreq
Error: unable to find CMSIS-DAP device

Done flashing
```

NXP FRDM-K64F have problems with debugger firmware and that's why OpenOCD
refuse to cooperate. Recent CMSIS-DAP firmware can be installed by using [this guide](https://developer.mbed.org/handbook/Firmware-FRDM-K64F)
although it has speed and debugging limitation about which you can read [here](https://mcuoneclipse.com/2014/04/27/segger-j-link-firmware-for-opensdav2/).

I followed [this post](http://jany.st/tag/frdm-k64f.html) to build recent
version of OpenOCD from source.

Custom OpenOCD can be provided to Zephyr `make` system, by using `OPENOCD`
variable, so:

```
OPENOCD=/usr/local/bin/openocd make BOARD=frdm_k64f flash
OPENOCD=/usr/local/bin/openocd make BOARD=frdm_k64f debug
```

Both worked fine for me. I realized that I use `0.8.2` Zephyr SDK, so this
could be possible issue, but it happen not. Neither OpenOCD provided in `0.8.2`
nor `0.9` Zephyr SDK worked for me.


### Zephyr SDK upgrade

For those curious how to upgrade Zephyr SDK below commands should help.

To get location of SDK:

```
$ source zephyr-env.sh 
$ echo $ZEPHYR_SDK_INSTALL_DIR
/home/pietrushnic/projects/2016/acme/zephyr_support/src/sdk
```

To upgrade:

```
$ wget https://nexus.zephyrproject.org/content/repositories/releases/org/zephyrproject/zephyr-sdk/0.9/zephyr-sdk-0.9-setup.run
$ chmod +x zephyr-sdk-0.9-setup.run 
$ ./zephyr-sdk-0.9-setup.run 
Verifying archive integrity... All good.
Uncompressing SDK for Zephyr  100% 
Enter target directory for SDK (default: /opt/zephyr-sdk/): /home/pietrushnic/projects/2016/acme/zephyr_support/src/sdk
Installing SDK to /home/pietrushnic/projects/2016/acme/zephyr_support/src/sdk
The directory /home/pietrushnic/projects/2016/acme/zephyr_support/src/sdk/sysroots will be removed!
Do you want to continue (y/n)?
y
 [*] Installing x86 tools...
 [*] Installing arm tools...
 [*] Installing arc tools...
 [*] Installing iamcu tools...
 [*] Installing nios2 tools...
 [*] Installing xtensa tools...
 [*] Installing riscv32 tools...
 [*] Installing additional host tools...
Success installing SDK. SDK is ready to be used.
```

## Flashing sample Zephyr application

Because SDK provided OpenOCD didn't worked for me I started to use one compiled
by myself.

`zperf` is network traffic generator included in sample applications of
Zephyr. It supports K64F, so it was great place to start with networking.

```
cd $ZEPHYR_BASE/samples/net/zperf
OPENOCD=/usr/local/bin/openocd make BOARD=frdm_k64f flash
```

On terminal I saw:

```
zperf&gt;
[zperf_init] Setting IP address 2001:db8::1
[zperf_init] Setting destination IP address 2001:db8::2
[zperf_init] Setting IP address 192.0.2.1
[zperf_init] Setting destination IP address 192.0.2.2
```

Testing scenarios are described [here](https://www.zephyrproject.org/doc/samples/net/zperf/README.html?highlight=zperf).
Unfortunately basic test hangs, what could be great to those who want to help
in Zephyr development. I tried to debug that problem.

## Debugging problems

To debug zpref application I used tui mode of gdb:

```
OPENOCD=/usr/local/bin/openocd TUI=&quot;--tui&quot; make BOARD=frdm_k64f debug
```

Please note that before debugging you have to flash application to your target.

Unfortunately debugging didn't worked for me out of the box. I struggle with
various problems trying different configuration. My main goal was to have pure
OpenOCD+GDB environment. It happen very problematic with breakpoints triggering
exception handlers and GDB initially stopping in weird location (ie. idle thread).

I [asked](https://lists.zephyrproject.org/pipermail/zephyr-devel/2017-March/007352.html)
on mailing list question about narrowing down this issue. Moving forward with
limited debugging functionality would be harder, but not impossible - `print is your friend`.

NXP employee replies on mailing list were far from being satisfying. Main
suggestion was to use KDS IDE.

## Digging in OpenOCD

In general there were two issues I faced:

```
Error: 123323 44739 target.c:2898 target_wait_state(): timed out (&gt;40000) while waiting for target halted
(...)
Error: 123917 44934 armv7m.c:723 armv7m_checksum_memory(): error executing cortex_m crc algorithm (retval=-302)
```

`timeout` value and `retval` value were added for debugging purposes. First
conclusion was that increasing timeout doesn't help and that crc failure could
be caused by problems with issuing halt, so it sound like both problems were
connected. On the other hand those error had no visible effect on flashed
application.

### DAPLink

Recently [DAPLink](https://github.com/mbedmicro/DAPLink) was introduced and on
mentioned previously mbed site it replaced previous CMSIS-DAP firmware, but
there is no clear information about support in OpenOCD except that `pyOCD`
should debug target with this firmware. Unfortunately DAPLink firmware provided
by NXP for FRDM-K64F didn't worked for me out of the box, what I tried to
resolve by asking question [here](https://community.nxp.com/thread/447692).

It looked like more people have problems with debugging. Proposed solutions are
KDS, using Segger and P&M firmware instead of CMSIS-DAP.

## Kinetis Design Studio

This was suggested as solution, by NXP and I get to point where I have to give
it a try. It is obvious that each vendor will force its solution.

I don't like idea of bloated Eclipse-based IDEs forced on us by big guys. It
looks like all of semiconductors go that way TI, STM, NXP - this is terrible for
industry. We loosing flexibility, features start to be hidden in hundreds of
menus and lot of Linux enthusiast have to deal memory consuming blobs. Not
mention Atmel, which is even worst going Visual Studio path and making whole
ecosystem terrible to work with.

Of course there is no way to validate such big ecosystem, so it have to be buggy.

I know they want to attract junior developers with "simple" and good looking
interface, but number of option hidden and quality of documentation lead
experts to rebel against this choice. Learning junior developers how custom,
vendor Eclipse works is useless for true skill set needed. It makes people
learn where options are in menu, but not how those options really work and what
is necessary to enable those. We wrapping everything to make its simple, but it
turns us into users that don't really know how system works and if anything
will happen different then usual we will have problems figuring out the way.

Portability of projects created in Eclipse-based IDEs is far from being useful.
Tracking configuration files to give working development environment to other
team members is also impossible. Finally each developer have different
configuration and if something doesn't work there is no easy way to figure out
what is going on. Support is slow and configuration completely not portable.

Best choice for me would be well working command line tool and build system.
All those components should be wrapped in portable containers. We were
successful in building such development environment for embedded Linux using
either Poky or Buildroot. Why not to go mbedCLI way ?

Luckily KDS is available in DEB package, but it couldn't be smaller then 691MB.
I have to allow this big bugged environment to hook into my system and I'm really
unhappy with that.

```
[1:31:54] pietrushnic:Downloads $ sudo dpkg -i  kinetis-design-studio_3.2.0-1_amd64.deb 
[sudo] password for pietrushnic:
Selecting previously unselected package kinetis-design-studio.
(Reading database ... 405039 files and directories currently installed.)
Preparing to unpack kinetis-design-studio_3.2.0-1_amd64.deb ...
Unpacking kinetis-design-studio (3.2.0) ...
Setting up kinetis-design-studio (3.2.0) ...

**********************************************************************
* Warning: This package includes the GCC ARM Embedded toolchain,     *
*          which is built for 32-bit hosts. If you are using a       *
*          64-bit system, you may need to install additional         *
*          packages before building software with these tools.       *
*                                                                    *
*          For more details see:                                     *
*          - KDS_Users_Guide.pdf:&quot;Installing Kinetis Design Studio&quot;. *
*          - The Kinetis Design Studio release notes.                *
**********************************************************************
Processing triggers for gnome-menus (3.13.3-9) ...
Processing triggers for desktop-file-utils (0.23-1) ...
Processing triggers for mime-support (3.60) ...
```

Then this:

![kds_error](http://3mdeb.com/wp-content/uploads/2017/07/kds_error.png)

It was very clear information. Maybe adding path log would be also useful ?
Finally problem was in lack of disk space.

### KDS OpenOCD

Interestingly OpenOCD in KDS behave little bit different then upstream. There
were still problems with halt and crc errors. Unfortunately flashing is
terribly slow (0.900 KiB/s). NXP seems to use old OpenOCD `Open On-Chip Debugger 0.8.0-dev (2015-01-09-16:23)` It doesn't seem that OpenOCD and
CMSIS-DAP can provide reasonable experience for embedded systems developer.

## What works ?

After all above tests it happen that the only solution that seem to work
without weird errors is Segger Jlink V2 firmware with Segger software provided
in KDS.

To configure working configuration you need correct firmware which can be
downloaded on [OpenSDA bootloader and application](http://www.nxp.com/products/software-and-tools/run-time-software/kinetis-software-and-tools/ides-for-kinetis-mcus/opensda-serial-and-debug-adapter:OPENSDA?tid=vanOpenSDA#FRDM-K64F)
website. After updating firmware you can follow with further steps.

### Flashing with Segger

To flash you can use `JLinkExe` inside Zephyr application:

```
/opt/Freescale/KDS_v3/segger/JLinkExe -if swd -device MK64FN1M0VLL12 -speed 1000 -CommanderScript ~/tmp/zephyr.jlink
```

Where `~/tmp/zephyr.jlink`
```
h
loadbin outdir/frdm_k64f/zephyr.bin 0x0
q
```

### Debugging with Segger

Then you can use `JLinkGDBServer` for debugging purposes:

```
/opt/Freescale/KDS_v3/segger/JLinkGDBServer -if swd -device MK64FN1M0VLL12 
-endian little -speed 1000 -port 2331 -swoport 2332 -telnetport 2333 -vd 
-ir -localhostonly 1 -singlerun -strict -timeout 0
```

Output should look like that:

```
SEGGER J-Link GDB Server V5.10n Command Line Version

JLinkARM.dll V5.10n (DLL compiled Feb 19 2016 18:45:10)

-----GDB Server start settings-----
GDBInit file:                  none
GDB Server Listening port:     2331
SWO raw output listening port: 2332
Terminal I/O port:             2333
Accept remote connection:      localhost only
Generate logfile:              off
Verify download:               on
Init regs on start:            on
Silent mode:                   off
Single run mode:               on
Target connection timeout:     0 ms
------J-Link related settings------
J-Link Host interface:         USB
J-Link script:                 none
J-Link settings file:          none
------Target related settings------
Target device:                 MK64FN1M0VLL12
Target interface:              SWD
Target interface speed:        1000kHz
Target endian:                 little

Connecting to J-Link...
J-Link is connected.
Firmware: J-Link OpenSDA 2 compiled Feb 28 2017 19:27:22
Hardware: V1.00
S/N: 621000000
Checking target voltage...
Target voltage: 3.30 V
Listening on TCP/IP port 2331
Connecting to target...Connected to target
Waiting for GDB connection...
```

To debug application you can use debugger provided wit Zephyr SDK that you used
to compile application.

```
cgdb -d $ZEPHYR_SDK_INSTALL_DIR/sysroots/x86_64-pokysdk-linux/usr/bin/arm-zephyr-eabi/arm-zephyr-eabi-gdb 
outdir/frdm_k64f/zephyr.elf
```

Then you have to connect to `JLinkGDBServer`:

```
target remote :2331
load
```

For `zperf` same application output should look like that:

```
GNU gdb (GDB) 7.11.0.20160511-git
Copyright (C) 2016 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later &lt;http://gnu.org/licenses/gpl.html&gt;
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type &quot;show copying&quot;
and &quot;show warranty&quot; for details.
This GDB was configured as &quot;--host=x86_64-pokysdk-linux --target=arm-zephyr-eabi&quot;.
Type &quot;show configuration&quot; for configuration details.
For bug reporting instructions, please see:
&lt;http://www.gnu.org/software/gdb/bugs/&gt;.
Find the GDB manual and other documentation resources online at:
&lt;http://www.gnu.org/software/gdb/documentation/&gt;.
For help, type &quot;help&quot;.
Type &quot;apropos word&quot; to search for commands related to &quot;word&quot;...
Reading symbols from outdir/frdm_k64f/zephyr.elf...done.
(gdb) target remote :2331
Remote debugging using :2331
__k_mem_pool_quad_block_size_define () at /home/pietrushnic/storage/wdc/projects/2017/acme/src/zephyr/include/kernel.h:3146
(gdb) load
Loading section text, size 0xaa7e lma 0x0
Loading section devconfig, size 0xe4 lma 0xaa80
Loading section net_l2, size 0x10 lma 0xab64
Loading section rodata, size 0xc40 lma 0xab74
Loading section datas, size 0xf68 lma 0xb7b4
Loading section initlevel, size 0xe4 lma 0xc71c
Loading section _k_sem_area, size 0x14 lma 0xc800
Loading section net_if, size 0x400 lma 0xc814
Loading section net_if_event, size 0x18 lma 0xcc14
Loading section net_l2_data, size 0x8 lma 0xcc2c
Start address 0x970c, load size 52274
Transfer rate: 25524 KB/sec, 2613 bytes/write.
(gdb) bt
#0  __start () at /home/pietrushnic/storage/wdc/projects/2017/acme/src/zephyr/arch/arm/core/cortex_m/reset.S:64
```

If you need to reset remote side use:

```
monitor reset
```

It happens that `load` piece was also missing part for `CMSIS-DAP`. This
command gives GDB access to program symbols when using remote debugging.

## Summary

In terms of speed there is no comparison between Segger and CMSIS-DAP. First
gave me speed of ~50MB/s second ~2MB/s. Unfortunately Segger have to be
externally installed with KDS or from binaries provided by Segger. Zephyr also
would require some modification to support that solution. CMSIS-DAP has a lot
of weird errors, which can confuse user. There is no information if those
errors affect firmware anyhow, but professional developers don't want to wonder
if their tools work correctly, because there is plenty of other tasks to worry
about. CMSIS-DAP is very slow OpenOCD from KDS version is 20x slower then
upstream OpenOCD, but advantage of this is that it works out of the box with
Zephyr what can be good for people starting.

If you struggle with development on FRDM-K64F or have some issues with Zephyr
we would be glad help. You can easily contact us via [socialmedia](https://twitter.com/3mdeb_com) or through email
`contact<at>3mdeb<dot>com`. Please share this post if you feel it has valuable information.
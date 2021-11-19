---
title: First impression on Nezha RISC-V SBC
abstract: "Nezha is a AIoT development board customized by AWOL based on
           Allwinner's D1 chip. It is the world's first mass-produced development
           board that supports 64bit RISC-V instruction set and Linux system."
cover: /img/nezha-logo.png
author: cezary.sobczak
layout: post
published: true
date: 2021-11-19
archives: "2021"

tags:
  - risc-v
  - sbc
  - linux
  - u-boot
  - boot0
  - opensbi
  - bootloader
  - logs
  - SoC
  - sdcard
categories:
  - Firmware
  - IoT
  - OS Dev

---

## Intro

Nezha board is a development board that is designed by an AWOL. This project
uses a D1 SoC from Allwinner which is used for the first time by the general
public. Probably this board is the **first massive** produced and available SBC
based at RISC-V architecture taking in mind a fact that [BeagleV™](https://blog.3mdeb.com/2021/2021-05-06-first-impressions-beaglev/)
was canceled in august this year after the pilot program with version beta of
the board. The Nezha board can be acquired at Aliexpress from
[PerfXLab Store](https://www.aliexpress.com/item/1005003565054561.html?spm=a2g0o.productlist.0.0.354924810Df6mL&algo_pvid=88942876-9d76-4423-a810-4a8cbc420498&algo_exp_id=88942876-9d76-4423-a810-4a8cbc420498-2&pdp_ext_f=%7B%22sku_id%22%3A%2212000026307794408%22%7D)
or from
[Sipeed Store](https://www.aliexpress.com/item/1005002856721588.html?spm=a2g0o.productlist.0.0.69c47eb8wYH0H8&algo_pvid=7832a07e-6881-446d-a910-20ed9546c700&algo_exp_id=7832a07e-6881-446d-a910-20ed9546c700-0&pdp_ext_f=%7B%22sku_id%22%3A%2212000022485490245%22%7D).

This article is such an opening to the series of posts about Neza D1 where
the basic facts, specification and firmware stack of this SBC are described and
present.

## Background

The name of this board is taken from a fictional character from Chinese literature.
"Nezha" also means "The third prince" and he is a God which was fighting with
dragons and snakes. His sign can be found on the board:

![nezha logo](/img/nezha-logo.png)

## Specification

The Nezha uses Allwinner D1 SoC with single-core XuanTie C906 64-bit RISC-V
processor running at 1.0GHz. This SoC has also a blocks as HiFi4 DSP or
G2D 2D graphics accelerators. It has 1GB DDR3 RAM memory and 256MB SPI NAND
flash. As massive storage also a microSD card can be used. Board has also a
various of the peripheries such as Ethernet, WiFi & Bluetooth module, HDMI,
type-c USB OTG, type-a USB HOST, and dedicated header for serial communication
(UART) which at the board is described as `DEBUG`. To power up this board the
5V/2A power adapter will be needed. For full specification please
refer to the [official site](https://d1.docs.aw-ol.com/en/d1_dev/).

![nezha logo](/img/nezha-board-layout.png)

## Unboxing

The presented copy comes with a quite extensive package which contains board,
USB-UART converter, 2xUSB type-c cables, and screws.

![nezha unboxing 1](/img/nezha-unboxing-1.jpg)

![nezha unboxing 2](/img/nezha-unboxing-2.jpg)

## Firmware & Operating System

For now, the D1 Nezha development board comes with `Tina` Linux system which is
a fork of the `OpenWRT`. You can find information about it
[here](https://d1.docs.aw-ol.com/en/study/study_1tina/).
It supports kernels such as Linux3.4, Linux3.10, Linux4.4, Linux4.9, Linux5.4,
and others. There are also other distributions available such as Debian
(`Sipeed` and `PerfXLab` versions) and Fedora. All of them can be found and
download [here](https://ovsienko.info/D1/).

On the other hand boot firmware on D1 consists of three parts, which largely
correspond to the components used by 64-bit ARM SoCs:

![nezha boot flow](/img/nezha-boot-flow.png)

* `boot0` - it is modified for this board and used as SPL due to features such
  as enabling the T-HEAD ISA and MMU extensions.

* `OpenSBI` - supervisor which is an interface between too less privileged modes
  boot0 and TPL bootloader.

* `U-Boot` - TPL bootloader which initializes additional hardware and loads
  kernel from storage or the network.

More information can be found at [linux-sunxi](https://linux-sunxi.org/Allwinner_Nezha)
wiki.

## First boot

As it is described in many posts and comments on the entire internet, the board
was shipped with `Tina Linux` installed at NAND. Below you can see bootlog from
this version:

[![asciicast](https://asciinema.org/a/450115.svg)](https://asciinema.org/a/450115?speed=1.5)

As you can see first two lines come from `boot0` and then further are `OpenSBI`
and `U-Boot`. If you analyze logs you should manage that kernel and rootfs
are loaded from `NAND`:

```shell
device nand0 <nand>, # parts = 4
```

After `Tina` starts up, the green LED blinks.

![nezha tina](/img/nezha-tina.jpg)

## Booting Debian image

There are two available distros of Debian. In this section let's take a look at
one of them prepared by the **PerfXLab**.

```shell
[104]HELLO! BOOT0 is starting!
[107]BOOT0 commit : 27369ab
[109]set pll start
[111]periph0 has been enabled
[114]set pll end
[116][pmu]: bus read error
[118]board init ok
[120]DRAM only have internal ZQ!!
[123]get_pmu_exist() = -1
[126]ddr_efuse_type: 0x0
[129][AUTO DEBUG] two rank and full DQ!
[133]ddr_efuse_type: 0x0
[136][AUTO DEBUG] rank 0 row = 15
[139][AUTO DEBUG] rank 0 bank = 8
[142][AUTO DEBUG] rank 0 page size = 2 KB
[146][AUTO DEBUG] rank 1 row = 15
[149][AUTO DEBUG] rank 1 bank = 8
[152][AUTO DEBUG] rank 1 page size = 2 KB
[156]rank1 config same as rank0
[159]DRAM BOOT DRIVE INFO: V0.24
[162]DRAM CLK = 792 MHz
[164]DRAM Type = 3 (2:DDR2,3:DDR3)
[168]DRAMC ZQ value: 0x7b7bfb
[170]DRAM ODT value: 0x42.
[173]ddr_efuse_type: 0x0
[176]DRAM SIZE =1024 M
[180]DRAM simple test OK.
[182]dram size =1024
[184]card no is 0
[186]sdcard 0 line count 4
[188][mmc]: mmc driver ver 2021-04-2 16:45
[197][mmc]: Wrong media type 0x0
[200][mmc]: ***Try SD card 0***
[210][mmc]: HSSDR52/SDR25 4 bit
[212][mmc]: 50000000 Hz
[215][mmc]: 121896 MB
[217][mmc]: ***SD/MMC 0 init OK!!!***
[265]Loading boot-pkg Succeed(index=0).
[268]Entry_name        = opensbi
[271]Entry_name        = u-boot
[275]Entry_name        = dtb
[277]mmc not para
[279]Jump to second Boot.

OpenSBI v0.6
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : T-HEAD Xuantie Platform
Platform HART Features : RV64ACDFIMSUVX
Platform Max HARTs     : 1
Current Hart           : 0
Firmware Base          : 0x40000400
Firmware Size          : 75 KB
Runtime SBI Version    : 0.2

MIDELEG : 0x0000000000000222
MEDELEG : 0x000000000000b1ff
PMP0    : 0x0000000040000000-0x000000004001ffff (A)
PMP1    : 0x0000000040000000-0x000000007fffffff (A,R,W,X)
PMP2    : 0x0000000080000000-0x00000000bfffffff (A,R,W,X)
PMP3    : 0x0000000000020000-0x0000000000027fff (A,�

U-Boot 2018.05-g0a88ac9 (Apr 30 2021 - 11:23:28 +0000) Allwinner Technology

[00.362]DRAM:  1 GiB
[00.364]Relocation Offset is: 3def0000
[00.368]secure enable bit: 0
[00.370]CPU=1008 MHz,PLL6=600 Mhz,AHB=200 Mhz, APB1=100Mhz  MBus=300Mhz
[00.377]flash init start
[00.379]workmode = 0,storage type = 1
[00.382][mmc]: mmc driver ver uboot2018:2021-04-16 14:23:00-1
[00.388][mmc]: get sdc_type fail and use default host:tm1.
[00.394][mmc]: can't find node "mmc0",will add new node
[00.399][mmc]: fdt err returned <no error>
[00.403][mmc]: Using default timing para
[00.407][mmc]: SUNXI SDMMC Controller Version:0x50310
[00.424][mmc]: card_caps:0x3000000a
[00.428][mmc]: host_caps:0x3000003f
[00.431]sunxi flash init ok
[00.434]line:714 init_clocks
__clk_init: clk pll_periph0x2 already initialized
register fix_factor clk error
[00.444]drv_disp_init
request pwm success, pwm2:pwm2:0x2000c00.
[00.461]drv_disp_init finish
[00.463]boot_gui_init:start
[00.466]set disp.dev2_output_type fail. using defval=0
[00.658]boot_gui_init:finish
partno erro : can't find partition bootloader
54 bytes read in 1 ms (52.7 KiB/s)
[01.016]bmp_name=bootlogo.bmp size 3072054
[01.070]LCD open finish
3072054 bytes read in 130 ms (22.5 MiB/s)
[01.185]Loading Environment from SUNXI_FLASH... OK
[01.204]out of usb burn from boot: not need burn key
root_partition is rootfs
set root to /dev/mmcblk0p5
[01.214]update part info
[01.217]update bootcmd
[01.220]change working_fdt 0x7eaafda8 to 0x7ea8fda8
[01.241]update dts
Hit any key to stop autoboot:  0
Android's image name: d1-nezha
No reserved memory region found in source FDT
[01.669]
Starting kernel ...

[01.672][mmc]: MMC Device 2 not found
[01.675][mmc]: mmc 2 not find, so not exit

(...)
```

As you can see bootlog is different than for the `Tina Linux`. Basically, this
difference is visible in logs from `boot0` where we can read the information
that this time the `SDCard` is detected and start to read data from it.

```shell
Debian GNU/Linux 11 RVBoards ttyS0

RVBoards login: root
Password:
Linux RVBoards 5.4.61 #12 PREEMPT Thu Jun 3 08:39:01 UTC 2021 riscv64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Wed May 19 18:39:24 CST 2021 on ttyS0
root@RVBoards:~#
```

The system starts up and enters the login interface after powering on for about
1 minute. During this process, the LED light will turn on in blue and go out
after 5 seconds.

> Note: Password to this distro is `rvboards`.

### Test of the wireless connection

Now let's test a WiFi connection. For this purpose, it is needed to do some
preparations:

* bring up the wireless interface,

* create `wpa_supplicant.conf` which contain information about the network we
  want to be connected,

* start a new instance of `wpa_supplicant` after we close existing processes,

* use `dhclient` to receive IP address,

* install `iperf3` at the Nezha board and your host machine.

After these steps we are prepared to proceed with a test as follows:

* run `iperf` server at the host
  ```shell
  $ iperf3 -s
  ```

* test connection between client and server
  ```shell
  # iperf3 -c <host ip>
  ```

As result, we receive information about sender and receiver speed. The board
was connected to `2.4GHz` network:
```
# iperf3 -c 192.168.1.234
Connecting to host 192.168.1.234, port 5201
[  5] local 192.168.1.171 port 35790 connected to 192.168.1.234 port 5201
[ 2600.050994] [BH_WRN] miss interrupt!
[ 2600.330996] [BH_WRN] miss interrupt!
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.78 MBytes  14.9 Mbits/sec    0    100 KBytes
[  5]   1.00-2.00   sec  2.73 MBytes  22.9 Mbits/sec    0    197 KBytes
[  5]   2.00-3.00   sec  4.60 MBytes  38.6 Mbits/sec    0    236 KBytes
[  5]   3.00-4.00   sec  4.16 MBytes  34.9 Mbits/sec    0    266 KBytes
[  5]   4.00-5.00   sec  3.54 MBytes  29.7 Mbits/sec    0    266 KBytes
[  5]   5.00-6.00   sec  4.29 MBytes  36.0 Mbits/sec    0    300 KBytes
[  5]   6.00-7.00   sec  4.47 MBytes  37.6 Mbits/sec    0    300 KBytes
[  5]   7.00-8.00   sec  3.42 MBytes  28.6 Mbits/sec    0    317 KBytes
[  5]   8.00-9.00   sec  3.67 MBytes  30.9 Mbits/sec    0    355 KBytes
[  5]   9.00-10.00  sec  2.92 MBytes  24.5 Mbits/sec    0    355 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  35.6 MBytes  29.9 Mbits/sec    0             sender
[  5]   0.00-10.03  sec  34.2 MBytes  28.6 Mbits/sec                  receiver
```

The numbers have spoken! I can say that it is a not bad speed, but it is a half,
I got in comparison with my `Huawei Matebook D`.

## Next steps

Certainly, Nezha's design is interesting. Many of the key elements for the
operation of the system is still being developed and we would like to have some
contribution to the software for D1 Nezha, for example, support in the Yocto
Project. Please let us know in the comments what do you think about this board
and what should we check?

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact@3mdeb.com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).

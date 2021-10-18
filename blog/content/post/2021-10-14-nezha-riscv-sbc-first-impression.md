---
title: First impression on Nezha RISC-V SBC
abstract: 'Nezha is a AIoT development board customized by AWOL based on
           Allwinner's D1 chip. It is the world's first mass-produced development
           board that supports 64bit RISC-V instruction set and Linux system.'
cover: /img/nezha-logo.png
author: cezary.sobczak
layout: post
published: true
date: 2021-10-14
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
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

## Intro

Nezha board is a development board that is designed by an AWOL. This project
uses a D1 SoC from Allwinner which is used for the first time by the general
public. Probably this board is the **first massive** produced and available SBC
based at RISC-V architecture taking in mind a fact that [BeagleV™](https://blog.3mdeb.com/2021/2021-05-06-first-impressions-beaglev/)
was canceled in august this year after the pilot program with version beta of
the board.

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
a fork of the `OpenWRT`. It supports kernels such as Linux3.4, Linux3.10,
Linux4.4, Linux4.9, Linux5.4, and others. There are also other distributions
available such as Debian (`Sipeed` and `PerfXLab` versions) and Fedora. All of
them can be found and download [here](https://ovsienko.info/D1/).

On the other hand boot firmware on D1 consists of three parts, which largely
correspond to the components used by 64-bit ARM SoCs:

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

```shell
[188]HELLO! BOOT0 is starting!
[191]BOOT0 commit : 2337244-dirty

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
PMP2    : 0x0000000000000000-0x0000000007ffffff (A,R,W)
PMP3    : 0x0000000009000000-0x000000000901ffff (�

U-Boot 2018.05-00107-gc22c3d075c (Apr 24 2021 - 07:52:58 +0000) Allwinner Technology

[00.435]DRAM:  1 GiB
[00.437]Relocation Offset is: 3deeb000
[00.442]secure enable bit: 0
[00.444]CPU=1008 MHz,PLL6=600 Mhz,AHB=200 Mhz, APB1=100Mhz  MBus=300Mhz
initr_ledc
unable to find ledc node in device tree.
[00.455]flash init start
[00.458]workmode = 0,storage type = 0
[00.464]sunxi-spinand-phy: not detect any munufacture from id table
[00.470]sunxi-spinand-phy: get spi-nand Model from fdt fail
[00.475]sunxi-spinand-phy: get phy info from fdt fail

device nand0 <nand>, # parts = 4
 #: name    size    offset    mask_flags
 0: boot0               0x00100000  0x00000000  1
 1: uboot               0x00300000  0x00100000  1
 2: secure_storage      0x00100000  0x00400000  1
 3: sys                 0x0fb00000  0x00500000  0

active partition: nand0,0 - (boot0) 0x00100000 @ 0x00000000

defaults:
mtdids  : nand0=nand
mtdparts: mtdparts=nand:1024k@0(boot0)ro,3072k@1048576(uboot)ro,1024k@4194304(secure_storage)ro,-(sys)
[00.814]ubi0: attaching mtd4
[01.210]ubi0: scanning is finished
[01.220]ubi0: attached mtd4 (name "sys", size 251 MiB)
[01.224]ubi0: PEB size: 262144 bytes (256 KiB), LEB size: 258048 bytes
[01.231]ubi0: min./max. I/O unit sizes: 4096/4096, sub-page size 2048
[01.237]ubi0: VID header offset: 2048 (aligned 2048), data offset: 4096
[01.243]ubi0: good PEBs: 1004, bad PEBs: 0, corrupted PEBs: 0
[01.249]ubi0: user volume: 9, internal volumes: 1, max. volumes count: 128
[01.255]ubi0: max/mean erase counter: 2/1, WL threshold: 4096, image sequence number: 0
[01.263]ubi0: available PEBs: 0, total reserved PEBs: 1004, PEBs reserved for bad PEB handling: 40
[01.272]sunxi flash init ok
[01.274]line:714 init_clocks
__clk_init: clk pll_periph0x2 already initialized
register fix_factor clk error
[01.284]drv_disp_init
partno erro : can't find partition bootloader
** Unable to read file lcd_compatible_index.txt **
[01.521]do_fat_fsload for lcd config failed
request pwm success, pwm2:pwm2:0x2000c00.
[01.536]drv_disp_init finish
[01.538]boot_gui_init:start
[01.541]set disp.dev2_output_type fail. using defval=0
[01.733]boot_gui_init:finish
[02.145]LCD open finish
partno erro : can't find partition bootloader
54 bytes read in 0 ms
[02.306]bmp_name=bootlogo.bmp size 38454
38454 bytes read in 5 ms (7.3 MiB/s)
[02.522]Loading Environment from SUNXI_FLASH... OK
[02.556]Item0 (Map) magic is bad
[02.559]usb burn from boot
delay time 0
weak:otg_phy_config
[02.570]usb prepare ok
[03.373]overtime
[03.377]do_burn_from_boot usb : no usb exist
[03.401]update bootcmd
[03.423]change working_fdt 0x7eaaad70 to 0x7ea8ad70
partno erro : can't find partition bootloader
** Unable to read file lcd_compatible_index.txt **
[03.474]do_fat_fsload for lcd config failed
partno erro : can't find partition bootloader
[03.502]please enable FAT_WRITE for lcd compatible first
partno erro : can't find partition bootloader
** Unable to read file lcd_compatible_index.txt **
[03.535]do_fat_fsload for lcd config failed
[03.540]libfdt fdt_path_offset() for lcd
[03.544]update dts
Hit any key to stop autoboot:  0
dsp0:gpio init config fail
DSP0 start ok, img length 252960, booting from 0x400660
Android's image name: d1-nezha
No reserved memory region found in source FDT
[09.502]
Starting kernel ...

[    0.000000] OF: fdt: Ignoring memory range 0x40000000 - 0x40200000
[    0.000000] Linux version 5.4.61 (wuhuabin@AwExdroid86) (riscv64-unknown-linux-gnu-gcc (C-SKY RISCV Tools V1.8.4 B20200702) 8.1.0, GNU ld (GNU Binutils) 2.32) #49 PREEMPT Wed Apr 28 09:23:43 UTC 2021
[    0.000000] cma: Reserved 8 MiB at 0x000000007f800000
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000040200000-0x000000007fffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000040200000-0x000000007fffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000040200000-0x000000007fffffff]
[    0.000000] On node 0 totalpages: 261632
[    0.000000]   DMA32 zone: 3577 pages used for memmap
[    0.000000]   DMA32 zone: 0 pages reserved
[    0.000000]   DMA32 zone: 261632 pages, LIFO batch:63
[    0.000000] elf_hwcap is 0x20112d
[    0.000000] pcpu-alloc: s0 r0 d32768 u32768 alloc=1*32768
[    0.000000] pcpu-alloc: [0] 0
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 258055
[    0.000000] Kernel command line: ubi.mtd=sys ubi.block=0,rootfs earlyprintk=sunxi-uart,0x02500000 clk_ignore_unused initcall_debug=0 console=ttyS0,115200 loglevel=8 root=/dev/ubiblock0_5 rootfstype=squashfs init=/sbin/init partitions=mbr@ubi0_0:boot-resource@ubi0_1:env@ubi0_2:env-redund@ubi0_3:boot@ubi0_4:rootfs@ubi0_5:dsp0@ubi0_6:recovery@ubi0_7:UDISK@ubi0_8: cma=8M snum= mac_addr= wifi_mac= bt_mac= specialstr= gpt=1 androidboot.hardware=sun20iw1p1 boot_type=5 androidboot.boot_type=5 gpt=1 uboot_message=2018.05-00107-gc22c3d075c(04/24/20
[    0.000000] Dentry cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Inode-cache hash table entries: 65536 (order: 7, 524288 bytes, linear)
[    0.000000] Sorting __ex_table...
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 1008024K/1046528K available (5944K kernel code, 655K rwdata, 2062K rodata, 208K init, 251K bss, 30312K reserved, 8192K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] rcu: Preemptible hierarchical RCU implementation.
[    0.000000]  Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
[    0.000000] plic: mapped 200 interrupts with 1 handlers for 2 contexts.
[    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x588fe9dc0, max_idle_ns: 440795202592 ns
[    0.000005] sched_clock: 64 bits at 24MHz, resolution 41ns, wraps every 4398046511097ns
[    0.000023] riscv_timer_clockevent depends on broadcast, but no broadcast function available
[    0.000331] clocksource: timer: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 79635851949 ns
[    0.000934] Console: colour dummy device 80x25
[    0.000975] Calibrating delay loop (skipped), value calculated using timer frequency.. 48.00 BogoMIPS (lpj=240000)
[    0.000991] pid_max: default: 32768 minimum: 301
[    0.001190] Mount-cache hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    0.001219] Mountpoint-cache hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    0.002933] ASID allocator initialised with 65536 entries
[    0.003098] rcu: Hierarchical SRCU implementation.
[    0.003798] devtmpfs: initialized
[    0.015636] random: get_random_u32 called from bucket_table_alloc.isra.31+0x4e/0x15e with crng_init=0
[    0.016511] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.016541] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
[    0.016979] pinctrl core: initialized pinctrl subsystem
[    0.018302] NET: Registered protocol family 16
[    0.020214] DMA: preallocated 256 KiB pool for atomic allocations
[    0.020838] cpuidle: using governor menu
[    0.065898] rtc_ccu: sunxi ccu init OK
[    0.072382] clock: sunxi ccu init OK
[    0.073312] clock: sunxi ccu init OK
[    0.112289] iommu: Default domain type: Translated 
[    0.112462] sunxi iommu: irq = 4
[    0.113630] SCSI subsystem initialized
[    0.113970] usbcore: registered new interface driver usbfs
[    0.114072] usbcore: registered new interface driver hub
[    0.114176] usbcore: registered new device driver usb
[    0.114354] mc: Linux media interface: v0.10
[    0.114416] videodev: Linux video capture interface: v2.00
[    0.115376] Advanced Linux Sound Architecture Driver Initialized.
[    0.115966] Bluetooth: Core ver 2.22
[    0.116045] NET: Registered protocol family 31
[    0.116056] Bluetooth: HCI device and connection manager initialized
[    0.116076] Bluetooth: HCI socket layer initialized
[    0.116088] Bluetooth: L2CAP socket layer initialized
[    0.116123] Bluetooth: SCO socket layer initialized
[    0.116401] pwm module init!
[    0.117921] g2d 5410000.g2d: Adding to iommu group 0
[    0.118406] G2D: rcq version initialized.major:250
[    0.118951] input: sunxi-keyboard as /devices/virtual/input/input0
[    0.120530] clocksource: Switched to clocksource riscv_clocksource
[    0.132206] sun8iw20-pinctrl 2000000.pinctrl: initialized sunXi PIO driver
[    0.147889] NET: Registered protocol family 2
[    0.148661] tcp_listen_portaddr_hash hash table entries: 512 (order: 1, 8192 bytes, linear)
[    0.148725] TCP established hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.148828] TCP bind hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.148910] TCP: Hash tables configured (established 8192 bind 8192)
[    0.149090] UDP hash table entries: 512 (order: 2, 16384 bytes, linear)
[    0.149152] UDP-Lite hash table entries: 512 (order: 2, 16384 bytes, linear)
[    0.149434] NET: Registered protocol family 1
[    0.150761] sun8iw20-pinctrl 2000000.pinctrl: 2000000.pinctrl supply vcc-pc not found, using dummy regulator
[    0.151329] spi spi0: spi0 supply spi not found, using dummy regulator
[    0.151596] sunxi_spi_resource_get()2062 - [spi0] SPI MASTER MODE
[    0.151704] sunxi_spi_clk_init()2138 - [spi0] mclk 100000000
[    0.152375] sunxi_spi_probe()2542 - [spi0]: driver probe succeed, base ffffffd00405a000, irq 31
[    0.154252] Initialise system trusted keyrings
[    0.154501] workingset: timestamp_bits=62 max_order=18 bucket_order=0
[    0.162047] squashfs: version 4.0 (2009/01/31) Phillip Lougher
[    0.182395] Key type asymmetric registered
[    0.182410] Asymmetric key parser 'x509' registered
[    0.182433] io scheduler mq-deadline registered
[    0.182441] io scheduler kyber registered
[    0.182461] atomic64_test: passed
[    0.183650] [DISP]disp_module_init
[    0.184218] disp 5000000.disp: Adding to iommu group 0
[    0.184814] [DISP] disp_init,line:2385:
[    0.184821] smooth display screen:0 type:1 mode:4
[    0.223477] display_fb_request,fb_id:0
[    0.253279] disp_al_manager_apply ouput_type:1
[    0.253440] [DISP] lcd_clk_config,line:731:
[    0.253452] disp 0, clk: pll(420000000),clk(420000000),dclk(70000000) dsi_rate(70000000)
[    0.253452]      clk real:pll(420000000),clk(420000000),dclk(105000000) dsi_rate(150000000)
[    0.253843] sun8iw20-pinctrl 2000000.pinctrl: 2000000.pinctrl supply vcc-pd not found, using dummy regulator
[    0.254582] [DISP]disp_module_init finish
[    0.255496] sunxi_sid_init()497 - insmod ok
[    0.256045] pwm-regulator: supplied by regulator-dummy
[    0.263358] sun8iw20-pinctrl 2000000.pinctrl: 2000000.pinctrl supply vcc-pb not found, using dummy regulator
[    0.263800] uart uart0: get regulator failed
[    0.263831] uart uart0: uart0 supply uart not found, using dummy regulator
[    0.264150] uart0: ttyS0 at MMIO 0x2500000 (irq = 18, base_baud = 1500000) is a SUNXI
[    0.264177] sw_console_setup()1808 - console setup baud 115200 parity n bits 8, flow n
[    1.051516] printk: console [ttyS0] enabled
[    1.057075] sun8iw20-pinctrl 2000000.pinctrl: 2000000.pinctrl supply vcc-pg not found, using dummy regulator
[    1.068541] uart uart1: get regulator failed
[    1.073368] uart uart1: uart1 supply uart not found, using dummy regulator
[    1.081468] uart1: ttyS1 at MMIO 0x2500400 (irq = 19, base_baud = 1500000) is a SUNXI
[    1.091420] misc dump reg init
[    1.095439] sunxi-rfkill soc@3000000:rfkill@0: module version: v1.0.9
[    1.102684] sunxi-rfkill soc@3000000:rfkill@0: devm_pinctrl_get() failed!
[    1.110297] sunxi-rfkill soc@3000000:rfkill@0: get gpio chip_en failed
[    1.117618] sunxi-rfkill soc@3000000:rfkill@0: get gpio power_en failed
[    1.125080] sunxi-rfkill soc@3000000:rfkill@0: wlan_busnum (1)
[    1.131615] sunxi-rfkill soc@3000000:rfkill@0: Missing wlan_power.
[    1.138524] sunxi-rfkill soc@3000000:rfkill@0: wlan clock[0] (32k-fanout1)
[    1.146288] sunxi-rfkill soc@3000000:rfkill@0: wlan_regon gpio=204 assert=1
[    1.154150] sunxi-rfkill soc@3000000:rfkill@0: wlan_hostwake gpio=202 assert=1
[    1.162322] sunxi-rfkill soc@3000000:rfkill@0: wakeup source is enabled
[    1.169939] sunxi-rfkill soc@3000000:rfkill@0: Missing bt_power.
[    1.176751] sunxi-rfkill soc@3000000:rfkill@0: bt clock[0] (32k-fanout1)
[    1.184286] sunxi-rfkill soc@3000000:rfkill@0: bt_rst gpio=210 assert=0
[    1.192590] [ADDR_MGT] addr_mgt_probe: module version: v1.0.8
[    1.200130] [ADDR_MGT] addr_mgt_probe: success.
[    1.206222] sunxi-spinand: AW SPINand MTD Layer Version: 2.0 20201228
[    1.213496] sunxi-spinand-phy: AW SPINand Phy Layer Version: 1.10 20200306
[    1.221437] sunxi-spinand-phy: not detect any munufacture from id table
[    1.228818] sunxi-spinand-phy: get spi-nand Model from fdt fail
[    1.235480] sunxi-spinand-phy: get phy info from fdt fail
[    1.241565] sunxi-spinand-phy: not detect munufacture from fdt
[    1.248248] sunxi-spinand-phy: detect munufacture from id table: Mxic
[    1.255499] sunxi-spinand-phy: detect spinand id: ff0326c2 ffffffff
[    1.262507] sunxi-spinand-phy: ========== arch info ==========
[    1.269007] sunxi-spinand-phy: Model:               MX35LF2GE4AD
[    1.275753] sunxi-spinand-phy: Munufacture:         Mxic
[    1.281698] sunxi-spinand-phy: DieCntPerChip:       1
[    1.287343] sunxi-spinand-phy: BlkCntPerDie:        2048
[    1.293286] sunxi-spinand-phy: PageCntPerBlk:       64
[    1.299010] sunxi-spinand-phy: SectCntPerPage:      4
[    1.304689] sunxi-spinand-phy: OobSizePerPage:      64
[    1.310414] sunxi-spinand-phy: BadBlockFlag:        0x1
[    1.316260] sunxi-spinand-phy: OperationOpt:        0x7
[    1.322137] sunxi-spinand-phy: MaxEraseTimes:       65000
[    1.328152] sunxi-spinand-phy: EccFlag:             0x2
[    1.333996] sunxi-spinand-phy: EccType:             8
[    1.339640] sunxi-spinand-phy: EccProtectedType:    3
[    1.345295] sunxi-spinand-phy: ========================================
[    1.352718] sunxi-spinand-phy: 
[    1.356218] sunxi-spinand-phy: ========== physical info ==========
[    1.363126] sunxi-spinand-phy: TotalSize:    256 M
[    1.368479] sunxi-spinand-phy: SectorSize:   512 B
[    1.373841] sunxi-spinand-phy: PageSize:     2 K
[    1.378983] sunxi-spinand-phy: BlockSize:    128 K
[    1.384372] sunxi-spinand-phy: OOBSize:      64 B
[    1.389611] sunxi-spinand-phy: ========================================
[    1.397002] sunxi-spinand-phy: 
[    1.400514] sunxi-spinand-phy: ========== logical info ==========
[    1.407328] sunxi-spinand-phy: TotalSize:    256 M
[    1.412685] sunxi-spinand-phy: SectorSize:   512 B
[    1.418036] sunxi-spinand-phy: PageSize:     4 K
[    1.423204] sunxi-spinand-phy: BlockSize:    256 K
[    1.428540] sunxi-spinand-phy: OOBSize:      128 B
[    1.433929] sunxi-spinand-phy: ========================================
[    1.441445] sunxi-spinand-phy: block lock register: 0x00
[    1.447532] sunxi-spinand-phy: feature register: 0x11
[    1.453232] sunxi-spinand-phy: sunxi physic nand init end
[    1.459876] Creating 4 MTD partitions on "sunxi_mtd_nand":
[    1.466129] 0x000000000000-0x000000100000 : "boot0"
[    1.481826] 0x000000100000-0x000000500000 : "uboot"
[    1.487951] random: fast init done
[    1.521711] 0x000000500000-0x000000600000 : "secure_storage"
[    1.541714] 0x000000600000-0x000010000000 : "sys"
[    1.933610] random: crng init done
[    2.692233] libphy: Fixed MDIO Bus: probed
[    2.696804] CAN device driver interface
[    2.702706] sun8iw20-pinctrl 2000000.pinctrl: 2000000.pinctrl supply vcc-pe not found, using dummy regulator
[    2.714020] sunxi gmac driver's version: 1.0.0
[    2.719149] gmac-power0: NULL
[    2.722502] gmac-power1: NULL
[    2.725809] gmac-power2: NULL
[    2.730241] Failed to alloc md5
[    2.733879] eth0: Use random mac address
[    2.738621] ehci_hcd: USB 2.0 'Enhanced' Host Controller (EHCI) Driver
[    2.745996] sunxi-ehci: EHCI SUNXI driver
[    2.751126] get ehci1-controller wakeup-source is fail.
[    2.757052] sunxi ehci1-controller don't init wakeup source
[    2.763363] [sunxi-ehci1]: probe, pdev->name: 4200000.ehci1-controller, sunxi_ehci: 0xffffffe0008d6748, 0x:ffffffd004079000, irq_no:31
[    2.776968] sunxi-ehci 4200000.ehci1-controller: 4200000.ehci1-controller supply drvvbus not found, using dummy regulator
[    2.789583] sunxi-ehci 4200000.ehci1-controller: EHCI Host Controller
[    2.796916] sunxi-ehci 4200000.ehci1-controller: new USB bus registered, assigned bus number 1
[    2.806740] sunxi-ehci 4200000.ehci1-controller: irq 49, io mem 0x04200000
[    2.840579] sunxi-ehci 4200000.ehci1-controller: USB 2.0 started, EHCI 1.00
[    2.849312] hub 1-0:1.0: USB hub found
[    2.853632] hub 1-0:1.0: 1 port detected
[    2.858813] ohci_hcd: USB 1.1 'Open' Host Controller (OHCI) Driver
[    2.865850] sunxi-ohci: OHCI SUNXI driver
[    2.870962] get ohci1-controller wakeup-source is fail.
[    2.876898] sunxi ohci1-controller don't init wakeup source
[    2.883208] [sunxi-ohci1]: probe, pdev->name: 4200400.ohci1-controller, sunxi_ohci: 0xffffffe0008d7288
[    2.893643] sunxi-ohci 4200400.ohci1-controller: 4200400.ohci1-controller supply drvvbus not found, using dummy regulator
[    2.906189] sunxi-ohci 4200400.ohci1-controller: OHCI Host Controller
[    2.913506] sunxi-ohci 4200400.ohci1-controller: new USB bus registered, assigned bus number 2
[    2.923304] sunxi-ohci 4200400.ohci1-controller: irq 50, io mem 0x04200400
[    3.005555] hub 2-0:1.0: USB hub found
[    3.009822] hub 2-0:1.0: 1 port detected
[    3.015325] usbcore: registered new interface driver uas
[    3.021491] usbcore: registered new interface driver usb-storage
[    3.028301] usbcore: registered new interface driver ums-alauda
[    3.035051] usbcore: registered new interface driver ums-cypress
[    3.041911] usbcore: registered new interface driver ums-datafab
[    3.048676] usbcore: registered new interface driver ums_eneub6250
[    3.055678] usbcore: registered new interface driver ums-freecom
[    3.062536] usbcore: registered new interface driver ums-isd200
[    3.069194] usbcore: registered new interface driver ums-jumpshot
[    3.076147] usbcore: registered new interface driver ums-karma
[    3.082756] usbcore: registered new interface driver ums-onetouch
[    3.089699] usbcore: registered new interface driver ums-realtek
[    3.096529] usbcore: registered new interface driver ums-sddr09
[    3.103246] usbcore: registered new interface driver ums-sddr55
[    3.109942] usbcore: registered new interface driver ums-usbat
[    3.117595] sunxi_gpadc_init,1968, success
[    3.123155] sunxi-rtc 7090000.rtc: errata__fix_alarm_day_reg_default_value(): ALARM0_DAY_REG=0, set it to 1
[    3.135399] sunxi-rtc 7090000.rtc: registered as rtc0
[    3.141259] sunxi-rtc 7090000.rtc: setting system clock to 1970-01-01T00:00:11 UTC (11)
[    3.150220] sunxi-rtc 7090000.rtc: sunxi rtc probed
[    3.156132] i2c /dev entries driver
[    3.160120] IR NEC protocol handler initialized
[    3.165914] sunxi cedar version 1.1
[    3.170081] sunxi-cedar 1c0e000.ve: Adding to iommu group 0
[    3.176422] VE: install start!!!
[    3.176422] 
[    3.181960] VE: cedar-ve the get irq is 6
[    3.181960] 
[    3.188297] VE: ve_debug_proc_info:000000009fc01abf, data:0000000010cdccca, lock:00000000bc239a3f
[    3.188297] 
[    3.199879] VE: install end!!!
[    3.199879] 
[    3.205863] sunxi-wdt 6011000.watchdog: Watchdog enabled (timeout=16 sec, nowayout=0)
[    3.215023] Bluetooth: HCI UART driver ver 2.3
[    3.220010] Bluetooth: HCI UART protocol H4 registered
[    3.225777] Bluetooth: HCI UART protocol BCSP registered
[    3.231724] Bluetooth: XRadio Bluetooth LPM Mode Driver Ver 1.0.10
[    3.239002] [XR_BT_LPM] bluesleep_probe: bt_wake polarity: 1
[    3.245419] [XR_BT_LPM] bluesleep_probe: host_wake polarity: 1
[    3.252042] [XR_BT_LPM] bluesleep_probe: wakeup source is disabled!
[    3.252042] 
[    3.260709] [XR_BT_LPM] bluesleep_probe: uart_index(1)
[    3.270442] sunxi-mmc 4020000.sdmmc: SD/MMC/SDIO Host Controller Driver(v4.19 2021-03-24 19:50)
[    3.280409] sunxi-mmc 4020000.sdmmc: ***ctl-spec-caps*** 8
[    3.286683] sunxi-mmc 4020000.sdmmc: No vmmc regulator found
[    3.293025] sunxi-mmc 4020000.sdmmc: No vqmmc regulator found
[    3.299430] sunxi-mmc 4020000.sdmmc: No vdmmc regulator found
[    3.305896] sunxi-mmc 4020000.sdmmc: No vd33sw regulator found
[    3.312427] sunxi-mmc 4020000.sdmmc: No vd18sw regulator found
[    3.318950] sunxi-mmc 4020000.sdmmc: No vq33sw regulator found
[    3.325480] sunxi-mmc 4020000.sdmmc: No vq18sw regulator found
[    3.332442] sunxi-mmc 4020000.sdmmc: Got CD GPIO
[    3.337948] sunxi-mmc 4020000.sdmmc: set cd-gpios as 24M fail
[    3.344619] sunxi-mmc 4020000.sdmmc: sdc set ios:clk 0Hz bm PP pm UP vdd 21 width 1 timing LEGACY(SDR12) dt B
[    3.355800] sunxi-mmc 4020000.sdmmc: no vqmmc,Check if there is regulator
[    3.375955] sunxi-mmc 4020000.sdmmc: sdc set ios:clk 400000Hz bm PP pm ON vdd 21 width 1 timing LEGACY(SDR12) dt B
[    3.400382] sunxi-mmc 4020000.sdmmc: detmode:gpio irq
[    3.406093] sunxi-mmc 4020000.sdmmc: sdc set ios:clk 0Hz bm PP pm OFF vdd 0 width 1 timing LEGACY(SDR12) dt B
[    3.417882] sunxi-mmc 4021000.sdmmc: SD/MMC/SDIO Host Controller Driver(v4.19 2021-03-24 19:50)
[    3.427949] sunxi-mmc 4021000.sdmmc: ***ctl-spec-caps*** 8
[    3.434253] sunxi-mmc 4021000.sdmmc: No vmmc regulator found
[    3.440595] sunxi-mmc 4021000.sdmmc: No vqmmc regulator found
[    3.447024] sunxi-mmc 4021000.sdmmc: No vdmmc regulator found
[    3.453458] sunxi-mmc 4021000.sdmmc: No vd33sw regulator found
[    3.459960] sunxi-mmc 4021000.sdmmc: No vd18sw regulator found
[    3.466522] sunxi-mmc 4021000.sdmmc: No vq33sw regulator found
[    3.473051] sunxi-mmc 4021000.sdmmc: No vq18sw regulator found
[    3.479600] sunxi-mmc 4021000.sdmmc: Cann't get pin bias hs pinstate,check if needed
[    3.489074] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 0Hz bm PP pm UP vdd 21 width 1 timing LEGACY(SDR12) dt B
[    3.500260] sunxi-mmc 4021000.sdmmc: no vqmmc,Check if there is regulator
[    3.520410] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 400000Hz bm PP pm ON vdd 21 width 1 timing LEGACY(SDR12) dt B
[    3.544651] sunxi-mmc 4021000.sdmmc: detmode:manually by software
[    3.552328] sunxi-mmc 4021000.sdmmc: smc 1 p1 err, cmd 52, RTO !!
[    3.559325] sunxi_led_probe()1715 - start
[    3.563817] sunxi-mmc 4021000.sdmmc: smc 1 p1 err, cmd 52, RTO !!
[    3.570727] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 400000Hz bm PP pm ON vdd 21 width 1 timing LEGACY(SDR12) dt B
[    3.582380] sunxi_get_str_of_property()1560 - failed to get the string of propname led_regulator!
[    3.592435] sunxi_register_led_classdev()1448 - led_classdev start
[    3.601077] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 400000Hz bm PP pm ON vdd 21 width 1 timing LEGACY(SDR12) dt B
[    3.615661] sunxi_led_probe()1820 - finish
[    3.620914] usbcore: registered new interface driver usbhid
[    3.627158] usbhid: USB HID core driver
[    3.633392] usbcore: registered new interface driver snd-usb-audio
[    3.640309] sunxi-mmc 4021000.sdmmc: smc 1 p1 err, cmd 5, RTO !!
[    3.647917] sunxi-mmc 4021000.sdmmc: smc 1 p1 err, cmd 5, RTO !!
[    3.655512] sunxi-mmc 4021000.sdmmc: smc 1 p1 err, cmd 5, RTO !!
[    3.663113] sunxi-mmc 4021000.sdmmc: smc 1 p1 err, cmd 5, RTO !!
[    3.669853] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 0Hz bm PP pm OFF vdd 0 width 1 timing LEGACY(SDR12) dt B
[    3.682535] sunxi-daudio 2034000.daudio: regulator missing or invalid
[    3.690344] [AUDIOCODEC][sunxi_codec_parse_params][2208]:digital_vol:0, lineout_vol:26, mic1gain:31, mic2gain:31 pa_msleep:120, pa_level:1, pa_pwr_level:1
[    3.690344] 
[    3.707608] [AUDIOCODEC][sunxi_codec_parse_params][2244]:adcdrc_cfg:0, adchpf_cfg:0, dacdrc_cfg:0, dachpf:0
[    3.719018] [AUDIOCODEC][sunxi_internal_codec_probe][2380]:codec probe finished
[    3.728216] debugfs: Directory '203034c.dummy_cpudai' with parent 'audiocodec' already present!
[    3.738017] [SNDCODEC][sunxi_card_init][583]:card init finished
[    3.745741] sunxi-codec-machine 2030340.sound: 2030000.codec <-> 203034c.dummy_cpudai mapping ok
[    3.757069] input: audiocodec sunxi Audio Jack as /devices/platform/soc@3000000/2030340.sound/sound/card0/input1
[    3.769152] [SNDCODEC][sunxi_card_dev_probe][832]:register card finished
[    3.778439] NET: Registered protocol family 10
[    3.784962] Segment Routing with IPv6
[    3.789259] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[    3.796715] NET: Registered protocol family 17
[    3.801772] can: controller area network core (rev 20170425 abi 9)
[    3.808801] NET: Registered protocol family 29
[    3.813831] can: raw protocol (rev 20170425)
[    3.818591] can: broadcast manager protocol (rev 20170425 t)
[    3.824992] can: netlink gateway (rev 20190810) max_hops=1
[    3.831469] Bluetooth: RFCOMM TTY layer initialized
[    3.836954] Bluetooth: RFCOMM socket layer initialized
[    3.842804] Bluetooth: RFCOMM ver 1.11
[    3.847988] Loading compiled-in X.509 certificates
[    3.855804] HDMI 2.0 driver init start!
[    3.860094] boot_hdmi=false
[    3.863333] ERROR: pinctrl_get for HDMI2.0 DDC fail
[    3.870388] HDMI2.0 module init end
[    3.900065] twi twi2: twi2 supply twi not found, using dummy regulator
[    3.915368] pcf857x 2-0038: probed
[    3.925538] sunxi_i2c_probe()2262 - [i2c2] probe success
[    3.941522] debugfs: Directory '2031000.dmic' with parent 'snddmic' already present!
[    3.951932] sunxi-audio-card 2031060.sounddmic: snd-soc-dummy-dai <-> 2031000.dmic mapping ok
[    3.962743] debugfs: Directory '2034000.daudio' with parent 'sndhdmi' already present!
[    3.973359] sunxi-audio-card 20340a0.sounddaudio2: snd-soc-dummy-dai <-> 2034000.daudio mapping ok
[    3.985054] get ehci0-controller wakeup-source is fail.
[    3.991050] sunxi ehci0-controller don't init wakeup source
[    3.997269] [sunxi-ehci0]: probe, pdev->name: 4101000.ehci0-controller, sunxi_ehci: 0xffffffe0008d6388, 0x:ffffffd0052f5000, irq_no:2e
[    4.010838] [sunxi-ehci0]: Not init ehci0
[    4.015814] get ohci0-controller wakeup-source is fail.
[    4.021801] sunxi ohci0-controller don't init wakeup source
[    4.028020] [sunxi-ohci0]: probe, pdev->name: 4101400.ohci0-controller, sunxi_ohci: 0xffffffe0008d6ec8
[    4.038486] [sunxi-ohci0]: Not init ohci0
[    4.044189] ubi0: attaching mtd3
[    5.019806] ubi0: scanning is finished
[    5.040077] ubi0: attached mtd3 (name "sys", size 250 MiB)
[    5.046241] ubi0: PEB size: 262144 bytes (256 KiB), LEB size: 258048 bytes
[    5.053947] ubi0: min./max. I/O unit sizes: 4096/4096, sub-page size 2048
[    5.061620] ubi0: VID header offset: 2048 (aligned 2048), data offset: 4096
[    5.069382] ubi0: good PEBs: 1000, bad PEBs: 0, corrupted PEBs: 0
[    5.076254] ubi0: user volume: 9, internal volumes: 1, max. volumes count: 128
[    5.084332] ubi0: max/mean erase counter: 2/1, WL threshold: 4096, image sequence number: 0
[    5.093711] ubi0: available PEBs: 16, total reserved PEBs: 984, PEBs reserved for bad PEB handling: 20
[    5.104158] ubi0: background thread "ubi_bgt0d" started, PID 69
[    5.112804] block ubiblock0_5: created from ubi0:5(rootfs)
[    5.121330] cfg80211: Loading compiled-in X.509 certificates for regulatory database
[    5.132311] cfg80211: Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
[    5.139787] platform regulatory.0: Direct firmware load for regulatory.db failed with error -2
[    5.149571] clk: Not disabling unused clocks
[    5.154482] cfg80211: failed to load regulatory.db
[    5.159908] ALSA device list:
[    5.163301]   #0: audiocodec
[    5.166510]   #1: snddmic
[    5.169453]   #2: sndhdmi
[    5.172467] alloc_fd: slot 0 not NULL!
[    5.181361] VFS: Mounted root (squashfs filesystem) readonly on device 254:0.
[    5.193072] devtmpfs: mounted
[    5.196575] Freeing unused kernel memory: 208K
[    5.201649] This architecture does not have kernel memory protection.
[    5.208831] Run /sbin/init as init process
[    6.098691] init: Console is alive
[    6.102889] init: - watchdog -
[    6.106446] init: - preinit -
/dev/by-name/UDISK already format by ubifs
[    7.490313] mount_root: mounting /dev/root
[    7.495570] mount_root: loading kmods from internal overlay
[    7.660608] hdmi_hpd_sys_config_release
[    7.767823] block: attempting to load /etc/config/fstab
[    7.813210] UBIFS (ubi0:8): Mounting in unauthenticated mode
[    7.819993] UBIFS (ubi0:8): background thread "ubifs_bgt0_8" started, PID 111
[    7.950994] UBIFS (ubi0:8): recovery needed
[    8.270527] UBIFS (ubi0:8): recovery completed
[    8.275759] UBIFS (ubi0:8): UBIFS: mounted UBI device 0, volume 8, name "UDISK"
[    8.284472] UBIFS (ubi0:8): LEB size: 258048 bytes (252 KiB), min./max. I/O unit sizes: 4096 bytes/4096 bytes
[    8.295634] UBIFS (ubi0:8): FS size: 192503808 bytes (183 MiB, 746 LEBs), journal size 9420800 bytes (8 MiB, 37 LEBs)
[    8.307542] UBIFS (ubi0:8): reserved for root: 0 bytes (0 KiB)
[    8.314075] UBIFS (ubi0:8): media format: w4/r0 (latest is w5/r0), UUID 2A9479AB-1A21-4021-8BE0-E8A7D5DEFB13, small LPT model
[    8.331220] block: extroot: UUID match (root: e4aac755-48e1b7c8-b32425c0-67317875, overlay: e4aac755-48e1b7c8-b32425c0-67317875)
[    8.352805] mount_root: switched to extroot
[    8.374378] procd: - early -
[    8.377741] procd: - watchdog -
[    8.777687] procd: - watchdog -
[    8.786717] procd: - ubus -
[    8.790491] procd (1): /proc/124/oom_adj is deprecated, please use /proc/124/oom_score_adj instead.
[    9.033021] procd: - init -
Please press Enter to activate this console.
[   10.094547] fuse: init (API version 7.31)
[   10.384559] file system registered
[   10.451669] configfs-gadget 4100000.udc-controller: failed to start g1: -19
[   10.483097] get ctp_power is fail, -22
[   10.487279] get ctp_power_ldo_vol is fail, -22
[   10.573428] sunxi_ctp_startup: ctp_power_io is invalid.
[   10.579340] get ctp_gesture_wakeup fail, no gesture wakeup
[   10.632324] gt9xxnew_ts 2-0014: 2-0014 supply ctp not found, using dummy regulator
[   10.771177] read descriptors
[   10.774434] read strings
[   10.920933] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   10.930444] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   10.950818] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   10.970694] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   10.997291] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.020381] <<-GTP-ERROR->> I2C Read: 0x8047, 1 bytes failed, errcode: -70! Process reset.
[   11.200649] <<-GTP-ERROR->> GTP i2c test failed time 1.
[   11.230805] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.250644] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.270649] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.284657] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.307841] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.330995] <<-GTP-ERROR->> I2C Read: 0x8047, 1 bytes failed, errcode: -70! Process reset.
[   11.490635] <<-GTP-ERROR->> GTP i2c test failed time 2.
[   11.521193] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.540718] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.558549] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.580812] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.600665] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.610017] <<-GTP-ERROR->> I2C Read: 0x8047, 1 bytes failed, errcode: -70! Process reset.
[   11.790632] <<-GTP-ERROR->> GTP i2c test failed time 3.
[   11.820843] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.840630] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.856153] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.879462] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.900865] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   11.910210] <<-GTP-ERROR->> I2C Read: 0x8047, 1 bytes failed, errcode: -70! Process reset.
[   12.090620] <<-GTP-ERROR->> GTP i2c test failed time 4.
[   12.120839] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   12.130766] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   12.142464] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   12.153971] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   12.165281] sunxi_i2c_do_xfer()1816 - [i2c2] incomplete xfer (status: 0x20, dev addr: 0x14)
[   12.175861] <<-GTP-ERROR->> I2C Read: 0x8047, 1 bytes failed, errcode: -70! Process reset.
[   12.341357] <<-GTP-ERROR->> GTP i2c test failed time 5.
[   12.370623] I2C communication ERROR!
[   12.370661] regulator-dummy: Underflow of regulator enable count
[   12.391059] gt9xxnew_ts: probe of 2-0014 failed with error -1
[   14.071387] ======== XRADIO WIFI OPEN ========
[   14.076943] [XRADIO] Driver Label:XR_V02.16.84_P2P_HT40_01.31
[   14.083772] [XRADIO] Allocated hw_priv @ 000000003621ddcc
[   14.100651] sunxi-rfkill soc@3000000:rfkill@0: bus_index: 1
[   14.116928] sunxi-rfkill soc@3000000:rfkill@0: wlan power on success
[   14.328119] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 0Hz bm PP pm UP vdd 21 width 1 timing LEGACY(SDR12) dt B
[   14.339277] [XRADIO] Detect SDIO card 1
[   14.350689] sunxi-mmc 4021000.sdmmc: no vqmmc,Check if there is regulator
[   14.370605] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 400000Hz bm PP pm ON vdd 21 width 1 timing LEGACY(SDR12) dt B
[   14.395505] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 400000Hz bm PP pm ON vdd 21 width 1 timing LEGACY(SDR12) dt B
[   14.410085] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 400000Hz bm PP pm ON vdd 21 width 1 timing LEGACY(SDR12) dt B
[   14.432790] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 400000Hz bm PP pm ON vdd 21 width 1 timing SD-HS(SDR25) dt B
[   14.444407] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 50000000Hz bm PP pm ON vdd 21 width 1 timing SD-HS(SDR25) dt B
[   14.456241] sunxi-mmc 4021000.sdmmc: sdc set ios:clk 50000000Hz bm PP pm ON vdd 21 width 4 timing SD-HS(SDR25) dt B
[   14.469100] mmc1: new high speed SDIO card at address 0001
[   14.476092] [SBUS] XRadio Device:sdio clk=50000000
[   14.490704] [XRADIO] XRADIO_HW_REV 1.0 detected.
[   14.601194] [XRADIO] xradio_update_dpllctrl: DPLL_CTRL Sync=0x00c00000.
[   14.646832] [XRADIO] Bootloader complete
[   14.763282] [XRADIO] Firmware completed.
[   22.369205] [WSM] Firmware Label:XR_C09.08.52.64_DBG_02.100 2GHZ HT40 Jan  3 2020 13:14:37
[   22.386726] [XRADIO] Firmware Startup Done.
[   22.391986] [XRADIO_WRN] enable Multi-Rx!
[   22.404368] ieee80211 phy0: Selected rate control algorithm 'minstrel_ht'
[   22.449900] Error: Driver 'gt9xxnew_ts' is already registered, aborting...
[   22.890353] ieee80211_do_open: vif_type=2, p2p=0, ch=3, addr=bc:c0:10:96:1f:87
[   22.907446] [STA] !!!xradio_vif_setup: id=0, type=2, p2p=0, addr=bc:c0:10:96:1f:87
[   22.928847] [AP_WRN] BSS_CHANGED_ASSOC but driver is unjoined.
Trying to connect to SWUpdate...



BusyBox v1.27.2 () built-in shell (ash)

 _____  _              __     _
|_   _||_| ___  _ _   |  |   |_| ___  _ _  _ _
  | |   _ |   ||   |  |  |__ | ||   || | ||_'_|
  | |  | || | || _ |  |_____||_||_|_||___||_,_|
  |_|  |_||_|_||_|_|  Tina is Based on OpenWrt!
 ----------------------------------------------
 Tina Linux (Neptune, 5C1C9C53)
 ----------------------------------------------
root@TinaLinux:/#
```

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

### Test the wireless connection

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
iperf3 -c 192.168.1.234
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

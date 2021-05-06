---
title: "First impressions on the beta BeagleV - affordable RISC-V SBC"
abstract: "BeagleV is the first affordable RISC-V SBC deisgned to run Linux. It
           is fully open-source with open-source software, open hardware design
           and RISC-V open architecture. This blog post presents the basic
           functionality of the first batch of the available beta samples
           released to the community."
cover: /img/YoctoProject_Logo_RGB.jpg
author: maciej.pijanowski
layout: post
published: true
date: 2021-05-06
archives: "2021"

tags:
  - beaglev
  - beaglebone
  - riscv
categories:
  - Firmware
  - hardware

---

## BeagleV

### Intro

BeagleV™ - StarLight is the first affordable RISC-V computer designed to run
Linux. It is fully open-source with open-source software, open hardware design
and RISC-V open architecture. It is a joint effort by Seeed Studio,
BeagleBoard.org® and StarFive.

The BeagleV hardware beta program already started as around 300 samples
shipped to developers all over the world. Please note that this post describes
the beta version of the BeagleV board and the experience of the final hardware
may be different. Please follow
[the official page](https://beagleboard.org/beaglev) for the latest information
about the public release.

### Specification

The BeagleV uses RISC-V SiFive U74 Dual-Core 64-bit RV64GC ISA SoC running at 1.5GHz.
It can have 4GB or 8GB LPDDR4 RAM, but the beta batch has 8GB only. It provides
various other peripherals, including USB3.0, Ethernet, and a 40-pin GPIO header.
The full specification can be found in the
[wiki pages](https://wiki.seeedstudio.com/BeagleV-Getting-Started/#specifications).

The board is running the beta version (`JH7100`) of the target SoC (`JH7110`).
There is a set of known performance and thermal issues with the beta chip,
which is described in the
[FAQ section](https://wiki.seeedstudio.com/BeagleV-Getting-Started/#what-is-jh7100-and-jh7110).

### Unboxing

The beta board comes with a simple package. There are no other peripherals like
power supply etc.

![beaglev-1](/img/beaglev-1.png)

The rather big heatsink with an active fan is what stands out at a first glance.

![beaglev-2](/img/beaglev-2.png)

### First boot

To get started, you should connect the USB-UART converter and power supply via
USB-C at minimum. Additionally, you can plug in an Ethernet cable and power on the
fan attached to the heatsink. The
[Getting started with BeagleV - StarLight page](https://wiki.seeedstudio.com/BeagleV-Getting-Started/)
describes the hardware setup in much detail.

![beaglev-3](/img/beaglev-3.png)

The board comes with the `OpenSBI` and `U-Boot` already flashed on the on-board
SPI flash. The boot log looks like below:

```
bootloader version:210209-4547a8d
                                 ddr 0x00000000, 1M test
ddr 0x00100000, 2M test
DDR clk 2133M,Version: 210302-5aea32f
0 crc flash: 7ebedaa2, crc ddr: 7ebedaa2
                                        crc check PASSED

                                                        bootloader.

OpenSBI v0.9
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name             : StarFive VIC7100
Platform Features         : timer,mfdeleg
Platform HART Count       : 2
Firmware Base             : 0x80000000
Firmware Size             : 92 KB
Runtime SBI Version       : 0.2

Domain0 Name              : root
Domain0 Boot HART         : 1
Domain0 HARTs             : 0*,1*
Domain0 Region00          : 0x0000000080000000-0x000000008001ffff ()
Domain0 Region01          : 0x0000000000000000-0x0000007fffffffff (R,W,X)
Domain0 Next Address      : 0x0000000080020000
Domain0 Next Arg1         : 0x0000000088000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes

Boot HART ID              : 1
Boot HART Domain          : root
Boot HART ISA             : rv64imafdcsux
Boot HART Features        : scounteren,mcounteren
Boot HART PMP Count       : 16
Boot HART PMP Granularity : 4096
Boot HART PMP Address Bits: 36
Boot HART MHPM Count      : 0
Boot HART MHPM Count      : 0
Boot HART MIDELEG         : 0x0000000000000222
Boot HART MEDELEG         : 0x000000000000b109


U-Boot 2021.04-rc4-g5b63233bc6-dirty (Apr 08 2021 - 14:09:59 +0800)

CPU:   rv64imafdc
DRAM:  8 GiB
MMC:   sdio0@10000000: 0, sdio1@10010000: 1
Net:   dwmac.10020000
Autoboot in 2 seconds
MMC CD is 0x1, force to True.
MMC CD is 0x1, force to True.
Card did not respond to voltage select! : -110
BeagleV # reset
resetting ...
Resetting BeagelV......
reset not supported yet
### ERROR ### Please RESET the board ###
```

As we can see, the `reset` command is not supported yet.

### Booting Fedora image

There is a
[ready to use Fedora 33 image](https://github.com/starfive-tech/beaglev_fedora).
To use it, we can simply download it, uncompress and flash it into uSD card. The
uncompressed image has 9GB and it takes around 15 minutes to flash it.

```
$ wget https://files.beagle.cc/file/beagleboard-public-2021/images/Fedora-riscv64-vic7100-dev-raw-image-Rawhide-20210419121453.n.0-sda.raw.zst
$ zstd -d Fedora-riscv64-vic7100-dev-raw-image-Rawhide-20210419121453.n.0-sda.raw.zst
$ sudo bmaptool copy --nobmap Fedora-riscv64-vic7100-dev-raw-image-Rawhide-20210419121453.n.0-sda.raw /dev/sde
```

It takes around 2-3 minutes to boot if from the uSD card for the first time.

```
fedora-starfive login: riscv
Password: starfive

[riscv@fedora-starfive ~]$ uname -a
Linux fedora-starfive 5.10.6+ #26 SMP Tue Apr 20 03:32:34 CST 2021 riscv64 riscv64 riscv64 GNU/Linux

[riscv@fedora-starfive ~]$ lscpu
Architecture:        riscv64
Byte Order:          Little Endian
CPU(s):              2
On-line CPU(s) list: 0,1
Thread(s) per core:  2
Core(s) per socket:  1
Socket(s):           1
L1d cache:           32 KiB
L1i cache:           32 KiB
L2 cache:            2 MiB

[riscv@fedora-starfive ~]$ free -h
              total        used        free      shared  buff/cache   available
Mem:          7.0Gi       107Mi       6.6Gi       8.0Mi       293Mi       6.8Gi
Swap:            0B          0B          0B
```

Some more first impressions are written below.

First of all, I needed to re-plug the Ethernet cable after each boot, so the IP address from
DHCP is assigned. Such issue is
[already reported](https://github.com/starfive-tech/beaglev_fedora/issues/2).

The kernel crashes when trying to reboot from OS:

```
[  383.143050] systemd-shutdown[1]: Rebooting.
[  383.181539] reboot: Restarting system
[  383.539221] mmc0: card 0007 removed
[  386.418886] ------------[ cut here ]------------
[  386.455621] WARNING: CPU: 0 PID: 1 at drivers/power/reset/gpio-restart.c:46 gpio_restart_notify+0x84/0x94
[  386.497441] Modules linked in: nft_ct nf_tables nf_conntrack nf_defrag_ipv6 nf_defrag_ipv4 ip_set rfkill nfnetlink sunrpc [last unloaded: ip_tables]
[  386.543330] CPU: 0 PID: 1 Comm: systemd-shutdow Tainted: G        W         5.10.6+ #26
[  386.583988] epc: ffffffe0009da52c ra : ffffffe0009da52a sp : ffffffe080007cb0
[  386.623790]  gp : ffffffe0018416a8 tp : ffffffe080013580 t0 : ffffffd004a6c110
[  386.663781]  t1 : 0000000000000000 t2 : ffffffe000ea9d88 s0 : ffffffe080007cd0
[  386.703770]  s1 : 0000000000000000 a0 : ffffffe0009da52a a1 : 0000000200000022
[  386.743813]  a2 : 0000000000000001 a3 : 0000000098dfb8ea a4 : 0000000000001869
[  386.783936]  a5 : 0000000000001869 a6 : ffffffe000743172 a7 : ffffffffad55ad55
[  386.824076]  s2 : ffffffe0842d14b0 s3 : 0000000000000000 s4 : 0000000000000000
[  386.864308]  s5 : 0000000000008000 s6 : a4f912efa6569000 s7 : 0000003fc5eeb7f0
[  386.904339]  s8 : 0000000000000000 s9 : 00000000c138fd04 s10: fffffffffffff000
[  386.944437]  s11: 0000002abc1f1768 t3 : 0000000000000001 t4 : 0000000000000002
[  386.984723]  t5 : 0000000000000010 t6 : ffffffe080007a70
[  387.022777] status: 0000000200000120 badaddr: 0000000080007c08 cause: 0000000000000003
[  387.063535] ---[ end trace ef57a8e571c8d0d9 ]---
[  412.148970] watchdog: BUG: soft lockup - CPU#0 stuck for 22s! [systemd-shutdow:1]
[  412.188632] Modules linked in: nft_ct nf_tables nf_conntrack nf_defrag_ipv6 nf_defrag_ipv4 ip_set rfkill nfnetlink sunrpc [last unloaded: ip_tables]
[  412.233990] CPU: 0 PID: 1 Comm: systemd-shutdow Tainted: G        W         5.10.6+ #26
[  412.273681] epc: ffffffe000202908 ra : ffffffe000202908 sp : ffffffe080007d40
[  412.312570]  gp : ffffffe0018416a8 tp : ffffffe080013580 t0 : ffffffd004a6c110
[  412.351744]  t1 : 0000000000000000 t2 : ffffffe000ea9d88 s0 : ffffffe080007d60
[  412.390878]  s1 : 0000000000000000 a0 : 0000000000000000 a1 : 0000000200000022
[  412.429935]  a2 : 0000000000000001 a3 : 0000000098dfb8ea a4 : 0000000000001869
[  412.468929]  a5 : 0000000000000000 a6 : ffffffe000743172 a7 : ffffffffad55ad55
[  412.508167]  s2 : 0000000028121969 s3 : ffffffe001620820 s4 : fffffffffee1dead
[  412.547359]  s5 : ffffffe0018440c0 s6 : a4f912efa6569000 s7 : 0000003fc5eeb7f0
[  412.586579]  s8 : 0000000000000000 s9 : 00000000c138fd04 s10: fffffffffffff000
[  412.625801]  s11: 0000002abc1f1768 t3 : 0000000000000001 t4 : 0000000000000002
[  412.664770]  t5 : 0000000000000010 t6 : ffffffe080007a70
[  412.701380] status: 0000000200000120 badaddr: 0000000000000000 cause: 8000000000000005
[  440.148970] watchdog: BUG: soft lockup - CPU#0 stuck for 22s! [systemd-shutdow:1]
[  440.187022] Modules linked in: nft_ct nf_tables nf_conntrack nf_defrag_ipv6 nf_defrag_ipv4 ip_set rfkill nfnetlink sunrpc [last unloaded: ip_tables]
[  440.231263] CPU: 0 PID: 1 Comm: systemd-shutdow Tainted: G        W    L    5.10.6+ #26
[  440.270224] epc: ffffffe000202908 ra : ffffffe000202908 sp : ffffffe080007d40
[  440.307942]  gp : ffffffe0018416a8 tp : ffffffe080013580 t0 : ffffffd004a6c110
[  440.345530]  t1 : 0000000000000000 t2 : ffffffe000ea9d88 s0 : ffffffe080007d60
[  440.383088]  s1 : 0000000000000000 a0 : 0000000000000000 a1 : 0000000200000022
[  440.420798]  a2 : 0000000000000001 a3 : 0000000098dfb8ea a4 : 0000000000001869
[  440.458044]  a5 : 0000000000000000 a6 : ffffffe000743172 a7 : ffffffffad55ad55
[  440.495363]  s2 : 0000000028121969 s3 : ffffffe001620820 s4 : fffffffffee1dead
[  440.532358]  s5 : ffffffe0018440c0 s6 : a4f912efa6569000 s7 : 0000003fc5eeb7f0
[  440.569280]  s8 : 0000000000000000 s9 : 00000000c138fd04 s10: fffffffffffff000
[  440.606136]  s11: 0000002abc1f1768 t3 : 0000000000000001 t4 : 0000000000000002
[  440.642964]  t5 : 0000000000000010 t6 : ffffffe080007a70
[  440.677939] status: 0000000200000120 badaddr: 0000000000000000 cause: 8000000000000005
[  443.208975] rcu: INFO: rcu_sched self-detected stall on CPU
[  443.243942] rcu:     0-....: (5832 ticks this GP) idle=d1a/1/0x4000000000000002 softirq=13129/13129 fqs=2921
[  443.282851]  (t=6000 jiffies g=16713 q=7725)
[  443.316059] Task dump for CPU 0:
[  443.347759] task:systemd-shutdow state:R  running task     stack:    0 pid:    1 ppid:     0 flags:0x00000008
[  443.386342] Call Trace:
[  443.417400] [<ffffffe0002036be>] walk_stackframe+0x0/0xcc
[  443.451485] [<ffffffe000c5f586>] show_stack+0x40/0x4c
[  443.485119] [<ffffffe000239d46>] sched_show_task+0x146/0x16a
[  443.519378] [<ffffffe000c5fdc0>] dump_cpu_task+0x50/0x5a
[  443.553272] [<ffffffe000c60ace>] rcu_dump_cpu_stacks+0xb2/0xee
[  443.587703] [<ffffffe000280186>] rcu_sched_clock_irq+0x6da/0x898
[  443.622330] [<ffffffe000289f18>] update_process_times+0x78/0xa8
[  443.656931] [<ffffffe000298a32>] tick_sched_handle+0x36/0x68
[  443.691264] [<ffffffe000299066>] tick_sched_timer+0x62/0xaa
[  443.725471] [<ffffffe00028aa1e>] __hrtimer_run_queues+0x150/0x250
[  443.760151] [<ffffffe00028b55e>] hrtimer_interrupt+0xe2/0x230
[  443.794509] [<ffffffe000a4f816>] riscv_timer_interrupt+0x3c/0x46
[  443.829116] [<ffffffe000270bf6>] handle_percpu_devid_irq+0x8e/0x1b8
[  443.863972] [<ffffffe00026b3e6>] __handle_domain_irq+0x8a/0xee
[  443.898459] [<ffffffe000733452>] riscv_intc_irq+0x46/0x74
[  443.932396] [<ffffffe0002019d2>] ret_from_exception+0x0/0xc
[  443.966280] [<ffffffe000202908>] machine_restart+0x20/0x22
```

Or when trying to run `iperf3` test:

```
[riscv@fedora-starfive ~]$ iperf3 -c 192.168.40.248
Connecting to host 192.168.40.248, port 5201
[  5] local 192.168.40.80 port 50328 connected to 192.168.40.248 port 5201
[  519.166137] Unable to handle kernel paging request at virtual address 0000005f82ae7000
[  519.174427] Oops [#1]
[  519.176782] Modules linked in: nft_fib_inet nft_fib_ipv4 nft_fib_ipv6 nft_fib nft_reject_inet nf_reject_ipv4 nf_reject_ipv6 nft_reject nft_ct nft_chain_nat nf_tables ebtable_nat ebtable_broute ip6table_nat is
[  519.218766] CPU: 0 PID: 0 Comm: swapper/0 Tainted: G        W         5.10.6+ #26
[  519.226476] epc: ffffffdf82ae7000 ra : ffffffe000b49366 sp : ffffffe001603710
[  519.233804]  gp : ffffffe0018416a8 tp : ffffffe001610040 t0 : ffffffe0838a0120
[  519.241204]  t1 : 00000000000000a8 t2 : 000000000002d9d2 s0 : ffffffe001603760
[  519.246110] dw_mmc 10000000.sdio0: Unexpected interrupt latency
[  519.248671]  s1 : 0000000000000000 a0 : 0000000000000000 a1 : ffffffe0838a00e0
[  519.262138]  a2 : ffffffe001603760 a3 : 0000000000000000 a4 : ffffffdf82ae7000
[  519.269537]  a5 : ffffffe0832ea900 a6 : ffffffe083985d20 a7 : 0000000000000000
[  519.276936]  s2 : 0000000000000001 s3 : ffffffe0832ea900 s4 : ffffffe0838a00e0
[  519.284332]  s5 : ffffffe001603760 s6 : 0000000000000001 s7 : 0000000000000003
[  519.291792]  s8 : ffffffe0838a0000 s9 : ffffffe0838a0108 s10: 0000000000000001
[  519.299191]  s11: 000000000000fb00 t3 : 00000000000000c0 t4 : 000000000000007f
[  519.306596]  t5 : 0000000000000001 t6 : ffffffe0838a0198
[  519.312043] status: 0000000200000120 badaddr: 0000005f82ae7000 cause: 000000000000000c
[  519.320212] ---[ end trace 850a31549be57ce6 ]---
[  519.324990] Kernel panic - not syncing: Fatal exception in interrupt
[  519.331573] SMP: stopping secondary CPUs
[  519.335651] ---[ end Kernel panic - not syncing: Fatal exception in interrupt ]---
```

The next `iperf3` test worked, but with limited speed. The Ethernet speed is
one of the
[known limitations](https://wiki.seeedstudio.com/BeagleV-Getting-Started/#why-ethernet-speed-does-not-reach-up-to-1gbps)
of this beta SoC.

```
[riscv@fedora-starfive ~]$ iperf3 -c 192.168.40.248
Connecting to host 192.168.40.248, port 5201
[  5] local 192.168.40.80 port 39478 connected to 192.168.40.248 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.05   sec  22.5 MBytes   179 Mbits/sec    0    204 KBytes
[  5]   1.05-2.01   sec  21.2 MBytes   185 Mbits/sec    0    204 KBytes
[  5]   2.01-3.03   sec  22.5 MBytes   186 Mbits/sec    0    204 KBytes
[  5]   3.03-4.05   sec  22.5 MBytes   186 Mbits/sec    0    204 KBytes
[  5]   4.05-5.00   sec  21.2 MBytes   187 Mbits/sec    0    204 KBytes
[  5]   5.00-6.02   sec  22.5 MBytes   185 Mbits/sec    0    204 KBytes
[  5]   6.02-7.03   sec  22.5 MBytes   186 Mbits/sec    0    204 KBytes
[  5]   7.03-8.05   sec  22.5 MBytes   186 Mbits/sec    0    204 KBytes
[  5]   8.05-9.01   sec  21.2 MBytes   186 Mbits/sec    0    204 KBytes
[  5]   9.01-10.01  sec  22.5 MBytes   188 Mbits/sec    0    307 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.01  sec   221 MBytes   185 Mbits/sec    0             sender
[  5]   0.00-10.01  sec   221 MBytes   185 Mbits/sec                  receiver
```

### Next steps

We will continue experimenting with the BeagleV and hopefully contribute to
improving the software support in some way. We are mostly interested in the areas
of coreboot, edk2, U-Boot, Linux, and Yocto support. Please let us know in the
comments what kind of test or software support would you like to see on the
BeagleV.

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with
us](https://calendly.com/3mdeb/consulting-remote-meeting) or drop us email to
`contact<at>3mdeb<dot>com`. If you are interested in similar content feel free
to [sign up to our newsletter](http://eepurl.com/doF8GX).

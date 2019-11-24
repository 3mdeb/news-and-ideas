---
author: Piotr Król
layout: post
title: "How to run IoTivity with Zephyr on NXP FRDM-K64F"
date: 2017-04-17 21:45:24 +0200
comments: true
categories: iotivity zephyr rtos nxp frdm-k64f
---

As consulting company we know that each project should start with evaluation.
Checking and verifying what features are already existing in other projects,
especially those with permissive licenses is one of first step during
evaluation.

Recently we were asked to port IoTvity to yet unsupported operating system
dedicated to some specific platform. Precisely query was about
[IoTvity-Constrained](https://github.com/iotivity/iotivity-constrained).
IoTvity is reference implementation of [Open Interconnect Consortium specification](https://openconnectivity.org/resources/specifications), which now exist under
name Open Connectivity Foundation. Don't ask me why they mess so much with
names making it really hard to understand what is what.

This is our first touch of IoTvity, but at first glance I see couple things:

- CoAP is communication protocol protocol of choice
- total specification has almost 500 pages - reasonable economic output would
  be required to justify reading through those documents,
- there are multiple APIs available: C, C++ and Java
- Apache 2.0 license
- feature set is blasting and far from KISS philosophy

But let's try what we can do with IoTvity-constrained basic use case from
documentation.

## Trying IoTvity with Zephyr on QEMU

```
git clone https://github.com/iotivity/iotivity-constrained.git
git submodule update --init
```

I assume you followed Zephyr [Getting Started](https://www.zephyrproject.org/doc/getting_started/getting_started.html)
or read [my post about Zephyr](2017/03/18/development-environment-for-zephyros-on-nxp-frdm-k64f).

To test we need Zephyr `net-tools` first:

```
git clone https://gerrit.zephyrproject.org/r/p/net-tools.git
cd net-tools
make
./loop-socat.sh # in 1st terminal
sudo ./loop-slip-tap.sh # in 2nd terminal
```

Please note your TAP interface IPv6 address in output. Mine was:

```
tap0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.0.2.2  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::500f:89ff:fe44:6836  prefixlen 64  scopeid 0x20<link>
        inet6 2001:db8::2  prefixlen 64  scopeid 0x0<global>
        ether 52:0f:89:44:68:36  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

`fe80::500f:89ff:fe44:6836`. Then let's run Linux `simpleclient`:

Now we can compile and run IoTivity-constrained stack in Zephyr:

```
cd port/zephyr
source /path/to/zephyr-project/zephyr-env.sh
make pristine && make run
```

Last command will run Zephyr with IoTivity in QEMU. Precisely it will run
sample application from `apps/server_zephyr.c`. Leave it as it is and follow
further steps.

We can check RAM and ROM consumption, by using `make ram_report` and `make
rom_report`. Depending on perspective IoTivity-constrained take quite a lot of
memory RAM: 26.3KB and ROM: 63.6KB. It means it requires at least Cortex-M3
device.

Then IoTvity Linux examples should be compiled:

```
cd port/linux
make
```

As result you should have couple applications. We are interested in
`simpleclient`. By running it Zephyr should see traffic on network level:

```
./simpleclient
```

What result with this log from IoTvity server running in Zephyr:

```
oc_network_receive: received 52 bytes
oc_network_receive: incoming message: [fe80:0000:0000:0000:fce1:3bff:fe11:2094]:41018
```


## Trying IoTvity with Zephyr on NXP FRDM-K64F

First you need `python3-yaml` because without that you can get:

```
$ make pristine && make BOARD=frdm_k64f
Using /home/pietrushnic/storage/wdc/projects/2017/3mdeb/zephyr-project/boards/arm/frdm_k64f/frdm_k64f_defconfig as base
Merging /home/pietrushnic/storage/wdc/projects/2017/3mdeb/zephyr-project/kernel/configs/kernel.config
Merging prj.conf
warning: (BLUETOOTH_DEBUG_LOG && NET_BUF_LOG && NET_BUF_SIMPLE_LOG && NET_LOG) selects SYS_LOG which has unmet direct dependencies (PRINTK)
#
# configuration written to .config
#
make[1]: Entering directory '/home/pietrushnic/storage/wdc/projects/2017/3mdeb/zephyr-project'
make[2]: Entering directory '/home/pietrushnic/storage/wdc/projects/2017/3mdeb/iotivity-k64f/iotivity-constrained/port/zephyr/outdir/frdm_k64f'
  GEN     ./Makefile
scripts/kconfig/conf --silentoldconfig Kconfig
warning: (BLUETOOTH_DEBUG_LOG && NET_BUF_LOG && NET_BUF_SIMPLE_LOG && NET_LOG) selects SYS_LOG which has unmet direct dependencies (PRINTK)
warning: (BLUETOOTH_DEBUG_LOG && NET_BUF_LOG && NET_BUF_SIMPLE_LOG && NET_LOG) selects SYS_LOG which has unmet direct dependencies (PRINTK)
  Using /home/pietrushnic/storage/wdc/projects/2017/3mdeb/zephyr-project as source for kernel
  GEN     ./Makefile
  CHK     include/generated/version.h
  UPD     include/generated/version.h
  CHK     misc/generated/configs.c
  UPD     misc/generated/configs.c
  DTC     dts/arm/frdm_k64f.dts_compiled
  CHK     include/generated/generated_dts_board.h
Traceback (most recent call last):
  File "/home/pietrushnic/storage/wdc/projects/2017/3mdeb/zephyr-project/scripts/extract_dts_includes.py", line 6, in <module>
    import yaml
ImportError: No module named 'yaml'
/home/pietrushnic/storage/wdc/projects/2017/3mdeb/zephyr-project/./Kbuild:139: recipe for target 'include/generated/generated_dts_board.h' failed
make[3]: *** [include/generated/generated_dts_board.h] Error 1
/home/pietrushnic/storage/wdc/projects/2017/3mdeb/zephyr-project/Makefile:981: recipe for target 'prepare' failed
make[2]: *** [prepare] Error 2
make[2]: Leaving directory '/home/pietrushnic/storage/wdc/projects/2017/3mdeb/iotivity-k64f/iotivity-constrained/port/zephyr/outdir/frdm_k64f'
Makefile:177: recipe for target 'sub-make' failed
make[1]: *** [sub-make] Error 2
make[1]: Leaving directory '/home/pietrushnic/storage/wdc/projects/2017/3mdeb/zephyr-project'
/home/pietrushnic/storage/wdc/projects/2017/3mdeb/zephyr-project/Makefile.inc:82: recipe for target 'all' failed
make: *** [all] Error 2
```

To fulfill requirements you can use:

```
sudo apt install python3-yaml
```



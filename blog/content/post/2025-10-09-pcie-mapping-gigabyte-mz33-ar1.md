---
title: 'Mapping and initializing PCI Express ports on Gigabte MZ33-AR1'
abstract: 'Another post about the Gigabyte MZ33-AR1 porting effort progress.
           This time, we add definitions for PCI Express initialization, and
           validate BMC KVM VGA and keyboard. Also, improvements to HCL
           reporting and data dumping on AMD systems have been made.'
cover: /covers/gigabyte_mz33_ar1.webp
author:
  - michal.zygowski
  - mateusz.kusiak
layout: post
published: true    # if ready or needs local-preview, change to: true
date: 2025-10-10    # update also in the filename!
archives: "2025"

tags:
 - coreboot
 - firmware
 - AMD
 - Turin
 - MZ33-AR1
 - open-source
categories:
 - Firmware

---

## Introduction

Continuing the process of I/O buses initialization from the previous post. In
this blog post, I will explain how PCI Express buses can be initialized on
modern server systems based on the AMD Turin processor family and the Gigabyte
MZ33-AR1.

If you haven't read previous blog posts, especially the [SATA and USB
initialization
post](https://blog.3mdeb.com/2025/2025-09-12-sata-usb-port-mapping-gigabyte-mz33-ar1/),
I encourage you to [read them](https://blog.3mdeb.com/tags/mz33-ar1/) in case
you have missed some. Lots of concepts explained earlier will be used to
describe the process of PCI Express initialization.

## Mapping of PCI Express ports

Mapping of PCI Express ports to hardware lanes is the prerequisite for porting
the configuration to any open-source firmware. While on Intel platforms it is
pretty straightforward, each PCI Express root port has its unique PCI device
and function, on AMD systems, the matter is a bit more complicated.

Modern AMD systems have multiple SERDES with 16 lanes each. Each SERDES can
bifurcate into various configurations to support up to 9 PCI Express root
ports, e.g., 1x8 and 8x1. Each bifurcated root port needs an assigned bridge
by the BIOS, where the endpoint devices could be enumerated. The assignment of
bridges and lanes has to follow a specific set of rules. But before that,
let's try to map the port to hardware lanes.

Before we can approach the mapping, we will need special cables and adapters
to populate the PCI Express slots and connectors:

- [Dual MCIO(74pin) 8i to PCIe5.0 X16 Gen5 Male Adapter](https://store.10gtek.com/10gtek-2x-mcio-74pin-8i-to-pcie-x16-adapter-gen5-pcie5-0/p-29147)
- [Dual MCIO 8i to PCIe5.0 X16 Gen5 female Adapter](https://store.10gtek.com/mcio-pcie-gen5-device-adapter-2-8i-to-x16/p-29134)
- [MCIO to MCIO 8i Cable](https://store.10gtek.com/mcio-to-mcio-8x-cable-sff-ta-1016-mini-cool-edge-io-straight-pcie-gen5-85-ohm-0-2m-0-75-m-80cm/p-29148)

Thanks to these cables and adapters, we will be able to plug regular PCI
Express expansion cards. I have used an MSI GeForce GT1030 card in the MCIO 8i
to a PCIe5.0 X16 female adapter as an endpoint device.

![GPU card via MCIO](/img/mcio_gpu.jpg)

We will also use the AMD XIO tool for Linux to help with the mapping. This
utility provided by AMD to its partners is for high-speed PHY diagnostic
purposes. It is able to show which SERDES and ports the given bridge uses. So
without any device populated in the PCI Express or MCIO slots yet, we get the
following output:

```text
sudo ./amdxio -list -pcie -ports
AMDXIO Version 5.1.75.2
Turin SBDF:0:0:18.0 Socket:0 Die:0
 1.PCIe Bridge               : 0:40:1.1
 Speed                     : 16 GT/s
 Width                     : x4
 Secondary Bus             : 0x41
 Subordinate Bus           : 0x41
 PCIe Core & Func          : PCIE1_nbio1 0x0
 SERDES & Port             : G2 0
 Phy & Version             :
 Port Type                 : Root Port
 LC_STATE                  : N/A(0x3f)
 Logical to SERDES Lane    :
 Logical to Controller Lane:
 Upstream Link:
 0:40:1.1
 Downstream Link(s):
 0:40:1.1-->0:41:0.0


 2.PCIe Bridge               : 0:a0:3.1
 Speed                     : 8 GT/s
 Width                     : x4
 Secondary Bus             : 0xa1
 Subordinate Bus           : 0xa1
 PCIe Core & Func          : PCIE5_nbio0 0x0
 SERDES & Port             : P5 0
 Phy & Version             :
 Port Type                 : Root Port
 LC_STATE                  : N/A(0x3f)
 Logical to SERDES Lane    :
 Logical to Controller Lane:
 Upstream Link:
 0:a0:3.1
 Downstream Link(s):
 0:a0:3.1-->0:a1:0.0
 0:a0:3.1-->0:a1:0.1


 3.PCIe Bridge               : 0:a0:3.3
 Speed                     : 5 GT/s
 Width                     : x1
 Secondary Bus             : 0xa2
 Subordinate Bus           : 0xa3
 PCIe Core & Func          : PCIE5_nbio0 0x2
 SERDES & Port             : P5 2
 Phy & Version             :
 Port Type                 : Root Port
 LC_STATE                  : N/A(0x3f)
 Logical to SERDES Lane    :
 Logical to Controller Lane:
 Upstream Link:
 0:a0:3.3
 Downstream Link(s):
 0:a0:3.3-->0:a2:0.0-->0:a3:0.0
```

The tool gives us the PCI address of the bridge, the SERDES, and its port.
Pretty much everything we need. Unfortunately, the `Logical to SERDES Lane`
and `Logical to Controller Lane` are empty, but I hoped it could also give us
some useful information about lane mapping. If the information is not present,
we will have to find that information via other means.

By looking at `lspci -tvvnn` output, we can match the bridges to the devices
they connect to:

```text
 +-[0000:40]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device [1022:153a]
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Device [1022:153b]
 |           +-01.0  Advanced Micro Devices, Inc. [AMD] Device [1022:153d]
 |           +-01.1-[41]----00.0  Kingston Technology Company, Inc. KC3000/FURY Renegade NVMe SSD E18 [2646:5013]
...
 +-[0000:a0]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device [1022:153a]
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Device [1022:153b]
 |           +-01.0  Advanced Micro Devices, Inc. [AMD] Device [1022:153d]
 |           +-02.0  Advanced Micro Devices, Inc. [AMD] Device [1022:153d]
 |           +-03.0  Advanced Micro Devices, Inc. [AMD] Device [1022:153d]
 |           +-03.1-[a1]--+-00.0  Broadcom Inc. and subsidiaries BCM57416 NetXtreme-E Dual-Media 10G RDMA Ethernet Controller [14e4:16d8]
 |           |            \-00.1  Broadcom Inc. and subsidiaries BCM57416 NetXtreme-E Dual-Media 10G RDMA Ethernet Controller [14e4:16d8]
 |           +-03.3-[a2-a3]----00.0-[a3]----00.0  ASPEED Technology, Inc. ASPEED Graphics Family [1a03:2000]
```

So we already see that:

- G2 port 0 with four lanes maps to an on-board M.2 slot with the NVMe disk
- P5 port 0 with four lanes maps to the on-board Ethernet devices
- P5 port 2 with one lane maps to the BMC PCI Express link for VGA

When the GT1030 card was plugged into the `PCIE_3` slot via the adapters and
cable, a new bridge appeared in the AMD XIO output:

```text
 4.PCIe Bridge               : 0:e0:1.3
 Speed                     : 2.5 GT/s
 Width                     : x4
 Secondary Bus             : 0xe1
 Subordinate Bus           : 0xe1
 PCIe Core & Func          : PCIE0_nbio0 0x2
 SERDES & Port             : P0 2
 Phy & Version             :
 Port Type                 : Root Port
 LC_STATE                  : N/A(0x3f)
 Logical to SERDES Lane    :
 Logical to Controller Lane:
 Upstream Link:
 0:e0:1.3
 Downstream Link(s):
 0:e0:1.3-->0:e1:0.0
 0:e0:1.3-->0:e1:0.1
```

We see that `PCIE_3` slot maps to P0. The port number can be ignored since the
slot has to occupy all 16 lanes. Now, when connecting the GPU to the MCIO
connector, e.g., `U2_P0_G3B`, we get the following output:

```text
 2.PCIe Bridge               : 0:60:1.3
 Speed                     : 2.5 GT/s
 Width                     : x4
 Secondary Bus             : 0x61
 Subordinate Bus           : 0x61
 PCIe Core & Func          : PCIE2_nbio1 0x2
 SERDES & Port             : G3 2
 Phy & Version             :
 Port Type                 : Root Port
 LC_STATE                  : N/A(0x3f)
 Logical to SERDES Lane    :
 Logical to Controller Lane:
 Upstream Link:
 0:60:1.3
 Downstream Link(s):
 0:60:1.3-->0:61:0.0
 0:60:1.3-->0:61:0.1
```

Judging from above, we deduce that `U2_P0_G3B` maps to G3 port 2 and higher.
Because the MCIO connector has eight lanes, but the GPU uses only four, the G3
port 3 is currently not occupied. It is also important to note that the
Gigabyte BIOS supports only `x4x4` bifurcation of the MCIO connectors. So all
devices appearing in these MCIO connectors will always occupy only one of two
ports on the given SERDES.

To complete the mapping, we have to plug our GPU into all possible PCIe slots
and MCIO connectors and gather the results. I have gathered full mapping
results from AMD XIO for the reference
[here](https://paste.dasharo.com/?0ca2ddb26e01f1bc#E1j5ULZM4Z2SmbaucLK8CT4nhR7BRb3PTuEogTwGJBvx).

In short, we have the following map:

- G2 port 0 with four lanes maps to an on-board M.2 slot with the NVMe disk
- P5 port 0 with four lanes maps to on-board Ethernet devices
- P5 port 2 with one lane maps to the BMC PCI Express link for VGA
- G2 port 2 with four lanes maps to `U2_P0_G2A` MCIO connector (another four
  lanes got G2 port 3 as well, lanes are reversed)
- G0 port 3 with four lanes maps to `U2_P0_G0A` MCIO connector (another four
  lanes got G0 port 2 as well, lanes are reversed)
- G0 port 1 with four lanes maps to `U2_P0_G0B` MCIO connector (another four
  lanes got G0 port 0 as well, lanes are reversed)
- G3 port 2 with four lanes maps to `U2_P0_G3B` MCIO connector (another four
  lanes got G3 port 3 as well)
- G3 port 0 with four lanes maps to `U2_P0_G3A` MCIO connector (another four
  lanes got G0 port 1 as well)
- P3 port 1 with 4 lanes map to `PCIE_7` (each 4 lanes map to P3 port
  0/1/2/3 respectively)
- P2 port 2 with 4 lanes map to `PCIE_6` (each 4 lanes map to P2 port
  0/1/2/3 respectively)
- P1 port 2 with 4 lanes map to `PCIE_4` (each 4 lanes map to P2 port
  0/1/2/3 respectively)
- P0 port 2 with 4 lanes map to `PCIE_3` (each 4 lanes map to P1 port 0/1/2/3
  respectively)

By switching the cables when mapping `PCIE_n` ports, we can get different
results due to lane swapping. Also, some of the ports are internally reversed,
which is why the devices appear on different SERDES ports.

The above map fulfills the following milestone:

- Task 3. Hardware-topology discovery - Milestone c. PCIe lane map

You may already see how complicated it gets once the lane reversals and cable
swapping come into play. We will demystify it in the next step, which is PCI
Express port configuration.

## PCI Express configuration

Now that the mapping is complete, we can start configuring the slots and
connectors. We will do it in a similar fashion as for SATA, but we of course
need to change the interface type from SATA to PCIE. During the mapping, I
mentioned that we miss the `Logical to SERDES Lane` and `Logical to Controller
Lane` information. Thankfully, we can find that information in the [OpenSIL
code
itself](https://github.com/openSIL/openSIL/blob/9856465a3de5475bb8ab0b58c5071e5a1a03b336/xUSL/Nbio/Brh/PkgTypeFixups.c#L16):

```C
static const uint8_t StartDxioLaneSP5 [] = {
  0, // P0
  96, // G0
  48, // P2
  112, // G2
  64, // G1
  32, // P1
  80, // G3
  16 // P3
};

static const uint8_t CoreReversedSP5 [] = {
  0, // P0
  1, // G0
  1, // P2
  0, // G2
  1, // G1
  0, // P1
  0, // G3
  1 // P3
};
```

These arrays tell us which ports are internally reversed in hardware and what
the starting lanes are. This is enough to write down the code we need to
initialize the ports. Well, almost... There is a set of rules explained in the
AMD documentation one has to follow to allocate PCIe bridges properly:

- Bridges should be allocated starting with the port with the widest link
- The lane numbers should be assigned to bridges in ascending order, except
  for reversed links
- For reversed links, the bridges should use descending lane numbers, e.g.,
  for P3 the ports should start from 31 down to 16
- If P4 and P5 links have the same width, prioritize P5
- P4/P5 links have lane numbers 128-135
- WAFL links can only be on lanes 132 and 133 and occupy a function
- Lane reversal is handled in the opposite order
- Each bridge of G0-3 and P0-3 can only be allocated to PCI addresses 1.1-1.7
  and 2.1-2.2 (up to 9 root ports)
- Bridges of P4/P5 links can only be allocated to PCI addresses 3.1-3.7
  and 4.1 (up to 8 root ports)

From the previous post, we know that:

- PCI domain 7 - P0 link
- PCI domain 4 - G1 link
- PCI domain 5 - P4, P5 and G0 link
- PCI domain 6 - P1 link
- PCI domain 0 - P2 link
- PCI domain 1 - G3 link
- PCI domain 2 - G2 link
- PCI domain 3 - P3 link

With that in mind, we can easily prepare the lane numbers and the PCI device
addresses for all the slots and connectors:

- M.2 NVMe G2 port 0 -> domain 2 device 1.1, 4 lanes from the
  start of G0:
  - start lane 112
  - end lane 115
- Ethernet P5 port 0 -> domain 5 device 3.1, 4 lanes from the
  start of P5:
  - start lane 128
  - end lane 131
- BMC VGA P5 port 2 -> this is tricky, there is a gap between Ethernet and BMC
  VGA, so the start lane number for VGA may be only 134, because WAFL links
  are at lanes 132-133 and occupy a function, so BMC VGA will be at domain 5
  device 3.3, 6th lane from the start:
  - start lane 134
  - end lane 134
- `U2_P0_G2A` G2 x4x4 -> domain 2 devices 1.3 and 1.4, eight lanes from the middle
 of G2, four lanes per device:
  - start lane 120 and 124 respectively
  - end lane 123 and 127 respectively
- `U2_P0_G0A` G0 x4x4 -> domain 2 devices 1.1 and 1.2. 8 lanes from the middle
 of G0, because the core is reversed, four lanes per device:
  - start lane 108 and 104 respectively
  - end lane 111 and 107 respectively
- `U2_P0_G0B` G0 x4x4 -> domain 2 devices 1.2 and 1.1. 8 lanes from the start
 of G0, because the core is reversed, four lanes per device:
  - start lane 100 and 96 respectively
  - end lane 103 and 99 respectively
- `U2_P0_G3A` and `U2_P0_G3B` are already configured for SATA, thus skipping
  them. If they were to be configured as PCI Express, then the code should
  allocate lanes 80-95 (four lanes each port) for PCIe on bridges 1.1-1.4 on
  domain 3 (not domain 1 as written above, apparently the P3 and G3 are swapped
  and after initialization, the root bridges appear in different PCI domains)
- `PCIE_7` P3 x4x4x4x4 -> domain 1 (not domain 3, mind the swap) devices
 1.1-1.4, 4 lanes each device, core reversed:
  - start lane 28, 24, 20, 16 respectively
  - end lane 31, 27, 23, 19 respectively
- `PCIE_6` P2 x4x4x4x4 -> domain 0 devices 1.1-1.4, 4 lanes each device, core
  reversed:
  - start lane 60, 56, 52, 48 respectively
  - end lane 63, 59, 55, 51 respectively
- `PCIE_4` P1 x4x4x4x4 -> domain 6 devices 1.1-1.4, 4 lanes each device:
  - start lane 32, 36, 40, 44 respectively
  - end lane 35, 39, 43, 47 respectively
- `PCIE_3` P0 x4x4x4x4 -> domain 7 devices 1.1-1.4, 4 lanes each device:
  - start lane 0, 4, 8, 12 respectively
  - end lane 3, 7, 11, 15 respectively

The patches that initialize those ports with the above lane numbers are linked
below:

- [Initialization of internal PCIe devices](https://review.coreboot.org/c/coreboot/+/89211)
- [Initialization of PCIe slots and MCIO connectors](https://review.coreboot.org/c/coreboot/+/89474)

## PCIe validation

Now that we have the PCIe configuration coded, it's time to validate if it
works properly. To validate every possible port described in the coreboot's
devicetree, we will be using another adapter, this time a [PCIe x16 to 4x NVMe
M.2
slot](https://www.glotrends-store.com/products/pa41-quad-m2-nvme-to-pcie-4x16-adapter-raid):

![4xNVMe via PCIe and MCIO adapters](/img/mcio_disks.jpg)

We will be plugging four different disks into this adapter and then plugging
it into every MCIO and PCIe slot to check if the disks appear in the firmware
and possibly work in the operating system. For the past few weeks, we have
been intensively working to get some operating system booting, and we finally
succeeded in running Xen on top of a Linux distribution. Unfortunately, bare
metal Linux still faces problems during CPU bring-up due to spurious
interrupts happening during AP wake, causing the memory to be corrupted. On
the day of writing this post, there are [over 60
patches](https://review.coreboot.org/q/topic:turin_poc) porting support of the
Turin processor family and fixing various bugs in coreboot. We will be going
through those patches in subsequent posts while explaining the fulfillment of
other milestones.

But let's get back to PCIe testing. We have four different NVMe disks:

- KINGSTON SKC3000S512G (actually two of them, one in the on-board M.2 slot,
 second in the adapter)
- KINGSTON SNV2S500G
- Samsung SSD 980 1TB
- GIGABYTE GP-GSM2NE3256GNTD

To test whether the disks work in firmware, I simply checked if they appear in
the boot menu (of course, they need to have an EFI partition present with a
bootable OS bootloader for that to work). And in the first `PCIE_3` we got:

![Boot menu](/img/mz33-ar1_boot_menu.png)

By the way, this picture is done with the BMC KVM VGA opened in the BMC
management console GUI, which proves that BMC VGA works. The firmware also
accepts virtual keyboard input from BMC, because I could freely browse the
setup menu. And here is a sample image from booting [Qubes
OS](https://www.qubes-os.org/):

![Boot menu](/img/mz33-ar1-qubes.png)

However, for validation purposes, it is easier to boot Ubuntu with Xen
hypervisor. I have checked the lspci output to see whether the disks are
detected (also on-board devices as well):

```bash
 +-[0000:40]-+-00.0  Advanced Micro Devices, Inc. [AMD] Turin Root Complex [1022:153a]
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Turin IOMMU [1022:153b]
 |           +-01.0  Advanced Micro Devices, Inc. [AMD] Turin PCIe Dummy Host Bridge [1022:153d]
 |           +-01.1-[41]----00.0  Kingston Technology Company, Inc. KC3000/FURY Renegade NVMe SSD [E18] [2646:5013]
...
 +-[0000:a0]-+-00.0  Advanced Micro Devices, Inc. [AMD] Turin Root Complex [1022:153a]
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Turin IOMMU [1022:153b]
 |           +-01.0  Advanced Micro Devices, Inc. [AMD] Turin PCIe Dummy Host Bridge [1022:153d]
 |           +-02.0  Advanced Micro Devices, Inc. [AMD] Turin PCIe Dummy Host Bridge [1022:153d]
 |           +-03.0  Advanced Micro Devices, Inc. [AMD] Turin PCIe Dummy Host Bridge [1022:153d]
 |           +-03.1-[a1]--+-00.0  Broadcom Inc. and subsidiaries BCM57416 NetXtreme-E Dual-Media 10G RDMA Ethernet Controller [14e4:16d8]
 |           |            \-00.1  Broadcom Inc. and subsidiaries BCM57416 NetXtreme-E Dual-Media 10G RDMA Ethernet Controller [14e4:16d8]
 |           +-03.3-[a2-a3]----00.0-[a3]----00.0  ASPEED Technology, Inc. ASPEED Graphics Family [1a03:2000]
...
 \-[0000:e0]-+-00.0  Advanced Micro Devices, Inc. [AMD] Turin Root Complex [1022:153a]
             +-00.2  Advanced Micro Devices, Inc. [AMD] Turin IOMMU [1022:153b]
             +-00.3  Advanced Micro Devices, Inc. [AMD] Turin RCEC [1022:153c]
             +-01.0  Advanced Micro Devices, Inc. [AMD] Turin PCIe Dummy Host Bridge [1022:153d]
             +-01.1-[e1]----00.0  Phison Electronics Corporation PS5013-E13 PCIe3 NVMe Controller (DRAM-less) [1987:5013]
             +-01.2-[e2]----00.0  Kingston Technology Company, Inc. KC3000/FURY Renegade NVMe SSD [E18] [2646:5013]
             +-01.3-[e3]----00.0  Kingston Technology Company, Inc. NV2 NVMe SSD [E21T] (DRAM-less) [2646:5019]
             +-01.4-[e4]----00.0  Samsung Electronics Co Ltd NVMe SSD Controller 980 (DRAM-less) [144d:a809]
```

In the above output, we see that all internal devices and all our disks are
detected. To check whether Ethernet actually works, I have pinged
`https://nlnet.nl/`. If the IP address has been assigned and ping works, then
it means the interface is functional:

```bash
ubuntu@ubuntu:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: enxeed55e65a9e6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 1000
    link/ether ee:d5:5e:65:a9:e6 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::7c7b:8783:f07d:5fcb/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: enp161s0f0np0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 10:ff:e0:ab:c8:b1 brd ff:ff:ff:ff:ff:ff
    altname enx10ffe0abc8b1
    inet 192.168.10.200/24 brd 192.168.10.255 scope global dynamic noprefixroute enp161s0f0np0
       valid_lft 43076sec preferred_lft 43076sec
    inet6 fe80::5cf9:970f:7883:182b/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
4: enp161s0f1np1: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 10:ff:e0:ab:c8:b2 brd ff:ff:ff:ff:ff:ff
    altname enx10ffe0abc8b2
5: enX1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
    altname enx525400123456
    inet6 fe80::743a:3e12:2558:c244/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
ubuntu@ubuntu:~$ ping nlnet.nl
PING nlnet.nl (5.255.103.93) 56(84) bytes of data.
64 bytes from 5.255.103.93: icmp_seq=1 ttl=57 time=28.6 ms
64 bytes from 5.255.103.93: icmp_seq=2 ttl=57 time=28.4 ms
64 bytes from 5.255.103.93: icmp_seq=3 ttl=57 time=28.4 ms
64 bytes from 5.255.103.93: icmp_seq=4 ttl=57 time=28.4 ms
64 bytes from 5.255.103.93: icmp_seq=5 ttl=57 time=28.5 ms
64 bytes from 5.255.103.93: icmp_seq=6 ttl=57 time=28.4 ms
64 bytes from 5.255.103.93: icmp_seq=7 ttl=57 time=28.5 ms
^C
--- nlnet.nl ping statistics ---
7 packets transmitted, 7 received, 0% packet loss, time 6008ms
rtt min/avg/max/mdev = 28.361/28.438/28.625/0.085 ms
```

Of course, it wouldn't be possible without work-in-progress patches with PCI
interrupt routing and many others, so keep it in mind. We merely validate
whether the physical layer of the PCIe initialization is done properly by
OpenSIL.

Additionally, to validate whether the disks are working as well, I used
`fdisk` to list the partitions on the disks. If the partitions are visible,
then it means the disks are working properly (one of the disks was actually
empty, fresh from the box):

```bash
sudo fdisk -l
Disk /dev/nvme0n1: 476.94 GiB, 512110190592 bytes, 1000215216 sectors
Disk model: KINGSTON SKC3000S512G
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/nvme1n1: 476.94 GiB, 512110190592 bytes, 1000215216 sectors
Disk model: KINGSTON SKC3000S512G
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: D43AEE23-B6A0-4D2E-BA86-58E0B2EA1564

Device             Start        End   Sectors   Size Type
/dev/nvme1n1p1      2048    2203647   2201600     1G EFI System
/dev/nvme1n1p2   2203648  351508479 349304832 166.6G Linux filesystem
/dev/nvme1n1p3 351508480  353605631   2097152     1G Linux filesystem
/dev/nvme1n1p4 353605632 1000214527 646608896 308.3G Linux filesystem


Disk /dev/nvme3n1: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: KINGSTON SNV2S500G
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: B999BC86-D024-4B0B-BAC3-EB4F3F2942CB

Device             Start       End   Sectors   Size Type
/dev/nvme3n1p1      2048   1026047   1024000   500M Windows recovery environment
/dev/nvme3n1p2   1026048   1558527    532480   260M EFI System
/dev/nvme3n1p3   1558528   1820671    262144   128M Microsoft reserved
/dev/nvme3n1p4   1820672 205287423 203466752    97G Microsoft basic data
/dev/nvme3n1p5 205287424 206618623   1331200   650M Windows recovery environment
/dev/nvme3n1p6 206620672 356907007 150286336  71.7G Microsoft basic data
/dev/nvme3n1p7 356907008 976771071 619864064 295.6G Linux filesystem


Disk /dev/nvme4n1: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
Disk model: Samsung SSD 980 1TB
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 16384 bytes / 131072 bytes
Disklabel type: gpt
Disk identifier: 18526E54-73FD-46A6-8CC9-5B2C557830B4

Device           Start        End    Sectors   Size Type
/dev/nvme4n1p1    2048    1230847    1228800   600M EFI System
/dev/nvme4n1p2 1230848    3327999    2097152     1G Linux extended boot
/dev/nvme4n1p3 3328000 1953523711 1950195712 929.9G Linux filesystem


Disk /dev/nvme2n1: 238.47 GiB, 256060514304 bytes, 500118192 sectors
Disk model: GIGABYTE GP-GSM2NE3256GNTD
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 04328242-A0A5-4839-B08D-E3CD794086E5

Device             Start       End   Sectors   Size Type
/dev/nvme2n1p1      2048   2000895   1998848   976M EFI System
/dev/nvme2n1p2   2000896 474320895 472320000 225.2G Linux filesystem
/dev/nvme2n1p3 474320896 500117503  25796608  12.3G Linux swap
```

We have to repeat this test for all possible slots and connectors. The full
validation output from `lspci` and `fdisk` for all slots and connectors is
available
[here](https://paste.dasharo.com/?3819dec9ee88816e#8xmnsojwVtCeR1APA9uNv8AhYzAFKs7aSFvVzkUQEy3H).

This concludes the PCIe initialization, which fulfills the following milestones:

- Task 4. Port configuration in coreboot - Milestone b. PCIe devicetree descriptors
- Task 5. Platform-feature enablement - Milestone b. BMC VGA enablement
- Task 5. Platform-feature enablement - Milestone c. BMC KVM enablement

## HCL and data dumping improvements on AMD systems

In the early phases of porting the Gigabyte MZ33-AR1 board, we have improved
[PSPTool](https://github.com/PSPReverse/PSPTool) to be able to parse Zen5
images and be able to construct the blobs properly to build a bootable image.
We are further improving the parsing with a couple of bug fixes and displaying
additional information about the images. In short, we have added proper
distinguishing of the blobs of the same type but for different CPU variants by
displaying the instance and subprogram fields. These fields, along with the
type, uniquely define the purpose of the binary. Previously, the tool assumed
that the type is longer than 8 bits and included the subprogram fields in the
type parsing, which was not correct. Additionally, we fixed displaying APOB
binaries, which were assumed to be duplicates due to not having any size or
offset in flash. As a bonus, we also implemented parsing the microcode files
to display their patch level and release date. It should help discover and
analyze how vendors care about security by updating the microcode in their
firmware images. Sample output of the improved PSPTool parsing the Gigabyte
MZ33-AR1 version R11_F08 vendor BIOS image is available
[here](https://paste.dasharo.com/?0ebe64305ace7e4d#FombLG2QkXCygwiJeVqG8rwu6tcReDVXan3o443xrQY6).
For more details about the changes, see the commit messages of these two PRs:

- [Parsing improvements](https://github.com/PSPReverse/PSPTool/pull/68)
- [Parsing improvements v2](https://github.com/PSPReverse/PSPTool/pull/70)
- [Handle address mode](https://github.com/PSPReverse/PSPTool/pull/71)

The above pull request concludes the planned effort to improve the PSPTool,
fulfilling the milestone:

- Task 7. Community tooling contributions - Milestone b. Upstream PSPTool
 parsing improvements

To assist with porting AMD hardware to coreboot, we also implemented a tool
specific to AMD CPUs that dumps useful information for developers. It serves
the same purpose as [coreboot's
inteltool](https://github.com/coreboot/coreboot/blob/main/util/inteltool/description.md),
but works on AMD systems only, of course. The sources of the tool have been
sent to upstream for review and can be found
[here](https://review.coreboot.org/c/coreboot/+/89492).

The output of the `amdtool -a` (dump all possible information) command can be found
[here](https://paste.dasharo.com/?8fdb16993d4e62b2#CWJwtfFHuJhk53CrtoGPYeq9inLxrTWqohNwto5qihQZ).

This fulfills the milestone:

- Task 7. Community tooling contributions - Milestone c. Introduce amdtool for
 platform data dumps

However, it would be best to use both PSPTool and amdtool as part of an HCL
report. For that purpose, we have integrated these utilities into the Dasharo
HCL report.

```log
CRITICAL ERROR: cannot dump firmware!
Firmware dump not found, but found user-supplied external binary.
[...]
[OK]  Intel configuration registers
[OK]  AMD configuration registers
[...]
[ERROR]  Firmware image
[UNKNOWN] PSP firmware entries
[...]
```

A known limitation of stock firmware is that it does not provide access to the
internal programmer; therefore, the firmware cannot be dumped. This is why a
workaround has been introduced, allowing users to supply their own firmware
binaries for HCL analysis. This has been described in
[DTS documentation](https://docs.dasharo.com/dasharo-tools-suite/documentation/features/#hcl-report-using-an-external-firmware-binary).

The status of `PSPTool` is reported as unknown, due to limitations with the
current tool implementation. PSPTool under most circumstances does not produce
errors, just warnings. Moreover, we established that it returns a success status
when run on Intel firmware binaries, as well as mockup binaries made of zeros.
Despite the returned status, the tool works, which is proven by the logs.

```log
# cat psptool.log
+-----+------+-----------+---------+------------------------------+
| ROM | Addr |    Size   |   FET   |            AGESA             |
+-----+------+-----------+---------+------------------------------+
|  0  | 0x0  | 0x1000000 | 0x20000 | AGESA!V9 GenoaPI-SP5 1.0.0.C |
+-----+------+-----------+---------+------------------------------+
+--+-----------+---------+------------+-------+---------------------+
|  | Directory |   Addr  | Generation | Magic | Secondary Directory |
+--+-----------+---------+------------+-------+---------------------+
|  |     0     | 0x41000 |    None    |  $PSP |       0x311000      |
+--+-----------+---------+------------+-------+---------------------+
[...]
```

The logs also showcase that `amdtool` works.

```log
# cat amdtool.log
CPU: ID 0xb00f21, Processor Type 0x0, Family 0x1a, Model 0x2, Stepping 0x1
Northbridge: 1022:153a (Turin Root Complex)
Southbridge SMBus: 1022:790b rev 71 (FCH SMBus Controller)
Southbridge LPC: 1022:790e rev 51 (FCH LPC Bridge)

========== LPC =========

0x0000: 0x790e1022 (ID)
0x0004: 0x000f     (CMD)
[...]
```

The pre-release DTS version with all tools integrated can be downloaded from
[this link](https://github.com/Dasharo/meta-dts/releases/tag/v2.7.2-rc1).

This fulfills the milestone:

- Task 7. Community tooling contributions - Milestone a. Integrate PSPTool
 into coreboot HCL pipeline

## Summary

Due to the huge dedication of the team, we are at the stage where we can boot
an operating system. This lets us perform the validation more extensively and
detect bugs more easily. Of course, there are some bugs still to be solved.
More exciting (and complicated) stuff is yet to come, so stay tuned for the
next blog posts.

Huge kudos to the NLnet Foundation for sponsoring the
[project](https://nlnet.nl/project/Coreboot-Phoenix/).

![NLnet](/covers/nlnet-logo.png)

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help. [Schedule
a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to sign up for our newsletter:

{{< subscribe_form "dbbf5ff3-976f-478e-beaf-749a280358ea" "Subscribe" >}}

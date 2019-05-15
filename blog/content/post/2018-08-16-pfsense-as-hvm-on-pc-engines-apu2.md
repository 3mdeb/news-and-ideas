---
title: Xen HVM guests on PC Engines apu2
author: piotr.krol
layout: post
published: true
date: 2018-08-16
year: "2018"

tags:
  - xen
  - iommu
  - coreboot
categories:
  - Firmware
  - OS Dev
---

Continuing blog post series around Xen and IOMMU enabling in coreboot we
are reaching a point in which some features seem to work correctly on top of [recent patch series in firmware](https://review.coreboot.org/#/c/coreboot/+/27602/).

What we can do at this point is PCI passthrough to guest VMs. Previously trying
that on Xen caused problems:

* random hangs
* firmware cause Linux kernel booting issues (hang during boot)
* IOMMU disabled - unable to use PCI passthrough

Now we can see something like that in dom0:

```
modprobe xen-pciback
root@apu2:~# xl pci-assignable-add 02:00.0
[  136.778839] igb 0000:02:00.0: removed PHC on enp2s0
[  136.887658] pciback 0000:02:00.0: seizing device
[  136.888115] Already setup the GSI :32
root@apu2:~# xl pci-assignable-list
0000:02:00.0
```

Of course, after above operation, we can't access `enp2s0` in dom0. Having
the ability to set pass through we can think about creating pfSense HVM and
having isolation between various roles on our PC Engines apu2 router.

What are the pros of that solution:

* price - this is DIY solution where you just pay price of apu2 and spent some
  time with setup, of course, you can also pay for that to companies like 3mdeb,
  what should be still cheaper than other commercial solutions - this makes it
  attractive to SOHO
* scalability - you can decide how much resources of your router you want to
  give to the firewall; the remaining pool can be used for other purposes this
	saves you a couple of cents on the energy bill
* security - even if attacker get access to pfSense (very unlikely), escaping
  VM and gaining full control and persistence on hardware is not possible
	without serious Xen bug, on the other hand, bugs in on the other VMs (e.g.
	network storage, web application, 3rd party software) cannot be leveraged to
	gain control over the router
* virtual machine - VMs by itself have a bunch of advantages, somewhere
  mentioned above, but other are easier migration, lower cost to introduce in
  existing network

# Required components

* PC Engines apu2c4
* `pxe-server` - or other means of booting Debian based Dom0 with Xen 4.8 and
  Linux 4.14.59 (or any other modern kernel which has correct support enabled
	as in [this kernel config](https://github.com/pcengines/apu2-documentation/blob/6b6dc7d1a52f0550aa237746fc236ba07ba9c747/configs/config-4.14.59))
* 2 connected Ethernet ports
* some storage (min 10GB)

# Prepare Xen

I'm using `apic=verbose,debug iommu=verbose,debug` for better visibility of Xen
configuration. More to that we need some preparation in Dom0:

## Storage

```
pvcreate /dev/sda1
vgcreate vg0 /dev/sda1
lvcreate -npfsense -L10G vg0
```

## PCI passthrough

```
modprobe xen-pciback
xl pci-assignable-add 02:00.0
```

After above commands `02:00.0` should be listed in `xl pci-assignable-list`
output:

```
root@apu2:~# xl pci-assignable-list
0000:02:00.0
```

`xl` allows assigning devices even if IOMMU is not present, but it will issue an
error during VM creation.

# Xen pfsense.cfg

First let's create

```
me = "pfSense-2.4.3"
builder = "hvm"
vcpus = 2
memory = 2048
pci = [ '02:00.0' ]
nographics = 1
serial = "pty"
disk=[ '/root/pfSense-CE-memstick-serial-2.4.3-RELEASE-amd64.img,,hda,rw', '/dev/vg0/pfsense,,hdb,rw' ]
```

Then you can create VM:

```
root@apu2:~# xl create pfsense.cfg
Parsing config from pfsense.cfg
root@apu2:~# xl list
Name                                        ID   Mem VCPUs      State   Time(s)
Domain-0                                     0   512     4     r-----     448.3
pfSense-2.4.3                                8  2048     2     r-----      29.5
```

# Install pfSense

After running VM you can attach to console:

```
xl console 8
```

You should see pfSense installer boot log:

```
Booting...
KDB: debugger backends: ddb
KDB: current backend: ddb
Copyright (c) 1992-2017 The FreeBSD Project.
Copyright (c) 1979, 1980, 1983, 1986, 1988, 1989, 1991, 1992, 1993, 1994
        The Regents of the University of California. All rights reserved.
FreeBSD is a registered trademark of The FreeBSD Foundation.
FreeBSD 11.1-RELEASE-p7 #10 r313908+986837ba7e9(RELENG_2_4): Mon Mar 26 18:08:25 CDT 2018
    root@buildbot2.netgate.com:/builder/ce-243/tmp/obj/builder/ce-243/tmp/FreeBSD-src/sys/pfSense amd64
FreeBSD clang version 5.0.1 (tags/RELEASE_501/final 320880) (based on LLVM 5.0.1)
VT(vga): text 80x25
XEN: Hypervisor version 4.8 detected.
CPU: AMD GX-412TC SOC                                (998.20-MHz K8-class CPU)
  Origin="AuthenticAMD"  Id=0x730f01  Family=0x16  Model=0x30  Stepping=1
  Features=0x1783fbff<FPU,VME,DE,PSE,TSC,MSR,PAE,MCE,CX8,APIC,SEP,MTRR,PGE,MCA,CMOV,PAT,PSE36,MMX,FXSR,SSE,SSE2,HTT>
  Features2=0xbef82203<SSE3,PCLMULQDQ,SSSE3,CX16,SSE4.1,SSE4.2,x2APIC,MOVBE,POPCNT,AESNI,XSAVE,OSXSAVE,AVX,F16C,HV>
  AMD Features=0x2e500800<SYSCALL,NX,MMX+,FFXSR,Page1GB,RDTSCP,LM>
  AMD Features2=0x40005f1<LAHF,CR8,ABM,SSE4A,MAS,Prefetch,IBS,DBE>
  Structured Extended Features=0x8<BMI1>
  XSAVE Features=0x1<XSAVEOPT>
Hypervisor: Origin = "XenVMMXenVMM"
real memory  = 2139095040 (2040 MB)
avail memory = 2016161792 (1922 MB)
Event timer "LAPIC" quality 100
ACPI APIC Table: <Xen HVM>
FreeBSD/SMP: Multiprocessor System Detected: 2 CPUs
FreeBSD/SMP: 2 package(s)
ioapic0: Changing APIC ID to 1
MADT: Forcing active-low polarity and level trigger for SCI
ioapic0 <Version 1.1> irqs 0-47 on motherboard
SMP: AP CPU #1 Launched!
iwi_monitor: You need to read the LICENSE file in /usr/share/doc/legal/intel_iwi.LICENSE.
iwi_monitor: If you agree with the license, set legal.intel_iwi.license_ack=1 in /boot/loader.conf.
module_register_init: MOD_LOAD (iwi_monitor_fw, 0xffffffff80682e80, 0) error 1
random: entropy device external interface
wlan: mac acl policy registered
ipw_bss: You need to read the LICENSE file in /usr/share/doc/legal/intel_ipw.LICENSE.
ipw_bss: If you agree with the license, set legal.intel_ipw.license_ack=1 in /boot/loader.conf.
module_register_init: MOD_LOAD (ipw_bss_fw, 0xffffffff8065c1c0, 0) error 1
ipw_ibss: You need to read the LICENSE file in /usr/share/doc/legal/intel_ipw.LICENSE.
ipw_ibss: If you agree with the license, set legal.intel_ipw.license_ack=1 in /boot/loader.conf.
module_register_init: MOD_LOAD (ipw_ibss_fw, 0xffffffff8065c270, 0) error 1
ipw_monitor: You need to read the LICENSE file in /usr/share/doc/legal/intel_ipw.LICENSE.
ipw_monitor: If you agree with the license, set legal.intel_ipw.license_ack=1 in /boot/loader.conf.
module_register_init: MOD_LOAD (ipw_monitor_fw, 0xffffffff8065c320, 0) error 1
iwi_bss: You need to read the LICENSE file in /usr/share/doc/legal/intel_iwi.LICENSE.
iwi_bss: If you agree with the license, set legal.intel_iwi.license_ack=1 in /boot/loader.conf.
module_register_init: MOD_LOAD (iwi_bss_fw, 0xffffffff80682d20, 0) error 1
iwi_ibss: You need to read the LICENSE file in /usr/share/doc/legal/intel_iwi.LICENSE.
iwi_ibss: If you agree with the license, set legal.intel_iwi.license_ack=1 in /boot/loader.conf.
module_register_init: MOD_LOAD (iwi_ibss_fw, 0xffffffff80682dd0, 0) error 1
kbd1 at kbdmux0
netmap: loaded module
module_register_init: MOD_LOAD (vesa, 0xffffffff81162bc0, 0) error 19
nexus0
vtvga0: <VT VGA driver> on motherboard
cryptosoft0: <software crypto> on motherboard
padlock0: No ACE support.
acpi0: <Xen> on motherboard
acpi0: Power Button (fixed)
acpi0: Sleep Button (fixed)
cpu0: <ACPI CPU> on acpi0
cpu1: <ACPI CPU> on acpi0
hpet0: <High Precision Event Timer> iomem 0xfed00000-0xfed003ff on acpi0
Timecounter "HPET" frequency 62500000 Hz quality 950
attimer0: <AT timer> port 0x40-0x43 irq 0 on acpi0
Timecounter "i8254" frequency 1193182 Hz quality 0
Event timer "i8254" frequency 1193182 Hz quality 100
atrtc0: <AT realtime clock> port 0x70-0x71 irq 8 on acpi0
Event timer "RTC" frequency 32768 Hz quality 0
Timecounter "ACPI-fast" frequency 3579545 Hz quality 900
acpi_timer0: <32-bit timer at 3.579545MHz> port 0xb008-0xb00b on acpi0
pcib0: <ACPI Host-PCI bridge> port 0xcf8-0xcff on acpi0
pci0: <ACPI PCI bus> on pcib0
isab0: <PCI-ISA bridge> at device 1.0 on pci0
isa0: <ISA bus> on isab0
atapci0: <Intel PIIX3 WDMA2 controller> port 0x1f0-0x1f7,0x3f6,0x170-0x177,0x376,0xc120-0xc12f at device 1.1 on pci0
ata0: <ATA channel> at channel 0 on atapci0
ata1: <ATA channel> at channel 1 on atapci0
pci0: <bridge> at device 1.3 (no driver attached)
xenpci0: <Xen Platform Device> port 0xc000-0xc0ff mem 0xf2000000-0xf2ffffff irq 24 at device 2.0 on pci0
vgapci0: <VGA-compatible display> mem 0xf0000000-0xf1ffffff,0xf3034000-0xf3034fff at device 3.0 on pci0
vgapci0: Boot video device
igb0: <Intel(R) PRO/1000 Network Connection, Version - 2.5.3-k> port 0xc100-0xc11f mem 0xf3000000-0xf301ffff,0xf3030000-0xf3033fff irq 32 at device 4.0 on pci0
igb0: Using MSIX interrupts with 3 vectors
igb0: Ethernet address: 00:0d:b9:43:3f:bd
igb0: Bound queue 0 to cpu 0
igb0: Bound queue 1 to cpu 1
igb0: netmap queues/slots: TX 2/1024, RX 2/1024
atkbdc0: <Keyboard controller (i8042)> port 0x60,0x64 irq 1 on acpi0
atkbd0: <AT Keyboard> irq 1 on atkbdc0
kbd0 at atkbd0
atkbd0: [GIANT-LOCKED]
psm0: <PS/2 Mouse> irq 12 on atkbdc0
psm0: [GIANT-LOCKED]
psm0: model IntelliMouse Explorer, device ID 4
fdc0: <floppy drive controller> port 0x3f0-0x3f5,0x3f7 irq 6 drq 2 on acpi0
fdc0: does not respond
device_attach: fdc0 attach returned 6
uart0: <16550 or compatible> port 0x3f8-0x3ff irq 4 flags 0x10 on acpi0
uart0: console (115200,n,8,1)
xenpv0: <Xen PV bus> on motherboard
granttable0: <Xen Grant-table Device> on xenpv0
xen_et0: <Xen PV Clock> on xenpv0
Event timer "XENTIMER" frequency 1000000000 Hz quality 950
Timecounter "XENTIMER" frequency 1000000000 Hz quality 950
xenstore0: <XenStore> on xenpv0
evtchn0: <Xen event channel user-space device> on xenpv0
privcmd0: <Xen privileged interface user-space device> on xenpv0
debug0: <Xen debug handler> on xenpv0
orm0: <ISA Option ROM> at iomem 0xec800-0xeffff on isa0
vga0: <Generic ISA VGA> at port 0x3c0-0x3df iomem 0xa0000-0xbffff on isa0
fdc0: No FDOUT register!
ppc0: cannot reserve I/O port range
Timecounters tick every 10.000 msec
nvme cam probe device init
xenballoon0: <Xen Balloon Device> on xenstore0
xctrl0: <Xen Control Device> on xenstore0
xs_dev0: <Xenstore user-space device> on xenstore0
xenbusb_front0: <Xen Frontend Devices> on xenstore0
xenbusb_add_device: Device device/suspend/event-channel ignored. State 6
xenbusb_back0: <Xen Backend Devices> on xenstore0
xbd0: 620MB <Virtual Block Device> at device/vbd/768 on xenbusb_front0
xbd0: attaching as ada0
xbd0: features: flush, write_barrier
xbd0: synchronize cache commands enabled.
xbd1: 10240MB <Virtual Block Device> at device/vbd/832 on xenbusb_front0
xbd1: attaching as ada1
xbd1: features: flush, write_barrier
xbd1: synchronize cache commands enabled.
Trying to mount root from ufs:/dev/ufs/FreeBSD_Install [ro,noatime]...
Setting hostuuid: 81dda54a-6bfd-4458-b8f2-5950cddb471a.
Setting hostid: 0x0bb6f4ee.
Starting file system checks:
/dev/ufs/FreeBSD_Install: FILE SYSTEM CLEAN; SKIPPING CHECKS
/dev/ufs/FreeBSD_Install: clean, 40755 free (43 frags, 5089 blocks, 0.0% fragmentation)
eval: cannot create /etc/hostid: Read-only file system
/etc/rc: WARNING: could not store hostuuid in /etc/hostid.
Mounting local filesystems:.
random: unblocking device.
mtree: /etc/mtree/BSD.sendmail.dist: No such file or directory
ELF ldconfig path: /lib /usr/lib /usr/lib/compat
32-bit compatibility ldconfig path:
/etc/rc: WARNING: $hostname is not set -- see rc.conf(5).
Setting up harvesting: [UMA],[FS_ATIME],SWI,INTERRUPT,NET_NG,NET_ETHER,NET_TUN,MOUSE,KEYBOARD,ATTACH,CACHED
Feeding entropy: dd: /entropy: Read-only file system
dd: /boot/entropy: Read-only file system
.
Starting Network: lo0 igb0 enc0.
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> metric 0 mtu 16384
        options=600003<RXCSUM,TXCSUM,RXCSUM_IPV6,TXCSUM_IPV6>
        inet6 ::1 prefixlen 128
        inet6 fe80::1%lo0 prefixlen 64 scopeid 0x2
        inet 127.0.0.1 netmask 0xff000000
        nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>
        groups: lo
igb0: flags=8c02<BROADCAST,OACTIVE,SIMPLEX,MULTICAST> metric 0 mtu 1500
        options=6403bb<RXCSUM,TXCSUM,VLAN_MTU,VLAN_HWTAGGING,JUMBO_MTU,VLAN_HWCSUM,TSO4,TSO6,VLAN_HWTSO,RXCSUM_IPV6,TXCSUM_IPV6>
        ether 00:0d:b9:43:3f:bd
        hwaddr 00:0d:b9:43:3f:bd
        nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>
igb0    media: Ethernet: link state changed to UP
 autoselect (1000baseT <full-duplex>)
        status: active
enc0: flags=0<> metric 0 mtu 1536
        nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>
        groups: enc
Starting devd.
Starting Network: igb0.
igb0: flags=8c02<BROADCAST,OACTIVE,SIMPLEX,MULTICAST> metric 0 mtu 1500
        options=6403bb<RXCSUM,TXCSUM,VLAN_MTU,VLAN_HWTAGGING,JUMBO_MTU,VLAN_HWCSUM,TSO4,TSO6,VLAN_HWTSO,RXCSUM_IPV6,TXCSUM_IPV6>
        ether 00:0d:b9:43:3f:bd
        hwaddr 00:0d:b9:43:3f:bd
        nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>
        media: Ethernet autoselect (1000baseT <full-duplex>)
        status: active
Starting Network: enc0.
enc0: flags=0<> metric 0 mtu 1536
        nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>
        groups: enc
add host 127.0.0.1: gateway lo0 fib 0: route already in table
add host ::1: gateway lo0 fib 0: route already in table
add net fe80::: gateway ::1
add net ff02::: gateway ::1
add net ::ffff:0.0.0.0: gateway ::1
add net ::0.0.0.0: gateway ::1
Generating host.conf.
eval: cannot create /etc/host.conf: Read-only file system
eval: cannot create /etc/host.conf: Read-only file system
eval: cannot create /etc/host.conf: Read-only file system
Creating and/or trimming log files.
Starting syslogd.
Clearing /tmp (X related).
Starting local daemons:/dev/md3: 8.0MB (16384 sectors) block size 32768, fragment size 4096
        using 4 cylinder groups of 2.03MB, 65 blks, 384 inodes.
super-block backups (for fsck_ffs -b #) at:
 192, 4352, 8512, 12672

Welcome to pfSense!

Please choose the appropriate terminal type for your system.
Common console types are:
   ansi     Standard ANSI terminal
   vt100    VT100 or compatible terminal
   xterm    xterm terminal emulator (or compatible)
   cons25w  cons25w terminal

Console type [vt100]:
```

Unfortunately, pfSense had problem getting DHCP offer and didn't configure IP
address - we tried to figure out what is wrong but my BSD-fu is low. We also
checked static IP configuration, but there is no result either. This leads us to [ask on the forum](https://forum.netgate.com/topic/133697/pfsense-2-4-3-hvm-with-pci-passthrough-no-packets-received).

# Xen debian.cfg

```
name = "debian-9.5.0"
builder = "hvm"
vcpus = 2
memory = 2048
pci = [ '02:00.0'  ]
disk=[ '/root/debian-9.5.0-amd64-netinst.iso,,hdc,cdrom', '/dev/vg0/debian,,hdb,rw'  ]
vnc=1
vnclisten='apu2_ip_addr'
boot='d'
```

Of course, you have to replace `apu2_ip_addr` with correct IP. After `xl create
debian.cfg` you can run VNC (tightvnc worked for me) and proceed with the
installation.

## PCI passthrough in Debian

Below screenshot show device `02:00.0`, which is apu2 middle NIC,
passed-through to VM.

![Debian lspci](/img/debian-9.5.0-hvm-pci-passthrough.png)

PCI passthrough on Debian worked without any issue DHCP offer was received
correctly and I could proceed with performance checks.

# Speedtest

Simplest possible test is comparison of throughput between eth0 and eth1.
The first is connected directly to our company switch and the second connects
pfSense HVM using PCI passthrough.

I used `speedtest-cli v2.0.2`.

Results for apu2 Dom0:

```
(speedtest-venv) root@apu2:~# speedtest-cli
Retrieving speedtest.net configuration...
Testing from Vectra Broadband (109.241.231.46)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by Volta Communications Sp. z o.o (Gdansk) [2.28 km]: 36.105 ms
Testing download speed................................................................................
Download: 81.67 Mbit/s
Testing upload speed................................................................................................
Upload: 15.38 Mbit/s
```

Results for Debian HVM with NIC PCI passthrough:

![Debian HVM speedtest-cli](/img/speedtest-cli-debian-hvm.png)

# iperf

Below results are for very simple LAN connection `apu3 -> switch -> apu2`:

```
(speedtest-venv) root@apu2:~# iperf -s -B 192.168.3.101
------------------------------------------------------------
Server listening on TCP port 5001
Binding to local address 192.168.3.101
TCP window size: 85.3 KByte (default)
------------------------------------------------------------
[  4] local 192.168.3.101 port 5001 connected with 192.168.3.102 port 34004
[ ID] Interval       Transfer     Bandwidth
[  4]  0.0-10.0 sec  1.10 GBytes   941 Mbits/sec
```

Unfortunately, our switch is probably not well suited for testing 1GbE. Those
tests should be repeated with directly connected ports/devices.

Results for Debian HVM with NIC PCI passthrough:

![Debian HVM iperf](/img/1GbE.png)

As you can see there is no difference between results, based on that we can
conclude that PCI passthrough works and there is no overhead when using IOMMU.

Below log show results from Debian PV and prove how virtualized drivers lead to
performance overhead.

```
root@debian-pv:~# iperf -c 192.168.3.128
------------------------------------------------------------
Client connecting to 192.168.3.128, TCP port 5001
TCP window size: 85.0 KByte (default)
------------------------------------------------------------
[  3 ] local 192.168.3.105 port 56204 connected with 192.168.3.128 port 5001
[ ID ] Interval       Transfer     Bandwidth
[  3 ]  0.0-10.0 sec   746 MBytes   625 Mbits/sec
```

# Possible problems

## xen-pciback not loaded

```
root@apu2:~# xl create pfsense.cfg
Parsing config from pfsense.cfg
libxl: error: libxl_pci.c:409:libxl_device_pci_assignable_list: Looks like pciback driver not loaded
libxl: error: libxl_pci.c:1225:libxl__device_pci_add: PCI device 0:2:0.0 is not assignable
libxl: error: libxl_pci.c:1304:libxl__add_pcidevs: libxl_device_pci_add failed: -3
libxl: error: libxl_create.c:1461:domcreate_attach_devices: unable to add pci devices
libxl: error: libxl.c:1575:libxl__destroy_domid: non-existant domain 1
libxl: error: libxl.c:1534:domain_destroy_callback: unable to destroy guest with domid 1
libxl: error: libxl.c:1463:domain_destroy_cb: destruction of domain 1 failed
```

Solution:

```
modprobe xen-pciback
```

## PCI device not assignable

```
libxl: error: libxl_pci.c:1225:libxl__device_pci_add: PCI device 0:2:0.0 is not assignable
libxl: error: libxl_pci.c:1304:libxl__add_pcidevs: libxl_device_pci_add failed: -3
libxl: error: libxl_create.c:1461:domcreate_attach_devices: unable to add pci devices
libxl: error: libxl.c:1575:libxl__destroy_domid: non-existant domain 2
libxl: error: libxl.c:1534:domain_destroy_callback: unable to destroy guest with domid 2
libxl: error: libxl.c:1463:domain_destroy_cb: destruction of domain 2 failed
```

Assign PCI device using `xl pci-assignable-add`.

## No IOMMU

```
root@apu2:~# xl create pfsense.cfg
Parsing config from pfsense.cfg
libxl: error: libxl_pci.c:1209:libxl__device_pci_add: PCI device 0000:02:00.0 cannot be assigned - no IOMMU?
libxl: error: libxl_pci.c:1304:libxl__add_pcidevs: libxl_device_pci_add failed: -1
libxl: error: libxl_create.c:1461:domcreate_attach_devices: unable to add pci devices
libxl: error: libxl.c:1575:libxl__destroy_domid: non-existant domain 9
libxl: error: libxl.c:1534:domain_destroy_callback: unable to destroy guest with domid 9
libxl: error: libxl.c:1463:domain_destroy_cb: destruction of domain 9 failed
```

This error means you don't have IOMMU correctly enabled. For AMD platforms `xl
dmesg` contain:

```
root@apu2:~# xl dmesg|grep -i iommu
(XEN) AMD-Vi: IOMMU not found!
```

## Lack of block backend

`xen-blkback` should be loaded or compiled in otherwise blow error pop-up.

```
root@apu2:~# xl create pfsense.cfg
Parsing config from pfsense.cfg
libxl: error: libxl_device.c:1086:device_backend_callback: unable to add device with path /local/domain/0/backend/vbd/1/51712
libxl: error: libxl_create.c:1255:domcreate_launch_dm: unable to add disk devices
libxl: error: libxl_device.c:1086:device_backend_callback: unable to remove device with path /local/domain/0/backend/vbd/1/51712
libxl: error: libxl.c:1647:devices_destroy_cb: libxl__devices_destroy failed for 1
libxl: error: libxl.c:1575:libxl__destroy_domid: non-existant domain 1
libxl: error: libxl.c:1534:domain_destroy_callback: unable to destroy guest with domid 1
libxl: error: libxl.c:1463:domain_destroy_cb: destruction of domain 1 failed
```

## Crash after couple tries

After a couple tries of creating pfSense VM I faced below error:

```
root@apu2:~# xl create pfsense.cfg
Parsing config from pfsense.cfg
libxl: error: libxl_exec.c:118:libxl_report_child_exitstatus: /etc/xen/scripts/block add [490] exited with error status 1
libxl: error: libxl_device.c:1237:device_hotplug_child_death_cb: script: Failed to find an unused loop device
libxl: error: libxl_create.c:1255:domcreate_launch_dm: unable to add disk devices
libxl: error: libxl_exec.c:118:libxl_report_child_exitstatus: /etc/xen/scripts/block remove [604] exited with error status 1
libxl: error: libxl_device.c:1237:device_hotplug_child_death_cb: script: /etc/xen/scripts/block failed; error detected.
libxl: error: libxl.c:1575:libxl__destroy_domid: non-existant domain 1
libxl: error: libxl.c:1534:domain_destroy_callback: unable to destroy guest with domid 1
libxl: error: libxl.c:1463:domain_destroy_cb: destruction of domain 1 failed
```

Solution: recompile kernel with `BLK_DEV_LOOP`

## Read-only not supported

```
root@apu2:~# xl create pfsense.cfg
Parsing config from pfsense.cfg
libxl: error: libxl_dm.c:1433:libxl__build_device_model_args_new: qemu-xen doesn't support read-only IDE disk drivers
libxl: error: libxl_dm.c:2182:device_model_spawn_outcome: (null): spawn failed (rc=-6)
libxl: error: libxl_create.c:1504:domcreate_devmodel_started: device model did not start: -6
libxl: error: libxl.c:1575:libxl__destroy_domid: non-existant domain 1
libxl: error: libxl.c:1534:domain_destroy_callback: unable to destroy guest with domid 1
libxl: error: libxl.c:1463:domain_destroy_cb: destruction of domain 1 failed
```

Solution: change pfsense.cfg by adding `rw` to img file.

# References

* [Install pfSense 2.1 RC0 amd64 on Xen 4.3 as PV HVM](https://forum.netgate.com/topic/58662/howto-install-pfsense-2-1-rc0-amd64-on-xen-4-3-as-pv-hvm)
* [Virtual firewall](https://en.wikipedia.org/wiki/Virtual_firewall)
* [xl.cfg manual for Xen 4.8](https://xenbits.xen.org/docs/4.8-testing/man/xl.cfg.5.html)
* [Unanswered question about DMA attacks](https://security.stackexchange.com/questions/176503/dma-attacks-despite-iommu-isolation)
* [Google blog post about fuzzying PCIe](https://cloudplatform.googleblog.com/2017/02/fuzzing-PCI-Express-security-in-plaintext.html)

# Summary

I hope this post was useful for you. Please feel free to share your opinion and
if you think there is value, then share with friends.

We plan to present above results during OSFC 2018 feel free to catch us there
and ask questions.

We believe there are still many devices with VT-d or AMD-Vi advertised in
specs, but not enabled because of buggy or not-fully-featured firmware. We are
always open to support vendors who want to boot hardware by extending and
improving their firmware. If you are user or vendor struggling with hardware
which cannot be fully utilized because of firmware, feel free to contact us
`contact<at>3mdeb<dot>com`.

---
title: pfSense firewall boot process optimization under Xen hypervisor
abstract: Running applications in Virtual Machines is not a trivial task.
          Especially, when we want to gain the highest possible performance.
          Find out how you can improve boot process of pfSense firewall under
          Xen hypervisor and reduce its boot time to minimum.
cover: /covers/pfsense-logo.png
author: piotr.kleinschmidt
layout: post
published: false
date: 2019-10-22
archives: "2019"

tags:
  - pfSense
  - Xen
  - virtualization
  - hypervisor
  - firewall
categories:
  - Firmware
  - OS dev

---

## Introduction

Network devices, such as modems, routers or servers are largely prone to cyber
attacks. Their security issue is a priority if we want to keep everything behind
them safe. As a solution user might choose from many available firewall
softwares.

However, skeptics will say that this is still not enough, because how they can
be sure if that software is in 100% compatible with their hardware? We are those
skeptics... and we would like to introduce pfSense firewall running in virtual
machine under Xen hypervisor. In that blogpost I focused only about boot process
and what changes could be invoked to improve it.

## pfSense, Xen, hypervisor... what is this all about?

pfSense is an **open-source firewall** (and router itself) based on FreeBSD
distribution. It has a lot of useful features:  high performance, scalability,
management via web interface, large community support and many others. No wonder
it is very popular and commonly used by companies and private users. However,
its implementation is not always so straightforward. Basically there are two
approaches:

- bare-metal pfSense - implemented directly on the firmware
- pfSense in virtual machine (VM) managed by **hypervisor**

As I mentioned earlier, we decided to implement pfSense in virtual machine under
**Xen hypervisor**. Second type of implementation was also used by us, but only
as a comparative test.

For better understanding our build configuration, you should be familiar with
some basics about virtualization, hypervisors and Xen itself. I will introduce
those issues at high-level overview. It should be enough to understand topic of
that blogpost, but if you are more interested in those fields and want to read
about details I refer to [Red Hat
article](https://www.redhat.com/en/topics/virtualization/what-is-virtualization)
and to our [blogposts](https://blog.3mdeb.com/tags/virtualization/) with
*virtualization* tag.

### Virtualization

Virtualization is a technology which let you run several, different environments
(e.g. operating systems) on one physical machine. Very important is fact that
all those environments are run in parallel, which significantly increases
efficiency. Differences between them mainly refer to supported hardware (e.g.
architecture, controllers, peripherals etc.), way of operation and application.
Virtualization technology concept is shown in the picture below.

![virtualization](/img/virtualization-overview.png)

As you can see, there is an additional `virtualization layer`. That layer is
mostly implemented as `hypervisor`.

### Hypervisor

Hypervisor is a software which manages all virtual machines running on it. It is
a middleman between hardware and every environment which user wants to create on
the machine. If you think about virtualization technology, hypervisor is its
essential part. In our implementation of pfSense firewall we used **Xen
hypervisor**. It is a open-source project supported by many companies, which are
firmware and IT market leaders. I won't elaborate about Xen. Most features you
need to know are:

- it is hypervisor type 1 - operates directly on the hardware, gaining full
  control over it
- can be built from source - that approach allows us to customize Xen to our
  needs
- is well-documented and largely supported- many issues are described in
  official documentation or they are solved by community

## pfSense booting

As I mentioned earlier, there are actually 2 implementations of pfSense:
bare-metal and with Xen. First one is used as reference one. If virtualized
pfSense could approach to reference values, then it is considered as
well-implemented.

Configurations for both realizations are shown in the table below.

|             |      pfSense bare-metal     | pfSense as Guest Virtual Machine |
|:-----------:|:---------------------------:|:--------------------------------:|
|  version    |  2.4.4-RELEASE-p3           |         2.4.4-RELEASE-p3         |
|run platform |  PC Engines apu2d4          |         PC Engines apu2d4        |
| CPU        |AMD Embedded GX-412TC, quad core|AMD Embedded GX-412TC, quad core|
| firmware    | coreboot v4.10.0.2          |coreboot v4.10.0.1 commit 468fd08 |
| Hypervisor  | -                           |   Xen 4.13-unstable              |
| boot drive  | SD card SanDisk Ultra 16GB  | SD card SanDisk Ultra 16GB       |

What we wanted to gain is to have boot time as short as possible. For bare-metal
case boot time is considered as time from power on platform to enter pfSense
main menu. For VM implementation, it is measured from creating VM in Xen to
enter main menu. In both cases every possible delay related to firmware was
turned off.

Also, we didn't want to simplify our build too much. Virtualization is very
powerful tool and besides compatibility advantages, it gives security features
either. We decided to 'close' in VM not only pfSense, but also Network Interface
Controlers (NIC). In this way we prepared platform on which is running Xen. Then
Xen runs 3 VMs:
 - 2x **Network Driver Virtual Machines (NDVM)** (one VM for one NIC)
 - 1x **pfSense in Virtual Machine**.

It might sounds confusing, so I believe picture below would clarify entire
concept.

![platform-config](/img/platform-config.png)

What we achieved by that? Platform is now more secure than with only pfSense
firewall. Remember, that VMs are *software environments* adjusted by user. It's
you, who decides what to keep in there and what task it should perform. NDVM
creates emulated network interface which is passed to pfSense. If something goes
wrong (e.g. infected data get through pfSense), there is still additional
protection which in eventually could isolate or cut off communication with
physical device.

Now, when you are familiar with virtualization technology and our goals, let's
move to actual topic of that blogpost. Let the boot process begin!

### Bare-metal pfSense

First, we needed to know how long bare-metal pfSense boots. As I mentioned, it
will be our reference sample to every next test.

Every delay which could occur in coreboot or SeaBIOS is turned off. Also
configuration for pfSense is optimized. We disabled `pfSense boot menu` (by the
way determined by vendors as `beastie menu`). Also we disabled auto-boot time,
so the kernel is loaded automatically without any delay. Follow logs show what
boot time we achieved.

```
[09:47:49] PC Engines apu2
[09:47:49] coreboot build 20190810
[09:47:49] BIOS version v4.10.0.2
[09:47:51] 4080 MB ECC DRAM
[09:47:51]
[09:47:52] SeaBIOS (version rel-1.12.1.3-0-g300e8b7)
[09:47:55]
[09:47:55] Press F10 key now for boot menu
[09:47:55]
[09:47:55] Booting from Hard Disk...
[09:47:55] /boot/config: -S115200 -h
[09:47:58] Consoles: serial port
[09:47:58] BIOS drive C: is disk0
[09:47:58] BIOS drive D: is disk1
[09:47:58] BIOS 639kB/3405396kB available memory
[09:47:58]
[09:47:58] FreeBSD/x86 bootstrap loader, Revision 1.1
[09:47:58] (Wed Nov 21 08:03:01 EST 2018 root@buildbot2.nyi.netgate.com)
[09:47:58] Loading /boot/defaults/loader.conf
[09:48:00] /boot/kernel/kernel text=0x17c1930 data=0xb93d38+0x557b28 syms=[0x8+0x197400-]
[09:48:19] /boot/entropy size=0x1000
[09:48:21] Booting [/boot/kernel/kernel]
[09:48:21] KDB: debugger backends: ddb
[09:48:22] KDB: current backend: ddb
[09:48:22] Copyright (c) 1992-2018 The FreeBSD Project.
[09:48:22] Copyright (c) 1979, 1980, 1983, 1986, 1988, 1989, 1991, 1992, 1993, 1994
(...)
[09:49:08] Bootup complete
[09:49:09]
[09:49:09] FreeBSD/amd64 (pfSense.localdomain) (ttyu0)
[09:49:09]
[09:49:10] PC Engines APU2 - Netgate Device ID: cb865006ef8a708e758b
[09:49:10]
[09:49:10] *** Welcome to pfSense 2.4.4-RELEASE-p3 (amd64) on pfSense ***
[09:49:10]
[09:49:10]  WAN (wan)       -> igb0       -> v4/DHCP4: 192.168.4.145/24
[09:49:10]  LAN (lan)       -> igb1       ->
[09:49:10]  OPT1 (opt1)     -> igb2       ->
[09:49:10]
[09:49:10]  0) Logout (SSH only)                  9) pfTop
[09:49:10]  1) Assign Interfaces                 10) Filter Logs
[09:49:10]  2) Set interface(s) IP address       11) Restart webConfigurator
[09:49:10]  3) Reset webConfigurator password    12) PHP shell + pfSense tools
[09:49:10]  4) Reset to factory defaults         13) Update from console
[09:49:11]  5) Reboot system                     14) Enable Secure Shell (sshd)
[09:49:11]  6) Halt system                       15) Restore recent configuration
[09:49:11]  7) Ping host                         16) Restart PHP-FPM
[09:49:11]  8) Shell
[09:49:11]
[09:49:11] Enter an option:
```

> Timestamps shown above are taken as local time used in running machine.
Therefore, to count boot time, it is needed to subtract last time log from first
time log

Boot time is given in following format: `HH:MM:SS`

**Bare-metal pfSense boot time**: **00:01:22**

`1 minute 22 seconds` - let find out if we can get close to such a result. Or
maybe we can do even better?

### First attempt

Running pfSense without any modifications wasn't optimistic. Boot performance
was very poor and it seemed like there are unnecessary delays in-between entire
process.

```
00:00:06 /boot/config: -S115200 -D
00:00:10 Consoles: internal video/keyboard  serial port
00:00:10 BIOS drive C: is disk0
00:00:10 BIOS 639kB/2096124kB available memory
00:00:10
00:00:10 FreeBSD/x86 bootstrap loader, Revision 1.1
00:00:10 (Wed Nov 21 08:03:01 EST 2018 root@buildbot2.nyi.netgate.com)
00:00:24 Loading /boot/defaults/loader.conf
00:00:24 Finish /boot/defaults/loader.conf
00:00:29 Loading /boot/loader.conf.local
00:00:29 Finish /boot/loader.conf.local
00:02:43 /
          __
   _ __  / _|___  ___ _ __  ___  ___
  | '_ \| |_/ __|/ _ \ '_ \/ __|/ _ \
  | |_) |  _\__ \  __/ | | \__ \  __/
  | .__/|_| |___/\___|_| |_|___/\___|
  |_|


 +============Welcome to pfSense===========+   __________________________
 |                                         |  /                       ___\
 |  1. Boot Multi User [Enter]             | |                      /`
 |  2. Boot [S]ingle User                  | |                     /    :-|
 |  3. [Esc]ape to loader prompt           | |      _________  ___/    /_ |
 |  4. Reboot                              | |    /` ____   / /__    ___/ |
 |                                         | |   /  /   /  /    /   /     |
 |  Options:                               | |  /  /___/  /    /   /      |
 |  5. [K]ernel: kernel (1 of 2)           | | /   ______/    /   /       |
 |  6. Configure Boot [O]ptions...         | |/   /          /   /        |
 |                                         |     /          /___/         |
 |                                         |    /                         |
 |                                         |   /_________________________/
 +=========================================+


/boot/kernel/kernel text=0x17c1930 data=0xb93d38+0x557b28 syms=[0x8+0x197400+0x8+0x197f72]
00:02:45 /boot/entropy size=0x1000
00:02:45 Booting...
(...)
00:03:54 Bootup complete
00:03:56
00:03:56 FreeBSD/amd64 (pfSense.localdomain) (ttyu0)
00:03:56
00:03:57 pfSense - Netgate Device ID: 1713b82be3f920695125
00:03:57
00:03:57 *** Welcome to pfSense 2.4.4-RELEASE-p3 (amd64) on pfSense ***
00:03:57
00:03:57  WAN (wan)       -> xn0        -> v4/DHCP4: 192.168.10.199/24
00:03:57
00:03:57  0) Logout (SSH only)                  9) pfTop
00:03:57  1) Assign Interfaces                 10) Filter Logs
00:03:58  2) Set interface(s) IP address       11) Restart webConfigurator
00:03:58  3) Reset webConfigurator password    12) PHP shell + pfSense tools
00:03:58  4) Reset to factory defaults         13) Update from console
00:03:58  5) Reboot system                     14) Enable Secure Shell (sshd)
00:03:58  6) Halt system                       15) Restore recent configuration
00:03:58  7) Ping host                         16) Restart PHP-FPM
00:03:58  8) Shell
00:03:58
```

>Timestamps are given as stopwatch format counting from 00:00:00. Therefore,
last value is boot time

Attempt 1: **pfSense in VM boot time** : **00:03:58**

We can see several issues here:

- over 2-minute delay after `Finish /boot/loader.conf.local`
- boot entry menu is displayed
- auto-boot delay is active

To optimize pfSense we added those lines to `/boot/loader.conf.local` file:

```
autoboot_delay="-1"       // Disable autoboot
kern.cam.boot_delay=0     // Disable additional installation disc delay
boot_multicons="NO"       // Disable multiconsole support
beastie_disable="YES"     // Disable pfSense boot entry menu
```

After making above changes, **boot time reduced to 00:03:38**. However, there is
still the 2-minute gap in boot process. Unfortunately, there is no possibility
to enable any verbose output to see what is happening there. Moreover, any
additional changes which we tried to introduce into `/boot/loader.conf.local`
didn't make any difference. After many futile attempts, we have thought that
maybe we should look for the source of the problem somewhere else...

### Debug Xen

If the problem doesn't lie in pfSense itself, then it certainly must lie higher -
in the hypervisor. Fortuantely, Xen has a very helpful tool for debugging
purpose. We used `Xentrace` and `Xenalyze`. Usage of them is well-descripted
[here](https://xenproject.org/2012/09/27/tracing-with-xentrace-and-xenalyze/),
so I won't duplicate that article. What you might need to know, `Xentrace` is a
tool for monitoring Xen performance. It gives logs about almost every parameter
which is useful from debugging point of view. For example, you can see what CPUs
are currently used by what VM. What is a state of VM and what interrupts change
that state. How long it was running and how long it was in idle state and many,
many other. `Xenalyze` transpose those logs to human-friendly form. It is then
easier to analyze them and search for potential issues.

Our priority is to find out why there is 2-minute delay in boot process and how
we can reduce it. To do this we collected Xentrace logs from that particular
stage of booting (actually we took only 12 seconds of that stage, because
Xentrace logs are very large and we didn't want to get out of free space). After
using Xenalyze on those logs, we achieved interesting output. **pfSense VM
during boot process is most of the time in offline state caused by VM_EXIT_IOIO
interrupt**. That interrupt is triggered every time when software tries to
read/write data to disk. It gives a clue that the problem might be caused by the
way of how SD card (on which pfSense image is) is emulated by Xen.

Every VM creation can be configured by a `.cfg` file. That file is passed to
Xen's `create` command as an argument. If you want to change anything about your
VM at the creation stage, that file is place when you add changes. For our issue
we made one significant modification. So far, SD card with pfSense image was
emulated as `hd[X]` device. It means that pfSense VM has communicated with it
via **emulated IDE controller**. We decided to change it to `sd[X]`, which means
**emulated SCSI controller**. Theoretically, both IDE and SCSI operations speed
are almost the same. The difference is in the number of cycles to access the
registers during R/W operations. SCSI needs less of them than IDE. Less
registers access = less IOIO interrupts = less exits to hypervisor.

Entire configuration of `pfsense.cfg` is shown below:

```
name = "pfsense"
type = "hvm"
vcpus = 4
memory = 2048
pae = 1
acpi = 1
apic = 1
viridian = 1
rtc_timeoffset = 0
localtime = 1
on_poweroff = "destroy"
on_reboot = "destroy"
on_crash = "destroy"
sdl = 0
vif = [
  'bridge=xenbr0,backend=ndvm-1',
  'bridge=xenbr0,backend=ndvm-2',
 ]
serial = "pty"
vga="none"
nographics = 1

disk = [ '/usr/share/xen-images/pfsense.img,,sdb,rw' ]
```

Let see how it affected boot process:

```
00:00:06 /boot/config: -S115200 -D                                              
00:00:10 Consoles: internal video/keyboard  serial port                         
00:00:10 BIOS drive C: is disk0                                                 
00:00:10 BIOS 639kB/1047548kB available memory                                  
00:00:10                                                                       
00:00:10 FreeBSD/x86 bootstrap loader, Revision 1.1                            
00:00:10 (Wed Nov 21 08:03:01 EST 2018 root@buildbot2.nyi.netgate.com)         
00:00:11 Loading /boot/defaults/loader.conf                                     
00:00:11 Finish /boot/defaults/loader.conf                                      
00:00:12 Loading /boot/loader.conf.local                                       
00:00:12 Finish /boot/loader.conf.local                                         
00:00:30
(...)
/boot/kernel/kernel text=0x17c1930 data=0xb93d38+0x557b28 syms=[0x8+0x197400+0x8+0x197f72]
00:00:31 /boot/entropy size=0x1000
00:00:31 Booting...
00:00:32 KDB: debugger backends: ddb
00:00:32 KDB: current backend: ddb
(...)
00:01:37 Bootup complete
00:01:39
00:01:39 FreeBSD/amd64 (pfSense.localdomain) (ttyu0)
00:01:39
00:01:40 pfSense - Netgate Device ID: 8eceac084b0ff28e385f
00:01:40
00:01:40 *** Welcome to pfSense 2.4.4-RELEASE-p3 (amd64) on pfSense ***
00:01:40
00:01:40  WAN (wan)       -> xn0        -> v4/DHCP4: 192.168.10.26/24
00:01:40  LAN (lan)       -> xn1        -> v4: 192.168.1.1/24
00:01:40
00:01:40  0) Logout (SSH only)                  9) pfTop
00:01:40  1) Assign Interfaces                 10) Filter Logs
00:01:40  2) Set interface(s) IP address       11) Restart webConfigurator
00:01:40  3) Reset webConfigurator password    12) PHP shell + pfSense tools
00:01:40  4) Reset to factory defaults         13) Update from console
00:01:40  5) Reboot system                     14) Enable Secure Shell (sshd)
00:01:40  6) Halt system                       15) Restore recent configuration
00:01:40  7) Ping host                         16) Restart PHP-FPM
00:01:40  8) Shell
00:01:40
```

>Timestamps are given as stopwatch format counting from 00:00:00. Therefore,
last value is boot time

Attempt 3: **pfSense in VM boot time** : **00:01:40**

There is no more unnecessary delays in booting. Also the entire process is only
19 seconds longer than bare-metal comparative one. We should consider it as a
success and it can be said that we gained our set goal. After applying all above
changes, booting pfSense under Xen hypervisor can be now described as optimized.

## Summary

As you probably have often found out, even well-described processes could bring
unexpected issues. Especially nowadays, when performance and reliability are
significant features of every hardware and software. Above blogpost proves that
the better you know the problem, the better solution you can apply.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

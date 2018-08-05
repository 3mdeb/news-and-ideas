---
post_title: pfSense as HVM guest on PC Engines apu2
author: Piotr Król
layout: post
published: true
post_date: 2018-07-27 16:00:00

tags:
	- xen
	- iommu
	- coreboot
categories:
	- Firmware
    - OS Dev
---

Continuing blog post series around Xen and IOMMU enabling in coreboot we
reaching point in which some features seem to work correctly on top of [recent patch series in firmware](https://review.coreboot.org/#/c/coreboot/+/27602/).

What we can do at this point is PCI passthrough to guest VMs. Previously trying
that on Xen caused problems: TBD


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

Of course after above operation we can't access `enp2s0` in dom0. Having
ability to sett pass through we can think about creating pfSense HVM and having
isolation between various roles on our PC Engines apu2 router.

What are the pros of that solution:

* price - this is DYI solution where you just pay price of apu2 and spent some
  time with setup, of course you can also pay for that to companies like 3mdeb,
  what should be still cheaper then other commercial solutions - this make it
  attractive to SOHO
* scalability - you can decide how much resources of your router you want to
  give to firewall, remaining pool can be used for other purposes this save you
  couple cents on on energy bill
* security - even if attacker get access to pfSense (very unlikely), escaping
  VM and gaining full control and persistence on hardware is not possible without
  serious Xen bug, on the other hand bugs in on the other VMs (e.g. network
  storage, web application, 3rd party software) cannot be leveraged to gain
  control over the router
* virtual machine - VMs by itself have bunch of advantages, some where
  mentioned above, but other are easier migration, lower cost to introduce in
  existing network

# Requirements

* PC Engines apu2c4
* `pxe-server` - or other means of booting Debian based Dom0 with Xen 4.8 and
  Linux 4.14.59 (or any other modern kernel which have correct support enabled as
  in [this kernel config](https://github.com/pcengines/apu2-documentation/blob/6b6dc7d1a52f0550aa237746fc236ba07ba9c747/configs/config-4.14.59))
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

`xl` allows assigning devices even if IOMMU is not present, but it will issues
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
(...)
```

Unfortunately pfSense had problem getting DHCP offer and didn't configure IP
address - I tried to figure out what is wrong but my BSD-fu is low. I will
probably attack that problem later.

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

Of course you have to replace `apu2_ip_add` with correct IP. After `xl create
debian.cfg` you can run VNC (tightvnc worked for me) and proceed with
installation.

# Speedtest

Simplest possible test is comparison of through put between eth0 and eth1.
First is connected directly to our company switch and second connects pfSense
HVM using PCI passthrough.

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

```
```

# iperf

Below results are for very simple LAN:

```
------------------------------------------------------------
Client connecting to 192.168.3.101, UDP port 5001
Binding to local address 192.168.3.100
Sending 1470 byte datagrams, IPG target: 1.18 us (kalman adjust)
UDP buffer size:  208 KByte (default)
------------------------------------------------------------
[  3 ] local 192.168.3.100 port 35149 connected with 192.168.3.101 port 5001
[ ID ] Interval       Transfer     Bandwidth
[  3 ]  0.0-10.0 sec   312 MBytes   261 Mbits/sec
[  3 ] Sent 222325 datagrams
[  3 ] Server Report:
[  3 ]  0.0-10.0 sec   312 MBytes   261 Mbits/sec   0.008 ms   18/222325 (0.0081%)
```

Unfortunately our switch is probably not well suited for testing 1GbE. Those
tests should be repeated with directly connected ports/devices.

Results for Debian HVM with NIC PCI passthrough:

```
```

# Possible problems

# xen-pciback not loaded

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

# PCI device not assignable

```
libxl: error: libxl_pci.c:1225:libxl__device_pci_add: PCI device 0:2:0.0 is not assignable
libxl: error: libxl_pci.c:1304:libxl__add_pcidevs: libxl_device_pci_add failed: -3
libxl: error: libxl_create.c:1461:domcreate_attach_devices: unable to add pci devices
libxl: error: libxl.c:1575:libxl__destroy_domid: non-existant domain 2
libxl: error: libxl.c:1534:domain_destroy_callback: unable to destroy guest with domid 2
libxl: error: libxl.c:1463:domain_destroy_cb: destruction of domain 2 failed
```

Assign PCI device using `xl pci-assignable-add`.

# No IOMMU

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

# Lack of block backend

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

# Crash after couple tries

After couple tries of creating pfSense VM I faced below error:

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

# Read-only not supported

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

# Summary

I hope this post was useful for you. Please feel free to share you opinion and
if you think there is value, then share with friends.

We plan to present above results during OSFC 2018 feel free to catch us there
and ask questions.

We believer there are still many devices with VT-d or AMD-Vi advertised in
specs, but not enabled because of buggy or not-fully-featured firmware. We are
always open to support vendors who want to boot hardware by extending and
improving their firmware. If you are user or vendor struggling with hardware
which cannot be fully utilized because of firmware feel free to contact us
`contact<at>3mdeb<dot>com`.

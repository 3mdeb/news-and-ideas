---
title: How to boot Xen over PXE and NFS on PC Engines apu2
author: piotr.krol
layout: post
published: true
date: 2018-07-18

tags:
  - coreboot
  - xen
  - apu2
categories:
  - Firmware
  - OS Dev
---

From time to time we face requests to correctly enable support for various Xen
features on PC Engines apu2 platform. Doing that requires firmware
modification, which 3mdeb is responsible for.

Xen have very interesting requirements from firmware development perspective.
Modern x86 have a bunch of features that support virtualization in hardware.
Those features were described in [Xen FAQ](https://wiki.xenproject.org/wiki/Xen_Common_Problems#What_are_the_names_of_different_hardware_features_related_to_virtualization_and_Xen.3F).

It happens that most requesting were IOMMU and SR-IOV. First, give the ability
to dedicate PCI device to given VM and second enables so-called Virtual
Functions, what means on a physical device (e.g. Ethernet NIC) can be
represented by many PCI devices. Connecting IOMMU with SR-IOV give the ability
for hardware-assisted sharing of one device between many VMs.

All those features are very nice and there is work spread on various forums,
which didn't get its way to mainline yet. Starting with this blog post we want
to change that.

To start any work in that area we need a reliable setup. I had a plan to build
something pretty simple using our automated testing infrastructure.
Unfortunately, this has to wait a little bit since when I started this work I had
to play with a [different configuration](https://3mdeb.com/os-dev/ssh-reverse-tunnel-for-pxe-nfs-and-dhcp-setup-on-qubesos/).

If you don't have PXE, DHCP (if needed) and NFS set up I recommend to read
above blog post or just use [pxe-server](https://github.com/3mdeb/pxe-server)
and [dhcp-server](https://github.com/3mdeb/dhcp-server).

## Xen installation in Debian stable

I assume you have PXE+NFS boot of our Debian stable. To netboot simply enter
iPXE:

```
iPXE> dhcp net0
Configuring (net0 00:0d:b9:43:3f:bc).................. ok
iPXE> chain http://192.168.42.1:8000/menu.ipxe
```

And choose `Debian stable netboot 4.14.y`:

```
---------------- iPXE boot menu ----------------
ipxe shell
Xen
Debian stable netboot 4.14.y
Debian stable netboot 4.15.y
Debian stable netboot 4.16.y
Debian stable netinst
Debian i386 stable netinst
TODO:Debian testing netinst
TODO:Debian testing netinst (UEFI-aware)
Voyage netinst 0.11.0
Ubuntu LTS netinst
Core OS netinst
Core 6.4
------------ iPXE boot menu end ----------------
```

After boot, you can log in with presented credentials `[root:debian]`:

```
Debian GNU/Linux 9 apu2 ttyS0 [root:debian]

apu2 login: root
Password:
Last login: Mon Jul 16 23:45:56 UTC 2018 on ttyS0
Linux apu2 4.14.50 #13 SMP Mon Jun 18 00:36:23 CEST 2018 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
root@apu2:~#
```

Xen installation in Debian is quite easy and there is [community website](https://wiki.debian.org/Xen)
describing the process, but to quickly dive in:

```
apt-get update
apt-get install xen-system-amd64 xen-tools xen-linux-system-amd64
```

# xencall error

I took a break from Xen debugging and found that after upgrading kernel and
rootfs I'm getting below error message:

```
root@apu2:~# xl dmesg
xencall: error: Could not obtain handle on privileged command interface: No such file or directory
libxl: error: libxl.c:108:libxl_ctx_alloc: cannot open libxc handle: No such file or directory
cannot init xl context
```

I'm not a Xen developer and it looked pretty cryptic to me. It happens that
`xen.service` also fails to run:

```
● xen.service - LSB: Xen daemons
   Loaded: loaded (/etc/init.d/xen; generated; vendor preset: enabled)
   Active: failed (Result: exit-code) since Wed 2018-05-02 11:20:00 UTC; 33s ago
     Docs: man:systemd-sysv-generator(8)
  Process: 392 ExecStart=/etc/init.d/xen start (code=exited, status=1/FAILURE)

May 02 11:20:00 apu2 systemd[1]: Starting LSB: Xen daemons...
May 02 11:20:00 apu2 xen[392]: Starting Xen daemons: xenfs failed!
May 02 11:20:00 apu2 systemd[1]: xen.service: Control process exited, code=exite
May 02 11:20:00 apu2 systemd[1]: Failed to start LSB: Xen daemons.
May 02 11:20:00 apu2 systemd[1]: xen.service: Unit entered failed state.
May 02 11:20:00 apu2 systemd[1]: xen.service: Failed with result 'exit-code'.
```

It happen that during upgrading of my rootfs I forget to install all required
packages to Xen rootfs directory. So, now you should not face this problem when
using `pxe-server`, but if you see something similar please make sure you have
all modules correctly loaded or compiled in. You can check my working [kernel config](https://github.com/pcengines/apu2-documentation/blob/master/configs/config-4.14.50)


# Xen boot log

Below boot log analysis was performed on `v4.6.9` release candidate.

```
(XEN) Xen version 4.8.3 (Debian 4.8.3+comet2+shim4.10.0+comet3-1+deb9u5) (ijackson@chiark.greenend.org.uk) (gcc (Debian 6.3.0-18) 6.3.0 20170516) debug=n  Fri Mar  2 16:10:09 UTC 2018
(XEN) Bootloader: iPXE 1.0.0+ (fd6d1)
(XEN) Command line: dom0_mem=512M loglvl=all guest_loglvl=all com1=115200,8n1 console=com1
(XEN) Video information:
(XEN)  No VGA detected
(XEN) Disc information:
(XEN)  Found 0 MBR signatures
(XEN)  Found 0 EDD information structures
(XEN) Xen-e820 RAM map:
(XEN)  0000000000000000 - 000000000009fc00 (usable)
(XEN)  000000000009fc00 - 00000000000a0000 (reserved)
(XEN)  00000000000f0000 - 0000000000100000 (reserved)
(XEN)  0000000000100000 - 00000000cff9e000 (usable)
(XEN)  00000000cff9e000 - 00000000d0000000 (reserved)
(XEN)  00000000f8000000 - 00000000fc000000 (reserved)
(XEN)  0000000100000000 - 000000012f000000 (usable)
(XEN) ACPI: RSDP 000F3610, 0024 (r2 CORE  )
(XEN) ACPI: XSDT CFFAF0E0, 0064 (r1 CORE   COREBOOT        0 CORE        0)
(XEN) ACPI: FACP CFFB08F0, 00F4 (r4 CORE   COREBOOT        0 CORE        0)
(XEN) ACPI: DSDT CFFAF280, 166D (r2 AMD    COREBOOT    10001 INTL 20161222)
(XEN) ACPI: FACS CFFAF240, 0040
(XEN) ACPI: SSDT CFFB09F0, 008A (r2 CORE   COREBOOT       2A CORE       2A)
(XEN) ACPI: TCPA CFFB0A80, 0032 (r2 CORE   COREBOOT        0 CORE        0)
(XEN) ACPI: APIC CFFB0AC0, 007E (r1 CORE   COREBOOT        0 CORE        0)
(XEN) ACPI: HEST CFFB0B40, 01D0 (r1 CORE   COREBOOT        0 CORE        0)
(XEN) ACPI: SSDT CFFB0D10, 48A6 (r2 AMD    AGESA           2 MSFT  4000000)
(XEN) ACPI: SSDT CFFB55C0, 07C8 (r1 AMD    AGESA           1 AMD         1)
(XEN) ACPI: HPET CFFB5D90, 0038 (r1 CORE   COREBOOT        0 CORE        0)
(XEN) System RAM: 4079MB (4177140kB)
(XEN) No NUMA configuration found
(XEN) Faking a node at 0000000000000000-000000012f000000
(XEN) Domain heap initialised
(XEN) CPU Vendor: AMD, Family 22 (0x16), Model 48 (0x30), Stepping 1 (raw 00730f01)
(XEN) found SMP MP-table at 000f3440
(XEN) DMI present.
(XEN) Using APIC driver default
(XEN) ACPI: PM-Timer IO Port: 0x818 (32 bits)
(XEN) ACPI: SLEEP INFO: pm1x_cnt[1:804,1:0], pm1x_evt[1:800,1:0]
(XEN) ACPI: 32/64X FACS address mismatch in FADT - cffaf240/0000000000000000, using 32
(XEN) ACPI:             wakeup_vec[cffaf24c], vec_size[20]
(XEN) ACPI: Local APIC address 0xfee00000
(XEN) ACPI: LAPIC (acpi_id[0x00] lapic_id[0x00] enabled)
(XEN) ACPI: LAPIC (acpi_id[0x01] lapic_id[0x01] enabled)
(XEN) ACPI: LAPIC (acpi_id[0x02] lapic_id[0x02] enabled)
(XEN) ACPI: LAPIC (acpi_id[0x03] lapic_id[0x03] enabled)
(XEN) ACPI: LAPIC_NMI (acpi_id[0xff] high edge lint[0x1])
(XEN) ACPI: IOAPIC (id[0x04] address[0xfec00000] gsi_base[0])
(XEN) IOAPIC[0]: apic_id 4, version 33, address 0xfec00000, GSI 0-23
(XEN) ACPI: IOAPIC (id[0x05] address[0xfec20000] gsi_base[24])
(XEN) IOAPIC[1]: apic_id 5, version 33, address 0xfec20000, GSI 24-55
(XEN) ACPI: INT_SRC_OVR (bus 0 bus_irq 0 global_irq 2 dfl dfl)
(XEN) ACPI: INT_SRC_OVR (bus 0 bus_irq 9 global_irq 9 low level)
(XEN) ACPI: IRQ0 used by override.
(XEN) ACPI: IRQ2 used by override.
(XEN) ACPI: IRQ9 used by override.
(XEN) Enabling APIC mode:  Flat.  Using 2 I/O APICs
(XEN) ACPI: HPET id: 0x10228201 base: 0xfed00000
(XEN) ERST table was not found
(XEN) HEST: Table parsing has been initialized
(XEN) Using ACPI (MADT) for SMP configuration information
(XEN) SMP: Allowing 4 CPUs (0 hotplug CPUs)
(XEN) IRQ limits: 56 GSI, 728 MSI/MSI-X
(XEN) xstate: size: 0x340 and states: 0x7
(XEN) AMD Fam16h machine check reporting enabled
(XEN) Using scheduler: SMP Credit Scheduler (credit)
(XEN) Platform timer is 14.318MHz HPET
(XEN) Detected 998.163 MHz processor.
(XEN) Initing memory sharing.
(XEN) alt table ffff82d0802bef18 -> ffff82d0802c0574
(XEN) AMD-Vi: IOMMU not found!
(XEN) I/O virtualisation disabled
(XEN) nr_sockets: 1
(XEN) ENABLING IO-APIC IRQs
(XEN)  -> Using new ACK method
(XEN) ..TIMER: vector=0xF0 apic1=0 pin1=2 apic2=0 pin2=0
(XEN) Allocated console ring of 32 KiB.
(XEN) mwait-idle: does not run on family 22 model 48
(XEN) HVM: ASIDs enabled.
(XEN) SVM: Supported advanced features:
(XEN)  - Nested Page Tables (NPT)
(XEN)  - Last Branch Record (LBR) Virtualisation
(XEN)  - Next-RIP Saved on #VMEXIT
(XEN)  - DecodeAssists
(XEN)  - Pause-Intercept Filter
(XEN)  - TSC Rate MSR
(XEN) HVM: SVM enabled
(XEN) HVM: Hardware Assisted Paging (HAP) detected
(XEN) HVM: HAP page sizes: 4kB, 2MB, 1GB
(XEN) HVM: PVH mode not supported on this platform
(XEN) spurious 8259A interrupt: IRQ7.
(XEN) CPU1: No irq handler for vector e7 (IRQ -2147483648)
(XEN) CPU2: No irq handler for vector e7 (IRQ -2147483648)
(XEN) Brought up 4 CPUs
(XEN) CPU3: No irq handler for vector e7 (IRQ -2147483648)
(XEN) build-id: dff6bad5189f35adc717d7989e1e2c87b87860cc
(XEN) ACPI sleep modes: S3
(XEN) VPMU: disabled
(XEN) MCA: Use hw thresholding to adjust polling frequency
(XEN) mcheck_poll: Machine check polling timer started.
(XEN) Dom0 has maximum 632 PIRQs
(XEN) NX (Execute Disable) protection active
(XEN) *** LOADING DOMAIN 0 ***
(XEN)  Xen  kernel: 64-bit, lsb, compat32
(XEN)  Dom0 kernel: 64-bit, PAE, lsb, paddr 0x1000000 -> 0x26de000
(XEN) PHYSICAL MEMORY ARRANGEMENT:
(XEN)  Dom0 alloc.:   0000000124000000->0000000128000000 (114688 pages to be allocated)
(XEN) VIRTUAL MEMORY ARRANGEMENT:
(XEN)  Loaded kernel: ffffffff81000000->ffffffff826de000
(XEN)  Init. ramdisk: 0000000000000000->0000000000000000
(XEN)  Phys-Mach map: 0000008000000000->0000008000100000
(XEN)  Start info:    ffffffff826de000->ffffffff826de4b4
(XEN)  Page tables:   ffffffff826df000->ffffffff826f6000
(XEN)  Boot stack:    ffffffff826f6000->ffffffff826f7000
(XEN)  TOTAL:         ffffffff80000000->ffffffff82800000
(XEN)  ENTRY ADDRESS: ffffffff82498180
(XEN) Dom0 has maximum 4 VCPUs
(XEN) Scrubbing Free RAM on 1 nodes using 4 CPUs
(XEN) ..........done.
(XEN) Initial low memory virq threshold set at 0x4000 pages.
(XEN) Std. Loglevel: All
(XEN) Guest Loglevel: All
(XEN) *** Serial input -> DOM0 (type 'CTRL-a' three times to switch input to Xen)
(XEN) Freed 312kB init memory
(XEN) PCI add device 0000:00:00.0
(XEN) PCI add device 0000:00:02.0
(XEN) PCI add device 0000:00:02.2
(XEN) PCI add device 0000:00:02.3
(XEN) PCI add device 0000:00:02.4
(XEN) PCI add device 0000:00:08.0
(XEN) PCI add device 0000:00:10.0
(XEN) PCI add device 0000:00:11.0
(XEN) PCI add device 0000:00:13.0
(XEN) PCI add device 0000:00:14.0
(XEN) PCI add device 0000:00:14.3
(XEN) PCI add device 0000:00:14.7
(XEN) PCI add device 0000:00:18.0
(XEN) PCI add device 0000:00:18.1
(XEN) PCI add device 0000:00:18.2
(XEN) PCI add device 0000:00:18.3
(XEN) PCI add device 0000:00:18.4
(XEN) PCI add device 0000:00:18.5
(XEN) PCI add device 0000:01:00.0
(XEN) PCI add device 0000:02:00.0
(XEN) PCI add device 0000:03:00.0
```

The thing that we are concerned about and want to fix is

```
(XEN) AMD-Vi: IOMMU not found!
```

There are some patches pending to enable IOMMU. Of course, enabling this
features open new universe with various advanced virtualization features which
we hope to discuss in further blog posts.

## Trying Xen boot params

I tried to use `iommu=on amd_iommu=on` which doesn't change anything with
firmware not-IOMMU capable.

## Summary

In further posts, I would like to get through IOMMU enabling by leveraging great
community work from Kyosti and Timothy. Also, I would like to exercise and prove
various virtualization features of PC Engines apu2. If you are interested in
commercial enablement of advanced SoC features feel free to let us know at
`contact@3mdeb.com`. Also feel free to contribute to pxe-server mini-project
as well as comment below.

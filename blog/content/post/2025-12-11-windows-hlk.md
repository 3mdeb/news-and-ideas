---
title: Windows HLK for Firmware validation
abstract: 'Learn about introducing a new tool to the arsenal of Dasharo testers.
           Windows Hardware Lab Kit - a framework able to perform over 3000 tests
           used to certify hardware and drivers as compatible with Windows'
cover: /covers/image-file.png
author: filip.golas
layout: post
published: true    # if ready or needs local-preview, change to: true
date: 2025-11-01    # update also in the filename!
archives: "2025"

tags:               # check: https://blog.3mdeb.com/tags/
  - Testing
  - Validation
  - Dasharo
categories:         # choose 1 or multiple from the list below
  - Miscellaneous

---

## Table of contents

1. Introduction and Background
1. Why Are We Interested in Windows HLK
2. Windows HLK Overview
3. Setup and Environment Configuration
4. Integration with Open Source Firmware Validation
5. Result Analysis and Product Quality Impact
6. Challenges, Mitigations, and Future Outlook

## Introduction and Background

Windows Hardware Lab Kit is the last iteration of a test automation framework
developed at Microsoft used to certify devices. The tool exists since the
times of Windows XP and has changed its name several times:

- Hardware Compatibility Test - Windows 2000, XP
- Driver Driver Kit - Windows Vista
- Windows Logo Kit / Windows Hardware Certification Kit - Windows 7, 8, 8.1
- Windows Hardware Lab Kit - Windows 10, 11

Windows HLK was quietly used every time we see a Windows sticker on a laptop,
a printer or even a game controller.

![Windows Logo certified sticker](/img/windows-sticker.png)
*https://www.microsoft.com/en-us/howtotell/hardware-pc-purchase*

In fact it contains at least `4659` unique test cases of the currently available
[test lists](https://aka.ms/HLKPlaylist).

Checked by searching for unique test IDs among listed in certification test lists:

```bash
grep -RhoP '<Test Id="\K[^"]+' "$PWD" | sort | uniq | wc -l
```

The tests cover functionality like:
- Audio, Video, Ethernet, Wi-Fi, Bluetooth
- GPIO, I2C, USB, NFC, PWM, SPI, UART, SATA, NVME
- Drivers
- TPM

And can be used to certify products like:
- Devices
  - Desktop computers, laptops, phones
  - game controllers, keyboards, mice
  - GPUs, audio, network cards, hard drives
  - proximity, IR, motion sensors, cameras, microphones
  - displays, projectors, scanners, paper and 3d printers
  - network routers, switches
- Software
  - file systems, anti virus software
  - media players

It should leave no room for doubt how HLK is a useful tool.

## Why Are We Interested in Windows HLK

As of writing this post there are `1321` test cases available in
[Open Source Firmware Validation](https://github.com/Dasharo/open-source-firmware-validation)
as well as `78` self tests to validate the OSFV itself. While it's an impressive
number, it's far behind the vast amount of nearly `5000` tests available
in HLK, which was being built since at least year `2000`.

![OSFV tests count per module](/img/osfv_test_counts_13_11_2025.png)
*OSFV tests count summary as of 13.11.2025* <!--TODO update before merging -->
It's only natural that the idea of using this huge collection of test cases
to aid Dasharo developers in finding places for improvement, as well as proving
where Dasharo works well already is very tempting. Especially considering that
new Windows issues not covered by OSFV do spring up like mushrooms

- [Immediate BSOD trying to boot Windows](https://github.com/Dasharo/dasharo-issues/issues/1598)
- [Error when enabling BitLocker](https://github.com/Dasharo/dasharo-issues/issues/1580)
- [Windows Device Manager shows errors even after updates](https://github.com/Dasharo/dasharo-issues/issues/1570)
- [Error while installing Windows 11 via USB drive](https://github.com/Dasharo/dasharo-issues/issues/1569)
- [USB mouse not working in Windows installer (USB pen drive installation)](https://github.com/Dasharo/dasharo-issues/issues/1568)
- [Windows SPM 2x suspend fails](https://github.com/Dasharo/dasharo-issues/issues/1521)

The thing that reels us in the most currently is the
[`Device.TrustedPlatformModule`](https://learn.microsoft.com/en-us/windows-hardware/test/hlk/testref/device-trustedplatformmodule-tests)
category including tests for TPM 2.0 functionality, cryptogtraphic operations,
storage, reliability and even some stress tests. While the tests would only
be run on Windows, as that's the purpose of Windows HLK, their results could
tell us a lot about the TPM functionality in Dasharo Firmware as a whole.

## Windows HLK Overview

Windows HLK manages the test execution workflow and the tested devices
differently than OSFV using Robot Framework.

![HLK Lab diagram](/img/2025-12-11-hlk.png)
*Multiple testers use single HLK Studio to access multiple HLK Controllers to run tests on multiple HLK Clients*

This architecture is more centralized than OSFV, where every tester runs
their tests independently of each other. The single point of synchronization is
the `Snipe-IT` instance that allows to manage the access to the Devices Under Test
(DUTs), so the testers don't interfere each other.

### HLK Components

A minimal Windows HLK setups is constructed of 3 components:

#### HLK CLient

The HLK Client is installed on a Device Under Test. The software allows remote
control by other HLK components in order to perform the tests.

HLK Client is able to scan for information about the device needed to determine
which tests are compatible with it. With that information the set of tests
that need to be passed in order to get the Windows Logo certification will
change to fit the specific device's capabilities.

#### HLK Controller

The tests server that manages the access to HLK Clients,
connects to them, runs tests and gathers the results.

One controller can manage up to about 150 HLK Clients. The
exact number is not a hardcoded limit, but a sane amount of computation that
a single machine can handle, so it depends on the hardware.

One HLK Client can only be managed by a single HLK Controller.

#### HLK Studio

A frontend for managing Windows HLK controllers. It can be used to explore
the available tests, ongoing runs, the results etc.

It can be installed on the same machine as HLK Controller if there is only
a single one, but for larger labs with multiple controllers HLK studio should
run on a separate device.

### HLK Lab diagram

![OSFV Lab diagram](/img/2025-12-11-hlk-osfv.png)
*Multiple testers ask single Snipe-IT instance for access, then run tests directly on DUT*

A more similar approach is possible in case of OSFV though through the use of
a centralized runner. It is especially useful when the tests are supposed to run
for a night or longer and the tester's workstation can't be trusted to work
reliably in that time.

![OSFV Lab \w runner diagram](/img/2025-12-11-hlk-osfv-vm.png)
*Multiple testers ask single Snipe-IT instance for access, then run tests via a runner*


## Setup and Environment Configuration

Windows HLK can only be set up on devices running Windows Server.

We didn't have a need for a Windows Server machine before at the Dasharo
Certification Lab and the expected load in the nearest future won't be high
as the amount of devices tested on the same time does not exceed just a couple.
There is no plan to include HLK tests as an integral part of Dasharo release
process, so the usage will not only be low, but also occasional.

These observations resulted in the decision to set up the HLK server on a
Proxmox Virtual Machine, which, as we will find in the later sections,
might need to be revisited due to performance limitations.

### Windows HLK Server - Proxmox

The installation on a virtual machine was pretty straightforward, but there
were a couple caveats encountered that required addressing.

#### OS

In the OS section we can choose an installer ISO image for the Windows Server.
The Guest OS `Type` should be set to `Microsoft Windows`.

![Proxmox Create VM OS section for Windows Server](/img/windows_server_vm_proxmox_os.png)
*Proxmox Create VM OS section for Windows Server, choose Type as Microsoft Windows*

#### Disks

Microsoft recommends a drive of at least 32GiB.
After installing HLK it leaves the VM with just about 4GiB of free space.

We recommend allocating more space if resizing in the future won't be possible,
as the packaged test results can take more than 100MiB each.

#### CPU

In the CPU section, it is important to give the VM at least `2` CPU cores,
and enable `NUMA`. Otherwise the installer won't be able to boot.

![Proxmox Create VM CPU section for Windows Server](/img/windows_server_vm_proxmox_cpu.png)
*Proxmox Create VM CPU section for Windows Server, select at least 2 cores and enable NUMA*

#### Memory

In the Memory section, we need to give the VM at least `8196 MiB` of RAM.
Otherwise the RAM usage will be topped out constantly and the machine will be
nearly unusable. The memory can be configured to be dynamic if it is not
a resource we are willing to reserve only to this VM.

![Proxmox Create VM Memory section for Windows Server](/img/windows_server_vm_proxmox_memory.png)
*Proxmox Create VM Memory section for Windows Server, select at least 8196 MiB and
4096 MiB of minimum memory*

We can now skip past the remaining sections and create the VM.

#### Virtio Drivers

One last thing to remember is that Windows does not come bundled with VirtIO
drivers - the VM won't be able to access its virtual hard drive and install
the OS.

To help with that, we need to attach a second iso image alongside the installer
that will contain VirtIO drivers.

In the `Hardware` tab of the newly created VM we add a `CD/DVD Drive` and attach
the ISO containg [Windows VirtIO drivers by RedHat](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/).

![Proxmox Adding Virtio drive to Windows VM](/img/windows_server_vm_proxmox_virtio.png)
*Proxmox Adding Virtio drive to Windows VM*

### Windows HLK Server Setup

To set up the HLK server on a VM we need to:
- Install Windows Server on a VM
- Install VirtIO drivers in the OS
- Install Windows HLK Controller and Studio
- Setup Network Discovery and Shares
- Note HLK Controller Device Name

#### Installer Setup

During the installer setup there's only one thing different than when installing
on a hardware device to remember. When presented with this screen:

![Windows Installer no drives](/img/windows-installer-no-drives.png)

There's nothing wrong. Just press `Load Driver` and locate the VirtIO drive
we've attached before in Proxmox. The installer will load the drivers and it
will be possible to choose the virtual drive as an installation destination.

The installation should continue without further hiccups.

#### Installing VirtIO drivers

The VirtIO disk drivers were installed by the Windows installer, but after
logging to the desktop, there will be no way of accessing the network.

For efficient network connection Proxmox attaches a VirtIO network card to the
VM by default, and there are no drivers for such things in Windows.

To install the rest of the VirtIO drivers and VM Guest tools that allow to, for
example, display the IP address of the VM in Proxmox and dynamically change
the display resolution, we need to locate the same drive with the VirtIO drivers
and install them.

![Windows VirtIO installer wizard](/img/windows_server_vm_virtio_wizard.png)
*Windows VirtIO installer wizard*

Run the `virtio-win-gt-x64.msi` installer and follow the instructions from the
wizard. The OS should detect the network card afterwards.

#### Installing HLK Server

The installation of HLK Controller and Studio on a server is one of the simpler
steps. With network accessible in the VM we download a version suitable for
the Windows version we want to be certifying for at
[learn.microsoft HLK docs](https://learn.microsoft.com/en-us/windows-hardware/test/hlk/)
and run the `.exe` installer which will lead us through the installation.
When prompted we chose to install both the `HLK Controller` and `HLK Studio` on
the same machine, as that's enough for less than about a hundred DUTs.

In our case we download the `Windows HLK for Windows 11, version 25H2` version
to certify for `Windows 11, version 25H2`.

#### Network Discovery and Shares
At this point it's worth verifying whether Network Discovery and file sharing
are enabled on the server. Without Network Discovery enabled
the server and client devices won't see each other and without File sharing
we won't be able to install the HLK client on a DUT.

To ensure the two settings are anabled open the `Settings` app and navigate
to `Network & internet` > `Advanced sharing settings` and make sure both
`Network discovery` and `File and printer sharing` are enabled.

![Windows Server Advanced sharing settings](/img/windows_server_vm_network_settings.png)

#### Device Name

To identify the HLK Controller server later we will need to note the device name
or give a friendly name to the server ourselves. Both options are available in:
`Settings App` > `System` > `About`

![Windows Controller Device Name](/img/windows_server_vm_device_name.png)

### Windows HLK Client Setup

For the client setup we will assume, that Windows 11 is already installed on
the DUT and only focus on the post installatoin steps required to allow running
HLK tests.

#### Network Discovery

The step is mostly the same as for the HLK server.
Open the `Settings` app, navigate
to `Network & internet` > `Advanced sharing settings` and make sure both
`Network discovery` and `File and printer sharing` are enabled.

#### Installing HLK Client

Interestingly there is no HLK Client installer available in the web.
To avoid incompatibility issues, the installer executable is being hosted by
the HLK Controller. By running the installer from a selected controller the
Client device will be automatically associated with the HLK Controller and
the HLK versions will always be compatible.

To install HLK Client:
- via command prompt
  - run `\\<HLK_Controller_Device_Name>\HLKInstall\Client\Setup.cmd /qn ICFAGREE=Yes`
- via the GUI
  - Open File Manager
  - Go to the `Network` tab under `This PC`
  - Select the HLK Controller using the Device Name noted before
    - a prompt will appear asking to enter credentials for the HLK Server
  - Go to `HLKInstall\Client` and run `Setup.cmd`

An installation wizard will lead us through the installation.



{{< subscribe_form "dbbf5ff3-976f-478e-beaf-749a280358ea" "Subscribe to 3mdeb Newsletter" >}}

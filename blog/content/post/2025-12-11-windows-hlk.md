---
title: Windows HLK for Firmware validation
abstract: 'Learn about introducing a new tool to the arsenal of Dasharo testers.
 Windows Hardware Lab Kit - a framework able to perform over 3000 tests
 used to certify hardware and drivers as compatible with Windows'
cover: /covers/windows-hlk-logo.png
author: filip.golas
layout: post
published: true    # TODO
date: 2025-11-01    # TODO
archives: "2025"

tags:
 - Testing
 - Validation
 - Dasharo
categories:
 - Miscellaneous

---

## Table of contents

1. [Introduction and Background](#introduction-and-background)
1. [Why Are We Interested in Windows HLK](#why-are-we-interested-in-windows-hlk)
2. [Windows HLK Overview](#windows-hlk-overview)
3. [Setup and Environment Configuration](#setup-and-environment-configuration)
4. [Integration with Open Source Firmware Validation](#integration-with-open-surce-firmware-validation)
5. [Results and Future Outlook](#results-and-future-outlook)

## Introduction and Background

The Windows Hardware Lab Kit is the last iteration of a test automation framework
developed at Microsoft, used to certify devices. The tool has existed since the
times of Windows XP and has changed its name several times:

- Hardware Compatibility Test - Windows 2000, XP
- Driver Driver Kit - Windows Vista
- Windows Logo Kit / Windows Hardware Certification Kit - Windows 7, 8, 8.1
- Windows Hardware Lab Kit - Windows 10, 11

Windows HLK was quietly used every time we see a Windows sticker on a laptop,
a printer or even a game controller.
<img src="/img/windows-hlk/windows-stickerd.png" alt="Windows Logo certified sticker" style="width:50%"/>
*https://www.microsoft.com/en-us/howtotell/hardware-pc-purchase*

In fact, it contains at least __4659__ unique test cases of the currently available
[test lists](https://aka.ms/HLKPlaylist).

Checked by searching for unique test IDs among those listed in the certification
test lists:

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
  - displays, projectors, scanners, paper, and 3d printers
  - network routers, switches
- Software
  - file systems, antivirus software
  - media players

It should leave no room for doubt that HLK is a valuable tool.

## Why Are We Interested in Windows HLK

As of writing this post, there are __1321__ test cases available in
[Open Source Firmware Validation](https://github.com/Dasharo/open-source-firmware-validation)
as well as 78 self-tests to validate the OSFV itself. While it's an impressive
number, it's far behind the vast amount of nearly __5000__ tests available
in HLK, which was being built since at least the year 2000.

![OSFV tests count per module](/img/windows-hlk/osfv_test_counts_13_11_2025.png)
*OSFV tests count summary as of 13.11.2025* <!--TODO update before merging -->
It's only natural that the idea of using this huge collection of test cases
to aid Dasharo developers in finding places for improvement, as well as proving
where Dasharo works well already, is very tempting. Especially considering that
new Windows issues not covered by OSFV do spring up like mushrooms.

- [Immediate BSOD trying to boot Windows](https://github.com/Dasharo/dasharo-issues/issues/1598)
- [Error when enabling BitLocker](https://github.com/Dasharo/dasharo-issues/issues/1580)
- [Windows Device Manager shows errors even after updates](https://github.com/Dasharo/dasharo-issues/issues/1570)
- [Error while installing Windows 11 via USB drive](https://github.com/Dasharo/dasharo-issues/issues/1569)
- [USB mouse not working in Windows installer (USB pen drive installation)](https://github.com/Dasharo/dasharo-issues/issues/1568)
- [Windows SPM 2x suspend fails](https://github.com/Dasharo/dasharo-issues/issues/1521)

The thing that reels us in the most currently is the
[`Device.TrustedPlatformModule`](https://learn.microsoft.com/en-us/windows-hardware/test/hlk/testref/device-trustedplatformmodule-tests)
category including tests for TPM 2.0 functionality, cryptographic operations,
storage, reliability, and even some stress tests. While the tests would only
be run on Windows, as that's the purpose of Windows HLK, their results could
tell us a lot about the TPM functionality in Dasharo Firmware as a whole.

## Windows HLK Overview

Windows HLK manages the test execution workflow and the tested devices
differently from OSFV using Robot Framework.

![HLK Lab diagram](/img/windows-hlk/2025-12-11-hlk.png)
*Multiple testers use a single HLK Studio to access multiple HLK Controllers to run tests on multiple HLK Clients*

This architecture is more centralized than OSFV, where every tester runs
their tests independently of each other. The single point of synchronization is
the `Snipe-IT` instance that allows managing access to the Devices Under Test
(DUTs), so the testers don't interfere with each other.

### HLK Components

A minimal Windows HLK setup is constructed of 3 components:

#### HLK Client

The HLK Client is installed on a Device Under Test. The software allows remote
control by other HLK components to perform the tests.

HLK Client can scan for information about the device needed to determine
which tests are compatible with it. With that information, the set of tests
that need to be passed to get the Windows Logo certification will
change to fit the specific device's capabilities.

#### HLK Controller

The test server that manages the access to HLK Clients,
connects to them, runs tests, and gathers the results.

One controller can manage up to about 150 HLK Clients.
The exact number is not a hardcoded limit, but a sane amount of
computation that a single machine can handle, so it depends on the hardware.

One HLK Client can only be managed by a single HLK Controller.

#### HLK Studio

A frontend for managing Windows HLK controllers. It can be used to explore
the available tests, ongoing runs, the results, etc.

It can be installed on the same machine as the HLK Controller if there is only
a single one, but for larger labs with multiple controllers, HLK Studio should
run on a separate device.

### HLK Lab diagram

![OSFV Lab diagram](/img/windows-hlk/2025-12-11-hlk-osfv.png)
*Multiple testers ask a single Snipe-IT instance for access, then run tests directly on DUT*

A more similar approach is possible in the case of OSFV through the use of
a centralized runner. It is beneficial when the tests are supposed to run
for a night or longer, and the tester's workstation can't be trusted to work
reliably for that time.

![OSFV Lab \w runner diagram](/img/windows-hlk/2025-12-11-hlk-osfv-vm.png)
*Multiple testers ask a single Snipe-IT instance for access, then run tests via a runner*


## Setup and Environment Configuration

Windows HLK can only be set up on devices running Windows Server.

We didn't need a Windows Server machine before at
the Dasharo Certification Lab and the expected load in the near future
won't be high, as the number of devices tested at the same time does not
exceed just a couple. There is no plan to include HLK tests as an integral
part of the Dasharo release process, so the usage will not only be low,
but also occasional.

These observations resulted in the decision to set up the HLK server on a
Proxmox Virtual Machine, which, as we will find in the later sections,
might need to be revisited due to performance limitations.

### Windows HLK Server - Proxmox

The installation on a virtual machine was pretty straightforward,
but there were a couple of caveats encountered that required addressing.

#### OS

In the OS section, we can choose an installer ISO image for the Windows Server.
The Guest OS `Type` should be set to `Microsoft Windows`.

![Proxmox Create VM OS section for Windows Server](/img/windows-hlk/windows_server_vm_proxmox_os.png)
*Proxmox Create VM OS section for Windows Server, choose Type as Microsoft Windows*

#### Disks

Microsoft recommends a drive of at least 32 GiB.
After installing HLK, it leaves the VM with just about 4 GiB of free space.

We recommend allocating more space if resizing in the future won't be possible.
The packaged test results can take more than 100MiB each.

#### CPU

In the CPU section, it is essential to give the VM at least two CPU cores
and enable `NUMA`. Otherwise, the installer won't be able to boot.

![Proxmox Create VM CPU section for Windows Server](/img/windows-hlk/windows_server_vm_proxmox_cpu.png)
*Proxmox Create VM CPU section for Windows Server, select at least two cores and enable NUMA*

#### Memory

In the Memory section, we need to give the VM at least 8196 MiB of RAM.
Otherwise, the RAM usage will be topped out constantly, and the machine will be
nearly unusable. The memory can be configured to be dynamic if it is not
a resource we are willing to reserve only for this VM.

![Proxmox Create VM Memory section for Windows Server](/img/windows-hlk/windows_server_vm_proxmox_memory.png)
*Proxmox Create VM Memory section for Windows Server, select at least 8196 MiB, and
4096 MiB of minimum memory*

We can now skip past the remaining sections and create the VM.

#### VirtIO Drivers

One last thing to remember is that Windows does not come bundled with VirtIO
drivers - the VM won't be able to access its virtual hard drive and install
the OS.

To help with that, we need to attach a second iso image alongside the installer
that will contain VirtIO drivers.

In the `Hardware` tab of the newly created VM, we add a `CD/DVD Drive` and attach
an ISO with the [Windows VirtIO drivers by Red Hat](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/).

![Proxmox Adding VirtIO drive to Windows VM](/img/windows-hlk/windows_server_vm_proxmox_virtio.png)
*Proxmox Adding VirtIO drive to Windows VM*

### Windows HLK Server Setup

To set up the HLK server on a VM, we need to:
- Install Windows Server on a VM
- Install VirtIO drivers in the OS
- Note HLK Controller Device Name
- Install Windows HLK Controller and Studio
- Set up Network Discovery and Shares

#### Installer Setup

During the installer setup, there's only one thing different from installing
on a hardware device to remember. When presented with this screen:

![Windows Installer no drives](/img/windows-hlk/windows-installer-no-drives.png)

There's nothing wrong. Just press `Load Driver` and locate the VirtIO drive
we've attached before in Proxmox. The installer will load the drivers, and it
will be possible to choose the virtual drive as an installation destination.

The installation should continue without further hiccups.

#### Installing VirtIO drivers

The Windows installer has installed the VirtIO disk drivers, but after
logging to the desktop, there will be no way of accessing the network.

For efficient network connection, Proxmox attaches a VirtIO network card to the
VM by default, and there are no drivers for such things on Windows.

We can install the rest of the VirtIO drivers and VM Guest tools that allow us, for example, to display the IP address of the VM in Proxmox and dynamically change the display resolution. To do so, we need to locate the drive with the VirtIO drivers and install them.

![Windows VirtIO installer wizard](/img/windows-hlk/windows_server_vm_virtio_wizard.png)
*Windows VirtIO installer wizard*

Run the `virtio-win-gt-x64.msi` installer and follow the instructions from the
wizard. The OS should detect the network card afterwards.

#### Device Name

To identify the HLK Controller server later, we will need to note the device name
or give a friendly name to the server ourselves. Both options are available in:
`Settings App` > `System` > `About`.

![Windows Controller Device Name](/img/windows-hlk/windows_server_vm_device_name.png)

It's important to change the device name (and reboot if so) before we set up
HLK. Otherwise, the HLK Controller and Studio would need to be reinstalled
to update the device names.

#### Installing HLK Server

The installation of HLK Controller and Studio on a server is one of the simpler
steps. With the network accessible in the VM, we download a version suitable for
the Windows version we want to certify for at
[learn.microsoft HLK docs](https://learn.microsoft.com/en-us/windows-hardware/test/hlk/)
and run the `.exe` installer, which will lead us through the installation.
When prompted, we chose to install both the HLK Controller and HLK Studio on
the same machine, as that's enough for less than about a hundred DUTs.

In our case, we've downloaded the `Windows HLK for Windows 11, version 25H2` version
to certify for `Windows 11, version 25H2`.

#### Network Discovery and Shares
At this point, it's worth verifying whether Network Discovery and file sharing
are enabled on the server. Without Network Discovery enabled, the server and client devices won't see each other, and without File sharing,
we won't be able to install the HLK client on a DUT.

To ensure the two settings are enabled, open the `Settings` app and navigate
to `Network & internet` > `Advanced sharing settings` and make sure both
`Network discovery` and `File and printer sharing` are enabled.

![Windows Server Advanced sharing settings](/img/windows-hlk/windows_server_vm_network_settings.png)

### Windows HLK Client Setup

For the client setup, we will assume that Windows 11 is already installed on
the DUT and only focus on the post-installation steps required to allow running
HLK tests.

#### Network Discovery

The step is mostly the same as for the HLK server.
Open the `Settings` app, navigate
to `Network & internet` > `Advanced sharing settings`, and make sure both
`Network discovery` and `File and printer sharing` are enabled.

#### Installing HLK Client

Interestingly, there is no HLK Client installer available on the web.
To avoid incompatibility issues, the installer executable is being hosted by
the HLK Controller. By running the installer from a selected controller, the
The client device will be automatically associated with the HLK Controller, and
the HLK versions will always be compatible.

To install HLK Client:
- via command prompt
  - run `\\<HLK_Controller_Device_Name>\HLKInstall\Client\Setup.cmd /qn ICFAGREE=Yes`
    - Despite it being documented on MS Learn, it might not work as
 no prompt for password appears when running from CMD.
- via the GUI
  - Open File Manager
  - Go to the `Network` tab under `This PC`
  - Select the HLK Controller using the Device Name noted before
    - A prompt will appear asking to enter credentials for the HLK Server
  - Go to `HLKInstall\Client` and run `Setup.cmd`

An installation wizard will lead us through the installation.

### Tests setup

Now that our HLK Server and HLK Client are installed on the devices, the last
thing to do is to run some tests.

For that, we'll use the HLK Studio app, which is a new (~15 y.o.) GUI for the
HLK Controller, which is supposed to simplify the process of managing tests
as opposed to the older, more complicated, but more capable HLK Manager.

![HLK Studio](/img/windows-hlk/windows-hlk-studio.png)
*Windows HLK Studio*

![HLK Manager](/img/windows-hlk/windows-hlk-manager.png)
*Windows HLK Manager*

#### Configuration

The first thing we need to do is to create a _Machine Pool_. A machine pool
will be used to run a single set of tests in order to certify a device.
We can have as many identical devices in a single machine pool as we want.
As long as the HLK Server is powerful enough, the tests will be run in
parallel on all of them.

To create a machine pool:
1. Click `Configuration` in the top right corner
   1. The Machines with the HLK Client installed before should be visible in the list
2. Right-click on `$ (Root)` machine pool on the `Machine Pools` list
3. Select `Create Machine Pool`
4. Type in a name and press Enter
   1. The Machines on the right side should disappear as they are a part of the
      `$ (Root)` machine pool by default
5. Go back to the `$ (Root)` machine pool by left-clicking it to bring back the
6. Drag and drop the machine from the list onto the newly created machine pool
7. Go back to the main screen by pressing the back arrow in the top left corner

#### Adding a project

Tests in HLK are categorized into projects.
In a given project, there is a single result of a test on any machine
in the project.

When the configuration changes (like a new revision, model,
or it's an entirely different device) or there is any other reason to re-run
a test without invalidating previous results, a new project
should be created.

![Creating a project in the Project tab](/img/windows-hlk/windows-hlk-create-project.png)
*Creating a project in the Project tab*

Multiple projects can be merged to create a single test results package sent
to Microsoft for verification, so a single device could be separated into
multiple projects to organise different components.

When the project is created, double-click it on the list to select the project
as active.

#### Device Selection

With the project created, we can go to the `Selection` tab to select the devices
we want to test in the project.

![Selection tab](/img/windows-hlk/windows-hlk-device-selection.png)
*Selection tab: `$\Dasharo` device pool and `DESKTOP-PORM3MO` selected for the project*

A project can use any subset of devices from any subset of available pools.
Two projects can use the same device, HLK Controller will handle that, but
only a single test can be run on a single device at the same time, so that
might be suboptimal.

Upon checking the checkbox for a device, HLK Controller will scan it
for compatible tests that can be run on it.

#### Test selection

In the test tab, we can select the tests to run from a list of compatible
test cases and schedule them to run at any time by pressing `Run Selected`.
The tests can very well be scheduled and canceled while other tests are
already running.

![Tests Tab](/img/windows-hlk/windows-hlk-tests-tab.png)
*Tests tab; `Check SMBIOS Table* test selected

The test selection can be exported using `Save Selected As Playlist` or imported
using `Load Playlist`.

#### Results Tab

The `Tests` tab already shows the status of every test, including whether they
have passed or failed. The `Results` tab contains more details about the
execution in the form of an expandable list for every test run.

![Results Tab](/img/windows-hlk/windows-hlk-results-tab.png)
*Results Tab; Wlan Device Enumeration test's details expanded*

A single test can produce multiple files with logs in XML format,
which HLK Manager will neatly render into a table after a double click.

![Example test report](/img/windows-hlk/test-report.png)
*Example test report*

Because the tests in HLK are in binary format (DLLs) and their sources are not
openly available, extracting useful information about what exactly happened
and how to fix the issues causing fails is hard or sometimes impossible to
come by just from the log files. It all depends on the specific test step and
how much useful logging is implemented in it.

![Example failed step](/img/windows-hlk/failed-test2.png)
*Example failed test step causing a test to FAIL; The actual cause is not obvious*

#### Package Tab

The `Package` tab is where the test results can be packaged alongside driver
files and other supplementary files. The _Package_ can be signed and then sent
to certify our hardware, or to share the results.

![Package tab](/img/windows-hlk/windows-hlk-package-tab.png)

With a package containing passed tests created, the journey of a project ends.


## Integration with Open Source Firmware Validation

An important subject of running Windows HLK tests in our Dasharo Certification
Lab is how to integrate the tests with our current testing framework.

We've decided that the HLK tests won't be integrated into OSFV and instead
be treated as a separate source of validation due to a couple of technical reasons.

### Communication

OSFV operates using interactive terminals via SSH and serial connections.
Windows HLK, on the other hand, is mainly operated using a GUI, although there's
an [API](https://learn.microsoft.com/en-us/windows-hardware/test/hlk/api/hlk-api-reference)
with a [developer guide](https://learn.microsoft.com/en-us/windows-hardware/test/hlk/developer/hlk-developer-guide)
that allows to operate it remotely.

The API, though, operates on .NET and requires
running either PowerShell or a .NET application in a Windows environment to work
on WMI/CIM objects to communicate with the HLK Controller.

Even analysing the test results without using the API would be difficult.
The directory containing the XML logs is well known, but the logs themselves
are held in a structure of directories with UUIDs as names and no way of
reliably navigating them without interfacing with the Controllers' database.

### Showing results

Up until the total number of test cases available in HLK was identified
(~4x the amount in OSFV), we had an idea to wrap HLK tests in the OSFV test ID
convention and present them alongside.

We've come to a realization that creating a test ID, name, and maybe creating test
cases in OSFV that schedule the tests would be an immense amount of work, that
doesn't really bring any value to the test results themselves.

## Results and Future Outlook

To test the setup and get a hang of the state of validation in the eyes of
Microsoft for a `NovaCustom NV41PZ` laptop with `Dasharo v1.7.2` release, we've
scheduled all the tests detected as compatible with the machine and left
Windows HLK for a weekend to do its thing.

It was set up so that the shortest ones run first. There were about 150 tests that
should take about 1 minute, and just as many tests that take
3–5 minutes, then around 360 tests that take 15 minutes each.

At the very end, there were about 60 tests scheduled that take 30–60 minutes,
and there are a few that take several hours, or even one that takes a __24 hours__.

### Test Runtime

After about 60 hours of runtime, `150/764` tests have finished running.
It was only the tests that were supposed to take 1 minute each, so it should
have taken about __two and a half hours__ to complete them, but in reality, it took
__60 hours__.

If we were to interpolate the runtime, while keeping the velocity of 30 minutes
per 1-minute test, all the 764 tests could take a whopping __250 DAYS__ to
complete on a single client device.

HLK Controller needs to run on a fast device to meet the expected
runtimes. In our case, it is run on two cores of a server CPU that is long
past its prime. The layer of virtualization does not help either.

By increasing the number of cores reserved to the VM from 2 to 4 and the max
RAM allocation to 12 GiB, the run times, and overall GUI responsiveness have
improved, but not that significantly, but that did not solve the issue
completely.

### Test Results

Accessing the results from a package file requires using the HLK API on Windows.
To parse the results more easily, we can:
- Left-click on the first test on the results list
- Shift+left click on the last test on the results list to select every test
- Press Ctrl+C

A brief text representation of the list contents will be copied to the clipboard
and can be pasted into a text file, which we'll be able to download and parse
on Linux.
To access the Network Share of our server, we can mount it using the `CIFS`
protocol:

```bash
sudo mount -t cifs //<SERVER_NAME>/Users <DESTINATION> -o username=<USER_NAME>
```

The results were saved as `results.tsv` and parsed to remove any tests
skipped or canceled after the 60 hours of runtime, as well as remove unnecessary
info like the Windows name of the client machine:

```bash
cat results.tsv| grep -E "(Failed)|(Passed)" | cut -f1,2 | sort > results-filtered.tsv
```

The results shown here are for the 145 1-minute-long test cases out of the
total 764 tests supported by the device. The whole test scope was not performed
due to current performance limitations.

<img src="/img/windows-hlk/hlk-tests-results-pie.png" alt="Windows HLK test results on NovaCustom NV41PZ with Dasharo v1.7.2" style="width:80%"/>

You can access the full test results here:
[Test results on NovaCustom NV41PZ \w Dasharo v1.7.2 release](/files/results-filtered.tsv)

### Future Outlook

Windows HLK might prove to be an immensely useful tool in the toolkit
of Dasharo testers who will take part in making sure Microsoft Windows runs great on machines powered by Dasharo.

Integrating it with the regular test routine for Dasharo releases will require
more work in the aspects of:
- Automatic deployment
  - Installing Windows HLK Server and HLK Clients takes some time and should
 be performed automatically, ideally using https://github.com/dasharo/preseeds
- Run time
  - On the current setup, the full supported scope could take as much as
  __250 days__ for a single device
  - Deploying the HLK Server on a more powerful virtual, or better, a physical machine could prove necessary
- Run automation
  - Running the tests from a HLK Studio GUI via RDP is highly suboptimal
    - There is an exciting organization on GitHub [HCK-CI](https://github.com/HCK-CI)
 that has created a range of FOSS Linux tools for managing Windows HLK
    - Their Ruby gem [rtoolsHCK](https://github.com/HCK-CI/rtoolsHCK)
 was briefly tried out for accessing the test results, but some issues
 probably caused by the HLK Server configuration, which made it fail.
- Results publishing
  - The test results created by HLK Studio are in a binary format that is only readable
 by another Studio instance, which is not great for making the results
 public and freely available, like the [OSFV Results](https://github.com/Dasharo/osfv-results/)
  - Retrieving the results in a human-readable format is quirky
    - Tools like https://github.com/HCK-CI/rtoolsHCK could greatly help
 in that regard


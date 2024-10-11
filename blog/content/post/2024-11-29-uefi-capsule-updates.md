---
title: 'UEFI Update Capsules for Open Source firmware'
abstract: 'MSI Z690-A and Z790-P are the first Dasharo firmware releases to
           support UEFI capsule updates. The additional way to update your
           firmware aims at making the process more reliable and convenient.'
cover: /covers/capsule-updates.png
author: sergii.dmytruk
layout: post
published: true
date: 2024-11-29
archives: "2024"

tags:
  - coreboot
  - edk2
  - firmware
  - uefi
categories:
  - Firmware

---

![Screen while update is in progress](/img/uefi-capsule-update.png)

Dasharo firmware starts to support capsule updates.  This post looks into what
it is, why it is useful, and what has led to this.

## Capsule updates for MSI boards

The first boards to get the support are [MSI PRO Z690-A (v1.1.4)][z690] and [MSI
PRO Z790-P (v0.9.2)][z790] (all their WIFI/DDR4/DDR5 variants).  Do note that
the functionality cannot be used to update from previous firmware releases
for these boards.  Only future updates can leverage this update method unless
you use it to "reinstall" newest releases as an experiment.

Worth mentioning right away that this work was funded by [NLnet
Foundation][nlnet] in the interest of making updates of open source firmware a
more pleasant experience.  More details about the project can be found
[here][nlnet-project].

[z690]: https://docs.dasharo.com/variants/msi_z690/releases/#v114-2024-11-22
[z790]: https://docs.dasharo.com/variants/msi_z790/releases/#v092-2024-11-22
[nlnet]: https://nlnet.nl/
[nlnet-project]: https://docs.dasharo.com/projects/capsule-updates/

## Firmware updates

Firmware is a crucial software component without which a device can't function
properly, in fact, most likely can't function at all.  Like anything, firmware
is subject to defects and, due to its integral role for a device, a firmware
defect can have a significant impact on its operation.  A bad firmware can be
subject to an attack or sometimes cause a physical damage to a device.  Even in
the absence of any issues, an update might still be desirable to provide more
configuration options or support wider range of hardware.

For these and other reasons firmware updates are a necessity.  As devices
get more advanced, firmware defects become more likely, thus further increasing
the importance of keeping firmware up-to-date.

Unfortunately, carrying out a firmware update is a relatively difficult task
that itself can go wrong and lead to a broken device.  This is hard to address
in full, but some update methods are more user-friendly than others and update
capsules are an example of moving in the direction of greater convenience to
end users.

## Firmware update methods

Let's have a quick overview of update methods to have the necessary context for
discussing capsule updates.

First of all, an update can be performed either internally or externally.  An
external update often requires a special device (see [this kit][ec-kit] for an
idea) capable of updating a [flash chip] which contains the firmware.  The
device gets connected to a host machine (so you need a second PC/laptop) from
which the chip is updated via a specialized software (e.g., [flashrom] or
[flashprog]).

An internal update means that the system applies an update to itself, which can
happen in at least two different ways:

* By the firmware (e.g., after entering its setup interface and picking a file
  containing an update).
* By an application running in an operating system (a generic one like
  `flashrom` or a one provided by system's manufacturer).

[flash chip]: https://en.wikipedia.org/wiki/Flash_memory
[ec-kit]: https://shop.3mdeb.com/shop/open-source-hardware/ec-flashing-kit/
[flashrom]: https://flashrom.org/
[flashprog]: https://flashprog.org/

## What are UEFI capsules

UEFI Update Capsules (also update capsules, capsule updates or just capsules)
are a way of delivering firmware updates to UEFI firmware.  A file format in
which such updates are provided is known by the same name.

Capsule updates belong to an internal kind of updates performed by firmware
itself.  The details are defined in [UEFI specification][uefi-spec], but no
need to study it to be able to understand how capsules work.  In a nutshell:

* Firmware actively participates in the update process:
  * An update can be validated and rejected if it can't work on a specific
    hardware, thus preventing bricking the device.
  * Current settings and other kinds of user data can be preserved.
  * Regular security measures that cause other kinds of internal updates to fail
    can be lifted automatically.
  * Capsule updates can be performed without an OS.
* There are several ways for delivering updates:
  * Via `CapsuleApp.efi` in UEFI Shell (or really using any EFI application).
  * By an OS if it supports this kind of communication with the firmware.
* There are several ways in which a capsule can be delivered to a firmware:
  * In-RAM.  A capsule is left in RAM while the system reboots retaining RAM's
    contents.  This is what got implemented.
  * On-disk.  A firmware is tasked with reading a capsule from a designated
    directory on ESP (EFI System Partition).  This can be added in the future.
* There are several pre-defined kinds of capsules:
  * UX (User eXperience) capsules, responsible for providing some on-screen
    information about an ongoing update.
  * FMP (Firmware Management Protocol) capsules, these are the ones which carry
    the updated firmware.

The advantages of capsules are covered more verbosely in [the
documentation][capsules-overview].  One extra thing worth mentioning is that
capsules are already used by a number of firmware vendors (even though it might
not be obvious).  This convergence on a format allows for a more unified
distribution and handling of updates, in particular through [LVFS/fwupd][lvfs].

LVFS is not restricted to capsule updates alone and works with plain flash
images just fine.  However, use of capsules comes with their advantages such as
data migration.  Doing it with plain images would require modifying `fwupd`,
while capsules provide the same functionality regardless of how they are
applied.

As for disadvantages, because an update is carried out without user interactions
and before any OS is loaded an unexpected error can result in an unbootable
system.  That is always a possibility, yet with some other internal flashing
methods it might be possible to keep the machine running while trying to
restore flash contents to a reasonable state.

[uefi-spec]: https://uefi.org/specs/UEFI/2.10_A/
[capsules-overview]: https://docs.dasharo.com/kb/capsule-updates-overview/
[lvfs]: https://fwupd.org/

## How a capsule update works

In general, it is possible for a capsule to be processed immediately or after a
system reboot.  System firmware updates fall into the second category, so a
successful update looks as follows:

1. Pass capsule to the firmware (see below for several ways to do it).
2. Reboot (can happen automatically as part of the first step).
3. Firmware detects presence of a capsule, runs all the necessary checks and
   applies the capsule while the user looks at a progress bar.  Like with any
   firmware update, it's very important to not power off the machine during
   this process.
4. The machine reboots again but this time boots into a different firmware.

An unsuccessful update looks very similar, but it's still an old version at the
last step (assuming nothing went horribly wrong and the system can still start).

## How to perform a capsule update

One way of doing it is running `CapsuleApp.efi` in a UEFI shell.  This is
thoroughly explained in [the documentation][update-guide].

[DTS] should be able to use capsules as well, but there the process will mostly
be hidden from the user.

A Linux-specific way is to write a capsule into a special device which is
typically not present by default:

```bash
# load corresponding kernel module
modprobe capsule-loader
# send the capsule
cat firmware-update.cap > /dev/efi_capsule_loader
# perform warm reset to let firmware process the capsule (might not work if
# kernel was instructed to not do a warm reset)
reboot
```

The next section of the post will be a bit more technical.  Skip everything
until [What's next](#whats-next) if you're not interested in this part.

[update-guide]: https://docs.dasharo.com/guides/capsule-update/
[dts]: https://docs.dasharo.com/dasharo-tools-suite/overview/

## Changes to firmware components (coreboot and EDK2) and difficulties

### Publication of ESRT

ESRT (EFI System Resource Table) is a way in which a UEFI firmware declares
versions of firmware components.  UEFI capsules target a specific entry in the
table and can only be applied if a suitable entry is reported by the currently
running firmware.

The ESRT is exposed at `/sys/firmware/efi/esrt/entries/` in Linux and while you
can view some information there it's mostly machine-oriented.

### Collecting pieces of capsules on boot

UEFI specification requires a capsule to be in a continuous virtual memory, but
not in physical memory.  This means that after a reboot capsules might need to
be stitched together from a bunch of small pieces.  The process is tedious,
error prone and potentially insecure.  In addition to that, a reconstructed
capsule better not be placed in an area which might be needed in later boot
phases or things will fall apart in ways which are hard to diagnose.

### Memory accesses beyond 32-bit address space

When a capsule survives a reset, it can end up almost anywhere in memory.
coreboot on x86 systems typically runs as a 32-bit program (64-bit mode exists
but is experimental) which means that memory accesses beyond first 4 GiB of RAM
require special handling.  This was made possible by updating [PAE]-enabled page
tables that describe a [virtual address space][virtas] below 4 GiB boundary to
point at a location above it, so that a 32-bit code could work with arbitrary
locations.

[pae]: https://en.wikipedia.org/wiki/Physical_Address_Extension
[virtas]: https://en.wikipedia.org/wiki/Virtual_address_space

### Accessing full flash from EDK2

When coreboot and EDK2 are used together, it's coreboot's job to deal with a
flash chip.  coreboot mediates flash accesses so that EDK2 could store its
settings between boots in a dedicated part of the chip.  When EDK2 performs an
update process, it needs to be able to access the whole chip.  This
extended access when an in-RAM capsule is present had to be implemented.

A related subject is flash protection.  Quite often at least part of the flash
is marked read-only by the firmware to make it more resilient against
attacks (or just buggy devices or software) that could try to modify it.
Dasharo is [no exception][security-settings] in this regard.  The way capsule
updates are dealing with it is by automatically activating [Firmware Update
Mode][fum] which lifts the protections for the duration of the next boot.

[security-settings]: https://docs.dasharo.com/dasharo-menu-docs/dasharo-system-features/#dasharo-security-options
[fum]: https://docs.dasharo.com/guides/firmware-update/#firmware-update-mode

### Early testing and debugging

When writing a parsing code, you want see how it behaves on artificial data of
different kinds to develop some confidence in its operation.  Testing firmware
is not an easy task in general and use of a [virtual machine][vm] (VM) can be of
great help.  This situation was no exception with the [QEMU] serving as a VM.

Dasharo already had an OVFM firmware image for some time before starting this
project.  However, that firmware did not have coreboot in it and was using a
separate EDK2 package called `OvmfPkg` which is not employed by Dasharo
releases targeting hardware platforms.  This has led to an effort of adding a
[Dasharo variant targeting Q35][q35].  It shares code with hardware variants
where possible, allowing it to be used for tests or just to check out Dasharo
firmware in a VM.

Availability of Dasharo for Q35 made it possible to abuse QEMU's "loader"
device to place predefined values in memory and observe how they are being
processed by the code.  It remained useful later when development focus has
shifted towards EDK2 and it became possible to test capsules in a VM.

[vm]: https://en.wikipedia.org/wiki/Virtual_machine
[qemu]: https://www.qemu.org/
[q35]: https://docs.dasharo.com/variants/qemu_q35/overview/

### Buggy capsule tooling

Working with capsules requires scripts that aid in assembling, disassembling and
analyzing of capsule files.  EDK2 provides such a tool as part of its
`BaseTools`.  However, the number of discovered bugs suggests that it's
underutilized.  Most of them are fixed by now thanks to this project.  Many
more details on the use of `GenerateCapsule.py` are provided in [the
documentation][tools-doc].

[tools-doc]: https://docs.dasharo.com/kb/edk2-capsule-updates/

### Hardware testing

Since MSI boards were the first to get the feature, that's where it was
validated on hardware.  Manual tests are done as described by the aforementioned
[update guide][update-guide], but that's not the real tests.  Real tests are
run automatically via [Robot Framework][robot] and follow a similar sequence but
also take into account various corner cases, verify whether data was actually
migrated or that the update screen looks as expected.  The [OSFV] tests of the
feature have their own [documentation][osfv-tests].

[robot]: https://robotframework.org/
[osfv]: https://github.com/Dasharo/open-source-firmware-validation
[osfv-tests]: https://docs.dasharo.com/unified-test-documentation/dasharo-stability/capsule-update/

### Intel ME vs. capsules

[Intel Management Engine][me] is stored on the same flash chip as the main
system firmware, leading to the both components being often updated
simultaneously.  Because ME operates independently and periodically writes to
flash, care needs to be taken to temporarily pause its operation to perform an
update.  The problem is that pausing ME takes a cold reboot which, unlike a
warm reboot, resets contents of RAM thus leaving no chance for in-RAM capsules.
Because firmware doesn't know when a user will initiate an update, it can't
disable ME beforehand.  This leads to a requirement for ME to be [HAP-disabled]
by the user and enabled back when the update is done.  This will, hopefully, be
improved in the future.

ME can also be [soft-disabled].  This way of disabling it is not suitable for
performing an update due to an extra ME state transition in coreboot which also
requires a cold reboot.

[me]: https://en.wikipedia.org/wiki/Intel_Management_Engine
[hap-disabled]: https://docs.dasharo.com/osf-trivia-list/me/#hap-altmedisable-bit-aka-disabling-me
[soft-disabled]: https://docs.dasharo.com/osf-trivia-list/me/#soft-disabling-me

### Data migration

A set of settings available in a given firmware is likely to remain the same or
grow in a more recent version.  It's nice to not have to recreate the
same configuration after every update.  The same goes about custom boot logo and
other user-configurable parts of a firmware.

In practice this means copying data from `SMMSTORE`, `COREBOOT` and
`BOOTSPLASH` regions into updated firmware so it's already suitably configured
on the first boot.

### Update screen

Default implementation in EDK2 is very peculiar:

* Location of the progress bar is tied to the dimensions of boot logo.
* When determining dimensions, some pixels of the logo are completely ignored.

Boot logo can be customized by a user, leading to unpredictable look of the
progress screen.  This is why a simple replacement driver was made to display
basic information and force predictable placement of the progress bar.

### Graphical progress bar

As was mentioned above, progress bar depends on certain characteristics of a
logo.  In addition to that it's very eager to abort.  If it can't fetch a logo
image, the whole firmware update progress is aborted despite such a non-critical
issue.

Some measures were taken to recover from a bad user-supplied logo (e.g., if it
uses [BMP] of unsupported version), although thanks to customized update screen
such errors shouldn't be a problem during an update.

[bmp]: https://en.wikipedia.org/wiki/BMP_file_format

## What's next

### Upstreaming

After the development is done changes made to open source projects are offered
for inclusion to their respective maintainers.  This is not exactly a future
step as various changes were sent upstream several months ago and even got
merged.  Upstreaming is rarely a fast process so it doesn't hurt to start it as
soon as you have a working implementation.  It also doesn't always go as
planned with some changes never making it upstream for various reasons, but you
still try.

#### coreboot

* [Announcement on the mailing list][cb-announce]
* [Capsule-specific code changes][capsules-topic] (in progress)
* [Q35 changes][q35-chain] (merged)
* [4 GiB cleanup][4gib-chain] (merged)

[cb-announce]: https://mail.coreboot.org/hyperkitty/list/coreboot@coreboot.org/thread/3V65LYNPNH5L4VAXBM5ZHAISOUHXXQ36/
[capsules-topic]: https://review.coreboot.org/q/topic:%22uefi-capsules%22
[q35-chain]: https://review.coreboot.org/c/coreboot/+/82639
[4gib-chain]: https://review.coreboot.org/c/coreboot/+/82247

#### EDK2

* [Announcement on the mailing list][edk-announce]
* [Main pull request][edk-pr] (submitted)
* [Pull request with tooling fixes][gen-cap-pr] (merged)

[edk-announce]: https://edk2.groups.io/g/devel/message/119901
[edk-pr]: https://github.com/tianocore/edk2/pull/6026
[gen-cap-pr]: https://github.com/tianocore/edk2/pull/5807

### Capsule updates for other Dasharo variants

[NovaCustom laptops] are the next to support UEFI capsule updates!  Stay tuned.

[NovaCustom laptops]: https://docs.dasharo.com/unified/novacustom/overview/#dasharo-coreboot--uefi

## Summary

[Project][nlnet-project]'s abstract states that it "aims to simplify the update
process and enhance the user experience, providing a more reliable approach
compared to complex flashrom-based updates".  While there are still things to
improve, adding update capsules to modern MSI boards with coreboot firmware
seems to have made strands in reaching the stated goal even though you might
have to wait until the next firmware update to see it in action.

***

If you are looking to extend firmware with the features you need, similar to
how it was done in this case, [schedule a call][calendar] or drop an email at
`contact<at>3mdeb<dot>com` to discuss how [3mdeb] can assist with that.

[calendar]: https://calendly.com/3mdeb/consulting-remote-meeting
[3mdeb]: https://3mdeb.com/

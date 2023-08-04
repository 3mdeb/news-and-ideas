---
title: Current status of coreboot and Heads ports for Talos II
abstract: 'This post summarizes our current progress on making first coreboot
          port for POWER platform, including Heads as a payload. It will also
          show how You can test it without having to flash firmware to PNOR.'
cover: /covers/coreboot-logo.svg
author: krystian.hebel
layout: post
published: true
date: 2022-02-16
archives: "2022"

tags:
  - coreboot
  - openpower
  - heads
categories:
  - Firmware

---

This post summarizes our current progress on making first coreboot port for
POWER platform\*, including [Heads](https://github.com/osresearch/heads) as a
payload. It will also show how You can test it without having to actually flash
firmware to PNOR permanently.

Description of OpenPOWER boot process and coreboot's place in it can be found in
previous post under [OpenPOWER tag](https://blog.3mdeb.com/tags/openpower/).

> \*) there is already a target for `qemu-power8` that compiles successfully,
> but it executes just a single instruction: `b .`, that is, CPU is kept in an
> infinite loop.

## State of coreboot code

List of initialization steps which are already implemented and seem to work as
expected:

- Nest initialization - SoC internal stuff like enabling power and clocks to
  chiplets
- PCIe initialization - lane configuration and reset de-assert only, training is
  actually done by Skiboot
- Memory controllers setup
- DRAM training - DDR4 RDIMM
- DRAM initial write - ECC requires this to keep ECC syndromes in sync with data
- OCC complex initialization - core power management
- TOD - time of day, timer that keeps timers of individual cores in sync with
  each other

Other implemented components that are not initialization per se, but are used by
it:

- a lot of code and documentation was modified to work also for big endian
  platforms (mostly around CBFS and FMAP), more fixes are yet to be done (CBMEM)
- XSCOM - virtually all of the configuration is done through SCOM registers,
  XSCOM is one of ways of doing it
- LPC - serial output, reading from flash
- I2C drivers - used to access RDIMMs RCD (registering clock driver) and EEPROM
  (SPD, VPD)
- multiple timekeeping functions, mostly for delays and timeouts
- FDT creation - prepares data consumed by Skiboot
- IPMI BT driver - used to kick BMC watchdog

There are some
[known issues and TODOs](https://github.com/Dasharo/dasharo-issues/labels/raptor-cs_talos-2)
that may require additional work, but Talos II based on coreboot is already able
to boot all the way to target OS. It even does it
[faster than Hostboot](https://youtu.be/toLV9d7H6Q0?t=388), although such
preliminary comparison has to be taken with a grain of salt -- there are still
places for optimization ;)

[![asciicast](https://asciinema.org/a/zkQV1KhxY4n6IrlzssuvFHHS5.svg)](https://asciinema.org/a/zkQV1KhxY4n6IrlzssuvFHHS5?t=20)

![Debian on Talos II](/img/debian_on_talos.png)

The biggest piece of code that is yet to be implemented is support for second
CPU. Other than that, serial output needs some cleanup - all new code set high
verbosity to print important lines while keeping standard coreboot internals
quiet.

Most recent, not thoroughly tested version of the code can be obtained from
[develop branch on Dasharo's fork of coreboot](https://github.com/Dasharo/coreboot/tree/raptor-cs_talos-2/develop),
but unless you want to test it, we suggest to stick to the
[release branch](https://github.com/Dasharo/coreboot/tree/raptor-cs_talos-2/release),
or, if you don't want to have to build it yourself, you can just use binaries
[compiled by us](#links).

We also are currently in process of
[upstreaming QEMU target](https://review.coreboot.org/q/topic:%22QEMU+POWER9+target%22),
but it takes time. If you are able to review that please do, we are impatiently
waiting with pushing Talos II code until all issues with POWER9 skeleton are
resolved and patches merged.

## State of Heads code

Changes to Heads also introduced another processor architecture. As it was first
non-x86 platform, it required modifications to the build system in which x86 had
been previously pretty much hardcoded. Another difference is that kernel image
file for PPC64 is called `zImage` instead of `bzImage`. These two changes alone
gave
[429 added and 196 removed lines](https://github.com/osresearch/heads/pull/1009).

OpenPOWER's PNOR layout and support in Skiboot requires that initramfs is
bundled into kernel image itself and coreboot is build with separate file for
bootblock due to HBB partition size. Separate PR was created for these two
features because they can be used by other boards, it is
[already merged](https://github.com/osresearch/heads/pull/1011).

The biggest PR is
[all-in-one that adds mainboard](https://github.com/osresearch/heads/pull/1002).
It has some of the changes introduced in PRs mentioned above for the sake of CI.
Even though there are more than 3k lines added, almost a third of that are
patches to Linux kernel
[created specifically for Talos II by Raptor CS](https://git.raptorcs.com/git/talos-op-build/tree/openpower/linux).

All of listed PRs are either approved or already merged, so it is just a
question of testing and time before they land in Heads' repository.

![Heads on Talos II](/img/heads_on_talos.png)

As with coreboot, instead of building Heads from scratch you can also use
[already compiled image](#links).

## Call for testing

Due to our limited experience with PPC64 architecture, as well as limited number
of hardware configurations we can test, we ask you to test the code in everyday
tasks. In case of any problems
[file an issue](https://github.com/Dasharo/dasharo-issues/issues) and we promise
to do our best to fix it.

### Links

All required binaries, along with their hashes and signatures, can be found on
[Talos II releases page on Dasharo website](https://docs.dasharo.com/variants/talos_2/releases/).
There you can also subscribe to the
[release newsletter](https://newsletter.3mdeb.com/subscription/w2Y2G4Rrj) or
read
[how to build images yourself](https://docs.dasharo.com/variants/talos_2/building-manual/).

### Modified PNOR partitions

Because coreboot replaces Hostboot and is much smaller than it, we can reuse
Hostboot's partitions. Skiboot's partition is left untouched, however for the
sake of easier deployment and integration with coreboot we decided to put
another copy of Skiboot into CBFS and load it this way. We still rely on HBBL
(running from SEEPROM) to load and start `HBB`, but getting rid of this
dependency is on our TODO list.

Heads can take place of Skiroot/Petitboot partition. This change is independent
of coreboot ones, you can easily choose to substitute Skiroot with Heads,
Hostboot with coreboot, or both. All mentioned combinations are supposed to
work, if they don't feel free to issue a bug report.

Summing up, these are the only changes to PNOR contents:

- coreboot's bootblock after adding ECC is written to `HBB`,
- coreboot's CBFS after adding ECC is written to `HBI`,
- Heads is written to `BOOTKERNEL`.

### Testing without actual flashing

It is possible to test new firmware images without flashing the physical flash
device. This makes testing and switching between two versions (e.g. Hostboot and
coreboot) much faster and safer. Note that this requires v2.00 or later of BMC
firmware.

Steps listed below assume that files containing new firmware components are
already located in `/tmp/` on BMC. Platform name and version numbers were
stripped from filenames for convenience.

> Keep in mind that `tmpfs` size is limited and exceeding that limit may result
> in unresponsive BMC, which in most severe cases requires hard power cycle.
> Unfortunately, `/home/` doesn't have nearly enough space to hold all of
> required files.

**All of the following has to be run on BMC, not host system**.

1. Read original flash into a file that will be modified in next steps:

   ```bash
   root@talos:~# pflash -r /tmp/talos.pnor
   ```

1. Next step is "flashing" modified partition, which is similar to flashing real
   device with two changes: no need to erase the flash and target file must be
   specified. New command looks like this:

   ```bash
   root@talos:~# pflash -P <partition_name> -p <file_to_write> -F /tmp/talos.pnor
   ```

   This has to be confirmed by writing `yes`. Example commands and output for
   flashing coreboot:

   ```bash
   root@talos:~# pflash -P HBB -p /tmp/bootblock.signed.ecc -F /tmp/flash.pnor
   About to program "/tmp/bootblock.signed.ecc" at 0x00205000..0x0020c002 !
   WARNING ! This will modify your HOST flash chip content !
   Enter "yes" to confirm:yes
   Programming & Verifying...
   [==================================================] 100%
   Updating actual size in partition header...
   root@talos:~# pflash -P HBI -p /tmp/coreboot.rom.signed.ecc -F /tmp/flash.pnor
   About to program "/tmp/coreboot.rom.signed.ecc" at 0x00425000..0x00666200 !
   WARNING ! This will modify your HOST flash chip content !
   Enter "yes" to confirm:yes
   Programming & Verifying...
   [==================================================] 100%
   Updating actual size in partition header...
   ```

   To write Heads:

   ```bash
   root@talos:~# pflash -P BOOTKERNEL -p /tmp/zImage.bundled -F /tmp/flash.pnor
   About to program "/tmp/zImage.bundled" at 0x022a1000..0x02e06158 !
   WARNING ! This will modify your HOST flash chip content !
   Enter "yes" to confirm:yes
   Programming & Verifying...
   [==================================================] 100%
   Updating actual size in partition header...
   ```

1. To mount the file as flash device (on powered down platform):

   ```bash
   root@talos:~# mboxctl --backend file:/tmp/flash.pnor
   ```

   > Partitions can be "flashed" while the file is mounted, as long as host
   > platform doesn't try to access it simultaneously.

   Occasionally this command may fail
   (`Failed to post message: Connection  timed out` or
   `Failed to post message: No route to host`), in that case repeat it until it
   succeeds (`SetBackend: Success`). Optionally, success can be tested with:

   ```bash
   root@talos:~# mboxctl --lpc-state
   LPC Bus Maps: BMC Memory
   ```

   `BMC Memory` means emulated flash is used instead of real one. Host doesn't
   see any difference (except different access times and reported erase
   granularity), it still reads and writes PNOR the same way as with physical
   device.

1. Start host now, it should boot to newly "flashed" firmware instead of the old
   one.

   > When BMC boots for the next time firmware from physical flash device is
   > used. This makes this approach safe against power failures or corrupted
   > images being flashed.

1. To get back to real PNOR one can use:

   ```bash
   root@talos:~# mboxctl --backend vpnor
   Failed to post message: Connection timed out
   root@talos:~# mboxctl --lpc-state
   LPC Bus Maps: Flash Device
   ```

   Even though this command reports failure, it maps LPC back to flash device.
   This can be tested with `mboxctl --lpc-state`.

## Summary

This blog post is just a summary of what is the current state and a quick how-to
for testing. Once again, we are really looking for your feedback, either good or
bad. Is there something that worked with Hostboot but doesn't work with
coreboot? Is there something firmware-related that you wished worked with
Hostboot but didn't? Let us know, either below in the comment or by creating an
issue on [Dasharo Issues](https://github.com/Dasharo/dasharo-issues).

> If you are interested, in this video Piotr mentions some of challenges we had
> to overcome: {{\< youtube toLV9d7H6Q0 >}}

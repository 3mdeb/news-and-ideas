---
title: Current status of coreboot and Heads ports for Talos II
abstract: 'This post summarizes our current progress on making first coreboot
          port for POWER platform, including Heads as a payload. It will also
          show how You can test it without having to flash firmware to PNOR.'
cover: /covers/coreboot-logo.svg
author: krystian.hebel
layout: post
published: true
date: 2021-12-10
archives: "2021"

tags:
  - coreboot
  - firmware
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
but it executes just a single instruction: `b .`, that is, CPU is kept in an
infinite loop.

## State of coreboot code

List of initialization steps which are already implemented and seem to work as
expected:

* Nest initialization - SoC internal stuff like enabling power and clocks to
  chiplets
* PCIe initialization - lane configuration and reset de-assert only, training is
  actually done by Skiboot
* Memory controllers setup
* DRAM training - DDR4 RDIMM
* DRAM initial write - ECC requires this to keep ECC syndromes in sync with data
* OCC complex initialization - core power management
* TOD - time of day, timer that keeps timers of individual cores in sync with
  each other

Other implemented components that are not initialization per se, but are used by
it:

* XSCOM - virtually all of the configuration is done through SCOM registers,
  XSCOM is one of ways of doing it
* LPC - serial output, reading from flash
* I2C drivers - used to access RDIMMs RCD (registering clock driver) and EEPROM
  (SPD, VPD)
* multiple timekeeping functions, mostly for delays and timeouts
* FDT creation - prepares data consumed by Skiboot
* IPMI BT driver - used to kick BMC watchdog

There are some [known issues and TODOs](https://github.com/Dasharo/dasharo-issues/issues?q=is%3Aopen+is%3Aissue+label%3A%22trustworthy+computing%22)
that may require additional work, but Talos II based on coreboot is already able
to boot all the way to target OS. It even does it [faster than Hostboot !!!TBD update numbers!!!](https://github.com/3mdeb/openpower-coreboot-docs/blob/main/devnotes/user_perspective.md),
although such preliminary comparison has to be taken with a grain of salt --
there are still places for optimization ;)

![Debian on Talos II](/img/debian_on_talos.png)

The biggest piece of code that is yet to be implemented is support for second
CPU. Other than that, serial output needs some cleanup - all new code set high
verbosity to print important lines while keeping standard coreboot internals
quiet.

Most recent, not thoroughly tested version of the code can be obtained from
[develop branch on Dasharo's fork of coreboot](https://github.com/Dasharo/coreboot/tree/raptor-cs_talos-2/develop),
but unless you want to test it, we suggest to stick to the [release branch](https://github.com/Dasharo/coreboot/tree/raptor-cs_talos-2/release),
or, if you don't want to have to build it yourself, you can just use binaries
compiled by us [!!!TBD link!!!](#).

We also are currently in process of [upstreaming QEMU target](https://review.coreboot.org/q/topic:%22QEMU+POWER9+target%22),
but it takes time. If you are able to review that please do, we are impatiently
waiting with pushing Talos II code until all issues with POWER9 skeleton are
resolved and patches merged.

## State of Heads code

!!!TBD!!!


## Changes in PNOR

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

* coreboot's bootblock after adding ECC is written to `HBB`,
* coreboot's CBFS after adding ECC is written to `HBI`,
* Heads is written to `BOOTKERNEL`.

## Call for testing

Due to our limited experience with PPC64 architecture, as well as limited number
of hardware configurations we can test, we ask you to test the code in everyday
tasks. In case of any problems [file an issue](https://github.com/Dasharo/dasharo-issues/issues)
and we promise to do our best to fix it.

#### Testing without actual flashing

It is possible to test new firmware images without flashing the physical flash
device. This makes testing and switching between two versions (e.g. Hostboot and
coreboot) much faster and safer. Note that this requires v2.00 or later of BMC
firmware.

Steps listed below assume that files containing new firmware components are
already located in `/tmp/` on BMC.

> Keep in mind that `tmpfs` size is limited and exceeding that limit may result
in unresponsive BMC, which in most severe cases requires hard power cycle.
Unfortunately, `/home/` doesn't have nearly enough space to hold all of required
files.

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
    platform doesn't try to access it simultaneously.

    Occasionally this command may fail (`Failed to post message: Connection
    timed out` or `Failed to post message: No route to host`), in that case
    repeat it until it succeeds (`SetBackend: Success`). Optionally, success can
    be tested with:

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
    used. This makes this approach safe against power failures or corrupted
    images being flashed.

1. To get back to real PNOR one can use:

    ```bash
    root@talos:~# mboxctl --backend vpnor
    Failed to post message: Connection timed out
    root@talos:~# mboxctl --lpc-state
    LPC Bus Maps: Flash Device
    ```

    Even though this command reports failure, it maps LPC back to flash device.
    This can be tested with mboxctl --lpc-state.


<!--

> copy all post images to `blog/static/img` directory. Example usage:

![alt-text](/img/file-name.jpg)

> example usage of asciinema videos:

[![asciicast](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO.svg)](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO?speed=1)

-->

## Summary

!!!TBD Summary of the post!!!

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

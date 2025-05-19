---
title: Talos II - second CPU support and test automation
abstract: 'Another post about our adventures with porting coreboot for Talos II.
          This phase focused on enabling second CPU and its internal devices.
          We also expanded our test suite.'
cover: /covers/coreboot-logo.svg
author: krystian.hebel
layout: post
published: true
date: 2022-04-15
archives: "2022"

tags:
  - coreboot
  - openpower
categories:
  - Firmware

---

Another post about our adventures with porting coreboot for Talos II. This phase
focused on enabling second CPU and its internal devices. We also expanded our
test suite.

## Links to binaries and installation instructions

Binaries and their signatures can be found on
[Talos II release page](https://docs.dasharo.com/variants/talos_2/releases/). In
[installation instructions](https://docs.dasharo.com/variants/talos_2/initial-deployment/)
you can find steps needed both for permanent flashing as well as for temporary
use of different firmware image.

## Second CPU initialization

First of the problems we had to overcome was accessing SCOM (Serial
COMmunication) registers on the second CPU. For first CPU we were using XSCOM
(eXtended SCOM) which was conveniently set up for us by SBE (Self Boot Engine,
small PowerPC-lite core inside POWER9 SoC), now we have to do something similar
for the other processor. Before that happens, all SCOM accesses are done through
FSI (Flexible Service Interface).

This added another layer in accessing buses that are already accessed through
SCOM. An example of such bus is I2C, which is used (among other uses) for
accessing MVPD (Module VPD). MVPD holds important data about CPU, like its
operating frequencies and voltages or list of enabled cores. It must be read
before XSCOM is enabled, meaning it has to happen using slow FSI communication.
How slow are we talking about? Reading 64 KB of MVPD takes 4 seconds when done
through XSCOM (primary CPU), but 9 seconds over FSI (secondary CPU). It is used
both in romstage and ramstage, so we quickly decided it is worth to cache MVPD
between stages. Next step will be saving it to flash and read it through I2C
only if necessary, i.e. after flashing whole PNOR or when processor was swapped
and saved image doesn't match hardware. Hostboot does it this way, so should we.
This could save about 13 seconds of boot time.

Next item on the list was enabling and training X bus links. An X bus is the
socket-to-socket SMP interconnect between two POWER9 processors. Before this
step each CPU worked independently of the other one, in so-called island mode.
In that mode it would be impossible to directly access address spaces (memory
and MMIO) behind remote CPU. Enabling SMP makes XSCOM access to secondary
processor's devices possible.

With SCOM, I2C and X Bus out of the way, most of initialization consisted of
repeating existing steps for the second CPU. There were some exceptions where
simple repetition was not enough, most notably:

- TOD (time of day) - in case of discrepancy between two clocks one of them
  takes precedence in setting the other. Complex calculations are done during
  the initialization to choose "more important" clock source - the one with
  higher delay, as it is more inert.
- memory controller - even though memory initialization and training is repeated
  for secondary processor, only main CPU sets a common memory space address
  translation maps.
- PCIe controller - links are split differently between ports connected to each
  of processor sockets.

In addition to various initialization steps, we had to update device tree passed
to Skiboot to include information about new CPU and devices it adds. We also
switched away from FIT payload and started using ELF. Main motivation for this
change was fact that
[FIT decompression code does not work as expected](https://mail.coreboot.org/hyperkitty/list/coreboot@coreboot.org/thread/6EZWU7YPUJE564GNCV7U32IXWPFTV7FB/)
in coreboot. With payload compressed with LZMA, flash memory footprint of whole
coreboot and Skiboot has shrunk to just below 700 KB. For comparison, Hostboot
takes about 30 MB of space.

## New tests

In order to achieve greater reliability of the firmware and to avoid bugs test
base on the Talos II platform has been improved.

Currently, before each firmware release, the following test suites will be
performed:

- [Dasharo compatibility: coreboot base port][cbp], which contains test cases
  for checking correctness of coreboot porting on the device.
- [Dasharo compatibility: Petitboot payload support][pbt], which contains test
  cases for checking Petitboot availabity and functionality.
- [Dasharo compatibility: Heads bootloader support][hds], which contains test
  cases for checking Heads bootloader availabity.
- [Dasharo compatibility: USB detection][usb], which contains test cases for
  checking correctness of USB detection after coldboot, warmboot and system
  reboot.
- [Dasharo compatibility: USB booting][ubb], which contains tests cases for
  checking correctness of booting from USB after coldboot, warmboot and system
  reboot.
- [Dasharo compatibility: Debian Stable and Ubuntu LTS support][lbt], which
  contains test cases for checking correctness of installing and booting into
  installed OS.
- [Dasharo compatibility: Device Tree][dvt], which contains test cases for
  checking correctness of coreboot presentation in Device Tree.
- [Dasharo compatibility: CPU status][cpu], which contains test cases for
  checking correctness of CPU work.

All test cases documentation is available under this [link][tests]. Full test
matrix for Talos II is available under this [link][matrix]

## Summary

We will soon start long and tedious process of upstreaming those changes, after
some additional cleanup. This may put most of further development on hold to
keep rebasing effort as low as possible. Nevertheless, we will in parallel start
researching what it would take to add TPM support.

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to
[sign up to our newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

[cbp]: https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/100-coreboot-base-port/
[cpu]: https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31T-cpu-status/
[dvt]: https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31W-device-tree/
[hds]: https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31U-heads-bootloader-support/
[lbt]: https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/308-debian-stable-and-ubuntu-lts-support/
[matrix]: https://docs.dasharo.com/variants/talos_2/test-matrix/
[pbt]: https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31V-petitboot-payload-support/
[tests]: https://docs.dasharo.com/unified-test-documentation/overview/
[ubb]: https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31N-usb-boot/
[usb]: https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31O-usb-detect/

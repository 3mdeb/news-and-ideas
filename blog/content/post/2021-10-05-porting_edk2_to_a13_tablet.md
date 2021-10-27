---
title: Porting EDK II to an old Allwinner A13 tablet
abstract: 'An effort to port EDK II to Allwinner SoCs'
cover: /covers/image-file.png
author: artur.kowalski
layout: post
published: true
date: 2021-10-05
archives: "2021"

tags:
  - firmware
categories:
  - Firmware
  - Manufacturing

---

# Introduction

I have an old cheap Allwinner A13 tablet with low memory and a weak CPU; it's
slow even for internet browsing, so I've been using it primarily for
development. Some time ago, I started porting EDK II to it. I plan to replace
the current Allwinner bootloader with a full-featured UEFI implementation
capable of booting mainline Linux, FreeBSD, and possibly Windows 10, all running
with ACPI. Using ACPI would allow OS to boot without SoC specific drivers, as
all basic functionality like CPU/RAM detection, frequency, and voltage scaling,
serial port, RTC, etc., would be implemented by ACPI and runtime drivers.

## Project status

The project is still at its early stage - it does not support CPU frequency
scaling, so it's running very slow. Currently, there is basic support for some
hardware: UART, I2C, PMIC, SD (eMMC support is broken).

It is possible to boot recent Linux with FDT (tested with v5.11).

Following things need to be implemented

- CPU frequency scaling
- LCD
- HDMI
- DMA
- UEFI variables - currently, variables are not preserved across reboots
- ACPI
- Support for other CPUs and boards.

Currently, I am working on USB peripheral mode support. It will allow making
boot process compliant with Pi specification. Currently, a small executable
(called SPL after U-Boot's SPL) is loaded into the device's memory, it
initializes DRAM and returns into BootROM, which proceeds into loading UEFI
image. Implementing USB driver makes it possible to load EFI directly from Pi
without going back into BootROM, thus allowing to move initialization code
there. Implementing it also enables UEFI to be debugged using USB instead of
UART.

## Supported hardware

Currently, only my XW711 tablet is supported, but this hardware is so similar
to Q8 that it should work on any Q8 tablet, these look like the same board, with
only some peripherals like touch panel and LCD differing.

Information about Q8 is available at [sunxi wiki](https://linux-sunxi.org/Q8),
there are no significant information available for XW711, except in its FEX file
available in [sunxi-boards](https://github.com/linux-sunxi/sunxi-boards/blob/master/sys_config/a13/szenio_1207c4.fex)
repo.

XW711 has

- 512 MiB RAM, running at 408 MHz, UEFI currently configures it to run at Q8
  default frequency (384 MHz)
- 4GB eMMC instead of raw NAND
- Goodix GT81x touchscreen
- 800x480 LCD
- RTL8188EU Wi-Fi

Since there is no display support and USB is still on its way, UART connection
is required, on this board (and on Q8), UART pads are located on the back of the
board, there is also a second UART multiplexed with µSD, which can be used
without disassembling device, support for this is coming soon.

## Building and booting UEFI

Source code is available
[here](https://github.com/arturkow2000/SunxiPlatformPkg), you can build it using
`arm-none-eabi-gcc`. 

```
git clone --depth=1 https://github.com/tianocore/edk2 --branch edk2-stable202102
cd edk2
git submodule update --init --recursive
git submodule add https://github.com/arturkow2000/SunxiPlatformPkg
make -C BaseTools/Source/C
. edksetup.sh
env GCC5_ARM_PREFIX=arm-none-eabi- build -a ARM -p SunxiPlatformPkg/XW711.dsc -t GCC5
```

This builds two files: `SUNXI_SPL.fd` and `SUNXI_EFI.fd`. For `sunxi-fel` to
accept SPL, you have to patch its header. Tool for this purpose is written in
Rust, so if you don't have Rust installed already, you can get it from
https://rustup.rs.

```
cd Build/XW711/DEBUG_GCC5/FV/
cargo install --git https://github.com/arturkow2000/sunxiboot
sunxiboot checksum SUNXI_SPL.fd
sunxi-fel --verbose spl SUNXI_SPL.fd write 0x42000000 SUNXI_EFI.fd exe 0x42000000
```

[![asciicast](https://asciinema.org/a/pCr0fQKHnBFRhHyWjC9ml3Gcz.svg)](https://asciinema.org/a/pCr0fQKHnBFRhHyWjC9ml3Gcz?speed=1)

## UEFI in action

This video shows booting EDK II and Fedora ARM with FDT, few workarounds are
required:

- DTB must be manually loaded from file on each boot, using `setfdt` EFI shell
  command

- I had to boot Linux with `cpufreq.off=1`, or it would hang while trying to
  raise CPU frequency (since there is no frequency scaling CPU is left at 384
  MHz, this looks like Linux bug)

- I had to disable `axp20x_adc` driver because it was causing board to power off
  instantly, this isn't related to EFI itself, yet still, it's causing problems.
  It can be caused by a bug in DTB or driver itself, or XW711 and Q8 aren't so
  similar, and I'm just using wrong DTB.
```shell
echo 'blacklist axp20x_adc' >> /etc/modprobe.d/blacklist.conf
```

{{< youtube PjRC6vXxlpY >}}

## Summary

Most of the basic stuff is already there. There is still a lot of work to do to
complete work, but it is even now almost functional. To bring this into usable
state, I need support for booting EFI from SD/eMMC; this will allow booting into
OS without using FEL every time I power on device. Until EFI gains ACPI support
it will be possible only to boot OS's that support FDT. Later on, it will be
possible to work either in ACPI or FDT mode.

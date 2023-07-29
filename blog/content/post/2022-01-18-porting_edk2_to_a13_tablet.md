---
title: Porting EDK II to an old Allwinner A13 tablet
abstract: "Most ARM SoC's run U-Boot or some custom bootloader. That was the
           case with Allwinner SoC's, until I started porting EDK II to my A13
           tablet. In this post, I will tell you about the current UEFI support
           status on Allwinner SoC's, my future plans, and how to test UEFI on
           a compatible device"
cover: /img/xw711_uefi_screen.jpg
author: artur.kowalski
layout: post
published: true
date: 2022-01-18
archives: "2022"

tags:
  - edk2
  - allwinner
categories:
  - Firmware
  - Manufacturing

---

## Introduction

I have an old cheap Allwinner A13 tablet with low memory and a weak CPU; it's
slow even for internet browsing, so I've been using it primarily for
development. Some time ago, I started porting EDK II to it. I plan to replace
the current Allwinner bootloader with a full-featured UEFI implementation
capable of booting mainline Linux, FreeBSD, and possibly Windows 10 (if I will
find ARM32 build), all running with ACPI. Using ACPI would allow OS to boot
without SoC specific drivers, as all basic functionality like CPU/RAM detection,
frequency, and voltage scaling, serial port, RTC, etc., would be implemented by
ACPI and runtime drivers.

## Project status

The project is still at its early stage - currently, there is basic support for
some hardware:

- UART
- I2C
- PMIC - voltage scaling (AXP209 only)
- Storage - SD card is supported (read-only, low-speed modes), eMMC support is
  broken and not usable
- RTC - can read and set current date and time

Currently, only my XW711 tablet is supported, but UEFI should work on any Q8
tablet as these tablets have a very similar board. Some peripherals differ, like
touch panel, Wi-Fi card, or internal memory (NAND instead of eMMC). So far, this
is not a problem since eMMC is disabled by default.

You can read about Q8 from its article at
[sunxi wiki](https://linux-sunxi.org/Q8), for XW711 there is no significant
information available, except in its FEX file available in
[sunxi-boards](https://github.com/linux-sunxi/sunxi-boards/blob/master/sys_config/a13/szenio_1207c4.fex)
repo and here:

- 512 MiB RAM, running at 408 MHz, UEFI currently configures it to run at Q8
  default frequency (384 MHz)
- 4GB eMMC instead of raw NAND
- Goodix GT81x touchscreen
- 800x480 LCD
- RTL8188EU Wi-Fi

UEFI can boot Linux if you provide a valid FDT. Currently, you can do this only
manually, so you need a working UART connection. On XW711 (and on Q8), UART pads
are located on the back of the board. There is also a second UART multiplexed
with µSD, which can be used without disassembling the device. U-Boot already
supports UART-over-µSD (`CONFIG_UART0_PORT_F`), soon I will implement this
feature in UEFI.

## Coming soon

Currently, I am working on USB peripheral mode support, which will allow me to
move the DRAM initialization code into PEI. Currently, DRAM initialization is
handled by a separate program called SPL (after U-Boot's SPL). SPL initializes
DRAM and returns to BootROM, which proceeds with loading UEFI image over USB
(Allwinner BootROM has support for writing arbitrary memory, so I just write raw
UEFI image and jump to its entry point). A USB driver will remove dependency on
BootROM and the need for SPL. Moving DRAM initialization code into PEI makes it
possible to fetch DRAM configuration from dynamic PCDs, which will be useful for
overclocking. Yet another significant advantage is that I can use the PEI MMC
driver to load the rest of UEFI, so when I get rid of SPL, I will add support
for UEFI booting from SD and eMMC. Last but not least, I want my implementation
to be PI spec compliant. To do that, I need to drop SPL and transfer some of its
responsibilities (like DRAM initialization) to PEI. There is only one problem
with this approach, BootROM has a 31 KiB limit on A13 and even less on A10 and
A20 (despite SRAM being much bigger than that). Even now, PEI size exceeds that
limit. There is a chance that I could compact it enough to make it fit, but I
can't be sure, and if it turns impossible, then I will have to keep a small MMC
driver in SEC just to load PEI. Also, PI spec is unclear about the SEC phase,
e.g., specification says that the SEC phase is the first phase to execute, but
then what about BootROM, which is always the first program to run and most ARM
SoCs have one.

Other things I will add shortly are, among others: CPU frequency scaling,
SD/eMMC write support, display support, etc.

I have recently added basic LCD support (available on the `display_support`
branch), so you should be able to see UEFI booting without using UART. Please
note that you won't be able to boot into OS, as you need to load FDT manually. I
will fix this problem shortly.

![UEFI boot menu](/img/xw711_uefi_screen.jpg)

![UEFI grub](/img/xw711_uefi_grub.jpg)

My long term goals include:

- DMA support in most performance-critical drivers (like MMC)
- Full ACPI support
- Support for other SoCs (like A10, A20, etc.) and other boards
- NAND support
- HDMI support (and other if supported by SoC)
- Support CPU and RAM overclocking
- Support for ATF and TEE (if possible) - apart from the standard benefits TEE
  provides, maybe I could restrict access to critical hardware (like PMIC).
  Instead of controlling hardware directly from a UEFI runtime driver, the
  hardware would be controlled by a secure driver instead. This approach would
  allow, e.g., protecting hardware from overvoltage.
- Persistent UEFI variable storage - required for things like changing the boot
  order, etc.

## Building and booting UEFI

You can get BSP source code from
[my GitHub repo](https://github.com/arturkow2000/SunxiPlatformPkg). It has been
tested with EDK II v2021.02, which you can obtain from
[TianoCore GitHub repo](https://github.com/tianocore/edk2/).

```bash
git clone --depth=1 https://github.com/tianocore/edk2 --branch edk2-stable202102
cd edk2
git submodule update --init --recursive
git submodule add https://github.com/arturkow2000/SunxiPlatformPkg
```

If you want LCD support, you need to switch branch:

```bash
git checkout display_support
```

You can build it directly on your host system. Note that this was tested on
Ubuntu 20.04 with GCC 9.2.1 and may not work on other distros with either too
old or too new compiler.

```bash
make -C BaseTools/Source/C
. edksetup.sh
env GCC5_ARM_PREFIX=arm-none-eabi- build -a ARM -p SunxiPlatformPkg/XW711.dsc -t GCC5
```

Alternatively, you can use 3mdeb's Docker container, which provides a stable
build environment independent of your distro.

```bash
$ docker run --rm -it -w /home/edk2/edk2 -v $PWD:/home/edk2/edk2 3mdeb/edk2 /bin/bash
(docker)$ make -C BaseTools
(docker)$ . edksetup.sh
(docker)$ env GCC5_ARM_PREFIX=arm-linux-gnueabihf- build -a ARM -p SunxiPlatformPkg/XW711.dsc -t GCC5
```

This builds two files: `SUNXI_SPL.fd` and `SUNXI_EFI.fd`. For `sunxi-fel` to
accept SPL, you have to patch its header. A tool for this purpose is written in
Rust, so if you don't have Rust installed already, you can get it from
<https://rustup.rs>.

```bash
cd Build/XW711/DEBUG_GCC5/FV/
cargo install --git https://github.com/arturkow2000/sunxiboot
sunxiboot checksum SUNXI_SPL.fd
sunxi-fel --verbose spl SUNXI_SPL.fd write 0x42000000 SUNXI_EFI.fd exe 0x42000000
```

[![asciicast](https://asciinema.org/a/pCr0fQKHnBFRhHyWjC9ml3Gcz.svg)](https://asciinema.org/a/pCr0fQKHnBFRhHyWjC9ml3Gcz?speed=1)

## UEFI in action

This video shows booting EDK II and Fedora ARM with FDT. Few workarounds are
required:

- FDT must be manually loaded from a file on each boot, using the `setfdt` UEFI
  shell command

- I had to boot Linux with `cpufreq.off=1`, or it would hang while trying to
  raise CPU frequency (since there is no frequency scaling, CPU is left at 384
  MHz), this looks like Linux's bug.

- I had to disable the `axp20x_adc` driver because it was causing the board to
  power off instantly, this isn't related to UEFI itself, yet still, it's
  causing problems. It can be caused by a bug in FDT or the driver itself, or
  XW711 and Q8 aren't so similar, and I'm just using the wrong FDT

```bashshell
echo 'blacklist axp20x_adc' >> /etc/modprobe.d/blacklist.conf
```

{{\< youtube PjRC6vXxlpY >}}

## Summary

Most of the basic stuff is already working, and when I get boot from SD and eMMC
working, UEFI will become a usable alternative to U-Boot. Still, there is much
work to do, especially ACPI support, and runtime drivers may take a long time.
For now, it will be possible to boot OS using FDT. Then I will gradually
implement missing stuff till I get a full-featured UEFI implementation.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to book a call with us or drop us email to
`contact<at>3mdeb<dot>com`. If you are interested in similar content feel free
to sign up to our
[newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).

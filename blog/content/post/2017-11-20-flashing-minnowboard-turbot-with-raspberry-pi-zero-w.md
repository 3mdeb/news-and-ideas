---
ID: 63673
title: Flashing MinnowBoard Turbot with Raspberry Pi Zero W
author: piotr.krol
post_excerpt: ""
layout: post
published: true
date: 2017-11-20 00:21:00
archives: "2017"
tags:
  - coreboot
  - UEFI
  - raspberrypi
  - Intel
  - BayTrail
categories:
  - Firmware
---
Recently we started preparation of coreboot training for one of our customers.
Our platform of choice for that training is MinnowBoard Turbot. There are couple
reasons for that:

*   During training we can show recent firmware trends - despite we don't like
blobs (FSP, AGESA, PSP, ME etc.) and bloated designs (UEFI) we cannot escape
reality and have to show customers how to deal with those components.
MinnowBoard Turbot use couple of them, but also supports coreboot.
*   We can present recent Intel SoC features - MinnowBoard Turbot Dual-Core has
Intel Atom E3826 which has support for VT-x, TXE, PCU (Platform Control Unit),
JTAG and other features that can be very interesting from firmware engineer
point of view.
*   We can use the platform which is used as a reference design for various
products - it looks like market for BayTrail (and newer Intel platforms) is
quite big and there are many companies that develop solutions based on it.

MinnowBoard was also used in UEFI security related trainings in which we are
really interested in. Key problem with presentation and workshop preparation was
need for SF100 as SPI programmer. This tool is high quality, but is quite
expensive. When we add it to cost of MinnowBoard, equipment and shipping we end
up with cost of one development environment ~530USD (MinnowBoard Turbot: 200USD,
SF100: 230USD, peripherals+power supply: 50USD, shipping: 50USD). If we want to
have 3-4 developers working on that project we end up spending >2k USD, which is
not negligible cost. Obviously in this case DediProg is first component to cut
price. DediProg is high quality hardware and truly we don't always need to
bleeding edge quality. It was already proven, that accepting wiring hassle, we
may have hardware solution that is much cheaper. Namely we can utilize Raspberry
Pi 3 what reduce cost to 46USD and using RPi Zero W reduce that to 7USD. So the
purpose of below blog post is to use RPi Zero W (RPiZW) as flasher for
MinnowBoard Turbot and possibly other platforms. This is nothing new as many
times this procedures were described on various RPi versions.

## RPiZW preparation Get recent

[Raspbian Lite][1]. In this guide I used `2017-09-07` version. Flash it on SD
card and boot system. I am using USB to TTY converter so serial console
configuration was needed. To do that modify `config.txt` on boot partition of
Raspbian with below entry and the end of file:

    # Enable UART
    enable_uart=1

Next you have to setup WiFi. Easiest way is through modification of
[wpa_supplicant.conf][2]. Please note that `wpa_supplicant` is not started
automatically without additional configuration, so it is good to add below
configuration to `/etc/network/interfaces`:

    allow-hotplug wlan0
    iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
    iface default inet dhcp

After reboot your WiFi should be connected.

## Flashrom installation

    sudo apt update
    sudo apt install flashrom

## Electrical considerations

![mb_spi_schem][3]

MinnowBoard Turbot B uses `Winbond Electronics W25Q64BVSSIG` flash chip. This
chip requires power supply voltage range 2.7V - 3.6V. The energy needed to power
this memory may come from the internal power circuit of MinnowBoard Turbot B or
by connecting the voltage to the pin 1 of J1 MinnowBoard header. In each of
these cases the current flowing from the power source flows through the `NXP
Semiconductors BAT754C` Schottky barrier diode, which causes 0.6V voltage drop.
Therefore, it is necessary to supply a voltage of at least 3.3V to properly
supply the memory chip. `Winbond Electronics W25Q64BVSSIG` has `WP` and `HOLD`
input pins. The first of them activates write protect state. The second one
pauses device even if it is selected by SPI `CS` pin. `WP` and `HOLD` are
activated by a low logical state. Both inputs are pulled-up to the power line.
Therefore, when 3.3V is applied to the 1 pin of J1 header write protect and
pause states are disabled due to the presence of a high logical state on `WP`
and `HOLD` inputs. This is required when we want to flash memory chip via SPI
bus using external device. If J1 header pin 1 not connected, voltage present on
power supply line may be floating. It may cause problems to read and write data
to the `W25Q64BVSSIG` memory chip. MinnowBoard Turbot B external SPI bus
operates on voltages in the range 0V - 3.3V, although the SOC used in Turbot B
requires a voltage not exceeding 1.8 V. It happens because `NXP Semiconductors
NTB0104` dual supply translating transceiver mediates between the SPI buses.
This device changes voltage levels to the right values for each bus. `NTB0104`
chip has `OE` input, which corresponds to whether the signals are transmitted on
the 1.8 V side. For a high logical state signals are transmitted, for a low
logical state not. `OE` input is connected to J1 header 8 pin of MinnowBoard
Turbot B and it is pulled up to 1.8V power supply line. Therefore, when we want
to make sure that the bus is isolated from SOC, it is advisable to short pin 8
with ground. Then we communicate on SPI bus only with the `Winbond Electronics
W25Q64BVSSIG` memory chip. During tests we figured out that this is not
necessary to get correct results.

## Wiring

![rpizw_mb_wiring][4]

It is hard to explain that without nice drawing tool, but I will try with the
table and above picture:

| RPi Z W pin on J8 | MinnowBoard pin on J1 | wire color |
| ----------------- | --------------------- | ---------- |
| Pin 1 - 3V3 OUT   | Pin 1 - DDP_VCC       | red        |
| Pin 9 - GND       | Pin 2 - GND           | black      |
| Pin 24 - SPI CS0  | Pin 3 - DDP_CS        | green      |
| Pin 23 - SPI SCLK | Pin 4 - DDP_CLK       | blue       |
| Pin 21 - SPI MISO | Pin 5 - DDP_MISO      | orange     |
| Pin 19 - SPI MOSI | Pin 6 - DDP_MOSI      | yellow     |

# Running flashrom read

    flashrom -p linux_spi:dev=/dev/spidev0.0 -r mb.rom

It is good practice to read couple times and confirm that we reading the same
binary. We faced some problems when `HOLD#` and `WP#` were not pulled-up. After
reading, `binwalk` can be used to look inside binary:

    sudo apt-get install binwalk
    binwalk mb.rom
    DECIMAL       HEXADECIMAL     DESCRIPTION
    --------------------------------------------------------------------------------
    5308536       0x510078        LZMA compressed data, properties: 0x5D, dictionary size: 16777216 bytes, uncompressed size: 8974464 bytes
    7471424       0x720140        Microsoft executable, portable (PE)
    7502023       0x7278C7        mcrypt 2.2 encrypted data, algorithm: blowfish-448, mode: CBC, keymode: 8bit
    7510080       0x729840        Microsoft executable, portable (PE)
    7517504       0x72B540        Microsoft executable, portable (PE)
    7526432       0x72D820        Microsoft executable, portable (PE)
    7549216       0x733120        Microsoft executable, portable (PE)
    7559072       0x7357A0        Microsoft executable, portable (PE)
    7565216       0x736FA0        Microsoft executable, portable (PE)
    7570208       0x738320        Microsoft executable, portable (PE)
    7584832       0x73BC40        Microsoft executable, portable (PE)
    7594656       0x73E2A0        Microsoft executable, portable (PE)
    7600832       0x73FAC0        Microsoft executable, portable (PE)
    7607552       0x741500        Microsoft executable, portable (PE)
    7625128       0x7459A8        SHA256 hash constants, little endian
    7626944       0x7460C0        Microsoft executable, portable (PE)
    7649728       0x74B9C0        Microsoft executable, portable (PE)
    7930144       0x790120        Microsoft executable, portable (PE)
    7956000       0x796620        Microsoft executable, portable (PE)
    7966183       0x798DE7        mcrypt 2.2 encrypted data, algorithm: blowfish-448, mode: CBC, keymode: 8bit
    7966624       0x798FA0        Microsoft executable, portable (PE)
    7972640       0x79A720        Microsoft executable, portable (PE)
    7982592       0x79CE00        Microsoft executable, portable (PE)
    7995808       0x7A01A0        Microsoft executable, portable (PE)
    8008992       0x7A3520        Microsoft executable, portable (PE)
    8016288       0x7A51A0        Microsoft executable, portable (PE)
    8021920       0x7A67A0        Microsoft executable, portable (PE)
    8029472       0x7A8520        Microsoft executable, portable (PE)
    8042016       0x7AB620        Microsoft executable, portable (PE)
    8060320       0x7AFDA0        Microsoft executable, portable (PE)
    8075424       0x7B38A0        Microsoft executable, portable (PE)
    8135476       0x7C2334        Microsoft executable, portable (PE)
    8382584       0x7FE878        Microsoft executable, portable (PE)

If you want to get back to recent MinnowBoard firmware you can find it [here][5].

## Flashing coreboot binary

Easy way to bake coreboot binary on your workstation is using our
`coreboot-trainings-sdk` container:

    docker pull 3mdeb/coreboot-trainings-sdk:1.50
    git clone https://review.coreboot.org/coreboot
    cd coreboot
    git submodule update --init --checkout
    cd ..
    docker run --rm -it -v $PWD/coreboot:/home/coreboot/coreboot
    coreboot/coreboot-sdk:1.50 /bin/bash
    cd ~/coreboot
    make menuconfig

Choose mainboard vendor (Intel) and model (Minnow Max), then go to Chipset and
choose `Use Intel Firmware Support Pakcage`.

    make -j$(nproc)

### Get flash layout

To boot MinnowBoard Turbot we need binary blobs like flash descriptor, ME and
GbE. Those binaries should be already flashed on SPI. To avoid overwriting those
parameters you should use flashrom feature and point it to area you want to
replace.

    $ cd util/ifdtool
    $ make
    $ ./ifdtool -f layout path/to/mb.rom
    File /home/pietrushnic/tmp/mb.rom is 8388608 bytes
    Wrote layout to layout
    $ cat layout
    00000000:00000fff fd
    00400000:007fffff bios
    00001000:003fffff me
    00000000:00000fff gbe

From above we know that bios region, in which `coreboot.rom` should be flashed,
has range `00400000:007fffff`.

### Flashing

Then copy `coreboot/build/coreboot.rom` to Raspberry Pi and flash:

    echo 00400000:007fffff cb > 8mb.layout
    flashrom -p linux_spi:dev=/dev/spidev0.0 -l 8mb.layout -i cb -w coreboot.rom

Disconnect wires after flashing. After powering on MinnowBoard Turbot you should
see serial output:

    (...)
    Searching bootorder for: /pci@i0cf8/pci-bridge@1c,2/*@0

    Press ESC for boot menu.

    Searching bootorder for: HALT
    Space available for UMB: c1000-ee800, f6940-f70d0
    Returned 262144 bytes of ZoneHigh
    e820 map has 17 items:
      0: 0000000000000000 - 000000000009fc00 = 1 RAM
      1: 000000000009fc00 - 00000000000a0000 = 2 RESERVED
      2: 00000000000f0000 - 0000000000100000 = 2 RESERVED
      3: 0000000000100000 - 0000000020000000 = 1 RAM
      4: 0000000020000000 - 0000000020100000 = 2 RESERVED
      5: 0000000020100000 - 000000007ad9e000 = 1 RAM
      6: 000000007ad9e000 - 0000000080000000 = 2 RESERVED
      7: 00000000e0000000 - 00000000f0000000 = 2 RESERVED
      8: 00000000feb00000 - 00000000fec01000 = 2 RESERVED
      9: 00000000fed01000 - 00000000fed02000 = 2 RESERVED
      10: 00000000fed03000 - 00000000fed04000 = 2 RESERVED
      11: 00000000fed05000 - 00000000fed06000 = 2 RESERVED
      12: 00000000fed08000 - 00000000fed09000 = 2 RESERVED
      13: 00000000fed0c000 - 00000000fed10000 = 2 RESERVED
      14: 00000000fed1c000 - 00000000fed1d000 = 2 RESERVED
      15: 00000000fee00000 - 00000000fee01000 = 2 RESERVED
      16: 00000000fef00000 - 00000000ff000000 = 2 RESERVED
    enter handle_19:
      NULL


## Speed up flashing procedure

There is magic flashrom parameter `spispeed`. Value it accepts depends on
hardware. RPi supports max 125MHz, but MinnowBoard chip has max speed of 80MHz.
Typical flashing time without that parameter is ~6min and it seems that default
SPI speed is set to 512kHz, so changing it matters a lot. From my experiments
32MHz works without problems.

    $ time flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=32000
    -l 8mb.layout -i cb -w coreboot.rom

    flashrom v0.9.9-r1954 on Linux 4.9.41+ (armv6l)
    flashrom is free software, get the source code at https://flashrom.org

    Using region: "cb".
    Calibrating delay loop... OK.
    Found Winbond flash chip "W25Q64.V" (8192 kB, SPI) on linux_spi.
    Reading old flash chip contents... done.
    Erasing and writing flash chip... Erase/write done.
    Verifying flash... VERIFIED.

    real    0m22.940s
    user    0m8.090s
    sys     0m6.470s

This is impressive improvement and knowledge about this feature is not so common.

## Recovery procedure

If for some reason you will overwrite different regions then needed and you end
up with not bootable platform you can write stock firmware and reflash coreboot
again. For example:

    $ flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=32000 -w MNW2MAX1.X64.0097.D01.1709211100.bin
    $ flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=32000 -l 8mb.layout -i cb -w coreboot.rom


## Stability issues

Above solution is low cost as well as low quality. A lot depends on quality of
wires. Probably well fitted connectors would save a lot of headache. Continuous
connecting/disconnecting cables damage pins and cables making things not stable
in long run. It would be useful to have header that match this setup on both
sides.

## Summary

I'm pretty sure that for most coreboot people this is not new stuff, but we
needed that post to refresh knowledge for beginners as well as for internal
usage. It's good to have all instructions in one place. If you have any comments
please feel free to contact us.

 [1]: https://www.raspberrypi.org/downloads/raspbian/
 [2]: https://core-electronics.com.au/tutorials/raspberry-pi-zerow-headless-wifi-setup.html
 [3]: /img/mb_spi_schem.png
 [4]: /img/rpizw_mb_wiring.jpg
 [5]: https://firmware.intel.com/projects/minnowboard-max

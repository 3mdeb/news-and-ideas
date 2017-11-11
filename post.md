---
post_title: Flashing MinnowBoard Turbot with Raspberry Pi Zero W
author: Piotr Król, Arkadiusz Cichocki
post_excerpt: ""
layout: post
published: true
post_date: 2017-11-20 00:21:00
tags:
  - coreboot
  - UEFI
  - RPi
  - Intel
categories:
  - Firmware
---

Recently we started preparation of coreboot training for one of our customers.
Out platform of choice for that training is MinnowBoard Turbot. There are
couple reasons for that:

* during training we can show recent firmware trends - despite we don't like
  blobs (FSP, AGESA, PSP, ME etc.) and bloated designs (UEFI) we cannot escape
  reality and have to show customers how to deal with those components.
  MonnowBoard Turbot use couple of them, but also support coreboot.

* we can present recent Intel SoC features - MinnowBoard Turbot Dual-Core has
  Intel Atom E3826 which support for VT-x, TXE, PCU (Platform Control Unity),
  JTAG and other features that can be very interesting from firmware engineer
  point of view

* we can use platform which is used as reference design for various products -
  it looks like market for BayTrail (and newer Intel platforms) is quite big
  and there are many companies that develop solutions based on it

MinnowBoard was also used in UEFI security related trainings in which we are
really interested in.

Key problem with presentation and workshop preparation was need for SF100 as
SPI programmer. This tool is high quality, but is quite expensive. When we add
it to cost of MinnoBoard, equipment and shipping we end up with cost of one
development environment ~530USD (MinnowBoard Turbot: 200USD, SF100: 230USD,
peripherals+power supply: 50USD, shipping: 50USD). If we want to have 3-4
developers working on that project we end up spending >2k USD, which is not
negligible cost.

Obviously in this case DediProg is first component to cut price. DediProg is
high quality hardware and truly we not always need to bleeding edge quality. It
was already proven, that accepting longer flashing time, we may have hardware
solution that is much cheaper. Namely we can utilize Raspberry Pi 3 what reduce
cost to 46USD and using RPi Zero W reduce that to 7USD.

So the purpose of below blog post is to use RPi Zero W (RPiZW) as flasher for
MinnowBoard Turbo and possibly other platforms. This is nothing new as many
times this procedures were described on various RPi versions.

# RPiZW preparation

Get recent [Raspbian Lite](https://www.raspberrypi.org/downloads/raspbian/). In
this guide I used `2017-09-07` version. Flash it on SD card and boot system. I
used to use USB to TTY converter so serial console configuration was needed. To
do that modfiy `config.txt` on boot partition of Raspbian with below entry and
end of file:

```
# Enable UART
enable_uart=1
```

Next you have to setup WiFi. Easiest way is through modification of
[wpa_supplicant.conf](https://core-electronics.com.au/tutorials/raspberry-pi-zerow-headless-wifi-setup.html).

Please note that `wpa_supplicant` is not started automatically without
additional configuration, so it is good to add below configuration to
`/etc/network/interfaces`:

```
allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
iface default inet dhcp
```

After reboot your WiFi should be connected.

# Flashrom compilation

```
sudo apt update
sudo apt install flashrom
```

# Wiring

![rpizw_mb_wiring](http://3mdeb.com/wp-content/uploads/2017/07/rpizw_mb_wiring.jpg)

It is hard to explain that without nice drawing tool, but I will try with the
table and above picture:

|RPi Z W pin on J8 | MinnowBoard pin on J1 | wire color |
|---|---|---|
| Pin 1 - 3V3 OUT | Pin 1 - DDP_VCC| red |
| Pin 9 - GND | Pin 2 - GND| black |
| Pin 24 - SPI CS0 | Pin 3 - DDP_CS | green |
| Pin 23 - SPI SCLK | Pin 4 - DDP_CLK | blue |
| Pin 21 - SPI MISO | Pin 5 - DDP_MISO | orange |
| Pin 19 - SPI MOSI | Pin 6 - DDP_MOSI | yellow |

# Running flashrom read

```
flashrom -p linux_spi:dev=/dev/spidev0.0 -r mb.rom
```

It is good practice to read couple times and confirm that we reading the same
binary. We faced some problems when `HOLD#` and `WP#` were not pulled-up.

After reading, `binwalk` can be used to look inside binary:

```
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
```

If you want to get back to recent MinnowBoard firmware you can find it [here](https://firmware.intel.com/projects/minnowboard-max).

# Flashing coreboot binary

Easy way to bake coreboot binary is using our `coreboot-trainings-sdk`
container:

```
docker pull 3mdeb/coreboot-trainings-sdk:1.50
git clone https://review.coreboot.org/coreboot
cd coreboot
git submodule update --init --checkout
cd ..
docker run --rm -it -v $PWD/coreboot:/home/coreboot/coreboot \
coreboot/coreboot-sdk:1.50 /bin/bash
cd ~/coreboot
make menuconfig
```

Choose mainboard vendor (Intel) and model (Minnow Max), then go to Chipset and
choose `Use Intel Firmware Support Pakcage`.

```
make -j$(nproc)
```

Then copy `coreboot/build/coreboot.rom` to Raspberry Pi and flash:

```
flashrom -p linux_spi:dev=/dev/spidev0.0 -w coreboot.rom
```

After reboot you should see:

```

```

# Stability issues

Above solution is low cost as well as low quality. A lot depends on quality of
wires. Probably well fitted connectors would save a lot of headache.

We also observed complains from flashrom:

```
Erasing and writing flash chip... FAILED at 0x00000010! Expected=0xff, Found=0x5a, failed byte count from 0x00000000-0x00000fff: 0xa5
ERASE FAILED!
Reading current flash chip contents... done. Looking for another erase function.
FAILED at 0x00000010! Expected=0xff, Found=0x5a, failed byte count from 0x00000000-0x00007fff: 0x260
ERASE FAILED!
```

This solution is also much slower, but if you need cheap alternative to SF100,
then some trade-offs have to be taken.

# Summary

I'm pretty sure that for most this is not new stuff, but we needed that post
refreshed for beginners as well as internal usage. It's good to have all
instructions in one place.

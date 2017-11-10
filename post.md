---
post_title: Flashing MinnowBoard Turbot with Raspberry Pi Zero W
author: Piotr Król
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
MinnowBoard Turbo and possibly other platforms.

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
sudo apt update && sudo apt upgrade
sudo apt install git libpci-dev libusb-dev libusb-1.0-0-dev
git clone https://review.coreboot.org/flashrom.git
cd flashrom
make
```


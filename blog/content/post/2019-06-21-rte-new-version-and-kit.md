---
title: RTE v1.1.0 - enhanced remote testing now available!
abstract: Get familiar with new RTE revision - what has been changed, which
          features are now more complex and which items has been added to the
          RTE kit available at our online shop.
cover: /covers/rte-new-revision.jpg
author: artur.raglis
layout: post
published: true
date: 2019-06-19
archives: "2019"

tags:
  - rte
  - shop
  - validation
categories:
  - Miscellaneous
  - Manufacturing

---

## Intro

Today we are happy to announce the new version of Remote Testing Environment
product - welcome RTE `v1.1.0`!

After using RTE over a year at 3mdeb in everyday tasks regarding validation and
developing firmware for various platforms, we have noticed more and more missing
features in the presented Orange Pi Hat. Furthermore, we have received valuable
feedback from our previous customers and we have addressed all requested
hardware and software upgrades. In result, we have achieved product that is even
more universal and capable of controlling and flashing wider range of computer
platforms.

## What's new?

Brand new RTE (previously `v1.0.0`) has been improved mostly from the hardware
perspective:

* SPI `Vcc` pin has been populated - power is now supplied to the SPI `Vcc`
  connector
* RTE is now compatible with 1.8V logic levels
* user can enable/disable SPI `Vcc` on demand:

| GPIO406 (OC_OUT1) state | SPI Vcc               |
|:-----------------------:|:---------------------:|
| 0 - low                 | disabled (by default) |
| 1 - high                | enabled               |

* user can choose the voltage level for `Vcc` SPI - either 1.8 or 3.3 V:

| GPIO405 (OC_OUT2) state | SPI Vcc voltage level |
|:-----------------------:|:---------------------:|
| 0 - low                 | 1.8 V (by default)    |
| 1 - high                | 3.3 V                 |

* user can enable/disable SPI lines (some platforms have problems when booting
  with SPI wires connected):

| GPIO404 (OC_OUT3) state | SPI lines (MOSI/MISO/CS/SCLK) |
|:-----------------------:|:-----------------------------:|
| 0 - low                 | disabled (by default)         |
| 1 - high                | enabled                       |

* OC buffers GPIO header (J11) is reduced from 12 to 9 pin. accordingly to the
  `GPIO404-406` new control feature,
* new UART header (J18) has been added - USB/UART external converters are not
  required anymore!
* user can choose whether RS232 DB9 port (J14) or UART header (J18) is enabled
  for serial communication by setting jumpers on `UART OUTPUT SELECT` header
  (J16):

| Jumper position (TX and RX) | Serial communication enabled |
|:---------------------------:|:----------------------------:|
| RS232 + COM                 | RS232 DB9 port (J14)         |
| EXT + COM                   | 3.3V UART header (J18)       |

![uart-header](/img/rte-uart-header.jpg)

* eliminated issue with J6 USB port (unreliable detection of USB devices)
* smaller capacitors were applied near MAX3232 SOIC
* added LED indicator (D5) for relay state information
* added easy accessible reset button (SW1) for resetting the RTE board

![reset-button](/img/rte-reset-btn.jpg)

* added `Open hardware` icon on PCB board

![open-hardware-pcb](/covers/rte-new-revision.jpg)

## Upgraded full kit

We came to the conclusion to remove shop kit options for RTE. From now on there
is only one possible set to buy - the full one with all required elements for
development and testing devices. Moreover, we have expanded kit with M3 plastic
spacers, set of jumpers (serial communication header) and Pomona 8-pin SOIC clip
with 8 connection wires for flashing firmware on platforms without SPI header.

To sum up, full kit costs now 93€ and includes:

| Category     | Description                                                     | Quantity |
|:------------:|:---------------------------------------------------------------:|:--------:|
| shield       | Remote Testing Environment v1.1.0                               | 1        |
| control unit | Orange Pi Zero 256MB RAM version                                | 1        |
| power supply | MicroUSB 5V/2A                                                  | 1        |
| storage      | SanDisk 16GB microSD card (with preinstalled compatible system) | 1        |
| clip         | Pomona 8-pin SOIC clip for Device Under Test SPI interface      | 1        |
| cables       | standard female-female connection wire 2.56mm raster            | 8        |
| cables       | IDC 8-pin wires for Device Under Test SPI interface             | 1        |
| cables       | DC Jack - DC Jack power cable for Device Under Test             | 1        |
| cables       | RS232 D-Sub 9P/9P cable for serial communication                | 1        |
| jumpers      | jumper for UART OUTPUT SELECT header                            | 2        |
| spacers      | Polyamide M3 spacers and bolts                                  | 4        |

## Summary

Don't hesitate and check out our **RTE** product on the [3mdeb-shop](https://shop.3mdeb.com/product/rte/)
where you can find more information about Orange Pi Zero shield or read about
products related to platform security such as **Trusted Platform** modules.

If you think that RTE is the product that You are looking for, but missing
something crucial for your project or that we can help in improving the security
of your firmware or you looking for someone who can boot your product by
leveraging advanced features of used hardware platform, feel free to
[boot a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD).

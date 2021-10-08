---
title: "Right to Repair - and why is it important?"
abstract: "Let's observe the struggles of today's repairman,
          why a right to repair is important and how 3mdeb can help."
cover: /covers/right_to_repair.png
author: mike.banon
layout: post
published: true
date: 2021-04-30
archives: "2021"

tags:
  - Repair
  - Activism
  - Community
  - Firmware
  - Hardware
categories:
  - Hardware
  - Miscellaneous

---

## Struggles of today's repairman

Any electronic device, regardless of its brand name, could break down eventually
- and getting a new one isn't always wise. What are the options if an owner
wants to repair his device by replacing or fixing its' internal components?

Let's say we would like to repair by replacing the components - which is more
accessible to an unskilled person. Usually, a manufacturer doesn't let the users
buy the spare parts directly: instead, it partners with a few chains of hardware
repair shops who are glad to make a profit. This results in a modest supply
limited to the unofficial channels: the owner gets a part either extracted from
some used device without a guarantee or quality, or bought under the table from
the unused supplies of these hardware repair shops through some grey-market
schemes.

If we would like to repair by fixing the components such as the laptop's
motherboard: in addition to some soldering skills - and hoping we won't have to
replace a BGA or a "centipede" SMD - we also need the board-specific
information. A motherboard's datasheet could be a great source of knowledge:
i.e. it could provide a diagram of power circuits with the known good voltages
at the various motherboard's points - which could greatly assist in
troubleshooting and finding the faulty components.  However, usually a
manufacturer doesn't provide a datasheet. So it'll be either unavailable or an
illegally leaked one: at some dark corner of the Internet, maybe for an older
motherboard revision and isn't user-friendly to study - since they didn't write
this internal documentation with end-users in mind.

Unfortunately, the firmware problems could accompany the hardware one. If a
controller with internal memory got burned, in addition to replacing a
controller - you'll also need to get a suitable firmware and find a way to
install it.

And the components themselves may be firmware-locked: to ensure that you can't
replace a broken part by yourself and have to bring your device to an authorized
hardware repair shop - who knows how to pass this system but charges a lot for
their services.

## "Right to repair" activism

Tired of jumping through these hoops while trying to fix their devices, the
people are advocating for "Right to repair" laws - which should force the
uncooperative manufacturers to sell the replacement parts and provide their
datasheets. One of the prominent activists is Trammell Hudson, a director of
special projects at Lower Layer Labs: several years ago, he became frustrated
with the limited capabilities of digital cameras and decided to reverse engineer
camera firmware to better meet his needs. That led to the creation of an open
source developer community focused on modifying camera firmware and Magic
Lantern, a software extension to expand the capabilities of digital cameras.

"It's really my firm belief that everyone should be able to customize and repair
devices that they own, including modifications to both the hardware and the
firmware, and especially that they be able to publish information on how to do
this, so that others are able to do the same," - he said. However, this may take
plenty of time to get these laws passed because of the lobbying by corporations.

## 3mdeb position

For those who aren't willing to wait or buy an older used device with a higher
repairability: there are some companies - who, despite not being obliged by law,
are voluntarily providing the "Right to repair" in an attempt to win the hearts
of customers. One of such companies is [3mdeb][1]: the [licensed provider][2] for quality
coreboot consulting services and Open Source Firmware Vendor (OSFV) relying on
[Dasharo][3] to deliver scalable, modular, easy to combine Open Source BIOS,
UEFI, and Firmware solutions. When we have the board schematics and our hands
are not tied by the NDAs - we happily provide these schematics to our customers,
and intend to continue doing so with our upcoming products as well.

If you are interested in these topics, feel free to reach us out by writing to
<contact@3mdeb.com>, [sign up to our newsletter][4] and check our other [blogposts][5].

 [1]: https://3mdeb.com/
 [2]: https://3mdeb.com/about-us/
 [3]: https://dasharo.com/
 [4]: https://eepurl.com/doF8GX
 [5]: https://blog.3mdeb.com/

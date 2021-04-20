---
title: "Right to Repair - and why is it important?"
abstract: "Let's observe the struggles of today's repairman,
          why a right to repair is important and how 3mdeb can help."
cover: /covers/right_to_repair.png
author: mike.banon
layout: post
published: true
date: 2021-04-20
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

Tired of jumping through these hoops while trying to fix their devices, the
people are advocating for "Right to repair" laws - which should force the
uncooperative manufacturers to sell the replacement parts and provide their
datasheets. One of the prominent activists is Trammell Hudson. [TBD: Expand the
info here.] However, this may take a long time to get these laws passed.

For those who aren't willing to wait or buy an older used device with a higher
repairability: there are some companies - who, despite not being obliged by law,
are voluntarily providing the "Right to repair" in an attempt to win the hearts
of customers. One of them is 3mdeb. [TBD: I struggle in interleaving the
3mdeb/Dasharo/OSF to the writing. What could the open-source firmware add to
"right to repair" other than not locking the components by ID like Apple, and
how 3mdeb/Dasharo could additionally help? I.e. if you're designing your custom
boards, would you provide the board schematics to your customers - as well as
the spare parts if your device isn't monolithic?]


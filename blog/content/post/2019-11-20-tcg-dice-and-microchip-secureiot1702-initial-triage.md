---
title: 'TCG DICE and Microchip SecureIoT1702 initial triage'
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: piotr.krol
layout: post
published: false
date: 2019-11-20
archives: "2019"

tags:
  - Microchip
  - TCG
  - TPM
  - DICE
categories:
  - Firmware
  - IoT
  - Security

---

TBD: describe DICE and its goals, how Microchip CEC1702 aligns with DICE

We promised that blog post long time ago on
[Twitter](https://twitter.com/3mdeb_com/status/1103628886955442176). Finally,
we have some free cycles to play with another Microchip security element. In
the past we played with Atmel/Microchip ATECC508A and ATECC608A with great
success in couple project.

Meanwhile security chips ecosystem gains very interesting new player
[OpenTitan](https://opentitan.org), which definitely is game changes in
hardware Root of Trust environment. As a open source and open hardware
consulting company we will encourage our customers to leverage new project
wherever it is possible.

Of course we are mostly interested about open-source ecosystem for mentioned
hardware and would like to avoid any weird IDE or proprietary technologies.

As every good triage of new board we should start with [User Guide reading](http://ww1.microchip.com/downloads/en/DeviceDoc/SecureIoT1702-Users-Guide-DS50002729A.pdf).
Unfortunately Microchip recommends Keil uVision as IDE

Board is not exactly developers friendly:
- expensive SPI programmer is recommended (DediProg SF100)


## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

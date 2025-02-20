---
title: Conclusions from RAM data remanence tests
abstract: 'A practical summary from the two previous blog posts presenting results of RAM data remanence tests.'
cover: /covers/image-file.png
author: maciej.pijanowski
layout: post
published: true
date: 2025-02-20
archives: "2025"
cover: /covers/DRAM_Cell.png

tags:
  - testing
categories:
  - Firmware
  - Miscellaneous

---

## General recommendation

General recommendation regarding leaving your device (with DDR4/DDR5 non-ECC
RAM) unattended after shutdown, considering the risks of cold boot attack:
- once device was shutdown, and left indoors at a room temperature, it's
  unlikely that any useful data can be extraced after < 10s for most memory
  modules,
  - for some specific memory modules this time may be higher; we have came
    across one specific module in which case it would be recommended to wait
    2 minutes until the data decays to a sufficient extent,
  - therefore the recommendation would be to wait 2 minutes until leaving
  device unattended, unless you have done prior testing of your specific setup
  using e.g. [this test app](https://github.com/Dasharo/ram-remanence-tester).

## Graceful vs forced shutdown

For practical application, there is no significant difference in RAM decay rate
between graceful (`shutdown` system command) or forced (cutting off the power)
shutdown.

## Impact of the notebook battery

Once notebook is shutdown (either via `shutdown` command, or via power button),
the presence of battery **does not** mean that the data in RAM is still being
refreshed. It can be only refreshed when notebook is powered on, or in suspend
(`S3`), not in shutdown state.

Recommendation: whether the battery is present in the notebook, ot not, it does
not negatively impact user concerned of the cold boot attack. There is no
significant difference in RAM decay rate here for a practical application.

## DDR4 vs DDR5 (non-ECC)

For practical application, there is no significant difference in RAM decay rate
between DDR4 and DDR5 modules.

## Memory clearing

For certain use-cases,
[memory clearing](https://doc.coreboot.org/security/memory_clearing.html)
feature can be implemented in boot firmware. It makes the initial boot longer,
and must be implemented on the machine where the modules would be placed for
data extraction.

Therefore, it might prevent these types of attacks, where memory modules are
not swapped to another machine.

## Summary

This research has been supported by Power Up Privacy, a privacy advocacy group
that seeks to supercharge privacy projects with resources so they can complete
their mission of making our world a better place.

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

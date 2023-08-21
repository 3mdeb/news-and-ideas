---
title: How TwPM is tested
abstract: 'This post shows how we tested simple commands on TwPM, which is our
          attempt at making TPM more open.'
cover: /covers/image-file.png
author: krystian.hebel
layout: post
published: true
date: 2023-08-21
archives: "2023"

tags:
  - TPM
  - TwPM
  - testing
categories:
  - Firmware
  - Security

---

TwPM project aims to increase the trustworthiness of the TPM module (hence the
TwPM), by providing the open-source firmware implementation for the TPM device,
compliant to the TCG PC Client Specification. Project aims to use already
available open-source software components whenever possible (such as TPM
simulators for TPM commands handling), while developing new code when necessary
(such as LPC FPGA module, or low-level TPM FIFO interface handling).

This project was funded through the [NGI Assure Fund](https://nlnet.nl/assure),
a fund established by [NLnet](https://nlnet.nl/) with financial support from the
European Commission's [Next Generation Internet](https://ngi.eu/) programme,
under the aegis of DG Communications Networks, Content and Technology under
grant agreement No 957073.

The project just entered a phase in which all basic components can communicate
with each other. This should be enough to test simplest commands that don't
require use of parts that aren't implemented yet. Nonvolatile storage, true
randomness source and primary keys' certificates manufacturing process are yet
to be implemented. As such, in current state TwPM cannot be used for all use
cases of TPM, but we're slowly getting there.

## SBOM

TDB: add links and revisions to code:
- TPM stack - Zephyr etc.
- top module
- TPM registers module
- LPC module

## Compiling and flashing

TBD: update documentation and link it here

## Connecting to the mainboard

TBD: choose mainboard(s), add table(s) with connections

## Test suite

TBD: link to test suite, results, demo of running tests?

## Known issues and limitations

TBD: if any

## Summary

TBD

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

---
title: Fobnail Token - platform attestation
abstract: 'The Fobnail Token is an open-source hardware USB device that helps to
           determine the integrity of the system. The purpose of this blog post
           is to present the development progress of this project. This phase
           was focused on attestation.'
cover: /covers/usb_token.png
author: krystian.hebel
layout: post
published: true
date: 2022-04-07
archives: "2022"

tags:
  - fobnail
  - firmware
  - tpm
  - attestation
categories:
  - Firmware
  - Security

---

# About the Fobnail Token project

The Fobnail Token is a project that aims to provide a reference architecture for
building offline integrity measurement servers on the USB device and clients
running in Dynamically Launched Measured Environments (DLME). It allows the
Fobnail owner to verify the trustworthiness of the running system before
performing any sensitive operation. This project was founded by [NlNet
Foundation](https://nlnet.nl/). More information about the project can be found
in the [Fobnail documentation](https://fobnail.3mdeb.com/). Also, make sure to
read other posts related to this project by visiting
[fobnail](https://www.blog.3mdeb.com/tags/fobnail/) tag.

# Attestation

## Architecture

## Implementation

# Demo

[![asciicast](https://asciinema.org/a/OJ1YWyKhexSztmbfNVS79eGbo.svg)](https://asciinema.org/a/OJ1YWyKhexSztmbfNVS79eGbo?speed=1)

# Running Fobnail on real hardware

During early development, we used nRF52 as a device for running Fobnail
firmware. However, due to problems with USB, we started running Fobnail as a
Linux application during the previous phase. The time has come to fix this.

## Fixing USB

Many times when Fobnail was plugged into USB, it didn't work properly. This
problem has been described
[here](https://github.com/fobnail/usbd-ethernet/issues/2). We have searched thru
issues and PRs of the libraries we use and updated them to their latest
versions, but it didn't help, so we started looking for the issue in our own
code.

The direct cause of USB failure was a too big delay between USB interrupts, up
to 85 ms, which occurred right after USB initialization. At first, we tried
profiling USB driver interrupt handler and critical sections, and both were
taking less than 1ms delay. Eventually, we discovered that the problem lies not
in the USB driver but in the NVMC driver, which we use for storing persistent
data in flash memory. When writing to flash, NVMC will stop CPU while writing,
and erasing a single 4K flash page takes exactly 85 ms.

Fortunately, nRF52840 has a feature called partial erase, which allows us to
split erase into many iterations. Instead of sleeping once for 85 ms, we can 85
times for 1 ms allowing USB interrupt to fire in-between.
[nrf-hal](https://github.com/nrf-rs/nrf-hal) didn't support partial erase, so we
implemented this on our own and opened
[PR](https://github.com/nrf-rs/nrf-hal/pull/385).

Implementing partial erase and a few other smaller fixes (described in
[commit history](https://github.com/fobnail/fobnail/pull/24/commits)) fixed USB.

## Fixing LittleFS

We have a problem with LittleFS
[corrupting](https://github.com/fobnail/fobnail/issues/12) itself, usually
during certificate installation. So far, we haven't discovered the exact cause
of the problem, and we are still working on this. It looks like the problem is
located in Rust bindings to LittleFS since it doesn't occur with equivalent
written in C. Problem is described more in-depth
[here](https://github.com/nickray/littlefs2/issues/16)

## Signaling provisioning and attestation result

We implemented LED driver, now Fobnail will signal attestation (and
provisioning) result using either red or green LED. Provisioning status is
signaled by 3 quick blinks and attestation status is signaled by flashing LED
for 10 seconds.

![Fobnail flashing red LED](/img/fobnail_red_led.jpg)

Right now Fobnail blinks with red LED, because we don't have support for
installing certificates into flash (we support this but only for emulated flash
on PC). We will implement this during the next phase. Until then you can comment
out [code](https://github.com/fobnail/fobnail/blob/86e3f22edba3e07f2eb54156e16a660d8c7254f6/src/certmgr/verify.rs#L45)
responsible for certificate verification.

## Summary

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

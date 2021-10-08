---
title: fwupd on FreeBSD - Status Update
abstract: "As the fwupd port for FreeBSD nears completion,
          let's take a look at the biggest challenges we faced
          and how we managed to overcome them."
cover: /covers/fwupd_bsd.png
author: michal.kopec
layout: post
published: true
date: 2021-06-14
archives: "2021"

tags:
  - fwupd-for-bsd
  - bsd
  - fwupd
categories:
  - Firmware

---

This is the third entry in the series documenting porting fwupd to *BSD
distributions. If you haven't read the
[previous](https://blog.3mdeb.com/2021/2021-02-16-fwupd-compilation-under-freebsd/)
[entries](https://blog.3mdeb.com/2021/2021-03-15-fwupd-bsd-packages-and-ci/),
I encourage you to do so.

---

## Introduction

In this blog post, I will document how we created a working port of fwupd for
FreeBSD, as well as the biggest challenges we encountered.

We found we had to implement 3 basic functionalities in order to have a basic
FreeBSD port:

- Gathering information about applicable updates for attached devices,
- Updating firmware of devices attached via USB,
- Updating the system firmware via the UEFI Update Capsule mechanism.

## Identifying available updates

One difference between Linux and FreeBSD 12.2, on which we started development,
is the lack of `memfd_create(),` a function that creates an anonymous,
temporary file in memory and returns a file descriptor. This is an alternative
to creating a temporary file and having to manage it manually, and fwupd
utilizes it for handling downloads.

Older (pre-13.0) versions of FreeBSD and other BSD distributions do not have an
equivalent API - so we had to emulate it by creating a temporary unlinked file.
The pull request adding this functionality is available
[here](https://github.com/fwupd/fwupd/pull/3279).

As you can see from the logs below, we are now able to identify available
updates for our machine - in this case, a Dell XPS 15 9560.

[![asciicast](https://asciinema.org/a/UJ2RRlo6lvgWfLJE5Mr9uuO2d.svg)](https://asciinema.org/a/UJ2RRlo6lvgWfLJE5Mr9uuO2d)

## Applying USB updates

Next, we encountered a problem with USB device updates: We tried to update
the firmware of a ColorHug2, and after rebooting it to the device's bootloader mode,
it didn't return to the operating system.

fwupd uses the libgusb library, a GLib wrapper around libusb. The usual flow
of an update is as follows:

1. Issue command to the device to enter bootloader mode - in the case of ColorHug2,
a custom HID-based flashing mode
2. Write an update to the device
3. Upon successful update, return the device to runtime mode

The issue occurred after the first step - we were unable to reattach the device to
the host. After issuing a command to reset the device back to normal operation,
the OS would not recognize and reattach it - it would stay gone.

Because libgusb uses libusb's asynchronous API, fwupd would close a
device after an update before all events had been processed. Upon processing
such an event, libusb would detect that the device is gone and mark it with
a `device_is_gone` flag. This meant that on all future requests, libusb would
fail with a `LIBUSB_ERROR_NO_DEVICE` error.

This turned out to be another difference between the Linux and FreeBSD APIs.
The way fwupd utilizes the libusb API was legal under the Linux version of
libusb. Therefore, we decided to change FreeBSD's behavior to more closely match
that of Linux. We did so by making it so that a device can only be marked as
gone if it's currently open.

The patch was submitted and accepted into the FreeBSD tree and is available
[here](https://cgit.freebsd.org/src/commit/?id=6847ea50196f1a685be408a24f01cb8d407da19c).

And with that, we can now perform a successful update of a ColorHug2:

[![asciicast](https://asciinema.org/a/G2OT5XvMpv9r10Q6qD5rZBbLA.svg)](https://asciinema.org/a/G2OT5XvMpv9r10Q6qD5rZBbLA)

## UEFI Update Capsule

From the perspective of security, UEFI updates are absolutely critical and
implementing this functionality for FreeBSD was a priority. There were a couple
of parts that would need to be implemented in order to make it work:

- UEFI ESRT table support in FreeBSD, and support for it in fwupd
- FreeBSD efivar backend for fwupd - on Linux, efivar support is implemented
via a `sysfs` interface, while FreeBSD has a C API
- `bsdisks` support in fwupd
- adding support in an `fwupd` daemon plugin - the UEFI update capsule plugin

UEFI ESRT (EFI System Resource Table) is a standard interface for firmware
updates available since UEFI 2.5. It exposes, among other data, information
about the currently installed firmware versions and the status of last
update attempt. It's used by fwupd for detection and matching available
updates. Support for these tables was missing in FreeBSD - so we added it.
Upstream patches available [here](https://reviews.freebsd.org/D30104).

fwupd applies firmware updates by installing a small EFI binary along with the
update capsule into the ESP and setting the EFI bootnext variable to point to it.
The machine reboots and launches the EFI binary which then calls
`UpdateCapsule()`, which in turn tells the UEFI to apply the capsule. The
actual flashing is handled by the UEFI implementation itself.

This requires efivar support, and FreeBSD has a different, programmatic
API, so support for it had to be added in fwupd. Furthermore, since FreeBSD has
a disk management API that differs slightly from the Linux standard UDisks2 API,
support for it also had to be added. The patches (
[1](https://github.com/fwupd/fwupd/pull/3330),
[2](https://github.com/fwupd/fwupd/pull/3318)
) were accepted by upstream.

With these patches, it is currently possible to install a UEFI update - but
keep in mind that this is an early implementation and bugs are more than likely
to occur. Bug reports are welcome.

[![asciicast](https://asciinema.org/a/EG2W6t13jeyxyoQIxzc4dmgeQ.svg)](https://asciinema.org/a/EG2W6t13jeyxyoQIxzc4dmgeQ)

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

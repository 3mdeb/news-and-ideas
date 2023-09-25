---
title: 'Simplifying Firmware Updates in Dasharo'
abstract: "Updating your firmware is an important part of keeping your device
          secure and reliable. Making this process as easy and reliable as
          possible is, therefore, a big focus for Dasharo. In this article we'll
          dive into the latest feature that make the update process a bit
          easier, and talk about where we want to go from here."
cover: /covers/dasharo-sygnet.svg
author: michal.kopec
layout: post
published: true
date: 2023-09-12
archives: "2023"

tags:
  - coreboot
  - UEFI
categories:
  - Firmware

---

## Introduction

The word _firmware_ comes from the fact that it sits somewhere in between
_soft_ware and _hard_ware. This term refers to the fact that firmware provides
an abstraction layer for hardware, so that software (e.g. OS) can make use of it
in a more generic manner.

Firmware also sits between hardware and software in a different category, which
is "how hard it is to modify". While software is easy to modify and update,
hardware is set in stone and cannot be fixed so easily (at least without
recalling devices and replacing components). Firmware, again, sits somewhere in
between those two.

While software typically resides on easily re-writable, fast, dense media,
firmware is usually stored separately. On x86, the boot firmware resides in SPI
flash chips, which is typically mapped by the chipset just below the first 4GB
of memory, which is a legacy of early x86 processors.

## Status quo

Right now, the recommended method of updating Dasharo is to use flashrom, which
is a tool running on Linux, writing to the BIOS flash memory by directly
accessing the SPI flash controller. This has the benefit of removing unnecessary
complexity from the firmware itself, and giving maximum control to the user. But
this approach has one big drawback: it's not secure. A malicious actor can
simply overwrite firmware with malicious, unverified code and we wouldn't be
able to stop them - and because we don't use Intel Boot Guard or other hardware
based root of trust, we wouldn't be able to detect such modifications.

How do we protect against this? Dasharo has several security features for this
specifically:

- Protected Range Registers: The firmware programs which ranges of SPI flash
  addresses are not allowed to be written to. This is typically set to the
  initial bootblock, which verifies the subsequent boot stages, and a recovery
  partition for when verification fails.

- SMM_BWP: This feature only allows code running in System Management Mode to
  write to the BIOS flash. This code is responsible for EFI variables, which
  are stored in the BIOS flash. Whenever the OS attempts to enable writes to the
  SPI flash, an SMI is fired and a handler, installed by the firmware, checks if
  the write attempt was made in SMM. If it wasn't, then the SMI handler disables
  writes to BIOS flash and returns control to OS.

- UEFI Secure Boot: This feature verifies the OS's bootloader using a
  cryptographic signature. The Linux kernel enables Lockdown mode when SB is
  enabled, which among other things disables direct access to /dev/mem, which
  prevents access to the SPI flash controller.

![img](/img/whack-a-mole.jpg)

_Pictured: An accurate summary of SMM_BWP_

All these features prevent a malicious actor from installing malicious firmware,
but it also prevents the user from updating firmware. Up until this point, we
have been recommending that users enable these locks for daily usage, but disable
them whenever they want to update firmware. Recognizing that this can be an
inconvenient, error prone process, we've added a new feature to make it easier:
Firmware Update Mode.

## Firmware Update Mode

Firmware Update Mode is an one-time boot mode that disables firmware protections
for the duration of one boot, allowing the user to boot into a firmware update
environment (Dasharo Tools Suite or OS of their own choice), update to the
latest version and reboot, which automatically exits Firmware Update Mode. Here
is a demo of the new FW update flow on NovaCustom laptops:

{{< youtube vHwYjoBo_XU >}}

## What's next?

The "proper" way to do firmware updates in the UEFI world is to use UEFI Capsule
Updates. In fact, it's one of Microsoft's requirements for PC vendors to be able
to put Windows stickers and labels on their products.

UEFI Capsule Updates work by putting the firmware updates and relevant metadata
into a single "capsule", which is passed to the UEFI firmware. UEFI then
verifies capsule's digital signature and determines how to update the device.
A capsule update may contain UEFI, FW for Embedded Controller, or for any other
on-board peripherals.

Capsule Updates are also supported under Linux by the fwupd / LVFS project, as
well as various BSD derivatives, support for which we helped develop in the
past few years. TODO link to relevant blogposts

We aim to add support for UEFI Capsule Updates in upcoming releases of Dasharo.
Firmware Update Mode provides some of the building blocks that will be useful
for that purpose. You can expect that we will continue working on making the
update process easier and more reliable in the future.

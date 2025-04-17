---
title: NovaCustom v1.7.2 / v1.5.2 release # TODO
abstract: 'A new firmware release for NovaCustom laptops is out! We put a lot
           of focus on stability and reliability in this release, and this post
           is about the challenges we faced here.'
cover: /covers/qubes-openqa.png # TODO
author: michal.kopec
layout: post
published: false
date: 2024-01-04
archives: "2024"

tags:
categories:

---

A couple of months ago we published firmware v1.5.1 for Tiger Lake and v1.7.1
for Alder Lake based NovaCustom laptops. Unfortunately, this release introduced
a number of issues that slipped past our validation and failed to correctly
address the existing problems.

We have just published the v1.7.2 and v1.5.2 "hotfix" releases, that focus
exclusively on fixing problems and polishing existing features. This release
also led to some changes in the testing and release process, to ensure that
these problems don't happen again in the future.

Let's go through the biggest problems and learn how they were fixed, and
hopefully learn how to avoid them in the future:

## USB-C issues

USB Type-C or USB-C for short is a powerful, versatile connector. As a user I
appreciate that I can travel with a single charger and cable and will be able
to charge almost every device I have, or plug my work laptop, personal laptop,
phone or gaming console into the same docking station and have everything work.

That versatility does, however, depend on every piece being compliant to the
USB-C specification and behaving as expected when connected to an arbitrary
accessory. For example, a laptop has to limit the current it draws from the
charger based on how much the charger says it can provide. And that alone can
be pretty difficult to get right...

## USB Power Delivery

NovaCustom laptops' USB-C power architecture consists of the physical USB-C
port, a USB Power Delivery controller that communicates with USB-PD accessories,
a battery charger in Hybrid Power Boost architecture, the Embedded Controller,
and voltage regulators that convert input voltage to whatever voltages the
platform may need. This is a rather standard architecture, and the EC is
responsible for orchestrating the various components to work together.

When you plug in a USB-C charger, a lot of things happen - in short:

- PD controller detects that a device was plugged in
- The PD power supply advertises the various voltages it supports
- PD controller requests the needed voltage (20V) and allows voltage from
  the USB-C connector to flow into the system
- Battery charger sees that power is supplied and:
    - Switches the input power from the battery to the power supply
    - Begins charging the battery

There is, however, a problem: USB-C power supplies can support various voltages
and current ratings. Whatever power the charger gives us, we must make sure not
to exceed.

## Volts, amps, watts

The voltage portion is rather simple in this case: as the laptops have buck
converters (as opposed to buck-boost) and the system input power is 19V, the
voltage must be 20V, which is the highest USB-PD voltage available (USB-PD EPR
is not supported). Therefore the PD controller is programmed to always request
20V and will not open the input gate for lower voltages.

The current (amperage) part of the equation is a whole different matter. The
laptops are capable of pulling in excess of 80W, so any weaker power brick will
shut down or reset due to overcurrent protection. The same thing will happen
to docking stations, and in this case the dock also disables video and data,
causing a bad experience for the user.

Clearly, we need a way to limit power draw. The way we went with is Psys power
limits, which is a feature supported by the hardware. Psys is the power draw
reported by the battery charger to the CPU voltage regulators, which then use
that information to throttle power draw appropriately. Psys power limits can
be programmed by the Embedded Controller based on available input power.

Now, when you plug in a USB-PD power supply, the EC will read out the negotiated
power contract and program the appropriate power limits in the CPU. That is
the biggest part of the equation that prevents unwanted dock and charger resets.

But what happens when throttling the CPU alone is not enough? There are some
cases where we can still exceed that power limit:

- When powering on - the CPU boots at maximum frequency, and has not yet been
  programmed with the right power limits
- Other platform components are drawing power - charging fully discharged
  battery, using the discrete GPU, plugging in a power-hungry accessory...

Clearly we need something more to solve these issues.

## Hybrid Power Boost

There are several battery charger architectures, the most common are Hybrid
Power Boost and Narrow Voltage DC. NovaCustom laptops come with HPB charger
units. They all share the following features:

- Buck conversion: They can convert input power down from >19V
- Power Boost mode: If the power draw is more than the limit programmed by the
  EC, we

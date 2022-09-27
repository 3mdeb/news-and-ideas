---
title: Qubes OS summit 2022 - Summary
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: norbert.kaminski
layout: post
published: true
date: 2022-09-21
archives: "2022"

tags:
  - Qubes
  - Conference
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

## Long story short

Three weeks ago 3mdeb with Qubes OS team had organized next edition of the
Qubes OS summit. The last years [2020](https://blog.3mdeb.com/2020/2020-06-17-qubes_summation/)
and [2021](#) editions were hosted
remotely and this year event was a face-to-face event hosted in Berlin, which
took place from the 9th to the 11th of September. It has been another productive
event, during which we have exchanged loads of knowledge and expertise.

## Day 1

The first day started with
[Welcome to Qubes OS summit 2022](https://youtu.be/hkWWz3xGqS8?t=882)
presentation held by Piotr Król. Let's say hi to each other and talk about:

Qubes Summit history
What changed since the last event
Event schedule and organization announcements
Shout out to sponsors

[Qubes OS development status update](https://youtu.be/hkWWz3xGqS8?t=2365)
held by Marek Marczykowski-Górecki.

This talk is a summary of projects Qubes team currently works on, and a rough
roadmap for Qubes OS 4.2.

[Building secure applications with Qubes OS](https://youtu.be/hkWWz3xGqS8?t=4719)
held by Michael Z.

SecureDrop Workstation is a new and improved front-end for journalists using
SecureDrop. It was built on top of Qubes OS and relies heavily on its features
and security properties. In this talk, we'll introduce the system and discuss
some lessons learned by treating Qubes OS as a framework for secure
multi-VM applications.

[Next generation of Qubes OS builder](https://youtu.be/hkWWz3xGqS8?t=7994)
held by Frédéric Pierret.

In this talk, we will present the second generation of the Qubes OS builder.
This new builder leverages container or disposable qube isolation to perform every
stage of the build and release process. From fetching sources to building them,
everything is executed inside a "cage" (either a disposable or a container) with the
help of what we call an "executor." For every command that needs to perform an action
on sources, like cloning and verifying Git repos, rendering a SPEC file, generating
SRPM or Debian source packages, a new cage is used. The global architecture will
be presented and demonstrations on how to use this new build system will be made.

[Tailoring Qubes for Enterprises](https://youtu.be/hkWWz3xGqS8?t=10228) held by
Jan Suhr.

Enterprises are usually a domain of Windows-only systems and users. We will
present how Qubes could be tailored to meet requirements of enterprises which
rely on Windows but at the same time provide a "reasonable secure system" based
on Qubes. A key requirement is to achieve a system which is usable for users
with ordinary Windows experience. Therefore key is the integration of a Windows
VM within Qubes OS.


After break

[Qubes OS Policy: Adventures in UX/UI Design](https://youtu.be/hkWWz3xGqS8?t=15275)
held by Marta Marczykowska-Górecka.

A brief overview of the current state of Qubes OS policy tools, the
in-development graphical policy editor / configuration editor, the process
of simplifying the complexities of policy configuration and design and
implementation challenges.

As a continuation of last year's redesign of Application Menu, I have been
working on making Qubes more accessible for non-expert users and on creating
GUI tools for system configuration that would be friendlier and easier-to-use
than existing tools. This time, I took on the challenge of creating a graphical
editor for various policy files. This talk will cover the results of user
research, the challenges encountered during design and implementation, and
show off the tools created as a result of this research.

[GPU Virtual Machine (GVM)](https://youtu.be/hkWWz3xGqS8?t=17671) held by
Arthur Rasmusson.

GVM is a GPU Virtual Machine built by the OpenMdev Project for IOMMU-capable
computers such as x86 and ARM.

In this talk OpenMdev developers Arthur Rasmusson and Michael Buchel plan to
give an overview of GPU Virtual Machine (GVM) and how it works to allow virtual
machine guests to run unmodified GPU drivers (non-paravirtual) on ordinary GPUs
such as those in laptops, desktops, embedded devices, and servers. We’d also
like to take some time to talk about ongoing efforts to improve support for
devices and areas of collaboration where we might best provide support to
QubesOS for integrating OpenMdev tools like GVM for enhanced GPU virtualization.

[Isolating GUIs with the power of Wayland](https://youtu.be/hkWWz3xGqS8?t=19969)
held by Puck Meerburg

Could Qubes OS replace its custom GUI isolation protocol with Wayland while
staying as performant and secure? With the advent of Wayland, many strides
have been made in the desktop Linux space, limiting the effects a malicious
application can have. Gone are the days of every application being able to
snoop every keypress! This presentation will dive into the differences
between X and Wayland, and why it makes for a great fit in isolating
operating systems like Qubes OS and Spectrum.

[PipeWire and Qubes Video Companion](https://youtu.be/hkWWz3xGqS8?t=22258)
held by Demi Marie Obenour.

Qubes OS currently has poor support for audio and video capture. Audio capture
works if used properly, but is easy to misuse and its latency is excessive.
Video capture is not supported except via device pass-through, which raises
serious security concerns. This talk is about replacing the legacy
PulseAudio-based solution with a modern PipeWire-based one, and replacing
camera pass-through with Qubes Video Companion.

[Design session: graphical subsystem (GPU, Wayland)](https://youtu.be/hkWWz3xGqS8?t=24465)
held by Marek Marczykowski-Górecki.

## Day 2

[Welcome to Qubes OS Summit 2022 - Day 2](https://youtu.be/A9GrlQsQc7Q?t=418)
held by Piotr Król.

Day two started with short introduction that sum up first day and showed the
agenda for the second day

[How Dasharo coreboot based firmware helps NovaCustom's customers](https://youtu.be/A9GrlQsQc7Q?t=1578)
held by Wessel klein Snakenborg.

NovaCustom has previously experienced a number of problems related to the
proprietary firmware of the laptop. In this talk, we will present three cases
in which Dasharo open source coreboot based firmware has played an important
role.

The first case is about the desire for a modified fan curve.
The second case study concerns an application where the customer asked whether
it is possible to disable certain CPU options, which turned out to be necessary
for audio production.
The third case is about the implementation of an own startup logo in the
firmware.

In addition, there will be an explanation of the security aspects of the
Dasharo firmware that NovaCustom has recently started using. Thanks to the
growing active Dasharo community, the firmware can be increasingly optimised
to the needs of our users.

Although Qubes OS already has a number of certified laptop models, their
hardware is often quite old. The need for newer hardware that is fully
compatible with Qubes OS is there, and this is where NovaCustom could play
a role with certified hardware and firmware that is fully adapted with
the Qubes OS operating system.

[Qubes User Support Stories](https://youtu.be/A9GrlQsQc7Q?t=3148)
held by nestire.

Qubes is the most common operation system we preinstall on our products.
Based on that, we have a lot of support questions. We want to share our
experience with that.

What are the most common problems?
Where lying the biggest security traps for users?
What needs to be done to enable user who really should use Qubes.

[Qubes OS Documentation Localization](https://youtu.be/A9GrlQsQc7Q?t=5741)
held by Tobias Killer.

The topic of this talk is the localization of the official Qubes OS documentation
and will cover the steps already taken, the current status and the future tasks.

We will take a look at the tech stack and the tools used to build the proposed
localization workflow and will wrap up with outlook, next steps and call for
participation.

The ultimate goal of the endeavour is continuous localization and thus
delivering quality translations quickly and reliably.

[Qubes OS on modern Alder Lake desktop](https://youtu.be/A9GrlQsQc7Q?t=8152)
held by Michał Żygowski.

There are very few desktop platforms that are user-controllable through
open-source firmware. Moreover, they haven't necessarily been tested with Qubes
OS. However, the recent initiative to port a modern Alder Lake desktop to coreboot
opened a new door for privacy and security respecting machine capable of running
Qubes OS.

In this presentation, a demo of Dasharo[1] distribution compatible with Alder
Lake-S desktop MSI PRO Z690-A WIFI DDR4 running Qubes OS will be shown. The
presenter will also describe new updates to Dasharo firmware and challenges
awaiting in future development. Also it will be discussed how Dasharo plans to
meet the future Qubes certification requirements[2] and approaches the openness
of the firmware based on Dasharo Openness Score of various supported platforms.

[Qubes OS: Towards Being a Reasonably Learnable System](https://youtu.be/A9GrlQsQc7Q?t=14609)
held by Deeplow

Following up on last year's presentation, deeplow presents the final work for
his contribution proposal for an integrated onboarding tutorial for Qubes OS.

[TrenchBoot - the only AEM-way to boot Qubes OS](https://youtu.be/A9GrlQsQc7Q?t=17441)
held by Michał Żygowski

The presentation will describe the project plan of improving and extending the
Qubes OS AEM with TrenchBoot[5] covering both Intel and AMD hardware, TPM 1.2
and 2.0. The goal is to unify the D-RTM early launch and Anti Evil Maid
software to secure the Qubes OS boot process for basically any hardware device
(as long as it supports the required technologies). The presenter will give
detailed overview of project phases and tasks to be fulfilled as well as the
cost outline. At the end a short demo of Qubes OS AEM with TrenchBoot on Dell
OptiPlex 7010/9010 with Intel TXT and TPM1.2 will be shown.

[Secure hardware for a secure operating system](https://youtu.be/A9GrlQsQc7Q?t=19620)
held by Brent Cowing

In this session we are going to discuss why you should care about open source
firmware and the ways we can reduce the risk of firmware persistent malware.
As the world is evermore consumed by detecting and preventing ransomware and
other financially damaging attacks on systems and organizations, far too little
attention has been paid to an attack surface common to every single
vulnerability - firmware. It’s time for firmware to be open source and secure.

[Design session: hardware requirements, firmware security](https://youtu.be/A9GrlQsQc7Q?t=21769)
held by Marek Marczykowski-Górecki.


[Dasharo vs vendor firmware performance on QubesOS - a comparison](https://youtu.be/A9GrlQsQc7Q?t=25694)
held by Michał Kopeć.

The presentation will compare performance between Dasharo and Vendor BIOSes
on Dasharo-supported platforms, in the context of QubesOS usage. I will attempt
to present the most significant differences that an end user user will see when
installing Dasharo over the original proprietary firmware.

In this presentation I will present actual difference in performance as measured
by a set of benchmarks, talk about what causes them and what challenges there
are to bring performance to a state that is competitive with the vendor BIOS.
We'll also discuss how these differences may impact QubesOS users.


## Hackaton

The last day was the time to talk and code projects connected to the previous
days.

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

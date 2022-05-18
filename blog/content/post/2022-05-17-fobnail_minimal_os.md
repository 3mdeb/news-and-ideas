---
title: Minimal OS for Fobnail
abstract: 'The Fobnail Token is an open-source hardware USB device that helps to
           determine the integrity of the system. The purpose of this blog post
           is to present the development progress of this project. During this
           phase, we focused on researching OS for hosting Fobnail Attester'
cover: /covers/usb_token.png
author: artur.kowalski
layout: post
published: true
date: 2022-05-17
archives: "2022"

tags:
  - fobnail
  - tpm
  - attestation
  - security
  - linux
  - yocto
  - xen
  - zephyr
categories:
  - Security

---

## About the Fobnail Token project

Fobnail is a project that aims to provide a reference architecture for building
offline integrity measurement verifiers on the USB device (Fobnail Token) and
attesters running in Dynamically Launched Measured Environments (DLME). It
allows the Fobnail owner to verify the trustworthiness of the running system
before performing any sensitive operation. This project was founded by [NlNet
Foundation](https://nlnet.nl/). More information about the project can be found
in the [Fobnail documentation](https://fobnail.3mdeb.com/). Also, make sure to
read other posts related to this project by visiting
[fobnail](https://blog.3mdeb.com/tags/fobnail/) tag.

## Scope of current phase

This phase is about researching an OS that will run in DLME. OS must also be
capable of running Fobnail Attester, communicating with Fobnail Token,
performing attestation, and booting the target OS after successful attestation.
Also, during this phase, we got selected OS running in DLME. We will bring the
functionality required to communicate with Fobnail and attest platform state
during the next phase.

## OS researching

We have conducted research to find out which OS/kernel suits our needs the most.
We need USB drivers, including USB EEM (Ethernet over USB) driver and network
stack. The base choice is Linux which already has all required drivers. However,
we researched the usage of microkernels due to increased security. If minimal OS
got compromised (through its USB or network stack), an attacker could trick
Fobnail into that platform is in a trustworthy state, revealing Fobnail's kept
secrets like cryptographic keys.

We evaluated the feasibility of using microkernel-based OSes (the research
report is available here, TBD: link). Many microkernel-based OSes lack the
required drivers, ability to boot another OS, and ability to run as DLME
payload. Also, since they are designed for an embedded environment, they are not
portable (across platforms with the same CPU architecture), which is a serious
limitation that would force us to ship many versions of OS for each platform.

## Why Linux?

We have decided to use Linux for building minimal OS because it already has
everything we need, and other OSes would require a significant amount of work.
In the future, we may use another OS.

## Running minimal OS on APU

TBD

## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

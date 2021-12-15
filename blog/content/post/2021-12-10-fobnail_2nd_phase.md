---
title: Fobnail Token - developing communication method that meets the CHARRA requirements
abstract: 'The Fobnail Token is an open-source hardware USB device that helps to
           determine the integrity of the system. The purpose of this blog post
           is to present the development progress of this project. During the
           last phase, we managed to implement the communication method that
           will be used between verifier and attester.'
cover: /covers/image-file.png
author: tomasz.zyjewski
layout: post
published: true
date: 2021-12-10
archives: "2021"

tags:
  - fobnail
  - firmware
  - usb
  - CHARRA
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
in the [Fobnail documentation](https://fobnail.3mdeb.com/).

# Communication in CHARRA

[CHARRA](https://github.com/Fraunhofer-SIT/charra) is a "Challenge/Response
Remote Attestation" interaction model of the IETF RATS Reference Interaction
Models for Remote Attestation Procedures using TPM 2.0. In this project, the
attester and verifier communicate with themselves using libcoap. In order to
achieve that we need to implement Ethernet over USB on the Fobnail Token. We
decided to use Rust so [nrf-hal](https://github.com/nrf-rs/nrf-hal) project
provides us with a USB driver, and the conducted
[research](https://fobnail.3mdeb.com/eth-over-usb-research/)
allowed us to determine that EEM will be the most appropriate protocol
implementing Ethernet over USB. Additionally, we use
[smoltcp](https://github.com/smoltcp-rs/smoltcp) which is an interesting project
that provides an implementation of TCP/IP stack.

# The Fobnail SDK

We started our work on Fobnail SDK. This is a Docker container containing all
tools essential for building and flashing Fobnail firmware. You can build the
SDK in a few minutes.

[![asciicast](https://asciinema.org/a/MeSZmWaIPXsfpV3hR5cvS9RaG.svg)](https://asciinema.org/a/MeSZmWaIPXsfpV3hR5cvS9RaG?speed=1.5)

# Building applications for Fobnail

With Fobnail SDK ready we moved on to running the `hello-world` example using
Rust nrf-hal. It turns out that the repository is missing an example for the
nRF52840 which we use as a Fobnail prototype. We have to port the `blinky-demo`
and the needed code can be found on
[Fobnail's](https://github.com/fobnail/nrf-hal/tree/blinky-demo-nrf52840/examples/blinky-demo-nrf52840)
fork of nrf-hal project. The full process is described in the
[documentation](https://fobnail.3mdeb.com/flashing_samples/).

The next step was to implement EEM protocol and integrate it with smoltcp. The
code can be found
[here](https://github.com/fobnail/usbd-ethernet/tree/main/src). Like in the
`hello-world` example, here we also use [dockerized Fobnail
SDK](https://github.com/fobnail/fobnail-sdk) which allows building Rust
applications. During the development, we encountered some
[problems](https://fobnail.3mdeb.com/implementing-eth-over-usb/#encountered-problems)
and the [status of the current
implementation](https://fobnail.3mdeb.com/implementing-eth-over-usb/#status-of-current-implementation)
can be found in Fobnail documentation.

The last step was to prepare a Fobnail firmware example, which for now is an
application that allows to read Ethernet frames and send them back unchanged
using the USB over Ethernet driver. Code is available
[here](https://github.com/fobnail/fobnail/blob/main/src/main.rs). Repo contains
`build.sh` that builds firmware for the selected platform. Building is simple
and it requires only a single command (once the repo is cloned).

[![asciicast](https://asciinema.org/a/iCNHrba1D3N5a2LNbhltDunF3.svg)](https://asciinema.org/a/iCNHrba1D3N5a2LNbhltDunF3?speed=1.25)

# Running Fobnail firmware

Running the Fobnail demo on the [nRF52840
dongle](https://www.nordicsemi.com/Products/Development-hardware/nrf52840-dongle)
is really straightforward if only the
[environment](https://fobnail.3mdeb.com/environment/) was correctly prepared.
[Tests](https://fobnail.3mdeb.com/implementing-eth-over-usb/#testing) results
have been made publicly available. Firmware running is also handled by
`build.sh` which automatically builds firmware (if needed), flashes it to target
device and spawns RTT console (used for debugging). The example presented below
was executed with the dongle attached to PC USB port.

[![asciicast](https://asciinema.org/a/JTVLHLSGazKQgGzcpTolXBOOy.svg)](https://asciinema.org/a/JTVLHLSGazKQgGzcpTolXBOOy?speed=1.25)

The Fobnail firmware can also run directly on PC (see [Developing firmware on
PC](https://fobnail.3mdeb.com/local_development/)), thanks to that it is
possible to develop firmware without any additional hardware.

## Summary

As part of the described phase, we were able to implement Ethernet over USB and
properly run it on [nRF52840
dongle](https://www.nordicsemi.com/Products/Development-hardware/nrf52840-dongle).
It is also worth paying attention to the provided code that allows you to use
this implementation in isolation from the hardware layer - without using the USB
standard. This will allow you to work on CHARRA functionality in the future
without the need for hardware. Future development of this project will be
presented in subsequent blog posts.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

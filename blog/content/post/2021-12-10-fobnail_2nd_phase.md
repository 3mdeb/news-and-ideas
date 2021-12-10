---
title: Fobnail Token - developing communication method that meets the CHARRA requirements
abstract: 'The Fobnail Token is an open-source hardware USB device that help to
           determine the integrity of the system. The purpose of this blog post
           is to present the progress of this project development. During the
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

[CHARRA](https://github.com/Fraunhofer-SIT/charra) - "Challenge/Response Remote
Attestation" interaction model of the IETF RATS Reference Interaction Models for
Remote Attestation Procedures using TPM 2.0. In this project the attester and
verifier communnicate with themselfes using libcoap. In order to achieve that we
need to implement Ethernet over USB on the Fobnail Token. We decided to use Rust
so [nrf-hal](https://github.com/nrf-rs/nrf-hal) project provide us with USB
driver, and the conducted
[research](https://github.com/fobnail/docs/blob/main/dev-notes/eth-over-usb-research.md#ethernet-over-usb-research)
allowed us to determine that EEM will be the most appropriate protocol
implementing Ethernet over USB. Additionaly we use
[smoltcp](https://github.com/smoltcp-rs/smoltcp) which is an interesting project
that provides implementation of TCP/IP stack.

# Building custom Ethernet over USB implementation

We start our work on running the `hello-world` example using Rust nrf-hal. It
turns out that the repository is missing example for the nrf52840 which we use
as a Fobnail prototype. The needed code can be found on
[Fobnail's](https://github.com/fobnail/nrf-hal/tree/blinky-demo-nrf52840/examples/blinky-demo-nrf52840)
fork of nrf-hal project. The full process is described in the
[documentation](https://fobnail.3mdeb.com/flashing_samples/).

The next step was to implement EEM protocol and use it with smoltcp. Code for
that can be found [here](https://github.com/fobnail/usbd-ethernet).

TBD

## Summary

As part of the described phase, we were able to implement Ethernet over USB and
properly run it on [nRF52840
dongle](https://www.nordicsemi.com/Products/Development-hardware/nrf52840-dongle).
It is also worth paying attention to the provided code that allows you to use
this implementation in isolation from the hardware layer - without using the USB
standard. This will allow you to work on CHARRA functionality in the future
without the need for hardware. In the future, this project will be developed,
which will also be presented in subsequent blog posts.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

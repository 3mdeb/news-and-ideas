---
title: Fobnail Token - platform attestation
abstract: 'The Fobnail Token is an open-source hardware USB device that helps to
           determine the integrity of the system. The purpose of this blog post
           is to present the development progress of this project. This phase
           was focused on attestation.'
cover: /covers/usb_token.png
author:
    - artur.kowalski
    - krystian.hebel
layout: post
published: true
date: 2022-04-06
archives: "2022"

tags:
  - fobnail
  - tpm
  - attestation
categories:
  - Firmware
  - Security

---

## About the Fobnail project

Fobnail is a project that aims to provide a reference architecture for building
offline integrity measurement verifiers on the USB device (Fobnail Token) and
attesters running in Dynamically Launched Measured Environments (DLME). It
allows the Fobnail owner to verify the trustworthiness of the running system
before performing any sensitive operation. This project was founded by
[NlNet Foundation](https://nlnet.nl/). More information about the project can be
found in the [Fobnail documentation](https://fobnail.3mdeb.com/). Also, make
sure to read other posts related to this project by visiting
[fobnail](https://blog.3mdeb.com/tags/fobnail/) tag.

## Scope of current phase

This phase was mostly about implementing attestation. It includes splitting the
current implementation of Fobnail (aka Verifier) code into separate modules. A
module for previous phase (platform provisioning) is started only if Fobnail
doesn't have platform-specific artifacts saved in flash. A module for
attestation is always started, either as first stage or immediately after
provisioning, to test if provisioning succeeded.

We also fixed some hardware issues that forced us to not use nRF52. nRF52 still
can't be fully used due to inability to provision Fobnail Token itself, but this
moves us closer to the final, remote (i.e., not running on the platform being
verified) implementation of Fobnail.

For definitions of roles and artifacts mentioned throughout the post, see
[Remote Attestation Procedures Architecture](https://datatracker.ietf.org/doc/draft-ietf-rats-architecture/)
and
[our documentation](https://fobnail.3mdeb.com/architecture/#fobnail-components)
that maps those to Fobnail components.

## Attestation

Attestation is a process during which Verifier (Fobnail Token) asks Attester
(host platform) for Evidence (in our case this is signed TPM quote), and based
on it creates Attestation Results. This process is additionally controlled by
Appraisal Policy and Reference Values. In general, Attestation Results may have
complex format that is later appraised by another party, but in case of Fobnail
this is binary _good_/_bad_ output.

![Diagram of Fobnail attestation flow](/img/Fobnail-flows-attestation.png)

### Implementation

Reference Values in form of RIM were created and passed to Fobnail Token in
[previous phase](https://blog.3mdeb.com/2022/2022-03-21-fobnail_3rd_phase/).
A per-platform Appraisal Policy is expected to be installed during remote
platform provisioning. In case of local provisioning, a default policy is used.

Default policy for Fobnail includes comparison of hashes of PCRs 0-7 and 17-18,
for SHA256 bank. It is checked by using `TPM2_Quote()` command, for which
Fobnail Token sends, in addition to PCR selection, a nonce that is included in a
signed response. This protects against replay attacks, and in combination with
TPM mechanism against signing external data starting with magic number also
proves that Claims (values read from TPM) and Evidence (values sent to Verifier)
are fresh.

Reasoning for choosing this particular set of PCRs is that PCR0-7 are used by
pre-OS environment, and PCR17-18 are used in DRTM flow. Other registers are used
by OS and may change after software is updated, which would require frequent
re-provisioning of the platform. SHA256 is the only algorithm commonly used –
SHA1 is deprecated and SHA384, while mandatory according to the latest TPM
specification, is not implemented by majority of available TPMs.

In addition to configurable part of policy described above, there are also
implicit assumptions:

- Metadata is always checked – hash of metadata is used to generate filenames
  for data stored in Fobnail Token.
- AIK (and because of its relation, also EK) doesn't change – it is saved during
  platform provisioning and never again sent by the Attester. During
  attestation, Fobnail Token checks signatures of received data against this
  saved copy.

## Building

[Previous build instructions](https://blog.3mdeb.com/2022/2022-03-21-fobnail_3rd_phase/#building)
still apply. These are commits that were used at the time of writing this post:

- SDK: `53f19086c993 2022-03-08|Fix build problems on nRF target`
- Attester: `0b7085ff80a3 2022-04-06|docker.sh: display tmux pane names`
- Fobnail: `be92a104c3b1 2022-04-06|Fix misleading error message`

## Demo

[![asciicast](https://asciinema.org/a/VgEAAH0V0YzXKWZJ7vT9ze9my.svg)](https://asciinema.org/a/VgEAAH0V0YzXKWZJ7vT9ze9my?speed=1)

## Running Fobnail on real hardware

During early development, we used
[nRF52840 Dongle](https://www.nordicsemi.com/Products/Development-hardware/nrf52840-dongle)
as a device for running Fobnail firmware (tested both on
`PCA10059 1.2.0 2019.28` and `PCA10059 1.2.0 2019.32`). However, due to problems
with USB, we started running Fobnail as a Linux application during the previous
phase. The time has come to fix this.

### Fixing USB

Plugging Fobnail Token into a USB socket didn't work all the time correctly –
details in [issue](https://github.com/fobnail/usbd-ethernet/issues/2). We have
searched through git repositories of libraries we use and updated them to their
latest versions, but it didn't help, so we started looking for a point in our
code.

We already knew from `dmesg` and from Wireshark that USB was failing due to
packets not arriving to host. Starting by checking USB interrupt handler, we
very quickly found that interrupts didn't fire right in time after initializing
USB, and delays were up to 85 ms.

This turned out to be the direct cause of USB failure. At first, we tried
profiling USB driver interrupt handler and critical sections, and both were
taking less than 1ms delay. Eventually, we discovered that the problem lies not
in the USB driver but in the NVMC driver, which we use for storing persistent
data in flash memory. When writing to flash, NVMC will stop CPU while writing,
and erasing a single 4K flash page takes exactly 85 ms. This is documented as
`t_ERASEPAGE` in
[nRF52840 specification](https://infocenter.nordicsemi.com/pdf/nRF52840_PS_v1.7.pdf).

Fortunately, nRF52840 has a feature called partial erase, which allows us to
split erase into many iterations. Instead of sleeping once for 85 ms, we can 85
times for 1 ms, allowing a USB interrupt to fire in-between.
[nrf-hal](https://github.com/nrf-rs/nrf-hal) didn't support partial erase, so we
implemented this on our own and opened
[PR](https://github.com/nrf-rs/nrf-hal/pull/385).

Implementing partial erase and a few other smaller fixes (described in
[commit history](https://github.com/fobnail/fobnail/pull/24/commits)) fixed USB.

### Fixing LittleFS

We have a problem with LittleFS
[corrupting](https://github.com/fobnail/fobnail/issues/12) itself, usually
during certificate installation. So far, we haven't discovered the exact cause
of the issue, and we are still working on this. It looks like there is an error
located in Rust bindings to LittleFS since it doesn't occur with equivalent
written in C. The problem is described more in-depth
[here](https://github.com/trussed-dev/littlefs2/issues/16).

### Signaling provisioning and attestation result

We implemented LED driver, now Fobnail will signal attestation (and
provisioning) result using either red or green LED. Provisioning status is
signaled by 3 quick blinks, and attestation status is signaled by flashing LED
for 10 seconds.

![Fobnail flashing red LED](/img/fobnail_red_led.jpg)

Right now Fobnail blinks with red LED, because we don't have support for
installing certificates into flash (we support this but only for emulated flash
on PC). We will implement this during the next phase. Until then, you can
comment out
[code](https://github.com/fobnail/fobnail/blob/86e3f22edba3e07f2eb54156e16a660d8c7254f6/src/certmgr/verify.rs#L45)
responsible for certificate verification.

### Summary

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to
[sign up to our newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

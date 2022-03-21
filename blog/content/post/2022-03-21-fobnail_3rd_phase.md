---
title: Fobnail Token - platform provisioning
abstract: 'The Fobnail Token is an open-source hardware USB device that helps to
           determine the integrity of the system. The purpose of this blog post
           is to present the development progress of this project. This phase
           was focused on platform provisioning.'
cover: /covers/usb_token.png
author: krystian.hebel
layout: post
published: true
date: 2022-03-21
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

# Keys used in communication between Fobnail Token and attester

In current phase two key pairs are used during communication, those are AIK and
EK. Both belong to TPM installed on attester and their private parts should
never leave TPM.

> There is one exception where a private part leaves TPM, that is as an output
of `TPM2_Create` command. It is used in `TPM2_Load` and immediately purged from
RAM. This path is taken only if AIK isn't already in persistent TPM memory.
Newer versions of TPM specification added mandatory `TPM2_CreateLoaded` command
to skip exposing private key to host, but this isn't supported by all TPMs so we
went with separate commands.

### AIK

Attester Identification Key is used to sign data originating from attester. It
is created by TPM under Endorsement Hierarchy from random data, meaning it will
be different with each creation. To keep it always the same we are making it
persistent by saving it in NVRAM under index `0x8100F0BA` (`81` is constant
telling this is persistent handle, `F0B` - short for Fobnail, `A` - AIK).

After key is made persistent, there is no way of reading its private part. It
can still be used for signing (and decryption, if key type allows it), but only
if this operation is carried out by TPM.

### EK

Endorsement Key is also created by TPM, but instead of using random data as an
input, it uses EPS (Endorsement Primary Seed) that is burnt into TPM during
manufacturing. Because manufacturer knows this seed, it can also create EK
certificate. Unless EPS is changed, EK will always be the same, but because its
creation takes significant amount of time it is also made persistent under
handle `0x8100F0BE`.

In most cases RSA EK certificate can be read from TPM NVRAM (index `0x01C00002`)
but sometimes it is absent (fTPM, simulated TPM). Because this certificate is
used by Fobnail Token for verification against trusted CA certificate chains,
we've created [a script for "manufacturing" it](https://github.com/fobnail/fobnail-attester/blob/main/tools/tpm_manufacture.sh)
whenever it is absent.

The only use of EK right now is proving that AIK comes from the same TPM.

# Tying AIK with EK

TPM has to have access to EK in order to load and use AIK, but this doesn't
imply that external party can test that AIK lives indeed inside TPM, or if it
was created outside TPM by man in the middle. EK is not a signing key, so it
can't sign AIK and prove its validity that way. `TPM2_ActivateCredential()` call
was made to prove association of loaded object (like a key pair) to a credential
(like Storage Key, e.g. EK).

To prove that AIK comes from the same as EK, Fobnail first obtains and verifies
EK certificate and asks for public AIK in TSS format. Based on this data it
creates encrypted blob of randomly created secret, which can be only decrypted
on TPM that has both EK and AIK currently loaded, and AIK is under the same
hierarchy as EK. By returning correct secret to Fobnail, attester proves this is
the case.

Because `TPM2_ActivateCredential()` just proves that _an object_ is associated
with a credential, Verifier has to check whether AIK is indeed a key with
appropriate properties, like ability to sign and protection policy.

# Metadata and RIM

Metadata is just a set of identifiers used to differentiate between platforms.
Currently it consists of platform's MAC address, manufacturer, product name and
serial number. It also includes version number specifying format of metadata
blob, which enables us to modify it when such a need arises.

Reference Integrity Manifest (RIM) is supposed to be created, signed and
provided by OEM, OS and/or software vendors, depending on which PCRs are touched
by those entities. Their format is described in multiple specifications. Some of
them are contradictory, others demand things that are physically impossible
(measurements must include all implemented banks for at least 8 PCRs, but have
to be returned in TPML_DIGEST which can hold max 8 digests). We also decided to
skip event log for the time being for the sake of easier testing in CI and
because of buggy firmware on host running attester...

For easier parsing on Fobnail side we put PCR values in CBOR format. We also
skipped metadata from RIM since we already sent it separately. By doing these
changes we basically created another standard:

[![Standards](https://imgs.xkcd.com/comics/standards.png)](https://xkcd.com/927/)

# Building

Build system was updated for easier and faster development. It now includes
packages required to build TPM simulator. This opens up a possibility of
CI-testing full solution, instead of just build tests for each component
separately.

### Cloning

```bash
$ git clone https://github.com/fobnail/fobnail-sdk.git
$ git clone https://github.com/fobnail/fobnail-attester.git --recurse-submodules
$ git clone https://github.com/fobnail/fobnail.git --recurse-submodules
```

Components should always work with each other when all repositories are cloned
at the same time, but for extra safety, these are commits used at the time of
writing this blog post:

* SDK: `53f19086c993 2022-03-08|Fix build problems on nRF target`
* Attester: `85e8ab442e9f 2022-03-17|docker.sh: review fixes;
  docker/entrypoint.sh: fix permissions issue`
* Fobnail: `9a8a404f9e5f 2022-03-16|tools/lfs/src/main.rs: add option to format
  flash before doing command`

### Building and installing SDK

Fobnail SDK is used to build code for Fobnail token, i.e. Verifier part of
attestation process. It is [published on GHCR](https://github.com/fobnail/fobnail-sdk/pkgs/container/fobnail-sdk)
and latest version of it is automatically pulled when needed, user needs only
the `run-fobnail-sdk.sh` script installed in PATH.

```bash
$ cd fobnail-sdk
# Feel free to use different directory or name, as long as it is in $PATH
$ ln -s $(readlink -f ./run-fobnail-sdk.sh) ~/bin/run-fobnail-sdk.sh
```

### Building and running full solution

Attester requires access to SMBIOS tables to read metadata (platform serial
number, manufacturer etc.) so as of now it has to be started with different set
of permissions. For this reason, another Docker container is used for building
and running Attester. This container also manages building every component
through a single script to make it as easy to use as possible. You just have to
point it to Verifier's code and everything else is done by that script.

```bash
# Assuming 'fobnail' and 'fobnail-attester' are in the same directory
$ cd fobnail-attester
$ export FOBNAIL_DIR=../fobnail

# Build Attester's Docker image
$ docker build -t fobnail/fobnail-attester .

# Build Attester:
$ ./docker.sh build-attester

# Build Verifier:
$ ./docker.sh build-fobnail

# Build tool for installing EK CA certificate in flash:
$ ./docker.sh build-lfs

# Start TPM simulator, create EK CA certificate, create sign and install EK
# certificate (in TPM NVRAM), install EK CA certificate (Fobnail flash), start
# Attester and Verifier side-by-side in tmux windows:
$ ./docker.sh run-tmux
```

# Demo

[![asciicast](https://asciinema.org/a/OJ1YWyKhexSztmbfNVS79eGbo.svg)](https://asciinema.org/a/OJ1YWyKhexSztmbfNVS79eGbo?speed=1)

As you can see, all PCRs have their initial values, that is either all `0`s or
all `F`s. This is because TPM simulator starts in this state. On real hardware
those will be properly filled:

[![asciicast](https://asciinema.org/a/2eZnIC7HMTeXKQ2hCQgqMoLM6.svg)](https://asciinema.org/a/2eZnIC7HMTeXKQ2hCQgqMoLM6)

## Summary

Even though this application is called Attester, it doesn't do attestation just
yet. At this stage it sends reference PCR values that are saved in Fobnail's
flash for later comparison, along with metadata used to uniquely identify host
platform. Support for attestation is planned for the next phase, so stay tuned.

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

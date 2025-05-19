---
title: Fobnail Token - Fobnail provisioning
abstract: 'This phase is about provisioning Fobnail Token itself. The closing
          point of that process is creating a certificate for Token that can be
          used later after attestation succeeds'
cover: /covers/usb_token.png
author: krystian.hebel
layout: post
published: true
date: 2022-05-25
archives: "2022"

tags:
  - fobnail
  - tpm
  - attestation
categories:
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

This phase is about provisioning Fobnail Token itself. The closing point of that
process is creating a certificate for Token that can be used later after
attestation, only if attestation finishes successfully. Before that happens,
Fobnail Token must verify that Platform Owner can be trusted, and prepare an
input for that certificate.

### Assumptions and flow of Fobnail provisioning

It is assumed that provisioning is performed in a secure environment, over a
secure channel, and encryption of data sent between Platform Owner and Fobnail
Token isn't necessary. After all, Platform Owner is able to issue certificates,
so there are bigger worries than lack of encryption during provisioning if it
gets compromised.

Communication with Platform Owner happens through CoAP. Fobnail Token is a
client, same as during communication with Attester. This is done to keep code
footprint small enough to fit in nRF52840 dongle. As a consequence, all
communication is initiated by the Token, so it is responsible for deciding which
of the three flows (Fobnail provisioning, platform provisioning or attestation)
it should follow.

First resource that Fobnail Token asks for during its provisioning is a Platform
Owner certificate chain. It has a
[strictly defined format](https://fobnail.3mdeb.com/keys_and_certificates/#platform-owner-certificate-chain)
and its root must be provided to the token during compilation. Fobnail validates
this chain, but because it has neither timekeeping nor (secure) networking
capabilities, it isn't able to check validity periods or CRLs.

Second request uses POST method and includes CSR (certificate signing request).
Platform Owner responses to that with a certificate generated from that CSR,
signed by Platform Owner's private key. This certificate is verified against
chain received in previous step and saved in non-volatile memory for later use.

![Diagram of Fobnail provisioning flow](/img/Fobnail-flows-fobnail-provisioning.png)

### Fobnail Token's key

There are no good crates for generating RSA keys on Cortex-M, and in our tests
using universal implementation wasn't able to generate 2048-bit key in 5 hours.
We also couldn't use ARM TrustZone CryptoCell 310 which is included in nRF52840
for this purpose because it doesn't have open-sourced libraries. Thus, currently
Fobnail Token generates Curve25519 key, with help of
[Trussed](https://trussed.dev/).

It was originally designed to be used in Diffie–Hellman method to generate
symmetric encryption key for communication between owners of two separate
Curve25519 keys. Ed25519 is a signature scheme using Curve25519, which adds the
ability to sign and verify data, including certificates. Unfortunately,
Curve25519 can't be used as encryption key pair. This is
[a problem that will have to be resolved](https://github.com/fobnail/fobnail/issues/40)
to unlock full power of Fobnail Token.

### Possible uses of Fobnail certificate

Fobnail architecture doesn't impose use of key for which certificate is being
made. The only restriction that should be followed is that created certificate
is not a CA, because that together with inability to use CRLs creates enormous
security issue.

Usage of key should answer the question: "why do I want to attest the platform"?
There is no universal answer, each use case has its own requirements. Example
usages with corresponding X.509 `keyUsage` bits include, but are not limited to:

- obtaining small data (e.g. nonce, password, salt) from encrypted challenge,
  for this `dataEncipherment` must be set (note: can't be done with Curve25519),
- authentication, in which case `digitalSignature` and `nonRepudiation` is good
  enough,
- handshake in TLS-like communication, which requires `keyAgreement` or
  `keyEncipherment`.

In any case, private key must never leave Fobnail Token. This may limit speed
and maximal size of data that is signed or encrypted, as those tasks must be
performed by the Token. For example, encrypting whole hard disk with Fobnail's
public key directly is a bad idea, but you can use it to encrypt a key used for
decrypting the drive.

Obviously, support on Fobnail side is required to expose API that uses private
key accordingly to the usage specified in the certificate, based on attestation
result. This is not done in this phase.

### Building and running

Since we've changed the way EK certificate chain is obtained, Attester can no
longer be run on simulated TPM as easy as before. Chain is now downloaded during
platform provisioning, but for cases when Internet connection can't be trusted
we plan to add option to
[use certificate chain from file](https://github.com/fobnail/fobnail-attester/issues/37).

Because TPM simulator is not used, Fobnail Token is also started separately.
There is also a new application for Platform Owner, which should be started on a
separate, secure machine, but for testing can also be run on the same system as
the other components.

#### Platform Owner

To build Platform Owner application, just run `make`:

```bash
git clone https://github.com/fobnail/fobnail-platform-owner.git --recurse-submodules
cd fobnail-platform-owner
make
```

It takes certificate chain and private key used for signing Fobnail Token's
certificate on input:

```bash
./bin/fobnail-platform-owner path/to/chain.pem path/to/key.priv
```

Proper key and chain can be generated by following
[these instructions](https://fobnail.3mdeb.com/keys_and_certificates/#creating-platform-owner-certificate-chain-with-openssl).
`chain.pem` is a concatenation of all certificates, starting with root:

```bash
cat root.crt ca1.crt ca2.crt > chain.pem
```

#### Attester

Attester is built similarly to Platform Owner:

```bash
git clone https://github.com/fobnail/fobnail-attester.git --recurse-submodules
cd fobnail-attester
make
```

It must be started as privileged user, in order to access TPM and SMBIOS:

```bash
sudo ./bin/fobnail-attester
```

Currently Attester must have physical NIC because its MAC is used as part of
metadata. This is a known issue that makes it unusable on platforms that don't
have one, such as virtual machines, wireless-only devices or controllers for
which kernel doesn't have a driver.

#### Fobnail Token

[Fobnail SDK](https://blog.3mdeb.com/2022/2022-03-21-fobnail_3rd_phase/#building-and-installing-sdk)
must be installed before building Fobnail Token software. After that,
clone Fobnail's repository:

```bash
git clone https://github.com/fobnail/fobnail.git --recurse-submodules
cd fobnail
```

To build, flash and run on nRF52840:

```bash
env FOBNAIL_PO_ROOT=path/to/PO/root.crt ./build.sh -t nrf --run
```

To build and run on PC:

```bash
env FOBNAIL_PO_ROOT=path/to/PO/root.crt ./build.sh -t pc --run
```

In both cases, `root.crt` must be located somewhere in `fobnail` directory. This
is limitation of Docker.

#### Running the whole shebang

> When physical USB token is used, it must be assigned IP address
> (169.254.0.1/16) after it is plugged in. This can be done automatically by
> adding appropriate configuration to `udev`, `systemd` and/or another daemon
> used for network configuration. Refer to your distro's documentation on how to
> do this or assign IP address manually. This inconvenience will be addressed in
> further releases.

1. Start Platform Owner application

   As mentioned, this should be running on another computer, but for testing it
   can be the same as attested platform (it is not secure in this case). Leave
   the application running until Fobnail provisioning is done.

1. Insert Fobnail Token (or start its simulation) into Platform Owner's machine

   Platform Owner application will print the progress, it should end with dump
   of newly created certificate in PEM format. If hardware Token was used, this
   part reports success with _red_ diode blinking 3 times. Fobnail Token is
   considered provisioned at this point.

1. Start Attester application on target platform

   On first run, it will create AIK and store it in TPM nonvolatile memory for
   later use. Time that is required for this step depends on TPM, but it
   shouldn't take more than a couple of seconds.

1. Remove Token from Platform Owner's machine and insert it into target platform

   Target platform is assumed to be in secure state at this point. Its PCR
   values will be used as reference measurements. In case of simulated Fobnail
   Token, Platform Owner application is stopped instead (Ctrl+C).

1. Wait for platform provisioning and test attestation

   Attester prints messages exchanged during this step with Fobnail Token, along
   with some other information. As part of this process, a certificate chain for
   EK is downloaded. Successful platform provisioning is reported with three
   blinks of green LED. Immediately after that, test attestation takes place,
   for which success is reported with longer, constant green light.

1. At this point platform is provisioned

   Further attestations can be performed by connecting Fobnail Token while
   Attester application is running.

#### Unprovisioning

Fobnail Token can be returned to its original state by:

- Reprogramming nRF52840 by rerunning `build.sh`

- Holding SW1 switch on nRF52840 while it is plugged in for 10 seconds

  Acknowledgment is reported by three short green blinks. Give it a second or
  two after that to actually clear its memory.

In case of PC simulation, remove `target/flash.bin` from `fobnail` directory.

AIK and _copy_ of EK can be cleared from TPM with following set of commands:

```bash
## Enable Owner authorisation
tpm2_changeauth -c o ownerauth
## Remove AIK
tpm2_evictcontrol -C o -c 0x8100F0BA -P ownerauth
## Remove EK (it can always be recreated from seed)
tpm2_evictcontrol -C o -c 0x8100F0BE -P ownerauth
## Disable Owner authorisation
tpm2_changeauth -c o -p ownerauth
```

### Demo

All phases required for provisioning and attestation are already in place, so
following video shows whole process. This includes steps done by administrator
(provisioning) as well as by end user (attestation). Provisioning is done once
for given platform, repeated only if reference measurements change, e.g. after
sanctioned firmware update. Attestation is repeated each time user has to attest
the state of his/her platform.

{{< youtube \_WYtvEg_nLs >}}

For those with keen eye, TSS error and warning is printed during platform
provisioning and attestation. They come from a bug in TSS that was reported
[here](https://github.com/tpm2-software/tpm2-tss/issues/1522) and fixed
[here](https://github.com/tpm2-software/tpm2-tss/pull/1531). Since most
currently used distributions use older packages, it is not available in them
just yet. This can and is
[worked around by the code](https://github.com/fobnail/fobnail-attester/commit/0f15f460a7934375e682763244bbf22670fd5402),
but there is no way of silencing those lines.

## Summary

With whole process tested at once, multiple issues became apparent. Those which
are limited to one of the components are listed in specific repository
([Fobnail Token](https://github.com/fobnail/fobnail/issues),
[Platform Owner](https://github.com/fobnail/fobnail-platform-owner/issues) and
[Attester](https://github.com/fobnail/fobnail-attester/issues)), and if it
applies to whole project, it landed in
[documentation repository](https://github.com/fobnail/docs/issues). There, we
also want to build a list of possible use cases with guides for expected
policies and certificates. If there is something we missed, feel free to add a
new item to those lists.

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to
[sign up to our newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

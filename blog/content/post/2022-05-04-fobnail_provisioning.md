---
title: Fobnail Token - Fobnail provisioning
abstract: 'This phase is about provisioning Fobnail Token itself. The closing
          point of that process is creating a certificate for Token that can be
          used later during attestation'
cover: /covers/usb_token.png
author: krystian.hebel
layout: post
published: true
date: 2022-05-04
archives: "2022"

tags:
  - fobnail
  - tpm
  - attestation
categories:
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
[fobnail](https://blog.3mdeb.com/tags/fobnail/) tag.

# Scope of current phase

This phase is about provisioning Fobnail Token itself. The closing point of that
process is creating a certificate for Token that can be used later during
attestation, only if attestation finishes successfully. Before that happens,
Fobnail Token must verify that Platform Owner can be trusted, and prepare an
input for that certificate.

## Assumptions and flow of Fobnail provisioning

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
Owner certificate chain. It has a [strictly defined format](TBD: link to docs)
and its root must be provided to the token during compilation. Fobnail validates
this chain, but because it has neither timekeeping nor (secure) networking
capabilities, it isn't able to check validity periods or CRLs.

Second request uses POST method and includes CSR (certificate signing request).
Platform Owner responses to that with a certificate generated from that CSR,
signed by Platform Owner's private key. This certificate is verified against
chain received in previous step and saved in non-volatile memory for later use.

TDB: image with provisioning flow

## Possible uses of Fobnail certificate

Fobnail architecture doesn't impose use of key for which certificate is being
made. The only restriction that should be followed is that created certificate
is not a CA, because that together with inability to use CRLs creates enormous
security issue.

Usage of key should answer the question: "why do I want to attest the platform"?
There is no universal answer, each use case has its own requirements. Example
usages with corresponding X.509 `keyUsage` bits include, but are not limited to:

- obtaining small data (e.g. nonce, password, salt) from encrypted challenge,
  for this `dataEncipherment` must be set,
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

## Summary

TBD

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

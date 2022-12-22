---
title: Fobnail Token - example use case
abstract: 'TBD'
cover: /covers/usb_token.png
author: krystian.hebel
layout: post
published: true
date: 2022-12-22
archives: "2022"

tags:
  - fobnail
  - tpm
  - attestation
  - linux
categories:
  - Security

---

# About the Fobnail project

Fobnail is a project that aims to provide a reference architecture for building
offline integrity measurement verifiers on the USB device (Fobnail Token) and
attesters running in Dynamically Launched Measured Environments (DLME). It
allows the Fobnail owner to verify the trustworthiness of the running system
before performing any sensitive operation. This project was founded by [NlNet
Foundation](https://nlnet.nl/). More information about the project can be found
in the [Fobnail documentation](https://fobnail.3mdeb.com/). Also, make sure to
read other posts related to this project by visiting
[fobnail](https://blog.3mdeb.com/tags/fobnail/) tag.

# Scope of current phase

This phase focused on using Fobnail in a real-life use case, namely using it to
access LUKS2 decryption key if and only if the PCR measurements are valid. In
this post only high-level usage will be described, if you want to know what
happens under the hood or want to modify it to your needs see
[documentation](https://fobnail.3mdeb.com/examples/disk_encryption/).

# Changes

In this phase we completely switched the architecture around. Now the CoAP
server is located on Fobnail Token, instead of each of PC applications. This
way we could implement [API endpoints](https://fobnail.3mdeb.com/fobnail-api/),
including [Fobnail Token Services (FTS)](https://fobnail.3mdeb.com/fobnail-api/#fobnail-token-services),
which allows for more elaborate applications without having to re-flash Token
firmware each time.

As of now, only storage services are fully defined in FTS. Few other endpoints
for working with cryptographic keys were listed, but they are yet to be
implemented. There is also an endpoint `/api/version` which reports all versions
of API supported by Token - the version will be increased only when
backward-incompatible changes are done. **TBD**

There are now two separate Attester applications - one with provisioning code,
and one without. Former should be used just for initial provisioning, and the
latter for normal use. We hope that by simplifying more frequently used form we
can reduce the surface of attack. It also helps with rare cases when users
inadvertently plugged in unprovisioned Token - in that case Token would also
lit _all-good_ green LED in the end, making it indistinguishable from normal
attestation.

Speaking of LEDs, we now have to steer them in a non-blocking manner. Simple
delay loops were good enough when the Token was CoAP client, but now it has to
be able to respond to the clients without making them wait too long, especially
for longer signals like attestation result. We took advantage of that forced
change to [expand and standardize **TBD**](TBD) blink codes produced by Fobnail
Token.

## Building and running

Building hasn't change much since [last time](https://blog.3mdeb.com/2022/2022-05-25-fobnail_provisioning/#building-and-running).
There are some changes done to produce `fobnail-attester-with-provisioning`
along with non-provisioning version, but instructions for building didn't
change.

Despite changes in the architecture, applications are started mostly the same as
before. Attester is an exception, it now can take arguments which use Fobnail
Token Services. Description of those can be obtained by starting Attester with
`--help`:

```
Usage:
    fobnail-attester [CMD]...

Commands:
    --read-file token_fname:local_fname
    -r token_fname:local_fname
        Read file token_fname from Fobnail Token and save it in local_fname.

    --write-file local_fname:token_fname
    -w local_fname:token_fname
        Write file local_fname to token_fname on Fobnail Token.

    --delete-file token_fname
    -d token_fname
        Remove file token_fname from Fobnail Token.

All commands are executed only if the attestation was successful.

Both --read-file and --write-file can take '-' as local_fname to use stdout
and stdin, respectively. If '-' appears in multiple write commands, the same
data is written to all files. If '-' appears in multiple read commands, output
consists of concatenated content of all files, in the order in which they are
read. Use './-' to access regular file named '-'.

Multiple commands may be specified at once, in that case they are executed in
order in which they appear on the command line. Attestation is performed only
once. If any of the commands fails, further commands are not executed.
```

## Preparing encrypted disk image for use with Fobnail

**TBD**

## Demo

**TBD**

## Summary

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

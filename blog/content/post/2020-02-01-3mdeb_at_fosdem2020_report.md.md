---
title: 3mdeb at FOSDEM 2020 report
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: piotr.krol
layout: post
published: true
date: 2020-02-01
archives: "2020"

tags:
  - fosdem
  - conference
categories:
  - Firmware
  - Miscellaneous
  - Security

---

On Saturday, with Michał Żygowski, we decided to go to Hardware aided Trusted Computing devroom.

First presentation was from UC Berkley Ph.D. about Rust and SGX, the thesis is
that most CVE detected in M$ products are releated to memory safety, because of
that Rust is the language that address most of issues related with it.

Rust:
- type safety
- statuc analysis built right into
- convinient error handling

Parsing is easy with anything except C. Rust has good features support that. Of
course enclave code should contain mininimal parsing code.

In architecture we should consider secure enclave as server, with that
attestation an identity is easy.

In general presentation was pitch about EDX Fortanix, which is SGX+Rust+Srevice
API, which simplifies interaction between secure enclave and system.

During demo was show how simple it is to run sample program in Rust in secure SGX encalve.

There was extensive discussion including concerns about all recent SGX
vulnerabilitie and if in that light keepeing private key in enclave is till
secure, the answer was more about mitigations
- update your microcode to most recent (to the one that contain fix)
- reprovision with new key in case of any issues

Second was from M$(?) CCF, in general it was about multi-party applications. We
would like to achive ditributed trusted computing (encyrpted integrity
proitected memory, remote attestation).

It looks like everywhere there is discussion about TLS session which terminates
in secure enclave, this is to hide traffic against host that enclave running
on. There is still need for time source, time is fetched from host and is not
considered trusted.

Key point of the system was to describe how mutli-party application can work in
similar was we set ruling, for example architecture can have voters that decide
about various things e.g. adding user changing community rules etc. It looks
like presentation discussed implementation/design of decision making system.
Of course everything use enclaves and secure communication.

Other case is code update, so based on votes we can decide if new version is
acceptable to be used, if there is different result we recover to previous
version.

## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

---
title: Reproducible builds
abstract: Recently we made sure that every build of PC Engines' firmware is
          built in a reproducible manner. This short post shows what exactly
          does it mean and why this should be important to firmware developers.
cover: /covers/coreboot-logo.svg
author: krystian.hebel
layout: post
published: true
date: 2019-05-22
archives: "2019"

tags:
  - apu
  - coreboot
categories:
  - Firmware

---

Recently we made sure that every build of PC Engines' firmware is built in a
reproducible manner. This short post shows what exactly does it mean and why
this should be important to firmware developers.

## What?

A build process is reproducible if it produces exactly the same image every time
it is built. This means that it **cannot**:

* include the time of compilation in resulting image or application
* use data obtained from build environment, like a host or user name
* use random input data
* point to any non-static points in a source tree (e.g. head of a branch)

## Why?

As firmware images for apu platforms were delivered in the form of binary
images, users would like to have a way of confirming whether those images are
what they are expected to be. The easiest way is to build an image from the
source and compare its hash with the hash of the pre-built binary.

Reproducibility is also important in most security features, where one stage
of a firmware calculates a checksum of the next one. The new stage starts only
if the checksum has a value known to the current stage.

The image read from a platform can also be compared to known images. It makes it
possible to check whether platform firmware was tampered with.

## How?

Both the time of compilation and environment variables were used a long time ago
by coreboot. These "features" were still present in the `legacy` releases up to
`v4.0.23` - the time of compilation was dropped earlier, but domain, host and
user name were still being saved. Note that they were not actually used in the
code, just saved in a `config` file in the firmware image. coreboot is built
with `coreboot-sdk` Docker image. The hostname was different with every build
because it is randomly assigned every time a container is started. This problem
was not present in the mainline releases - new coreboot code was already
reproducible.

We discovered that it was not the only issue - images still had different
checksums with every build. The next step was to find which part of CBFS
changes. It was iPXE, because of [this line](https://git.ipxe.org/ipxe.git/blob/fd6d1f4660a37d75acba1c64e2e5f137307bbc31:/src/Makefile.housekeeping#l1144).
This variable can be overwritten when executing `make`.

After that, all consecutive builds resulted in identical images, but these were
not reproducible yet. Some payloads were still built from the `master` branch,
so the image would be different as soon as new commits appear. The last change
left to do was to use stable commits in all payloads used.

All mentioned changes can be found in pull requests: [241](https://github.com/pcengines/coreboot/pull/241),
[242](https://github.com/pcengines/coreboot/pull/242), [269](https://github.com/pcengines/coreboot/pull/269)
and [270](https://github.com/pcengines/coreboot/pull/270).

## Summary

From now on, the coreboot images for PC Engines by 3mdeb will be built in a
reproducible manner. It means that a couple of years from now it should still
be possible to build the versions released recently.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

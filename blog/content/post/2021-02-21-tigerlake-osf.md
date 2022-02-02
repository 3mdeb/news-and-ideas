---
title: Open Source Firmware on TigerLake platforms - part 1
abstract: 'This post describes efforts of building open source firmware for
           Tiger Lake UP3 RVP platform and the problems faced in the process.
           Tiger Lake is one of the newest Intel processors for which the FSP
           and EDK2 MinPlatform has been recently released.'
cover: /covers/tigerlake.jpg
author: michal.zygowski
layout: post
published: true
date: 2021-01-21
archives: "2021"

tags:
  - firmware
  - coreboot
  - edk2
  - Tiger-Lake-RVP
categories:
  - Firmware

---

# Introduction

If somebody would tell 7 years ago that Intel will support open source
firmware, he would be laughed at instantly. If we recall time, like 15 years
ago where the datasheets were more open and were sufficient to write open
source firmware, today it is not possible. Silicon vendors are hiding the
intellectual property contained in the processors. It would seem like the open
source firmware is doomed, but...

Thankfully there are companies and Intel employees that try to make impact and
change this situation. For example Google supporting the coreboot project on
their Chromebooks encourage Intel to release the Firmware Support Package
([FSP](https://www.intel.com/content/www/us/en/intelligent-systems/intel-firmware-support-package/intel-fsp-overview.html)).
The FSP is a bundled silicon initialization code in a binary form with well
documented interface and configuration options. It simplifies new hardware
enabling and reduces cost of overall firmware development. While it doesn't
solve all problems and sometimes causes issues, kudos should go to Intel for
supporting the open source firmware. Special credits should go to the open
source firmware community members from Intel:
[Nathaniel DeSimone](https://github.com/nate-desimone),
[Vincent Zimmer](https://www.linkedin.com/in/vzimmer/),
[Brian Richardson](https://www.linkedin.com/in/richardsonbrian/) and
[Isaac Oram](https://www.linkedin.com/in/isaac-w-oram-8bb79320/). The are often
present on various open source firmware events on communities, few examples of
their contribution::

* [OSCF2018 Keynote](https://youtu.be/3VVaCOCCiD8)
* [OSFC2019 Intel Open Platform Enabling Plans](https://www.youtube.com/watch?v=d2aKDVuFaX8)
* [OSFC2019 Hardening Firmware Components with Host-based Analysis Tools](https://www.youtube.com/watch?v=cd80acwTYLY)

# OSF on Tiger Lake platform

Tiger Lake is the codename of the 11th generation Intel processors. We had the
pleasure to get the Tiger Lake Reference Validation Platform (RVP) and test the
available open source firmware options. coreboot development for Tiger Lake
begun some time ago so that when FSP is released, the build target for Tiger
Lake RVP should be ready. This however is different from EDK2 MinPlatform. The
open board implementation is released some time after FSP. But let's start form
the beginning.

## coreboot

Tiger Lake implementation in coreboot was the first we have tried before going
with MinPlatform because the latter wasn't available yet. For reasonably
experienced engineer it is quite simple to configure the build, since almost
all the options are in place when selecting the TigerLake RVP platform.
However, one may miss the microcode binary when building coreboot. Typically
one extract the microcode blob from the original BIOS binary shipped with the
platform if the microcode is not disclosed or publicly available. When
extracted simply change the configuration options to include microcode external
binaries and point to the path with extracted microcode, done.

I will omit the build process here since I would like focus more on problems
and their possible solutions. If you are interested in building coreboot for
RVP platform please refer to [Booting coreboot on Intel Comet Lake S RVP8 blog post](https://blog.3mdeb.com/2020/2020-08-31-booting-coreboot-on-cometlake/)

The first challenge I have encountered is that the platform did not print any
output on any of the serial consoles, although it is capable of printing it
according to the schematics. Thankfully the RVP platforms have 7-segment
displays for post codes which makes it easy to debug instructions after reset
vector. It occurred that it stops in the cache as RAM setup. At this point
there is not much one can do without support or bug history. So I have sent an
email to coreboot mailing list and got a reply that
[older microcode revisions had problem with new CAR setup](https://mail.coreboot.org/hyperkitty/list/coreboot@coreboot.org/thread/7YHWASZX3CQ5U3L7D5CVJCDZSMRNCCXK/).

I have followed the [Tim Wawrzynczak](https://www.linkedin.com/in/tim-wawrzynczak-0011315/)
advise and turned off the `INTEL_CAR_NEM_ENHANCED` (thank you Tim for the hint
by the way). I did the trick and I could see the serial output on the console.
"Now it is a piece of cake" I thought... Then I saw the
`FSP memory init returned an error`. Great, now what?

Second challenge is the memory initialization and configuration. After
investigating the source code I noted the Tiger Lake RVP mainboard has LPDDR4
configuration. But wait, my platform has 2 DDR4 SODIMMs... That explains the
error. The typical difference between LPDDR and DDR memory is that the former
requires an exact mapping of memory signal from CPU to DRAM to be passed to
FSP. So simply zeroing this configuration should be enough. Also the memory
initialization was called by `meminit_lpddr4x` which was not suited for DDR4,
so I had to change it to `meminit_ddr4` with appropriate parameters for SMBus
SPD addresses. After these modifications I could past through the memory
initialization.

Another challenge faced was the CPU initialization in coreboot. I was getting
board resets during MCE (Machine Check Error registers) clearing which I have
written about [here on coreboot mailing list](https://mail.coreboot.org/hyperkitty/list/coreboot@coreboot.org/thread/MW44TIEMFMVDWPVCAFPE2QUFXXGZYYAX/).

Till today I haven't got any response, however, I managed to resolve the
problem as well. When investigating the logs I noticed that the microcode is
not automatically loaded before the reset vector (wait, what?! how?!). For
reminder, the microcode is being loaded through FIT table before reset vector
since Haswell (4th generation) processors. This could be due to the processor
being engineering sample (which is common for RVP platforms). I had placed an
explicit call to update microcode in the coreboot's bootblock (the very first
stage executed after reset vector) then I got past the PCI enumeration phase.

Right after the PCI enumeration phase I was hit with FSP notify error. No idea
what could cause this issue, since the notify phases typically do not do much,
but yet I managed to hit an error. To this point I haven't been able to figure
out what is wrong. Trying to narrow it down with debug FSP binary didn't help
as well, because the FSP asserts in Thunderbolt/USB type C initialization. I
finally ended up disabling Thunderbolt.

I am still not close to booting an operating system and what is most
frightening, I had to disable most I/O devices (USB, SATA, PCIe), yet those
that were enabled refused to work, so I have no media to boot an OS from...
At this point I decided to try a different path, that is EDK2 MinPlatform.
You may find all the modifications on [Dasharo coreboot repository](https://github.com/Dasharo/coreboot/tree/tgl_rvp).

## EDK2

EDK2 besides the open source common modules for UEFI compliant firmware also
contains the platform code hosted in a separate repository called
[edk2-platforms](https://github.com/tianocore/edk2-platforms). This is where
Intel publishes the reference board support code that integrates with FSP to
boot RVP platforms. The TigerLake open board packages have been published just
around the same time I have been conducting my experiments. I gave it a try
almost immediately with hope it will give better results.

Unfortunately I stumbled upon another challenge. As a fellow open source
enthusiast I have been compiling EDK2 with Linux using GCC. Although EDK2 is
supposed to support GCC5 and newer versions, it occurred it is not always true.
The freshly published code was not buildable with GCC when trying with the
3mdeb [edk2-docker](https://github.com/3mdeb/edk2-docker). When giving it a
little thought it is not surprising. Visual Studio compiler is the one that
dominates the ecosystem of firmware. Intel, AMD and IBVs (Independent BIOS
Vendors) use Windows and Microsoft compilers to build EDK2. Thus I think it was
not tested with GCC compilers when published. The list of encountered problems
is posted on [TianoCore Bugzilla](https://bugzilla.tianocore.org/show_bug.cgi?id=3220).

Thankfully Intel engineers were very helpful and responsive on these bugs. The
fixes for GCC toolchain were committed quickly (in just one week) to the Tiger
Lake open board packages on edk2-platforms repository.

In the mean time (before the fixes landed into repositories) I have fixed all
compilation issues for GCC locally, I noticed that the packages contain support
for LPDDR4 platform, again... The EDK2 FSP integration can work in two modes:

* FSP API mode - the bootloader simply calls the entry point of the FSP module
  by parsing the FSP header. The bootloader is also responsible for providing a
  pointer to UPD values that have to be patched per platform.
* FSP dispatch mode - this mode is dedicated for UEFI compliant bootloader
  because the FSP acts as a standard Firmware Volume detectable by PEI
  dispatcher. PEI dispatcher detects the FSP modules and evaluates the
  dependency expressions of particular PE files and decides about the order of
  their execution. The bootloader's responsibility is to provide necessary
  protocol interfaces called Policy Updates that will set/patch the FSP UPD
  values per platform needs.

Switching between them is simply a build flag change. Gave a try to both, but
unfortunately without success. The `FSP memory init returned error`, again...
Changing the DDR memory signals routing as in coreboot did not help. Currently
I am stuck at this problem which I have reported to the [Bugzilla](https://bugzilla.tianocore.org/show_bug.cgi?id=3219).
Apparently the A0 stepping (which is an engineering sample) cannot work with
the published code. It seems I have reached a dead end.

## Possible solutions

One of the obvious solutions that would be necessary is to add the build
targets for TigerLake UP3 RVP DDR4 by Intel. To get rid of build issue under
different toolchains a simple CI/CD would be more than enough to build test the
reference platform with supported toolchains. I believe EDK2 has CI integration
which could be extended to cover edk2-platforms repository. coreboot already
has the build testing of the patchsets sent for review with Jenkins for a long
time. It could be also great if Intel would publish validation results for FSP
and open board packages (Dasharo does it as part of its transparent validation
philosophy). As far as I know, Intel publishes only the memory HCL (Hardware
Compatibility List) for the FSP and microarchitectures. 3mdeb is working on
[Dasharo Transparent Validation System](https://github.com/Dasharo/transparent-validation)
to improve the state of firmware and its features test coverage and results
reporting. If you are interested how are we testing the supported hardware
please read [this blog post](https://blog.3mdeb.com/2021/2021-02-18-testing/).

## Summary

Silicon vendor contributions to open source firmware still lacks in some
aspects. But it is understandable. The BIOS reference code provided to IBVs is
well tested, while the open source support equivalents are just a subsets of
the BIOS reference code providing bare hardware initialization just enough to
boot the platform. This code comes in a form of FSP and the open board package
to EDK2. Somewhere between this transition some human error may occur. Also it
is important to have similar testing configuration. As you can see engineering
sample and production SKU behavior with the same code changes dramatically. The
situation is similar if not more difficult when it comes to coreboot. The open
board package integration has to be rewritten in coreboot style and to coreboot
interfaces/APIs. This process is tedious and error prone, it is like
reinventing a wheel. Thus the community should actively support silicon vendors
in testing and feedback of new microarchitectures integration.

Most of the challenges and issues describes in this post can be mitigated or
addressed with through extensive testing suggested in the [Possible solutions section](#possible-solutions).
Testing on target hardware is still a challenge, ideally we want to do it
remotely. 3mdeb is advanced in that matter and is testing firmware on real
hardware on automated tests stands with [RTE](https://docs.dasharo.com/transparent-validation/rte/introduction/)
in an own laboratory. If you need extensive testing or a good maintenance for
your firmware, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).

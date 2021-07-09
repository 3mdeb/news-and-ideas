---
title: Open Source Firmware on TigerLake platforms
abstract: 'This post describes efforts of building open source firmware for
           Tiger Lake UP3 RVP platform and the problems faced in the process.
           Tiger Lake is one of the newest Intel processors for which the FSP
           and EDK2 MinPlatform has been recently released.'
cover: /covers/tigerlake.jpg
author: michal.zygowski
layout: post
published: true
date: 2021-02-21
archives: "2021"

tags:
  - Firmware
categories:
  - Firmware

---

# Introduction

If somebody would tell 6 years ago that Intel will support open source
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
source representatives from Intel like Nataniel DeSimone, Vincent Zimmer, Brian
Richardson and Isaac Oram. The are often present on various open source
firmware events on communities, few examples:

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
with MinPlatform because the latter wasn't available yet. It is quite simple to
configure the build, since almost all the options are in place when selecting
the TigerLakeRVP platform. However, one may miss the microcode binary when
building coreboot. Typically one extract the microcode blob from the original
BIOS binary shipped with the platform if the microcode is not disclosed or
publicly available. When extracted simply change the configuration options to
include microcode external binaries and point to the path with extracted
microcode, done.

I will omit the build process here since I would like focus more on problems
and their possible solutions. If you are interested in building coreboot for
RVP platform please refer to [Booting coreboot on Intel Comet Lake S RVP8 blog post](https://blog.3mdeb.com/2020/2020-08-31-booting-coreboot-on-cometlake/)

The first problem I have encountered is that the platform did not print any
output on any of the serial consoles, although it is capable of printing it it
according to the schematics. Thankfully the RVP platforms have 7-segment
displays for post codes which makes it easy to debug instructions after reset
vector. It occurred that it stops in the cache as RAM setup. At this point
there is not much one can do without support or bug history. So I have  sent an
email to coreboot mailing list and got a reply that older microcode revisions
had problem with new CAR setup:

https://mail.coreboot.org/hyperkitty/list/coreboot@coreboot.org/thread/7YHWASZX3CQ5U3L7D5CVJCDZSMRNCCXK/

I have followed the advise and turned off the INTEL_CAR_NEM_ENHANCED. I did the
trick and I could see the serial output on the console. "Now it is a piece of
cake" I thought... Then I saw the FSP memory init returned an error... Great,
what now?

Second issue is the memory initialization and configuration. After
investigating the source code I noted the Tiger Lake RVP mainboard has LPDDR4
configuration. But wait, my platform has 2 DDR4 SODIMMs... That explains the
error. The typical different between LPDDR and DDR memory is that the former
requires an exact mapping of memory signal from CPU to DRAM to be passed to
FSP. So simply zeroing this configuration should be enough. Also the memory
initialization was called by `meminit_lpddr4x` which was not suited for DDR4,
so I have to change it to `meminit_ddr4` with appropriate parameters for SMBus
SPD addresses. After these modifications I could past through the memory
initialization.

Another problem faced was the CPU initialization in coreboot. I was getting
board resets during MCE (Machine Check Error registers) clearing which I have
written about here:

https://mail.coreboot.org/hyperkitty/list/coreboot@coreboot.org/thread/MW44TIEMFMVDWPVCAFPE2QUFXXGZYYAX/

Till today I haven't got any response, however, I managed to resolve the
problem as well. When investigating the logs I noticed that the microcode is
not automatically loaded before the reset vector. For reminder, the microcode
is being loaded through FIT table before reset vector since Haswell (4th
generation) processors. This could be due to the processor being engineering
sample (which is common for RVP platforms). I had placed explicit call to
update microcode using coreboot then I got past the PCI enumeration phase.

Right after the PCI enumeration phase I was hit with FSP notify error. No idea
what could cause this issue, since the notify phases typically do not do much,
but yet I managed to hit an error. To this point I haven't been able to figure
out what is wrong. Trying to narrow it down with debug FSP binary didn't help
as well, because the FSP asserts in Thunderbolt/USB type C initialization.

I am still not close to booting an operating system, but yet I have encountered
many bugs in the meantime. This is the first time I have been put through so
much effort to boot a reference platform. Previous platform I have tried
(Cometlake-S or Kaby Lake U) did not cause almost any problem. The quality of
the implementation of the Intel silicon support done by Intel employees
themselves seem to have degraded. As a proof of that please red the following
section about EDK2 MinPlatform.

## EDK2

EDK2 besides the open source common modules for UEFI compliant firmware it also
contains the platform code hosted in a separate repository called
[edk2-platforms](https://github.com/tianocore/edk2-platforms). This is where
Intel publishes the reference board support code that integrates with FSP to
boot reference platforms. The TigerLake open board packages have been published
just few days ago. I gave it a try almost immediately with hope it will give
better results.

But on high hopes it ended, quite quickly. Although EDK2 is supposed to support
GCC5, it occurred it is not always true. The freshly published code was not
buildable with GCC5 when trying with the 3mdeb
[edk2-docker](https://github.com/3mdeb/edk2-docker).

When giving it a little thought it is not surprising. Visual Studio compiler is
the one that dominates the ecosystem of firmware. Intel, AND and IBVs
(Independent BIOS Vendors) use Windows and Microsoft compilers to build EDK2.
Thus it was not tested with GCC compilers. The list of encountered problems is
posted on EDK2 Bugzilla: https://bugzilla.tianocore.org/show_bug.cgi?id=3220

Even though I have fixed all compilation issues for GCC5, I noticed that the
packages contain support for LPDDR4 platform, again... The EDK2 FSP integration
can work in two modes; FSP API and FSP dispatch mode. Switching between them is
simply a build flag change. Gave a try to both without success. The FSP memory
init return error, again... Changing the DDR memory signals routing as in
coreboot did not help. Currently I am stuck at this problem which I have
reported to the Bugzilla: https://bugzilla.tianocore.org/show_bug.cgi?id=3219

## Possible solutions

One of the obvious solutions that would be necessary is to add the build
targets for TigerLake UP3 RVP DDR4 by Intel, hopefully validated build targets.
To get rid of build issue under different toolchains a simple CI/CD would be
more than enough to build test the reference platform with supported
toolchains. coreboot already has the build testing of the patchsets sent for
review with Jenkins for a long time. Moreover it is moving to validation on
target hardware which EDK2 clearly lacks currently. It could be also great if
Intel would publish validation results for FSP and open board packages. As far
as I know, Intel publishes only the memory HCL (Hardware Compatibility List)
for the FSP and microarchitectures.

## Summary

Silicon vendor contributions to open source firmware still lacks quality in
many aspects. Most of them can be easily addressed or mitigated with above
proposals. Testing on target hardware is still a challenge, however 3mdeb is
advanced in that matter and is testing firmware on real hardware with automated
test. If you need your firmware being extensively tested or need a good
maintenance for your firmware, contact us.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

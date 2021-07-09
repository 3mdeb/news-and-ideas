---
title: Open Source Firmware on AMD Milan server processors
abstract: 'There were times where AMD was actively supporting open source
           firmware ecosystem by providing silicon initialization code. With
           a few years break AMD is now trying to support open source firmware
           again with the mobile platform like Chromebooks. However, the recent
           achievements have made everybody think that open source firmware is
           also possible on severs.'
cover: /covers/amd-epyc.jpg
author: michal.zygowski
layout: post
published: true
date: 2021-02-21
archives: "2021"

tags:
  - firmware
categories:
  - Firmware

---

# Introduction

Do you remember times when AMD was actively supporting open source firmware?
Back in the 2008 AMD was delivering the AGESA silicon initialization code and
was contributing it to coreboot. Up to 2014 AMD was release the AGESA code in
public. These were the golden years of open source firmware for AMD processors
and many platforms emerged in coreboot. You may know those platform under
various names like PC Engines ALIX and APU1. They benefit still from fully open
source implementation. However since 2014 AMD started to deliver the AGESA in
binary form only. And that situation is maintained till today with some
exceptions (after AMD Steppe Eagle there were no AGESA binary releases
anymore). Google encouraged the AMD to work on FSP compatible interface for
AGESA for their Chromebooks and today we have a AMD Picasso support in
coreboot. If you want to know more about Open Source Firmware on AMD history,
please refer to our FOSDEM presentations:

* https://video.fosdem.org/2020/K.4.401/coreboot_amd.mp4
* https://video.fosdem.org/2021/D.firmware/firmware_osfsoap2.mp4

Everybody hopes that AMD server will get open source firmware too. According to
rumors something is moving into that direction. However, in this blog post I
will describe the real current situation.

## OSF on AMD Milan

Since the Ron Minnich talk about [pure open source on an AMD Zen](https://vimeo.com/488147337)
we have been getting more requests for open source firmware on AMD based
servers like Rome or Milan. While this isn't surprising, many people seem to be
missing a few important points and get the wrong idea (by the way big kudos to
Ron for attempting and showing it on OSFC2020). The number of issues
encountered by Ron is enormous (and not all has been shown) and typically
related to very basic thing like timers. Only those tightly related to firmware
development can understand that this is only the beginning of the road full of
obstacles. There are many more undocumented registers that are set by AGESA and
many more issues to find out yet. One may forget to use advanced features
without AGESA. One more important thing is that the presentation noted that SMP
is not yet well understood. That means only one main core is running, while the
rest is not initialized, where on server platforms is basically a killer
performance limitation.

## OSF development on AMD server processors

Let's move to the development now from typically BIOS/firmware provider
company, different from 3 major IBVs. First of all, the server initialization
code is not distributed to other companies than IBVs, so there is no chance to
integrated it or even provide BIOS/firmware for a customer platform. Similar
situation is present in Intel. The server market is the most confidential and
protected one. Code aside, but what with the hardware?

Ron Minnich told on his presentation that "AMD was very kind and willing to
ship us the CRB". Silicon vendors have different policies about borrowing CRBs
and they may depend on various factors, like project details. Sometimes you
need to have a use-case or customer. Typical questions thats sometimes
influence the decision: what product (processors, chipset) is going to be used
on the customer platform, what is estimated annual volume, product application,
etc. For example if your volume is lower, your chance are most likely
decreased.

Some OEMs/ODMs also believe they can support coreboot on their platform,
because it was shown on OSFC and they have an AGESA compatible with FSP. This
is not true. The only FSP compatible AGESAs currently are those developed for
Chromebooks, i.e. the mobile processors like Picasso, Cezanne (incoming). If
you are an OEM or ODM you may simply check whether you have a FSP compatible
AGESA. Simply searching keyword FSP through the code will not give any
meaningful results: `mfspr` or `FSPS` (which stands for
`Memory Feature Online Spare` `FixSocPstate`).

## Current possibilities

Given the unfavorable situation described in previous sections there are very
few options for an open source firmware provider company like 3mdeb:

1. Offer few times higher pricing than IBV for developing the integration of
   AGESA the customer obtained to an open source firmware framework (probably
   EDK2, because it is the only supported framework for AGESA).
2. Advise the customer to go to IBV for the firmware, then offer training or
   customization services to address customer's specific needs for firmware
   features.

We already have tried the approach number 1 and encountered tons of problems
and bugs in the EDK2 code as well as AGESA code. One of the main, most painful
bugs are:

* improper GDT setup code in EDK2 CPU package
* function definition mismatches in AGESA code that do not conform to UEFI
  specification (missing or unnecessary `EFIAPI` directives before function
  declarations which causes mixing the function calling conventions)

There are many more, but it is not a place for that. We have announced that we
are working on a open source EDK2 bindings and integration for AGESA for AMD
V1000/R1000 embedded processors. Initially we planned to release this code in
2021, but that depends on whether we managed to resolve the issues.

Option number two is of course the least desirable, because it doesn't move OSF
on AMD any step forward.

## How to port the hardware?

If you are OEM/ODM and create a product based on AMD processor this is what you
should know and how the process looks like:

1. Ensure you have the AGESA code for you platform. Depending on your selected
   framework you may need the FSP compatible AGESA for e.g. coreboot. For EDK2
   this may be any form.
2. Contact an open source firmware vendor or consulting company like 3mdeb.
   State your requirements, be ready to provide a hardware BOM and eventually
   schematics. Sign NDA if required.
3. Depending on the selected framework we can offer following options:
   - EDK2 integration, based on our work with V1000/R1000 processors
   - coreboot integration if AGESA is FSP compatible, otherwise it may take
     tons of work and huge amount of time and funds
   - ~~go to IBV~~ (please don't, you will make the open source firmware more
     far away)
4. We provide an estimation costs with the description of product and features
   included in the project and their cost.
5. Customer may negotiate which features he wants to be included.
6. We agree on the conditions and start to work.

## Summary

It seems like the open source firmware on AMD processor based servers will not
be possible for a while. Server market was always one of the most closed and
protected regions of the firmware. We hope to see it happen soon, but current
situation does not let anybody move forward with open source firmware competing
with the firmware solutions present nowadays.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

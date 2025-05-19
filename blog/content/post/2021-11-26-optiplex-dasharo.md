---
title: 'Dasharo for Dell OptiPlex 7010 / 9010'
abstract: 'Open source firmware may be hundreds of times better than the
           proprietary one. On the example of Dell OptiPlex 7010 / 9010 we will
           show you the advantages of Dasharo firmware on this machine.'
cover: /covers/dasharo-sygnet.svg
author: michal.zygowski
layout: post
published: true
date: 2021-11-26
archives: "2021"

tags:
  - dasharo
  - optiplex
categories:
  - Firmware

---

## Introduction

Dell OptiPlex 7010 / 9010 is the majority of machines used in 3mdeb office by
the engineers and developers. It is only natural for a company promoting open
source firmware (OSFW) to utilize their own product in daily work. The process
of porting coreboot on the machine took significant amount of free time (which
you may read about in [other blog posts](https://blog.3mdeb.com/tags/optiplex/)
by the way) but it was definitely worth it. It opened a path for developing a
firmware that would squeeze out the full potential of the platform. You may be
wondering what else a platform may do that OEM didn't implement. But I will tell
you this, with open source firmware almost anything is possible and with
[Dasharo firmware](https://dasharo.com/) we make it a reality.

## ME neutralization

Intel Management Engine is a very controversial component of modern Intel
chipsets and SoCs due to its capabilities and features. One of the most fearful
features is the remote management and connectivity. Intel ME is able to utilize
network via dedicated network controller on vPro machines without any awareness
of the operating system software. It is used for software like Intel Active
Management Technology
([AMT](https://www.intel.co.uk/content/www/uk/en/architecture-and-technology/intel-active-management-technology.html))
or
[Computrace](https://i.dell.com/sites/content/business/solutions/brochures/en/Documents/absolute-overview.pdf)
([with cooperation of Intel Anti-theft Technology](https://media9.connectedsocialmedia.com/intel/06/4470/Intel_Anti_Theft_Technology_Computrace_WhitePaper.pdf)
which seems to be a
[service running on Intel ME](https://community.intel.com/t5/Intel-vPro-Platform/How-to-disable-Intel-Anti-Theft-service-in-Intel-ME-Status/m-p/472962/thread-id/5789?attachment-id=13594)).
Such features and capabilities often raises doubts and concerns about privacy.
Moreover it is a few megabytes of proprietary closed source firmware of unknown
quality with uncertain other impacts on the system. Many people often want to
disable ME or even neutralize it to reduce the attack surface. This is what we
offer with Dasharo firmware on Dell OptiPlex 7010 / 9010,
[me_cleaner](https://github.com/corna/me_cleaner) is being applied on the
firmware image which can be flashed on the board. From a 6MB of unknown firmware
only dozens of kilobytes are left. me_cleaner has been created based on
researching and reversing of the Intel ME which is prohibited according to its
license agreement. Decompilation however, may be allowed according to
[some EU courts](https://osfw.slack.com/archives/C9ZLS0U4F/p1633701873113300).
See also
[Article 6](https://eur-lex.europa.eu/legal-content/EN/TXT/PDF/?uri=CELEX:32009L0024&from=EN).
But IANAL.

## RAM support

As engineers we often encounter situation that the same board comes in a few
SKUs (stock keeping units) which may be distinguished by the used processor for
example. Such a procedure is often utilized to reduce the cost of the product or
rather offer a product less or more equipped to make it more affordable on the
market. Also as engineers doing open source firmware we want to know how many
differences they are, whether we may unify support of the variants or even use
the same binary to support multiple boards. But in the cases where the mainboard
is essentially identical and the OEM offers it with different hardware
capabilities, one question comes to the mind immediately: what is going on? It
happens for the 7010 and 9010 variants in the
[specsheet](https://www.dell.com/support/manuals/en-us/optiplex-7010/opti7010_usff/specifications?guid=guid-157e8495-34d3-4efa-ab61-1d9efba4c90e).

```bash
Maximum memory:
  OptiPlex 7010 16 GB
  OptiPlex 9010 32 GB
```

Why would maximum RAM be limited by the variant? The number of memory slots and
the used processors are the same so there should not be any difference. However
with the Dasharo firmware we ensure that you are not limited to vendor
restrictions and 32GB memory may be populated on both 7010 and 9010. Fortunately
putting 32GB of RAM into Dell OptiPlex 7010 with Dell firmware does not limit
the memory reported to the operating system. Summing it up, the limitation of
maximum RAM is just business differentiation of the offered machines, i.e. "the
higher model number is the better are the parameters offered". That's it
(fortunately).

## ECC support

It occurred that the mainboard design allows the usage of ECC memory modules.
The memory module ECC lanes are connected to the CPU socket. However there is
one caveat. The Intel Q77 chipset used on the machine doesn't support CPUs with
ECC (currently only Xeon CPUs and some embedded ones support ECC). The CPU
compatibility of the chipset may be checked on
[Intel ARK](https://ark.intel.com/content/www/us/en/ark/products/64027/intel-q77-express-chipset.html).
But no risk no fun. A decent Xeon CPU matching the board could be bought for
less than $100. So we did a quick test and...
[it worked!](https://twitter.com/Dasharo_com/status/1435161914896748547?s=20).
We have a ECC capable CPU, now all we need is a ECC DIMM. Be aware though. A
typical server memory will not work here. We need an unbuffered ECC DIMM with
lower latencies (registered memory will only work on servers). However this time
it didn't work.

According to the investigations of the coreboot logs the CPU did not report the
ECC capability. The real question is why? There are a few pointers:

- [something else is controlling the capability](https://github.com/coreboot/coreboot/blob/master/src/northbridge/intel/sandybridge/raminit_common.c#L356)
- ECC support does not depend solely on CPU (the memory controller is a part of
  the CPU)

In some depths of a sensitive black hole I have found an information that the
chipset and CPU is "autonegotiating" the supported features according based on
the SKUs before the BIOS executes. So basically the CPU features may be limited
by the chipset based on supported processors. So even though you may be
successful in booting ECC capable Xeon CPU, if you don't have a C-series chipset
(C216 in this case) you will not be able to utilize ECC. Linus Torvalds has
expressed his deep dissatisfaction how Intel phased off the ECC support on
consumer chipsets in
[this article](https://www.extremetech.com/computing/318832-linus-tovalds-blames-intel-for-killing-ecc-ram-in-consumer-systems)
Maybe if we know a little bit more about how the autonegotiation works or if ME
firmware may force the ECC support, it will be possible to override the current
state.

## NVMe support

Dasharo firmware enables support for booting from PCIe NVMe drives unlike the
original Dell firmware. Back in 2013 the first NVMe drives have actually been
manufactured (Samsung XS1715) so the technology was not so popular when the
machine is launched. However even after 5 years of
[BIOS update releases](https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=90dd2&driverid=90dd2&lwp=rt)
this lovely machine did not live to see NVMe support. These machines have a PCIe
x4 slot which is perfect for a NVMe disk, just need a few bucks to buy an
adapter like [this one](https://www.aliexpress.com/item/1005003114626058.html).
With Dasharo firmware it is possible to boot from such NVMe disk without issues.

## Intel TXT support and TrenchBoot

Intel Trusted Execution Technology is a feature of Intel CPUs and chipsets to
perform trusted measurement of the operation system software defined in Trusted
Computing Group
[D-RTM architecture specification](https://trustedcomputinggroup.org/wp-content/uploads/TCG_D-RTM_Architecture_v1-0_Published_06172013.pdf).
Although Dell firmware supports TXT and it is nothing new for Dasharo to support
it as well. And [we did it](https://review.coreboot.org/q/topic:sandybridge_txt)
(you will be able to read more about this achievement in the incoming blog
post). Moreover we aim to support [TrenchBoot](https://trenchboot.org/) on this
machine. A very good use case of Intel TXT was presented by Qubes OS
[Anti Evil Maid (AEM)](https://github.com/QubesOS/qubes-antievilmaid/). By the
way we have been working on enabling AMD CPUs and TPM 2.0 as well in AEM. In an
ideal case Dell OptiPlex will come with TXT and TrenchBoot support and use AEM
to securely measure Qubes OS and perform a remote attestation using
[Fobnail](https://fobnail.3mdeb.com/). To protect the user even further we also
plan to integrate
[Intel STM](https://software.intel.com/content/www/us/en/develop/articles/smi-transfer-monitor-stm.html)
to avoid System Management Mode attacks to which Intel TXT is vulnerable.

## Open Security Training 2

All these possibilities, open source firmware and security features, makes the
Dell OptiPlex 7010 / 9010 a first class citizen secure workstation. It has been
recognized by [Xeno Kovah](https://twitter.com/XenoKovah), a former Apple
firmware security architect, as an excellent training platform for teaching
Intel firmware security and coreboot courses. The Dell OptiPlex 7010 / 9010 is
used as a reference machine in the [OpenSecurityTraining2](https://ost2.fyi/)
"Architecture 4001: x86-64 Reset Vector Firmware" class (which is currently in
private beta testing). And that class then leads into the "Architecture 4031:
x86-64 Reset Vector: coreboot" class, and future coreboot classes which are
under development, such as "Architecture 4032: coreboot Hardware Hands-On"
(where you will be able to experience flashing the firmware on the Dell OptiPlex
7010).

## How to get it?

Of course 3mdeb offers the OST2 reference setups of Dell OptiPlex 7010 / 9010 to
be purchased
[here](http://web.archive.org/web/20230529130440/https://3mdeb.com/shop/open-source-hardware/dasharo-dell-optiplex-7010-sff-i3-i7-8gb-32gb-ram-copy/).

The machine setup is configurable where you may choose the fully featured option
with 32GB RAM, NVMe with M.2 adapter, ME neutering and of course the Dasharo
firmware. If you like games you may even put some Nvidia GTX/RTX graphics card
(must be low profile, half height) if you like, the PCIe x16 port (blue) is
available for such extension. Onboard TPM 1.2 is supported out-of-the box.

## Summary

Dell OptiPlex is a wonderful machine with many security features. When TXT
becomes available with the open source firmware, the STM and Fobnail remote
attestation integration will create a machine which may rival Microsoft Secured
Core PC (if not outclass). There is still more to come o Dasharo on Dell
OptiPlex so stay tuned and watch for new blog posts and Dasharo releases.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to
[sign up to our newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

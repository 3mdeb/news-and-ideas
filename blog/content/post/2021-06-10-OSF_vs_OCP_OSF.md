---
title: "Open Compute Open System Firmware (OCP OSF) and its' importance"
abstract: "Let's figure out what is OCP Open System Firmware,
          see how it relates to the Open Source Firmware (OSF) - and why it is
          important for your company to have one running on your product."
cover: /covers/OSF_vs_OCP_OSF.png
author: piotr.krol
layout: post
published: true
date: 2021-06-10
archives: "2021"

tags:
  - Firmware
  - Open-source
categories:
  - Firmware
  - Miscellaneous

---

The [Open Compute Project (OCP)][1] is a rapidly growing community with a mission
to design and enable the delivery of the most efficient server, storage and
data-centre hardware designs available for scalable computing. OCP has been
[embraced][2] by the top tier tech giants: IBM, ARM, Google, Facebook, Alibaba,
Intel, Nvidia and even Microsoft - are already the OCP Platinum members. And
over 200 companies have jumped aboard, of course not for the sake of "one more
certification": their customers want to have complete control over their
hardware and its' low-level software *(firmware)*: having the source helps to
prolong their lifecycle by expanding the capabilities, to fix the bugs for
reducing the long-term maintenance fees, and to do their own security audit.
And these customers are willing to pay an extra for the OCP-certified products.

**OCP Technology Segment Data, 2019 and 2024** ***(Revenues are in US$ billions)***

| Market        | 2019 Revenue  | 2019 Market Share | 2024 Revenue | 2024 Market Share | 2019-2024 Compound Annual Growth Rate |
| -------------:|:-------------:|:-----------------:|:------------:|:-----------------:|:-------------- |
| Compute       | $13.25        | 83.1%             | $28.07       | 83.0%             | 16.2%          |
| Storage       | $2.45         | 16.9%             | $5.73        | 17.0%             | 18.5%          |
| **Total**         | **$15.70**        | **100.0%**            | **$33.80**       | **100.0%**            | **16.6%**          |

*Source: IDC Worldwide Open Compute Project Compute and Storage Infrastructure Market Forecast, May 2020.*

The OCP Open System Firmware project is aiming to allow system firmware like
[BIOS][3] and [BMC][4] to be modified and their source code shared - according
to a [OSF Checklist][5] - with the owners of OCP-certified hardware. Since March
2021, supporting Open System Firmware is mandatory for servers with OCP badging.

Unfortunately, a lot of data-centre hardware vendors are slow at open-sourcing
the firmware of their products, which hinders customers' ability to improve this
firmware and to harden its security. In turn, the security-conscious customers
and the advocates of [right-to-repair][6] - prefer to stay away from such products.
In such a situation the OCP OSF term is really confusing, since it can not describe
the actual openness of a firmware; and the Open Source Firmware (OSF) term is
much better - since it openly states and guarantees the openness of firmware.

Luckily, some of the more-conscious ecosystem partners - have already decided to
implement such Open Source Firmware (OSF) as coreboot for the Open System
Firmware architecture of their OCP products, with the help of such Open Source
Firmware Vendors (OSFV) as [3mdeb][7]. They did it because having a source code helps
to adapt the firmware to the needs of even the most demanding clients by fixing
the firmware bugs and expanding the device's feature set - at a reduced cost -
which allows making the most out of both your existing and future products by
extending their lifecycle and bringing them to the new previously unthought-of
markets. Another reason is that full control over firmware helps in long-term
hardware maintenance and removes the dependency on external companies, which at
the time of the incident may or may not have the resources to provide support.

![Embedded software market](/img/Embedded_Software_Market.png)

Just being open-source - by itself is not enough for the firmware to meet the
OCP certification: the extra requirements are mentioned in a [OSF Checklist][8].
The source code should be easily buildable by a native (ideally the open-source)
toolchain and the flashing utility should be either open-source like [flashrom][9]
or at least documented well enough for an open-source implementation to be
written. The key Open System Firmware components have to be open-source at new
OCP products, and although it is allowed to include some closed-source components
*(aka binary blobs)* to Open System Firmware when there is no other choice - there
should be a valid justification for them to be approved, such as "containing
silicon IP": i.e. a blob has been provided by your SV (Silicon Vendor) like
Intel to set up their chip during boot, which is needed for your device to run.
So the Open System Firmware has to be as close to being the Open Source Firmware
as it is possible - for the mutual benefit of a vendor and a customer - and all
the documentation should be good enough and distributable without NDAs.

![OSF features](/img/OSF_features.png)

The diagram above shows 6 types of Open Source Firmware features: the
fundamental features to the more advanced ones are depicted from left to right
and 1st to 3rd are essential.

1. Chip Initialization and Integration: the firmware components for the initial
setup of the motherboard's key chips - like the chips themselves - are usually
provided by the Silicon Vendors, sometimes in a binary-only form *(without the*
*source code)* like Intel FSP and later AMD AGESA. We at [3mdeb][10] can audit the
source code either available publicly or accessible to us thanks to our NDAs &
close cooperative relationships with Silicon Vendors like Intel and AMD. When
the sources aren't available, we can reverse-engineer a binary-only component to
create a higher quality open-source replacement with fewer bugs and more features,
or isolate from its' vulnerabilities & shortcomings with technology like [D-RTM][11]
(Dynamic Root of Trust for Measurement) that we are [highly-experienced][12] with.

2. Board Customization: in addition to the chip initialization, there should
be a board-specific setup for the things like GPIO, PCIe bifurcation and BMC
interface. In a coreboot, these could be configured at the mainboard files.

3. System Table Generation: system tables like SMBIOS and ACPI tables have to
be generated by Open Source Firmware to provide access to various management
features for an OS.

4. IPMI Integration: IPMI is a popular interface for BMC out-of-band management
control. The basic IPMI driver is already integrated into coreboot firmware.

5. Security Features: verified boot and Intel TXT integration are examples of
security features that use the hardware capabilities for advanced protection.

6. RAS Features: Reliability, Availability and Serviceability are essential
for data-centre operation. These features depend on the SMM handler readiness.

As you can expect, even just creating the Open Source Firmware for your product
is a great challenge that only a few companies in the world can complete, let
alone to maintain it in good shape and to meet all the OCP OSF certification
requirements to enter this new [rapidly growing market][13]. However: we at [3mdeb][14] -
being the [licensed provider][15] for quality coreboot consulting services and
Open Source Firmware Vendor (OSFV) relying on [Dasharo][16] to deliver scalable,
modular, easy to combine Open Source BIOS, UEFI, and Firmware solutions - are
surely more than capable of helping your company to pull this off! Feel free to
[book a call with us][17] or drop us an e-mail at <contact@3mdeb.com>, and
we will do our best to help your company to reach new heights.

 [1]: https://www.opencompute.org/
 [2]: https://www.opencompute.org/membership/membership-organizational-directory
 [3]: https://en.wikipedia.org/wiki/BIOS
 [4]: https://en.wikipedia.org/wiki/Intelligent_Platform_Management_Interface#Baseboard_management_controller
 [5]: https://www.opencompute.org/wiki/Open_System_Firmware/Checklist
 [6]: https://blog.3mdeb.com/2021/2021-04-30-right_to_repair/
 [7]: https://3mdeb.com/
 [8]: https://www.opencompute.org/wiki/Open_System_Firmware/Checklist
 [9]: https://www.flashrom.org/Flashrom
 [10]: https://3mdeb.com/
 [11]: https://blog.3mdeb.com/2020/2020-03-28-trenchboot-nlnet-introduction/
 [12]: https://blog.3mdeb.com/tags/trenchboot/
 [13]: https://www.opencompute.org/marketplace
 [14]: https://3mdeb.com/
 [15]: https://3mdeb.com/about-us/
 [16]: https://dasharo.com/
 [17]: https://calendly.com/3mdeb/consulting-remote-meeting

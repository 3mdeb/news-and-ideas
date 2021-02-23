---
title: "Open Compute Open System Firmware (OCP OSF) and its' importance"
abstract: "Together with Piotr Król let's figure out what is OCP OSF,
          see how it relates to the open-source firmware - and why it is
          important for your company to have one running on your product."
cover: /covers/OSF_vs_OCP_OSF.png
author: piotr.krol
layout: post
published: true
date: 2021-02-23
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
hardware and its' low-level software (firmware): having the source helps to
prolong their lifecycle by expanding the capabilities, to fix the bugs for
reducing the long-term maintenance fees, and to do their own security audit.
And these customers are willing to pay an extra for the OCP-certified products.

The OCP Open System Firmware (OSF) project is aiming to allow system firmware
like [BIOS][3] and [BMC][4] to be modified and their source code shared with
the owners of OCP-certified hardware. From March 2021, supporting OSF is
mandatory for servers with OCP badging. The ecosystem partners have decided to
implement such open-source firmware as Coreboot for their OSF architecture.

Just being open-source - by itself is not enough for the firmware to meet the
OCP certification: the extra requirements are mentioned in a [OSF Checklist][5].
The source code should be easily buildable by a native (ideally the open-source)
toolchain and the flashing utility should be either open-source like [flashrom][6]
or at least documented well enough for an open-source implementation to be
written. The key OSF components have to be open-source, and although it is
allowed to include some closed-source ones (aka binary blobs) to OSF - there
should be a valid justification for them to be approved, such as "containing
silicon IP": i.e. a blob has been provided by your SV (Silicon Vendor) like
Intel to set up their chip during boot, which is needed for your device to run.
And all the documentation should be good enough and distributable without NDAs.

As you can expect, even just creating the open-source firmware for your product
is a great challenge that only a few companies in the world can complete, let
alone to maintain it in good shape and to meet all the OCP OSF certification
requirements to enter this new [rapidly growing market][7]. However: we at [3mdeb][8] -
being the [licensed provider][9] for quality Coreboot consulting services and
Independent BIOS Vendor (IBV) for [Dasharo][10] coreboot-based firmware - are surely
more than capable of helping your company to pull this off! Feel free to
[book a call with us][11] or drop us an e-mail at <contact@3mdeb.com>, and
we will do our best to help your company to reach new heights.

 [1]: https://www.opencompute.org/
 [2]: https://www.opencompute.org/membership/membership-organizational-directory
 [3]: https://en.wikipedia.org/wiki/BIOS
 [4]: https://en.wikipedia.org/wiki/Intelligent_Platform_Management_Interface#Baseboard_management_controller
 [5]: https://www.opencompute.org/wiki/Open_System_Firmware/Checklist
 [6]: https://www.flashrom.org/Flashrom
 [7]: https://www.opencompute.org/products
 [8]: https://3mdeb.com/
 [9]: https://3mdeb.com/about-us/
 [10]: https://dasharo.com/
 [11]: https://calendly.com/3mdeb/consulting-remote-meeting

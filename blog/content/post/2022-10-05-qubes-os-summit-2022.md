---
title: Qubes OS summit 2022 - Summary
abstract: 'Three weeks ago 3mdeb with Qubes OS team had organized next
          edition of the Qubes OS summit. This year summit was a face-to-face
          event hosted in Berlin, which took place from the 9th to the 11th of
          September.'
cover: /covers/qubes&3mdeb_logo.png
author: norbert.kaminski
layout: post
published: true
date: 2022-10-05
archives: "2022"

tags:
  - QubesOS
  - Conference
categories:
  - Miscellaneous
  - OS Dev

---

## Qubes OS summit 2022

In the first half of September, Invisible Things Lab with 3mdeb organized the
next edition of the Qubes OS summit. In the last years, the
[2020](https://blog.3mdeb.com/2020/2020-06-17-qubes_summation/) and
[2021](https://www.youtube.com/watch?v=uR5_FlMTbnU) editions were remote. This
year summit was a face-to-face event hosted in Berlin, which took place from the
9th to the 11th of September. It has been another productive event, during which
we have exchanged loads of knowledge and expertise.

![Qubes-poster-2022.png](/img/Qubes-poster-2022.png)

### Day 1

The first day started with the
[Welcome to Qubes OS summit 2022](https://youtu.be/hkWWz3xGqS8?t=882)
presentation held by Piotr Król. Piotr said about Qubes OS Summit history and
what changed since the last event.

The next presentation held by Marek Marczykowski-Górecki was a
[Qubes OS development status update](https://youtu.be/hkWWz3xGqS8?t=2365). In
this talk, Marek did a summary of the Qubes project. Also, he presented the
current work of his team and a rough roadmap for Qubes OS 4.2.

The next presentation was
[Building secure applications with Qubes OS](https://youtu.be/hkWWz3xGqS8?t=4719)
held by Michael Z. He presented SecureDrop Workstation which is a new and
improved front-end for journalists using SecureDrop. It was built on top of
Qubes OS and relies heavily on its features and security properties. In this
talk, Michael introduced the system and discussed some lessons learned by
treating Qubes OS as a framework for secure multi-VM applications.

After the short break Frédéric Pierret presented the
[Next generation of Qubes OS builder](https://youtu.be/hkWWz3xGqS8?t=7994) In
this talk, Frédéric presented the second generation of the Qubes OS builder.
This new builder leverages container or disposable qube isolation to perform
every stage of the build and release process. From fetching sources to building
them, everything is executed inside a "cage" (either a disposable or a
container) with the help of what we call an "executor." For every command that
needs to perform an action on sources, like cloning and verifying Git repos,
rendering a SPEC file, generating SRPM or Debian source packages, a new cage is
used. Frédéric presented the global architecture and demonstrated how to use
this new build system.

Jan Suhr presented the next interesting topic, which was
[Tailoring Qubes for Enterprises](https://youtu.be/hkWWz3xGqS8?t=10228).
Enterprises are usually a domain of Windows-only systems and users. Jan
presented how Qubes could be tailored to meet the requirements of enterprises
that rely on Windows but at the same time provide a "reasonable secure system
based on Qubes. A key requirement is to achieve a system that is usable for
users with ordinary Windows experience. Therefore the key is the integration of
a Windows VM within Qubes OS.

After the lunch break, Marta Marczykowska-Górecka presented a new
[Qubes OS Policy: Adventures in UX/UI Design](https://youtu.be/hkWWz3xGqS8?t=15275).
Marta gave a brief overview of the current state of Qubes OS policy tools, the
in-development graphical policy editor/configuration editor, the process of
simplifying the complexities of policy configuration, and design and
implementation challenges. As a continuation of last year's redesign of the
[Application Menu](https://www.youtube.com/watch?v=Wyi560JiJDI), Marta has been
working on making Qubes more accessible for non-expert users and on creating GUI
tools for system configuration that would be friendlier and easier to use than
existing tools. This time, Marta took on the challenge of creating a graphical
editor for various policy files. In this talk, she covered the results of user
research, the challenges encountered during design and implementation, and
showed off the tools created as a result of this research.

The next presentation was
[GPU Virtual Machine (GVM)](https://youtu.be/hkWWz3xGqS8?t=17671) held by Arthur
Rasmusson. GVM is a GPU Virtual Machine built by the OpenMdev Project for
IOMMU-capable computers such as x86 and ARM. In this talk OpenMdev developers,
Arthur Rasmusson and Michael Buchel gave an overview of GPU Virtual Machine
(GVM) and how it works to allow virtual machine guests to run unmodified GPU
drivers (non-paravirtual) on ordinary GPUs such as those in laptops, desktops,
embedded devices, and servers. They also took some time to talk about ongoing
efforts to improve support for devices and areas of collaboration where we might
best provide support to QubesOS for integrating OpenMdev tools like GVM for
enhanced GPU virtualization.

Puck Meerburg talked about
[Isolating GUIs with the power of Wayland](https://youtu.be/hkWWz3xGqS8?t=19969)
She tried to answer the question if Qubes OS could replace its custom GUI
isolation protocol with Wayland while staying as performant and secure. With the
advent of Wayland, many strides have been made in the desktop Linux space,
limiting the effects a malicious application can have. Gone are the days of
every application being able to snoop on every keypress. This presentation dived
into the differences between X and Wayland, and why it makes for a great fit in
isolating operating systems like Qubes OS and Spectrum.

The next presentation was
[PipeWire and Qubes Video Companion](https://youtu.be/hkWWz3xGqS8?t=22258) held
by Demi Marie Obenour. Her talk was about replacing the legacy PulseAudio-based
solution with a modern PipeWire-based one and replacing camera pass-through with
Qubes Video Companion. As Demi refereed Qubes OS currently has poor support for
audio and video capture. Audio capture works if used properly, but is easy to
misuse and its latency is excessive. Video capture is not supported except via
device pass-through, which raises serious security concerns.

At the end of day one, there was a
[Design session: graphical subsystem (GPU, Wayland)](https://youtu.be/hkWWz3xGqS8?t=24465)
hosted by Marek Marczykowski-Górecki. During the design session, summit
participants discussed common problems connected to the graphical subsystem and
proposed the solutions and PoC that were checked during the hackathon on day 3.

### Day 2

Day two started with
[Welcome to Qubes OS Summit 2022 - Day 2](https://youtu.be/A9GrlQsQc7Q?t=418).
It was a short introduction held by Piotr Król who sum up the first day and
showed the agenda for the second day.

The first speaker of the second day was Wessel Klein Snakenborg who presented
[How Dasharo coreboot-based firmware helps NovaCustom's customers](https://youtu.be/A9GrlQsQc7Q?t=1578).
NovaCustom has previously experienced a number of problems related to the
proprietary firmware of the laptop. In this talk, Wessel presented three cases
in which Dasharo open-source coreboot-based firmware has played an important
role. The first case is about the desire for a modified fan curve. The second
case study concerns an application where the customer asked whether it is
possible to disable certain CPU options, which turned out to be necessary for
audio production. The third case is about the implementation of an own startup
logo in the firmware.

In addition, there will be an explanation of the security aspects of the Dasharo
firmware that NovaCustom has recently started using. Thanks to the growing
active Dasharo community, the firmware can be increasingly optimized to the
needs of our users. Although Qubes OS already has a number of certified laptop
models, its hardware is often quite old. The need for newer hardware that is
fully compatible with Qubes OS is there, and this is where NovaCustom could play
a role with certified hardware and firmware that is fully adapted with the Qubes
OS operating system.

The next presentation was
[Qubes User Support Stories](https://youtu.be/A9GrlQsQc7Q?t=3148) held by
nestire. Nestire tried to answer the following questions during his
presentation:

- What are the most common problems?
- Where lying the biggest security traps for users?
- What needs to be done to enable a user who really should use Qubes?

After a short break, Tobias Killer presented his presentation about
[Qubes OS Documentation Localization](https://youtu.be/A9GrlQsQc7Q?t=5741). The
presentation covered the steps already taken, the current status, and the future
tasks connected to the Qubes OS documentation localization. Tobias gave a brief
look at the tech stack and the tools used to build the proposed localization
workflow. Tobias concluded with perspectives, the next steps, and an invitation
to participate in his project. The ultimate goal of this endeavor is the
continuous localization, and therefore the rapid and reliable delivery of
high-quality translations.

Michał Żygowski talked about
[Qubes OS on modern Alder Lake desktop](https://youtu.be/A9GrlQsQc7Q?t=8152)
There are very few desktop platforms that are user-controllable through
open-source firmware. Moreover, they haven't necessarily been tested with Qubes
OS. However, the recent initiative to port a modern Alder Lake desktop to
coreboot opened a new door for privacy and security respecting machines capable
of running Qubes OS. In this presentation, Michał showed a demo of Dasharo
distribution compatible with Alder Lake-S desktop MSI PRO Z690-A WIFI DDR4
running Qubes OS. He also described new updates to Dasharo firmware and
challenges awaiting future development. Michał also presented how Dasharo plans
to meet the future Qubes certification requirements and approaches the openness
of the firmware based on the Dasharo Openness Score of various supported
platforms.

The next presentation was
[Qubes OS: Towards Being a Reasonably Learnable System](https://youtu.be/A9GrlQsQc7Q?t=14609)
held by Deeplow. It was following up on last year's presentation. Deeplow
presented the final work for his contribution proposal for an integrated
onboarding tutorial for Qubes OS.

[TrenchBoot - the only AEM-way to boot Qubes OS](https://youtu.be/A9GrlQsQc7Q?t=17441)
was a second presentation held by Michał Żygowski. The presentation described
the project plan of improving and extending the Qubes OS AEM with TrenchBoot
covering both Intel and AMD hardware, TPM 1.2 and 2.0. The goal is to unify the
D-RTM early launch and Anti Evil Maid software to secure the Qubes OS boot
process for basically any hardware device (as long as it supports the required
technologies). The presenter will give a detailed overview of project phases and
tasks to be fulfilled as well as the cost outline. In the end, a short demo of
Qubes OS AEM with TrenchBoot on Dell OptiPlex 7010/9010 with Intel TXT and
TPM1.2 will be shown.

After the short break Brent Cowing was talking about
[Secure hardware for a secure operating system](https://youtu.be/A9GrlQsQc7Q?t=19620).
In this session, Brent discussed why we should care about open source firmware
and the ways we can reduce the risk of firmware persistent malware. As the world
is evermore consumed by detecting and preventing ransomware and other
financially damaging attacks on systems and organizations, far too little
attention has been paid to an attack surface common to every single
vulnerability - firmware. It’s time for the firmware to be open source and
secure.

The last presentation was held by Michał Kopeć who was talking about
[Dasharo vs vendor firmware performance on QubesOS - a comparison](https://youtu.be/A9GrlQsQc7Q?t=25694).
The presentation compared performance between Dasharo and Vendor BIOSes on
Dasharo-supported platforms, in the context of QubesOS usage. Michał attempted
to present the most significant differences that an end user will see when
installing Dasharo over the original proprietary firmware. In this presentation,
Michał showed the differences in performance as measured by a set of benchmarks,
and talk about what causes them and what challenges there are to bring
performance to a state that is competitive with the vendor BIOS. Michał also
discussed how these differences may impact QubesOS users.

During the second day, Marek Marczykowski-Górecki hosted the
[Design session: hardware requirements, firmware security](https://youtu.be/A9GrlQsQc7Q?t=21769).
During this design session, participants discussed the requirements of the Qubes
OS certification for new platforms.

### Hackathon

The last day was the time to talk and code projects connected to the topics
discussed during the design sessions. The topics were split into themes: GPU,
and Qubes OS certifications requirements for the software and for the hardware.
It was a productive time that allows us to exchange our experiences. If you're
interested in what we've done during this session I encourage you to take a look
at [the Hackathon highlights](https://youtu.be/gnWHjv-9_YM?t=109).

### Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of the used hardware platform, feel free to [book a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us an email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up for our
newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

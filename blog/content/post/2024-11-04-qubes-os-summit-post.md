---
title: 'Qubes Os Summit 2024'
abstract: 'The sixth edition of the Qubes OS Summit, organized by Invisible
Things Lab and 3mdeb, took place at the end of September'
cover: /covers/image-file.png
author: marta.witkowska, piotr.król
layout: post
published: false
date: 2024-11-04
archives: "2024"

tags:
  - QubesOS
  - conference
categories:
  - Miscellaneous
  - OS Dev

---

## Qubes OS Summit 2024

The sixth edition of the Qubes OS Summit, organized by Invisible Things Lab and
3mdeb, took place at the end of September. This year's event, held from
September 20th to 22nd, was hosted in Berlin. It was not only an in-person
gathering but also streamed live. The previous year’s conference was also hosted
in Berlin and included a live online streaming for remote participants from
[the first](https://www.youtube.com/watch?v=_UxndcxIngw&t=2s) and
[the second](https://www.youtube.com/watch?v=xo2BVTn7ohs&t=3s) day of the
summit.

The summit was highly productive, facilitating the exchange of significant
knowledge and expertise among participants. Contributions and insights shared
during the event were greatly appreciated, as they advanced discussions on
security, privacy, and open-source technologies.

## Day 1

The first day of the Qubes OS Summit 2024 began with a
[Welcome to Qubes OS Summit 2024](https://www.youtube.com/watch?v=lJFxtdan9qY)
presentation held by Piotr Król and Marek Marczykowski-Górecki. Piotr formally
acknowledged the event sponsors, expressed gratitude for their generous support,
and highlighted their crucial contributions to the event's success.

In his address, Piotr discussed the history of the Qubes OS Summit and outlined
the critical accomplishments since the last event. These remarks set the tone
for the conference, providing context on the progress made and framing the
following discussions.

The next presentation, delivered by Marek Marczykowski-Górecki, provided a
[Qubes OS development status update](https://www.youtube.com/watch?v=5j7P7E0uq0s).
In his talk, Marek offered a comprehensive overview of the Qubes project,
summarizing its current state and progress. He also outlined the work being
carried out by his team and presented a preliminary roadmap for the upcoming
release of Qubes OS 4.3.

A new concept for devices was presented: device port ID and self-identity
device. Qubes Air was brought back, and cross-host flow would be possible. There
are also many updates to Qubes tools, especially GUI agent support for Windows.

The following presentation was
[Qubes OS GUI Changes and Future Perspectives](https://www.youtube.com/watch?v=5j7P7E0uq0s)
by
Marta Marczykowska – Górecka. One key area of focus was enhancing user
experience by making the interface more intuitive and visually cohesive while
maintaining its strong security principles. Marta has been focusing on improving
the accessibility of Qubes OS for users who are not experts in the field. Her
efforts include developing graphical user interface (GUI) tools for system
configuration that are more intuitive and user - friendly than the current
options, making the system easier to navigate and configure for a wider
audience.

She discussed integrating modern design elements to align Qubes OS with
contemporary usability standards and improvements in the new devices widget,
such as automatically attaching the new device to a qube.

After the short break, Piotr started the design session:
[Enhancing OS Awarness of Hardware Security Capabilities in Qubes OS](https://www.youtube.com/watch?v=tT9ss8gQYm8&t=5s).
He highlighted how Qubes is evolving to integrate better and leverage hardware
security features to enhance system security. During the session, a fascinating
discussion arose among the conference participants, including some interfaces
for CPU assessment.

Nestire presented the talk
[Passwordless encrypted Qubes? Exploring some concepts](https://www.youtube.com/watch?v=GUOnBapSLRE&t=5s).
In his talk, he focused on possible ways to prevent attacks. This approach aims
to enhance user experience without compromising security by using
alternative, hardware-backed authentication methods in place of traditional
passwords.

At the Qubes OS Summit 2024, the talk on
[How to architect your Qubes OS with SaltStack](https://www.youtube.com/watch?v=GUOnBapSLRE&t=5s)
hosted by Benjamin Grande emphasized how SaltStack can be leveraged to automate
and manage Qubes OS configurations efficiently.

The following presentation was
[FlashKeeper: where SpiSpy meets Stateless Laptop jaded dreams: A retrofit plan first](https://www.youtube.com/watch?v=DxFceGi6C0k)
held by Thierry Laurion. Thierry pointed out the advantages of using FlashKeeper
because of its quick flashing cycles. He pointed out that for users concerned
with physical attacks on their systems, for whom easy access to SPI flash pins
may be seen as a risk, a variant including a small FPGA closely collocated with
the flash is also being developed.

The presentation delves into the convergence of two key projects: SpiSpy, a tool
for monitoring SPI flash chips, and efforts toward stateless laptops, which
eliminate sensitive data persistence. The talk outlined a retrofit plan to
enhance hardware security, particularly within the Qubes OS ecosystem.

Michał Żygowski talked about [Anti Evil Maid status and future plans](https://www.youtube.com/watch?v=5ieNhbLLTIU).
AEM is a security tool designed to protect against attacks that tamper with the
boot process of systems like Qubes OS. Michał presented an interesting case on
the performance of AEM on NovaCustom NV4x Alderlake laptop and the results he
achieved.

Marek Marczykowski-Górecki and Frédéric Pierret presented an [Update on Qubes Air](https://www.youtube.com/watch?v=V4flhwEITr4),
indicating the current issues, for example focus on Qrexec calls to other
systems anddisposable qube support.

Moreover, in this version, there is no GUI support for remote qubes, focus is on
individual VMS on both systems and not on automatically synchronizing all the
cube machines to the other. There is also a new type of Qube – a Relay Qube – a
specialized LocalVM or a RemoteVM that acts as a bridge between the local and
remote Qubes OS hosts.

At the end of day one, there was a Qubes OS Summit 2024 – Day 1 closing notes
hosted by Piotr Król who invited all conference participiants to the afterparty
at Sudblock.

## Day 2

Day two of the Qubes OS Summit 2024 began with a brief
[Welcome to Qubes OS Summit Day 2](https://www.youtube.com/watch?v=9AkBeBwxdA0)
by Piotr Król, who welcomed attendees, once again acknowledged
conference sponsors, and provided an overview of the second day’s agenda.

The first talk of the second day was
[NovaCustom: introducing the new Qubes OS certified V54 and V56 Series](https://www.youtube.com/watch?v=RV-1IR_d1Gg),
hosted by Wessel klein Snakenborg and Tijn Veldhuis. They present a roadmap for
the next few months, including, for example, developing comprehensive firmware
updates and the UEFI updates.

Tijn announced the new laptop model V56 and its specifications, including up to
96 GB of internal memory. Wessel mentioned that they are also planning a Dasharo
ACPI driver for the laptops, which provides communication between the OS and
firmware.

The following presentation,
[Implementing UEFI Secure Boot in Qubes OS: Challenges and Future Steps](https://www.youtube.com/watch?v=ZcF_RN04oq8),
was held by Piotr Król. Piotr started the talk by pointing out what UEFI Secure
Boot is and what led the open-source software to dislike it. This talk explored
the challenges and potential solutions for implementing UEFI Secure Boot in
Qubes OS. An essential part of this talk was the presentation of future steps
toward full Secure Boot support and how the community can participate in ongoing
testing, feedback, and development work. Without a doubt, the first step that
Secure Boot users can consider is choosing hardware that has better UEFI Secure
Boot.

The subsequent presentation, delivered by Neowutran
[GPU passthrough - My personal experience](https://www.youtube.com/watch?v=_OTwWvlDcgg)
showed the bugs across stack and the journay of making a Qubes OS Gaming Machine
and presented setup difficulty evolution: 2019 – 2024.

The following presentation
[Joys and sorrows of multi-VM app development: a SecureDrop Workstation case study](https://www.youtube.com/watch?v=GIZTeJU0iBY&t=10s),
delivered by Rown and Francisco Rocha. One of the more interesting aspects of
the presentation was the shift from configuration made purely by saltstack to
a new approach. Moreover using specific architectural updates as case studies,
they outlined some of the changes they made to both the design and their concept
of developing native applications for Qubes. This talk delved into the unique
complexities and insights from developing multi-virtual machine applications on
Qubes OS, focusing on the SecureDrop Workstation as an example.

After the short break, Jan Suhr led a design session
[Future of Measured Boot such as Heads](https://www.youtube.com/watch?v=ZPeidhgNBtg&list=PLuISieMwVBpL5S7kPUHKenoFj_YJ8Y0_d&index=6s).
The discussion focused on advanced techniques for measured
boot implementations and the Heads firmware, exploring both current practices
and potential developments. Jan remarked some of the concerns of Heads users,
the users want, for example, Heads in Windows support and more supported
hardware.

Thierry Laurion presented the concept of
[Safe disk states as a firmware service, what do we want](https://www.youtube.com/watch?v=It13u9UASs4&list=PLuISieMwVBpL5S7kPUHKenoFj_YJ8Y0_d&index=7),
examining how firmware can
contribute to maintaining secure and consistent disk states. The talk covered
the desired outcomes for secure firmware services, emphasizing how reliable disk
states could bolster data protection, particularly in multi-VM environments.
Thierry discussed potential approaches and outlined goals for integrating such
firmware capabilities, aiming to enhance overall system security and stability
in Qubes OS deployments.

Piotr Bartman - Szwarc talked about
[Qubes & Devices](https://www.youtube.com/watch?v=zQzZUf9Kzjs&list=PLuISieMwVBpL5S7kPUHKenoFj_YJ8Y0_d&index=8),
peripheral device handling (especially USB and block devices) in Qubes OS. He
presented on the topic of integrating and managing external devices within the
Qubes OS framework. He discussed current device compatibility, associated
security challenges, and future development paths to enhance device management.
The session highlighted approaches to ensure secure interactions between
hardware and Qubes’ virtualized environment, addressing practical use cases and
potential advancements.

Thierry's second talk of the day was
[Heads rolling release: roles of upstream and downstream forks](https://www.youtube.com/watch?v=mAb_kHrF6SQ&list=PLuISieMwVBpL5S7kPUHKenoFj_YJ8Y0_d&index=9).
Thierry’s talk underscored the
importance of collaboration in securing firmware updates and ensuring continued
innovation in open-source firmware solutions.

At the end of day one, there was a
[Qubes OS Summit 2024 - Day 2 closing notes](https://www.youtube.com/watch?v=5P1dCUNbDm8&list=PLuISieMwVBpL5S7kPUHKenoFj_YJ8Y0_d&index=10)
hosted by Piotr Król. Piotr invited all conference participiants to
the Hackathon.

## Hackathon

The last day – the Hackathon, was the time to talk and code projects connected
to the topics discussed during the design sessions. It was a productive time
that allows to exchange our experiences.

## Summary

The Qubes OS Summit 2024 brought together a vibrant community dedicated to
pushing the boundaries of secure, open-source computing. The in-depth
presentations, collaborative discussions, and hands-on hackathon underscored the
shared commitment to advancing Qubes OS and enhancing its usability, security,
and adaptability. Thanks to the support of the sponsors and the engagement of
all participants, this year's summit marked another step forward in shaping the
future of secure computing.

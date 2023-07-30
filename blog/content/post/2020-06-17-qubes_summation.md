---
title: Qubes OS & 3mdeb 'minisummit' 2020 summation
abstract: 'The second Qubes OS & 3mdeb minisummit is ahead of us. We had gone
through four evenings of topics devoted to Qubes OS, so it is time for broad
summation of the event.'
cover: /covers/qubes&3mdeb_logo.png
author: kamila.banecka
layout: post
published: true
date: 2020-06-17
archives: "2020"

tags:
  - QubesOS
  - coreboot
categories:
  - Miscellaneous
  - Security
  - Firmware


---

The second Qubes OS and 3mdeb 'minisummit' is ahead of us. We have gone through
four evenings of topics devoted to Qubes OS. It has been another fruitful and
productive event, during which we have exchanged loads of knowledge and
expertise. Below you will find list of topics, we have discussed with related
videos and broad report of each day.

- 20.05

  1. Michał Żygowski: Qubes OS on modern AMD platform -
  [recording](https://www.youtube.com/watch?v=Rw7rAPPyPPc&t=31s)
  2. Norbert Kamiński: Status fwupd/LVFS support for Qubes OS -
  [recording](https://www.youtube.com/watch?v=o_IdERo3aiE&t=984s)
  3. AMA session - [recording](https://www.youtube.com/watch?v=BSGUcW6QDYU&t=1509s)

- 28.05

  1. Piotr Król: SRTM for Qubes OS VMs -
  [recording](https://www.youtube.com/watch?v=Eip5Rts6S2I&t=2s)
  2. Michał Żygowski: Anti Evil Maid for modern AMD UEFI-based platform -
  [recording](https://youtu.be/rM0vRi6qABE?t=3)
  3. AMA session - [recording](https://youtu.be/rM0vRi6qABE?t=1904)

- 04.06

  1. Piotr Król: DRTM for Qubes OS VMs - [recording](https://youtu.be/pZF-jyJWTE4)
  2. Michał Żygowski: Anti Evil Maid for Intel coreboot-based platform -
  [recording](https://youtu.be/YE2FbFlszI4?t=9)
  3. AMA session - [recording](https://youtu.be/YE2FbFlszI4?t=1725)

- 10.06

  1. Frédéric Pierret: How to build Qubes? From components to operating system
  overview -[recording](https://www.youtube.com/watch?v=WYDfzg9T0MU)
  2. Marek Marczykowski-Górecki: Operating system testing, when it itself uses
  virtual machines - [recording](https://www.youtube.com/watch?v=kKGjtKa_zok)
  3. AMA session - [recording](https://youtu.be/kKGjtKa_zok?t=2057)

### Qubes OS future: AMD SEV and fwupd/LVFS

The first day of 'minisummit' gathered us around Qubes OS future: AMD SEV and
fwupd/LVFS, where speakers were discussing projects based on Qubes OS. The
opening presentation dedicated to
[Qubes OS on modern AMD platform](https://cloud.3mdeb.com/index.php/apps/files/?dir=/projects/3mdeb/conf_and_shows/QubesOS_3mdeb_minisummit_2020&fileid=247810#pdfviewer)
was held by [Michał Żygowski](https://blog.3mdeb.com/authors/michal-zygowski/),
Firmware Engineer in 3mdeb, Braswell SoC, PC Engines and Protectli maintainer in
coreboot who has presented Qubes on SuperMicro M11SDV-4C-LN4F superserver
platform, that has been tested with Qubes OS on board. Michał has introduced and
explained it’s features, Secure Memory Encryption (SME) and Secure Encrypted
Visualisation (SEV) with encrypted state (SEV-ES) extension and explained why
SME is better than TSME. Afterwards, we have been introduced with status of
mentioned features on Open Source, debating whether it is supported, whether it
can be used, what impact Qubes OS will have on the features or is it possible to
run SEV-enabled guests using open-source tools. Michał described briefly also
OVMF and SUSE Linux Enterprise Server support for SEV, Automatic Exits (AE) and
Non-automatic Exits (NAE). After presentation, our specialists took the floor
debating over host system protection, memory encryption on the BIOS level, XEN
support and many more issues that can be found in the video above.

The second speaker was
[Norbert Kamiński](https://blog.3mdeb.com/authors/norbert-kaminski/). Junior
Embedded Systems Engineer in 3mdeb and open-source contributor, who has
introduced us status of fwupd/LVFS support for Qubes OS. Starting with overall
information about Firmware Update and Linux Vendor Firmware Service, Norbert
described three layers of it’s architecture (system, session, internet) and
explained how exactly works secure web service used by hardware vendors to
upload firmware archives. He also presented fwupdmgr CLI, client tool for manual
update process, describing it’s role between LVFS database and fwupd. Inside
project status, sponsored by NLnet Foundation, we’ve heard about Qubes OS
support challenges and architecture solutions, architecture plan of the
fwupd/LVFS support for Qubes OS based on sys-usb, Dom0 and UpdateVM, process of
downloading and updating firmware and what is going to be done in the next steps
of development: qubes fwupdmgr script and `.cab` archives validation. After the
presentation many questions came around the topic. We were considering how
`.cab` archives are signed, Qubes Dom0 update issues, `.cab` file validation
tool, services that provide proofs of reproducibility and many more. What we
hope to do in the nearest future inside fwupd/LVFS is upstream of `qubes-fwupd`
component to Qubes OS Project repository.

### Different approaches of using RTMs in Qubes OS

The second day of the 'minisummit' was devoted to different approaches of using
RTMs in Qubes OS. [Piotr Król](https://blog.3mdeb.com/authors/piotr-krol/),
founder and Embedded Systems Consultant, has introduced
[SRTM for Qubes OSVMs](https://www.slideshare.net/PiotrKrl/srtm-for-qubes-os-vms),
covering feasibility and security of various S-RTM implementations for Qubes OS
virtual machines. Piotr has presented S-RTM, giving practical use cases and
explained how it is created on real hardware, presenting ways of moving it to
VMs. He described Xen stub domains and explained how to enable TPM in QEMU,
considering options of boot firmware, bootloaders, operating systems and Xen
version. We were broadly familiarised with libtpm-based TPM emulator swtpm, Xen
vTPMs and finally with assumptions and future ideas for 3mdeb. Among Q&A
questions specialists were debating over an option for hosting QEMU emulation
outside of QEMU and a general idea of TPM inside VM. 3mdeb is looking for
possible founding of S-RTM effort either through the foundation, commercial
agreement, or community effort.

[Michał Żygowski](https://blog.3mdeb.com/authors/michal-zygowski/) presented
[Anti Evil Maid for modern AMD UEFI-based platform](https://cloud.3mdeb.com/index.php/apps/files/?dir=/projects/3mdeb/conf_and_shows/QubesOS_3mdeb_minisummit_2020&fileid=247810#pdfviewer),
where he has explained what exactly Evil Maid attacks are and how can we protect
ourselves from them with Qubes OS Anti-Evil-Maid. Michał presented the current
status of AEM, explained what it provides and which attacks are still not
prevented. Afterwards, speaker described ways of enabling AEM in Qubes OS for
AMD platform and for TPM2 showing installation steps, sources and repositories.
During Q&A we were considering how does it work with UEFI, what differs AMD from
Intel in AEM script and more.

### DRTM in Qubes OS – not only for Dom0 but also for VMs

The third day was devoted to DRTM in Qubes OS – not only for Dom0 but also for
VMs. [Piotr Król](https://blog.3mdeb.com/authors/piotr-krol/) has introduced
[DRTM for Qubes OS VMs](https://www.slideshare.net/PiotrKrl/drtm-for-qubes-os-vms),
discussing the value and usage models of D-RTM implementation in Qubes OS. He
started presenting Root of Trust family discussing D-RTM and how does it differ
from S-RTM proceeding with an overview of boot process for Qubes OS with
Early/Late Launch scenario and Flicker session. Based on Flicker, Piotr has
proposed scenarios in which D-RTM may be used for: Platform Relaunch, Virtual
Machine Introspection technique and D-RTM, vTPM and D-RTM, Network booted vDLME
and Visual Trust level indicator for VMs. The presentation has ended with future
ideas, among others trusted system backups and migration, trusted firmware
update, dynamic RPC policy or secure storage. The broad discussion covered among
others the best way to re-establish trust in the platform. D-RTM is a vast and
complicated topic and requires much more education and development. Our work
related to
[OpenDRTM for AMD using TrenchBoot](https://nlnet.nl/project/OpenDRTM/) founded
by NLnet should move the ecosystem forward, but we are still looking at how to
advance Intel-based solutions. There is also quite a lot of work in Xen and
Linux kernel. We believe that Qubes OS minisummit 2021 should cover practical
demos of TrenchBoot as a reference open source D-RTM implementation.

The second speaker,
[Michał Żygowski](https://blog.3mdeb.com/authors/michal-zygowski/) has presented
an
[Anti-Evil-Maid for Intel coreboot-based platform](https://cloud.3mdeb.com/index.php/apps/files/?dir=/projects/3mdeb/conf_and_shows/QubesOS_3mdeb_minisummit_2020&fileid=247810#pdfviewer).
Michał described what is needed for AEM to work on Intel processors, how Qubes
OS Anti-Evil Maid works, what are installation steps, what troubleshooting steps
he himself had to go through to make AEM work, what is Intel TXT status in
coreboot and how to enable Intel TXT on other hardware.

### Qubes OS testing and development – by Qubes core developers

On the last day of minisummit Qubes core developers took the floor.
[Frédéric Pierret](https://www.qubes-os.org/team/), general packaging, CentOS
and Fedora templates maintainer, explained how to build Qubes:
[from components to operating system overview](https://cloud.3mdeb.com/index.php/apps/files/?dir=/projects/3mdeb/conf_and_shows/QubesOS_3mdeb_minisummit_2020&fileid=247810#pdfviewer).
The speaker described what is Qubes OS composed of, in terms of developing qubes
(UX, Qubes, Isolation Provider Layer), presented the choice of Fedora as Dom0
and VMs side distributions overview. In the next step, Frederic has explained
how Qubes OS developers are introducing new features, fixes, what tools do they
use and develop, on the example of Qubes builder v.1 and v.2.

The last speaker, [Marek Marczykowski-Górecki](https://www.qubes-os.org/team/),
Project lead in QubesOS has introduced operating system testing, when it itself
uses virtual machines. Marek briefly presented how to test Qubes OS, by
describing python unit tests and pytest frameworks, used inside Qubes OS with
Travis CI. He has also mentioned fuzzing tests, build tests, integration tests,
installation tests, presented openQA tool used for running tests in VM and
described missing parts of testing Qubes. During Q&A session we were considering
how the community can help extending test scope and what kind of test are the
most necessary for Qubes OS development.

## Community

From this standpoint, before we will thank you for your valuable presence during
the event sessions, we want to point out how important is your contribution for
future development of the open source projects we currently work on. Without
your mental, financial and informational support we won't be able to go as far
as we want to. Thank you for all the help we have received so far: we are proud
of being a member of the community that looks in one direction of secure
open-source solutions.

## Summary

Qubes OS & 3mdeb 'minisummit' has been a great event that triggered many
important questions and allowed the community to take an active part in the
broad discussion around covered issues. We would like to thank Marek and
Frédéric for sharing your knowledge and time through all the events. Thank you
for your cooperation and willingness to ask and answer. Great appreciation goes
towards all the community that joined our meetings and many times convinced us
that events such as 'minisummit' are important and necessary. We have exchanged
loads of knowledge and experience and we would like to meet again, on Qubes OS
and 3mdeb 'minisummit' 2021. Thank you all once again.

If you think we can help in improving Qubes OS support for your hardware, help
you with Qubes OS certification on firmware level or you looking for someone who
can boost your product by leveraging advanced features of used hardware
platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us [email](mailto:contact%3Cat%3E3mdeb%3Cdot%3Ecom). If you are interested
in similar content feel free to sign up to our
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).

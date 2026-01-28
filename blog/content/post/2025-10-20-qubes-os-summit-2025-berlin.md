---
title: 'Qubes OS Summit 2025 in Berlin: From R4.3 Features to Qubes Air Architecture'
abstract: 'Qubes OS Summit 2025 took place September 26-28 in Berlin,
          bringing together the community for talks on R4.3 updates, GUI
          improvements, infrastructure advances, and Qubes Air architecture.
          The event featured contributions from the Dasharo ecosystem including
          server firmware foundations, NovaCustom updates, UEFI Secure Boot
          progress, and TrenchBoot compatibility work. Day three hackathon
          focused on practical implementation including the Dasharo Patchqueue
          Initiative with XenServer expertise.'
cover: /covers/qubes&3mdeb_logo.png
author: piotr.krol
layout: post
private: false
published: true
date: 2025-10-20
archives: "2025"

tags:
  - QubesOS
  - Dasharo
  - conference
  - Qubes Air
  - TrenchBoot
  - UEFI Secure Boot
categories:
  - Security
  - OS Dev
  - Firmware

---

## Introduction

Qubes OS Summit 2025 happened September 26-28 in Berlin at The Social Hub.
Three days of talks, discussions, and hackathon work. The event wouldn't exist
without sponsors - [Freedom of the Press Foundation](https://freedom.press/)
and [ExpressVPN](https://www.expressvpn.com/) (Platinum Partners),
[Mullvad VPN](https://mullvad.net/) (Gold Partner), and
[NovaCustom](https://novacustom.com/), [Nitrokey](https://www.nitrokey.com/),
and [PowerUp Privacy](https://powerupprivacy.com/) (Silver Partners). Their
support made it possible to host the community and livestream talks for remote
participants.

![The Social Hub venue in Berlin](/img/qoss2025-venue-social-hub.jpg)

Behind the scenes, there's a lot of work that happens throughout the year:
negotiating venue, coordinating accommodations, planning the afterparty at BRLO
Beer Garden, and managing logistics. Special recognition to the audio-video
team - Rafał Kochanowski from 3mdeb and Stanisław Bieniek - who kept streaming
and recording running smoothly both days. And to Magda Kochanowska, who handled
attendee onboarding and kept things organized on-site. Invisible Things Lab and
3mdeb co-organized, continuing the Summit tradition since 2019.

The conference covered Qubes OS R4.3 updates ([Marek
Marczykowski-Górecki](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/WSZJ9H/)),
GUI/UX improvements ([Marta "marmarta"
Marczykowska-Górecka](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/9A8JQA/)),
infrastructure advances, and contributions from the Dasharo ecosystem. [Michał
Żygowski](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/WUJUZ8/) presented
on [server hardware/firmware foundations for Qubes
Air](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/XAWYSA/), [Kamil
Aronowski](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/PRTHGT/) on [UEFI
Secure Boot progress](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/THN3ZF/),
[Maciej Pijanowski](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/CL7STR/)
on [TrenchBoot hardware
compatibility](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/ZXDQMW/), and I
presented on [RemoteVM architecture for Qubes
Air](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/CRK7EM/). NovaCustom's
[Wessel klein
Snakenborg](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/CGL8YQ/) - a
customer and supporter whose investment brings capital for ecosystem growth -
discussed [firmware updates including Dasharo
features](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/C78C8U/). [Rafał
Wojdyła](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/TVBTND/) from ITL
covered [Windows Tools
improvements](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/BSN7GH/). Also:
[Alyssa Ross](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/VYLDUX/) on
[Spectrum OS](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/UPMP38/),
corporate deployment ([Matthias
Ferdinand](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/VC9NXC/)), EU CRA
implications ([Peter
Schoo](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/CLHTWR/)), and
infrastructure sessions on Ansible, device management, and disposable VM
performance.

Hackathon on day three: TrenchBoot HCL testing, Dasharo Patchqueue Initiative,
UEFI Secure Boot work, QubesBuilder v2 improvements, and other projects. Talk
recordings and details: [conference
schedule](https://cfp.3mdeb.com/qubes-os-summit-2025/schedule/).

## Day 1 Highlights (September 26)

![Marek Marczykowski-Górecki presenting Qubes OS 4.3 updates](/img/qoss2025-marek-presentation.jpg)

### Qubes OS 4.3 Development Update

[Marek Marczykowski-Górecki](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/WSZJ9H/)
opened with an [overview of what's coming in Qubes OS
4.3](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/SEGENM/). Many features
mentioned in this presentation got separate dedicated presentations later in
the summit. The update covered improvements across the board - disposable VM
preloading for better performance, Ansible integration for automation, and
various GUI improvements that we'd hear more about from Marta.

### GUI and UX: Design for Hackers

[Marta "marmarta"
Marczykowska-Górecka's](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/9A8JQA/)
[talk](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/Y8N9UZ/) focused on how
to contribute to GUI tools without being intimidated by the process.
Contributing to GUI tools can be daunting - it's not easy to test things on
Qubes OS, the whole OS stack is enormous, and the idea of designing an
interface is quite scary to many developers. But it doesn't have to be that
bad.

The talk started with the observation that not everyone reads manuals and
complete release notes. CLI has a high barrier to entry. GUI development
doesn't require you to be an artist, and you don't have to extensively
communicate with others if you're not comfortable with that. But you do need to
understand design fundamentals.

Marta emphasized the "happy path" concept - the typical, positive user journey
where good UX causes problems to get out of your way. Many developers have
false assumption bias about other people's skills and knowledge, and how
programs and interfaces should be used. Information architecture is crucial:
simple options first, rarely-used features should be hidden or in advanced
options. The expert bias problem is that experts think everything is important
and struggle to decide what's more critical or what isn't - they want to
explain everything.

Don't overload the interface. Most often we're not building interfaces for
ourselves - code is read more often than it's written. We're very bad at
assessing other people's skills, assuming significant knowledge on the
listener's part without accounting for our own competencies. Personas are
important. We think 80% of people are like us, but the opposite is true - most
people are not like us. Personas should help answer whether this mechanism or
interface will work for that user. Users adapt to developers, and developers to
users - sometimes.

Attention span matters. Developers remember more details naturally, but users
can be distracted at any moment. Always remind them what each option is for and
why. Global Config is a good example where each option has smaller text
explaining what, how, and why. When deleting a qube, confirmation requires
typing the name - things happen accidentally, so we shouldn't give "Yes/No" or
"Accept/Cancel" confirmation windows because those get ignored.

Consistency is important. Default or most-used action buttons go on the left
side, colored blue. Alignment and symmetry provide better UX. Things that are
related should be close together, distant things aren't related - grouping
matters. PenPot is probably the best FOSS tool for interface sketches. There's
a component library for Qubes. Lucide.dev is a good tool for icons - creating
icons is very difficult.

### Corporate Deployment: Have Your Qubes and Keep It?

[Matthias
Ferdinand](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/VC9NXC/)
[presented](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/UFJLJM/) on using
Qubes OS as admin workstations in their corporate IT environment. This was one
of the best talks at the summit. Using Qubes requires some changes on both
sides - adapting corporate processes for Qubes and adapting Qubes usage for
corporate requirements - while trying not to ruin security on either side. Surely
there is room for improvement.

The discussion touched on practical challenges of deploying Qubes in an
environment where IT infrastructure expects certain patterns and behaviors. How
do you handle corporate authentication? How do you manage policy for users who
need access to internal resources while maintaining Qubes' isolation model? The
talk was valuable because it came from real-world experience, not theoretical
deployment scenarios.

### Spectrum OS: Rethinking Compartmentalization

[Alyssa Ross](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/VYLDUX/) is
the founder and project lead of Spectrum, an in-development compartmentalized
operating system. It's heavily inspired by Qubes OS, but also does a lot of
things differently. The
[talk](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/UPMP38/) highlighted
differences between Spectrum and Qubes OS, with particular focus on user and
developer experience, explaining the reasoning behind those differences and
what Qubes OS might be able to take from Spectrum's experience doing things
differently.

Particular areas covered included Spectrum's immutable host system and purely
functional build process, tight integration between base OS, desktop
environment, and VMs, use of XDG Desktop Portals, and focus on avoiding the
need for system maintenance work from users. It's interesting to see what
architectural choices someone makes when building a compartmentalized OS from
scratch with the benefit of hindsight from Qubes' development.

### Alternative Qube Ownership Visualization

[Ali Mirjamali](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/MW7N7N/)
(presenting online) shared his personal quest of implementing alternative
approaches to the default 8 label colors. The work includes tools to create and
manage additional label colors (and why it matters), alternate icons for the
App Menu, alternative effects to the default tint (overlay, thin/thick
borders/untouched/invert/compositor), sending windows of specific qubes to
designated workspaces, and alternate border styles (solid/dash/dot/...). [Talk
details and
video](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/KBT3UM/)

### The Future of Qube Manager: Design Session

Marta and [Christopher
Hunter](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/LX3WFZ/) from Ura
Design led a [design
session](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/VSWRFV/) on the future
of Qube Manager. The history of Qube(s) Manager is long and fraught - for a brief
time it was even completely removed, until popular outcry summoned it back.
This session discussed with the community possible futures and ideas for how a
Qubes OS installation should be managed.

### Using Segregation to Hyper-Secure Development Environments

[Rene Malmgren](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/GZKBBY/)
[discussed](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/VHAQMX/) what we
can learn from threats like SolarWinds and Bybit/Safe, as well as high-end
vulnerabilities like libXv and regreSSHion. After four years at Ericsson and
now one year in the crypto industry, he presented how segregated operating
systems like Qubes can be deployed to protect important assets such as
cryptographic keys - making them resistant to even the most advanced actors.

## Dasharo Ecosystem Impact

### Server Hardware and Firmware Foundations for Qubes Air

[Michał Żygowski](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/WUJUZ8/)
presented on [Qubes Air: Hardware, Firmware, and Architectural
Foundations](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/XAWYSA/). The talk's
goal was to start discussion about Qubes Air and Qubes OS Hardware Certification
for server-class hardware - something that will be inevitable in the Qubes Air
world where compute resources are distributed across multiple physical systems.

Modern server platforms offer significant advantages over desktop hardware:
expanded PCIe capabilities, non-standard high-performance connectors like MCIO,
massive RAM capacity, and Baseboard Management Controllers (BMC). These
bleeding-edge features are exactly what Qubes Air will need for distributed
compartmentalization at scale.

Two concrete platforms are progressing toward Qubes OS Hardware Certification.
ASRock Rack's [SPC741D8](https://docs.dasharo.com/variants/asrock_spc741d8/overview/)
already ships with Dasharo firmware support. The Gigabyte MZ33-AR1 with AMD
Turin EPYC processors is targeted for Q4 2025 - ongoing [porting work
documented in blog posts](https://blog.3mdeb.com/tags/mz33-ar1/) covers PCIe
initialization, AMD PSP blob analysis, and USB/SATA port mapping. This platform
represents the newest generation of AMD server processors with OpenSIL support.

Security improvements for server platforms include ZarhusBMC - an open-source
BMC replacement planned to replace proprietary solutions, enabling verifiable
security properties. Platform Firmware Resiliency (PFR) provides additional
protection against firmware attacks. AMD's Secure Encrypted Virtualization (SEV)
features offer auditable code for memory encryption, which could significantly
improve security for Qubes Air's distributed VM model.

Why does open-source firmware porting and Qubes OS Hardware Certification matter
from a firmware perspective? This is the foundation for trustworthy server
platforms. Without certified, auditable firmware stacks, Qubes Air's security
model breaks down - you can't compartmentalize trust if the underlying platform
firmware is opaque.

### NovaCustom Firmware Updates

![Collaboration at the venue](/img/qoss2025-hackathon-collaboration.jpg)

On Day 2, [Wessel klein
Snakenborg](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/CGL8YQ/) from
NovaCustom [presented
updates](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/C78C8U/) on Intel Boot
Guard fusing, HSI levels, Capsule Updates and new products. We started
presentations on time with Wessel, who presented information on products and
functionality introduced over the last year:

- NUC Box initial release
- Dasharo TrustRoot
- HSI level 3
- UEFI Capsule update
- Dasharo ACPI in kernel v6.16
- A lot of bug fixes

Plans include AMD somewhere in 2026. Servers and tablets are in plans. Dasharo
TrustRoot was presented and explained. The ACPI Dasharo driver delivers quite a
lot of quality-of-life functions, more than typical developers assume: fan
speed, temperature, backlight control feedback, profiles, power management,
etc.

UEFI Capsule Update for Dasharo and EC firmware which both can be flashed from
coreboot before locks are applied. Upcoming DTS will switch to Capsule Updates
and with that support we should also see LVFS/fwupd support. A discount code
was offered for NovaCustom products to all participants.

Dasharo TrustRoot is a feature requested by Marek and Demi during Qubes OS
Summit 2024, so we can claim "delivered". The difference from initial request
is that firmware is signed not by firmware developers, but by NovaCustom.

Regarding all delays on firmware features roadmap we just wanted to admit that
most is on 3mdeb, so apologies for that.

It is important to highlight role that NovaCustom's support play in ecosystem.
Thank you for bringing resources that enables continued ecosystem growth.

### Qubes Air: Value Proposition and RemoteVM PoC

I presented [Qubes Air: Opinionated Value Proposition for Security-Conscious
Technical
Professionals](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/CRK7EM/)
([video](https://www.youtube.com/watch?v=ie2VvBS5R4I),
[slides](https://cfp.3mdeb.com/media/qubes-os-summit-2025/submissions/CRK7EM/resources/qubes-air-opinionated-value-prop_cP1jChA.pdf)).
Building on Michał's hardware foundations talk, this session outlined an
opinionated vision for Qubes Air vertical integration targeting
security-conscious technical professionals: security researchers, developers,
privacy advocates, and SMEs in the surrounding ecosystem.

The presentation was grounded in threat model work funded by PowerUp Privacy
and reviewed by Whonix/Kicksecure maintainers. The threat model defines three
key actors: Experts (maintainers of security-related software, incident
response teams), Adversaries (internal or external), and Auditors (governments,
certification organizations, insurers). For systems where trustworthiness is a
requirement not an option, controlling the Root of Trust and Chain of Trust
becomes critical.

The talk explored vertical integration of secure thin clients and robust
servers equipped with Dasharo firmware and Qubes OS. Key focus areas included
leveraging qrexec-based RemoteVM capabilities for secure delegation of
sensitive workloads - cryptographic operations, blockchain development, malware
analysis, and secure coding environments. The preliminary RemoteVM PoC
demonstrates that Qubes OS R4.3 contains working service calls to RemoteVM,
proving technical feasibility. Implementation strategies for attestation using
TrenchBoot ecosystem were discussed for verifiable platform integrity.

The RemoteVM/qrexec demo of copying file from local VM to remote one leveraging
qrexec policy checks worked impressively well in testing, though there wasn't
time to show it live during the presentation. The intentionally fast-paced
delivery was designed to serve as an investor-focused pitch and reference point
for future discussions with community and customers, highlighting both the
practical path forward and high-value security outcomes achievable through
targeted ecosystem integration.

During Q&A, xcp-ng interest emerged, leading to realization that the presented
model should be adopted in other virtualization platforms. Building a
trustworthy ecosystem without architecture patterns like Qubes Air would be
very difficult.

### UEFI Secure Boot Progress

[Kamil Aronowski](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/PRTHGT/)
gave an [update on UEFI Secure Boot in Qubes
OS](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/THN3ZF/). He started with
introduction and explanation of UEFI Secure Boot including mention of recent
issues. UKI support didn't land in Qubes R4.3, so we have to wait longer. Kamil
very quickly jumped into details with the hat of shim-reviewer, showing how we
check things like the `.reloc` section.

Some Xen issues were addressed - there is active development regarding Xen
support for UEFI Secure Boot. Kamil nicely connected early communication from
[my presentation on Xen Winter Meetup
2025](https://cfp.vates.tech/xen-meetup-2025/talk/8JBQKC/), giving a pitch
about Zarhus Provisioning Box. ZPB was mentioned very shortly.

### TrenchBoot: Can It Run?

[Maciej
Pijanowski](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/CL7STR/) started
his [talk](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/ZXDQMW/) with a very
brief introduction to TrenchBoot. Then Maciej discussed hardware requirements:
fTPMs vs dTPM. Microsoft distinguishes TPMs even more: iTPM and fTPM, where
iTPM is an IP block in SoC and fTPM is software/firmware running in other
firmware (ME/PSP).

Then Maciej explained Intel TXT support - what does it mean, how many things have
to align to make it work. Maciej was essentially explaining that if you want to
prove if TrenchBoot can work, there are so many factors it is unlikely to check
without trying on real hardware. So you can see that offering Qubes OS
AEM-enabled hardware is not that easy.

Maciej introduced [meta-trenchboot](https://github.com/zarhus/meta-trenchboot)
based image for booting using USB, which can be used for testing. He presented
test results for v0.5.2. Modern (Zen and newer) AMD are not supported. The
meta-trenchboot HCL needs better marketing and inclusion in DTS, but that is
not that simple, because to realize quality of DRTM implementation we have to
boot platform couple times with different set of bootloader, hypervisor and
kernel. 3mdeb would like to gather results as we gather HCL for Dasharo and
thenks to that deliver hardware offering that can meet TrenchBoot needs. Parto
of that was Maciej's help during the hackathon to run TrenchBoot HCL to gather
more results.

## Day 2: Infrastructure, Automation, and Technical Deep Dives (September 27)

### Qubes Windows Tools: Present and Future

[Rafał Wojdyła](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/TVBTND/)
gave an [introduction to Qubes Windows
Tools](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/BSN7GH/), which are
mostly functional for Windows 10 and 11. Windows 7 support was dropped. There
is a discrepancy between what windowing API is reporting and reality - there are
undocumented flags used by Microsoft applications. Some windows by API status
should be visible but in reality they are not, kind of a cloak mode.

There are some improvements in the Windows installer, which was rewritten in
WiX4. The most important improvement is automatic approval of the test-sign
driver popup. QubesBuildv2 support was another important improvement. Release
signed code and performance optimizations are in the plans for future. The GUI
agent is spaghetti code, so it won't be an easy task.

### Recent Advances in Device Management

[Piotr
Bartman-Szwarc](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/33Q7W8/)
presented the [latest improvements in peripheral device
handling](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/BBGGBC/)
([video](https://www.youtube.com/watch?v=KE_2lNX3n1w)) in Qubes OS, focusing on
USB, block devices, and PCI. The talk explored architectural changes, security
implications, and user experience enhancements introduced in recent updates.

Device identification in Qubes relies on three elements: port ID, device ID,
and the backend qube to which the device is connected. This identification
scheme enables proper device routing and security isolation.

A key point of confusion that Piotr clarified is the distinction between device
attachment and device assignment - two different concepts with different use
cases:

**Attachment** is for everyday device management and manual use. You attach a
device when you need it right now. This approach is prone to human error
(misclicks) and only works when the device is physically present in the system.
It's the typical workflow for USB drives, cameras, or other peripherals you
occasionally connect.

**Assignment** is for automation and permanent system configuration. Assignments
can be configured even when the device isn't physically attached to the system.
This makes the most sense for vault qubes where you want to permanently route
specific hardware like HSM tokens or USB cryptographic devices. When the device
is plugged in, it automatically goes to the correct qube without manual
intervention.

Piotr presented a compatibility matrix showing which device types can be
attached versus assigned, helping users understand the capabilities and
limitations of each approach for different hardware categories (USB, block,
PCI).

### Qubes OS CI Review

Marek Marczykowski-Górecki gave a [talk about CI used by Qubes
OS](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/3BVSTJ/). Frédéric
contribution was custom integration to be able to leverage code from forks.

Qubes OS uses multiple runner types: docker, VM based on KVM, as well as Qubes
VM (including Windows). There's also vm-kvm - KVM with nested virtualization -
which allows running Qubes in VM. This is Xen on KVM, not the other way around,
but Xen works on it. Xen project works on being able to run KVM in Xen.

Arsenal for CI and validation is extensive. There are a bunch of unit tests for
Python tools and linters. There is some fuzzing from Google. Build tests do
reproducible tests, installing in a container, catching trivial errors.

Here we can bring paranoia level of build environment reproducibility, if what
we already have is not enough. And I mean things like
[Guix](https://guix.gnu.org/en/) or even [StageX](https://stagex.tools/). By
definition build environment is not part of reproducibility, but it really
depends on software supply chain paranoia. In Qubes OS not everything is
reproducible yet.

Other important tool is openQA, which is used for integration testing. It is
essentially clicking on the screen. Other tests write commands to run Python
tools. openQA has a good presentation layer for test results. End-to-end tests
for split-gpg, where there is email signing and then checking if it was
received and correctly signed and encrypted sound quite impressive. It helps a
lot with installation. Interesting stuff is that openQA adds comments to the
package updates on GitHub as test results thanks to its integration with CI.

There are compatibility tests for Qubes OS Certified Hardware, performance
tests, and Windows tests, as well as some specific tests. Windows installation
test was 4 hours or something like that, but that is too slow on nested
virtualization.

New thing is also Orange Pi 5B based on RK3588 as the new controller added to
support 4K. There is very limited testing of GPU - performance of sys-gui-gpu
is low, 18fps, half of the native. There is a test for WiFi testing. Some tests
and hardware platforms are participating in Xen Project CI. Automatic bisection
is implemented.

### Documentation and Localization

[m](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/FMYV33/) and [Tobias
Killer](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/NVR97L/) gave a
[presentation about updates in
documentation](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/R7B77L/), its
quality assurance, and the difference between Read The Docs, Sphinx, and rST:

- RTD was chosen since it has a lot of useful features, and Qubes switched to
it recently. Translation was one of the most important features needed.
- Issues with Markdown admonitions were mentioned between the lines.
- Evaluation criteria defined for qualification of automatic translation were
established.
- There is already Ollama running on Jetson Nano where we can call it through
qubes.ConnectTCP a la Qubes Air.

All of that and more in already classical talk about so important aspect as
Qubes OS documentation.

### Ansible in Qubes OS

[Frédéric Pierret](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/YESJU7/)
gave a [talk](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/ULSH3A/) starting
with explaining Ansible vs Salt. Ansible use is known in corporate
environments. Ansible support started with kushaldas working in 2018, where an
Ansible connection plugin was written from scratch. In 2024, Qubes 4.2 got
Ansible 7.7 compatibility. In 2025, Qubes R4.3 got official integration - CI
and packaging was added. ITL's customers requested Ansible and it is now on its
way to replace Salt in long run.

The `qubes_proxy` proxies Ansible execution through a management disposableVM,
sanitized with qrexec. Limitations include that access to facts and variables
from other hosts is not possible. What is good is that there are safeguards for
using incorrect strategy for execution. Bootstrapping needs installation of
packages.

Remote management is possible à la Qubes Air through mgmt VM with predefined
connections like in the RemoteVM example presented in the Qubes Air PoC. It
would be ideal to reproduce configuration of PoC communication.

Whole solution seem to be sound. The only regret could be years of work while
integrating Salt and migration of all production quality stuff to Ansible.
Hopefully Ansible will stay with us for longer.

### Even More Control: Device Widget Updates

[Marta's second
talk](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/JGVEWM/) on Day 2 (Saturday)
focused on practical device widget improvements. She showed the evolution of
device widgets across Qubes OS versions: 4.0, 4.2, and 4.3. The most notable
improvement is a way to not show child devices, which addresses the annoying
problem of too many partitions cluttering the interface. For storage devices
with multiple partitions, this decluttering significantly improves usability.

The talk highlighted device assignment as a valuable feature for specific use
cases.

One repeating inquiry was about setting up conferencing equipment - forgetting to
switch microphone and headset between qubes takes multiple iterations every
time. This was why Matthias (from the corporate deployment talk) requested a
dedicated conference VM.

Device assignment UI is planned for Qubes OS R4.3, making it easier to
permanently configure device routing for specific workflows.

### Fast and Fresh Disposable Qubes

After some technical issues related to cooperation between eDP, HDMI, and
projector, [Ben
Grande](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/EAYSRB/)
[presented](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/FCJLF7/) on
disposable VM preloading. He explained difference between named vs unnamed
disposable VMs - the point is that the first do not close after closing the
app, unnamed are closed. Right now time is "almost instant" and it is biggest
achievement of Ben work.

Ben described couple considered approaches to solve problem of fast disposable
qube. Suspend to disk deemed to be unreliable, same for Xen VM forking.

Preloading and pausing is the method building on existing Qubes infrastructure.
On startup there is waiting for the system to be fully operational, then pause
VMs. There are some options for preload: `preload-dispvm-{max, threshold}`.
Enabling the option preloads a number of disposables until some threshold of
free memory is crossed.

Real gain is 2x-9x. There are various situations where things can fail:
insufficient memory, failure to preload, outdated volumes, interrupted qubesd.
R4.3 has it enabled if >15GB of available space.

## EU CRA: Seven Ways to Profit from Qubes OS

[Peter Schoo](https://cfp.3mdeb.com/qubes-os-summit-2025/speaker/CLHTWR/) gave
a very important and insightful [talk about details of where we are in EU CRA
legislation](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/RLYLSR/). This
presentation was not recorded and not streamed. Peter is a BSI expert
contractor with a mission to inform the Qubes OS community and not only about
EU CRA impact.

Questions and discussions covered several critical topics:

What is in and our of scope of EU CRA.

Training and content creation is out of scope. Any devops and automation which
is delivered to clients may apply if you create and distribute tooling
(Ansible, Salt). This is a gray zone a little bit - if this is a product or
service, it really depends on profit, which is different from income (are you
greedy?). Creation of tools and selling pre-configured machines also falls into
this.

How can you give users freedom to deliver their own Root of Trust and Chain of
Trust if you cannot ship that hardware? Probably transfer of ownership has to
be employed. How does EU CRA see organizations which would like to help in RoT
and CoT provisioning and maintenance? ISO 62304 relation and more.

December 11, 2027 is the time for setting things in stone. How should upstream
and downstream vulnerabilities be handled? This radically increases the cost of
products.

We appreciate the initiative and motivation to come to the QOSS event to
educate us about the EU CRA.

## Hackathon Results (September 28)

![Hackathon TODO list](/img/qoss25_hackathon.jpg)

Day three was dedicated to hands-on hackathon work. Based on the goals
whiteboard, several projects made progress:

**Dasharo Patchqueue Initiative** (Andrew Cooper, Piotr Król, Michał Żygowski,
Maciej Pijanowski): This consumed most of my time during the hackathon.
Together with Michał and Maciej, we received a lecture from Andrew Cooper on
how to maintain a patch queue based on his experience from the [XenServer
xen.pg project](https://github.com/xenserver/xen.pg). Learning from someone
with that level of experience in patch queue management for Xen was incredibly
valuable for our Dasharo firmware work. This took all my time, so I couldn't
work on RemoteVM PoC reproduction that I had planned.

**TrenchBoot HCL Reports** (Maciej): Gathering hardware compatibility reports
for TrenchBoot/AEM. The meta-trenchboot USB testing image introduced during
Maciej's talk was used to collect real-world compatibility data across
different hardware platforms.

**UEFI Secure Boot Development** (Kamil): Continued work on UEFI Secure Boot
implementation, building on the progress discussed in his Day 2 talk.

**QubesBuilder v2 + Debian/Podman** (Yann D): Build system improvements
focusing on Debian integration and Podman support for QubesBuilder version 2.

**Runtime Suspend Patch Review** (Vertex, Andrew, Simon): High-level review of
PCIe passthrough suspend improvements - addressing one of the pain points with
device management and power states.

**Easy VPN Setup Tool** (Marta): Quality-of-life tooling to simplify VPN
configuration in Qubes, addressing a common user pain point.

The hackathon demonstrated the practical side of the summit - moving from talks
and discussions to concrete implementation work and collaboration across
different areas of the Qubes ecosystem.

## Reflections and Observations

A note on event timing: It seems that a lot of people attended in commercial
capacity on Friday. A survey was sent after the summit to gather feedback on
this and other aspects, which will lead to adjustments for future events.

The summit showed maturity in several areas: comprehensive CI/testing
infrastructure (Marek's CI talk), improving documentation processes (m and
Tobias), and proactive engagement with regulatory challenges like EU CRA (Peter
Schoo). The Qubes Air architecture emerged as a recurring theme across multiple
talks - from Michał's server hardware foundations, to my RemoteVM presentation,
to Frédéric's Ansible remote management PoC. This suggests the community is
converging on distributed computing patterns that extend Qubes beyond single
workstations.

Corporate adoption challenges (Matthias Ferdinand) highlighted practical gaps
that need addressing: proxy configuration as a first-class citizen, flexible IP
address pool allocation, system-wide CA deployment, and better videoconferencing
VM support. These aren't just enterprise nice-to-haves - they're requirements for
broader adoption.

The Dasharo ecosystem's role in hardware enablement continues to expand: server
firmware foundations (Michał), NovaCustom customer adoption bringing capital
and validation (Wessel), TrenchBoot compatibility work (Maciej), UEFI Secure
Boot progress (Kamil), and the Patchqueue Initiative learning from XenServer
experience (Andrew Cooper). The ecosystem needs this kind of sustained firmware
and hardware certification work to make Qubes viable on modern platforms.

The comparison with Spectrum OS (Alyssa Ross) was valuable - seeing different
architectural trade-offs (KVM vs Xen, image-based vs customizable,
Wayland-native) helps both projects learn from each other. Competition and
diversity in compartmentalized OS development is healthy for the market and
drives innovation.

Overall, the summit balanced technical depth with practical deployment
concerns, bringing together firmware developers, OS maintainers, corporate
users, and security researchers. The afterparty at BRLO Beer Garden provided
space for informal discussions that often lead to future collaborations.

We looking forward for Qubes OS Summit 2026 for which organization should start
soon.

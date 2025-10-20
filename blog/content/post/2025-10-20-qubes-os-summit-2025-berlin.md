---
title: 'Qubes OS Summit 2025 in Berlin: From R4.3 Features to Qubes Air Architecture'
abstract: 'Qubes OS Summit 2025 took place September 26-28 in Berlin, bringing together the community for talks on R4.3 updates, GUI improvements, infrastructure advances, and Qubes Air architecture. The event featured contributions from the Dasharo ecosystem including server firmware foundations, NovaCustom updates, UEFI Secure Boot progress, and TrenchBoot compatibility work. Day three hackathon focused on practical implementation including the Dasharo Patchqueue Initiative with XenServer expertise.'
cover: /covers/qubes-summit-2025.jpg
author: piotr.krol
layout: post
published: false
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

Qubes OS Summit 2025 happened September 26-28 in Berlin at The Social Hub. Three days of talks, discussions, and hackathon work. The event wouldn't exist without sponsors—Freedom of the Press Foundation and ExpressVPN (Platinum Partners), Mullvad VPN (Gold Partner), and NovaCustom, Nitrokey, and PowerUp Privacy (Silver Partners). Their support made it possible to host the community and livestream talks for remote participants.

Behind the scenes, there's a lot of work that happens throughout the year: negotiating venue, coordinating accommodations, planning the afterparty at BRLO Beer Garden, and managing logistics. Special recognition to the audio-video team—Rafał Kochanowski from 3mdeb and Staszek—who kept streaming and recording running smoothly both days. And to Magda, who handled attendee onboarding and kept things organized on-site. 3mdeb and Invisible Things Lab co-organized, continuing the Summit tradition since 2019.

The conference covered Qubes OS R4.3 updates (Marek Marczykowski-Górecki), GUI/UX improvements (Marta "marmarta" Marczykowska-Górecka), infrastructure advances, and contributions from the Dasharo ecosystem. Michał Żygowski presented on server hardware/firmware foundations for Qubes Air, Kamil Aronowski on UEFI Secure Boot progress, Maciej Pijanowski on TrenchBoot hardware compatibility, and I presented on RemoteVM architecture for Qubes Air. NovaCustom's Wessel klein Snakenborg—a customer and supporter whose investment brings capital for ecosystem growth—discussed firmware updates including Dasharo features. Rafał Wojdyła from ITL covered Windows Tools improvements. Also: Alyssa Ross on Spectrum OS, corporate deployment (Matthias Ferdinand), EU CRA implications (Peter Schoo), and infrastructure sessions on Ansible, device management, and disposable VM performance.

Hackathon on day three: TrenchBoot HCL testing, Dasharo Patchqueue Initiative, UEFI Secure Boot work, QubesBuilder v2 improvements, and other projects. Talk recordings and details: [conference schedule](https://cfp.3mdeb.com/qubes-os-summit-2025/schedule/).

## Day 1 Highlights (September 26)

### Qubes OS 4.3 Development Update

Marek Marczykowski-Górecki opened with an overview of what's coming in Qubes OS 4.3. Many features mentioned in this presentation got separate dedicated presentations later in the summit. The update covered improvements across the board—disposable VM preloading for better performance, Ansible integration for automation, and various GUI improvements that we'd hear more about from Marta.

### GUI and UX: Design for Hackers

Marta "marmarta" Marczykowska-Górecka's talk focused on how to contribute to GUI tools without being intimidated by the process. Contributing to GUI tools can be daunting—it's not easy to test things on Qubes OS, the whole OS stack is enormous, and the idea of designing an interface is quite scary to many developers. But it doesn't have to be that bad.

Marta introduced the testing tools Qubes OS has that can be useful for GUI development, explained how to find design patterns for more consistent GUI applications, and gave a brief introduction to Design for Hackers—how to make GUI tools that don't suck without reading a stack of books on design and human brain. Nobody can become a great interface designer in half an hour, but there are many typical pitfalls developers fall into when trying to make a workable user interface.

Later in the day, Marta showed the evolution of the device widget across versions (4.0, 4.2, 4.3). There's now a way to not show child devices, which helps with the problem of too many partitions being annoying. Where will those child devices be visible? It always takes a couple iterations to setup conferencing—forgetting to switch my mic and headset between qubes. That's why there was a request from industry (Matthias) to create a conference VM, and I guess device assignment would be a very useful feature for that. There is UI for assignments now. Can I save current attachment to convert it to assignment? TODO: create issue for that.

### Corporate Deployment: Have Your Qubes and Keep It?

Matthias Ferdinand presented on using Qubes OS as admin workstations in their corporate IT environment. This was one of the best talks at the summit. Using Qubes requires some changes on both sides—adapting corporate processes for Qubes and adapting Qubes usage for corporate requirements—while trying not to ruin security on either side. Surely there is room for improvement.

The discussion touched on practical challenges of deploying Qubes in an environment where IT infrastructure expects certain patterns and behaviors. How do you handle corporate authentication? How do you manage policy for users who need access to internal resources while maintaining Qubes' isolation model? The talk was valuable because it came from real-world experience, not theoretical deployment scenarios.

### Spectrum OS: Rethinking Compartmentalization

Alyssa Ross is the founder and project lead of Spectrum, an in-development compartmentalized operating system. It's heavily inspired by Qubes OS, but also does a lot of things differently. The talk highlighted differences between Spectrum and Qubes OS, with particular focus on user and developer experience, explaining the reasoning behind those differences and what Qubes OS might be able to take from Spectrum's experience doing things differently.

Particular areas covered included Spectrum's immutable host system and purely functional build process, tight integration between base OS, desktop environment, and VMs, use of XDG Desktop Portals, and focus on avoiding the need for system maintenance work from users. It's interesting to see what architectural choices someone makes when building a compartmentalized OS from scratch with the benefit of hindsight from Qubes' development.

### Alternative Qube Ownership Visualization

Ali Mirjamali (presenting online) shared his personal quest of implementing alternative approaches to the default 8 label colors. The work includes tools to create and manage additional label colors (and why it matters), alternate icons for the App Menu, alternative effects to the default tint (overlay, thin/thick borders/untouched/invert/compositor), sending windows of specific qubes to designated workspaces, and alternate border styles (solid/dash/dot/...). [Talk details and video](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/KBT3UM/)

### The Future of Qube Manager: Design Session

Marta and Christopher Hunter from Ura Design led a design session on the future of Qube Manager. The history of Qube(s) Manager is long and fraught—for a brief time it was even completely removed, until popular outcry summoned it back. This session discussed with the community possible futures and ideas for how a Qubes OS installation should be managed. [Session details](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/VSWRFV/)

### Using Segregation to Hyper-Secure Development Environments

Rene Malmgren discussed what we can learn from threats like SolarWinds and Bybit/Safe, as well as high-end vulnerabilities like libXv and regreSSHion. After four years at Ericsson and now one year in the crypto industry, he presented how segregated operating systems like Qubes can be deployed to protect important assets such as cryptographic keys—making them resistant to even the most advanced actors. [Talk details](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/VHAQMX/)

## Dasharo Ecosystem Impact

### Server Hardware and Firmware Foundations

Michał Żygowski presented on [Qubes Air: Hardware, Firmware, and Architectural Foundations](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/XAWYSA/), starting with an introduction to modern server hardware. Server platforms have way more expansion capabilities—PCIe, non-standard connectors like MCIO, significant amounts of RAM, and BMC. The benefits of using server platforms include access to bleeding-edge features.

ASRock Rack is ready for Qubes OS certification. A rough roadmap for shipping Dasharo was presented: MZ33-AR1 is planned for Q4'25, while ASRock was already shipped. ZarhusBMC is planned to replace proprietary BMC, which would enable some security properties to be gained. There's also PFR (Platform Firmware Resiliency) which could improve security for server platforms.

Michał described nice SEV (Secure Encrypted Virtualization) features, code for which is auditable, which could largely improve security. He also discussed how those features could help in implementing Qubes Air. Why is porting of open-source firmware and getting through Qubes OS Hardware Certification from a firmware perspective so important? This is the foundation for trustworthy server platforms.

### NovaCustom Firmware Updates

On Day 2, Wessel klein Snakenborg from NovaCustom presented updates on [Intel Boot Guard e-fusing, HSI levels, Capsule Updates and new products](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/C78C8U/). We started presentations on time with Wessel, who presented information on products and functionality introduced over the last year:

- NUC Box initial release
- Dasharo TrustRoot
- HSI level 3
- UEFI Capsule update
- Dasharo ACPI in kernel v6.16
- A lot of bug fixes

Plans include AMD somewhere in 2026. Servers and tablets are in plans. Dasharo TrustRoot was presented and explained. The ACPI Dasharo driver delivers quite a lot of quality-of-life functions, more than typical developers assume: fan speed, temperature, backlight control feedback, profiles, power management, etc.

UEFI Capsule Update means EC can be flashed from coreboot. DTS will switch to Capsule updates. CalyxOS was changed because the OS is dying—maybe GrapheneOS? The plan is to have kill switches and various customization options. UNITE message: join the community. A discount code was offered.

Corrections from the talk: Dasharo TrustRoot is a feature requested by Marek and Demi during Qubes OS Summit 2024, so we delivered. Firmware is signed not by firmware developers, but by NovaCustom. Delays are on 3mdeb, so apologies for that.

NovaCustom's support as a customer brings capital that enables continued ecosystem growth.

### My Talk: Qubes Air Value Proposition

I presented [Qubes Air: Opinionated Value Proposition for Security-Conscious Technical Professionals](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/CRK7EM/). It went not too bad. The demo worked impressively nice, though there wasn't time to show it live. The presentation was intentionally fast-paced to serve as a reference point for future discussions with community, customers, and investors.

Most questions were about the demo or experiments I made testing the solution, which worked impressively well. Unfortunately, I didn't have time to show that during the presentation. There were already complaints that I was running quite fast through the presentation and not everything could be grasped easily. That was intentional—I wanted that presentation as a reference point for future discussions with community, customers, and investors.

During questions I was very happy to get xcp-ng interest, and I think we realized that the presented model or architecture should be adopted in other places, because it would be hard to build a trustworthy ecosystem without architecture like Qubes Air.

### UEFI Secure Boot Progress

Kamil Aronowski gave an [update on UEFI Secure Boot in Qubes OS](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/THN3ZF/). He started with introduction and explanation of UEFI Secure Boot including mention of recent issues. UKI support didn't land in Qubes R4.3, so we have to wait longer. Kamil very quickly jumped into details with the hat of shim-reviewer, showing how we check things like the `.reloc` section.

Some Xen issues were addressed—there is active development regarding Xen support for UEFI Secure Boot. Kamil nicely connected early communication from my presentation, giving a pitch about Zarhus Provisioning Box. ZPB was mentioned very shortly.

### TrenchBoot: Can It Run?

Maciej Pijanowski started his talk on [Can It Run TrenchBoot?](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/ZXDQMW/) with a very brief introduction to TrenchBoot. Then Maciej discussed hardware requirements: fTPMs vs dTPM. Microsoft distinguishes TPMs even more: iTPM and fTPM, where iTPM is an IP block in SoC and fTPM is software/firmware running in other firmware (ME/PSP).

Then Maciej explained Intel TXT support—what does it mean, how many things have to align to make it work. Maciej was essentially explaining that if you want to prove if TrenchBoot can work, there are so many factors it is unlikely to check without trying on real hardware. So you can see that offering Qubes OS AEM-enabled hardware is not that easy.

Maciej introduced meta-trenchboot based image for booting using USB, which can be used for testing. He presented test results for v0.5.2. Modern (Zen and newer) AMD are not supported. The meta-trenchboot HCL needs better marketing and inclusion in DTS, but that is not that simple. What about exposing it over the network? 3mdeb can gather results as we gather HCL for Dasharo. Maciej helped during the hackathon to run TrenchBoot HCL to gather more results.

## Day 2: Infrastructure, Automation, and Technical Deep Dives (September 27)

### Qubes Windows Tools: Present and Future

Rafał Wojdyła gave an [introduction to Qubes Windows Tools](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/BSN7GH/), which are mostly functional for Windows 10 and 11. Windows 7 support was dropped. There is a discrepancy between what windowing API is reporting and reality—there are undocumented flags used by Microsoft applications. Some windows by API status should be visible but in reality they are not, kind of a cloak mode.

There are some improvements in the Windows installer, which was rewritten in WiX4. The most important improvement is automatic approval of the test-sign driver popup. Qubes Build v2 support was another important improvement. Release signed code and performance optimizations are in the plans for future. The GUI agent is spaghetti code, so it won't be an easy task.

### Recent Advances in Device Management

Piotr Bartman-Szwarc [discussed peripheral devices from the point of view of Qubes](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/BBGGBC/). Device identification relies on port ID, device ID, and backend qubes to which the device is connected.

There is still confusion between assignment and attachment to qube:

- We attach for everyday device management/use. It is prone to error—misclick, and it may only happen when the device is in the system.
- Assignment is for automation and proper configuration of the system. Assignment may happen even if the device is not attached to the system.
- Assignments make the most sense for vault qube, where you would like to connect HSM/USB cryptotoken.

Piotr then explained using a compatibility matrix what can be attached and assigned.

### Qubes OS CI Review

Marek Marczykowski-Górecki gave a [talk about CI used by Qubes OS](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/3BVSTJ/). Frédéric did custom integration to be able to leverage code from forks. Qubes OS uses multiple runner types: docker, VM based on KVM, as well as Qubes VM (including Windows). There's also vm-kvm—KVM with nested virtualization—which allows running Qubes in VM. This is Xen on KVM, not the other way around, but Xen works on it.

There are a bunch of unit tests for Python tools and linters. There is some fuzzing from Google. Build tests do reproducible tests, installing in a container, catching trivial errors. In theory, build environment is not part of reproducibility AFAIK. Not everything is reproducible yet.

openQA is for integration testing. It is essentially clicking on the screen. Other tests write commands to run Python tools. openQA has a good presentation layer for test results. End-to-end tests for split-gpg, where there is email signing and then checking if it was received and correctly signed and encrypted. It helps a lot with installation. Interesting stuff is that QA adds comments to the package updates on GitHub as test results.

There are compatibility tests for Qubes OS Certified Hardware, performance tests, and Windows tests, as well as some specific tests. Windows installation test was 4 hours or something like that, but that is too slow on nested virtualization. How is emulated USB input connected to device through a separate controller? Or how does it work for laptops? Or is this accepted as a separate device?

Orange Pi 5B based on RK3588 is the new controller added to support 4K. There is very limited testing of GPU—performance of sys-gui-gpu is low, 18fps, half of the native. There is a test for WiFi testing. Some tests and hardware platforms are participating in Xen Project CI. There are AMD Ryzen devices—what are those? Automatic bisection is implemented.

### Documentation and Localization

m and Tobias Killer gave a [presentation about updates in documentation](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/R7B77L/), its quality assurance, and the difference between Read The Docs, Sphinx, and rST. There were issues with paragraphs in lists. Markdown admonitions also had confusing colors and header text. RTD has a lot of useful features, and Qubes switched to it recently. Translation was one of the most important features needed. There are evaluation criteria defined for qualification of automatic translation. There is already Ollama running on Jetson Nano where we can call it through qubes.ConnectTCP.

### Ansible in Qubes OS

Frédéric Pierret gave a [talk starting with explaining Ansible vs Salt](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/ULSH3A/). Ansible use is known in corporate environments. Ansible support started with kushaldas working in 2018, where an Ansible connection plugin was written from scratch. In 2024, Qubes 4.2 got Ansible 7.7 compatibility. In 2025, Qubes R4.3 got official integration—CI and packaging was added. ITL's customers requested Ansible 9.13 support. There are a lot of features.

Questions included: What's the 3-5 year vision of Ansible support? How does it compare to Ben's qusal, especially with per-application VM and very strict isolation? What would be useful for that is limiting traffic and unblocking traffic needed only by application. Also, DNS resolution would be great to have fixed. Is there any best practice for users?

The `qubes_proxy` proxies Ansible execution through a management disposableVM, sanitized with qrexec. Limitations include that access to facts and variables from other hosts is not possible. What is good is that there are safeguards for using incorrect strategy for execution. Bootstrapping needs installation of packages.

Remote management is possible à la Qubes Air through mgmt VDM with predefined connections like in the RemoteVM example presented in the PoC. It would be ideal to reproduce configuration of PoC communication. What will happen if we try to remotely execute Ansible stuff? Is it possible?

### Even More Control: Device Widget Updates

Marta showed a lot of [nice pictures on GUI tools updates](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/JGVEWM/). First, the evolution of device widgets: 4.0, 4.2, 4.3. There is a way to not show child devices, which will lead to hiding child devices. For storage, e.g., partitions, which in case of too many partitions was annoying. Where will those child devices be visible?

It always takes a couple iterations to setup conferencing. I have this all the time, forgetting to switch my mic and headset. That's why there was a request from industry (Matthias) to create a conference VM, and I guess device assignment would be a very useful feature. There is UI for assignments. Can I save current attachment to convert it to assignment? TODO: create issue for that.

### Fast and Fresh Disposable Qubes

After some technical issues related to cooperation between eDP, HDMI, and projector, Ben Grande presented on [disposable VM preloading](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/FCJLF7/). Named vs unnamed disposable VMs—the point is that the first do not close after closing the app, unnamed are closed. Right now time is "almost instant"—it would never be 0 ms. What was the gain in time, before and after?

Suspend to disk is unreliable, same for Xen VM forking. Preloading and pausing is the method building on existing Qubes infrastructure. On startup there is waiting for the system to be fully operational, then pause VMs. There are some options for preload: `preload-dispvm-{max, threshold}`. I'm not sure what is the boot flow. Enabling the option preloads a number of disposables until some threshold of free memory is crossed.

The gain is 2x-9x. There are various situations where things can fail: insufficient memory, failure to preload, outdated volumes, interrupted qubesd. R4.3 has it enabled if >15GB.

## EU CRA: Seven Ways to Profit from Qubes OS

Peter Schoo gave a very important and insightful [talk about details of where we are in EU CRA legislation](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/RLYLSR/). This presentation was not recorded and not streamed. Peter is a BSI expert contractor with a mission to inform the Qubes OS community.

Questions and discussions covered several critical topics:

How can you give users freedom to deliver their own Root of Trust and Chain of Trust if you cannot ship that hardware? Probably transfer of ownership has to be employed. How does EU CRA see organizations which would like to help in RoT and CoT provisioning and maintenance? ISO 62304 was mentioned.

We appreciate the initiative and motivation to come to the QOSS event to educate us about the EU CRA. Wouldn't that disable OEM/ODM as well as potential interoperability?

Training and content creation is out of scope. Any devops and automation which is delivered to clients may apply if you create and distribute tooling (Ansible, Salt). This is a gray zone a little bit—if this is a product or service, it really depends on profit, which is different from income (are you greedy?). Creation of tools and selling pre-configured machines also falls into this.

Is there any immediate action that has to be taken by Steward? December 11, 2027 is the time for setting things in stone. How should upstream and downstream vulnerabilities be handled? This radically increases the cost of products. How can we engage? https://en.wikipedia.org/wiki/IEC_62304 seems to be for medical devices—how does that apply?

## Hackathon Results (September 28)

Day three was dedicated to hands-on hackathon work. Based on the goals whiteboard, several projects made progress:

**Dasharo Patchqueue Initiative** (Andrew Cooper, Piotr Król, Michał Żygowski, Maciej Pijanowski): This consumed most of my time during the hackathon. Together with Michał and Maciej, we received a lecture from Andrew Cooper on how to maintain a patch queue based on his experience from the XenServer xen.pg project: https://github.com/xenserver/xen.pg. Learning from someone with that level of experience in patch queue management for Xen was incredibly valuable for our Dasharo firmware work. This took all my time, so I couldn't work on RemoteVM PoC reproduction that I had planned.

**TrenchBoot HCL Reports** (Maciej): Gathering hardware compatibility reports for TrenchBoot/AEM. The meta-trenchboot USB testing image introduced during Maciej's talk was used to collect real-world compatibility data across different hardware platforms.

**UEFI Secure Boot Development** (Kamil): Continued work on UEFI Secure Boot implementation, building on the progress discussed in his Day 2 talk.

**QubesBuilder v2 + Debian/Podman** (Yann D): Build system improvements focusing on Debian integration and Podman support for QubesBuilder version 2.

**Start Guide for New Apps Features** (Ben): Documentation work to help users understand and adopt new application features.

**Runtime Suspend Patch Review** (Vertex, Andrew, Simon): High-level review of PCIe passthrough suspend improvements—addressing one of the pain points with device management and power states.

**Easy VPN Setup Tool** (Marta): Quality-of-life tooling to simplify VPN configuration in Qubes, addressing a common user pain point.

The hackathon demonstrated the practical side of the summit—moving from talks and discussions to concrete implementation work and collaboration across different areas of the Qubes ecosystem.

## Reflections and Observations

A note on event timing: It seems that a lot of people attended in commercial capacity on Friday. So maybe the event should be shifted to Thursday/Friday and Saturday? A survey was sent after the summit to gather feedback on this and other aspects, which will lead to adjustments for future events.

The summit showed maturity in several areas: comprehensive CI/testing infrastructure (Marek's CI talk), improving documentation processes (m and Tobias), and proactive engagement with regulatory challenges like EU CRA (Peter Schoo). The Qubes Air architecture emerged as a recurring theme across multiple talks—from Michał's server hardware foundations, to my RemoteVM presentation, to Frédéric's Ansible remote management PoC. This suggests the community is converging on distributed computing patterns that extend Qubes beyond single workstations.

Corporate adoption challenges (Matthias Ferdinand) highlighted practical gaps that need addressing: proxy configuration as a first-class citizen, flexible IP address pool allocation, system-wide CA deployment, and better videoconferencing VM support. These aren't just enterprise nice-to-haves—they're requirements for broader adoption.

The Dasharo ecosystem's role in hardware enablement continues to expand: server firmware foundations (Michał), NovaCustom customer adoption bringing capital and validation (Wessel), TrenchBoot compatibility work (Maciej), UEFI Secure Boot progress (Kamil), and the Patchqueue Initiative learning from XenServer experience (Andrew Cooper). The ecosystem needs this kind of sustained firmware and hardware certification work to make Qubes viable on modern platforms.

The comparison with Spectrum OS (Alyssa Ross) was valuable—seeing different architectural trade-offs (KVM vs Xen, image-based vs customizable, Wayland-native) helps both projects learn from each other. Competition and diversity in compartmentalized OS development is healthy for the market and drives innovation.

Overall, the summit balanced technical depth with practical deployment concerns, bringing together firmware developers, OS maintainers, corporate users, and security researchers. The afterparty at BRLO Beer Garden provided space for informal discussions that often lead to future collaborations.

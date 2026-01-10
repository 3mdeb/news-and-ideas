---
title: "Stop dreading NIS2: Unlock your firmware digital sovereignty with
  Zarhus."
abstract: "The NIS2 Directive marks a new era of mandatory cyber risk
  management and accountability, with a focus on supply chain integrity. Today,
  we'll discover how Zarhus empowers you to master NIS2 compliance effortlessly,
  so you can take back control, secure your digital sovereignty, and focus on
  what truly matters - YOUR way."
cover: /covers/zarhus_logo.png
author: kamil.aronowski
layout: post
private: false
published: true
date: 2025-11-28
archives: "2025"

tags:
  - NIS2
  - dasharo
  - encryption
  - linux
  - luks
  - secure-boot
  - zarhus
categories:
  - Firmware
  - Security

---

The European Union’s NIS2 Directive ushers in a powerful new era of cyber risk
management, [holding every link in the supply chain
accountable](https://web.archive.org/web/20250916222654/https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX%3A32022L2555)
to protect your business and the digital future.

Complex regulations often feel like an endless maze of bureaucracy, adding to
the mountain of regulations that organizations already struggle to navigate. In
practice, they don't have to feel this way! When it comes to securing your
supply chain and mastering cryptography, there’s a clear path that cuts through
the red tape and puts you back in control. Imagine meeting all these stringent
requirements without the usual headaches, freeing your team to focus on
protecting your digital future with confidence and ease.

Today, we'll discover how [Zarhus](https://docs.zarhus.com/) empowers you to
master NIS2 compliance effortlessly, so you can take back control, secure your
digital sovereignty, and focus on what truly matters - **YOUR** way.

## Introduction

The NIS2 Directive lays down robust obligations designed to mitigate
cybersecurity risks in supply chains. Key stipulations include implementing
comprehensive supply chain risk management plans, assessing vulnerabilities in
suppliers and service providers, and enforcing strict cryptographic policies to
protect sensitive data.

[ENISA Executive Director, Juhan Lepassaar
stated](https://web.archive.org/web/20251003154059/https://enisa.europa.eu/news/etl-2025-eu-consistently-targeted-by-diverse-yet-convergent-threat-groups):

> Systems and services that we rely on in our daily lives are intertwined, so a
> disruption on one end can have a ripple effect across the supply chain. This
> is connected to a surge in abuse of cyber dependencies by threat actors that
> can amplify the impact of cyberattacks.

Organizations are required not only to adopt technical and operational
safeguards but also to coordinate with suppliers for consistent risk evaluation
and response. Through these mandates, NIS2 aims to close security gaps that
threat actors have long exploited in interconnected digital supply
environments.

But how can effective coordination and comprehensive risk evaluation be
achieved when your organization relies on black-box devices, without the
ability to transparently validate machine integrity? What strategies should be
employed when your vendor discontinues firmware support for critical hardware?
How can you guarantee that the foundational firmware truly serves **your**
operational requirements rather than external interests?

This article takes a deep dive into these challenges and illustrates how
adopting [Zarhus](https://docs.zarhus.com/) enables precise [control over your
hardware’s low-level
functions](https://docs.dasharo.com/osf-trivia-list/dasharo/#future-work),
enhancing [security,
reliability](https://docs.dasharo.com/osf-trivia-list/dasharo/#dasharo-professional-support),
and [long-term
maintainability](https://docs.dasharo.com/osf-trivia-list/dasharo/#dasharo-long-term-maintenance).

![Zarhus logo](/img/zarhus-logo-new.png)

## The Challenge of Firmware Security

Navigating the complexities of NIS2 compliance can be daunting for many
companies, as cybersecurity regulations tighten across industries. For
businesses relying heavily on major corporations within their firmware supply
chain (and with closed implementations, naturally its cryptography as well),
the challenge is even greater. Counterintuitively, it itself could become part
of your company's threat model, given the history of key mismanagement by tech
giants, in the light of NIS2's approach to supply chain and cryptographic
requirements.

Here, the focus will be on **this specific threat model** to analyze the
requirements outlined in [Article
21.2](https://web.archive.org/web/20250916222654/https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX%3A32022L2555)
addressing its specific aspects in the context of firmware security - the area
of our expertise.

Please note that while this firmware-based analysis does not cover the entire
technological stack of your systems, it represents an essential first step
toward enhancing their commitment to your digital sovereignty.

In short,

- Supply Chain Security
  - Entities must implement appropriate technical, operational, and
      organizational measures to manage cybersecurity risks related to supply
      chains.
  - Assess vulnerabilities of direct suppliers and service providers,
      including their secure development practices.
  - Take coordinated security risk assessments into account to ensure
      comprehensive supply chain risk management.
- Cryptography usage shall establish:
  - Logging and auditing of key management-related activities.
  - Proper key handling, backups, restoration and revocation.
  - Assurances about secure key generation.

Having the directive in mind when analysing our threat model, it becomes clear
that satisfying several points becomes difficult, if not outright impossible.
The essential part of NIS2 is the emphasis on the **actual effectiveness of
controls**, not merely their documented existence - evidence is based on
factual proofs and objective principles.

Ask yourself: how can you **prove to the auditor**, that the keys have been
generated securely?

- Can you present any evidence that an HSM or an air-gapped machine was used to
  generate the keys?
- Can you receive or provide any audit log on what was happening with the keys
  after they have been created?

Furthermore:

- Can you prove that the product you own hasn't been tampered with in transit?
- Can you rely on the vendor's security implementation?

<img src="/img/nis2-with-zarhus/cve-2025-7026.png" alt="The cvedetails.com page
on the CVE-2025-7026 vulnerability, showcasing the reliance on vendor's
security implementations given the closed source nature of the product."
style="border: 2px solid grey;">
<center>
<i>
Source: <a
href="https://www.cvedetails.com/cve/CVE-2025-7026/">cvedetails.com</a>
</i>
</center>
<br><br>

- Can you rely on proper key handling and revocations?

<img src="/img/nis2-with-zarhus/cve-2024-7344.png" alt="The
bleepingcomputer.com article from January 2025 about the CVE-2024-7344 security
vulnerability in UEFI Secure Boot. The vulnerability specifically resides in
certain system recovery tools from multiple vendors that use a custom UEFI
application signed with a Microsoft third-party certificate, which can be
exploited to deploy bootkits, showcasing the reliance on vendor key handling
and revocations." style="border: 2px solid grey;">
<center>
<i>
Source: <a
href="https://web.archive.org/web/20250116151152/https://www.bleepingcomputer.com/news/security/new-uefi-secure-boot-flaw-exposes-systems-to-bootkits-patch-now/">bleepingcomputer.com</a>
</i>
</center>
<br><br>

Past vulnerabilities have shown how attackers can exploit insecure firmware to
inject malware or subvert boot processes, rendering traditional defenses
ineffective. Furthermore, the complexity of proper cryptographic key handling
and revocations adds to these risks, emphasizing the need for stronger
sovereignty over firmware security mechanisms.

According to the [2025 Cyber Threat Analysis by
IDS-INDATA](https://web.archive.org/web/20251031110741/https://idsindata.co.uk/20-rise-in-supply-chain-cyberattacks-legacy-systems-continue-to-leave-manufacturing-exposed/),
supply chain attacks have risen by 20% between 2024 and 2025. This increase
identifies them as the fastest-growing cybersecurity threat.

<img src="/img/nis2-with-zarhus/supply_chain_attacks_2024_2025.png" alt="A
chart showcasing the percentage difference between various kinds of cyber
attacks, supply chain attacks ranking the highest">
<center>
<i>
Source: <a
href="https://web.archive.org/web/20251031110741/https://idsindata.co.uk/20-rise-in-supply-chain-cyberattacks-legacy-systems-continue-to-leave-manufacturing-exposed/">idsindata.co.uk</a>
</i>
</center>
<br><br>

[Article 21.3's
requirements](https://web.archive.org/web/20250916222654/https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX%3A32022L2555)
leave no stone unturned here. It's essential that

> [...] entities take into account the vulnerabilities specific to each direct
> supplier and service provider and the overall quality of products and
> cybersecurity practices of their suppliers and service providers, including
> their secure development procedures.
>
> [...] entities are required to take into account the results of the
> coordinated security risk assessments of critical supply chains carried out
> in accordance with Article 22(1).

With that in mind, ask yourself: how can you **prove to the auditor**, that
your direct suppliers, their development and key management practices, and the
aforementioned quality of products and cybersecurity practices have been
appropriately assessed.

## Taking Control: Building Your Firmware Security Infrastructure

Achieving true digital sovereignty over firmware requires owning a secure
infrastructure for the retrieval and provisioning of open source code. This
entails customizing the sources so that they are tailored precisely to the
organization’s machines and establishing a secure compartment for signing
firmware binaries. Although setting up such infrastructure may initially seem
daunting and resource-intensive, advances in dedicated hardware and automation
tools now make this approach practical and sustainable.

Additionally, all logs related to key generation and management, along with the
associated configuration settings, can be made available for auditor review,
meeting the essential principles of audit evidence:

- sufficiency: the evidence comprehensively covers the claimed process.
- relevance: the evidence directly supports the entity’s assertions.
- authenticity: the evidence is verifiable and can be traced back to the
  relevant process.
- corroboration: the technical controls and configurations are documented to
  reinforce the evidence.

Proper audit evidence documentation ensures a clear understanding of the
procedures performed and facilitates a robust and transparent review process.

**Please note, this does not constitute legal advice. While these principles
align with established audit evidence standards, which emphasize the need for
evidence to be reliable, relevant, and properly documented to support audit
conclusions effectively, we do not provide legal counsel, and for specific
guidance on the validity of evidence, it is essential to consult a qualified
auditing expert.**

A pivotal innovation in this domain is the advent of dedicated,
secure-by-design hardware for automation.

Enter: **Zarhus Trust Root Provisioning Box**.

This device, a physical appliance or a virtual machine, empowers organizations
to generate and securely store cryptographic keys in an encrypted manner on
physical media, such as USB flash drives, USB-connected hardware tokens, and
Hardware Security Modules, where they remain under sole control. It also
enables the fortification of the boot process via mechanisms such as Intel Boot
Guard and UEFI Secure Boot, but with keys managed exclusively by the
organization, rather than third-party vendors. The Box is designed specifically
to automate the mass provisioning of the entire organization's infrastructure,
while being secured with equivalent protection measures.

The flow is simple - this diagram showcases a high-level overview, how the key
generation and firmware provisioning process happen:

![Zarhus Trust Root Provisioning Box high-level
flow](/img/nis2-with-zarhus/provisioning_box_high_level_flow_vertical.svg)

This means that your organization can automate the secure signing of the
firmware tailored to your machines and provision devices confidently, knowing
that you control the entire trust chain from key generation to deployment.

Why generate your own UEFI Secure Boot keys and Intel Boot Guard keys, you
might ask? Depending solely on the vendor's stock keys can raise concerns under
NIS2 about responsibility for security controls, ability to fully comply with
risk management mandates, and meeting audit and traceability requirements.

Consider the following:

- The risks around supply chain security, since key management depends on the
  vendor's security practices and timelines, which may not fully align with
  your organization's or regulatory demands.
- The potential compliance challenges if an incident does occur nevertheless
  and your organization cannot independently prove that it maintained full
  control of critical boot integrity mechanisms, affecting evidential chain of
  custody and accountability.
- The increased exposure to legal liability or penalties if third-party key
  management leads to vulnerabilities or compromises that violate NIS2
  requirements, which include strict reporting and incident management
  obligations.

Organizations responsible for critical infrastructure or subject to stringent
compliance requirements often opt to manage their own UEFI Secure Boot keys.
This approach, combined with management of their own Intel Boot Guard keys and
firmware signing, ensures complete governance and minimizes reliance on third
parties, thereby reducing potential legal and compliance risks associated with
NIS2's requirements on assessing your supplier's practices - it is
significantly easier to obtain a comprehensive audit trail of the entire
process within an organization-controlled environment and to present the
relevant logs and configurations as evidence to an auditor. This contrasts
sharply with the considerable challenge of demonstrating control over machines
when relying on vendor firmware that lacks an audit trail or transparent
security measures.

However, it is important to be aware that this strategy presents several
challenges related to system maintenance and IT administration, specifically:

- Increased responsibility for secure key management, encompassing key
  generation, storage, updating, revocation, and the implementation of
  stringent operational procedures to prevent key compromise. This includes
  practices such as generating keys offline or directly within a Hardware
  Security Module (Zarhus Trust Root Provisioning Box automates this) and
  enforcing strict access controls.
- More complex firmware and bootloader update processes, as updates must be
  digitally signed using the organization’s private keys.
- Enhanced security control accompanied by increased operational overhead,
  requiring IT teams to establish and enforce robust policies along with
  [comprehensive training focused on the Secure Boot key
  lifecycle](https://3mdeb.com/training/).
- The understanding of how the Zarhus Trust Root Provisioning Box works, and
  the challenges related to managing the ever-expanding volume of binary blobs
  in the firmware tailored for the target systems.
- Specialized expertise and tools for recovery operations, acknowledging that
  occasional device unavailability may occur due to rare edge cases.
- Proficiency across the entire Chain of Trust domain, not limited to UEFI
  Secure Boot, but also including technologies such as verified boot, CBFS
  verification, and [Heads](https://osresearch.net/).
- Thorough threat modeling associated with the distribution of unfused
  hardware.
- Coordination within fixed timeframes according to the service provider’s
  Service Level Agreement (SLA), requiring close collaboration for deployment
  activities.
- Limited options for ownership transfer post-fusing, unless precise,
  irrevocable contracts regarding ownership and key transfer are established in
  advance.

Although the challenges may seem formidable, a visually appealing overview
clearly demonstrates the simplicity of the process:

![Zarhus Trust Root Provisioning Box sequence
diagram](/img/nis2-with-zarhus/provisioning_box_sequence_diagram.svg)

## Example key generation

With that in mind, operating this hardware solution is straightforward, with
guided command-line interfaces facilitating key creation, firmware signing, and
UEFI Secure Boot key enrollment, catalyzing productivity without compromising
security.

You create your keys with:

```console {linenos=inline hl_lines=["7-9"]}
$ zarhus storage create

Checking available USB flash drives
Choose USB flash drive to use for encrypted storage.
All data on this device will be lost!
c: Cancel
0: Kingston - DataTraveler 3.0, /dev/sdb
1: Wilk - USB 3.2 gen. 1, /dev/sda
Your choice:
```

And let the solution encrypt the keys' storage with your password:

```console {linenos=inline}
Enter password for encrypted storage:
```

<br><br>

Once the encrypted storage has been created, you generate your keys securely:

```console {linenos=inline hl_lines=["4"]}
$ zarhus prepare --eom

Generating Intel BootGuard keys
Choose your Intel BootGuard keys name (without spaces): ZPB_IBG
```

And receive your firmware binary provisioned.

```console {linenos=inline hl_lines=["1"]}
zarhus-dtrpb-fw.cap was provisioned successfully
Updating Zarhus Provisioning Box firmware
Queue firmware update
Firmware will be updated during reboot!
Press Enter to reboot
```

<br><br>

Provisioning UEFI Secure Boot with your own keys is also straightforward.

```console {linenos=inline hl_lines=["13"]}
$ zarhus provision-secure-boot

Generating Secure Boot keys
Choose your Secure Boot keys name: ZPB_SB

Created Owner UUID 1cd64494-c5c7-4688-bf6a-e200d38fcc00
Creating secure boot keys...+
Secure boot keys created!
Signing Unsigned original image
Signing Unsigned original image
Enrolling keys to EFI variables...+
Enrolled keys to the EFI variables!
Secure boot was provisioned! Make sure to reboot
```

## Liberating Firmware with Open-Source Solutions

A firmware binary tailored to your organization's machines can be downloaded
and signed with a few commands:

```console {linenos=inline hl_lines=["12"]}
$ ./share-fw download firmware.cap
$ sudo mount /dev/disk/by-label/fw-bin /mnt
$ zarhus provision /mnt/<path/to/firmware>.cap

Choose your keys:
c: Cancel
g: Generate new
0: Zarhus_IBG
Your choice: 0

Provisioning binary
firmware.cap was provisioned successfully
```

And deployed to your machines:

```console {linenos=inline}
# fwupdtool install-blob firmware.cap
```

With keys under direct control, your organization can liberate your firmware by
adopting transparently maintained open source projects such as
[Dasharo](https://www.dasharo.com/). This approach enhances
[trust](https://blog.3mdeb.com/tags/validation/),
[privacy](https://docs.dasharo.com/osf-trivia-list/dasharo/#future-work), and
[maintainability](https://docs.dasharo.com/osf-trivia-list/dasharo/#future-work).
As we've demonstrated, the workflow involves downloading firmware images,
mounting them on the provisioning hardware, signing them with locally generated
keys, and deploying them to the physical devices confidently - all boiling down
to [running a few commands](#example-key-generation). This model ensures that
firmware integrity is verifiable, firmware updates are under organizational
control, and the entire lifecycle aligns with rigorous cybersecurity standards.

## Summary

NIS2 introduces stringent cybersecurity obligations, particularly around supply
chain security and cryptography requirements. Meeting these new, broad-ranging
requirements is seen as complex and resource-intensive.

It does **not** have to be seen this way. The use of appropriate tools for each
specific context is essential to enhance ease of use and implement security by
design. Achieving digital sovereignty over firmware and supply chain security
no longer needs to be a costly or complex burden. By embracing this
paradigm-combining regulatory compliance, cryptographic sovereignty, and
open-source flexibility, organizations effectively strengthen supply chain
security while reducing reliance on potentially insecure third-party vendors.
[Such control directly addresses long-standing firmware security challenges,
facilitates adherence to the NIS2 Directive, and anchors a more resilient
cybersecurity posture](https://blog.3mdeb.com/tags/open-source/).

Since the NIS2 Directive mandates not only theoretical cybersecurity policies
but also the provision of **practical evidence demonstrating compliance**, in
this context organizations must demonstrate comprehensive logs related to key
generation and management, verifiable proof of the use of air-gapped systems or
Hardware Security Modules, and corresponding configuration settings. These
elements **must be available for auditor review to substantiate compliance
claims**. Through modern tools and well-defined processes, securing firmware
and enforcing cryptographic policies can become an [automated, manageable, and
auditable](https://docs.dasharo.com/osf-trivia-list/dasharo/#dasharo-transparent-validation)
practice that supports both regulatory demands and [organizational
trust](https://docs.dasharo.com/osf-trivia-list/dasharo/#future-work).

Furthermore, vendor assessment can be conducted transparently, given the
involvement of open-source solutions from [smaller, but worldwide-recognized
company](https://3mdeb.com/about-us/), to avoid reliance on opaque or
unauditable implementations. This **practical proof** approach ensures
adherence to NIS2's stringent requirements for risk management, security
governance, and incident readiness beyond mere documentation or policy
statements.

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help. [Schedule
a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to sign up for our newsletter:

{{< subscribe_form "69962d05-47bb-4fff-a0c2-7355b876fd08" "Subscribe" >}}

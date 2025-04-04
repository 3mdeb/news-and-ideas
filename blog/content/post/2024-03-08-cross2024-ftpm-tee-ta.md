---
title: Embracing fTPM on embedded ARM Devices - Insights and Solutions
abstract: 'This article examines the integration of firmware Trusted Platform
Module (fTPM) in embedded devices, particularly for custom ARM-based projects.
It covers the benefits alongside challenges and potential drawbacks. The piece
compares fTPM with other TPM implementations, offering strategies to mitigate
issues and guide developers towards informed choices and a stronger open
security framework for embedded devices.'
cover: /covers/ftpm_tee_cover.png
author: tymek.burak
layout: post
published: false
date: 2024-03-08
archives: "2024"

tags:
  - arm
  - embedded
  - fosdem
  - tpm
  - confidential-computing
categories:
  - IoT
  - Security
  - Manufacturing

---

In the realm of digital security, Trusted Platform Modules (TPMs) play a
pivotal role by safeguarding cryptographic keys and other sensitive data used
in authentication processes. Traditionally, TPMs are external hardware
components, adding a layer of physical security but also increasing the overall
cost of device manufacturing. However, in the quest to balance
cost-effectiveness with security, one viable solution that emerges is the
integration of firmware-based TPMs (fTPMs) within the CPU itself. This approach
presents an innovative alternative for scenarios where traditional hardware
TPMs may not be feasible or cost-effective but also come with fallbacks.
The essence of fTPM, securing cryptographic keys and facilitating secure
authentication processes, can be achieved in firmware alone, where it's executed
in a protected execution environment called a trusted execution environment
(TEE), that separates it from the rest of the code running on the CPU.

## Arm TrustZone

For Arm Cortex-A, there exists the Arm TrustZone technology.
When used on an embedded device it creates two distinct memory "worlds": a
Normal World for the Operating System (referred to as Rich OS in documentation)
and a Secure World, perfect for implementing the Trusted Execution
Environment<sup>[[1]](#figure-1%3A-arm-trustzone-for-arm-cortex-a)</sup>. <!-- markdownlint-disable-line MD033 MD051 MD013 -->
The transition between these worlds is managed by the Secure Monitor, operating
at a higher exception level (EL3), ensuring secure memory regions are
exclusively accessible from the Secure
World<sup>[[2]](#figure-2%3A-cortex-a-exception-levels)</sup>. <!-- markdownlint-disable-line MD033 MD051 MD013 -->
This mechanism supports running
fTPM in the Secure World, enabling secure syscalls from user space. Secrets
stored in fTPM are secure as long as the Secure Monitor is not compromised.
<!-- markdownlint-disable-next-line MD033 MD013-->
<div style="text-align: center;"> <img src="../../static/img/TEE_ARM_Cortex-a.svg" alt="Cortex-A TrustZone"> </div>

<!-- markdownlint-disable-next-line MD033 MD001 -->
##### <div style="text-align: center;">Figure 1: Arm TrustZone for ARM Cortex-A </div>

<br> <!-- markdownlint-disable-line MD033 -->
<br> <!-- markdownlint-disable-line MD033 -->

<!-- markdownlint-disable-next-line MD033 MD013-->
<div style="text-align: center;"> <img src="../../static/img/TEE_ARM_Cortex-a_exception_levels.svg" alt="Cortex-A TrustZone Exception Levels"> </div>

<!-- markdownlint-disable-next-line MD033 MD001 -->
##### <div style="text-align: center;">Figure 2: Cortex-A Exception Levels </div>

Arm TrustZone also exists for the Cortex-M series but adopts a simpler and more
hardware-focused approach relying on hardware mechanisms to manage the CPU
state via
interrupts<sup>[[3]](#figure-3%3A-arm-trustzone-for-arm-cortex-m)</sup>. <!-- markdownlint-disable-line MD033 MD051 MD013 -->

fTPM requires a non-trivial amount of computational
resources and memory, which might be scarce in the environments where Cortex-M
processors are typically used. Implementing fTPM could therefore be impractical
due to the limited resources available on these devices. It's also rare for the
Cortex-M devices demand the complex security functionalities that fTPM
provides.

<!-- markdownlint-disable-next-line MD033 MD013 -->
<div style="text-align: center;"> <img src="../../static/img/TEE_ARM_Cortex-m.svg" alt="Cortex-M TrustZone"> </div>

<!-- markdownlint-disable-next-line MD033 MD001 -->
##### <div style="text-align: center;">Figure 3: Arm TrustZone for ARM Cortex-M </div>

## Fallbacks and Security Concerns

_The best-protected systems have dedicated hardware security measures included
from the beginning of their design process, starting with the specification
for the processor core and the SoC infrastructure._

As fTPM is implemented purely in software the huge advantage is that it can be
added to already provisioned devices via an update. The caveat is that while
this can improve the security of such devices there are hardware security
concerns that the device should fulfill from the beginning.

OP-TEE (Open Portable Trusted Execution Environment) is an open-source project
that provides a TEE designed for ARM architectures that utilizes Arm TrustZone.
Its [official documentation specifies the Raspberry Pi 3 platform as not
suitable for a secure implementation of Trusted Execution Environment](
https://optee.readthedocs.io/en/latest/building/devices/rpi3.html#disclaimer).
A sole CPU can't provide features such as a good source of entropy, a
secure counter or a secure clock. Thus fTPM, while being a great hardening
option, comes with a set of weaknesses. These drawbacks can be mitigated but the
device manufacturers need to seriously take into account potential
vulnerabilities in the early stages of designing an embedded device.

Additionally while the firmware-based TPM (fTPM) offers a software-centric
approach to trusted computing, developed and [reference-implemented by
Microsoft](https://github.com/microsoft/ms-tpm-20-ref/blob/6b72d6690d830ed282c8b8a32e12a638fd0dc19a/README.md),
integrating it across diverse platforms and Trusted Execution Environments
(TEEs) presents significant developmental challenges. This fragmentation hinders
the widespread adoption of fTPMs, particularly in the IoT sector, where device
heterogeneity is the norm.

CROSSCON's mission is to engineer a new, open, modular, highly portable, and
vendor-neutral IoT security stack. By doing so, we aim to dismantle the
barriers currently complicating the deployment of fTPMs and other trusted
applications on varied devices and architectures. The project's strategy
involves the development of a unified API set that abstracts the complexities
of TEE functionalities and trusted services. This approach promises to simplify
the development process, enabling seamless and secure integration of trusted
applications across different IoT platforms. Ultimately, CROSSCON sets a new
benchmark for creating secure IoT environments, demonstrating a clear path
towards standardizing and fortifying IoT security at scale.

## Summary

In the CROSSCON project, the exploration and integration of fTPMs stands as a
strategic approach to fortify IoT security in scenarios where traditional TPMs
are impractical or infeasible, particularly in the context of already deployed
devices. This underlines our commitment to pushing the boundaries
of security standards, offering a versatile and
cost-effective alternative to enhance cryptographic operations and
authentication processes on devices that were previously considered vulnerable
or less secure. By designing a unified set of APIs to utilize Trusted Execution
Environment functionalities and trusted services, the CROSSCON project can
significantly simplify the development and provisioning of fTPMs, facilitating
seamless integration across diverse IoT platforms and setting a new benchmark
for secure IoT ecosystems.

While traditional hardware TPMs offer robust physical security, fTPMs provide a
a promising avenue for enhancing security in a variety of devices, from high-end
computing systems to more constrained embedded devices and demonstrate a huge
potential to close the security gap in a broad spectrum of IoT applications.

However, the transition to fTPMs is not without its challenges, as this approach
necessitates a careful evaluation of the underlying hardware's capacity to
support secure operations.

For more information about implementing the fTPM in practice please refer to the
[fTPM: A Software-only Implementation of a TPM Chip](
https://www.microsoft.com/en-us/research/publication/ftpm-software-implementation-tpm-chip/).
This topic is also expanded at the [Securing Embedded Systems with
fTPM implemented as Trusted Application in TEE](
https://fosdem.org/2024/schedule/event/fosdem-2024-3097-securing-embedded-systems-with-ftpm-implemented-as-trusted-application-in-tee/)
talk that was presented at FOSDEM 2024 along with a small PoC.

---
title: "CROSSCON, its Hypervisor, and Zarhus"
abstract: "Learn about CROSSCON, how it's hypervisor works, and why running
          Zarhus on top of it streamlines development and testing on the RPi4."
cover: /covers/crosscon-logo.png
author: wiktor.grzywacz
layout: post
published: true
date: 2025-04-10
archives: "2025"

tags:
  - hypervisor
  - virtualization
  - zarhus
  - arm
categories:
  - Virtualization
  - Security
  - Firmware

---

## Introduction: what is CROSSCON?

Modern IoT systems increasingly require robust security while supporting
various hardware platforms. Enter [**CROSSCON**](https://crosscon.eu/), which
stands for **Cross-platform Open Security Stack for Connected Devices**.
CROSSCON is a consortium-based (part of which is 3mdeb) project aimed at
delivering an open, modular, portable, and vendor-agnostic security stack for
IoT.

Its goal: ensure devices within any IoT ecosystem meet essential security
standards, preventing attackers from turning smaller or more vulnerable
devices into easy entry points.

---

## The CROSSCON Hypervisor

The
[**CROSSCON Hypervisor**](https://github.com/crosscon/CROSSCON-Hypervisor/tree/main)
is a key piece of CROSSCON’s open security stack. It
builds upon the [Bao hypervisor](https://github.com/bao-project/bao-hypervisor),
a lightweight static-partitioning hypervisor offering strong isolation
and real-time guarantees. Below are some highlights of its architecture and
capabilities:

##### Static Partitioning and Isolation

The Bao foundation provides **static partitioning** of resources - CPUs, memory,
and I/O - among multiple virtual machines (VMs). This approach ensures that
individual VMs do not interfere with one another, improving fault tolerance and
security. Each VM has dedicated hardware resources:

- **Memory:** Statically assigned using two-stage translation.
- **Interrupts:** Virtual interrupts are mapped one-to-one with physical interrupts.
- **CPUs:** Each VM can directly control its allocated CPU cores without a
  conventional scheduler.

##### Dynamic VM Creation

To broaden applicability in IoT scenarios, CROSSCON Hypervisor introduces a
**dynamic VM creation** feature. Instead of being fixed at boot, new VMs can be
instantiated during runtime using the **VM-stack mechanism** and a hypervisor call
interface. A host OS driver interacts with the Hypervisor to pass it a
configuration file, prompting CROSSCON Hypervisor to spawn the child VM. During
this process, resources - aside from the CPUs - are reclaimed from the parent VM
and reassigned to the newly created VM, ensuring isolation between VMs.

##### Per-VM Trusted Execution Environment (TEE)

CROSSCON Hypervisor also supports **per-VM TEE** services by pairing each guest
OS with its own trusted environment. This approach leverages OP-TEE (both on
Arm and RISC-V architectures) so that even within the “normal” world, multiple
trusted OS VMs can run safely in isolation.

---

## Relation to Zarhus

CROSSCON Hypervisor demos on the RPi4 have always used a **Buildroot** initramfs
to showcase virtualization. While handy for proof-of-concept, buildroot lacks
many essential development tools - such as compilers, linkers, and other
utilities that embedded engineers often need. This is where **Zarhus** steps in.

---

## Why it's Convenient to Have Zarhus on the Hypervisor

Bringing **Zarhus** to the CROSSCON Hypervisor significantly boosts development
and testing convenience, especially on the Raspberry Pi 4:

- ***Full Toolchain Availability:** With Zarhus, you gain out-of-the-box
  compilers, linkers, and more. This is a major
  improvement over the limited buildroot initramfs environment.

- **Faster Iteration:** You can build and test software entirely within the
  guest environment - no need to rely on external cross-compilation or
  complicated host setups.

- **Complete Rootfs Mounting:** Now that Zarhus mounts a full filesystem,
  you can install additional tools (especially for security tests), manage
  logs, and run services in ways that would be impossible or cumbersome
  in a minimal initramfs environment.

---

## How to Build Zarhus for the CROSSCON Hypervisor

We’ve prepared a **step-by-step guide** on building and running Zarhus on
CROSSCON for the Raspberry Pi 4. This includes:

- **Setting up the Yocto environment** needed for Zarhus.
- **Configuring CROSSCON** to accept the Zarhus guest image.
- **Deploying** the final images to your RPi4 test environment.
- **Validation** and first-boot checks to confirm everything is operating
   as expected.

For the full instructions, visit
[our official documentation](https://docs.zarhus.com/guides/rpi4-crosscon-hypervisor/).

---

## Conclusion

The successful port of Zarhus to the CROSSCON hypervisor on the RPi4 marks
a milestone in our quest to simplify and streamline embedded development.
Where once we had to rely on a basic buildroot environment, we can now enjoy a
fully featured Linux distribution with all the trimmings - a huge leap forward
in flexibility and productivity.

If you've been using the CROSSCON Hypervisor demo on the RPi and trying to
test something on the Linux VM, there's a high chance you found the minimal
initramfs environment limiting. We suggest giving
[our setup](https://docs.zarhus.com/guides/rpi4-crosscon-hypervisor/) a try -
we are excited to see how developers might use this, and we remain committed to
expanding this solution.

For any questions or feedback, feel free to contact us at
<contact@3mdeb.com> or hop on our [community channels](https://3mdeb.com/community)
to join the discussion.

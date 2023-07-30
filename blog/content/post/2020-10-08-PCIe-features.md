---
title: What features PCIe has?
abstract: 'Introductory blog post to PCIe features.
          In this article you can read what PCIe capability is
          and see examples of such capabilities.'
cover: /covers/PCIExpress.jpg
author: marek.kasiewicz
layout: post
published: true
date: 2020-10-08
archives: "2020"

tags:
  - PCIe
categories:
  - Firmware

---

## What this blog is about

The goal of this post is to introduce readers to the concept of PCI Express
capabilities. It briefly describes what they are and how they works. It also
lists some example capability described in PCI Express (PCIe) specification.

## Introduction

Probably everyone knows about the existence of the PCIe standard. It is commonly
used in PCs to connect various devices to the motherboard. Every possible modern
graphic card uses PCIe, most sound cards use it, it starts to become the
standard even for SSDs, and that's just a tip of the iceberg. But how does the
OS communicate with all of these devices and how does it know what these devices
are capable of? This post will bring you closer to knowing the answer for those
questions, but let's start from the beginning...

PCI Express uses inverted tree topology. It starts from the Root Complex which
is connected directly to the CPU and RAM. Root Complex branches to Switches and
Endpoints. Switches branch founder and can be connected to more Switches or to
Endpoints. Endpoints reside at the bottom of branches and have only one upstream
Port (facing toward the Root). By comparison, a Switch may have several
downstream Ports, but can only one upstream Port. Possible are also Bridges and
Legacy Endpoints. Bridges are interfaces to other buses such as PCI. Legacy
Endpoints are devices which were designed for the operation of an older bus like
PCI‐X but now have a PCIe interface.

![PCIe topology](/img/Example_PCI_Express_Topology.png) Every Switch, Bridge and
Endpoint is a PCIe Device. All Devices have at least one Function, and each
Function has its Configuration Space which is Device registers mapped to either
I/O memory space (used mostly by PCI Devices) or to normal memory space. By
writing or reading from this memory OS can exchange information with a Function.
For example OS can check the vendor of a Device by checking the Vendor ID field
in Configuration Space Header of this device function.

### In the Configuration Space we can find most importantly 2 structures

- **Header** ![config header](/img/Pci-config-space.png) It contains information
  like vendor ID, and Device ID, pointers to memory assigned to the Function and
  pointer to first capability in linked list.

- **Linked list of capabilities** Each capability has its own header, it
  contains ID of the capability, its version and pointer to the next capability
  in the list. Beneath this header are mapped registers needed by the
  capability.

To check if a given capability is implemented by Function, a software has to
search through the list and check if a given capability ID is present in it.

## What PCIe capability actually is

It is nothing more than a predefined feature of the Device Function, a feature
that is known to be possible to be implemented in every Function, but most of
them are optional. Every capability has registers in a Device mapped to
configuration space. Those registers are a kind of interface to the capability.
Some are read only and contain information needed by the software, others are
read/write and can be used to pass information to the Function.

## List of capabilities structures

(This list can be incomplete)

- **PCI Express Capability register block**

This is one of the most important capability structure, it must be present in
all PCIe Functions. It is a collection of various information about:

1. **Device** e.g.:

   - Maximum payload of Transaction Layer Packet size that the Function can
     support,
   - Maximum accepted change latency between power states.

1. **Link** e.g.:

   - Link max speed \[GT/s\]
   - Link max width (number of lines)
   - Link change latency between power states
   - Port number for given Link

1. **Port** e.g.:

   - Physical slot number which is a chassis unique identifier for a slot.

1. **Hot-Plug**

   Registers responsible for this capability are located in the Capability
   register block. This capability allows change of Device in the PCIe slot at
   runtime. By writing to registers corresponding to this capability OS can let
   the Root or Switch Ports know to power Off or power On. After power is turned
   Off an user can safely remove the Device, after inserting new one power
   should be turned On to its Port.

1. **Baseline Error Reporting**

   Bits corresponding to this capability are located partially in the
   configuration header, partially in the Capability register block. All of them
   must be present in all PCIe Functions. Some bits of this capability are used
   to set error reporting, others store status of errors.

- **Power Management**

OS can manage the power environment of a Function directly by accessing
registers corresponding to this capability. OS can set Device state to one of 4
states. Two of them (D0, D3) are mandatory and other 2 (D1, D2) can be
optionally implemented. D0 state is a state where the Function is fully
operational and uses full power, every next state (D1,D2,D3) uses lower power,
but also takes more time to recover to D0.

- **Message Signaled Interrupts**

PCI has pins to let the central interrupt controller know that it needs to be
serviced. This improves efficiency of the CPU which does not need to check every
Function periodically, but it also significantly increases the number of needed
lines. In PCIe instead of additional lines special messages are used to signal
interrupt. Message Signaled Interrupts (MSI) allow the Function to write a small
amount of interrupt-describing data to a special memory-mapped I/O address. The
interrupt controller then delivers the corresponding interrupt to a processor.
Data and address to which they are being written are located in MSI capability
structure.

---

**All following capabilities are optional.**

---

- **Extended Message Signaled Interrupts**

Extends MSI from 32 possible vectors to 2048 by placing a table containing
addresses and messages of each vector in RAM instead of Device registers.
Pointer to the table and its size is saved in the capability structure.

- **Dynamic Power Allocation**

This capability extends power states by additional 32 states between D0 and D1.

- **Power Budgeting**

Its goal is to allocate power for PCIe hot plug Devices that are added to the
system during runtime. This ensures that the system can allocate the proper
amount of power and cooling for these Devices.

- **Advanced Error Reporting**

It provides additional registers that give error handling software more
information to work with in diagnosing and recovering from problems.

- **Virtual Channel**

It adds buffers that act as queues for outgoing packets. This capability allows
Device to assign one of 8 priorities to packets. Every priority has its own
buffer. Packets from buffers with higher priorities are sent more frequently.

- **TLP Processing Hints**

It adds the possibility to use cache inside Switches and the root complex to
alleviate the need for RAM usage. The idea is similar to the idea of ​​adding
cache to processors; adding a small amount of very fast memory to save soon
needed data is a more efficient approach than saving this data in bigger and
slower RAM.

- **Resizable BAR Capability**

It replaces the BAR registers from the header with bigger registers in this
capability structure, allowing bigger memory space allocation for Functions.

- **Access Control Services**

The PCIe specification allows for peer-to-peer transactions. It is possible and
even desirable in some cases for one PCIe Endpoint to send data directly to
another Endpoint without having to go through the Root Complex. ACS provides a
mechanism by which a Peer-to-Peer PCIe transaction can be forced to go up
through the PCIe Root Complex. ACS can be thought of as a kind of gate-keeper -
preventing unauthorized transactions from occurring.

- **Multicast**

It enables sending packets to more than one Endpoint eliminating the need for
the host to write a unicast packet multiple times to each Endpoint which
improves efficiency of the CPU.

- **Alternative Routing ID-Interpretation**

The motivation for this optional feature is to increase the number of Function
numbers available to Endpoints. Device numbers were useful in a shared‐bus
architecture like PCI but are not usually needed in a point‐to‐point
architecture. When Alternative Routing ID-Interpretation is used the Device
number is always zero and the Function number uses the 5 bits in the ID that
were previously the Device number. Effectively, the Device number goes away
while the Function number grows to 8 bits.

## Summary

PCIe Devices use registers mapped into memory space to allow the OS to know what
Device’s feature set is. These registers are grouped into capabilities
structures defined by PCI Special Interest Group in PCIe specification. This
blog post was only an introduction to PCIe capabilities, the idea is to describe
some of them in detail in future posts.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

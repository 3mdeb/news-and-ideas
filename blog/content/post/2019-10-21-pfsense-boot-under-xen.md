---
title: pfSense firewall boot process optimization under Xen hypervisor
abstract:

cover: /covers/pfsense-logo.png
author: piotr.kleinschmidt
layout: post
published: false
date: 2019-10-21
archives: "2019"

tags:
  - pfSense
  - Xen
  - virtualization
  - hypervisor
  - firewall
categories:
  - Firmware
  - OS dev

---

## Introduction

Network devices, such as modems, routers or servers are largely prone to cyber
attacks. Their security issue is a priority if we want to keep everything behind
them safe. As a solution user might choose from many available firewall
softwares.

However, skeptics will say that this is still not enough, because how they can
be sure if that software is in 100% compatible with their hardware? We are those
skeptics... and we would like to introduce pfSense firewall running in virtual
machine under Xen hypervisor. In that blogpost I focused only about boot process
and what changes could be invoked to improve it.

## pfSense, Xen, hypervisor... what is this all about?

pfSense is an **open-source firewall** (and router itself) based on FreeBSD
distribution. It has a lot of useful features:  high performance, scalability,
management via web interface, large community support and many others. No wonder
it is very popular and commonly used by companies and private users. However,
its implementation is not always so straightforward. Basically there are two
approaches:

- bare-metal pfSense - implemented directly on the firmware
- pfSense in virtual machine managed by **hypervisor**

As I mentioned earlier, we decided to implement pfSense in virtual machine under
**Xen hypervisor**. Second type of implementation was also used by us, but only
as a comparative test.

For better understanding our build configuration, you should be familiar with
some basics about virtualization, hypervisors and Xen itself. I will introduce
those issues at high-level overview It should be enough to understand topic of
that blogpost, but if you are more interested in those fields and want to read
about details I refer to [red hat
article](https://www.redhat.com/en/topics/virtualization/what-is-virtualization)
and to our [blogposts](https://blog.3mdeb.com/tags/virtualization/) with
*virtualization* tag.

### Virtualization

Virtualization is a technology which let you run several, different environments
(e.g. operating systems) on one physical machine. Very important is fact that
all those environments are run in parallel, which significantly increases
efficiency. Differences between them mainly refer to supported hardware (e.g.
architecture, controllers, peripherals etc.), way of operation and application.
Virtualization technology concept is shown in the picture below.

![virtualization](/img/virtualization-overview.png)

As you can see, there is an additional `virtualization layer`. That layer is
mostly implemented as `hypervisor`.

### Hypervisor

Hypervisor is a software which manages all virtual machines running on it. It is
a middleman between hardware and every environment which user wants to create on
the machine. If you think about virtualization technology, hypervisor is its
essential part. In our implementation of pfSense firewall we used **Xen
hypervisor**. It is a open-source project supported by many companies, which are
firmware and IT market leaders. I won't elaborate about Xen. Most features you
need to know are:

- it is hypervisor type 1 - operates directly on the hardware, gaining full
  control over it
- can be built from source - that approach allows us to customize Xen to our
  needs
- is well-documented and largely supported- many issues are described in
  official documentation or they are solved by community

> Virtual machines are very often called *guest*. Hypervisor is called *host*.
That terminology is also used further in that blogpost.

## pfSense booting

As I mentioned earlier, there are actually 2 implementations of pfSense:
bare-metal and with Xen. First one is used as reference one. If virtualized
pfSense could approach to reference values, then it is considered as
well-implemented.

Configurations for both realizations are shown in the table below.

|             |      pfSense bare-metal     | pfSense as Guest Virtual Machine |
|:-----------:|:---------------------------:|:--------------------------------:|
|  version    |  2.4.4-RELEASE-p3           |         2.4.4-RELEASE-p3         |
|run platform |  PC Engines apu2d4          |         PC Engines apu2d4        |
| CPU        |AMD Embedded GX-412TC, quad core|AMD Embedded GX-412TC, quad core|
| firmware    | coreboot v4.10.0.2          |coreboot v4.10.0.1 commit 468fd08 |
| Hypervisor  | -                           |   Xen 4.13-unstable              |
| boot drive  | SD card SanDisk Ultra 16GB  | SD card SanDisk Ultra 16GB       |

What we wanted to gain is to have boot time as short as possible. For bare-metal
case boot time is considered as time from power on platform to enter pfSense
main menu. For VM implementation, it is measured from creating VM in Xen to
enter main menu. In both cases every possible delay related to firmware was
turned off.

### First attempt

### pfSense config adjustment

### VM creation config adjustment

## Summary

Summary of the post.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

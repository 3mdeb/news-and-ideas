---
title: Open, innovative and extremely secure - OPNSense under Xen and TrenchBoot
abstract: Our experience and efforts in virtualization and security field, set
          new requirements and challenges for us. Combining them together,
          emerged our brand-new product. Let me introduce OPNSense running under
          Xen with TrenchBoot support...

cover: /covers/
author: piotr.kleinschmidt
layout: post
published: false
date: 2020-02-19
archives: "2020"

tags:
  - OPNSense
  - Xen
  - TrenchBoot
  - virtualization
  - hypervisor
  - firewall
categories:
  - Firmware
  - OS dev
  - security

---

## Introduction

Before reading this article I strongly recommend to get familiar with 3 other
ones, which surely make virtualization concept easier to understand:
- [Xen Project](https://blog.3mdeb.com/2020/2020-02-05-meta-pcengines-xen/)
- [pfSense under Xen part 1](https://blog.3mdeb.com/2019/2019-11-06-pfsense-under-xen-introduction/)
- [pfSense under Xen part 2](https://blog.3mdeb.com/2019/2019-12-13-pfsense-boot-under-xen/)

As above articles give basic knowledge and explanations, I assume you already
know what is Xen, virtual machines, hypervisor and other related stuff. If yes,
then we can move on to the essential part of this article.

## Security, protection, confidence and... open source?!

You might wonder many times - how to make sure that my device is secure? Who can
ensure me that my data will not be stolen? How to protect myself against every
hacker attack? Unfortunately, there is no definitive and clear answer for above
questions. Hardware, firmware and software safety is a complex issue, which
should be analyzed for risk factors specific for given part. Only then, you can
try to join all security together and prepare, as title suggest, extremely
secure platform.

// Description, why it is better to use open source solutions and what
// restrictions do we face off in our challenge.


// Next sections describes, how we solve individual problems to meet all
// requirements. These sections should only bring readers closer to the subject -
// - high-level overview  
## Hardware protection

// TPM description and usage

## Firmware protection

// coreboot and TrenchBoot - SRTM and DRTM

## Software protection

// virutalization - OPNSense (with WiFi) under Xen

## Secure update

// LVFS/fwupd

## Our implementation

// Description of our implementation of all above features
// with demo and performance tests


## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

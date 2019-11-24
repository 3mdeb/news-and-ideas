---
author: Piotr Król
layout: post
title: "How to build mainline coreboot for apu1d"
date: 2017-08-02 18:21:02 +0200
comments: true
categories: apu1 pcengines coreboot
---

Because of coming coreboot 4.7 and changes [that it will introduce](https://www.mail-archive.com/coreboot@coreboot.org/msg49234.html) I
decided to refresh my memory about [apu1d platform](http://www.pcengines.ch/apu1d.htm).

{image tbd}

apu1d is AMD T40E based device that can be used as customizable router, which
is supported by coreboot since end of 2014.

## Building mainline coreboot firmware for apu1d

```
git clone https://review.coreboot.org/coreboot
cd util/docker
make coreboot-sdk
make docker-build-coreboot
```

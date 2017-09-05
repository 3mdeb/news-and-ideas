---
ID: 62665
post_title: UEFI from Linux enthusiast perspective
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/uefi-from-linux-enthusiast-perspective/
published: true
post_date: 2012-01-15 23:04:00
tags:
  - UEFI
categories:
  - Miscellaneous
---
Another interesting topic with which I am dealing with recently is the
[UEFI](http://www.uefi.org/home/). As we read on wikipedia: "The Unified
Extensible Firmware Interface (UEFI) is a specification that defines a software
interface between an operating system and platform firmware.". The purpose of
this specification is to create something what in the future fully replace the
BIOS.

Of course, as always in such a situation, I wonder what OpenSource and Linux
gurus have to say. A brief googling and I found
[this](http://kerneltrap.org/node/6884). On the one hand are noticeable
advantages: better design, formalized structure of the code, the C programming
language, but you can feel that community fears and feared that the "standard"
will be used in an inappropriate manner. Therefore, I regularly read
[LWN](http://lwn.net/) RSS feeds, and it seems that on the horizon you can see
already the first ideas on how to use UEFI to limit freedom. You can read about
it in this article: ["SFLC: Microsoft confirms UEFI fears, locks down ARM
devices"](http://lwn.net/Articles/475359/).  

Personally, I really do not like it, because I believe that everyone who buys
the equipment has the right to exploit its capabilities in such a manner it
deems appropriate.

Of course, as usual, I change the subject. I wanted to write about the project
[TianoCore](http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=Welcome),
which is an open source implementation of UEFI implemented by Intel. When you
do not have the strength nor the resources to fight the system, use the system
to gather strength and resources, and then start fighting. So in the next post
I will try to describe my first experience with
[EDKII](http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=EDK2)
in emulated environment of QEMU.
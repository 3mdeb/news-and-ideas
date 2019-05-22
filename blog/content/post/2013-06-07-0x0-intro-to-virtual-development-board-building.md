---
ID: 62816
title: '0x0: Intro to Virtual Development Board building'
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/0x0-intro-to-virtual-development-board-building/
published: true
date: 2013-06-07 01:27:00
archives: "2013"
tags:
  - qemu
  - embedded
  - linux
  - virtual development board
  - VDB
categories:
  - Firmware
---
*   [Preface][1]
*   [First question: How to start ?][2]
*   [Virtual Development Board - table of contents][3]
*   [Kudos][4]

<a id="preface"></a>

### Preface

There are many reasons why ambitious programmers should care about huge rush in
embedded market. IMO there is great potential in it. I don't want to go deep
into this but take a look at all tablets, phones, smart TVs and other cool stuff
like wireless in you washing machine or refrigerator (ok this two are right now
only a gadgets :) ). This is all embedded. Another thing is that wages of
experienced embedded developers are really high. This environment is very
interesting. A lot to learn, a lot to do, so why not get your hands dirty?

<a id="first-question"></a>
### First question: How to start?

To do real embedded development, to learn the most, you simply buy hardware like
all this `${animal}board (animal={panda,beagle,hawk})`. This is the best way but
if you're beginner (like me) you probably don't want to spend $50 for stuff that
you throw away after month because you don't like to deal with it or problems
are not on your level, than maybe you should take a look around and wonder if it
is possible to build virtual environment to check what kind of problem you may
encounter learning embedded ? BTW this is cheap and fun, so potential ROI is big
enough to try. IMHO this is where world going: proof of concept embedded
platforms affordable for common man (not only for US/West Europe), testing
environment based on virtualized/emulated solution, to check basic features,
speed up testing, development and deployment. That's why we see so active
development of software like Qemu/KVM.

<a id="virtual-development-board"></a>
### Virtual Development Board - table of contents

I realize that it is achievable and I will learn a lot trying to implement this
idea. Finally I was convinced reading [this][5] two years old article on
[eLinux.org][6]. I decide to divide this article on few parts because IMHO it
was to big to read it at once. Also people interesting in particular topic won't
have to scrolling `>2k` words post. List of all articles in this series:

1.  [Qemu as an environment for embedded board emulation][7]
2.  [Toolchain for Virtual Development Board][8]
3.  [Embedded board bootloader][9]
4.  [Linux kernel for embedded system][10]
5.  [Qemu network configuration and tftp for Virtual Development Board][11]
6.  [Root file system for embedded system][12]

<a id="kudos"></a>
### Kudos

At the and of this intro I want to give big kudos to all those hackers without whom creating this article would not be possible. Thanks for sharing your knowledge. Every time when I use knowledge that found by googling I'm trying to stick link for further reading.

####[*Enjoy!*][13]####

 [1]: /2013/06/07/intro-to-virtual-development-board-building/#preface
 [2]: /2013/06/07/intro-to-virtual-development-board-building/#first-question
 [3]: /2013/06/07/intro-to-virtual-development-board-building/#virtual-development-board
 [4]: /2013/06/07/intro-to-virtual-development-board-building/#kudos
 [5]: http://www.elinux.org/Virtual_Development_Board
 [6]: http://www.elinux.org
 [7]: /2013/06/07/qemu-as-an-environment-for-embedded-board-emulation/
 [8]: /2013/06/07/toolchain-for-virtual-development-board/
 [9]: /2013/06/07/embedded-board-bootloader/
 [10]: /2013/06/07/linux-kernel-for-embedded-system/
 [11]: /2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/
 [12]: /2013/06/07/root-file-system-for-embedded-system/
 [13]: /2013/06/07/qemu-as-an-environment-for-embedded-board-emulation

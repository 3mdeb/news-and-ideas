---
ID: 62826
title: '0x1: Qemu as an environment for embedded board emulation'
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/0x1-qemu-as-an-environment-for-embedded-board-emulation/
published: true
date: 2013-06-07 08:27:00
tags:
  - qemu
  - linux
  - virtual development board
  - emulation
  - VDB
categories:
  - OS Dev
  - App Dev
---
## Table of contents

*   [Introduction][1]
*   [Compilation][2]
*   [Kudos][3]

<a id="intro"></a> 
### Introduction QEMU is a CPU emulator using dynamic binary translation to convert guest CPU instructions into host CPU instructions

[[1]][4]. It supports many architectures from x86, through ARM and MIPS, to MicroBlaze. According to compilation configuration target list QEMU targets 26 different softmmu types. Only for ARM it supports 33 machines (like ARM Versatile/PB (ARM926EJ-S) or Samsung NURI board (Exynos4210)) and 28 CPUs (with cortex-a9 and pxa270). It gives access to network, storage, video, usb, serial and other peripheral, also user defined. It is developed under GNU GPL, so everybody are free to make modifications, improve and extend it. This properties makes QEMU very good candidate for virtual board emulator. <a id="compilation"></a> 
### Compilation Let's start creating our Virtual Development Board. As usually I will use latest greatest version from git: 

<pre><code class="bash">git clone http://git.qemu.org/git/qemu.git
</code></pre> Compile it and install. Right now I will use only 

`arm-softmmu` target because it will emulate whole arm system for me. ARM right now dominated big part of embedded market but we will see if situation won't change in feature. 
<pre><code class="bash">cd qemu
./configure --target-list=arm-softmmu
make
make install
</code></pre> During configuration process you can encounter lack of 

`pixman`, just accept qemu offer to initialize it as a submodule. 
    git submodule update --init pixman
    make # restart compilation process
    make install
     If compilation ends without problem than our first component is ready to use. Right now we can emulate our ARM based board with many types of CPUs. List of all available can be retrieved by running command 

`qemu-system-arm -cpu ?`, list of emulated machines by `-M ?`. Now, let's talk about [toolchains][5]. <a id="kudos"></a> 
### Kudos [1] 

[Dynamically Translating x86 to LLVM using QEMU][4]

 [1]: /2013/06/07/qemu-as-an-environment-for-embedded-board-emulation/#intro
 [2]: /2013/06/07/qemu-as-an-environment-for-embedded-board-emulation/#compilation
 [3]: /2013/06/07/qemu-as-an-environment-for-embedded-board-emulation/#kudos
 [4]: http://infoscience.epfl.ch/record/149975/files/x86-llvm-translator-chipounov_2.pdf
 [5]: /2013/06/07/toolchain-for-virtual-development-board
---
author: Piotr Król
layout: post
title: "Initial coreboot triage on SolidRun SolidPC Brasswell SoM"
date: 2017-07-14 17:22:27 +0200
comments: true
categories: solidrun coreboot uefi bios
---

Some time ago I was approached by customer with request of porting coreboot to
SolidRun SolidPC platform. I obtained hardware but deal was never closed. This
board took some dust, but I finally decided to refresh it and see what this
hardware can do. Unfortunately board appeared to be bricked. I tried to resolve
that issue, by [posting on SolidRun forum](http://forum.solid-run.com/linux-kernel-bootloaders-and-bios-f40/is-my-solidpc-broken--t3242.html).
Unfortunately this sub-forum seem to quite dead since no one answer.

I like the platform and see potential opportunities with using it especially
for firmware research needs. Meanwhile I also worn on CorebootPyaloadPkg, so I
think output of that can used with SolidPC.

All modifications I pushed [here](https://github.com/3mdeb/Solidrun-Braswell-SOM-Coreboot) with intention of further mainlining.

## Restoring G33KatWork work

First I followed Andreas instruction.

```
git clone https://github.com/3mdeb/Solidrun-Braswell-SOM-Coreboot.git
cd Solidrun-Braswell-SOM-Coreboot
git clone --recursive https://github.com/3mdeb/coreboot.git -b solidpc-origin
cd coreboot
patch -p1 < ../solidrun.patch
mkdir -p 3rdparty/blobs/mainboard/solidrun/braswell_som
cp -rf ../solidrun_braswell_blobs/* 3rdparty/blobs/mainboard/solidrun/braswell_som
cp ../config .config
```

## Hardware connection

Most stuff was greatly described on [SolidPC wiki](https://wiki.solid-run.com/doku.php?id=products:ibx:software:development:bios:dediprog)
the only change I have in my setup is that I used SF100 instead of SF600, but
in this situation it doesn't matter.

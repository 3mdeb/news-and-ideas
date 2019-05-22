---
ID: 62871
title: Linux (Debian Wheezy) on Lenovo y510p
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/linux-debian-wheezy-on-lenovo-y510p/
published: true
date: 2014-05-16 22:36:27
archives: "2014"
tags:
  - linux
  - Debian
categories:
  - OS Dev
---
After long analysis I decide to buy new laptop. I had about $1000
(or 3000PLN) and most important things to me were:

* i7 CPU - because of performance (of course at least 4700 series)
* SSD - again performance
* 17.3” - working space
* no OS/FreeDos/Linux - I will not pay additional fee to M$ for system that I won’t use
* Full HD resolution
* at least 8GB RAM
* non-glare display

First I realize that my budget is to small for such a hardware. Second as always
we have to deal with trade-offs, so you cannot have everything. In final round I had two candidates [Acer Aspire V7-772G](http://www.notebookcheck.net/Review-Acer-Aspire-V3-772G-747A321-Notebook.93916.0.html)
and [Lenovo IdeaPad y510p](http://www.notebookcheck.net/Review-Lenovo-IdeaPad-Y510p-Notebook.97470.0.html).

I resign from using 17.3" display because most of them in my budget range were
glare and without Full HD support. After reading Newegg reviews about both
laptops I choose Lenovo. It is better brand with better design (ie. metal lid),
other parameters, except RAM expansion possibilities, are the same.

## First boot
Today I have it on my desk and trying to install Debian Wheezy. I put Debian
netinst in drive and get wonderful UEFI message :)

{% img center /assets/images/cdrom-blocked.jpg 450 450 'image' 'images' %}

I figure out that I have to disable my last days favourite feature from M$ -
namely Secure Boot. I was surprised when I realized that there is no hot key to
enter UEFI Setup. Instead of hot key Lenovo decide to put small button (called
Novo Button) on the side of laptop near power socket. Quite interesting idea
when taking into consideration that InsydeH20 Setup Utility doesn’t provide
much of functions, so we end with entering setup maybe dozen of times during laptop
lifetime. Also I think it can improve boot time a little bit because UEFI don’t
have to poll for user input during hot key pushing time window.

## Disable secure thing

So to disable this `feature-that-name-should-be-doomed` you have to enter Setup
using Novo Button and switch to Security tab. At first glance you can find
option called `Scure Boot` set to `[Enabled]`. Description of this option said
`Enabl or Disable Secure Boot support`. Don’t be naive this button won’t do
what you want. To disable this devil work you have to push enter on `Reset to Seupt Mode`
option, which cleans keys database. Don't panic your database of
vendor keys will not disappear you can restore it anytime you want using
`Restore Factory Keys`. BTW I didn't found any information about it in `User Manual`.

{% img center /assets/images/uefi-security.jpg 640 400 'image' 'images' %}

## Installation

Next surprise after booting netinst (it works in UEFI mode, so no need to
switching to legacy) is that Debian `7.5.0` was unable to find driver for
on-board LAN card.So I installed my Debian over wireless Intel card. Wheezy use
`3.2.0` kernel which doesn't not contain `alx` driver with support for Qualcomm
Atheros QCA8171.

Note that there is possibility to load new driver from pendrive during
installation. But best way would using netinst with Jessie or Sid. You can get it [here](http://www.debian.org/devel/debian-installer/).
I with to knew that before I started to fight with stable version.

## Xorg crash

After all above I booted my favourite distro and it welcomes me with blinking
cursor and Xorg crashed because of:
```
(EE) VESA(0): V_BIOS address 0x0 out of range
(EE) Screen(s) found, but none have a usable configuration
```

During long an unequal battle, which was full of google hits. I figured out
that best way to improve awful situation in Debian stable for y510p is to
upgrade to Sid (unstable). Of course I messed up this because I tried move from
stable to unstable skipping testing.

I found on Debian pages that upgrade to `unstable` should be performed through
`testing` version. This mistake cost me time, because I have to install OS
second time after breaking my Gnome installation.

## Final considerations

Upgrade to latest kernel version helps a lot but there are still many things to
do. Right now I'm using Intel integrated graphics. It would be great to enable
second card GT755M and try Optimus technology. Especially when I would like to
rest from coding and try to relax playing Heroes Of Newearth. I also think
about running CUDA on my setup. Next thing for me will be testing vitalization
performance. If I will find reliable method to enable GT 755M on Debian I will
let you know.

I compiled edk2 and linux kernel. I see big difference in performance and
that's most important thing to me.

Some of you will say that Linux is a piece of $!#@, but for me this is very
good opportunity to verify my skills and contribute to community. During my
research about y510p I found also complains from Windows users that not all
works smoothly (Optimus), so there are also cons on the other side. Finally if
you won't deal with problems simply use Mint or Ubuntu there is much better
support there. By the way I think that I'm immune to problems with my operating
system ;)

{% img center /assets/images/lenovo-y510p.jpg 640 400 'image' 'images' %}

Thanks for reading.

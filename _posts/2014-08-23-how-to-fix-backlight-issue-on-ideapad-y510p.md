---
ID: 62886
post_title: >
  How to fix backlight issue on IdeaPad
  y510p
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/how-to-fix-backlight-issue-on-ideapad-y510p/
published: true
post_date: 2014-08-23 23:49:03
tags:
  - linux
  - Debian
categories:
  - OS Dev
---
Today I decide to switch to latest kernel (`3.17-rc1`) on my IdeaPad y510p. I
hit only one annoying problem until now - after booting my main screen was dimmed. I
tried all instructions from top google hits for all possible configurations of
keywords `linux`, `y510p`, `backlight issue`, etc.

Especially I tried all methods from [Arch Wiki](https://wiki.archlinux.org/index.php/Intel_graphics#Backlight_is_not_adjustable).

Finally I found solution, by greping `modinfo` for my Intel graphics card:

```
[23:55:24] pietrushnic:~ $ sudo modinfo i915|grep backlight
parm:           invert_brightness:Invert backlight brightness (-1 force normal, 
 0 machine defaults, 1 force inversion), please report PCI device ID, subsystem 
vendor and subsystem device ID to dri-devel@lists.freedesktop.org, if your 
machine needs it. It will then be included in an upcoming module version. (int)
```

So simple modification in `/etc/default/grub` by adding kernel parameter to
`GRUB_CMDLINE_LINUX_DEFAULT` fix the issue:

```
# If you change this file, run 'update-grub' afterwards to update
# /boot/grub/grub.cfg.
# For full documentation of the options in this file, see:
#   info -f grub -n 'Simple configuration'

GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="rcutree.rcu_idle_gp_delay=1 i915.invert_brightness=1"
GRUB_CMDLINE_LINUX=""
(...)
```

After that:

```
sudo update-grub
```

And all things should work fine.
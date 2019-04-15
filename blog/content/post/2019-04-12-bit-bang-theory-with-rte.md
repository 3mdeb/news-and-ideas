---
title: The Bit Bang Theory with RTE
cover: /cover/cover_01.jpg
author: lukasz.wcislo
layout: post
published: false
date: 2019-04-12

tags:
  - RTE
  - OpenOCD
  - Bit Banging
  - SWD
  - STM32
categories:
  - Firmware
  - Miscellaneous
  - Security
  - Manufacturing

---

When you are working with firmware and embedded systems usually you flash some
microchips at least several times a day. Often you use SWD (Serial Wire Debug)
interface to do so. It is fast and simple, but requires additional device, a
programmer, witch sometimes tend to crash. RTE (Remote Testing Environment),
which we use to control devices under tests, is equipped with many interfaces to
contact with our device in any possible way. But not SWD. The whole idea is to
emulate it with dedicated software and make use of the state of RTE pins for all
parameters of the signal: timing, levels, synchronization, etc. and use it to
flash microchip.

This technique is called **The Bit Banging**.

So, lets assume, that we have some board with chip, i.e. STM32 series, which is
very popular, and a binary image, which we want to be flashed on it. To do it,
at the very beginning we need some software that provide us a way to
manipulate state of RTE pins as if they were pins of a programmer. As we prefer
open source we used OpenOCD (Open-On-Chip_Debbuger). This is well developed
tool for such jobs, but, unfortunately, it doesn't support Orange Pi Zero. And  
this is our microcomputer assembled with RTE.  

It doesn't support it YET.

After compiling OpenOCD and all the required libraries on Orange Pi Zero we've
compared pinout of it with pinout of Raspberry Pi 1, which on the first sight
has been similar. It was the same similarity as between a dolphin and a shark,
as we get close to it it appeared to be much different. The only thing the same
was a number of pins.

After studying of RTE and Orange Pi Zero pins usage and accessibility we've
choose three sets of pins, that we considered to be our candidates. SWD
interface requires three connected routes (SWDIO - data in and out, SWCLK -
clock synchronization and NRST - reset signal) and ground connection. Next step
was to create configuration file to translate OpenOCD which pins we want to be
used and in what purpose. It also had to be described what OpenOCD should try to
pretend to be (it can emulate many interfaces).

```
interface sysfsgpio
reset_config srst_only srst_push_pull
sysfsgpio_swd_nums 11 12
sysfsgpio_srst_num 6
```

 


> post cover image should be located in `blog/static/cover/` directory or may be
  linked to `blog/static/img/` if image is used in post content

> author meta-field MUST be strictly formatted (lowercase, non-polish letters):

```
author: lukasz.wcislo
```


> remember about newlines before lists, tables, quotes blocks (>) and blocks of
  text (\`\`\`)

> copy all post images to `blog/static/img` directory. Example usage:

![alt-text](/img/file-name.jpg)

> remember to change published meta-field to `true` when post is done

## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

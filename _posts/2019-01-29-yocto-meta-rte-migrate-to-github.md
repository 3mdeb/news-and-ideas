---
post_title: Yocto meta-rte migrate to GitHub
author: Marta Szelecka
layout: post
published: false
post_date:

tags:
    - Yocto
    - meta-rte
    - linux
    - rte
categories:
    - OS Dev
---

## Yocto meta-rte migrate to GitHub

We are happy to announce that our 3mdeb’s Yocto `meta-rte` is now available on our GitHub.

But let's say briefly what the Yocto Project is and why we decided to work with it.
First of all, like everything that we love the most, Yocto Project is open sourced.
The project is hosted by the Linux Foundation and gives you templates, methods, and set
of interoperable tools for creating OS images for embedded Linux systems.
Secondly, the Yocto project is used by many mainstream embedded Linux providers and offers
thousands of packages which are available through layers. What are they? Yocto project
can be used by itself or be extended by meta layers, which are repositories with instructions
(recipes) telling the build system what it should do. By separating the instructions into layers
we can reuse them and share for other users (our 3mdeb’s `meta-rte` is exactly
that kind of layer). Thirdly, with Yocto Project you can bring to life exactly the Linux
you want and need. The project lets you choose your CPU architecture, select footprint size and
remove and/or add components to get the features you want. In addition, it is important to stress
that Yocto project is developed by programming enthusiasts and because we consider ourselves
as one of them we created and now we share `meta-rte`. `Meta-rte` is created for our [RTE](https://shop.3mdeb.com/product/rte/)
(remote testing environment - a hat designed for Orange Pi Zero board, a tool which makes easier
work with firmware debugging tasks). So let's now present some raw data about it:

## Hardware support:

The Orange Pi Zero default config does not enable all of its interfaces.
Following interfaces were enabled in the `meta-rte`
(as devicetree patches and kernel configuration changes) to support the
features of the RTE extension boards:
  * UART (uart2) interface - for RS-232
  * I2C (i2c1) interface - for mcp2301 GPIO expander
  * SPI (spi1) interface - for flashing external boards' SPI flash chips
  * USB (ehci/ohci 2 and 3) interfaces - for additonal on-board USB connector

## System features:

* minimal image with full support for the target hardware,
* RteCtrl utility - controlling the RTE via REST API calls,
* dual-image OTA upgrades based on the SWUpdate: https://sbabic.github.io/swupdate/swupdate.html
* systemd as init manager
* standard useful system utilities such as:
  * tmux,
  * minicom,
  * openssh-server,
  * full python3,
  * bash shell,
  * etc.
* Utilities for controlling the platform under test via RTE:
  * ser2net - redirecting platform's serial via Ethernet over telnet
  * flashrom - flashing platform's SPI chip,
  * fastboot and imx-usb-loader https://github.com/vitroTV/imx_usb_loader for
    i.MX6 boards flashing,
  * stlink and openocd for STM32 microcontrollers flashing
  * ifdtools, cbftools - utilites useful for coreboot testing

[image]
Here we have our dev version API. It starts automatically and thanks to that you can
start your remote work without any additional configurations.

We all know that using Linux for embedded devices is complicated,
but thanks to Yocto Project bringing embedded devices to market becomes easier, cheaper
and faster. And it doesn't even matter what kind of device it is. In our case, it's 3mdeb's
[RTE](https://shop.3mdeb.com/product/rte/). If you have any questions about rte, `meta-rte`
or you are just interested in embedded systems you can email us at: contact@3mdeb.com.
The confirmation of our competence is our presence on the [Embedded Linux Expert List](https://elinux.org/Experts#The_List)
and [Yocto Project Consultants List](https://www.yoctoproject.org/community/consultants/).

You should also know that anyone can build a system based on `meta-rte`. To do this you will
need a tool named `kas`. Interested? Check our another article:
https://github.com/3mdeb/news-and-ideas/blob/kas/kas.md.

You can also find us on our [official site](https://3mdeb.com/), [blog](https://3mdeb.com/news-ideas/)
and on social media: [Twitter](https://twitter.com/3mdeb_com),
[Facebook](https://www.facebook.com/3mdeb), [LinkedIn](https://www.linkedin.com/company/3mdeb),
[GitHub](https://github.com/3mdeb),
[stackoverflow](https://stackoverflow.com/users/587395/piotr-kr%C3%B3l).

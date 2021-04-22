---
title: "Yocto Project and its components as the Reference OS for Dasharo"
abstract: "Let's dive into the most frequently asked questions regarding Dasharo
           products based on Yocto Project - this blog post will answer what is
           Yocto and what are the reasons for choosing such a solution"
cover: /img/YoctoProject_Logo_RGB.jpg
author: maciej.pijanowski
layout: post
published: true
date: 2021-04-22
archives: "2021"

tags:
  - yocto
  - dasharo
categories:
  - Firmware
  - OS Dev
  - Security

---

## What is Yocto?

The project provides a flexible set of tools and a space where embedded
developers worldwide can share technologies, software stacks, configurations,
and best practices that can be used to create tailored Linux images for embedded
and IOT devices, or anywhere a customized Linux OS is needed.  

~ yoctoproject.com

Yocto is not an Operating System that you can download and use widely on your
devices. It provides the infrastructure Build Tools for creating fully
customized operating systems, that can be adjusted to your hardware and it's
purpose. The customization is based on a Layer Model that allows for combining
related metadata and isolate information for multiple architecture builds
according to their related functionality that can be furhter added flexibly, as
required. 

## Why Yocto Project is the solution?

When choosing Yocto for your amazing embedded solution, you may be sure that it
was a good decision. Yocto is the best choice for the devices that are focused
on data processing or networking, by having a variety of distributions. Provides
a broad support for serial ports and Ethernet, SSH server, and on-target tools
with a full drives support so you don't have to rely on a third-party solutions.

Yocto is an open source project. Companies are increasingly switching to open
source software, as it builds trust in the quality and security, giving full
insight into the source code.

Yocto equips developers with flexible tools, but every tool needs experienced
hands to hammer a cross-compilation environment. Let us help you! Our talented
Yocto developers can take the effort and provide you with a customized result.
3mdeb can professionally select Yocto components that won't burden your
hardware, creating the base for further security and performance boost, that
will allow you to save costs.

## Let us hammer your operating system

If you need a customized Yocto distribution with a maintenance support for your
platform, we can provide you a Yocto Base Image. Created basic system image can
be further expanded with improvements and updates (OTA). Within a *10 days we
will provide you with a ready-to-use binary image file supported with
documentation and the source code on the MIT licence.

## Yocto Update System (OTA)

System update is crucial when providing the security layer to your product. That
is why we have crafted an extension of the Yocto Base Image product, with an
automatic update system. No need for your participation when a new version is
released, keeping your solution simply secured.

## Yocto Best Practices Audit

Do you need to verify your own Yocto solution? We can perform an analysis of
your code suggesting best practices, improvements or support providing updates,
maintenance, or bug-fixing. Audit covers the analysis of the current BSP code,
list of known vulnerabilities (CVE) in the system software, and valuation of a
one-time BSP update or maintenance service

## Dasharo Reference OS

Dasharo Reference OS is a Linux distribution crafted using the Yocto Project. It
is build using the Yocto products and services provided by the 3mdeb. Some of
them are described above. The main goal of the Dasharo Reference OS is to
leverage all of the features provided by the given hardware platform and Dasharo
firmware. You can use the Dasharo Reference OS to unleash the full potential of
your device.

You will likely not use the Dasharo Reference OS in a product directly. Instead,
you can use it to verify all of the Dasharo features. It can serve as a
reference point of porting those features to your custom OS. You can also always
ask us to the work for you. 

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with
us](https://calendly.com/3mdeb/consulting-remote-meeting) or drop us email to
`contact<at>3mdeb<dot>com`. If you are interested in similar content feel free
to [sign up to our newsletter](http://eepurl.com/doF8GX).

More about Dasharo you can read on our website
[dasharo.com](https://dasharo.com/) and on dedicated MkDocs site
[docs.dasharo.com](https://docs.dasharo.com/).

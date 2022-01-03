---
title: PCIe Screamer first look
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/PCIExpress.jpg
author: igor.bagnucki
layout: post
published: true
date: 2022-01-03
archives: "2022"

tags:
  - pcie
  - pciescreamer
  - screamer
  - lambda
  - lambdaconcept
  - sniffer
  - sniff
  - sniffing
  - pci
  - fpga
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

## Why to test PCIe sniffing

The information security is a complicated topic. It needs to be considered on
every step of system design. Additionally, for every system the threat model may
be different.
As a system includes multiple PCIe devices, that i.e. can use system's memory
and be shared to untrusted virtual machine or can themself be malicious there is
a need to protect the memory from DMA attacks executed from PCIe bus.

To avoid this risk there is an option to enable [IOMMU](https://blog.3mdeb.com/2021/2021-01-13-iommu/)
what should fix the problem, but does it really?

To verify that IOMMU really protects from DMA attacks, this functionality should
be tested or in other words, it should be tried to make such attack on a system.

## What is PCIeScreamer

LambdaConcept's PCIeScreamer is an FPGA board based on Xilinx 7 Series XC7A35T.
As the board has PCIe connector, it can be connected as the normal PCIe device
but remains under our comlete control.

## Open-source state in FPGA environment

## Vavado installation problem

## Script tested

## Power problem

## Summary

Summary of the post.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

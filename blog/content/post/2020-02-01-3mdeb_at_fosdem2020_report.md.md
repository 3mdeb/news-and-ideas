---
title: 3mdeb at FOSDEM 2020 report
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: piotr.krol
layout: post
published: true
date: 2020-02-01
archives: "2020"

tags:
  - fosdem
  - conference
categories:
  - Firmware
  - Miscellaneous
  - Security

---

On Saturday, with Michał Żygowski, we decided to go to Hardware aided Trusted Computing devroom.

Some general considerations:
1. We would like to have disposable laptops available for 3mdeb employees
2. Laptop should give secure access to comapny infrstructure for employees, which can be easily wipe out
3. There should be support for high-end security features SRTM+DRTM
4. Laptop would be wiped every time we getting back from conference

How secure access from unknown location would look like?
- we need tamper proofs after getting though custom clearance 
- attestation to USB crypto token

# Be secure with Rust & Intel SGX

First presentation was from UC Berkley Ph.D. about Rust and SGX, the thesis is
that most CVE detected in M$ products are releated to memory safety, because of
that Rust is the language that address most of issues related with it.

Rust:
- type safety
- statuc analysis built right into
- convinient error handling

Parsing is easy with anything except C. Rust has good features support that. Of
course enclave code should contain mininimal parsing code.

In architecture we should consider secure enclave as server, with that
attestation an identity is easy.

In general presentation was pitch about EDP Fortanix, which is SGX+Rust+Srevice
API, which simplifies interaction between secure enclave and system.

During demo was show how simple it is to run sample program in Rust in secure SGX encalve.

There was extensive discussion including concerns about all recent SGX
vulnerabilitie and if in that light keepeing private key in enclave is till
secure, the answer was more about mitigations
- update your microcode to most recent (to the one that contain fix)
- reprovision with new key in case of any issues

# The Confidential Consortium Framework

A framework to build secure, highly available, and performant applications that focus on multi-party compute and data

Second was from M$(?) CCF, in general it was about multi-party applications. We
would like to achive ditributed trusted computing (encyrpted integrity
proitected memory, remote attestation).

It looks like everywhere there is discussion about TLS session which terminates
in secure enclave, this is to hide traffic against host that enclave running
on. There is still need for time source, time is fetched from host and is not
considered trusted.

Key point of the system was to describe how mutli-party application can work in
similar was we set ruling, for example architecture can have voters that decide
about various things e.g. adding user changing community rules etc. It looks
like presentation discussed implementation/design of decision making system.
Of course everything use enclaves and secure communication.

Other case is code update, so based on votes we can decide if new version is
acceptable to be used, if there is different result we recover to previous
version. Definitely whole talk was focused on cryptocurrency related use cases.

Attestation relies on Intel attestation server, but M$ got their own and AFAIK
anyone can setup its own based on 

# Break for discussion with Daniel Kiper and dev room organization

Meanwhile we discussed with Daniel about devroom , took devroom organizer
t-shirts. Daniel rise important question about TrenchBoot in light of Intel
TXT, about teardown of DLME  and I started to wonder how this applies to AMD.

# A tale of two worlds

I get back to Hardware aided Trusted Computing, for attack-oriented talk. Room
was full of people at tis point.

Talk based on paper.:w

Interface is where attackers are intersted in (its like in old fortress break
in). Presenter also show comparison of various TEE enclaves and mentioned that
there are 5 CVEs coming which are under embargo.

Trusted computing in cotect of this room concentrate on secure enclaves, why?
Probably because everyone already things systems and platforms are doomed.

There are couple classes of attacks we should care, hypervisor attacks, CPU
attacks and enclave attacks. Solution for first class is secure enclave,
malusious hypervisior should no access content of enclave. Second class is
problematic, but not easy to exploit and we believe hardware vendors solve that
at some point. Third class is laos interesting and this is what about this tlak
was. It happen that interface to enclave can be buggy and this can be exploited
much simpler then other calsses.

Let's imageing we can have some ABI at the entrance of enclave that can
validate what coming to enclave and expose some API to application inside
enclave. This design split responsibilities in enclave.

There are many vulnerabilities across TEEs related to flags, stack pointeres
and registry leakage. More complex is CPU architecture more attack vectors and
problems you may face. RSIC-V seem to be good place to go here.

In x86 you can change bahvior of instruction by CPU flags (RFLAGS.DF). What can
go wrong, before entering enclave bad actor can set that flag, this may cause
memory corruption inside enclave. there is also AC flag, which is alginment
check. This can be helpful in side-channel attack since it leaks bit of
information about code in enclave each time alignment exception is triggered

On the another level, after enclave ABI level, there is API provided inside
enclave. For example you can pass pointer to encalve that points to untrosted
world, but malcious actor can replace pointer with adddress of something what
is inside secure world. Interestingly this attacks works.

There are some other attacks based on IRQ handler lookop and execution time,
there was special framework created for that called sgx-step.

From TEE frameworks Rust-EDP seem to be quite good quality. Very good talk over
all. Presenter advocate for RISC platform, but TEE thinga are not so
production-ready as advertised. Key point is that TEE is based on CISC.


Interesting things to check:
- sancus 16-bit open source hardware processor for enclaves

# Pengutronix: building products with OP-TEE

Pengutronix doing integration of OP-Tee into BSPs. This talk was about
TrustZone  and started with idea how things work.

Pengutronix worked mostly on i.MX6 integrating OP-TEE. There is also support
for RPi3 in OP-TEE. Motivation for talk is to secure and harden OP-TEE for
production workloads. Also make sure that fixes are contributed back. The idea
is that atendees may help fixing problems and implmenting features for STM, TI
and other not yet well suported solutions.

It is important to add some protection of RAM for secure world behaving like
DDR fiewall. Upstream dirver for that is already implmented. In I.MX6 there is
TZC3809 controller.

i.MX6UL may not have enough SRAM. This talk definitely contain lot of valuable
things that we can leverage for our customers using NXP.

QUestions from me:

1. Did Pengutronix perform any DMA attacks against OP-TEE on i.MX6? If yes can you reveal details. - not yet tried.
2. Musterinf enable bit in i.MX6

# Demo: SGX-LKL

All problems in enclaves lead to generation of more frameworks containgin shim
laher that separate internal application in enclave from external interface by
adding sanitizing and checks on the boundary, Use muslc as libc used in side
enclave.

It supports features like fiulesystem in enclave disk encryption and integrity,
Has limited interface with host and remote attestation.
 
Demo show Wireguad VPN between 2 enclaves.


## Open Source Firmware, Bootloaders and OpenBMC devroom

This room was created as collaboration between Piotr Król (3mdeb) and Daniel Kiper (Oracle, GRUB). Room was great success.

### Open source UEFI and TianoCore

### Discover UEFI with U-Boot

This was very interesting talk how to solve some problems of bootloader
ecosystem fragmentation and fact that some projects already implemented
features needed for others.

### Heads OEM device ownership/reownership : A tamper evident approach to remote integrity attestation

Current status and future plan : A call for collaboration

### Improving the Security of Edge Computing Services

Update status of the support for AMD and Intel processors

### Introducing AUTOREV

An automatic reverse-engineering framework for firmware BLOBs

### Look at ME!

Intel ME firmware investigation

### Capsule Update & LVFS: Improving system firmware updates

Improving reliability and security by simplifying distribution of firmware updates

### Opening Intel Server firmware based on OpenBMC example

# Day 2

## BSP generator for 3000+ ARM microcontrollers

AdaCore company representatives gave talk about MCUs supported by Ada, there
are over 4000 supported MCUs. Talk discussed how ecosystem managed to add so
many MCUs and keep sanity.

Interesting is SPARK.

CMSIS:
- set of software interfaces for debugging, drivers, RTOS, neural networks,
  DSPs and more
- packs - the way to distribute software packages, there are PDSC (MCU details)
  and SVD (peripherals description)

How all that data can be used?
- SVD2Ada
- startup-gen - use PDSC XML files to prepare Ada GPR files

At this point they can create Ada/SPARK binding (BSP) for any Cortex-M microcontroller.

Embedded Rust people developing vey similar project.

## On-hardware debugging of IP cores with free tools

Verilog and VHDL use depends on what side of Atlantic you are ;)
Free software is available for HDL developers.

Common way to debug hardware is blinking LED.

Tlak was very well prepared showing various approaches to FPGA programming and
debugging.

TCL is still used by Verilog/VHDL developers in similar way as regular
developers use make. Most important work that should be done is tools
integration.

##  Continuous Integration for Open Hardware Projects

OpenTec Gmbh founder as well as co-founder of FOSSASIA. They started Pocker
Sicence Lab project. There is Android associated application and device can be
used as many measuring tools.

Other project is drawing on led badge. Another one is Neurolab which collects
brain waves for checking the mood and/or related data.

CI for hardware, the goal for CI is to reduce the time of integration.

There are many things to do to improve building hardware
- testing
- BOM creation automation
- 

## Open Source Firmware Testing at Facebook

If you don't test your firmware, your firmware fails you

This talk was very crowded, this talk was sent for open source firmware
devroom, but we rejected it mostly because of too many talks.

One of the goals of Facebook infrastructure plan to be generic. They claim that
due diligence and no system fulfilled their needs.

Unfortunately our opinion is that this project contribute to automated
validation systems market fragmentation and will cause more problems to have
interoperability between systems. We are not exactly understand why not to
follow LF Automated Testing group effort.

##  AMENDMENT How to run Linux on RISC-V

with open hardware and open source FPGA tools

RISC-V foundation is Switzerlang. lowRISC working with Google on OpenTitan, but
organization do intreesting things and they have RISC-V implementation which an
be flashed on FPGA and boot Linux.

This is another presentation overviewing topics in this focus on RISC-V. It is rather call for participation then anything innovative.

There was information about cheap RISC0V (13USD) K210, which can boot Linux,
unfortunately tis is NOMMU platform. The way to go now is QEMU.

These year there are 3 processors that coming.

NXP working with open hw group to create:
http://linuxgizmos.com/linux-driven-risc-v-core-to-debut-on-an-nxp-i-mx-soc/

There were many intresting things in this presentation for anyone intrested in RISC-V and FPGA.

## A free toolchain for 0.01 € - computers

The free toolchain for the Padauk 8-bit microcontrollers

Niche talk although probably because of title gathered audience. It was call for participation in SDCC compiler, which is used for 

## Status of AMD platforms in coreboot

Michals talk gathered quite a lot of people interested in history of AMD in
coreboot. This was not first talk that had problem setting up the screen.

Michal started with terminology and moved with history of hardware and how
coreboot supported those various platforms across time.

Over all Michal presented what would be the plans of 3mdeb in area of
supporting old boards.

## Open Source Hardware for Industrial use

OSHW model has benefits for SOC vendors, industrial manufacturers and end users

This talk was by Olimex

Talk was very interested with lot of laughs, becaue of ridiculous istuation and
lack of understanding from Allwinner about open source hardware.

Olimex made a lot of industrial projects with long term support.


## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

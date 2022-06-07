---
title: Minimal OS for Fobnail
abstract: 'The Fobnail Token is an open-source hardware USB device that helps to
           determine the integrity of the system. The purpose of this blog post
           is to present the development progress of this project. During this
           phase, we focused on researching OS for hosting Fobnail Attester'
cover: /covers/usb_token.png
author: tomasz.zyjewski
layout: post
published: true
date: 2022-06-10
archives: "2022"

tags:
  - fobnail
  - tpm
  - attestation
  - security
  - linux
  - yocto
  - xen
  - zephyr
categories:
  - Security

---

## About the Fobnail Token project

Fobnail is a project that aims to provide a reference architecture for building
offline integrity measurement verifiers on the USB device (Fobnail Token) and
attesters running in Dynamically Launched Measured Environments (DLME). It
allows the Fobnail owner to verify the trustworthiness of the running system
before performing any sensitive operation. This project was founded by [NlNet
Foundation](https://nlnet.nl/). More information about the project can be found
in the [Fobnail documentation](https://fobnail.3mdeb.com/). Also, make sure to
read other posts related to this project by visiting
[fobnail](https://blog.3mdeb.com/tags/fobnail/) tag.

## Scope of current phase

This phase covers two main subjects: researching an OS that will run in DLME and running . OS must also be
capable of running Fobnail Attester, communicating with Fobnail Token,
performing attestation, and booting the target OS after successful attestation.
Also, during this phase, we got selected OS running in DLME. We will bring the
functionality required to communicate with Fobnail and attest platform state
during the next phase.

## OS researching

We have conducted research to find out which OS/kernel suits our needs the most.
We need USB drivers, including USB EEM (Ethernet over USB) driver and network
stack. The base choice is Linux which already has all required drivers. However,
we researched the usage of microkernels due to increased security. If minimal OS
got compromised (through its USB or network stack), an attacker could trick
Fobnail into that platform is in a trustworthy state, revealing Fobnail's kept
secrets like cryptographic keys.

We evaluated the feasibility of using microkernel-based OSes (the research
report is available [here](https://fobnail.3mdeb.com/minimal-os-for-fobnail/)).
Many microkernel-based OSes lack the required drivers, ability to boot another
OS, and ability to run as DLME payload. Also, since they are designed for an
embedded environment, they are not portable (across platforms with the same CPU
architecture), which is a serious limitation that would force us to ship many
versions of OS for each platform.

## Why Linux?

We have decided to use Linux for building minimal OS because it already has
everything we need, and other OSes would require a significant amount of work.
In the future, we may use another OS.

## Reference minimal OS for Fobnail Project

We build a minimal OS image for Fobnail Project by using [Yocto
Project](https://www.yoctoproject.org/) our
[meta-fobnail](https://github.com/fobnail/meta-fobnail) layer and
[kas](https://github.com/siemens/kas) container. It is based on
[TrenchBoot](https://trenchboot.org/) project and releated meta layers:
[meta-pcengines](https://github.com/3mdeb/meta-pcengines) to provide board
support package for PCengines apu2 and
[meta-security](https://git.yoctoproject.org/meta-security/) to use additional
usefull software like `tpm-tools` package.

### meta-fobnail layer

Our minimal OS is based on the TrenchBoot project, so we use all of their
components to implement fully secured execution flow: GRUB with SKINIT support,
Secure Kernel Loader, and Linux with Secure Launch. All of these components we
got from [TrenchBoot](https://github.com/TrenchBoot/) repositories.

We also add [Fobnail Attester](https://github.com/fobnail/fobnail-attester)
application with required dependencies: `qcbor` and `libcoap`. The application
itself is automatically started on system startup. After positive result of
attestation, we can run the target system from an external device by using
`kexec`.

The process of generating minimal OS is not complicated and looks similar to
building system images from `meta-trenchboot` or `meta-pcengines`. Firstly, we
need to download the latest kas container:

```
$ wget -O ~/bin/kas-container https://raw.githubusercontent.com/siemens/kas/3.0.2/kas-container
$ chmod +x ~/bin/kas-container
```

With that we can build a minimal OS from `meta-fobnail` repository:

```
$ git clone https://github.com/fobnail/meta-fobnail.git
$ kas-docker build meta-fobnail/kas-debug.yml
```

It may take a while (up to a few hours). If building will be finished, the
system image should be available in `build/tmp/deploy/images/fobnail-machine/`.
It was prepared to run from SD card. We need to use `bmaptool` to flash image on
the card:

```
$ bmaptool copy --bmap fobnail-base-image-debug-fobnail-machine.wic.bmap \
    fobnail-base-image-debug-fobnail-machine.wic.gz /dev/sdX
```

### Attestation workflow

A list of steps below describes the workflow of attestation with running
different system from an external device (like USB memory). For purpose of this
example, we used `Ubuntu 20.04 LTS Live` flashed on pendrive.

1. Boot [meta-fobnail](https://github.com/fobnail/meta-fobnail) image in DLME -
   this was described [here](running-os-in-dlme.md).

2. Run attestation server

```
# fobnail-attester
Creating CoAP server endpoint using UDP.
Registering CoAP resources.
Entering main loop.
```

3. Connect Fobnail Token to PC Engines apu2. If the device is detected properly
   system should print following information

```
usb 2-2: new full-speed USB device number 11 using xhci_hcd
cdc_eem 2-2:1.0 usb0: register 'cdc_eem' at usb-0000:00:10.0-2, CDC EEM Device, da:7f:03:e0:57:12
```

4. Wait a few seconds for provisioning and attestation. During this procedure
   `fobnail-attester` should print information about received data

```
Received message: ek
Received message: aik
Received message: challenge
Received message: metadata
MAC:  0: D:B9:53:D2:50
SMBIOSv2
Manufacturer >PC Engines<
Product Name >apu2<
Serial Number >1373268<
Received message: rim
Received message: metadata
MAC:  0: D:B9:53:D2:50
SMBIOSv2
Manufacturer >PC Engines<
Product Name >apu2<
Serial Number >1373268<
Received message: quote
```

5. Attestation was finished successfully when green LED blinked on Fobnail
   Token - see image below

![Fobnail token LEDs](/img/token-led.png)


6. Now we can assume that we are in secure environment, so we will execute
Ubuntu from external memory by using `kexec`

```
# mkdir /mnt/usb
# mount /dev/sda /mnt/usb
mount: /mnt/usb: WARNING: source write-protected, mounted read-only.
# cd /mnt/usb

# kexec -l casper/vmlinuz --initrd=casper/initrd --command-line="$( cat /proc/cmdline )"
# kexec -e
```

After a minute you should be able to login into the Ubuntu shell:

```
[  OK  ] Started Serial Getty on ttyS0.
[  OK  ] Reached target Login Prompts.
         Starting Set console scheme...
Ubuntu 22.04 LTS ubuntu ttyS0
ubuntu login: ubuntu
Welcome to Ubuntu 22.04 LTS (GNU/Linux 5.15.0-25-generic x86_64)
```

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

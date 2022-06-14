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
date: 2022-06-15
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

This phase was carried out to look at how the Fobnail Token can be used in
everyday use and to analyze other elements of the Fobnail Project, such as
minimal operating system. A system image was prepared using the [Yocto
Project](https://www.yoctoproject.org/) and tested on PC Engines apu2. Its
functionalities include:

* commissioning in the Dynamically Launched Measured Environment,
* integration with Fobnail Token,
* kexec integration, the ability to run other operating systems.

Any tests are described in this post or in additional documents to which links
are provided. As part of this phase, we also conducted a research on other
possible operating systems that could be run in DLME and work with Fobnail
Token.

## OS researching

We have conducted research to find out which OS/kernel suits our needs the most.
We need USB drivers, including USB EEM (Ethernet over USB) driver and network
stack. The base choice is Linux which already has all required drivers. However,
we researched the usage of microkernels due to increased security. If minimal OS
got compromised (through its USB or network stack), an attacker could trick
Fobnail that platform is in a trustworthy state, revealing Fobnail's kept
secrets like cryptographic keys.

So we evaluated the feasibility of using microkernel-based OSes. Many
microkernel-based OSes lack the required drivers, ability to boot another OS,
and ability to run as DLME payload. Also, since they are designed for an
embedded environment, they are not portable (across platforms with the same CPU
architecture), which is a serious limitation that would force us to ship many
versions of OS for each platform.

As a teaser we include here a table that summarize our research.

| OS      | USB host driver  | USB EEM driver   | Network stack     | TPM driver        | OS portability | Bootloader capabilities | C library    | Microkernel | CPU Architecture support | Bootable by SKL | License | Score |
| ------- | ---------------- | ---------------- | ----------------- | ----------------- | -------------- | ----------------------- | -------------| ----------- | ------------------------ | --------------- | ------- | ----- |
| Zephyr  | Yes (+2)         | Yes (+2)         | Yes (+2)          | PoC available (0) | Limited (-1)   | No (0)                  | Yes (+2)     | No (0)      | Good (+1) [^4]           | No (0) [^6]     |  OK (0)  | 8     |
| Xous    | No (0)           | No (0)           | Yes (+2)          | No (0)            | Limited (-1)   | No (0)                  | No (0)       | Yes (+1)    | RISC-V only (-1)         | No (0)          |  OK (0)  | 1     |
| seL4    | No (0) [^1]      | No (0) [^2]      | Yes (+2)          | No (0)            | Limited (-1)   | No (0)                  | Yes (+2)     | Yes (+1)    | Good (+1) [^3]           | Yes (+2)        | OK (but problematic with Genode) (0)  | 7     |
| Linux   | Yes (+2)         | Yes (+2)         | Yes (+2)          | Yes (+2)          | Yes (+1)       | Yes (kexec) (+2)        | Yes (+2)     | No (0)      | Good (+1) [^5]           | Yes (+2)        |  OK (0)  | 16    |
| LK      | No (0)           | No (0)           | Limited (-2) [^7] | No (0)            | Yes (+1)       | No (0)                  | Limited (-2) | No (0)      | Good (+1) [^8]           | No (0)          |  OK (0)  | -2    |
| Fuchsia | Limited (0) [^9] | No (0)           | Yes (+2)          | Limited (0) [^10] | Yes (+1)       | Yes (mexec) (+2)        | Yes (+2)     | Yes (+1)    | Good (+1) [^11]          | No (0)          |  OK (0)  | 7     |

As we can see, multiple OSes were taken into account and a lot of requirements.
If you are interested in the meanings of the numbers here, please check the
full [report](https://fobnail.3mdeb.com/minimal-os-for-fobnail/) available on
Fobnail Project official website.

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

The process of generating minimal OS is not complicated. In our case, we were
using a PC running Ubuntu 20.04 Firstly, we need to download the latest
`kas container`:

```
$ mkdir ~/bin
$ wget -O ~/bin/kas-container https://raw.githubusercontent.com/siemens/kas/3.0.2/kas-container
$ chmod +x ~/bin/kas-container
```

With that we can build a minimal OS from `meta-fobnail` repository:

```
$ mkdir fobnail-yocto && cd fobnail-yocto
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

> Note: We recommend to use debug version as it is passwordless.

We have also published a
[document](https://fobnail.3mdeb.com/meta-fobnail-in-dlme/) outlining our
efforts to make our minimal OS run in DLME. We mentioned that the components
from TrenchBoot were used, but in practice, using them on the PC Engines apu2
platform was not trivial.

### Attestation workflow

The minimum operating system we have prepared includes a set of functionalities
that allows to test the following scenario. Imagine we got a Fobnail Token along
with a minimal OS. We can now run it on our platform and validate it. If we get
a positive result, we have the green light to boot our target system. Otherwise,
unfortunately, we receive information that something may have changed on our
platform and it is better not to boot anything else. The diagram below shows the
whole situation.

![Fobnail Token flow with minimal OS](/img/ft-minimal-os.png)

In order to run the test we need to perform following steps. In our scenario we
boot to the minimal OS, run attestation and finally boot `Ubuntu 20.04 LTS Live`
flashed on pendrive.

1. Boot [meta-fobnail](https://github.com/fobnail/meta-fobnail) image in DLME -
   this was described [here](https://fobnail.3mdeb.com/meta-fobnail-in-dlme/).

2. Log into the platform, the server should be started on boot, to see logs,
   please run the following command.

```
# journalctl -fu fobnail-attester
-- Journal begins at Tue 2022-06-07 15:04:57 UTC. --
Jun 07 15:05:14 tb systemd[1]: Started Fobnail Attester service.
```

3. Connect Fobnail Token to PC Engines apu2. If the device is detected properly
   system should print following information

```
[   42.108151] usb 2-2: new full-speed USB device number 2 using xhci_hcd
[   42.334313] cdc_eem 2-2:1.0 usb0: register 'cdc_eem' at usb-0000:00:10.0-2, CDC EEM Device, 5e:f9:bb:9b:dd:06
[   42.355332] usbcore: registered new interface driver cdc_eem
```

4. Wait a few seconds for provisioning and attestation. During this procedure
   `Fobnail Attester` should print information about received data

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

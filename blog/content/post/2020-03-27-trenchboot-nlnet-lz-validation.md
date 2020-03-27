---
title: Open Source DRTM with TrenchBoot. Landing Zone validation.
abstract: When you already know what is TrenchBoot, what is DRTM and how we
          enable it on AMD processors, we can move on to practice. Today, I will
          show you how to configure all components and verify first project's
          requirements.
cover: /covers/
author: piotr.kleinschmidt
layout: post
published: false
date: 2020-03-27
archives: "2020"

tags:
  - trenchboot
  - security
  - open-source
  - coreboot
categories:
  - Firmware
  - Security

---

In [previous article](link-to-tb-nlnet-basics) I introduced project's basics. I
explained briefly what parts of system are necessary in DRTM and how to prepare
them. Now, let's try to build them, so you can enjoy having secure platform too.
Also, we will verify first requirements which are already met in project.

## Preparation

We are using PC Engines apu2 platform with coreboot and NixOS. Procedures which
are presented further in article are done for that exact configuration. If you
want to perform any operations step-by-step, I strongly recommend to use exactly
the same setup. I assume you have already installed NixOS and can install
original and custom packages (tutorials are in [previous article](link-to-tb-nlnet-basics)).
It's important because it will be used very often, so you shouldn't have any
problems with it.

Also in NixOS download our [custom `nixpkgs` library](linkt-to-custom-nixpkgs).
It already has every additional tool and component added, so it will be easy to
install it.


## Verification

To create platform with DRTM enabled and properly prepared Linux kernel you must
install following packages:

- linux-kernel-trenchboot
- initrd-trenchboot
- GRUB-trenchboot
- LZ-trenchboot

Reboot the platform and see if NixOS boots normally. Later in the article, I
will show you how to verify each part of above operation and hence DRTM itself.

### Linux kernel and initrd

Prepare system by installing following packages: `linux-kernel-trenchboot` and
`initrd-trenchboot`. Rebuild kernel and reboot platform.

```
What to exactly verify?
What should be/be not seen in NixOS?
```

### GRUB

There are two ways to validate if GRUB will load `slaunch` module and hence run
SKINIT and LZ (DRTM). First, during platform boot you can see if there is
`slaunch` option available and if you can boot from it. Second, you can verify
content of `grub.cfg` file. Both methods with possible outputs are presented
below.

#### GRUB without slaunch

Prepare your system. Make sure that `GRUB-trenchboot` package is not
installed. If it is present, uninstall it. Reboot platform and verify outputs.

1. Content of grub.cfg

```
content of grub.cfg
```

2. GRUB menu in bootlog

```
GRUB menu in bootlog without slaunch
```

#### GRUB with slaunch

Prepare your system. Boot to NixOS and install `GRUB-trenchboot` package. Reboot
platform and verify outputs.

1. Content of grub.cfg

```
content of grub.cfg
```

2. GRUB menu in bootlog

```
GRUB menu in bootlog with slaunch
```

### LZ

Actually, there are few aspects which can be verified in LZ. We will focus on
those two:
- check if LZ debug option can be enabled
- check if LZ utilizes SHA256 algorithm when using TPM2.0 module

#### check if LZ debug option can be enabled

Prepare your system. Boot to NixOS and install `LZ-trenchboot` package. Reboot
platform and verify boot log.

```
LZ logs without debug
```

Boot to NixOS once again and install `LZ-trenchboot-debug` package. Reboot
platform and verify boot log once again.

```
LZ logs with debug
```

As you can see, debug output is more verbose then previous one. However, I
recommend to use non-debug one in normal operation.

#### check if LZ utilizes SHA256 algorithm when using TPM2.0 module

Prepare your system by installing `LZ-trenchboot` package and `tpm2-tools`
package. Reboot platform and boot to NixOS. To see correctness of LZ operation
do the following steps:

1. Run `tpm2-tool`

```bash
./tpm2_command

//tpm-tool output
```

2. Run `extended_all.sh` script.

```bash
./extended_all.sh <dir-to-kernel> <dir-to-initrd>

//script output
```

Above script perform same operations as LZ. It measures kernel and store value
in PCR17-18. If script's output for PCR17-18 is exactly the same as `tpm-tool`
output then LZ use SHA256.

## Summary

With theoretical knowledge and practice you should be able to enable DRTM on
your platform and verify its operations. Further development will bring more
features. Each of them will be presented in similar way. Each of them also will
be verifiable by you. So stay tuned and read our social media for more
information!

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

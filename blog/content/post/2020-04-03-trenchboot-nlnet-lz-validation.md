---
title: 'TrenchBoot: Open Source DRTM. Landing Zone validation.'
abstract: When you already know what is TrenchBoot, what is DRTM and how we
          enable it on AMD processors, we can move on to practice. I will
          show you how to configure all components and verify first of project's
          requirements.
cover: /covers/trenchboot-logo.png
author: piotr.kleinschmidt
layout: post
published: true
date: 2020-04-03
archives: "2020"

tags:
  - trenchboot
  - open-source
  - coreboot
categories:
  - Firmware
  - Security

---

**UPDATE:** At time of releasing this blog post, we were missing TPM1.2
verification and kernel measurements requirements. It is done now. As a result,
we have added/updated following sections:

- **Landing Zone update** section with procedure how to update Landing Zone
  only;
- **Landing Zone** section with explanation of extending PCRs by Landing Zone
  and kernel, so it should be easily distinguished;
- **Landing Zone** section with _check if LZ utilizes SHA1 algorithm when using
  TPM1.2 module_ requirement verification;
- **Changes in source code** section with point to exact place in LZ's code,
  where SHA1 algorithm is utilized;

In
[previous article](https://blog.3mdeb.com/2020/2020-03-31-trenchboot-nlnet-lz/)
I introduced project's basics. I explained briefly what parts of system are
necessary in DRTM and how to prepare them. Now, let's try to build them, so you
can enjoy having secure platform too. Also, we will verify first requirements
which are already met in project.

## Preparation

We are using PC Engines apu2 platform with coreboot and NixOS. Procedures which
are presented further in article are done for that exact configuration. If you
want to perform any operations step-by-step, I strongly recommend to use exactly
the same setup.

At this stage, I assume you have already installed NixOS according to our
[instructions](https://blog.3mdeb.com/2020/2020-03-31-trenchboot-nlnet-lz/#nixos-installation).
If yes, then we can start process of **enabling DRTM**.

### Quick reminder - boot flow

Before we execute essential part, I would like to pass through quick reminder.
Don't worry, I won't give a lecture or bring unfamiliar concepts. I want to show
you differences between platform without DRTM and with DRTM. It is presented in
graphical form, so it will be easier to visualize it.

A normal boot process without DRTM enabled, typically looks like this:

![boot without drtm](/img/boot-non-drtm.png)

GRUB bootloader **directly** loads Linux kernel and whereby NixOS boots. As you
know, by modifying GRUB, Linux kernel and adding special boot modules, we enable
DRTM. Then, the boot process looks like this:

![boot drtm](/img/boot-drtm.png)

You can clearly see 3 additional elements, which are **slaunch module**,
**SKINIT** and **Landing Zone**. Their functionality should be already known by
you. Briefly, it is DRTM stage, when platform boots.

Now, when you can visualize differences, you will learn how to switch your
platform from the first case to the second one. Let's do it!

## System customization - enabling DRTM

It is the first thing we need to do. Clean NixOS doesn't meet all requirements.
First of all, we want to replace default `nixpkgs` with our custom one. Second
of all, as it doesn't have all necessary packages installed by default, we want
to add them.

Fortunately, customization of NixOS will demand its **configuration update, but
not entire system re-installation**. Moreover, there is no need to install every
single package manually. Of course, it still can be done if you wish. However,
entire process of enabling DRTM is automated by us to minimize user's effort. So
much for the introduction - now we can finally run the procedure. Boot to NixOS
and follow these steps:

1. Install `cachix`

   `cachix` is binary cache hosting. It allows to store binary files, so there
   is no need to build them on your own. If it is not very useful for small
   builds, it is very handy for large ones e.g. Linux kernel binary.

   ```bash
   nix-env -iA cachix -f https://cachix.org/api/v1/install
   ```

1. Add 3mdeb cachix hosting as default.

   ```bash
   $ cachix use 3mdeb
   Cachix configuration written to /etc/nixos/cachix.nix.
   Binary cache 3mdeb configuration written to /etc/nixos/cachix/3mdeb.nix.

   To start using cachix add the following to your /etc/nixos/configuration.nix:

       imports = [ ./cachix.nix ];

   Then run:

       $ sudo nixos-rebuild switch
   ```

1. Meet above requirement by editing `/etc/nixos/configuration.nix`.

   > Probably vim editor is not available at this stage. Instead of vim, you can
   > use nano.

   ```bash
   $ nano /etc/nixos/configuration.nix
   (...)
   imports =
   [ # Include the results of the hardware scan.
     ./hardware-configuration.nix
     ./cachix.nix
   ];
   (...)
   ```

   > Don't rebuild NixOS yet. It will be done later.

1. Install git package.

   ```bash
   nix-env -iA nixos.git
   ```

1. Clone
   [3mdeb/nixpkgs](https://github.com/3mdeb/nixpkgs/tree/trenchboot_support_2020.03)
   repository.

   `3mdeb nixpkgs` contains additional packages compared with default NixOS
   `nixpkgs`, so everything is in one place. Most of all, there are:

   1. [grub-tb](https://github.com/3mdeb/grub2/tree/trenchboot_support) - custom
      GRUB2 with `slaunch` module enabled;
   1. [landing-zone](https://github.com/TrenchBoot/landing-zone.git) - LZ
      without debug flag
   1. [landing-zone-debug](https://github.com/TrenchBoot/landing-zone.git) - LZ
      with debug
   1. [linux-5.1](https://github.com/3mdeb/linux-stable/tree/linux-sl-5.1-sha2-amd)
      \- custom Linux kernel with initrd

   ```bash
   $ git clone https://github.com/3mdeb/nixpkgs.git -b trenchboot_support_2020.03
   (...)
   $ ls
   nixpkgs
   ```

1. Update (rebuild) NixOS.

   ```bash
   sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
   ```

   > IMPORTANT: `-I nixpkgs=~/nixpkgs` flag is needful here! It replaces default
   > `nixpkgs` with previously downloaded one. Make sure the directory is valid
   > (we have it in home (~)). If you follow our instruction step-by-step, you
   > have it also there.

1. Reboot platform.

   > DRTM is not enabled yet! Boot to NixOS and finish configuration.

1. Clone
   [3mdeb/nixos-trenchboot-configs](https://github.com/3mdeb/nixos-trenchboot-configs.git)
   repository.

   This repository contains all necessary NixOS configuration files in
   ready-to-use form, so there is no need to edit them by hand at this moment.

   ```bash
   git clone https://github.com/3mdeb/nixos-trenchboot-configs.git
   ```

   List `nixos-trenchboot-configs` folder.

   ```bash
   $ cd nixos-trenchboot-configs/
   $ ls
   configuration.nix  linux-5.1.nix  MANUAL.md  README.md  tb-config.nix
   ```

   Among listed files, most interesting one is `configuration.nix`. Customizing
   it saves time and work compared with tools and package manual installs.
   Manual work is good for small and fast builds. The more (and more
   significant) changes you want to do, the more efficient way is to re-build
   your NixOS system. That is done by editing `configuration.nix` file. As you
   already know, among others we want to rebuild Linux kernel, replace GRUB
   bootloader and install custom packages. That is why we decided to prepare new
   config and re-install NixOS.

   Let's take a closer look at its content. Entire file is rather large, so the
   output will be truncated and only essential parts/lines will be mentioned.

   ```bash
   $ cat configuration.nix

   (...)
   imports =
     [ # Include the results of the hardware scan.
       ./hardware-configuration.nix
       ./cachix.nix
       ./linux-5.1.nix
     ];
   (...)
   boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
   boot.loader.grub.extraEntries = ''
     menuentry "NixOS - Secure Launch" {
     search --set=drive1 --fs-uuid 178473b0-282f-4994-96fc-a8e51e2cfdac
     search --set=drive2 --fs-uuid 178473b0-282f-4994-96fc-a8e51e2cfdac
       slaunch skinit
       slaunch_module ($drive2)/boot/lz_header
       linux ($drive2)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/b32wgz392q99cls12pkd8adddzbdkprn-nixos-system-nixos-20.09.git.50c3e448fceM init=/nix/store/b32wgz392q99cls12pkd8adddzbdkprn-nixos-system-nixos-20.09.git.50c3e448fceM/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 loglevel=4
       initrd ($drive2)/nix/store/zv2vl35xldkbss1y2fib1nifmw0yvick-initrd-linux-5.1.0/initrd
     }
   '';

   # OS utilities
   environment.systemPackages = [
                                  pkgs.pkg-config
                                  pkgs.git
                                  pkgs.gnumake
                                  pkgs.autoconf
                                  pkgs.automake
                                  pkgs.gettext
                                  pkgs.python
                                  pkgs.m4
                                  pkgs.libtool
                                  pkgs.bison
                                  pkgs.flex
                                  pkgs.gcc
                                  pkgs.gcc_multi
                                  pkgs.libusb
                                  pkgs.ncurses
                                  pkgs.freetype
                                  pkgs.qemu
                                  pkgs.lvm2
                                  pkgs.unifont
                                  pkgs.fuse
                                  pkgs.gnulib
                                  pkgs.stdenv
                                  pkgs.nasm
                                  pkgs.binutils
                                  pkgs.tpm2-tools
                                  pkgs.tpm2-tss
                                  pkgs.landing-zone
                                  pkgs.landing-zone-debug
                                  pkgs.grub-tb
                                 ];

   # Grub override
   nixpkgs.config.packageOverrides = pkgs: { grub2 = pkgs.grub-tb; };
   ```

   Remarks:

   1. we import `cachix` service and custom linux 5.1 kernel to be built;
   1. adjust GRUB entries to boot `slaunch` and change directories of `bzImage`
      (Linux kernel) and `initrd` to custom ones;
   1. add all necessary system packages (i.a. `landing-zone`,
      `landing-zone-debug` and `grub-tb`);
   1. override default GRUB package with custom one;

1. Copy all configuration files to `/etc/nixos/` directory.

   ```bash
   cp nixos-trenchboot-configs/*.nix /etc/nixos
   ```

1. Update (re-build) system.

   ```bash
   $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
   building Nix...
   building the system configuration...
   ```

1. Reboot platform.

   > DRTM is not enabled yet. Choose `"NixOs - Default"` entry in GRUB menu.

1. Install GRUB2-TrenchBoot to `/dev/sdX`.

   ```bash
   grub-install /dev/sda
   ```

   > Remember to choose proper device (disk) - in our case it is `/dev/sda`.

1. Ensure that `slaunch` module is present in `/boot/grub/i386-pc/`.

   ```bash
   $ ls /boot/grub/i386-pc | grep slaunch
   slaunch.mod
   ```

1. Find Landing Zone package in `/nixos/store/`.

   ```bash
   $ ls /nix/store/ | grep landing-zone
   5q92f6l4s1jfbw5ygfr1sd4hlczjj6l2-landing-zone-0.3.0.drv
   6v15ikqsyqk5fs0jg1n6755dp1nr6cyc-landing-zone-debug-0.3.0.drv
   dnpqvb64jjr3x2kxx92wvdkvmah72h6m-landing-zone-debug-0.3.0
   zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0
   ```

   > Package without `-debug` in its name and without _.drv_ extension is what
   > we are looking for.

1. Copy `lz_header.bin` to `/boot/` directory.

   ```bash
   cp /nix/store/zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0/lz_header.bin /boot/lz_header
   ```

1. Check `/boot/grub/grub.cfg` file and its `NixOS - Default` menu entry. Adjust
   `/etc/nixos/configuration.nix` and its `boot.loader.grub.extraEntries` line
   to have exactly the same directories included.

   ```bash
   $ cat /boot/grub/grub.cfg
   (...)
   menuentry "NixOS - Default" {
   search --set=drive1 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
   search --set=drive2 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
     linux ($drive2)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/1mgqiy35hksf0r66gfffrl76s2img9z2-nixo
   s-system-nixos-20.09.git.c36910d42c5 init=/nix/store/1mgqiy35hksf0r66gfffrl76s2img9z2-nixos-system-nixos-20.09.git.c36910d42c5/init console=tt
   yS0,115200 earlyprintk=serial,ttyS0,115200 loglevel=4
     initrd ($drive2)/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
   }
   (...)
   ```

   With `grub.cfg` content as above `configuration.nix` must have
   `boot.loader.grub.extraEntries`line like this:

   ```bash
   $ cat /etc/nixos/configuration.nix
     (...)
     boot.loader.grub.extraEntries = ''
     menuentry "NixOS - Secure Launch" {
       search --set=drive1 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
       search --set=drive2 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
       slaunch skinit
       slaunch_module ($drive2)/boot/lz_header
       linux ($drive2)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/1mgqiy35hksf0r66gfffrl76s2img9z2-nixos-system-nixos-20.09.git.c36910d42c5 init=/nix/store/1mgqiy35hksf0r66gfffrl76s2img9z2-nixos-system-nixos-20.09.git.c36910d42c5/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 loglevel=4
       initrd ($drive2)/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
     }
   '';
   ```

   If there are differences in any of `search --set=drive1...`,
   `search --set=drive2...`, `linux ($drive2)/nix/store...` lines, edit
   `configuration.nix` content and copy those lines from `grub.cfg` menuentry
   `"NixOS - Default"`. They must be exactly the same.

1. Update system for the last time.

   ```bash
   sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
   ```

1. Reboot platform.

During platform booting, in GRUB menu there should be at least
`"NixOS - Default"` and `"NixOS - Secure Launch"` entries. First entry boots
platform without DRTM. Second entry **executes DRTM**! Choose the second entry
and see if platform boots successfully. If yes, you have secure platform with
DRTM enabled.

## Validation

You can still be suspicious, if it really works. And rightly so. In this
section, I will show you, how to verify each component of the system to make you
sure about its correctness. Also, I will present how we met first stage
project's requirement.

### GRUB

There are two ways to validate if GRUB will load `slaunch` module and hence run
SKINIT and LZ (DRTM).

#### Verify content of `grub.cfg` file

```bash
$ cat /boot/grub/grub.cfg
menuentry "NixOS - Default" {
search --set=drive1 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
search --set=drive2 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
  linux ($drive2)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/zyb42vdhv4pqwwmi9szrvd88i92sb7zb-nix4
  initrd ($drive2)/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
}

menuentry "NixOS - Secure Launch" {
  search --set=drive1 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
  search --set=drive2 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
  slaunch skinit
  slaunch_module ($drive2)/boot/lz_header
  linux ($drive2)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/1mgqiy35hksf0r66gfffrl76s2img9z2-nix4
    initrd ($drive2)/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
}
```

In "NixOS - Secure Launch" entry there must be `slaunch skinit` entry and
`slaunch_module  ($drive2)/boot/lz_header` which points to LZ.

##### Compare bootlog with DRTM and without DRTM

1. Reboot platform. In GRUB menu choose `"NixOS - Default"` entry (without
   DRTM).

   Collect logs during boot to be able to verify them. Using `dmesg` command in
   NixOS doesn't work because it doesn't show pre-kernel stage logs! Correct
   bootlog is shown below.

   ```bash
   early console in extract_kernel
   input_data: 0x00000000023eb3b1
   input_len: 0x0000000000424e94
   output: 0x0000000001000000
   output_len: 0x00000000017e7398
   kernel_total_size: 0x000000000142c000
   trampoline_32bit: 0x000000000009d000
   booted via startup_32()
   Physical KASLR using RDTSC...
   Virtual KASLR using RDTSC...

   Decompressing Linux... Parsing ELF... Performing relocations... done.
   Booting the kernel.
   [    0.000000] Linux version 5.1.0 (nixbld@localhost) (gcc version 9.2.0 (GCC)) #1-NixOS SMP Thu Jan 1 00:00:01 UTC 1970
   [    0.000000] Command line: BOOT_IMAGE=(hd0,msdos1)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/74
   [    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'

   (...)

   <<< Welcome to NixOS 20.09.git.a070e686875 (x86_64) - ttyS0 >>>

   Run 'nixos-help' for the NixOS manual.
   ```

   **Verification**: As expected, bootloader executes Linux kernel directly.
   Platform booted without DRTM then.

1. Reboot platform once again. In GRUB menu choose `"NixOS - Secure Launch"`
   entry.

   Once again, collect logs during boot to be able to verify them. Using `dmesg`
   command in NixOS doesn't work, as in previous case. Correct bootlog is shown
   below.

   ```bash
   grub_cmd_slaunch:122: check for manufacturer
   grub_cmd_slaunch:126: check for cpuid
   grub_cmd_slaunch:136: set slaunch
   grub_cmd_slaunch_module:156: check argc
   grub_cmd_slaunch_module:161: check relocator
   grub_cmd_slaunch_module:170: open file
   grub_cmd_slaunch_module:175: get size
   grub_cmd_slaunch_module:180: allocate memory
   grub_cmd_slaunch_module:192: addr: 0x100000
   grub_cmd_slaunch_module:194: target: 0x100000
   grub_cmd_slaunch_module:196: add module
   grub_cmd_slaunch_module:205: read file
   grub_cmd_slaunch_module:215: close file
   grub_slaunch_boot_skinit:41: real_mode_target: 0x8a000
   grub_slaunch_boot_skinit:42: prot_mode_target: 0x1000000
   grub_slaunch_boot_skinit:43: params: 0xcfe7745early console in extract_kernel
   input_data: 0x00000000023eb3b1
   input_len: 0x0000000000424e94
   output: 0x0000000001000000
   output_len: 0x00000000017e7398
   kernel_total_size: 0x000000000142c000
   trampoline_32bit: 0x000000000009d000
   booted via startup_32()
   Physical KASLR using RDTSC...
   Virtual KASLR using RDTSC...

   Decompressing Linux... Parsing ELF... Performing relocations... done.
   Booting the kernel.
   [    0.000000] Linux version 5.1.0 (nixbld@localhost) (gcc version 9.2.0 (GCC)) #1-NixOS SMP Thu Jan 1 00:00:01 UTC 1970
   [    0.000000] Command line: BOOT_IMAGE=(hd0,msdos1)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/j4
   [    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'

   (...)

   <<< Welcome to NixOS 20.09.git.a070e686875 (x86_64) - ttyS0 >>>

   Run 'nixos-help' for the NixOS manual.
   ```

   **Verification**: As expected, before Linux kernel, there should be `slaunch`
   module executed. It proves that DRTM is enabled. There is no information
   about LZ execution because it is non-debug version.

### Landing Zone

As we mentioned in previous article, measurements are done by Landing Zone and
Linux kernel as well. LZ extends only **PCR17**, kernel extends only **PCR18**.
It's important to distinguish those two values. If kernel doesn't make
measurements, there should be only `00000...` in PCR18. In requirements
verification procedures (presented later), you can notice, that regardless of
using TPM2.0 or TPM1.2 module, PCR17 and PCR18 are both filled with non-zero
values. It proves that both LZ and kernel takes measurements.

There are few aspects which can be verified in LZ. We will focus on those three:

- check if LZ utilizes SHA256 algorithm when using TPM2.0 module
- check if LZ utilizes SHA1 algorithm when using TPM1.2 module
- check if LZ debug option can be enabled

Before moving to validation procedures, update necessary Trenchboot packages to
have all latest changes applied.

1. Pull `trenchboot_support_2020.06` branch from `3mdeb/nixpkgs` repository.

   ```bash
   cd ~/nixpkgs/
   git checkout trenchboot_support_2020.04
   git pull
   ```

1. Rebuild NixOS.

   ```bash
   sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
   ```

#### check if LZ utilizes SHA256 algorithm when using TPM2.0 module

1. If not already booted to `"NixOS - Secure Launch"`, reboot platform and boot
   to NixOS via `"NixOS - Secure Launch"` entry in GRUB menu.

1. Run `tpm2_pcrread` command.

   ```bash
   $ tpm2_pcrread
   sha1:
     0 : 0x3A3F780F11A4B49969FCAA80CD6E3957C33B2275
     1 : 0xFE4F0F826A15FA9E426722AAE12731508D84110D
     2 : 0x53DE584DCEF03F6A7DAC1A240A835893896F218D
     3 : 0x3A3F780F11A4B49969FCAA80CD6E3957C33B2275
     4 : 0x017A3DE82F4A1B77FC33A903FEF6AD27EE92BE04
     5 : 0x46DF69CCCFB08DE09E8BC2E8FAAD8D4F942FDD85
     6 : 0x3A3F780F11A4B49969FCAA80CD6E3957C33B2275
     7 : 0x3A3F780F11A4B49969FCAA80CD6E3957C33B2275
     8 : 0x0000000000000000000000000000000000000000
     9 : 0x0000000000000000000000000000000000000000
     10: 0x0000000000000000000000000000000000000000
     11: 0x0000000000000000000000000000000000000000
     12: 0x0000000000000000000000000000000000000000
     13: 0x0000000000000000000000000000000000000000
     14: 0x0000000000000000000000000000000000000000
     15: 0x0000000000000000000000000000000000000000
     16: 0x0000000000000000000000000000000000000000
     17: 0xD425110792179753635626B3FAB43E8F657026E2
     18: 0x0000000000000000000000000000000000000000
     19: 0x0000000000000000000000000000000000000000
     20: 0x0000000000000000000000000000000000000000
     21: 0x0000000000000000000000000000000000000000
     22: 0x0000000000000000000000000000000000000000
     23: 0x0000000000000000000000000000000000000000
   sha256:
     0 : 0xD27CC12614B5F4FF85ED109495E320FB1E5495EB28D507E952D51091E7AE2A72
     1 : 0xF4CE533757FFD1AA737A15D0D6804CAFEBE9FF2B507C696709557E72E49FFD34
     2 : 0xFA8791BB6BCE8EBF4AD7B516ADFBBB9B2F1499A8876E2C909135AEBDCCA2D84C
     3 : 0xD27CC12614B5F4FF85ED109495E320FB1E5495EB28D507E952D51091E7AE2A72
     4 : 0x94855A1DF928211EAB2000178968B4B630B9BAC53B4C34177EE5224E9AAF2304
     5 : 0x9DEEEAA62816FDC5BB53C83AEDE49BAD1F92A7DABC35A9548253A3B9D535574A
     6 : 0xD27CC12614B5F4FF85ED109495E320FB1E5495EB28D507E952D51091E7AE2A72
     7 : 0xD27CC12614B5F4FF85ED109495E320FB1E5495EB28D507E952D51091E7AE2A72
     8 : 0x0000000000000000000000000000000000000000000000000000000000000000
     9 : 0x0000000000000000000000000000000000000000000000000000000000000000
     10: 0x0000000000000000000000000000000000000000000000000000000000000000
     11: 0x0000000000000000000000000000000000000000000000000000000000000000
     12: 0x0000000000000000000000000000000000000000000000000000000000000000
     13: 0x0000000000000000000000000000000000000000000000000000000000000000
     14: 0x0000000000000000000000000000000000000000000000000000000000000000
     15: 0x0000000000000000000000000000000000000000000000000000000000000000
     16: 0x0000000000000000000000000000000000000000000000000000000000000000
     17: 0x7392BE6CD449323115D11BBC97AF4CB2ADAD25B9CF52D0861F87934FEEA7B03E
     18: 0x47D99FC5D85B202479E2D5473224E144B51759EE1F34BBFE8073134E72A073E3
     19: 0x0000000000000000000000000000000000000000000000000000000000000000
     20: 0x0000000000000000000000000000000000000000000000000000000000000000
     21: 0x0000000000000000000000000000000000000000000000000000000000000000
     22: 0x0000000000000000000000000000000000000000000000000000000000000000
     23: 0x0000000000000000000000000000000000000000000000000000000000000000
   ```

1. Run `extend_all.sh` script from `landing-zone` package.

   This script simulates what should be extended into PCR17 by SKINIT, LZ and
   kernel during platform booting. It extends both SHA256 and SHA1 values.
   However, expected result is valid only for SHA256 if used with TPM2.0 device.

   To properly execute script, first find correct directory to `bzImage` and
   `initrd`. Best way to find exact directories is to see
   `"NixOS - Secure  Launch"` entry in `/boot/grub/grub.cfg`:

   ```bash
   $ cat /boot/grub/grub.cfg
   (...)
   menuentry "NixOS - Secure Launch" {
     search --set=drive1 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
     search --set=drive2 --fs-uuid fcc62677-b961-4ccf-bd66-376db104240f
     slaunch skinit
     slaunch_module ($drive2)/boot/lz_header
     linux ($drive2)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/1mgqiy35hksf0r66gfffrl76s2img9z2-nix4
       initrd ($drive2)/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
   }
   (...)
   ```

   `/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage` is
   directory to Linux kernel.
   `/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd` is
   directory to initrd.

1. Go to `/nix/store/` and run below command:

   ```bash
   $ cd /nix/store
   $ ls | grep landing-zone
   5q92f6l4s1jfbw5ygfr1sd4hlczjj6l2-landing-zone-0.3.0.drv
   6v15ikqsyqk5fs0jg1n6755dp1nr6cyc-landing-zone-debug-0.3.0.drv
   dnpqvb64jjr3x2kxx92wvdkvmah72h6m-landing-zone-debug-0.3.0
   zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0
   ```

   > Hash before `-landing-zone-1.0` is dependent on built version and might be
   > different in yours. Choose non-debug version from above results.

1. Go to `/nix/store/zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0`
   directory.

   ```bash
   cd /nix/store/zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0
   ```

1. Execute `./extend_all.sh` script.

   Usage is `./extend_all.sh <directory-to-bzImage> <directory-to-initrd>`

   It must be executed inside directory containing currently used (debug or
   non-debug) version of `lz_header.bin`. You should already be in this
   directory after previous step. Directories to `bzImage` and `initrd` we found
   in step 3.

   ```bash
   ./extend_all.sh /nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage /nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
   d91e7f685bcae20f84308eafe46f02eea8fcc90c  SHA1
   7392be6cd449323115d11bbc97af4cb2adad25b9cf52d0861f87934feea7b03e  SHA256
   ```

   Compare SHA256 value with PCR17 content checked previously with
   `tpm2_pcrread` output. If DRTM is enabled and executes properly, they should
   be the same. It proves that LZ code utilizes SHA256 algorithm during
   measurements.

##### check if LZ utilizes SHA1 algorithm when using TPM1.2 module

1. If not already booted to `"NixOS - Secure Launch"`, reboot platform and boot
   to NixOS via `"NixOS - Secure Launch"` entry in GRUB menu.

1. Update `landing-zone` package to have support for TPM1.2.

   ```bash
   cd ~/nixpkgs
   git checkout tpm12_support
   nix-build -A landing-zone
   ```

1. Go to `/nix/store/` directory and search for newly build landing-zone
   package.

   ```bash
   $ cd /nix/store
   $ ls | grep landing-zone
   5a6kapnjxs8dj4jp49qagz1mw2r6hnr2-landing-zone-debug-0.3.0
   l1b2h84fdw8g0m9aygmv8g3nhbnw9kic-landing-zone-debug-0.3.0.drv
   lf763br9hm0ipp76k2p16iq75x3xpgrm-landing-zone-0.3.0
   mnbh5xahlbzmfa50r60y5z4lph9rd41k-landing-zone-0.3.0.drv
   ```

   We are looking for entry without `-debug` and `.drv` extension. In this
   particular example, it is
   `5a6kapnjxs8dj4jp49qagz1mw2r6hnr2-landing-zone-debug-0.3.0`.

1. Copy `lz_header.bin` from above directory to `/boot` directory.

   ```bash
   cp /nix/store/5a6kapnjxs8dj4jp49qagz1mw2r6hnr2-landing-zone-debug-0.3.0/lz_header.bin /boot/lz_header
   ```

1. Reboot platform to apply changes.

1. Check PCR values of TPM1.2 module.

   > Notice, that `tpm2_tools` is not compatible with TPM1.2 module, so it won't
   > work!

   ```bash
   # cat /sys/class/tpm/tpm0/pcrs
   PCR-00: 3A 3F 78 0F 11 A4 B4 99 69 FC AA 80 CD 6E 39 57 C3 3B 22 75
   PCR-01: 40 9C 01 12 67 A9 37 5E BF 5A 5C 43 C6 96 FE 25 AD 0F 02 3B
   PCR-02: B2 2A 53 5A C8 0C CA 8A 49 AD 1A D8 77 29 82 6F 49 2D 53 7E
   PCR-03: 3A 3F 78 0F 11 A4 B4 99 69 FC AA 80 CD 6E 39 57 C3 3B 22 75
   PCR-04: 01 7A 3D E8 2F 4A 1B 77 FC 33 A9 03 FE F6 AD 27 EE 92 BE 04
   PCR-05: 37 0C 7F 87 39 AF DC E7 1F EB 67 FE 83 B2 47 6F D7 B5 59 CD
   PCR-06: 3A 3F 78 0F 11 A4 B4 99 69 FC AA 80 CD 6E 39 57 C3 3B 22 75
   PCR-07: 3A 3F 78 0F 11 A4 B4 99 69 FC AA 80 CD 6E 39 57 C3 3B 22 75
   PCR-08: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-09: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-10: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-11: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-12: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-13: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-14: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-15: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-16: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-17: AD CA 0E DC CD A7 EF 26 71 27 51 42 BE C2 E3 95 BF 37 3F 02
   PCR-18: EF F6 CC FC 57 41 36 4A DF 29 68 E5 50 81 E8 AF AD 72 B4 7B
   PCR-19: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-20: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-21: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-22: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   PCR-23: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
   ```

1. Execute steps 3-6 from _check if LZ utilizes SHA256 algorithm when using
   TPM2.0 module_ instruction.

   ```bash
   ./extend_all.sh /nix/store/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3/bzImage /nix/store/n9wj42p2kvm84rxr7bwh8qjxmawa447k-initrd-linux-5.5.3/initrd
   adca0edccda7ef2671275142bec2e395bf373f02  SHA1
   b06f177d3fe280bd0bb1cc24ad54930d953751ee028f461a4d352959d10f9fd0  SHA256
   ```

   Compare SHA1 value with PCR17 content checked previously with
   `/sys/class/tpm/tpm0/pcrs` output. If DRTM is enabled and executes properly,
   they should be the same. It proves that LZ code utilizes SHA1 algorithm
   during measurements.

   > It is ok, if your PCRs values aren't exactly the same as in above logs.
   > Since writing this instruction, some changes were most probably added to
   > LZ. Therefore, make sure to always compare values between script and
   > command output on your local machine, rather than with above logs.

##### Check if LZ debug option can be enabled

1. Boot NixOS and go to `/nix/store/` directory.

   ```bash
   cd /nix/store/
   ```

1. Find landing-zone package (without debug).

   ```bash
   $ ls /nix/store/ | grep landing-zone
   5q92f6l4s1jfbw5ygfr1sd4hlczjj6l2-landing-zone-0.3.0.drv
   6v15ikqsyqk5fs0jg1n6755dp1nr6cyc-landing-zone-debug-0.3.0.drv
   dnpqvb64jjr3x2kxx92wvdkvmah72h6m-landing-zone-debug-0.3.0
   zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0
   ```

   We are looking for entry without `-debug` and `.drv` extension. In this
   particular example, it is
   `zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0`.

1. Copy `lz_header.bin` from above directory to `/boot` directory.

   ```bash
   cp /nix/store/zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0/lz_header.bin /boot/lz_header
   ```

1. Reboot platform and choose `"NixOS - Secure Launch"` entry in GRUB.

   Collect logs during boot to be able to verify them. Using `dmesg` command in
   NixOS doesn't work because it doesn't show pre-kernel stage logs. Correct
   bootlog is shown below.

   ```bash
   grub_cmd_slaunch:122: check for manufacturer
   grub_cmd_slaunch:126: check for cpuid
   grub_cmd_slaunch:136: set slaunch
   grub_cmd_slaunch_module:156: check argc
   grub_cmd_slaunch_module:161: check relocator
   grub_cmd_slaunch_module:170: open file
   grub_cmd_slaunch_module:175: get size
   grub_cmd_slaunch_module:180: allocate memory
   grub_cmd_slaunch_module:192: addr: 0x100000
   grub_cmd_slaunch_module:194: target: 0x100000
   grub_cmd_slaunch_module:196: add module
   grub_cmd_slaunch_module:205: read file
   grub_cmd_slaunch_module:215: close file
   grub_slaunch_boot_skinit:41: real_mode_target: 0x8a000
   grub_slaunch_boot_skinit:42: prot_mode_target: 0x1000000
   grub_slaunch_boot_skinit:43: params: 0xcfe7745early console in extract_kernel
   input_data: 0x00000000023eb3b1
   input_len: 0x0000000000424e94
   output: 0x0000000001000000
   output_len: 0x00000000017e7398
   kernel_total_size: 0x000000000142c000
   trampoline_32bit: 0x000000000009d000
   booted via startup_32()
   Physical KASLR using RDTSC...
   Virtual KASLR using RDTSC...

   Decompressing Linux... Parsing ELF... Performing relocations... done.
   Booting the kernel.
   [    0.000000] Linux version 5.1.0 (nixbld@localhost) (gcc version 9.2.0 (GCC)) #1-NixOS SMP Thu Jan 1 00:00:01 UTC 1970
   [    0.000000] Command line: BOOT_IMAGE=(hd0,msdos1)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/j4
   [    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'

   (...)

   <<< Welcome to NixOS 20.09.git.a070e686875 (x86_64) - ttyS0 >>>

   Run 'nixos-help' for the NixOS manual.
   ```

   **Verification**: We have chosen `lz_header` (LZ) without debug. Above log is
   correct example for such case. Pre-kernel logs are limited to minimum.

1. Go to `/nix/store/` directory.

   ```bash
   cd /nix/store/
   ```

1. Find landing-zone package (with debug).

   ```bash
   $ ls /nix/store/ | grep landing-zone-debug
   6v15ikqsyqk5fs0jg1n6755dp1nr6cyc-landing-zone-debug-0.3.0.drv
   dnpqvb64jjr3x2kxx92wvdkvmah72h6m-landing-zone-debug-0.3.0
   ```

   `dnpqvb64jjr3x2kxx92wvdkvmah72h6m-landing-zone-debug-0.3.0` is directory we
   are looking for.

1. Copy `lz_header.bin` from above directory to `/boot` directory.

   ```bash
   cp /nix/store/dnpqvb64jjr3x2kxx92wvdkvmah72h6m-landing-zone-debug-0.3.0/lz_header.bin /boot/lz_header
   ```

1. Reboot platform and choose `"NixOS - Secure Launch"` entry in GRUB.

   Once again, collect logs during boot to be able to verify them. Using `dmesg`
   command in NixOS doesn't work, as in previous case. Correct bootlog is shown
   below.

   ```bash
   grub_cmd_slaunch:122: check for manufacturer
   grub_cmd_slaunch:126: check for cpuid
   grub_cmd_slaunch:136: set slaunch
   grub_cmd_slaunch_module:156: check argc
   grub_cmd_slaunch_module:161: check relocator
   grub_cmd_slaunch_module:170: open file
   grub_cmd_slaunch_module:175: get size
   grub_cmd_slaunch_module:180: allocate memory
   grub_cmd_slaunch_module:192: addr: 0x100000
   grub_cmd_slaunch_module:194: target: 0x100000
   grub_cmd_slaunch_module:196: add module
   grub_cmd_slaunch_module:205: read file
   grub_cmd_slaunch_module:215: close file
   grub_slaunch_boot_skinit:41: real_mode_target: 0x8a000
   grub_slaunch_boot_skinit:42: prot_mode_target: 0x1000000
   grub_slaunch_boot_skinit:43: params: 0xcfe7746sl_stub_entry_offset:
   0x00000000014318a8: d0 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00   ................
   0x00000000014318b8: 23 02 00 00 00 00 00 00 00 00 00 00 66 66 2e 0f   #...........ff..
   0x00000000014318c8: 1f 84 00 00 00 00 00 90 fa fc 8d a5 c4 9c 43 00   ..............C.
   0x00000000014318d8: 01 ad 72 6c 43 00 0f 01 95 70 6c 43 00 b8 10 00   ..rlC....plC....
   0x00000000014318e8: 00 00 8e d8 8e c0 8e e0 8e e8 8e d0 8d 85 fe 18   ................
   0x00000000014318f8: 43 00 6a 08 50 cb b9 1b 00 00 00 0f 32 a9 00 01   C.j.P.......2...
   0x0000000001431908: 00 00 75 02 0f 0b bf 01 00 00 00 31 c0 0f a2 81   ..u........1....
   0x0000000001431918: fb 47 65 6e 75 0f 85 82 00 00 00 81 fa 69 6e 65   .Genu........ine
   0x0000000001431928: 49 75 7a 81 f9 6e 74 65 6c 75 72 bf 02 00 00 00   Iuz..ntelur.....
   0x0000000001431938: c7 85 b0 6c 43 00 02 00 00 00 ff 85 bc 6c 43 00   ...lC........lC.
   0x0000000001431948: 31 db b8 07 00 00 00 0f 37 8d 85 5c 19 43 00 9c   1.......7..\.C..
   0x0000000001431958: 6a 08 50 cf c7 05 30 00 d2 fe 00 00 00 00 c7 05   j.P...0.........
   0x0000000001431968: 08 00 d2 fe ff ff ff ff a1 00 03 d2 fe 8b 08 8d   ................
   0x0000000001431978: 44 08 08 8b 70 04 89 a8 34 02 00 00 8b b8 3c 02   D...p...4.....<.
   0x0000000001431988: 00 00 89 bd c0 6c 43 00 50 56 e8 e9 00 00 00 5e   .....lC.PV.....^
   0x0000000001431998: e8 c3 01 00 00 5f e8 5d 01 00 00 eb 0e c7 85 b0   ....._.]........
   shasum calculated:
   0x00000000001001b0: ed a5 f1 9e 28 0e d8 b3 5a de bc b6 e7 15 c8 de   ....(...Z.......
   0x00000000001001c0: 1f bb 2c aa f2 8a af c8 a0 2f d3 60 d5 d0 78 a1   ..,....../.`..x.
   PCR extended
   pm_kernel_entry:
   0x00000000010001d0: 8d ab 30 fe ff ff e9 f5 16 43 00 00 00 00 00 00   ..0......C......
   0x00000000010001e0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   ................
   ...
   0x0000000001000200: 31 c0 8e d8 8e c0 8e d0 8e e0 8e e8 48 8d 2d ed   1...........H.-.
   0x0000000001000210: fd ff ff 8b 86 30 02 00 00 ff c8 48 01 c5 48 f7   .....0.....H..H.
   0x0000000001000220: d0 48 21 c5 48 81 fd 00 00 00 01 7d 07 48 c7 c5   .H!.H......}.H..
   0x0000000001000230: 00 00 00 01 8b 9e 60 02 00 00 81 eb 00 60 46 00   ......`......`F.
   0x0000000001000240: 48 01 eb 48 8d a3 40 de 44 00 48 31 c0 e8 00 00   H..H..@.D.H1....
   0x0000000001000250: 00 00 5f 48 81 ef 52 02 00 00 e8 3e 50 42 00 48   .._H..R....>PB.H
   0x0000000001000260: 8d 05 e4 68 43 00 48 89 05 d5 68 43 00 0f 01 15   ...hC.H...hC....
   0x0000000001000270: cc 68 43 00 56 48 89 f7 e8 b3 a9 42 00 5e 48 89   .hC.VH.....B.^H.
   0x0000000001000280: c1 48 8d 3d 0c 00 00 00 6a 08 48 8d 80 00 10 00   .H.=....j.H.....
   0x0000000001000290: 00 50 48 cb 48 8d a3 40 de 44 00 56 48 8d bb 00   .PH.H..@.D.VH...
   0x00000000010002a0: 50 46 00 e8 c8 ab 42 00 5e 6a 00 9d e8 00 00 00   PF....B.^j......
   0x00000000010002b0: 00 58 48 2d b1 02 00 00 48 89 df e8 dd 4f 42 00   .XH-....H....OB.
   0x00000000010002c0: 56 48 8d 35 70 9b 43 00 48 8d bb 38 9e 43 00 48   VH.5p.C.H..8.C.H
   zero_page:
   0x000000000008a000: 00 0d 00 80 00 00 03 50 00 00 00 00 00 00 19 01   .......P........
   0x000000000008a010: 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   ................
   0x000000000008a020: 3f a3 00 10 00 00 00 00 00 00 00 00 00 00 00 00   ?...............
   0x000000000008a030: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   ................
   ...
   0x000000000008a0d0: 00 00 00 00 00 00 00 00 00 a0 10 00 00 00 00 00   ................
   0x000000000008a0e0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   ................
   ...
   lz_base:
   0x0000000000100000: d4 01 00 d0 00 00 00 00 00 00 00 00 00 00 00 00   ................
   0x0000000000100010: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   ................
   ...
   0x0000000000100060: 19 19 10 00 00 00 00 00 00 00 00 00 00 00 00 00   ................
   0x0000000000100070: b0 00 10 00 00 00 00 00 40 00 00 00 aa f3 e2 dc   ........@.......
   0x0000000000100080: 00 29 10 00 00 00 00 00 1a 13 e2 aa 1d af ab 59   .).............Y
   0x0000000000100090: cc 8e 1e 1c 68 42 f8 12 28 01 10 00 00 00 00 00   ....hB..(.......
   0x00000000001000a0: b3 e1 3a e9 08 00 00 00 58 01 10 00 00 00 00 00   ..:.....X.......
   0x00000000001000b0: 4b 88 d2 cb 27 91 a5 53 bb 49 64 ae 32 40 a6 ce   K...'..S.Id.2@..
   0x00000000001000c0: aa a1 96 a1 e6 b4 6c df 8e b7 83 ee 2c 13 aa 8f   ......l.....,...
   0x00000000001000d0: 98 5a cb bb b0 64 34 b3 5f 8c 20 28 a7 52 64 06   .Z...d4._. (.Rd.
   0x00000000001000e0: d1 b4 50 95 e6 2b 8f b2 4d 33 a4 80 ca e5 7d 48   ..P..+..M3....}H
   0x00000000001000f0: 30 01 10 00 00 00 00 00 b0 01 10 00 00 00 00 00   0...............
   early console in extract_kernel
   input_data: 0x00000000023eb3b1
   input_len: 0x0000000000424e94
   output: 0x0000000001000000
   output_len: 0x00000000017e7398
   kernel_total_size: 0x000000000142c000
   trampoline_32bit: 0x000000000009d000
   booted via startup_32()
   Physical KASLR using RDTSC...
   Virtual KASLR using RDTSC...

   Decompressing Linux... Parsing ELF... Performing relocations... done.
   Booting the kernel.
   [    0.000000] Linux version 5.1.0 (nixbld@localhost) (gcc version 9.2.0 (GCC)) #1-NixOS SMP Thu Jan 1 00:00:01 UTC 1970
   [    0.000000] Command line: BOOT_IMAGE=(hd0,msdos1)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/14
   [    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'
   (...)
   ```

   **Verification**: As you can see, debug output is more verbose than previous
   one. It has additional information about e.g. LZ, zero page etc. Above
   procedure proves that LZ is available in debug and non-debug version. Both
   can be easily adopted by user in NixOS. However, we recommend to use
   non-debug one.

## Changes in source code

Above requirements can be inspected in source code of above components too. I
give references to exact places (repository and files), where to find this
features.

1. LZ can be built with and without debug flag; by default it is non-debug
   build.

   Repository:
   [TrenchBoot/landing-zone - tag v0.3.0](https://github.com/TrenchBoot/landing-zone/tree/v0.3.0)

   Files:

   1. [Makefile](https://github.com/TrenchBoot/landing-zone/blob/v0.3.0/Makefile#L5L7)
   1. [main.c](https://github.com/TrenchBoot/landing-zone/blob/v0.3.0/main.c#L31#L141)

1. LZ code utilizes SHA256 algorithm during measurements with TPM2.0.

   Repository:
   [TrenchBoot/landing-zone - tag v0.3.0](https://github.com/TrenchBoot/landing-zone/tree/v0.3.0)

   Files:

   1. [sha256.c](https://github.com/TrenchBoot/landing-zone/blob/v0.3.0/sha256.c)

1. LZ code utilizes SHA1 algorithm during measurements with TPM1.2.

   Repository:
   [3mdeb/landing-zone - branch tpm12_fix](https://github.com/3mdeb/landing-zone/tree/tpm12_fix)

   Files:

   1. [sha1sum.c](https://github.com/3mdeb/landing-zone/blob/tpm12_fix/sha1sum.c)

1. LZ implementation of TPM interface cover both TPM2.0 and TPM1.2 and use
   appropriate SHA algorithm.

   Repository:
   [TrenchBoot/landing-zone - tag v0.3.0](https://github.com/TrenchBoot/landing-zone/tree/v0.3.0)

   Files:

   1. [main.c](https://github.com/TrenchBoot/landing-zone/blob/v0.3.0/main.c#L220#L236)

1. Linux kernel utilizes SHA256 during measurements.

   Repository: [3mdeb/linux-stable](https://github.com/3mdeb/linux-stable)

   Files:

   1. [arch/x86/boot/compressed/sl_main.c](https://github.com/3mdeb/linux-stable/blob/linux-sl-5.1-sha2-amd/arch/x86/boot/compressed/sl_main.c#L115#L158)

## Summary

With theoretical knowledge and now also practice you should be able to enable
DRTM on your platform and verify its operations. Further development will bring
more features. Each of them will be presented in similar way. Each of them also
will be verifiable by you. So stay tuned and follow our social media for more
information!

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up for our
newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

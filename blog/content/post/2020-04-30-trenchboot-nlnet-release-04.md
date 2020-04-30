---
title: 'TrenchBoot: Open Source DRTM. DRTM update and meta-trenchboot implementation'
abstract: Another release brings new updates in our Open Source DRTM project.
          Except for code changes, we have prepared our custom Linux image with
          DRTM. Also we set up CI/CD system for automation build and test. Read
          this article if you want to find out more details.
cover: /covers/trenchboot-logo.png
author: piotr.kleinschmidt
layout: post
published: true
date: 2020-04-30
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

[Previous article](https://blog.3mdeb.com/2020/2020-04-03-trenchboot-nlnet-lz-validation/)
showed how to enable DRTM on PC Engines apu2 platform and NixOS operating
system. As project is constantly developed by us, there are regularly new
features implemented. This article is showing how to update your DRTM and verify
next project's requirements. Also, we will show you new custom Linux image with
DRTM enabled.

Remember, that typically, new updates should be published every month as form of
following blog posts and they will develop already configured system components.
Therefore, **we strongly encourage to keep project up-to-date and keep track of
TrenchBoot blog posts series**. If you haven't read previous articles, we
recommend to catch up. At this point, we have already introduced project's
motivation and goals. Moreover, we have shown what platform and operating system
we use for development and tests. Finally, we have enabled DRTM on our platform
and prepared exact step-by-step procedure, so you can enable it too!

## What's new

We have made following changes since last release:

1. general **DRTM update in NixOS** (including landing-zone, Linux kernel
and Grub)
1. enabled DRTM in Yocto custom Linux built - **meta-trenchboot**
1. introduced **CI/CD system** to build each TrenchBoot components

First two from above points is described with details later in this article. It
is divided into sections:

1. Update DRTM in NixOS
1. Enable DRTM in custom Linux built

> Depending on specific section, there are already met project's requirements
  mentioned and ways to verify them.

CI/CD system is rather comprehensive topic, so we decided to describe it in
[seperate article](https://blog.3mdeb.com/2020/2020-04-30-trenchboot-nlnet-release-04-ci-cd/).

## Update DRTM in NixOS

Since last release, there are improvements in **landing-zone, grub and Linux
kernel**. All of these components should be updated. Following procedure is
showing how to do this properly.

>Remember, that everything is done in NixOS and further verification is done for
system precisely configured this way.

1. Pull `3mdeb/nixpkgs` repository.

    ```
    $ cd ~/nixpkgs
    $ git branch trenchboot_support_2020.04
    $ git pull
    ```

2. Pull `3mdeb/nixos-trenchboot-configs` repository.

    ```
    $ cd ~/nixos-trenchboot-configs
    $ git branch master
    $ git pull
    ```

3. Copy all configuration files to `/etc/nixos/` directory.

    ```
    $ cp nixos-trenchboot-configs/*.nix /etc/nixos
    ```

4. Update Linux kernel.

    > Linux kernel update must be done separately due to *out of memory error*
    which might appear when entire system is rebuilt.

    ```
    $ // Linux kernel update logs
    ```

5. Update entire system.

    > Now, there should be Landing Zone and grub updated.

    ```
    $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
    building Nix...
    building the system configuration...
    ```

6. Re-install grub to `/dev/sdX`.

    ```
    $ grub-install /dev/sda
    ```

7. Ensure that `slaunch` module is present in `/boot/grub/i386-pc/`.

    ```
    $ ls /boot/grub/i386-pc | grep slaunch
    slaunch.mod
    ```

8. Find new `Landing Zone` package in `/nixos/store/`.

    ```
    $ ls /nix/store/ | grep landing-zone
    5q92f6l4s1jfbw5ygfr1sd4hlczjj6l2-landing-zone-0.3.0.drv
    6v15ikqsyqk5fs0jg1n6755dp1nr6cyc-landing-zone-debug-0.3.0.drv
    dnpqvb64jjr3x2kxx92wvdkvmah72h6m-landing-zone-debug-0.3.0
    zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0
    ```

9. Copy `lz_header.bin` to `/boot/` directory.

    ```
    $ cp /nix/store/<new-lz-package>/lz_header.bin /boot/lz_header
    ```

10. Check `/boot/grub/grub.cfg` file and its `NixOS - Default menu entry`.
Adjust `/etc/nixos/configuration.nix` and its `boot.loader.grub.extraEntries`
line to have exactly the same directories included.

    ```
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
    `boot.loader.grub.extraEntriesline` like this:

    ```
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

    If there are differences in any of `search --set=drive1...`, `search
    --set=drive2...`, `linux ($drive2)/nix/store...` lines, edit
    `configuration.nix` content and copy those lines from `grub.cfg` menuentry
    `"NixOS - Default"`. They must be exactly the same.

11. Update system for the last time.

    ```
    $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
    ```

12. Reboot platform

    ```
    $ reboot

    ```

13. Choose `"NixOS - Secure Launch"` entry in grub menu and check if platform
    boots correctly.


#### Requirements verification - LZ content and layout

There are two requirements which LZ must met:

1. bootloader information header in LZ should be moved at the end of the LZ
binary or the end of code section of the LZ.

1. the size of the measured part of the SLB must be set to the code size only.

Bootloader information header is special data structure which layout is
hardcoded in [landing-zone source code](https://github.com/TrenchBoot/landing-zone/blob/master/include/boot.h#L50).
The requirement is to keep that data in `lz_header.bin` file after code section.
Hence, when SKINIT instruction makes measurements of the Landing Zone, only code
section is measured. Verification of above requirements can be carried out like
this:

1. Check the value of second word of `lz_header.bin` file using `hexdump`
tool.

    ```
    $ hexdump -C lz_header.bin | head                                                    
    00000000  d4 01 00 d0 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    000001d0  00 00 00 00 89 c5 8d a5  00 02 00 00 b9 14 01 01  |................|
    000001e0  c0 0f 32 83 e0 f9 0f 30  01 ad bc 27 00 00 01 ad  |..2....0...'....|
    000001f0  52 02 00 00 01 ad 00 90  00 00 01 ad 00 80 00 00  |R...............|
    00000200  01 ad 08 80 00 00 01 ad  10 80 00 00 01 ad 18 80  |................|
    00000210  00 00 01 ad 00 40 00 00  0f 01 95 ba 27 00 00 b8  |.....@......'...|
    00000220  10 00 00 00 8e d8 8e c0  0f 20 e1 83 c9 20 0f 22  |......... ... ."|
    00000230  e1 8d 85 00 90 00 00 0f  22 d8 b9 80 00 00 c0 0f  |........".......|
    ```

    > Value of second word (`00 d0`) is size of code section and concurrently
    offset (address) of bootloader information header. Used notation is
    little-endian so the value is actually `0xd000` (NOT 0x00d0).

2. Check the content of `lz_header.bin` file from `0xd000` address.

    ```
    $ hexdump -C -s 0xd000 lz_header.bin | head                                          
    0000d000  78 f1 26 8e 04 92 11 e9  83 2a c8 5b 76 c4 cc 02  |x.&......*.[v...|
    0000d010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    0000d030  04 00 00 00 10 00 00 00  05 00 00 00 47 4e 55 00  |............GNU.|
    0000d040  01 00 00 c0 04 00 00 00  01 00 00 00 00 00 00 00  |................|
    0000d050
    ```

    > As you can see, there is `78 f1 26 8e 04 92 11 e9  83 2a c8 5b 76 c4 cc
    02` data under 0xd000 address.

3. If above data is the same as in data structure in
[landing-zone source code](https://github.com/TrenchBoot/landing-zone/blob/master/include/boot.h#L50)
then it is **bootloader information header**. In given example, it is
placed after code section in LZ.

    Debug version of landing zone can be checked exactly the same way. Just
    make sure, you read address properly, as it probably isn't the same
    value as in non-debug landing-zone.

1. Check value of second word of `lz_header_debug.bin` file using
`hexdump` tool.

    ```
    $ hexdump -C lz_header_debug.bin | head                                              
    00000000  d4 01 00 e0 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    000001d0  00 00 00 00 89 c5 8d a5  00 02 00 00 b9 14 01 01  |................|
    000001e0  c0 0f 32 83 e0 f9 0f 30  01 ad ac 2b 00 00 01 ad  |..2....0...+....|
    000001f0  52 02 00 00 01 ad 00 a0  00 00 01 ad 00 90 00 00  |R...............|
    00000200  01 ad 08 90 00 00 01 ad  10 90 00 00 01 ad 18 90  |................|
    00000210  00 00 01 ad 00 50 00 00  0f 01 95 aa 2b 00 00 b8  |.....P......+...|
    00000220  10 00 00 00 8e d8 8e c0  0f 20 e1 83 c9 20 0f 22  |......... ... ."|
    00000230  e1 8d 85 00 a0 00 00 0f  22 d8 b9 80 00 00 c0 0f  |........".......|
    ```

    > Value of the second word (`00 e0`) is size of code section and
    concurrently offset (address) of bootloader information header. Used
    notation is little-endian so the offset is actually `0xe000` (NOT 0x00e0).

2. Check the content of `lz_header_debug.bin` file from `0xe000` address.

    ```
    $ hexdump -C -s 0xe000 lz_header_debug.bin | head                                    
    0000e000  78 f1 26 8e 04 92 11 e9  83 2a c8 5b 76 c4 cc 02  |x.&......*.[v...|
    0000e010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    0000e030  04 00 00 00 10 00 00 00  05 00 00 00 47 4e 55 00  |............GNU.|
    0000e040  01 00 00 c0 04 00 00 00  01 00 00 00 00 00 00 00  |................|
    0000e050
    ```

    > As you can see, there is `78 f1 26 8e 04 92 11 e9  83 2a c8 5b 76 c4 cc
    02` data under 0xe000 address.

3. If above data is the same as in data structure in
[landing-zone source code](https://github.com/TrenchBoot/landing-zone/blob/master/include/boot.h#L50)
then it is **bootloader information header**. In given example, it is
placed after code section in LZ.

## Enable DRTM in custom Linux built

Our custom Linux built is called **meta-trenchboot**. To use it on your PC
Engines apu2 platform, all you need to have is:

1. SSD disk to store image.
1. Linux operating system (e.g. Debian) with `bmaptool` tool to flash SSD
  disk.
1. [tb-minimal-image-pcengines-apu2.wic.bmap](https://cloud.3mdeb.com/index.php/s/3c5QNHbNRx5gpY5/download)
  file.
1. [tb-minimal-image-pcengines-apu2.wic.gz](https://cloud.3mdeb.com/index.php/s/xd9z3iDS3gkPrmQ/download)
  file.

`tb-minimal-image-pcengines-apu2.wic.*` files are built from
[3mdeb/meta-trenchboot](https://github.com/3mdeb/meta-trenchboot) repository.
You can build them on your own thanks to included instruction. However, we have
already prepared working images, so you can just download them. Installation
procedure will cover second scenario.

Procedure that will be presented shortly is conventional *disk flashing process
with usage of `bmaptool`*. Therefore, steps 1-3 can be carried out on any
machine with Linux. In this particular example, we are using only PC Engines
apu2 platform with iPXE enabled and SSD disk included.

1. Boot to Linux based operating system.

    In our case it is Debian Stable 4.16 booted via iPXE.

2. Download *tb-minimal-image.bmap* and *tb-minimal-image.gz* files from 3mdeb
  cloud.

    ```
    $ wget -O tb-minimal-image-pcengines-apu2.wic.bmap https://cloud.3mdeb.com/index.php/s/3c5QNHbNRx5gpY5/download
    $ wget -O tb-minimal-image-pcengines-apu2.wic.gz https://cloud.3mdeb.com/index.php/s/xd9z3iDS3gkPrmQ/download
    ```

3. Using `bmaptool` flash SSD disk with downloaded image.

    > **IMPORTANT**: Make sure to use proper target device - /dev/sdX. In our
    case it is /dev/sda, but can be different for you.

    Usage of bmaptool is: `bmaptool copy --bmap <image.wic.bmap> <image.wic.gz> </dev/sdX>`

    ```
    $ bmaptool copy --bmap tb-minimal-image-pcengines-apu2.wic.bmap tb-minimal-image-pcengines-apu2.wic.gz /dev/sda
    [ 1076.049347]  sda: sda1 sda2
    bmaptool: info: block map format version 2.0
    bmaptool: info: 532480 blocks of size 4096 (2.0 GiB), mapped 48007 blocks (187.5 MiB or 9.0%)
    bmaptool: info: copying image 'tb-minimal-image-pcengines-apu2.wic.gz' to block device '/dev/sda' using bmap file 'tb-minimal-image-pcengines-apu2.wic.bmap'
    (...)
    bmaptool: info: 99% copied
    [ 1120.645490]  sda: sda1 sda2
    ```

4. Reboot platform and boot from just flashed SSD disk.

    You should see GRUB menu with 2 entries:

    - boot - it is 'normal' boot without DRTM
    - secure-boot - it is boot with **DRTM enabled**

5. Choose `secure-boot` entry, verify bootlog and enjoy platform with DRTM!

    At the beginning, there should be similar output:

    ```
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
    grub_slaunch_boot_skinit:41: real_mode_target: 0x8b000
    grub_slaunch_boot_skinit:42: prot_mode_target: 0x1000000
    grub_slaunch_boot_skinit:43: params: 0xcfe2391
    code32_start 0x0000000001000000:
    (...)
    ```

    > It indicates that DRTM is enabled and executed. For details about bootflow
    and DRTM verification we refer to [previous article](https://blog.3mdeb.com/2020/2020-04-03-trenchboot-nlnet-lz-validation/)
    in which it is precisely described.

# Summary

If you followed showed procedures, you should have up-to-date DRTM in your NixOS
or custom Linux image with DRTM enabled. As mentioned at the beginning, in next
article we introduce our CI/CD system. You will see how it improve development
and how entire community will take advantage of it.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

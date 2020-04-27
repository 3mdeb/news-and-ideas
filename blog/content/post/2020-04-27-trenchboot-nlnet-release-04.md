---
title: 'TrenchBoot: Open Source DRTM. Landing zone update.'
abstract:
cover: /covers/trenchboot-logo.png
author: piotr.kleinschmidt
layout: post
published: false
date: 2020-04-27
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
next project's requirements. Typically, new updates should be published every
month as form of following blog posts and they will develop already configured
system components. Therefore, **we strongly encourage to keep project up-to-date
and keep track of TrenchBoot blog posts series**. If you haven't read previous
articles, we recommend to catch up.

## Update DRTM in NixOS

Since last release, there are improvements in **landing-zone, grub and Linux
kernel**. All of these components should be updated. Following procedure is
showing how to do this properly.

>Remember, that everything is done in NixOS and further verification is done for
system precisely configured this way.

      1. Pull `3mdeb/nixpkgs` repository.

      ```
      $ cd ~/nixpkgs
      $ git branch trenchboot_support_2020.03
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

      4. Update system.

      ```
      $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
      building Nix...
      building the system configuration...
      ```

      5. Reboot platform

      ```
      $ reboot
      ```

## Requirements verification

### LZ content and layout

There are two requirements which LZ must met:

- bootloader information header in LZ should be moved at the end of the LZ
binary or the end of code section of the LZ;
- the size of the measured part of the SLB must be set to the code size only;

Bootloader information header is special data structure which content is
hardcoded in [landing-zone source code](https://github.com/TrenchBoot/landing-zone/blob/master/include/boot.h#L50).
The requirement is to keep that data in `lz_header.bin` file after code section.
Hence, when Landing Zone makes measurements, only code section is measured.
Verification of above requirements can be carried out like this:

      1. Check the content of second word of `lz_header.bin` file. Use `hexdump`
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

      > Second word (`00 d0`) is size of code section and concurrently offset
      (address) of bootloader information header. Used notation is little-endian
      so the offset is actually `0xd000` (NOT 0x00d0)

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
      then it is **bootloader information header** and it is at the end of code
      section of the LZ.

Debug version of landing zone can be checked exactly the same way. Just make
sure, you read address properly, as it probably won't be the same as in
non-debug landing-zone.

      1. Check the content of second word of `lz_header_debug.bin` file. Use
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

      > Second word (`00 e0`) is size of code section and concurrently offset
      (address) of bootloader information header. Used notation is little-endian
      so the offset is actually `0xe000` (NOT 0x00e0)

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
      then it is **bootloader information header** and it is at the end of code
      section of the LZ.

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

---
title: TrenchBoot: Open Source DRTM. GRUB's features and TPM event log.
abstract: This blog post will show you what features we have added to GRUB
          and why they are useful from our point of view. Also, there
          will be shown how to utilize TPM event logs and hence debug DRTM.
cover: /covers/trenchboot-logo.png
author: piotr.kleinschmidt
layout: post
published: false
date: 2020-06-30
archives: "2020"

tags:
  - security
  - open-source
  - grub
  - trenchboot
  - nixos
categories:
  - Firmware
  - Security

---

If you haven't read previous blog posts from *TrenchBoot* series, we strongly
encourage to catch it up. Best way, is to search under
[TrenchBoot](https://blog.3mdeb.com/tags/trenchboot/) tag. In this article, we
want to show what changes have been made in GRUB and what was our motivation to
introduce them. Also, we will introduce **TPM event log**, which is useful tool
for DRTM debugging. Besides theoretical considerations, there is the
**verification part** which introduce particular examples and verification
procedures.

## GRUB additional feature - CBFS and LZMA support

Before moving to essential part of GRUB development, first you need to
understand what stands behind **CBFS** and **LZMA**. *CBFS* stands for *coreboot
filesystem* and it is 'kind of layout' in which every coreboot's binary file is
organized. As name might be misleading, it is **not actual filesystem**. It only
describes what components in what order should be presented in SPI Flash (if it
is flashed with coreboot of course). With such unification, it is much easier
for developers and users to manipulate coreboot's image, debug it or check its
integrity. Also, it allows to makes changes on final binary file (e.g. adding or
removing some part of coreboot) by utilizng special tool - `cbfstool`. More
about it will be presented later.

Second abbreviation - **LZMA** stands for *Lempel-Ziv-Markov chain-Algorithm*
and it is **compression algorithm** strongly used in coreboot (and not only
there). As SPI flash capacity is not great, but hardware and BIOS is getting
more complex and in effect final binary files are larger, it is common to use
compression wherever it is possible. Therefore, LZMA can be utilized in coreboot
for e.g. payloads. The goal is simple - make binary file as slim as possible, so
there is more space for the other components. Moreover, LZMA has high degree of
compression. Hence using it is not triumph of form over content, but very
reliable solution.

Now, when you have some theoretical background, you probably have one question -
how it is related to TrenchBoot and GRUB? Answer is very simple. We prepare GRUB
to support making operations on CBFS files (coreboot binaries) to create basis
for possible LZ integration into coreboot's project. It means that in the
feature, there will be possibility to have LZ already included in coreboot's
binary. However, it is not reliable to take 64kB of space (LZ size), if we can
compress it and take only 16kB. GRUB's part is essential here. First, it must
read coreboot binary file layout. Second, it must decompress LZ, so it is
prepared to be measured with DRTM. And that is exactly what we have introduced
in this TrenchBoot project release! Now, GRUB have features to read SPI flash
coreboot image and decompress any LZMA-compressed components.

### GRUB features verification

As every requirement, this one can also be validated by you. However, before
GRUB verification, first we need to preapre special coreboot image and update
GRUB package to have additional features included.

> Remember that every verification procedure, if it is possible, is done in
NixOS. Also, following requirements are only valid for platforms with coreboot.

#### coreboot image preparation

TO BE DONE: Description, how to add compressed text file to coreboot image and
check final binary file layout.

#### GRUB package update

1. Update `nixpkgs` repository.

    It is assumed that you have already downloaded custom
    [3mdeb/nixpkg](https://github.com/3mdeb/nixpkgs) repository to your NixOS.
    If yes, then go to `nixpkgs/` directory and pull `grub_cbfs_support` branch.

    ```
    $ cd ~/nixpkgs/
    $ git checkout grub_cbfs_support
    ```

2. Rebuild GRUB package.

    Only package which has been changed is `nixpkgs/pkgs/tools/misc/grub-tb/`.
    Go to `nixpkgs` top directory and run following command:

    ```
    $ nix-build -A grub-tb
    (...)
    moving /nix/store/b3mnqqjal6zr4ap2l0d5flvfx1ww6my8-grub-tb-1.2/sbin/* to /nix/store/b3mnqqjal6zr4ap2l0d5flvfx1ww6my8-grub-tb-1.2/bin
    /nix/store/b3mnqqjal6zr4ap2l0d5flvfx1ww6my8-grub-tb-1.2
    ```

3. Rebuild NixOS to apply changes.

    ```
    $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
    building Nix...
    building the system configuration...
    (...)
    updating GRUB 2 menu...
    installing the GRUB 2 boot loader on /dev/sda...
    Installing for i386-pc platform.
    Installation finished. No error reported.
    ```

    > There should be `updating GRUB 2 menu...` log after above command. It
    indicates that grub has been updated.

4. Reboot system and check if you can boot to NixOS via `Secure Launch` entry.

    ```
    $ reboot
    ```

If GRUB update procedure went well, we can move on to *GRUB CBFS and LZMA
support* verification.

#### GRUB CBFS and LZMA support verification

1. Reboot platform and go to GRUB menu.

    ```
    $ reboot
    (...)

    *NixOS - Default
    NixOS - Secure Launch
    NixOS - All configurations

    Press enter to boot the selected OS, `e' to edit the commands       
    before booting or `c' for a command-line.                                                                                                                                                 
    ```

2. Press `c` to enter command-line. Do not boot to NixOS.

    ```
    Minimal BASH-like line editing is supported. For the first word, TAB   
    lists possible command completions. Anywhere else TAB lists possible   
    device or file completions. ESC at any time exits.

    grub>
    ```

3. Load necessary modules for CBFS and LZMA support.

    ```
    grub> insmod /boot/grub/i386-pc/lzma.mod
    grub> insmod /boot/grub/i386-pc/cbfs.mod
    ```

4. Check if `(cbfsdisk)` is seen by GRUB.

    ```
    grub> ls
    (cbfsdisk) (hd0) (hd0,msdos2) (hd0,msdos1) (hd1) (hd1,msdos5) (hd1,msdos1) (hd2
    ) (hd3) (hd4) (hd4,msdos5) (hd4,msdos1)
    ```

    `cbfsdisk` is your SPI flash and coreboot binary file itself.

5. Check `cbfsdisk` layout.

    ```
    grub> ls (cbfsdisk)/

    cbfs master header fallback/ config revision bootorder_map bootorder fallback/
    spd.bin fallback/ payload_config payload_revision bootorder_def etc/ img/
    genroms/ etc/ test-file AGESA apu/ bootblock
    ```

    Although components are not presented in listed form, check if content above
    is exactly the same as previously checked with `cbfstool`. Especially, look
    for added `test-file`. If content is verified by you, it means that **GRUB
    supports CBFS**.

6. Decompress `test-file` from `cbfsdisk`.


    ```
    grub> cat (cbfsdisk)/test-file
    First part of file:
    If you can read this, then it is the proof that grub LZMA decompression works c
    orrectly.
    If you can read this, then it is the proof that grub LZMA decompression works c
    orrectly.
    If you can read this, then it is the proof that grub LZMA decompression works c
    orrectly.
    If you can read this, then it is the proof that grub LZMA decompression works c
    orrectly.
    If you can read this, then it is the proof that grub LZMA decompression works c
    orrectly.
    If you caan read this, then it is the proof that grub LZMA decompression works c
    orrectly.
    If you can read this, then it is the proof that grub LZMA decompression works c
    orrectly.
    Second part:
    It is the second part of file, just to have something else besides one repeated
    sentence.
    It is the second part of file, just to have something else besides one repeated
    sentence.
    It is the second part of file, just to have something else besides one repeated
    sentence.
    It is the second part of file, just to have something else besides one repeated
    sentence.
    It is the second part of file, just to have something else besides one repeated
    sentence.
    It is the second part of file, just to have something else besides one repeated
    sentence.
    It is the second part of file, just to have something else besides one repeated
    sentence.
    Third part:
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin nibh augue, susc
    ipit a, scelerisque sed, lacinia in, mi. Cras vel lorem. Etiam pellentesque ali
    quet tellus. Phasellus pharetra nullla ac diam. Quisque semper justo at risus. D
    onec venenatis, turpis vel hendrerit interdum, dui ligula ultricies purus, sed
    posuere libero dui id orci. Nam congue, pede vitae dapibus aliquet, elit magna
    vulputate arcu, vel tempus metus leo non est. Etiam sit amet lectus quis est co
    ngue mollis. Phasellus congue lacus eget neque. Phasellus ornare, ante vitae co
    nsectetuer consequat, purus sapien ultricies dolor, et mollis pede metus eget n
    isi. Praesent sodales velit quis augue. Cras suscipit, urna at aliquuam rhoncus,
    urna quam viverra nisi, in interdum massa nibh nec erat.
    ```

    If content of above command is exactly the same as your `test-file.txt`,
    than it means that **GRUB supports LZMA**


## TPM event log

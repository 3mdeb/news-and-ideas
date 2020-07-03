---
title: "TrenchBoot: Open Source DRTM. GRUB's new features and TPM event log."
abstract: This blog post will show you what features we have added to GRUB
          and why they are useful from user's point of view. Also, there
          will be shown how to utilize TPM event logs and hence debug DRTM.
cover: /covers/trenchboot-logo.png
author: piotr.kleinschmidt
layout: post
published: true
date: 2020-07-03
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
introduce them. Also, we will introduce extension of **TPM event log** which
lets users debug DRTM and verify some operations. Besides theoretical
considerations, there is the **verification part** which introduce particular
examples and verification procedures.

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
future, there will be possibility to have LZ already included in coreboot's
binary. However, it is not reliable to take 64kB of space (LZ size), if we can
compress it and take only 16kB. GRUB's part is essential here. First, it must
read coreboot binary file layout. Second, it must decompress LZ, so it is
prepared to be measured with DRTM. And that is exactly what we have introduced
in this TrenchBoot project release. Now, GRUB have features to read SPI flash
coreboot image and decompress any LZMA-compressed components.

### GRUB features verification

As every requirement, this one can also be validated by you. Before
GRUB verification, first we need to preapre special coreboot image and update
GRUB package to have additional features included.

Hardware and firmware specification which we are using for test:

- PC Engines apu2 platform
- coreboot v4.12.0.2
- NixOS operating system

>We don't ensure valid test results if you don't have exactly the same
configuration and environment as above.

Procedure is divided into 3 sections:

- coreboot image preparation
- GRUB upgrade
- feature verification

#### coreboot image preparation

Let's prepare coreboot image, which will include custom text file. This file
should be compressed with LZMA. Later, GRUB should read content of coreboot
image and decompress this message. To manipulate final coreboot binary file, one
can use `cbfstool` utility. It is available with coreboot repository, in
`coreboot/util/cbfstool` directory. We recommend to use
[pcengines/coreboot](https://github.com/pcengines/coreboot/tree/develop/)
repository for apu platforms. To prepare image with custom text file, follow the
procedure below.

1. Download latest coreboot release from [github.io](https://pcengines.github.io/)

    ```
    $ wget https://3mdeb.com/open-source-firmware/pcengines/apu2/apu2_v4.12.0.2.rom -O apu2_v4.12.0.2.rom
    ```

    > At time of writing this blog post, v4.12.0.2.rom was latest release

2. Clone
[pcengines/coreboot](https://github.com/pcengines/coreboot/tree/develop/)
repository.

    ```
    $ git clone https://github.com/pcengines/coreboot -b develop
    ```

3. Enter `coreboot/util/cbfstool` directory and build `cbfstool`.

    ```
    $ cd coreboot/util/cbfstool
    $ make
    ```

    If built was successful, there should be executable file `./cbfstool`
    available.

4. Create text file with any content you wish.

    Only limitation here is to have long enough content, so LZMA will be done.
    If file is too short (e.g. it contains only one sentence), most probably
    LZMA won't execute on it and it won't be compressed. Name the file
    `test-file.txt`.

5. Add previously made text file to coreboot image.

    To achieve this, we will use `cbfstool`. First check layout of original
    coreboot image. Usage is `./cbfstool <path-to-coreboot-image> print`.

    ```
    $ cd coreboot/util/cbfstool
    $ ./cbfstool ../../../apu2_v4.12.0.2.rom print
    FMAP REGION: COREBOOT
    Name                           Offset     Type           Size   Comp
    cbfs master header             0x0        cbfs header        32 none
    fallback/romstage              0x80       stage           21644 none
    config                         0x5580     raw               963 none
    revision                       0x5980     raw               673 none
    spd.bin                        0x5c80     spd               256 none
    bootorder                      0x5dc0     raw              4096 none
    fallback/ramstage              0x6e00     stage           72787 none
    fallback/dsdt.aml              0x18ac0    raw              7098 none
    fallback/postcar               0x1a700    stage           16856 none
    fallback/payload               0x1e940    simple elf      49499 none
    payload_config                 0x2ab00    raw              1571 none
    payload_revision               0x2b180    raw               237 none
    bootorder_map                  0x2b2c0    raw               153 none
    bootorder_def                  0x2b3c0    raw               611 none
    etc/boot-menu-key              0x2b680    raw                 8 none
    etc/boot-menu-wait             0x2b700    raw                 8 none
    etc/boot-menu-message          0x2b780    raw                48 none
    img/memtest                    0x2b800    simple elf      60495 none
    img/setup                      0x3a480    simple elf      38882 none
    genroms/pxe.rom                0x43cc0    raw             83456 none
    etc/sercon-port                0x58300    raw                 8 none
    (empty)                        0x58340    null          5929560 none
    AGESA                          0x5ffdc0   raw            504032 none
    (empty)                        0x67af00   null           675480 none
    apu/amdfw                      0x71fdc0   raw            239872 none
    (empty)                        0x75a700   null           644760 none
    bootblock                      0x7f7dc0   bootblock       32768 none
    ```

    >As you can see there is no section named `test-file` yet.

    Add text file to `apu2_v4.12.0.2.rom`. Assuming text file name is
    `test-file.txt` command is as follow:
    `./cbfstool <path-to-coreboot-image> add -f <path-to-test-file.txt> -n test-file -t raw -c lzma`

    ```
    $ cd coreboot/util/cbfstool
    $ ./cbfstool ../../../apu2_v4.12.0.2.rom add -f ../../../test-file.txt -n test-file -t raw -c lzma
    ```

    Check layout of modified file once again.

    ```
    $ cd coreboot/util/cbfstool
    $ ./cbfstool ../../../apu2_v4.12.0.2.rom print
    FMAP REGION: COREBOOT
    Name                           Offset     Type           Size   Comp
    cbfs master header             0x0        cbfs header        32 none
    fallback/romstage              0x80       stage           21644 none
    config                         0x5580     raw               963 none
    revision                       0x5980     raw               673 none
    spd.bin                        0x5c80     spd               256 none
    bootorder                      0x5dc0     raw              4096 none
    fallback/ramstage              0x6e00     stage           72787 none
    fallback/dsdt.aml              0x18ac0    raw              7098 none
    fallback/postcar               0x1a700    stage           16856 none
    fallback/payload               0x1e940    simple elf      49499 none
    payload_config                 0x2ab00    raw              1571 none
    payload_revision               0x2b180    raw               237 none
    bootorder_map                  0x2b2c0    raw               153 none
    bootorder_def                  0x2b3c0    raw               611 none
    etc/boot-menu-key              0x2b680    raw                 8 none
    etc/boot-menu-wait             0x2b700    raw                 8 none
    etc/boot-menu-message          0x2b780    raw                48 none
    img/memtest                    0x2b800    simple elf      60495 none
    img/setup                      0x3a480    simple elf      38882 none
    genroms/pxe.rom                0x43cc0    raw             83456 none
    etc/sercon-port                0x58300    raw                 8 none
    test-file                      0x58340    raw               584 LZMA (2067 decompressed)
    (empty)                        0x585c0    null          5928920 none
    AGESA                          0x5ffdc0   raw            504032 none
    (empty)                        0x67af00   null           675480 none
    apu/amdfw                      0x71fdc0   raw            239872 none
    (empty)                        0x75a700   null           644760 none
    bootblock                      0x7f7dc0   bootblock       32768 none
    ```

    > There should be `test-file` section added with `LZMA` description in
    compressed column.

6. Flash your platform with prepared image.

    Now you have properly prepared firmware, on which further verification can
    be performed.

#### GRUB package update

1. Update `nixpkgs` repository.

    It is assumed that you have already downloaded custom
    [3mdeb/nixpkg](https://github.com/3mdeb/nixpkgs) repository to your NixOS.
    If yes, then go to `nixpkgs/` directory and pull latest changes. Change
    branch to `grub_cbfs_lzma`.

    ```
    $ cd ~/nixpkgs/
    $ git pull
    $ git checkout grub_cbfs_lzma
    ```

2. Rebuild NixOS to apply changes.

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

3. Reboot system and check if you can boot to NixOS via `Secure Launch` entry.

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

    >`cbfsdisk` is your SPI flash and coreboot binary file itself.

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

    If the content of above command is exactly the same as your `test-file.txt`,
    then it means that **GRUB supports LZMA decompression of CBFS file**

## TPM event log

Recently, we had possibility to verify firmware by analyzing PCRs values.
However, there is still lack of information about TPM operations itself. User
doesn't have any details about measurements which were done (hashes of every
measured component). Without them, it is hard to make an attestation and fully
trust that firmware is not malicious. As we see this deficiency, we introduced
**TPM event log**. Idea is very simple. Every event related to TPM is
registered. It means that every operation done by TPM is memorized and can be
accessed by user at any time. Most interesting parts are of course **hashes of
every firmware component**. With this knowledge and details about PCR extension
process (extension order mostly) user has tool to analyze PCRs and, if there is
a need, verify against corruption. All you have to do is to make your own
calculations and see if every step is exactly as TPM event log reports.

As you can see, it is a great security feature because now user has possibility
to attest TPM. In case of calculations incompatibility, it also allows to easily
track corrupted part of firmware. Now, when you know what is TPM event log and
we believe you see its great benefit, let's see how it works and how to use it.

### TPM event log verification

Hardware and firmware specification which we are using for test:

- PC Engines apu2 platform with TPM2.0 or TPM1.2
- coreboot v4.12.0.2
- NixOS operating system

>We don't ensure valid test results if you don't have exactly the same
configuration and environment as above.

Following procedure will guide you step-by-step how to enable and read TPM event
log. Before giving final example, you need to prepare all necessary components.

1. Install `xxd` tool.

    > This tool will be used during `landing-zone` build, so it must be done
    earlier.

    ```
    $ cd ~/nixpkgs
    $ nix-build -A unixtools.xxd
    (...)
    /nix/store/2q94zc1agpkvchxxnx6pwy1v6rpdqzdx-xxd-1003.1-2008
    ```

    Last line points to directory where package is installed. Copy `/bin/xxd`
    file to one of the `PATH` directory.

    ```
    $ echo $PATH
    /run/wrappers/bin:/root/.nix-profile/bin:/etc/profiles/per-user/root/bin:/nix/var/nix/profiles/default/bin
    $ cp /nix/store/2q94zc1agpkvchxxnx6pwy1v6rpdqzdx-xxd-1003.1-2008/bin/xxd /run/wrappers/bin/
    ```

    > Adding `xxd` binary to PATH is necessary, so landing-zone compilation
    process will end successfully.

2. Update `nixpkgs` repository.

    It is assumed that you have already downloaded custom
    [3mdeb/nixpkg](https://github.com/3mdeb/nixpkgs) repository to your NixOS.
    If yes, then go to `nixpkgs` directory and pull latest changes.

    ```
    $ cd ~/nixpkgs
    $ git pull
    ```

    Change branch to `tpm_event_log`

    ```
    $ git checkout tpm_event_log
    ```

3. Rebuild NixOS.

    ```
    $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
    $ reboot
    ```

    There are changes in `grub-tb` and `landing-zone` packages. Moreover there
    is new package `cbmem-tb` added. It contains `cbmem` utility, which is a
    tool for gathering early logs. It lets reading TPM event logs from OS level.

4. Replace `/boot/lz_header` with just built new one.

    ```
    $ cd /nix/store
    $ ls | grep -i 'landing-zone-0.6.0'
    bqi0phr2rvwqlzfr3qj5117arxjhlbil-landing-zone-0.6.0
    nw8rsi5jfx9zikv06dhjxc6a5219xr20-landing-zone-0.6.0.drv
    ```

    >`landing-zone-0.6.0` without any extension is directory you looking for.

    ```
    $ cp /nix/store/bqi0phr2rvwqlzfr3qj5117arxjhlbil-landing-zone-0.6.0/lz_header.bin /boot/lz_header
    ```

5. Reboot platform and boot to NixOS Secure Launch.

6. Install `cbmem-tb` package manually.

    ```
    $ cd ~/nixpkgs
    $ nix-build -A cbmem-tb
    (...)
    /nix/store/8y25mfqw0igqa5yfpvrks0nvr5wah5kn-cbmem-4.12
    ```

7. Copy `cbmem` utility to home directory.

    ```
    $ cd /nix/store/
    $ ls | grep -i 'cbmem-4.12'
    8y25mfqw0igqa5yfpvrks0nvr5wah5kn-cbmem-4.12
    b4pds6l5fbkxdykkf2248c4mfnhf5ll5-cbmem-4.12.drv
    plm3jyg54hjyiy3zldclx83k14i34lpq-cbmem-4.12.drv
    pzifnqhgk0xarm3xrgkn07s9l572aw5p-cbmem-4.12.lock
    ```

    Search for entry with `cbmem-4.12` without any extension. In above case
    `cbmem` is installed in
    `/nix/store/8y25mfqw0igqa5yfpvrks0nvr5wah5kn-cbmem-4.12` directory.

    ```
    $ cp /nix/store/8y25mfqw0igqa5yfpvrks0nvr5wah5kn-cbmem-4.12/sbin/cbmem ~/
    ```

7. Go to home directory and use `cbmem` to read TPM event log.

    ```
    $ cd ~
    $ ./cbmem -d
    DRTM TPM2 log:
        Specification: 2.00     Platform class: PC Client
        No vendor information provided
    DRTM TPM2 log entry 1:
        PCR: 17
        Event type: Unknown (0x600)
        Digests:                 SHA1: 2400e5bdfbaa8cfc42eae13d9b742b89d0ba35b4
                 SHA256: b65067767baf988b18e3a83410f90f055a4dcd59509b1ab6b17e18926ad8de82
        Event data not provided
    DRTM TPM2 log entry 2:
        PCR: 17
        Event type: Unknown (0x601)
        Digests:                 SHA1: ecad3658a0cda535a8db50c207d726d2dac46509
                 SHA256: f76f571cb78beddba64ceab81b679ab3328ec15e2c4ff49f9fff625c300dc5a1
        Event data: Kernel
    ```

    > `-d` flag means 'print DRTM TPM log'. For more information about cbmem
    usage, type `cbmem --help`.

    Above logs are collected on platform with TPM2.0. Below there is example for
    platform with TPM1.2.

    ```
    $ cd ~
    $ ./cbmem -d
    DRTM TCPA log:
            Specification: 1.21     Platform class: PC Client
            No vendor information provided
    DRTM TCPA log entry 1:
            PCR: 17
            Event type: Unknown (0x600)
            Digest: 2400e5bdfbaa8cfc42eae13d9b742b89d0ba35b4
            Event data not provided
    DRTM TCPA log entry 2:
            PCR: 17
            Event type: Unknown (0x601)
            Digest: ecad3658a0cda535a8db50c207d726d2dac46509
            Event data: Kernel
    ```

As you can see output for platform with TPM1.2 is slightly different than with
TPM2.0. This is due to different TPM specification requirements about TPM1.2
event log and TPM2.0 event log. However, both are showing events and hashes
which extend PCR 17. For now, there is lack of support for TPM event log in
Linux kernel. Therefore, final values **are not the same** as those read with
tpm_tools. We are going to add this feature in near future, so TPM event log
will be complete and will be suitable for real-case use.

8. Compare `DRTM TPM2 log entry 1` with `LZ hash`.

    `DRTM TPM log entry 1` is hash of Landing Zone. Let's verify it against real
    value. Hexdump `/boot/lz_header` with `xxd` tool. Assuming `xxd` is added to
    PATH:

    ```
    $ xxd /boot/lz_header | tail
    00009ff0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
    0000a000: 78f1 268e 0492 11e9 832a c85b 76c4 cc02  x.&......*.[v...
    0000a010: 0000 0000 0000 0000 0000 0000 0000 0000  ................
    0000a020: 0000 0000 0000 0000 0000 0000 0000 0000  ................
    0000a030: 0000 0000 0200 0000 0400 2400 e5bd fbaa  ..........$.....
    0000a040: 8cfc 42ea e13d 9b74 2b89 d0ba 35b4 0b00  ..B..=.t+...5...
    0000a050: b650 6776 7baf 988b 18e3 a834 10f9 0f05  .Pgv{......4....
    0000a060: 5a4d cd59 509b 1ab6 b17e 1892 6ad8 de82  ZM.YP....~..j...
    0000a070: 0400 0000 1000 0000 0500 0000 474e 5500  ............GNU.
    0000a080: 0100 00c0 0400 0000 0100 0000 0000 0000  ................
    ```

    Starting from `0000a050` offset, there is SHA256 value:
    `b650 6776 7baf 988b 18e3 a834 10f9 0f05 5a4d cd59 509b 1ab6 b17e 1892 6ad8 de82`
    This value is exactly the same as *`DRTM TPM2 log entry 1* shows. It proves
    that TPM event log works correct.

## Summary

As you can see, in this release we mainly focus on TrenchBoot's components
adaptation to suit further requirements. First of all, we have made big step for
integration TrenchBoot into coreboot. We introduced changes in GRUB, so it would
operate on CBFS files and treat with LZMA. Second of all, we added *TPM event
logs* which further allow users to attest their platform on their own. Briefly
speaking, although presented features seem to be not very useful now, they will
definitely be crucial in TrenchBoot project development.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

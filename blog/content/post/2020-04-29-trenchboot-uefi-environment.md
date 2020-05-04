---
title: Installing Trenchboot in UEFI environments
abstract: This blog post will show you how to install NixOS on UEFI platforms
          and how to install Trenchboot on them.
          
cover: /covers/trenchboot-logo.png
author: michal.zygowski
layout: post
published: true
date: 2020-04-29
archives: "2020"

tags:
  - firmware
  - security
  - open-source
categories:
  - Firmware
  - OS Dev
  - Security

---

If you haven't read previous blog posts about TrenchBoot project, I encourage
to do so. We have presented our motivation, project's overview concept and
goals there. If you want to keep up with project development, stay tuned and
always try to catch up missed articles.

> Those articles will not always be strictly technical. Therefore, if you think
some topics should be elaborated, feel free to ask us a question.

In this article, I will explain how to install the NixOS on machines with UEFI
firmware and hwo to install TrenchBoot. The most essential parts of system will
be also described in details. It's important to understand their role, so you
will be able to reproduce the environment smoothly and consciously.

## Testing platform

As you already know, our solution is built for AMD processors. Therefore, for
tests we use suitable platforms. Our hardware infrastructure is still being
expanded. Eventually, there will be few more devices with different
characteristic. For this particular article, we use **Supermicro Super Server**
** M11SDV-4C** which has **AMD EPYC 3151** processor. We use connection via
serial port, so every relevant output will be presented in form of logs. What
is important, our platform is equipped with **TPM** module which is obligatory
in this project. Make sure you have it on your platform too.

## Operating system

To better understand next section, first I will introduce operating system which
we use. Our choice is [NixOS](https://nixos.org/nixos/) which is a Linux
distribution based on unusual (but reliable) package management. You can install
tools from official packages or build your own ones. Second feature will be
strongly utilized in entire project.

> Of course, you can use any other Linux distribution. However, every procedure
will be carried out by us in NixOS. If you won't have all dedicated tools and
(supported? compatible?) configuration, we can't provide full reliability.

#### NixOS installation

Now, I will guide through installation of NixOS. After it, you should have
an operating system in a default configuration. Later, I will show you how to
customize it in a runtime.

>Important: NixOS installation is not interactive as in most Linux distributions
(e.g. Debian). Therefore, pay attention to typed commands and configurations!

1. Download minimal installer image from the [website](https://nixos.org/nixos/download.html).

2. Flash USB drive with the image.

3. Insert USB drive on the target platform and choose proper boot option.

4. In boot menu press `tab` and add serial console parameters:

    ```bash
    console=ttyS0,115200 earlyprintk=serial,ttyS0,115200
    ```

5. Press enter and you will see following bootlog:

    ```bash
    ott//iinniittrrdd

    early console in extract_kernel
    input_data: 0x00000000023fc3b1
    input_len: 0x0000000000404c90
    output: 0x0000000001000000
    output_len: 0x00000000017d8030
    kernel_total_size: 0x000000000142c000
    trampoline_32bit: 0x000000000009d000
    booted via startup_32()
    Physical KASLR using RDTSC...
    Virtual KASLR using RDTSC...

    Decompressing Linux... Parsing ELF... Performing relocations... done.
    Booting the kernel.
    [    0.000000] Linux version 4.19.107 (nixbld@localhost) (gcc version 8.3.0 (GCC)) #1-NixOS SMP Fri Feb 28 15:39:01 UTC 2020
    [    0.000000] Command line: BOOT_IMAGE=/boot/bzImage init=/nix/store/ph9hjng3mwwsnnd20pq364fay8baqm6x-nixos-system-nixos-19.09.2201.7d31bbceaa1/init root=LABEL=NIXOS_ISO console=ttyS0,115200 earlyprintkd
    (...)

    <<< NixOS Stage 1 >>>

    loading module loop...
    loading module vfat...
    loading module nls_cp437...
    loading module nls_iso8859-1...
    loading module fuse...
    loading module dm_mod...
    running udev...
    kbd_mode: KDSKBMODE: Inappropriate ioctl for device
    Gstarting device mapper and LVM...
    mounting tmpfs on /...
    waiting for device /dev/root to appear...
    mounting /dev/root on /iso...
    mounting /mnt-root/iso/nix-store.squashfs on /nix/.ro-store...
    mounting tmpfs on /nix/.rw-store...
    mounting unionfs on /nix/store...

    <<< NixOS Stage 2 >>>

    running activation script...
    setting up /etc...
    unpacking the NixOS/Nixpkgs sources...
    created 1 symlinks in user environment
    ln: failed to create symbolic link '/root/.nix-defexpr/channels/channels': Read-only file system
    starting systemd...

    Welcome to NixOS 19.09.2201.7d31bbceaa1 (Loris)!

    [  OK  ] Created slice system-getty.slice.
    (...)
    [  OK  ] Started Login Service.


    <<< Welcome to NixOS 19.09.2201.7d31bbceaa1 (x86_64) - ttyS0 >>>
    The "nixos" and "root" accounts have empty passwords.

    Type `sudo systemctl start sshd` to start the SSH daemon.
    You then must set a password for either "root" or "nixos"
    with `passwd` to be able to login.


    Run `nixos-help` or press <Alt-F8> for the NixOS manual.

    nixos login: nixos (automatic login)
    ```

6. Create partitions for UEFI

    >Be careful and choose correct /dev/sdX device. In our case it is `sda`, which
    is SSD disk.

    Create a GPT partition table

    ```bash
    parted /dev/sda -- mklabel gpt
    ```

    Add the root partition. This will fill the the disk except for the end part,
    where the swap will live and spare 512MiB for boot partition.

    ```bash
    parted /dev/sda -- mkpart primary 512MiB -8GiB
    ```

    Add swap partition

    ```bash
    parted /dev/sda -- mkpart primary linux-swap -8GiB 100%
    ```

    Add EFI System Partition (ESP)

    ```bash
    parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
    parted /dev/sda -- set 3 boot on
    ```

7. Format partitions

    sda1

    ```bash
    mkfs.ext4 -L nixos /dev/sda1
    ```

    sda2 (swap)

    ```bash
    mkswap -L swap /dev/sda2
    ```

    sda3 (ESP)
    ```bash
    mkfs.fat -F 32 -n boot /dev/sda3
    ```

8. Mount partitions

    ```bash
    mount /dev/disk/by-label/nixos /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot
    ```

9. Generate initial configuration:

    ```bash
    nixos-generate-config --root /mnt
    ```

    >Above command will create `configuration.nix` file. It contains all default
    configuration options according to which NixOS will be installed.

10. Change the bootloader settings in `configuration.nix` file.

    ```bash
    boot.loader.systemd-boot = {
      enable = true;
      editor = false;
    };
    boot.loader.efi = {
      canTouchEfiVariables = true;
    };
    boot.loader.grub = {
      enable = true;
      copyKernels = true;
      efiInstallAsRemovable = false;
      efiSupport = true;
      fsIdentifier = "uuid";
      splashMode = "stretch";
      version = 2;
      device = "nodev";
      extraEntries = ''
        menuentry "Reboot" {
          reboot
        }
        menuentry "Poweroff" {
          halt
        }
      '';
    };
    ```

11. Add boot kernel parameters for serial connection:

    ```bash
    boot.kernelParams = [ "console=ttyS0,115200 earlyprintk=serial,ttyS0,115200" ];
    ```

12. Install NixOS based on config (it will take a few minutes)

    ```bash
    nixos-install
    ```

13. Set password for root.

14. Reboot OS. (Now you can remove installation media)

If above procedure was successful, NixOS is installed in default configuration.
Boot to system and play around to check if everything is correct. If yes, let's
move on to TrenchBoot installation.

# TrenchBoot installation

1. Install `cachix`

    `cachix` is binary cache hosting. It allows to store binary files, so there
    is no need to build them on your own. If it is not very useful for small
    builds, it is very handy for large ones e.g. Linux kernel binary.

    ```bash
    $ nix-env -iA cachix -f https://cachix.org/api/v1/install
    ```

2. Add 3mdeb cachix hosting as default.

    ```bash
    $ cachix use 3mdeb
    Cachix configuration written to /etc/nixos/cachix.nix.
    Binary cache 3mdeb configuration written to /etc/nixos/cachix/3mdeb.nix.

    To start using cachix add the following to your /etc/nixos/configuration.nix:

        imports = [ ./cachix.nix ];

    Then run:

        $ sudo nixos-rebuild switch
    ```

3. Meet above requirement by editing `/etc/nixos/configuration.nix`.

    > Probably vim editor is not available at this stage. Instead of vim, you
    can use nano.

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

4. Install git package.

    ```bash
    $ nix-env -iA nixos.git
    ```

5. Clone [3mdeb/nixpkgs](https://github.com/3mdeb/nixpkgs/tree/trenchboot_support_2020.04)
   repository.

    `3mdeb nixpkgs` contains additional packages compared with default NixOS
    `nixpkgs`, so everything is in one place. Most of all, there are:

    - [grub-tb](https://github.com/3mdeb/grub2/tree/trenchboot_support) -
      custom GRUB2 with `slaunch` module enabled;
    - [landing-zone](https://github.com/TrenchBoot/landing-zone.git) - LZ
      without debug flag
    - [landing-zone-debug](https://github.com/TrenchBoot/landing-zone.git) - LZ
      with debug
    - [linux-5.5](https://github.com/TrenchBoot/linux/tree/linux-sl-5.5) -
      custom Linux kernel with initrd

    ```bash
    $ git clone https://github.com/3mdeb/nixpkgs.git -b trenchboot_support_2020.04
    (...)
    $ ls
    nixpkgs
    ```

6. Update (rebuild) NixOS.

    ```
    $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
    ```

    > IMPORTANT: `-I nixpkgs=~/nixpkgs` flag is needful here! It replaces
    default `nixpkgs` with previously downloaded one. Make sure the directory is
    valid (we have it in home (~)). If you follow our instruction step-by-step,
    you have it also there.

7. Reboot platform.

    > DRTM is not enabled yet! Boot to NixOS and finish configuration.

8. Clone [3mdeb/nixos-trenchboot-configs](https://github.com/3mdeb/nixos-trenchboot-configs.git)
   repository.

    This repository contains all necessary NixOS configuration files in
    ready-to-use form, so there is no need to edit them by hand at this moment.

    ```bash
    $ git clone https://github.com/3mdeb/nixos-trenchboot-configs.git
    ```

    List `nixos-trenchboot-configs` folder.

    ```bash
    $ cd nixos-trenchboot-configs/
    $ ls
    configuration-efi.nix  configuration.nix  linux-5.5.nix  MANUAL.md  nixpkgs  README.md  tb-config.nix
    ```

    Among listed files, most interesting one is `configuration.nix`. Customizing it
    saves time and work compared with tools and package manual installs. Manual work
    is good for small and fast builds. The more (and more significant) changes you
    want to do, the more efficient way is to re-build your NixOS system. That is
    done by editing `configuration.nix` file. As you already know, among others we
    want to rebuild Linux kernel, replace GRUB bootloader and install custom
    packages. That is why we decided to prepare new config and re-install NixOS.

    Let's take a closer look at its content. Entire file is rather large, so
    the output will be truncated and only essential parts/lines will be
    mentioned. In this post we will use `configuration-efi.nix` since we have
    installed the NixOS in UEFI mode.

    ```bash
    $ cat configuration-efi.nix

    (...)
    imports =
        [ # Include the results of the hardware scan.
          ./hardware-configuration.nix
          ./cachix.nix
          ./linux-5.5.nix
        ];

    boot.loader.systemd-boot = {
      enable = true;
      editor = false;
    };
    # Automatically add boot entry to UEFI boot order.
    boot.loader.efi = {
      canTouchEfiVariables = true;
    };
    boot.loader.grub = {
      enable = true;
      copyKernels = true;
      efiInstallAsRemovable = false;
      efiSupport = true;
      fsIdentifier = "uuid";
      splashMode = "stretch";
      version = 2;
      device = "nodev";
      extraEntries = ''
        menuentry "NixOS - Secure Launch" {
          --set=drive1 --fs-uuid 4881-6D27
          slaunch skinit
          slaunch_module ($drive1)/boot/lz_header
          linux ($drive1)/nix/store/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3/bzImage systemConfig=/nix/store/3adz0xnfnr71hrg84nyawg2rqxrva3x3-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/3adz0xnfnr71hrg84nyawg2rqxrva3x3-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 loglevel=4
          initrd ($drive1)/nix/store/7q64073svk689cvk36z78zj7y2ifgjdv-initrd-linux-5.5.3/initrd
        }
        menuentry "Reboot" {
          reboot      
        }
        menuentry "Poweroff" {
          halt
        }
      '';
    };
    boot.kernelParams = [ "console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0" ];

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
                                  pkgs.grub-tb-efi
                                  ];

    # Grub override
    nixpkgs.config.packageOverrides = pkgs: { grub2 = pkgs.grub-tb-efi; };

    ```

    Remarks:
      - we import `cachix` service and custom linux 5.5 kernel to be built;
      - adjust GRUB entries to boot `slaunch` and change directories of
        `bzImage` (Linux kernel) and `initrd` to custom ones;
      - add all necessary system packages (i.a. `landing-zone`,
        `landing-zone-debug` and `grub-tb-efi`);
      - override default GRUB package with custom one;

9. Copy all configuration files to `/etc/nixos/` directory.

    ```bash
    $ cp nixos-trenchboot-configs/*.nix /etc/nixos
    ```

10. Update (re-build) system.

    ```bash
    $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
    building Nix...
    building the system configuration...
    ```

11.   Ensure that `slaunch` module is present in `/boot/grub/i386-pc/`.

    ```bash
    $ ls /boot/grub/i386-pc | grep slaunch
    slaunch.mod
    ```

12.   Find Landing Zone package in `/nixos/store/`.

    ```bash
    $ ls /nix/store/ | grep landing-zone
    5q92f6l4s1jfbw5ygfr1sd4hlczjj6l2-landing-zone-0.3.0.drv
    6v15ikqsyqk5fs0jg1n6755dp1nr6cyc-landing-zone-debug-0.3.0.drv
    dnpqvb64jjr3x2kxx92wvdkvmah72h6m-landing-zone-debug-0.3.0
    zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0
    ```

    > Package without `-debug` in its name and without *.drv* extension is what
    we are looking for.

13.   Copy `lz_header.bin` to `/boot/` directory.

    ```bash
    $ cp /nix/store/zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0/lz_header.bin /boot/lz_header
    ```

14.   Check `/boot/grub/grub.cfg` file and its `NixOS - Default` menu entry.
Adjust `/etc/nixos/configuration.nix` and its `boot.loader.grub.extraEntries`
line to have exactly the same directories included.

    ```bash
    $ cat /boot/grub/grub.cfg
    (...)
    menuentry "NixOS - Default" {
    search --set=drive1 --fs-uuid 4881-6D27
      linux ($drive1)//kernels/01gwliiiv6k2cbk90fd7z8r5g5dvqpal-linux-5.4.28-bzImage systemConfig=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
      initrd ($drive1)//kernels/7r7l0689jckx04v0kdf4mlk307v4xw3m-initrd-linux-5.4.28-initrd
    }
    (...)
    ```

    With `grub.cfg` content as above `configuration.nix` must have
    `boot.loader.grub.extraEntries `line like this:

    ```bash
    $ cat /etc/nixos/configuration.nix
      (...)
      boot.loader.grub.extraEntries = ''
      menuentry "NixOS - Secure Launch" {
        search --set=drive1 --fs-uuid 4881-6D27
        slaunch skinit
        slaunch_module ($drive1)//lz_header
        linux ($drive2)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
        initrd ($drive2)/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
      }
    '';
    ```

    If there are differences in any of `search --set=drive1...`,
    `linux ($drive1)/nix/store...` lines, edit `configuration.nix` content and
     copy those lines from `grub.cfg` menuentry `"NixOS - Default"`. They must
     be exactly the same.

1.   Update system for the last time.

    ```bash
    $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
    ```

2.   Reboot platform.

During platform booting, in GRUB menu there should be at least `"NixOS -
Default"` and `"NixOS - Secure Launch"` entries. First entry boots platform
without DRTM. Second entry **executes DRTM**! Choose the second entry and see if
platform boots successfully. If yes, you have secure platform with DRTM enabled.

## Validation

You can still be suspicious, if it really works. And rightly so. In this
section, I will show you, how to verify each component of the system to make you
sure about its correctness. Also, I will present how we met first stage
project's requirement.

### GRUB

There are two ways to validate if GRUB will load `slaunch` module and hence run
SKINIT and LZ (DRTM).

##### Verify content of `grub.cfg` file.

```
$ cat /boot/grub/grub.cfg
menuentry "NixOS - Default" {
search --set=drive1 --fs-uuid 4881-6D27
  linux ($drive1)//kernels/01gwliiiv6k2cbk90fd7z8r5g5dvqpal-linux-5.4.28-bzImage systemConfig=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
  initrd ($drive1)//kernels/7r7l0689jckx04v0kdf4mlk307v4xw3m-initrd-linux-5.4.28-initrd
}

menuentry "NixOS - Secure Launch" {
  search --set=drive1 --fs-uuid 4881-6D27
  slaunch skinit
  slaunch_module ($drive1)//lz_header
  linux ($drive2)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
  initrd ($drive2)/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
}
```

In "NixOS - Secure Launch" entry there must be `slaunch skinit` entry and
`slaunch_module  ($drive1)//lz_header` which points to LZ.

##### Compare bootlog with DRTM and without DRTM

1. Reboot platform. In GRUB menu choose `"NixOS - Default"` entry (without
DRTM).

    Collect logs during boot to be able to verify them. Using `dmesg` command in
    NixOS doesn't work because it doesn't show pre-kernel stage logs! Correct
    bootlog is shown below.

    ```
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

2. Reboot platform once again. In GRUB menu choose `"NixOS - Secure Launch"`
entry.

    Once again, collect logs during boot to be able to verify them. Using `dmesg`
    command in NixOS doesn't work, as in previous case. Correct bootlog is shown
    below.

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

    **Verification**: As expected, before Linux kernel, there should be
    `slaunch` module executed. It proves that DRTM is enabled. There is no
    information about LZ execution because it is non-debug version.

### Landing Zone

Actually, there are few aspects which can be verified in LZ. We will focus on
those two:
- check if LZ utilizes SHA256 algorithm when using TPM2.0 module
- check if LZ debug option can be enabled

##### check if LZ utilizes SHA256 algorithm when using TPM2.0 module

1. If not already booted to `"NixOS - Secure Launch"`, reboot platform and boot
to NixOS via `"NixOS - Secure Launch"` entry in GRUB menu.

2. Run `tpm2_pcrread` command.

    ```
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

3. Run `extend_all.sh` script from `landing-zone` package.

    This script simulates what should be extended into PCR17 by SKINIT, LZ and
    kernel during platform booting. It extends both SHA256 and SHA1 values.
    However, expected result is valid only for SHA256 if used with TPM2.0
    device.

    To properly execute script, first find correct directory to `bzImage` and
    `initrd`. Best way to find exact directories is to see `"NixOS - Secure
    Launch"` entry in `/boot/grub/grub.cfg`:

    ```
    $ cat /boot/grub/grub.cfg
    (...)
    menuentry "NixOS - Secure Launch" {
      search --set=drive1 --fs-uuid 4881-6D27
      slaunch skinit
      slaunch_module ($drive1)//lz_header
      linux ($drive2)/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage systemConfig=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/faqjg310ldbmhd1j6rn0rpb022g2msv6-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
      initrd ($drive2)/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
    }
    (...)
    ```

    `/nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage` is directory
    to Linux kernel.
    `/nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd` is
    directory to initrd.

4. Go to `/nix/store/` and run below command:

    ```
    $ cd /nix/store
    $ ls | grep landing-zone
    5q92f6l4s1jfbw5ygfr1sd4hlczjj6l2-landing-zone-0.3.0.drv
    6v15ikqsyqk5fs0jg1n6755dp1nr6cyc-landing-zone-debug-0.3.0.drv
    dnpqvb64jjr3x2kxx92wvdkvmah72h6m-landing-zone-debug-0.3.0
    zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0
    ```

    > Hash before `-landing-zone-1.0` is dependent on built version and might be
    different in yours. Choose non-debug version from above results.

5. Go to `/nix/store/zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0`
directory.

    ```
    $ cd /nix/store/zpcf7yf1fjf9slz2sr2f6s3wl3ch1har-landing-zone-0.3.0
    ```

6. Execute `./extend_all.sh` script.

    Usage is `./extend_all.sh <directory-to-bzImage> <directory-to-initrd>`

    It must be executed inside directory containing currently used (debug or
    non-debug) version of `lz_header.bin`. You should already be in this
    directory after previous step. Directories to `bzImage` and `initrd` we
    found in step 3.

    ```
    ./extend_all.sh /nix/store/ymvcgas7b1bv76n35r19g4p142v4cr0b-linux-5.1.0/bzImage /nix/store/gyqhrgvapfhfqq8x1km3z9ipv7phcadq-initrd-linux-5.1.0/initrd
    d91e7f685bcae20f84308eafe46f02eea8fcc90c  SHA1
    7392be6cd449323115d11bbc97af4cb2adad25b9cf52d0861f87934feea7b03e  SHA256
    ```

    Compare SHA256 value with PCR17 content checked previously with
    `tpm2_pcrread` output. If DRTM is enabled and executes properly, they should
    be the same. It proves that LZ code utilizes SHA256 algorithm during
    measurements.

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

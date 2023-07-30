---
title: Installing TrenchBoot in UEFI environments
abstract: This blog post will show you how to install NixOS on UEFI platforms
          and how to install TrenchBoot on them.
cover: /covers/trenchboot-logo.png
author: michal.zygowski
layout: post
published: true
date: 2020-05-06
archives: "2020"

tags:
  - open-source
  - trenchboot
  - nixos
  - uefi
categories:
  - Firmware
  - OS Dev
  - Security

---

***UPDATE 18.01.2021: Step 14th of Trenchboot installation section has been
extended with more straightforward instructions how to create GRUB entry for
Secure Launch.***

If you haven't read previous blog posts about the TrenchBoot project, I
encourage you to do so by discovering the
[TrenchBoot](https://blog.3mdeb.com/tags/trenchboot/) tag. We have presented our
motivation, project's overview concept, and goals there. If you want to keep up
with project development, stay tuned, and always try to catch up with missed
articles.

> Those articles will not always be strictly technical. Therefore, if you think
> some topics should be elaborated, feel free to ask us a question.

In this article, I will explain how to install the NixOS on machines with UEFI
firmware and how to install TrenchBoot. The most essential parts of the system
will be also described in detail. It's important to understand their role, so
you will be able to reproduce the environment smoothly and consciously. For now
TrenchBoot focuses only on early launch (the initial launch of operating
system), but the late launch (relaunching the operating system with DRTM without
physical reboot) is also on the roadmap. Find out more about DRTM in the
[TCG DRTM Architecture specification](https://trustedcomputinggroup.org/wp-content/uploads/TCG_D-RTM_Architecture_v1-0_Published_06172013.pdf)

## Testing platform

As you already know, our solution is built for AMD processors. Therefore, for
tests, we use suitable platforms. Our hardware infrastructure is still being
expanded. Eventually, there will be a few more devices with different
characteristics. For this particular article, we use
[**Supermicro Super** **Server M11SDV-4C**](https://www.supermicro.com/en/products/motherboard/M11SDV-4C-LN4F)
which has **AMD EPYC 3151** processor. We use connection via serial port, so
every relevant output will be presented in the form of logs. What is important,
our platform is equipped with **TPM** module (aka dTPM) which is obligatory in
this project. Make sure you have it on your platform too.

## Operating system

To better understand the next section, first I will introduce an operating
system which we use. Our choice is [NixOS](https://nixos.org/nixos/) which is a
Linux distribution based on unusual (but reliable) package management. You can
install tools from official packages or build your ones. The second feature will
be strongly utilized in the entire project.

> Of course, you can use any other Linux distribution. However, every procedure
> will be carried out by us in NixOS. If you won't have all dedicated tools and
> (supported and/or compatible) configuration, we can't provide full
> reliability.

### NixOS installation

Now, I will guide through the installation of NixOS. After it, you should have
an operating system in a default configuration. Later, I will show you how to
customize it at runtime.

> Important: NixOS installation is not interactive as in most Linux
> distributions (e.g. Debian). Therefore, pay attention to typed commands and
> configurations!

1. Download a minimal installer image from the
   [website](https://nixos.org/nixos/download.html).

1. Flash USB drive with the image.

1. Insert the USB drive on the target platform and choose the proper boot
   option.

1. In the boot menu press `tab` and add serial console parameters:

   ```bash
   console=ttyS0,115200 earlyprintk=serial,ttyS0,115200
   ```

1. Press enter and you will see following boot log:

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
   with `passwd` to be able to log in.


   Run `nixos-help` or press <Alt-F8> for the NixOS manual.

   nixos login: nixos (automatic login)
   ```

1. Create partitions for UEFI

   > Be careful and choose the correct /dev/sdX device. In our case, it is
   > `sda`, which is SSD disk.

   Create a GPT partition table

   ```bash
   parted /dev/sda -- mklabel gpt
   ```

   Add the root partition. This will fill the disk except for the end part,
   where the swap will live and spare 512MiB for the boot partition.

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

1. Format partitions

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

1. Mount partitions

   ```bash
   mount /dev/disk/by-label/nixos /mnt
   mkdir -p /mnt/boot
   mount /dev/disk/by-label/boot /mnt/boot
   ```

1. Generate initial configuration:

   ```bash
   nixos-generate-config --root /mnt
   ```

   > Above command will create `configuration.nix` file. It contains all default
   > configuration options according to which NixOS will be installed.

1. Change the bootloader settings in `configuration.nix` file.

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

1. Add boot kernel parameters for serial connection:

   ```bash
   boot.kernelParams = [ "console=ttyS0,115200 earlyprintk=serial,ttyS0,115200" ];
   ```

1. Install NixOS based on config (it will take a few minutes)

   ```bash
   nixos-install
   ```

1. Set a password for root.

1. Reboot OS. (Now you can remove installation media)

If the above procedure was successful, NixOS is installed in the default
configuration. Boot to the system and play around to check if everything is
correct. If yes, let's move on to the TrenchBoot installation.

## TrenchBoot installation

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
   [3mdeb/nixpkgs](https://github.com/3mdeb/nixpkgs/tree/trenchboot_support_2020.04)
   repository.

   `3mdeb nixpkgs` contains additional packages compared with default NixOS
   `nixpkgs`, so everything is in one place. Most of all, there are:

   - [grub-tb](https://github.com/3mdeb/grub2/tree/trenchboot_support_efi) -
     custom GRUB2 with `slaunch` module enabled;
   - [landing-zone](https://github.com/TrenchBoot/landing-zone.git) - LZ without
     debug flag
   - [landing-zone-debug](https://github.com/TrenchBoot/landing-zone.git) - LZ
     with debug
   - [linux-5.5](https://github.com/TrenchBoot/linux/tree/linux-sl-5.5) - custom
     Linux kernel with initrd

   ```bash
   $ git clone https://github.com/3mdeb/nixpkgs.git -b trenchboot_support_2020.04
   (...)
   $ ls
   nixpkgs
   ```

1. Update (rebuild) NixOS.

   ```bash
   sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
   ```

   > IMPORTANT: `-I nixpkgs=~/nixpkgs` flag is necessary here! It replaces
   > default `nixpkgs` with previously downloaded ones. Make sure the directory
   > is valid (we have it in home (~)). If you follow our instruction
   > step-by-step, you have it also there.

1. Reboot platform.

   > DRTM is not enabled yet! Boot to NixOS and finish the configuration.

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
   configuration-efi.nix  configuration.nix  linux-5.5.nix  MANUAL.md  nixpkgs  README.md  tb-config.nix
   ```

   Among the listed files, the most interesting one is `configuration.nix`.
   Customizing it saves time and work compared with tools and package manual
   installs. Manual work is good for small and fast builds. The more (and more
   significant) changes you want to do, the more efficient way is to re-build
   your NixOS system. That is done by editing `configuration.nix` file. As you
   already know, among others we want to rebuild Linux kernel, replace GRUB
   bootloader and install custom packages. That is why we decided to prepare a
   new config and re-install NixOS.

   Let's take a closer look at its content. The entire file is rather large, so
   the output will be truncated and only essential parts/lines will be
   mentioned. In this post, we will use `configuration-efi.nix` since we have
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
         linux ($drive1)//kernels/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3-bzImage systemConfig=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
         initrd ($drive1)//kernels/k1x969q4mwj59hyq3hn2mcxck8s2410a-initrd-linux-5.5.3-initrd

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
   - adjust GRUB entries to boot `slaunch` and change directories of `bzImage`
     (Linux kernel) and `initrd` to custom ones;
   - add all necessary system packages (i.a. `landing-zone`,
     `landing-zone-debug` and `grub-tb-efi`);
   - override default GRUB package with custom one;

1. Copy all configuration files to `/etc/nixos/` directory and replace the
   configuration for EFI.

   ```bash
   cp nixos-trenchboot-configs/*.nix /etc/nixos
   cp nixos-trenchboot-configs/configuration-efi.nix /etc/nixos/configuration.nix
   ```

1. Update (re-build) system.

   ```bash
   $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
   building Nix...
   building the system configuration...
   ```

1. Ensure that `slaunch` module is present in `/boot/grub/i386-pc/` (or
   `/boot/grub/x86_64-efi/` on 64bit GRUB EFI installation).

   ```bash
   $ ls /boot/grub/x86_64-efi | grep slaunch
   slaunch.mod
   ```

1. Find the Landing Zone package in `/nix/store/`.

   ```bash
   $ ls /nix/store/ | grep landing-zone
   5a6kapnjxs8dj4jp49qagz1mw2r6hnr2-landing-zone-debug-0.3.0
   l1b2h84fdw8g0m9aygmv8g3nhbnw9kic-landing-zone-debug-0.3.0.drv
   lf763br9hm0ipp76k2p16iq75x3xpgrm-landing-zone-0.3.0
   mnbh5xahlbzmfa50r60y5z4lph9rd41k-landing-zone-0.3.0.drv
   ```

   > Package without `-debug` in its name and without _.drv_ extension is what
   > we are looking for.

1. Copy `lz_header.bin` to `/boot/` directory.

   ```bash
   cp /nix/store/lf763br9hm0ipp76k2p16iq75x3xpgrm-landing-zone-0.3.0/lz_header.bin /boot/lz_header
   ```

1. Check `/boot/grub/grub.cfg` file and its `NixOS - Default` menu entry. Adjust
   `/etc/nixos/configuration.nix` and its `boot.loader.grub.extraEntries` line
   to have exactly the same directories included.

   ```bash
   $ cat /boot/grub/grub.cfg
   (...)
   menuentry "NixOS - Default" {
   search --set=drive1 --fs-uuid 4881-6D27
       linux ($drive1)//kernels/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3-bzImage systemConfig=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
       initrd ($drive1)//kernels/k1x969q4mwj59hyq3hn2mcxck8s2410a-initrd-linux-5.5.3-initrd
   }
   (...)
   ```

   > The hashes in the `/nix/store` or `/kernels` may be different for your
   > installation, especially initrd, that is why you should copy them from the
   > `NixOS - Default` entry and apply to a new entry shown below.

   Just copy the `Default` entry, rename it to `Secure Launch` and add two lines
   before `linux` command:

   ```bash
   slaunch skinit
   slaunch_module ($drive1)//lz_header
   ```

   With `grub.cfg` content as above `configuration.nix` must have
   `boot.loader.grub.extraEntries` line like this:

   ```bash
   $ cat /etc/nixos/configuration.nix
     (...)
     boot.loader.grub.extraEntries = ''
     menuentry "NixOS - Secure Launch" {
       search --set=drive1 --fs-uuid 4881-6D27
       slaunch skinit
       slaunch_module ($drive1)//lz_header
       linux ($drive1)//kernels/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3-bzImage systemConfig=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
       initrd ($drive1)//kernels/k1x969q4mwj59hyq3hn2mcxck8s2410a-initrd-linux-5.5.3-initrd
     }
   '';
   ```

   If there are differences in any of `search --set=drive1...`,
   `linux ($drive1)/nix/store...` or lines, edit `configuration.nix` content and
   copy those lines from `grub.cfg` menuentry `"NixOS - Default"`. They must be
   exactly the same.

1. Update the system for the last time.

   ```bash
   sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
   ```

1. Reboot platform.

During platform booting, in GRUB menu there should be at least
`"NixOS - Default"` and `"NixOS - Secure Launch"` entries. First entry boots
platform without DRTM. Second entry **executes DRTM**! Choose the second entry
and see if platform boots successfully. If yes, you have a secure platform with
DRTM enabled.

## Validation

You can still be suspicious if it really works. And rightly so. In this section,
I will show you, how to verify each component of the system to make you sure
about its correctness. Also, I will present how we met the second stage
project's requirements.

### GRUB

There are two ways to validate if GRUB will load `slaunch` module and hence run
SKINIT and LZ (DRTM).

#### Verify content of `grub.cfg` file

```bash
$ cat /boot/grub/grub.cfg
menuentry "NixOS - Default" {
search --set=drive1 --fs-uuid 4881-6D27
  linux ($drive1)//kernels/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3-bzImage systemConfig=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
  initrd ($drive1)//kernels/k1x969q4mwj59hyq3hn2mcxck8s2410a-initrd-linux-5.5.3-initrd
}

menuentry "NixOS - Secure Launch" {
  search --set=drive1 --fs-uuid 4881-6D27
  slaunch skinit
  slaunch_module ($drive1)//lz_header
  linux ($drive1)//kernels/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3-bzImage systemConfig=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
  initrd ($drive1)//kernels/k1x969q4mwj59hyq3hn2mcxck8s2410a-initrd-linux-5.5.3-initrd
}
```

In "NixOS - Secure Launch" entry there must be `slaunch skinit` entry and
`slaunch_module ($drive1)//lz_header` which points to LZ.

##### Compare bootlog with DRTM and without DRTM

1. Reboot platform. In GRUB menu choose `"NixOS - Default"` entry (without
   DRTM).

   Collect logs during boot to be able to verify them. Using `dmesg` command in
   NixOS doesn't work because it doesn't show pre-kernel stage logs! The correct
   boot log is shown below.

   ```bash
   early console in extract_kernel
   input_data: 0x00000000041fd3b1
   input_len: 0x000000000045e254
   output: 0x0000000002c00000
   output_len: 0x0000000001a301c0
   kernel_total_size: 0x000000000182c000
   needed_size: 0x0000000001c00000
   trampoline_32bit: 0x000000000009d000
   booted via startup_32()
   Physical KASLR using RDRAND RDTSC...
   Virtual KASLR using RDRAND RDTSC...

   Decompressing Linux... Parsing ELF... Performing relocations... done.
   Booting the kernel.
   [    0.000000] Linux version 5.5.3 (nixbld@localhost) (gcc version 9.2.0 (GCC)) #1-NixOS SMP Thu Jan 1 00:00:01 UTC 1970
   (...)

   <<< Welcome to NixOS 20.09.git.c156a866dd7M (x86_64) - ttyS0 >>>

   Run 'nixos-help' for the NixOS manual.
   ```

   **Verification**: As expected, the bootloader executes Linux kernel directly.
   Platform booted without DRTM then.

1. Reboot platform once again. In GRUB menu choose `"NixOS - Secure Launch"`
   entry.

   Once again, collect logs during boot to be able to verify them. Using `dmesg`
   command in NixOS doesn't work, as in the previous case. The correct boot log
   is shown below.

   ```bash
   early console in extract_kernel
   input_data: 0x00000000041fd3b1
   input_len: 0x000000000045e254
   output: 0x0000000002c00000
   output_len: 0x0000000001a301c0
   kernel_total_size: 0x000000000182c000
   needed_size: 0x0000000001c00000
   trampoline_32bit: 0x000000000009d000
   booted via startup_32()
   Physical KASLR using RDRAND RDTSC...
   Virtual KASLR using RDRAND RDTSC...

   Decompressing Linux... Parsing ELF... Performing relocations... done.
   Booting the kernel.
   [    0.000000] Linux version 5.5.3 (nixbld@localhost) (gcc version 9.2.0 (GCC)) #1-NixOS SMP Thu Jan 1 00:00:01 UTC 1970
   [    0.000000] Command line: BOOT_IMAGE=(hd1,gpt3)//kernels/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3-bzImage systemConfig=/nix/store/bxjlwx3dcjg8jjvd6792fdjwnw1idgfg-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/bxjlwx3dcjg8jjvd6792fdjwnw1idgfg-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4

   (...)

   <<< Welcome to NixOS 20.09.git.a070e686875 (x86_64) - ttyS0 >>>

   Run 'nixos-help' for the NixOS manual.
   ```

   **Verification**: As expected, before the Linux kernel, there should be
   `slaunch` module executed. It proves that DRTM is enabled. There is no
   information about LZ execution because it is a non-debug version.

### Landing Zone

Actually, there are a few aspects that can be verified in LZ. We will focus on
those two:

- check if LZ utilizes the SHA256 algorithm when using TPM2.0 module
- check if LZ debug option can be enabled

#### check if LZ utilizes SHA256 algorithm when using TPM2.0 module

1. If not already booted to `"NixOS - Secure Launch"`, reboot platform, and boot
   to NixOS via `"NixOS - Secure Launch"` entry in GRUB menu.

1. Run `tpm2_pcrread` command.

   ```bash
   $ tpm2_pcrread
   sha1:
     0 : 0x122896C747F64CE4E9081BBF36513BB26C7D7841
     1 : 0xFF0B4D5E2B550AB4C56E27C69DEF49AA933B9722
     2 : 0xB2A83B0EBF2F8374299A5B2BDFC31EA955AD7236
     3 : 0xB2A83B0EBF2F8374299A5B2BDFC31EA955AD7236
     4 : 0x8E15F45C1AC99950850949C3D2D425B8A59EE2AC
     5 : 0x81DCF5ED6034C0BE3F992869AD1F78BA713A8548
     6 : 0xB2A83B0EBF2F8374299A5B2BDFC31EA955AD7236
     7 : 0x4037336FA7BC0EABE3778FCFFF5FCD0EE6ADCDE3
     8 : 0x0000000000000000000000000000000000000000
     9 : 0x0000000000000000000000000000000000000000
     10: 0x0000000000000000000000000000000000000000
     11: 0x0000000000000000000000000000000000000000
     12: 0x0000000000000000000000000000000000000000
     13: 0x0000000000000000000000000000000000000000
     14: 0x0000000000000000000000000000000000000000
     15: 0x0000000000000000000000000000000000000000
     16: 0x0000000000000000000000000000000000000000
     17: 0x00883227E275C12E1FAD0024133C1F71D8BA699A
     18: 0x0000000000000000000000000000000000000000
     19: 0x0000000000000000000000000000000000000000
     20: 0x0000000000000000000000000000000000000000
     21: 0x0000000000000000000000000000000000000000
     22: 0x0000000000000000000000000000000000000000
     23: 0x0000000000000000000000000000000000000000
   sha256:
     0 : 0xF831C72F6C06F0196169E9B13F76B93B01316761142C98E2BF7AF2B069970A03
     1 : 0xFFE279C00FAC3B552E88E24EF5CB6D456DB19CE13D9F8A8EB848E94E01791347
     2 : 0x3D458CFE55CC03EA1F443F1562BEEC8DF51C75E14A9FCF9A7234A13F198E7969
     3 : 0x3D458CFE55CC03EA1F443F1562BEEC8DF51C75E14A9FCF9A7234A13F198E7969
     4 : 0x5155731E9498F6BA0AF9CBFA785AE5C107809745C51FB98ED01DF1E283FE25CD
     5 : 0x701DC6CA7B80B2C6BC2E563ED34BD06E8ABDE913A7E69C56D0BB2323D65C7371
     6 : 0x3D458CFE55CC03EA1F443F1562BEEC8DF51C75E14A9FCF9A7234A13F198E7969
     7 : 0xB5710BF57D25623E4019027DA116821FA99F5C81E9E38B87671CC574F9281439
     8 : 0x0000000000000000000000000000000000000000000000000000000000000000
     9 : 0x0000000000000000000000000000000000000000000000000000000000000000
     10: 0x0000000000000000000000000000000000000000000000000000000000000000
     11: 0x0000000000000000000000000000000000000000000000000000000000000000
     12: 0x0000000000000000000000000000000000000000000000000000000000000000
     13: 0x0000000000000000000000000000000000000000000000000000000000000000
     14: 0x0000000000000000000000000000000000000000000000000000000000000000
     15: 0x0000000000000000000000000000000000000000000000000000000000000000
     16: 0x0000000000000000000000000000000000000000000000000000000000000000
     17: 0x21D3D024420A4149A3A226D39331A3A69E434200EE2D1C56FB02F3B982DC97B2
     18: 0xF60CE5BD1FBA080302211F6FAD660374B82DE4AEC102369764E411461C7B71E6
     19: 0x0000000000000000000000000000000000000000000000000000000000000000
     20: 0x0000000000000000000000000000000000000000000000000000000000000000
     21: 0x0000000000000000000000000000000000000000000000000000000000000000
     22: 0x0000000000000000000000000000000000000000000000000000000000000000
     23: 0x0000000000000000000000000000000000000000000000000000000000000000
   ```

1. Run `extend_all.sh` script from `landing-zone` package.

   This script simulates what should be extended into PCR17 by SKINIT, LZ and
   kernel during platform booting. It extends both SHA256 and SHA1 values.
   However, the expected result is valid only for SHA256 if used with TPM2.0
   device.

   To properly execute script, first find correct directory to `bzImage` and
   `initrd`. Best way to find exact directories is to see
   `"NixOS - Secure  Launch"` entry in `/boot/grub/grub.cfg`:

   ```bash
   $ cat /boot/grub/grub.cfg
   (...)
   menuentry "NixOS - Secure Launch" {
     search --set=drive1 --fs-uuid 4881-6D27
     slaunch skinit
     slaunch_module ($drive1)//lz_header
     linux ($drive1)//kernels/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3-bzImage systemConfig=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M init=/nix/store/ci38is4cvjlz528jay66h7qpqr6ws22n-nixos-system-nixos-20.09.git.c156a866dd7M/init console=ttyS0,115200 earlyprintk=serial,ttyS0,115200 console=tty0 loglevel=4
     initrd ($drive1)//kernels/k1x969q4mwj59hyq3hn2mcxck8s2410a-initrd-linux-5.5.3-initrd
   }
   (...)
   ```

   `/nix/store/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3/bzImage` is
   directory to Linux kernel.
   `/nix/store/k1x969q4mwj59hyq3hn2mcxck8s2410a-initrd-linux-5.5.3/initrd` is
   directory to initrd.

1. Go to `/nix/store/` and run below command:

   ```bash
   $ cd /nix/store
   $ ls | grep landing-zone
   5a6kapnjxs8dj4jp49qagz1mw2r6hnr2-landing-zone-debug-0.3.0
   l1b2h84fdw8g0m9aygmv8g3nhbnw9kic-landing-zone-debug-0.3.0.drv
   lf763br9hm0ipp76k2p16iq75x3xpgrm-landing-zone-0.3.0
   mnbh5xahlbzmfa50r60y5z4lph9rd41k-landing-zone-0.3.0.drv
   ```

   > Hash before `-landing-zone-0.3.0` is dependent on built version and might
   > be different in yours. Choose non-debug version from above results.

1. Go to `/nix/store/lf763br9hm0ipp76k2p16iq75x3xpgrm-landing-zone-0.3.0`
   directory.

   ```bash
   cd /nix/store/lf763br9hm0ipp76k2p16iq75x3xpgrm-landing-zone-0.3.0
   ```

1. Execute `./extend_all.sh` script.

   Usage is `./extend_all.sh <directory-to-bzImage> <directory-to-initrd>`

   It must be executed inside the directory containing currently used (debug or
   non-debug) version of `lz_header.bin`. You should already be in this
   directory after the previous step. Directories to `bzImage` and `initrd` we
   found in step 3.

   ```bash
   ./extend_all.sh /nix/store/3w98shnz1a6nxpqn2wwn728mr12dy3kz-linux-5.5.3/bzImage /nix/store/k1x969q4mwj59hyq3hn2mcxck8s2410a-initrd-linux-5.5.3/initrd
   ff4562570be624792d7cc1ae8dcb8a2c9d978cfd  SHA1
   21d3d024420a4149a3a226d39331a3a69e434200ee2d1c56fb02f3b982dc97b2  SHA256
   ```

   Compare SHA256 value with PCR17 content checked previously with
   `tpm2_pcrread` output. If DRTM is enabled and executes properly, they should
   be the same. It proves that the LZ code utilizes the SHA256 algorithm during
   measurements.

## Summary

As we mentioned earlier, we are introducing new platforms according to the
project's development. Moreover, in this blog post, we have shown how to enable
DRTM in the UEFI environment as well. It proves that this solution is not only
dedicated to a narrow group of devices, but can be a common tool for many more.
Therefore, keep following our work and project's progress and feel free to
experiment with your hardware too!

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of the used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

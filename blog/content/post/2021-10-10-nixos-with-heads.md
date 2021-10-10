---
title: Installing NixOS with heads firmware on ThinkPad X230
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: maciej.pijanowski
layout: post
published: true
date: 2021-10-10
archives: "2021"

tags:
  - heads
  - NixOS
categories:
  - Firmware
  - OS Dev
  - Security

---

Your post content

> post abstract in the header is required for the posts summary in the blog list
  and must contain from 3 to 5 sentences, please note that abstract would be used
  for social media and because of that should be focused on keywords/hashtags

> post cover image should be located in `blog/static/covers/` directory or may be
  linked to `blog/static/img/` if image is used in post content

> copy all post images to `blog/static/img` directory. Example usage:

![alt-text](/img/file-name.jpg)

> example usage of asciinema videos:

[![asciicast](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO.svg)](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO?speed=1)

> embed Twitter post (you need the `URL` of the tweet):

{{< tweet 1247072310324080640 >}}

> or centered (temporary hack):

<div style="display:table;margin:auto">{{< tweet 1247072310324080640 >}}</div>

## Introduction

From time to time I've been looking for the X230 ThinkPads available in the
local market. I was looking specifically for the model with the best available
CPU - [i7-3520m](https://ark.intel.com/content/www/pl/pl/ark/products/64893/intel-core-i7-3520m-processor-4m-cache-up-to-3-60-ghz.html).
Once I've spotted one in decent visual condition and good price (\<$200), I've
decided to get one for some experiments.

At 3mdeb, we've used the [heads](https://github.com/osresearch/heads) in our
projects a few times already. For example, we have been developing
[fwupd support for QubesOS with heads](https://blog.3mdeb.com/2020/2020-09-18-qubes_fwupd_heads_uefi/).
But I have never used it on my personal device and always waited for a good
reason to try it out.

Another one I wanted to try out for some time, was the
[NixOS](https://nixos.org/). I always loved the idea of reproducible builds and
declarative definition of the whole OS. We have used the NixOS already for some
projects (like the
[TrenchBoot one](https://blog.3mdeb.com/2020/2020-05-06-trenchboot-uefi-environment/))
but I wanted to see how it would work for a daily workstation.

The last piece of the puzzle was the
[tiling window manager](https://en.wikipedia.org/wiki/Tiling_window_manager).
I've always liked the idea of controlling the PC with keyboard as much as
possible (using VIM keybindings wherever possible). Interstingly, I was stick
with the default WM, and never bothered to try the tiling one. Most of them
(including the famous [i3](https://i3wm.org/) run on the X11). I chose
[sway](https://swaywm.org/) instead, which is the most active tiling WM for
[Wayland](https://wayland.freedesktop.org/). The great synergy here was that
the [NixOS is one of the most popular OS among sway users](https://www.reddit.com/r/swaywm/comments/gh4dfa/what_distro_are_you_using_for_sway/)
and (as we will later see) quite easy to setup here.

## Installing heads

### Building

Heads project has [great documentation](https://osresearch.net/Install-and-Configure)
leading you through the installation process. I will just briefly describe it
here, leaving references to heads documentation.

At first, you need to build the heads for your board. In this case you need to
build for the [Lenovo X230](https://osresearch.net/x230-building/). I have used
the [heads-docker](https://github.com/3mdeb/heads-docker) container to build
this project.

### Cleaning ME

What is ME and why would you like to clean it up (and how to do that) is
already described in the
[heads documentation](https://osresearch.net/Clean-the-ME-firmware/).

In my case I just skipped the EC firmware downgrade part (I had the most recent
one already installed). I am not interested with any keyboard mods, so I just
skipped this step as it seemed not necessary in my case.

### Installing

Installing heads for the first time requires some
[playing with hardware](https://twitter.com/macpijan/status/1403434697384988672).
You need to disassemble the laptop to get access to two of the flash chips,
which will be used for storing heads firmware. This excellent
[X230 flashing guide](https://osresearch.net/x230-flashing/) should walk you
through the process. The only difference in my case was the programmer. I have
not used the CH341A as suggested in the documentation. Instead, I have used the
[RTE](https://docs.dasharo.com/transparent-validation/rte/introduction/).It is
[Ceritified Open Source Hardware device](https://certification.oshwa.org/pl000003.html),
which we are using for our daily work. It is also available
[in our shop](https://3mdeb.com/shop/open-source-hardware/open-source-hardware-3mdeb/rte/).

![installing-heads](/img/heads_flashing.png)

### Configuring

Heads needs some initial configuration to be performed. To go through this
process, you should have one of the
[supported USB security dongles](https://osresearch.net/Prerequisites#usb-security-dongles-aka-security-token-aka-smartcard).
In my case I went with the
[Yubico YubiKey 5](https://www.yubico.com/products/yubikey-5-overview/).

I started configuration with generating new PGP key on the YubiKey. The process
is well-described in the
[heads documentation](https://osresearch.net/Configuring-Keys/#generating-your-pgp-key)
as well. This PGP key will be later used to sign the files in `/boot`
partition.

The second configuration step was to setup the
[tmtotp feature](https://osresearch.net/Configuring-Keys/#tpmtotp). It allows
you to conenct your firmware with authenticator app. On each boot you can verify
the TOTP code displayed by firmware with the one from app before booting
further. Here I can recommend [Aegis Authenticator](https://getaegis.app/),
which is an open-source alternative to the commonly used Google Authenticator.
It can be installed from the
[F-Droid](https://f-droid.org/en/packages/com.beemdevelopment.aegis/) as well.

TBD: photo

## Installing NixOS

### Obtaining NixOS

After the heads was installed and configured, I could proceed with NixOS
installation.

NixOS has excellent manual covering the most important subjects. The
installation process is quite different than in case of the typical Linux OS.
Certainly you will not experience GUI installer here. All of the partitioning
must be done manually, so some prior Linux command line experience is helpful.

We need to start with
[obtaining the NixOS](https://nixos.org/manual/nixos/stable/index.html#sec-obtaining).
I have selected the
[Minimal ISO image](https://channels.nixos.org/nixos-21.05/latest-nixos-minimal-x86_64-linux.iso),
rather than the graphical one. The reason for that was the graphical uses
either GNOME or Plasme Desktop, while I wanted to use neither of them.

### Booting NixOS installer

So at first I flashed the USB stick and
[booted from the USB](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb).
To boot from USB in HEADS, one must select the `Options --> Boot Options --> USB boot`
option.

![heads_usb_boot](/img/heads_usb_boot.png)

### Configuring networking

Once booted, we need to set up the networking, as it will be needed during the
installation process. The easy way is to plug in Ethernet cable. But the manual
describes how to set up the
[WiFi connection](https://nixos.org/manual/nixos/stable/index.html#sec-installation-booting-networking)
as well.

### Partitioning

Then we should move on the
[partitioning and formatting section](https://nixos.org/manual/nixos/stable/index.html#sec-installation-partitioning).
In our case, we will be interesed with the
[Legacy Boot (MBR)](https://nixos.org/manual/nixos/stable/index.html#sec-installation-partitioning-MBR),
as we do not have UEFI firmware.

The official documentation suggests here to create only two partitions: `root`
and `swap`. This will not work well in our case. Heads firmware verifies content
on the first (boot) partition on each boot. If it will cover the whole rootfs,
the whole process can take a lot of time and the signatures can be different
each time we reboot (as we probably make some changes in the rootfs).

So I decided to modify this and create a separate `boot` partition as well.

I started with creating 512 MB boot partition:

```bash
# fdisk /dev/sda

Welcome to fdisk (util-linux 2.36.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Command (m for help): o
Created a new DOS disklabel with disk identifier 0xeb0d5543.

Command (m for help): p
Disk /dev/sda: 167.68 GiB, 180045766656 bytes, 351651888 sectors
Disk model: INTEL SSDSC2BF18
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xeb0d5543

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1):
First sector (2048-351651887, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-351651887, default 351651887): +512M

Created a new partition 1 of type 'Linux' and of size 512 MiB.
Partition #1 contains a ext4 signature.

Do you want to remove the signature? [Y]es/[N]o: y

The signature will be removed by a write command.

Command (m for help): p
Disk /dev/sda: 167.68 GiB, 180045766656 bytes, 351651888 sectors
Disk model: INTEL SSDSC2BF18
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xeb0d5543

Device         Start       End   Sectors   Size Type
/dev/sda1        2048 1050623 1048576  512M 83 Linux

Filesystem/RAID signature on partition 1 will be wiped.

```

And then with secend partition, filling up the rest of the disk:

```bash
Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p):

Using default response p.
Partition number (2-4, default 2):
First sector (1050624-351651887, default 1050624):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (1050624-351651887, default 351651887):

Created a new partition 2 of type 'Linux' and of size 167.2 GiB.

Command (m for help): p
Disk /dev/sda: 167.68 GiB, 180045766656 bytes, 351651888 sectors
Disk model: INTEL SSDSC2BF18
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xeb0d5543

Device         Start       End   Sectors   Size Type
/dev/sda1          2048   1050623   1048576   512M 83 Linux
/dev/sda2       1050624 351651887 350601264 167.2G 83 Linux

Filesystem/RAID signature on partition 1 will be wiped.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

I also wanted to setup an encrypted volume on the second partititon. The main
NixOS manual does not present such setup. There are some information
[in the wiki](https://nixos.wiki/wiki/Full_Disk_Encryption), though.

It consists of the following steps.

1. Create LUKS volume on the second partition:

```bash
# cryptsetup luksFormat /dev/sda2

WARNING!
========
This will overwrite data on /dev/sda2 irrevocably.

Are you sure? (Type 'yes' in capital letters): YES
Enter passphrase for /dev/sda2:
Verify passphrase:
```

2. Open LUKS volume:

```bash
# cryptsetup luksOpen /dev/sda2 enc-pv
Enter passphrase for /dev/sda2:
```

3. Create LVM physical volume:

```bash
# pvcreate /dev/mapper/enc-pv
Physical volume "/dev/mapper/enc-pv" successfully created.
```

4. Create LVM `vg` group

```bash
# vgcreate vg /dev/mapper/enc-pv
Volume group "vg" successfully created
```

5. Create `swap` volume in the `vg` group:

```bash
# lvcreate -L 8G -n swap vg
Logical volume "swap" created.
```

6. Create `root` volume in the `vg` group:

```bash
# lvcreate -l '100%FREE' -n root vg
Logical volume "root" created.
```

7. Create FAT filesystem on the `boot` parititon

```bash
# mkfs.fat /dev/sda1
mkfs.fat 4.1 (2017-01-24)
```

8. Create ext4 filesystem on the `root` volume:

```bash
# mkfs.ext4 -L root /dev/vg/root
mke2fs 1.46.2 (28-Feb-2021)
Creating filesystem with 41722880 4k blocks and 10436608 inodes
Filesystem UUID: 6839a958-2b1b-4548-909a-e479a02cb800
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
	4096000, 7962624, 11239424, 20480000, 23887872

Allocating group tables:    0/1274 done
Writing inode tables:    0/1274 done
Creating journal (262144 blocks): done
Writing superblocks and filesystem accounting information:    0/1274 done
```

8. Create swap on the `swap` volume:

```
# mkswap -L swap /dev/vg/swap
Setting up swapspace version 1, size = 8 GiB (8589930496 bytes)
LABEL=swap, UUID=4c021582-f0a9-4348-9565-267fa8f3d1b1
```

### Proceeding with installation

Once we have the partitioning in place, we can proceed with the installation.
Before we start, we need to mount our partitions under `/mnt`:

```bash
# mount /dev/vg/root /mnt/
# mkdir /mnt/boot
# mount /dev/sda1 /mnt/boot
# swapon /dev/vg/swap
```

The actual installation process consists of two steps. The first one is to edit
the `/mnt/etc/nixos/configuration.nix` configuration file, which describes the
whole content and configuration of our system.

```bash
# nixos-generate-config  --root /mnt/
writing /mnt/etc/nixos/hardware-configuration.nix...

# vi /mnt/etc/nixos/hardware-configuration.nix
```

In my case, I have enabled Wayland, sway, and some applications for my sway
desktop environment:

```
  # Disable the X11 windowing system.
  services.xserver.enable = false;

  # Use Wayland with sway
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      swaylock # screen locker
      swayidle # idle management
      xwayland
      wl-clipboard
      mako # notoficatoins
      alacritty # terminal emulator
      sway-contrib.grimshot # screenshot
      wdisplays # displays configuration
      wob # volume/backlight bar
      wofi # launcher
      waybar # top bar
      oguri # wallpaper
      autotiling
      wlsunset
      lxsession
      udiskie
      zathura # PDF viewer
      imv # image viewer
    ];
  };
```

I also made some more configuration later on, but I can write more about that
some other time. The only configuration I want to mention here (as it directly
impacts the boot process) is the partitions configuration.

The `/mnt/etc/nixos/hardware-configuration.nix` was generated automatically
when running the `nixos-generate-config`, but it failed to correctly describe
my logical volumes. I could not find a way how to properly fix that. I could
not override the settings in the `configuration.nix`, as the `nixos-install`
would complain:

```bash
building the configuration in /mnt/etc/nixos/configuration.nix...
error The option `fileSystems./.device' has conflicting definition values:
- In `/mnt/etc/nixos/configuration.nix': "/dev/mapper/vg-root"
- In `/mnt/etc/nixos/hardware-configuration.nix': "/dev/disk/by-uuid/6839a958-2b1b-4548-909a-e479a02cb800"
(use '--show-trace' to show detailed location information)
```

I ended up with commenting out the parts in the `hardware-configuration.nix`:

```nix
# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # fileSystems."/" =
  #   { device = "/dev/disk/by-uuid/6839a958-2b1b-4548-909a-e479a02cb800";
  #     fsType = "ext4";
  #   };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/56D5-4720";
      fsType = "vfat";
    };

  # swapDevices =
  #   [ { device = "/dev/disk/by-uuid/4c021582-f0a9-4348-9565-267fa8f3d1b1"; }
  #   ];

}
```

And defining them in the `configuration.nix`:

```nix
# cryptestup configuration
boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/d0c94847-fabe-4bda-98fd-04dda65055fd"; # /dev/sda2 block device
fileSystems."/".device = "/dev/mapper/vg-root"; # root volume
swapDevices =
  [ { device = "/dev/mapper/vg-swap"; } # swap volume
  ];
```

With these configuration in place, I could run the installer:
```bash
# nixos-install

.....

copying channel...
installing the boot loader...
setting up /etc...

.....

All rules containing unresolvable specifiers will be skipped.
setting root password...
New password:
Retype new password:
```

After that, I should be able to `reboot` into newly installed NixOS.

### Booting NixOS

Unfortunately, booting NixOS with heads as a firmware fails. I have raised a
[GitHub issue](https://github.com/osresearch/heads/issues/1001) describing
this. The problem is that the `grub.cfg` produced by the NixOS is rather
complex. It uses
[GRUB environment variables](https://www.gnu.org/software/grub/manual/grub/html_node/Environment.html)
which heads fails to parse.

I had to modify the `kexec_default.1.txt` as described in
[this comment](https://github.com/osresearch/heads/issues/1001#issue-930741786).
This way, I can boot from the heads rescue shell manually, typing the following
command each time I want to boot NixOS:

```bash
# kexec-boot -b /boot -e "$(cat /boot/kexec_default.1.txt)"
```

![nixos_decrypt](/img/nixos_decrypt.png)

![nixos_login](/img/nixos_login.png)

![nixos_sway](/img/nixos_sway.png)

## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

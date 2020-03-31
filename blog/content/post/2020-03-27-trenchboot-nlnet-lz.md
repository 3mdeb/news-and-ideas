---
title: Open Source DRTM with TrenchBoot. Project's basics.
abstract: This is the first blog post of TrenchBoot series. It will introduce
          you to the project, its structure and environment. Additionally the
          reader will find out more about each component, how to setup the
          environment and configure the build.
cover: /covers/trenchboot-logo.png
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

If you haven't read [introductory blog post](link-to-introductory) yet, I
strongly recommend to do it before proceeding here. We have presented our
motivation, project's overview concept and goals there. Generally speaking, we
will be introducing new issues according to project's state over time. If you
want to keep up with project development, stay tuned and always try to catch up
missed articles.

> Those articles will not always be strictly technical. Therefore, if you think
some topics should be elaborated, feel free to ask us a question.

In this article, I will explain how the project is built. Mostly, what hardware,
firmware and software components we are using. The most essential parts of
system will be also described in details. It's important to understand their
role, so you will be able to reproduce the environment smoothly and consciously.

## Testing platform

As you already know, our solution is built for AMD processors. Therefore, for
tests we use suitable platforms. Our hardware infrastructure is still being
expanded. Eventually, there will be few more devices with different
characteristic. For now, we use **PC Engines apu2** which has **AMD GX-412TC**
processor. We use connection via serial port, so every relevant output will be
presented in form of logs. What is important, our platform is equipped with
**TPM** module which is obligatory in this project. Make sure you have it on
your platform too.

## Operating system

To better understand next section, first I will introduce operating system which
we use. Our choice is [NixOS](https://nixos.org/nixos/) which is a Linux
distribution based on unusual (but reliable) package management. You can install
tools from official packages or build your own ones. Second feature will be
strongly utilized in entire project. Later, I will show you how to build custom
package on `flashrom` example.

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

6. Create legacy boot partition

  >Be careful and choose correct /dev/sdX device. In our case it is `sda`, which
  is SSD disk.

  - Create a MBR partition table

  ```bash
  parted /dev/sda -- mklabel msdos
  ```
  - Add the root partition. This will fill the the disk except for the end part,
    where the swap will live.

  ```bash
  parted /dev/sda -- mkpart primary 1MiB -8GiB
  ```
  - Add swap partition

  ```bash
  parted /dev/sda -- mkpart primary linux-swap -8GiB 100%
  ```

7. Format partitons

  - sda1

  ```bash
  mkfs.ext4 -L nixos /dev/sda1
  ```
  - sda2 (swap)

  ```boot
  mkswap -L swap /dev/sda2
  ```

8. Mount partiton

```bash
mount /dev/disk/by-label/nixos /mnt
```

9. Generate initial configuration:

```bash
nixos-generate-config --root /mnt
```

>Above command will create `configuration.nix` file. It contains all default
configuration options according to which NixOS will be installed.

10. Uncomment following line in `configuration.nix` file.

```bash
$ vim /mnt/etc/nixos/configuration.nix
boot.loader.grub.device = "/dev/sda";
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
move on to package manager and system customization.

#### NixOS package installation

As already mentioned, your NixOS is now in default configuration. It means it
have already installed only basic tools and applications. Additional ones can be
added using **package manager**. Most of the packages could be found in
`nixpkgs` library. All are listed in
[all-packages.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/all-packages.nix).
Alternatively you can use the command:

```bash
nix-env -qaP '*' --description |grep -i name
```

As you can see most tools are presented in `nixpkgs`. However, there is
possibility to build your own (custom ones), based on github repository. Let's
try to this with custom `flashrom` and [3mdeb github fork](https://github.com/3mdeb/flashrom/commit/5f164cc28fdc055c272d21c60a0a32dc23d29e3b).

1. First, clone the `nixpkgs` repo. Without it, you won't have access to any
package.

```bash
git clone git@github.com:NixOS/nixpkgs.git
```

2. Change directory to `nixpkgs` and create the package directory for new
flashrom. We named it `flashrom2`, as `flashrom` already exists.

```bash
cd nixpkgs
mkdir pkgs/tools/misc/flashrom2
```

3. Move to the `flashrom2` directory and create a `default.nix` config file.

```bash
cd pkgs/tools/misc/flashrom2
touch default.nix
vim default.nix
```

4. Fill `default.nix` file with following content

```bash
{ lib
, stdenv
, fetchurl
, meson
, ninja
, pkgconfig
, libftdi1
, libusb1
, pciutils
}:

stdenv.mkDerivation rec {
  pname = "flashrom2";
  version = "2.0";

  src = builtins.fetchGit {
  url = "https://github.com/3mdeb/flashrom.git";
  ref = "wip";
  rev = "5f164cc28fdc055c272d21c60a0a32dc23d29e3b";
  };

  nativeBuildInputs = [ meson pkgconfig ninja ];
  buildInputs = [ libftdi1 libusb1 pciutils ];

  meta = with lib; {
    homepage = http://www.flashrom.org;
    description = "Utility for reading, writing, erasing and verifying flash ROM chips";
    license = licenses.gpl2;
    platforms = platforms.all;
  };
}
```

5. Build `flashrom2`

```bash
nix-build -A flashrom2
```

> `nix-build` command builds any package which is added or already exists in
`nixpkgs` library.

6. Add `flashrom2` to NixOS profile to create symlinks.

```bash
nix-env -f . -iA flashrom2
installing 'flashrom2-2.0'
building '/nix/store/hbxi8l93x2qv3kzg7kjpfaa6pmkij48f-user-environment.drv'...
created 21 symlinks in user environment
```

You have just built your first package in NixOS. Moreover, it is your custom
build! However, as you can see entire process is non-trivial. Essential part of
each package is `stdenv` library. Its
[documentation](https://nixos.org/nixos/nix-pills/fundamentals-of-stdenv.html)
should clarify some issues. However, it is good to experiment with package
manager on your own. Good point to start are already existing packages and their
`default.nix` files.

You may wonder why do we build our own tools, when most of them are available in
default `nixpkgs`. Answer is simple - we have possibility to build not only
tools, but also many other software and firmware components... You will
learn more about it in next section.

## Firmware

As I mentioned in previous section, with NixOS we have possibility to customize
our platform (both firmware and operating system). Before, we do that, I need to
introduce some concepts. The better you understand them, the more awareness
about security of your platform you will have and better understand the purpose
of entire project. Let's break our entire system into following main parts. They
are listed in order of execution when the platform is booted, so you can also
see the flow and relations between them.

#### BIOS

Our solution is open-source, so we also use such firmware (BIOS) -
**coreboot**. Also, as we are maintainers of coreboot for PC Engines platforms,
we use
[this](https://github.com/pcengines/coreboot/tree/pcengines_trenchboot_4.11.x)
particular fork and branch. Every change appears there, so it is definitely
place where you will find up-to-date firmware. I won't describe coreboot itself
here. What you need to know, it is first code which is running during boot
process. It initialize all hardware components on platform.

#### GRUB

When coreboot ends its work, a bootloader comes in. We use **GRUB**. Its task is
to boot operating system. Normally, if NixOS is installed on hard disk, GRUB
loads it to RAM. Being more precise, *Linux kernel* and *initrd* are being
loaded. However, that operation is slightly different when we enable DRTM. As it
is main goal of our project, let's take a look a little bit closer on it.

We prepared extension module called `slaunch`. When DRTM is enabled, `slaunch`
executes AMD's dedicated machine instruction `SKINIT`. Treat is as 'pre-DRTM'
operation. It prepares all components and jump to secure loader - `Landing
Zone`.

#### Landing Zone (LZ)

LZ has 2 main tasks: measure Linux kernel and then run it. If you wonder, when
measurements are done, then you have just find out. Without LZ, DRTM doesn't
exist. Although it seems inconspicuous, it does fundamental job in secure boot
process.

#### Linux kernel

Linux kernel is a core of all Linux based operating systems. Actually, it is
operating system without any additional applications. It can be modified to
given platform by including and excluding particular drivers, called modules. In
general, it is done to limit size of kernel image and adjust its performance.

#### initrd

initrd stands for *initial ramdisk*. It is image used by bootloader to mount
initial file system in memory. Also, that image contains modules which will be
loaded by Linux kernel.

## Bring it all together

I have mentioned and described all parts of system which you need to know, to
understand TrenchBoot and DRTM. But how they are related and how to build such
system? I said that package manager in NixOS is very important and we will
commonly use it. And now I want to show you how.

First, we have 'clean' NixOS operating system installed on hard drive. It has
default Linux kernel and initrd. From GRUB we can boot it and... that's it. No
DRTM, no measurements and no security. But, with custom package management, we
can **enable DRTM** and **prepare all components** directly from operating
system. That's what we did. We have prepared, in separate packages, all elements
mentioned above:

- GRUB-trenchboot - it updates GRUB, so it boots `slaunch` and in consequence LZ
- LZ-trenchboot - it adds LZ which measures and runs Linux kernel (enables DRTM)
- linux-kernel-trenchboot - customized NixOS kernel which also make some
  measurements
- initrd-trenchboot - customized initrd

Installing those packages will create a target system with enabled DRTM. How to
do this in practice and verify if it really works will be discussed in next
article. So don't waste time and move to the [next post](link-to-next-post) to
use this knowledge in practice!

## Summary

This article was mostly theoretical introduction to a project. There were a lot
of knowledge and new concepts. However, it is necessary to struggle through it
at the beginning, so it will be a lot easier later. In next blog post, I will
show you a real working example. You will see how to configure NixOS and verify
DRTM. Of course, everything in reproducible way, so you can perform it too!

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

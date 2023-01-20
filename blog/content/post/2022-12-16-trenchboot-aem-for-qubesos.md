---
title: TrenchBoot Anti Evil Maid for Qubes OS
abstract: 'Qubes OS Anti Evil Maid (AEM) software heavily depends on the
           availability of the DRTM technologies to prevent the Evil Maid
           attacks. However, the project hasn't evolved much since the
           beginning of 2018 and froze on the support of TPM 1.2 with Intel TXT
           in legacy boot mode (BIOS). In the post we show how existing
           solution can be replaced with TrenchBoot and how one can install it
           on the Qubes OS. Also the post will also briefly explain how
           TrenchBoot opens the door for future TPM 2.0 and UEFI support for
           AEM.'
cover: /covers/trenchboot-logo.png
author: michal.zygowski
layout: post
published: true
date: 2022-12-16
archives: "2022"

tags:
  - firmware
  - coreboot
  - Qubes OS
  - TrenchBoot
  - GRUB
  - Xen Hypervisor
categories:
  - Firmware
  - Bootloader
  - Hypervisor
  - OS Dev
  - Security

---

# Introduction

The firmware is the heart of the security of a given system and should always
be up-to-date to maintain the computer's security. However, being up to date
does not prevent the firmware vulnerabilities from appearing. The Static Root
of Trust (SRT) like Unified Extensible Firmware Interface (UEFI) Secure Boot
and measured boot provided by the firmware is not always sufficient to
establish a secure environment for an operating system. If the firmware is
compromised, it could inject malicious software into operating system
components and prevent the machine owner from detecting it. Silicon vendors
implement alternative technologies to establish a Dynamic Root of Trust (DRT)
to provide a secure environment for operating system launch and integrity
measurements.

The usage of DRT technologies like Intel Trusted Execution Technology (TXT) or
AMD Secure Startup becomes more and more significant, for example, Dynamic Root
of Trust for Measurement (DRTM) requirements of
[Microsoft Secured Core PCs](https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-highly-secure#what-makes-a-secured-core-pc).
DRTM hasn't found its place in open-source projects yet, but that gradually
changes. The demand on having firmware independent Roots of Trust is
increasing, and projects that satisfy this demand are growing, for instance,
[TrenchBoot](https://trenchboot.org/). TrenchBoot is a framework that allows
individuals and projects to build security engines to perform launch integrity
actions for their systems. The framework builds upon Boot Integrity
Technologies (BITs) that establish one or more Roots of Trust (RoT) from which
a degree of confidence that integrity actions were not subverted.

[Qubes OS Anti Evil Maid (AEM)](https://blog.invisiblethings.org/2011/09/07/anti-evil-maid.html)
software heavily depends on the availability of the DRTM technologies to
prevent the Evil Maid attacks. However, the project hasn't evolved much since
the beginning of 2018 and froze on the support of TPM 1.2 with Intel TXT in
legacy boot mode (BIOS). Because of that, the usage of this security software
is effectively limited to older Intel machines only. TPM 1.2 implemented SHA1
hashing algorithm, which is nowadays considered weak in the era of
forever-increasing computer performance and quantum computing. The solution to
this problem comes with a newer TPM 2.0 with more agile cryptographic
algorithms and SHA256 implementation by default.

The post will present the TrenchBoot solution for Qubes OS AEM replacing the
current TPM 1.2 and Intel TXT only implementation. The advantage of TrenchBoot
solution over existing [Trusted Boot](https://sourceforge.net/p/tboot/wiki/Home/)
is the easier future integration of AMD platform support, as well as TPM 2.0
and UEFI mode support.

# Modificationts to original Qubes OS AEM

To replace the original implementation of Qubes OS AEm based on Trusted Boot,
there weren't any AEM scripts modifications necessary. What actually had to
change is GRUB and Xen Hypervisor (and Trusted Boot - to be removed). Why? one
may ask... First of all one must understand the role of Trusted Boot (TBOOT).

## Trusted Boot DRTM flow

![Breakout of measured launch details](/img/txt_launch2.jpg)

> Source: *[A Practical Guide to TPM 2.0](https://link.springer.com/book/10.1007/978-1-4302-6584-9)*

The main role of Trusted Boot was to prepare a platform to be launched with
Intel TXT (Intel's DRTM technology) in a operating system agnostic way. It has
been achieved by loading a tboot kernel with multiboot protocol and the other
system components as the modules. That way TBOOT is the main kernel which
starts first, prepares the platform for TXT launch. When the platform is ready
then tboot performs the TXT launch. The control is passed to SINIT ACM which
uses TXT to measure the operating system components in a secure manner. Then
the control is handed back to tboot kernel which check if the operation was
successful and boots the target operating system.

Although the tboot tried to be as OS agnostic as possible, some tboot presence
awareness from operating system is needed because the application processor
cores (all cores except the main one) are left in a special state after TXT
launch and cannot be woken up like in traditional boot process. To solve this
problem, tboot installs a special processor wakeup procedure in the memory
which OS must call into to start the processor cores. Only then OS may
initialize the processor per its own requirements.

As one can see the process is complex in case of Intel TXT. Migration of all
tboot responsibilities was not trivial and has been divided into the work on
both GRUB and Xen Hypervisor side of Qubes OS.

## GRUB modifications

![](/img/grub_logo.png)

In order to fulfill the same role as tboot, GRUB had to learn how to prepare
the platform and perform TXT launch. Most of the work for that particular part
has been done by [Oracle Team working on TrenchBoot for GRUB](https://www.mail-archive.com/grub-devel@gnu.org/msg30167.html).
That work however covered the Linux kernel TXT launch only. What still had to
be done was the multiboot protocol support in GRUB to be able to TXT launch a
Xen Hypervisor. The patches have been prepared for the respective Qubes GRUB
[package](https://github.com/3mdeb/qubes-grub2/pull/2).

## Xen modifications

![](/img/xen_project_logo.png)

Analogically to GRUB, Xen had to take over some responsibilities from tboot.
Due to the Intel TXT requirements for boot process, a new entry point had to be
developed to which SINIT ACM will return control. The new entry point was
responsible for saving information that a TXT launch happened and clean up the
processor state so that the booting of Xen kernel could continue with the
standard multiboot path. Among others, if Xen detected TXT launch, it had to
perform the special processor cores wakeup process (which has been rewritten
from TrenchBoot Linux patches to Xen native code) and measure external
components before using them (that is the Xen parameters, Dom0 Linux kernel and
initrd). Xen also had to reserve the memory regions used by Intel TXT, like it
was done when tboot has been utilized. The relevant source code for the
respective Qubes Xen package is available [here](https://github.com/3mdeb/qubes-vmm-xen/pull/1).

# Installation and verification of TrenchBoot AEM on Qubes OS

For a seamless deployment and installation of TrenchBoot AEM, the modifications
have been converted to patches which are applied to projects' sources during
Qubes OS components compilation. Those patches have been presented earlier with
links to Pull Requests. It allows building ready-to-use RPM packages that can
be installed directly on an installed Qubes OS system. Below a procedure for
building the packages has been presented. If your are not interested in
compilation, skip to the [next section](#installing-xen-and-grub-packages).
The pre-built packages can be downloaded from [here](https://cloud.3mdeb.com/index.php/s/K99jFTFYo8eM2ZW).

Note, in order to use the TrenchBoot AEM for Qubes OS you have to own a
TXT-capable platform with TXT-enabled firmware offering legacy boot. You may
find such platform and firmware in the [Dasharo with Intel TXT support](https://blog.3mdeb.com/2022/2022-03-17-optiplex-txt/)
post.

## Building Xen and GRUB packages

To not make the post excessively long the procedure for building packages
has been put into [TrenchBoot-SDK documentation](https://github.com/TrenchBoot/trenchboot-sdk/blob/3d56ca7b27bb038629fd838819a1050006725a1e/Documentation/build_qubes_packages.md).
Follow the instructions in the file to build the TrenchBoot AEM packages.

## Installing Xen and GRUB packages

The following process was carried out and tested on
[Qubes OS 4.2](https://openqa.qubes-os.org/tests/55506#downloads). Packages that
should be downloaded from there and then installed are
`xen-4.17.0-3.fc32.x86_64.rpm` and if on your device is EFI
`grub2-efi-x64-2.06-1.fc32.x86_64.rpm`.

In order to install the packages one has to send the Xen and GRUB RPMs to the
Dom0. Please not that moving any external files or data to Dom0 is potentially
dangerous. Ensure that your environment is safe and the RPMs have the right
checksums after copying them to Dom0. If you don't know how to copy files to
Dom0, refer to the [Qubes OS documentation](https://www.qubes-os.org/doc/how-to-copy-from-dom0/#copying-to-dom0).

1. Even before installing packages, it is required to enable the
   `current-testing` repository to avoid the need to install additional
   dependencies:

    ```bash
    sudo qubes-dom0-update --enablerepo=qubes-dom0-current-testing
    ```

2. If the RPMs are inside Dom0 install them with the following command:

   ```bash
   sudo rpm --define '_pkgverify_level digest' -i path/to/package.rpm 
   ```

3. Additionally you will have to download SINIT ACM and place it in `/boot`
   partition/directory so that GRUB will be able to pick it up. Note it is only
   necessary if your firmware/BIOS does not include/place SINTI ACM in the Intel
   TXT region. You may obtain all SINIT ACMs as described
   [here](https://github.com/QubesOS/qubes-antievilmaid/blob/7561a4d724b9b0df8ba48d8f2735d3754961f87b/README#L177).
   Copy the SINTI ACM suitable for your platform to `/boot` directory.
   In case of Dell OptiPlex it will be `SNB_IVB_SINIT_20190708_PW.bin`.
4. Install Qubes AEM packages with the following command, because Qubes OS 4.2
   lacks AEM packages:

    ```bash
    qubes-dom0-update --enablerepo=qubes-dom0-unstable --enablerepo=qubes-dom0-current-testing anti-evil-maid
    ```

5. Enter the SeaBIOS TPM menu (hotkey `t`) and there choose the clear TPM
   option. Then activate and enable the TPM by selecting the appropriate
   options.
6. Follow steps in [setup TPM for AEM](https://github.com/QubesOS/qubes-antievilmaid/blob/7561a4d724b9b0df8ba48d8f2735d3754961f87b/README#L147).
7. The anti-evil-maid script may not work with LUKS2 in its current state, so
   make a fix according to this [Pull Request](https://github.com/QubesOS/qubes-antievilmaid/pull/41/files)
   if needed.
8. Now is possible to [setup Qubes OS AEM device](https://github.com/QubesOS/qubes-antievilmaid/blob/7561a4d724b9b0df8ba48d8f2735d3754961f87b/README#L202).
   This will create the AEM entry in Qubes GRUB, but this entry is using tboot.
9. You will need to edit the grub configuration file(/boot/grub2/grub.cfg) by
   copying standard Qubes OS entry (without AEM) and adding:

    ```bash
    slaunch
    slaunch_module /<name_of_the_sinit_acm>
    ```

    before the `multiboot2` directive which loads Xen Hypervisor. Name the entry
    differently, e.g. `Qubes OS with TrenchBoot AEM`.  We are still working on
    automating this step, so please bare with the manual file edition for now.

    Example GRUB entry:

    ```bash
    menuentry 'Qubes, with Xen hypervisor' --class qubes --class gnu-linux --class gnu --class os --class xen $menuentry_id_option 'xen-gnulinux-simple-/dev/mapper/qubes_dom0-root' {
        insmod part_msdos
        insmod ext2
        set root='hd0,msdos1'
        if [ x$feature_platform_search_hint = xy ]; then
          search --no-floppy --fs-uuid --set=root --hint-bios=hd0,msdos1 --hint-efi=hd0,msdos1 --hint-baremetal=ahci0,msdos1 --hint='hd0,msdos1'  38474da6-7b2d-410d-95e6-8683005fb23f
        else
          search --no-floppy --fs-uuid --set=root 38474da6-7b2d-410d-95e6-8683005fb23f
        fi
        echo    'Loading Xen 4.17.0 ...'
        if [ "$grub_platform" = "pc" -o "$grub_platform" = "" ]; then
            xen_rm_opts=
        else
            xen_rm_opts="no-real-mode edd=off"
        fi
        slaunch
        slaunch_module /SNB_IVB_SINIT_20190708_PW.bin
        multiboot2      /xen-4.17.0.gz placeholder  console=none dom0_mem=min:1024M dom0_mem=max:4096M ucode=scan smt=off gnttab_max_frames=2048 gnttab_max_maptrack_frames=4096 ${xen_rm_opts}
        echo    'Loading Linux 5.15.81-1.fc32.qubes.x86_64 ...'
        module2 /vmlinuz-5.15.81-1.fc32.qubes.x86_64 placeholder root=/dev/mapper/qubes_dom0-root ro rd.luks.uuid=luks-f1f850fa-59bf-4911-8256-4986c485e112 rd.lvm.lv=qubes_dom0/root rd.lvm.lv=qubes_dom0/
swap plymouth.ignore-serial-consoles i915.alpha_support=1 rd.driver.pre=btrfs rhgb quiet
        echo    'Loading initial ramdisk ...'
        module2 --nounzip   /initramfs-5.15.81-1.fc32.qubes.x86_64.img
    }
    ```

## Verifying TrenchBoot AEM for Qubes OS

The moment of truth has come. If the installation has been performed
successfully, it is time to try out the TXT launch. So reboot the platform and
choose the newly created entry with TrenchBoot. If it succeeds you should get a
password prompts.

TODO: screenshots/logs

## Summary

It has been shown that TrenchBoot can be integrated to perform DRTM secure
launch of Qubes OS in place of old tboot. Moreover TrenchBoot is more
extensible to other platforms like AMD. In the future Anti Evil Maid will be
available on both Intel and AMD platform with both TPM 1.2 and TPM 2.0 thanks
to TrenchBoot (which seemed to not be possible with tboot only).

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

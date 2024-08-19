---
title: Secure Booting FreeBSD with Dasharo firmware
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: filip.lewinski
layout: post
published: true
date: 2024-08-19
archives: "2024"

tags:
  - bsd
  - dasharo
  - edk2
  - secure-boot
  - protectli
  - uefi
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

## Introduction

## UEFI Secure Boot

UEFI Secure Boot is a security feature designed to ensure that only trusted,
signed software can execute during the boot process, protecting against malware
and unauthorized code execution. It verifies the signatures of bootloaders and 
kernel binaries against trusted certificates embedded in the firmware.

### Linux

On Linux, Secure Boot is supported using a small, signed bootloader called "
shim," which is pre-signed by Microsoft. Shim loads the GRUB bootloader, which
is verified against a certificate embedded in shim, and GRUB then loads the 
Linux kernel, also ensuring it is signed and trusted.

### UEFI Secure Boot status on FreeBSD - brief summary

In short, the [FreeBSD wiki](https://wiki.freebsd.org/SecureBoot) proposes two
stages of Secure Boot implementation. 

First would be to enable booting the system with Microsoft-signed shim and a 
FreeBSD-signed EFI loader, while also offering users to generate their own 
keys and certificates.

The second stage would involve having all of the drivers and kernel modules to
be signed and authorized, resulting in a locked-down system akin to Fedora's 
implementation. 

As of the time of writing this post, the first stage is mostly complete. It is
possible to create and sign a complete EFI executable containing the bootloader
and the FreeBSD kernel, which can be booted using Dasharo firmware Secure Boot.

Now, let's analyze what the said executable consists of.

#### FreeBSD UEFI boot process

The regular UEFI boot process on FreeBSD is as follows:

* UEFI firmware loads `boot1.efi`
* `boot1.efi` in turn loads `loader.efi`
* Finally, `loader.efi` loads the kernel.

The goal scenario, according to the FreeBSD Foundation, would be that a
cryptographic handshake would verify each transition within the process. That
is still under development, and the currently available option is a little less
modular.

It is possible to skip `boot1.efi` and combine the loader and the kernel into 
one large package, which then can be signed with self-issued keys. The keys
are enrolled into Dasharo firmware, which boots the loader-kernel object
directly.

## Creating a Secure Boot - ready FreeBSD EFI executable

This guide is about migrating your current installation, not from scratch

### Determine the loader of choice

There are currently several flavors of the `loader.efi` available. The original
one was written in 
[FORTH](https://hackaday.com/2017/01/27/forth-the-hackers-language/).
The 14.1 release defaults to a more modern Lua one, the final option being
`loader_simp` - a simplified C implementation. This guide will only provide
instructions on using the legacy FORTH loader and the current default.

### Copy the boot filesystem

```
$ mkdir ~/bootfs
$ mkdir ~/bootfs/boot
$ cd ~/bootfs/boot
$ cp -r /boot/kernel .
$ cp -r /boot/defaults .
$ cp /boot/loader.conf .
$ cp /boot/*.rc .
$ cp /boot/device.hints .
$ cp /boot/loader.help* .
```

#### Lua loader

```
$ mkdir lua
$ cp -r /boot/lua ./lua
```

#### FORTH loader

```
$ cp /boot/*.4th .
```

### Copy the fstab

```
$ mkdir ~/bootfs/etc
$ cp /etc/fstab ~/bootfs/etc/fstab
```

### Create an image of the filesystem

```
$ cd ~/
$ makefs bootfs.img bootfs
```

determine the size of the boot filesystem. This will determine how much memory 
to reserve in the loader:

```
$ ls -l bootfs.img | awk '{print $5}'
```
add a safety factor of a couple hundred bytes (~512) to this number, and record
it.

### Build the Loader With Extra Space

This step requires you to have the source code for your system. You might have 
checked the `src` component during OS installation, then the `/usr/src/` 
directory should be already populated. If not, clone the source code from
Github, substituting `14.1` with the release you are currently using:

```
git clone -b releng/14.1 https://git.freebsd.org/src.git /usr/src
```

Now, recall your bootfs size and substitute ${BOOTFS_SIZE_PLUS_SAFETY} below:

```
$ cd /usr/src/stand
$ make MD_IMAGE_SIZE=${BOOTFS_SIZE_PLUS_SAFETY}
```

### Embed bootfs image in the loader.efi

The build results will be available under `/usr/obj`. 

* If you have chosen to use the legacy FORTH loader, the path to the file that 
  interests you should be similar to
  `/usr/obj/usr/src/amd64.amd64/stand/efi/loader_4th/loader_4th.efi`.

* If you have chosen the Lua loader, the path should be similar to
  `/usr/obj/usr/src/amd64.amd64/stand/efi/loader_lua/loader_lua.efi`

Copy the appropriate file and use the available embedding utility:

```
$ cp /usr/obj/${PATH_TO_LOADER}/loader.efi ~/
$ /usr/src/sys/tools/embed_mfs.sh ~/loader.efi ~/bootfs.img
```

You might need to make `embed_mfs.sh` executable:

```
$ chmod +x /usr/src/sys/tools/embed_mfs.sh
```

At this point, `loader.efi` is an UEFI-bootable binary, consisting of the 
FreeBSD bootloader and kernel. The last remaining step to Secure Boot 
compatibility is generating keys and signing the binary.

## Signing the binary

FreeBSD includes a tool for signing EFI executables - `uefisign`. There is also
a utility provided to generate example keys and certificates needed to sign an
executable. 

You can generate a self-signed certificate and use it to sign a binary as 
follows:

```
$ /usr/share/examples/uefisign/uefikeys testcert
$ uefisign -c testcert.pem -k testcert.key -o signed-loader.efi loader.efi
```

As earlier, make sure the script is marked as executable.

You should now have a `signed-loader.efi` and a `testkey.cer` file. The loader
file is what we're going to be booting from Dasharo, and the `.cer` file is our
custom certificate we need to enroll, so that Secure Boot can verify the 
loader's signature against it.

## Testing in QEMU

To spare yourself the trouble of recovering a broken OS installation, it is 
recommended to test the binary in an emulated environment.

Make sure you have an up-to-date installation of QEMU on your system, and get 
the latest QEMU release of Dasharo 
[here](https://github.com/Dasharo/edk2/releases).

### Launching QEMU with an emulated filesystem

Create a directory for the QEMU firmware files, and a directory for the test
EFI files:

```
$ mkdir -p ~/qemu_test/efi
```

Download `OVMF_CODE_RELEASE.fd` and `OVMF_VARS_RELEASE.fd` and place them in
the `~/qemu_test` directory. Place the `signed-loader.efi` and `.cer` files in 
the `~/qemu_test/efi` directory:

```
$ cp ~/signed-loader.efi ~/qemu_test/efi/
$ cp ~/testcert.cer ~/qemu_test/efi/
$ cd ~/qemu_test
```

Run Dasharo firmware in QEMU, mounting the EFI directory as a virtual fat 
drive:

```
$ qemu-system-x86_64 -machine q35,smm=on \
    -m 1G \
    -global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file=OVMF_CODE_RELEASE.fd,readonly=on \
    -drive if=pflash,format=raw,unit=1,file=OVMF_VARS_RELEASE.fd \
    -global ICH9-LPC.disable_s3=1 \
    -drive file=fat:rw:efi
```

### Enrolling the certificate

#### Preparing clean Secure Boot

1. Press `F2` to enter setup
    ![setup menu](/img/setup_root.png)

1. Navigate to `Device Manager/Secure Boot Configuration`
    ![secure boot menu](/img/sboot_init.png)

1. Enable `Custom Mode`
    ![secure boot custom mode](/img/custom_mode.png)

1. Enter the new `Advanced Secure Boot Keys Management` menu
    ![advanced secure boot keys management](/img/advanced_sboot.png)

1. Select `Reset to default Secure Boot Keys`
    ![reset to default sboot keys](/img/reset_to_def.png)

1. Select `YES`

1. Press `F10` to save and `Y` to confirm
    ![f10 save dialog](/img/save_conf.png)

1. Reset the platform by pressing `ESC` twice and selecting `Reset`

#### Enrolling the ceritficate

1. Press `F2` to enter setup again
    ![setup menu](/img/setup_root.png)

1. Navigate to `Device Manager/Secure Boot Configuration`
    ![secure boot enabled](/img/sboot_enabled.png)

1. Enable `Custom Mode` and enter the `Advanced Secure Boot Keys Management` 
    menu again.
    ![advanced secure boot keys management](/img/advanced_sboot.png)

1. Navigate to `DB Options/Enroll Signature/Enroll Signature Using File/`.
    If the EFI directory is properly mounted, you should see a single entry in
    this menu, similar to this
     ![efi directory entry](/img/efi_entry.png)

1. Select the entry, and then select `testcert.cer`
     ![testcert.cer](/img/testcert.png)

1. Select `Commit Changes and Exit`
     ![commit changes and exit](/img/commit_changes.png)

1. Press `F10` to save and `Y` to confirm
    ![f10 save dialog](/img/save_conf.png)

1. Make sure that `Current Secure Boot State` is enabled
    ![secure boot enabled](/img/sboot_enabled.png)

1. Reset the platform again

### Booting FreeBSD

1. Wait for Dasharo to boot into UEFI Shell
    ![EFI shell](/img/efi_shell.png)

1. Enter the filesystem and boot the signed-loader.efi
  ```
  fs0:
  signed-loader.efi
  ```
  ![EFI shell commands](/img/ush_commands.png)

1. Say hello to Beastie
    ![beastie](/img/beastie.png)


## Testing on hardware

Upon making sure that the loader-kernel object boots properly within an 
emulation environment, we can proceed to Secure Booting FreeBSD on hardware.

To do that, follow the exact same steps as with emulation, the only differewnce
being that you will now need to upload the certificate to a USB drive and 
enroll the certificate from there. 

You will also need to place the `signed-loader.efi` file in your EFI partition,
and add it as a custom boot option.

### Adding a custom boot option

* Enter setup menu
* Navigate to `Boot Maintenance Manager/Boot Options/Add Boot Option`
* Choose the appropriate disk label. They might look intimidating, but you
  should be able to find the correct one by looking for a familiar keyword.
  If you have an NVME drive for example, there should be an entry with 
  `Pci(0x0,0x0)/NVMe`.
* Find the loader-kernel object. It should be located under 
  `<efi>/<freebsd>/loader.efi`
* Name the entry appropriately, confirm and save the changes.


## Troubleshooting

### Mountroot

If after booting the `signed-loader.efi` you land in `mountroot`, you need to
type in `zfs:zroot/ROOT/default` and add the line

```bash
vfs.root.mountfrom="zfs:zroot/ROOT/default"
```

to your `/boot/loader.conf`.

## Summary



Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

---
title: UEFI Secure Booting FreeBSD with Dasharo firmware
abstract: 'This blogpost is a very brief introduction to the UEFI Secure Boot.
          It focuses on enabling Secure Boot on FreeBSD, on the example of a
          device running Dasharo firmware.'
cover: /covers/freebsd-logo-daemon.png
author: filip.lewinski
layout: post
published: true
date: 2024-11-14
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

UEFI Secure Boot is a security feature designed to provide an infrastructure
for UEFI Image load-time authentication. It authenticates OS Loaders, UEFI
drivers, and applications. The Platform Owner manages the platform's security
policy and can check the integrity and security of a given UEFI Image.

### Linux

Mainstream distributions like Ubuntu or Fedora took the approach of using a
small, signed bootloader called `shim`, which is pre-signed by Microsoft. Shim
loads the bootloader, which is verified against a certificate embedded in shim,
and the bootloader then loads the Linux kernel, also ensuring it is signed and
trusted. To put it simply, they can sign their kernel themselves, instead of
having to ask Microsoft to sign each kernel update.

Please see [this blogpost](https://mjg59.dreamwidth.org/20303.html) for more
information on this specific subject.

### UEFI Secure Boot status on FreeBSD - brief summary

In short, the [FreeBSD wiki](https://wiki.freebsd.org/SecureBoot) proposes two
stages of UEFI Secure Boot implementation.

First would be to enable booting the system with Microsoft-signed shim and a
FreeBSD-signed EFI loader, while also offering users to generate their own
keys and certificates.

The second stage would involve having all of the drivers and kernel modules to
be signed and authorized, resulting in a locked-down system, as is now possible
in the upstream
[Linux kernel](https://www.kernel.org/doc/html/v4.17/admin-guide/module-signing.html)

As of the time of writing this post, the first stage is mostly complete. It is
possible to create and sign a complete EFI executable containing the bootloader
and the FreeBSD kernel, which can be booted using UEFI Secure Boot.

Now, let's analyze what the said executable consists of.

#### FreeBSD UEFI boot process

The regular UEFI boot process on FreeBSD is as follows:

![bootflow](/img/freebsd_boot_process.png)

* UEFI firmware loads `boot1.efi`
* `boot1.efi` in turn loads `loader.efi`
* Finally, `loader.efi` loads the kernel.

The target scenario, according to the FreeBSD Foundation, would be that a
cryptographic handshake would verify each transition within the process. That
is still under development, and the currently available option is a little less
modular.

It is possible to skip `boot1.efi` and combine the loader and the kernel into
one large package, which then can be signed with self-issued keys. The keys
are enrolled into Dasharo firmware, which boots the loader-kernel object
directly.

![bootflow](/img/freebsd_secboot_process.png)

## Creating a UEFI Secure Boot - ready FreeBSD EFI executable

Please note that this guide assumes that you have a working FreeBSD
installation that you wish to modify for UEFI Secure Boot support. Installation
of the system will not be covered here.

### Determine the loader of choice

There are currently several flavors of the `loader.efi` available. The original
one was written in
[FORTH](https://hackaday.com/2017/01/27/forth-the-hackers-language/).
The 14.1 release defaults to a more modern Lua one, the final option being
`loader_simp` - a simplified C implementation. This guide will only provide
instructions on using the legacy FORTH loader and the current default. The
process has been tested using FreeBSD 14.1.

### Copy the boot filesystem

```bash
mkdir ~/bootfs
mkdir ~/bootfs/boot
cd ~/bootfs/boot
cp -r /boot/kernel .
cp -r /boot/defaults .
cp /boot/loader.conf .
cp /boot/*.rc .
cp /boot/device.hints .
cp /boot/loader.help* .
```

#### Lua loader

```bash
mkdir lua
cp -r /boot/lua ./lua
```

#### FORTH loader

```bash
cp /boot/*.4th .
```

### Copy the fstab

```bash
mkdir ~/bootfs/etc
cp /etc/fstab ~/bootfs/etc/fstab
```

### Create an image of the filesystem

```bash
cd ~/
makefs bootfs.img bootfs
```

Determine the size of the boot filesystem. This will determine how much memory
to reserve in the loader:

```bash
ls -l bootfs.img | awk '{print $5}'
```

Add a safety factor of a couple hundred bytes (~512) to this number, and record
it.

### Build the Loader With Extra Space

This step requires you to have the source code for your system. You might have
checked the `src` component during OS installation, then the `/usr/src/`
directory should be already populated. If not, clone the source code from
GitHub, substituting `14.1` with the release you are currently using:

```bash
git clone -b releng/14.1 https://git.freebsd.org/src.git /usr/src
```

Now, recall your bootfs size and substitute `${BOOTFS_SIZE_PLUS_SAFETY}` below:

```bash
cd /usr/src/stand
make MD_IMAGE_SIZE=${BOOTFS_SIZE_PLUS_SAFETY}
```

### Embed bootfs image in the loader.efi

The build results will be available under `/usr/obj`.

* If you have chosen to use the legacy FORTH loader, the path to the file that
  interests you should be similar to
  `/usr/obj/usr/src/amd64.amd64/stand/efi/loader_4th/loader_4th.efi`.

* If you have chosen the Lua loader, the path should be similar to
  `/usr/obj/usr/src/amd64.amd64/stand/efi/loader_lua/loader_lua.efi`

Copy the appropriate file and use the available embedding utility:

```bash
cp /usr/obj/${PATH_TO_LOADER}/loader.efi ~/
/usr/src/sys/tools/embed_mfs.sh ~/loader.efi ~/bootfs.img
```

You might need to make `embed_mfs.sh` executable:

```bash
chmod +x /usr/src/sys/tools/embed_mfs.sh
```

At this point, `loader.efi` is an UEFI-bootable binary, consisting of the
FreeBSD bootloader and kernel. The last remaining step to UEFI Secure Boot
compatibility is generating keys and signing the binary.

## Signing the binary

FreeBSD includes a tool for signing EFI executables - `uefisign`. There is also
a utility provided to generate example keys and certificates needed to sign an
executable.

You can generate a self-signed certificate and use it to sign a binary as
follows:

```bash
/usr/share/examples/uefisign/uefikeys testcert
uefisign -c testcert.pem -k testcert.key -o signed-loader.efi loader.efi
```

As earlier, make sure the script is marked as executable.

You should now have a `signed-loader.efi` and a `testkey.cer` file. The loader
file is what we're going to be booting from Dasharo, and the `.cer` file is our
custom certificate we need to enroll, so that UEFI Secure Boot can verify the
loader's signature against it.

## Testing in QEMU

To spare yourself the trouble of recovering a broken OS installation, it is
recommended to test the binary in an emulated environment.

Make sure you have an up-to-date installation of QEMU on your system, and get
the latest QEMU release of Dasharo
[here](https://github.com/Dasharo/edk2/releases). This process has been tested
on the [v0.1.0](https://github.com/Dasharo/edk2/releases/tag/qemu_q35_v0.1.0)
release.

### Launching QEMU with an emulated filesystem

Create a directory for the QEMU firmware files, and a directory for the test
EFI files:

```bash
mkdir -p ~/qemu_test/efi
```

Download `OVMF_CODE_RELEASE.fd` and `OVMF_VARS_RELEASE.fd` from
[GitHub](https://github.com/Dasharo/edk2/releases) and place them in
the `~/qemu_test` directory. Place the `signed-loader.efi` and `.cer` files in
the `~/qemu_test/efi` directory:

```bash
cp ~/signed-loader.efi ~/qemu_test/efi/
cp ~/testcert.cer ~/qemu_test/efi/
cd ~/qemu_test
```

Run Dasharo firmware in QEMU, mounting the EFI directory as a virtual fat
drive:

```bash
qemu-system-x86_64 -machine q35,smm=on \
    -m 1G \
    -global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file=OVMF_CODE_RELEASE.fd,readonly=on \
    -drive if=pflash,format=raw,unit=1,file=OVMF_VARS_RELEASE.fd \
    -global ICH9-LPC.disable_s3=1 \
    -drive file=fat:rw:efi
```

### Enrolling the certificate

#### Preparing clean UEFI Secure Boot

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

1. Enter setup menu
1. Navigate to `Boot Maintenance Manager/Boot Options/Add Boot Option`
1. Choose the `QEMU_VFAT` disk label
   ![qemu vfat](/img/qemu_vfat.png)
1. Find the loader-kernel object. It should be located under
  `<efi>/<freebsd>/loader.efi`
1. Name the entry appropriately, confirm and save the changes.

1. Say hello to Beastie
    ![beastie](/img/beastie.png)

## Testing on hardware

Upon making sure that the loader-kernel object boots properly within an
emulation environment, we can proceed to UEFI Secure Booting FreeBSD on
hardware.

To do that, follow the exact same steps as with emulation, the only differewnce
being that you will now need to upload the certificate to a USB drive and
enroll the certificate from there.

You will also need to place the `signed-loader.efi` file in your EFI partition,
and add it as a custom boot option.

### Adding a custom boot option

> NOTE: You should always set a Setup Menu password if using UEFI Secure Boot.
  Otherwise, nothing keeps a bad actor from simply disabling it ;)

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

We have learned how to set up UEFI Secure Boot on FreeBSD, a feature
that ensures only trusted, signed software can run during boot to protect
against malware. FreeBSD's implementation involves two stages: using
Microsoft's signed shim bootloader along with a FreeBSD EFI loader, and later
securing all kernel modules.

As our approach, we have chosen to bundle the bootloader and kernel into a
single EFI executable, then sign it using FreeBSD's uefisign tool. We have also
tested the setup in QEMU before deploying on hardware, ensuring that custom
keys are properly enrolled in Dasharo firmware to enable UEFI Secure Boot.

---

If you want to deepen your understanding of UEFI Secure Boot and explore Intel
Root of Trust technologies hands-on, consider joining our **DS08MSA: Mastering
UEFI Secure Boot and Intel Root of Trust Technologies** training. This
intensive course provides the operational knowledge and practical skills to
work confidently with security technologies for x86 platforms. You'll learn to
handle hardware assessments, configure UEFI Secure Boot, and provision Root of
Trust for robust system security; for more details, visit our training page at
[3mdeb Training.](https://3mdeb.com/training/)

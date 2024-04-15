---
title: Implementing UEFI Secure Boot on MPL PIP4x
abstract: "This post explains how we tackled the problem of implementing UEFI
           Secure Boot on MPL's PIP platforms. The process included testing the
           platform's compatibility with Secure Boot and integrating automatic
           image signing into an existing Yocto layer."
cover: /covers/mpl-pip44.jpg
author: pawel.langowski
layout: post
published: true
date: 2024-03-15
archives: "2024"

tags:
  - secure boot
  - uefi
  - mpl
  - yocto
categories:
  - Firmware
  - Security

---

MPL is a Swiss company, which designs and manufactures embedded computers and
microcontroller hardware for rugged environment, extended temperature range, and
with long-term availability. The PIP series is a family of low-power,
ready-to-use embedded computers manufactured by MPL. Recently we tackled the
problem of integrating UEFI Secure Boot in Yocto build on platforms from the
PIP4x series. The goal of the project was to verify that the platform in
question is compatible with UEFI Secure Boot and to enable automatic signing of
system components during build in Yocto.

## Verifying UEFI Secure Boot compatibility

The first step we took was verifying that UEFI Secure Boot could indeed be
implemented on the platform and identifying potential issues and
vulnerabilities. To do that, we developed and executed various automated tests
within the Dasharo OSFV ([Open
Source Firmware Validation](https://github.com/Dasharo/open-source-firmware-validation))
environment. It utilizes the [Robot Framework](https://robotframework.org/) – an
open-source automation framework, which simplifies the creation and execution of
test cases. The tests can be run on the actual platform, or in QEMU. OSFV
provides a
[script](https://github.com/Dasharo/open-source-firmware-validation/blob/b48d554abd32bc0f1ba30a63bb71de27d617b941/scripts/ci/qemu-run.sh),
which allows testing QEMU with Dasharo.

### Setup

The Dasharo OSFV [README
page](https://github.com/Dasharo/open-source-firmware-validation?tab=readme-ov-file#getting-started).
lists the steps that were taken to prepare the environment for tests.

### Test implementation

Development of test cases in the Robot Framework consists of defining reusable
keywords and utilizing them in concrete scenarios. Dasharo OSFV introduces many
such keywords, which allow reading and writing to the terminal, navigating
menus, etc. This allows the developer to implement test cases with much more
ease. Below is an example of a test case, which verifies that UEFI Secure Boot
does not allow booting files that are not signed.

```robot
SBO004.001 Attempt to boot file without the key from Shell (firmware)
    [Documentation]    This test verifies that Secure Boot blocks booting a file
    ...    without a key.
    Skip If    not ${TESTS_IN_FIRMWARE_SUPPORT}    SBO004.001 not supported
    Mount ISO As USB    ${CURDIR}/../scripts/secure-boot/images/NOT_SIGNED.img
    # 1. Make sure that SB is enabled
    Power On
    ${sb_menu}=    Enter Secure Boot Menu And Return Construction
    Enable Secure Boot    ${sb_menu}
    # Save Changes And Reset
    # Changes to Secure Boot menu takes action immediately, so we can just reset
    Reset System
    Boot Efi File Should Fail    hello.efi    NOT_SIGNED
```

As you can see, the test case is brief and easily readable thanks to its use of
predefined keywords.

The test suite can be found in the [OSFV
repository](https://github.com/Dasharo/open-source-firmware-validation/blob/main/dasharo-security/secure-boot.robot)
and the detailed description of each test is available on the [Unified Test
Documentation](https://docs.dasharo.com/unified-test-documentation/dasharo-security/206-secure-boot)
page.

The test suite can be run using the following command:

```bash
robot -L TRACE \
  -v ansible_config:yes \
  -v rte_ip:<rte_ip> \
  -v snipeit:no \
  -v config:mpl-pip4 \
  -v device_ip:<device_ip> \
  dasharo-security/secure-boot.robot
```

Most flags are specific to the OSFV infrastructure. They are explained in the
repo's
[README](https://github.com/Dasharo/open-source-firmware-validation?tab=readme-ov-file#running-tests).

The `-L TRACE` option sets the log level to `TRACE` and the final argument
specifies the test suite that will be run.

To use QEMU execute this instead:

```bash
robot -L TRACE \
  -v ansible_config:yes \
  -v rte_ip:127.0.0.1 \
  -v snipeit:no \
  -v config:qemu \
  -v device_ip:<device_ip> \
  dasharo-security/secure-boot.robot
```

### Results

The tests were performed on MPL PIP44 running PIP40 Family BIOS V057. The BIOS
documentation can be found [here](https://www.mpl.ch/t24g4.html). Please note
that you need to be logged in to access the document.
The following images show the test suite results:
![uefi-sb-results-report](/img/uefi-sb-results-pt1.png)
![uefi-sb-results-report](/img/uefi-sb-results-pt2.png)

The results lead to the following conclusions:

- The state of UEFI Secure Boot functionality can be freely modified from the
  UEFI BIOS Menu, and it is correctly detected from the operating system.
- Verification of launched images works correctly when UEFI Secure Boot is
  enabled. The firmware allows the execution of files signed with the
  appropriate keys but blocks the booting of unsigned files or files signed with
  keys not present in the database (DB) or files with hashes not stored in the
  database (DB).
- The firmware correctly recognizes the chain of trust when intermediate
  certificates are used, allowing their use in the verification process.
- Keys intended for UEFI Secure Boot must be generated using the RSA
  cryptographic algorithm and sizes 2048, 3072, and 4096. Keys generated with
  the ECDSA cryptographic algorithm are not correctly supported.
- The firmware does not verify the expiration date of certificates during the
  verification of launched files. It means that enrolled certificates may expire
  and will not affect the ability to boot files verified by them. This is
  potentially dangerous: an expired certificate should theoretically not be used
  any longer. Therefore, its owner may cease to bother about the corresponding
  private key's privacy. Accepting an expired certificate risks using a public
  key for which the corresponding private key has been compromised.
- The firmware only allows the resetting of enrolled certificates when they
  have been added from the UEFI BIOS Menu. If they are added from the operating
  system, the certificates are marked as External, and only a full firmware
  reset (for example, by removing the CMOS battery) allows their removal.
- Certificates enrolled through the [Automatic Certificate
  Provisioning]((https://github.com/Wind-River/meta-secure-core/tree/master/meta-efi-secure-boot#automatic-certificate-provision))
  method are correctly used to verify launched files.
- The [sbctl](https://github.com/Foxboron/sbctl) tool can be used to manage UEFI
  Secure Boot certificates.
- Automatic tests of the sbctl tool and the Automatic Certificate Provisioning
  methods have been omitted due to their logic, assuming that firmware can
  remove certificates enrolled this way from the UEFI BIOS Menu.

The conclusions allowed us to proceed with UEFI Secure Boot integration in the
Yocto layer.

## Integrating UEFI Secure Boot into a Yocto layer

Integrating UEFI Secure Boot into an existing Yocto layer is possible by using
the [meta-secure-core](https://github.com/Wind-River/meta-secure-core) layer in
your build. Its sublayer – `meta-efi-secure-boot` introduces mechanisms that
allow verifying various files used in the boot process. It offers two
technologies increasing security:

- UEFI Secure Boot, which verifies images loaded by UEFI firmware against
  certificates enrolled into it.
- MOK (Machine Owner Key) Secure Boot, which extends UEFI Secure Boot by
  introducing user-added Machine Owner Keys.

### Custom certificates

UEFI Secure Boot allows the user to enroll custom certificates which will be
used to verify images. The certificates can be loaded automatically thanks to
the Automatic Certificate Provisioning procedure provided by `meta-secure-core`.
The procedure uses `LockDown.efi`, which can only be executed when UEFI Secure
Boot is disabled. The provisioning process looks the following way:

- Secure Boot is manually disabled by the user.
- BIOS boots `LockDown.efi`.
- `LockDown.efi` loads the new certificates, which are built into it during
  build, into BIOS.

<!--
                    +---------------+
+------------+      |               |
|            +---- >+ LockDown.efi  |
|  BIOS      |      +---------------+
|(setup mode)|      |  Custom certs |
+------------+      +--------+------+
| (waiting   |               |
| for certs) |< -------------+
+------------+

ditaa image.fig  auto-cert-provisioning.png

-->

![UEFI Secure Boot boot process](/img/auto-cert-provisioning.png)

The boot process looks the following way:

- BIOS verifies GRUB against the DB key.
- GRUB verifies the kernel, `grub.cfg` and `grubenv` against a GPG key used in
  the build process.
- GRUB loads the kernel.

If any of the checks fail, the respective file cannot be booted. This mechanism
increases the system's security by making sure that the firmware does not boot
untrusted files.

<!--
                                         GPG key     +--------+
                                       +----------- >+ kernel |
                                       |             +--------+
+----------------+                +----+-+
|    BIOS        |      DB key    | GRUB |   GPG key  +----------+
|                +-------------- >+      +---------- >+ grub.cfg |
+----------------+                +--+---+            +----------+
                                     |
                                     | GPG key  +----------+
                                     +-------- >+ grubenv  |
                                                +----------+

ditaa image.fig uefi-sb-boot.png

-->

![UEFI Secure Boot boot process](/img/uefi-sb-boot.png)

### Implementation

To integrate the mechanisms available in `meta-secure-core` we needed to
integrate that layer into our build. We use
[kas-container](https://github.com/siemens/kas/blob/master/kas-container) to set
up bitbake projects.

In the kas configuration file we added the following to the `repos` section:

```yaml
meta-secure-core:
url: https://github.com/Wind-River/meta-secure-core.git
refspec: 8dc9f1b4a735eccee65a8896760e473e110d147e
layers:
    meta-efi-secure-boot:
    meta:
    meta-signing-key:
```

We defined `meta-secure-core` variables in the layer's `local.conf`:

```conf
# UEFI Secure Boot variables
# Use only UEFI Secure Boot without MOK Secure Boot
UEFI_SELOADER = "0"
GRUB_SIGN_VERIFY = "1"
UEFI_SB = "1"
MOK_SB = "0"

# We want grub-efi from meta-efi-secure-boot to install bootfiles under
# /boot/EFI/BOOT
EFI_BOOT_PATH = "/boot/EFI/BOOT"

DISTRO_FEATURES_NATIVE:append = " efi-secure-boot"
DISTRO_FEATURES:append = " efi-secure-boot modsign"
MACHINE_FEATURES_NATIVE:append = " efi"
MACHINE_FEATURES:append = " efi"

DEBUG_FLAGS:forcevariable = ""
IMAGE_INSTALL:append = " kernel-image-bzimage"
```

`UEFI_SELOADER` is a flag, which enables the SELoader, which is a bootloader
used in MOK Secure Boot. Setting `MOK_SB` enables MOK Secure Boot. Since we did
not want that, we set both flags to `0`. When `GRUB_SIGN_VERIFY` is set all GRUB
components are signed during build and verified by GRUB during the boot process.
Aside from setting the flags mentioned above, we also defined
[features](https://docs.yoctoproject.org/4.3.3/ref-manual/features.html#features),
which help Yocto work out which packages to include in the image and how certain
recipes should be built. The `efi` feature adds support for booting through EFI.
`efi-secure-boot` supports the UEFI Secure Boot mechanism.

We had to install the `efi-secure-boot` packagegroup into the image:

```bitbake
IMAGE_INSTALL:append = " \
    packagegroup-efi-secure-boot \
"
```

The packagegroup consists of, among other packages:

- `grub-efi`, which is needed to sign and verify grub components
- `mokutil`, which can be used on a booted system to verify the state of Secure
  Boot

We used the `bootimg-efi` wic plugin to set up a UEFI-compliant image. This
required us to define the
[IMAGE_BOOT_FILES](https://docs.yoctoproject.org/singleindex.html#term-IMAGE_BOOT_FILES),
which lists files that should be installed into the boot partition by the wic
tool. We defined it in `kas.conf`. Note that the value of this variable heavily
depends on used system's boot partition layout:

```conf
IMAGE_BOOT_FILES = " \
  bootfiles/EFI/BOOT/grubx64.efi;EFI/BOOT/bootx64.efi \
  bootfiles/EFI/BOOT/grubenv*;EFI/BOOT/
  bootfiles/EFI/BOOT/grub.cfg*;EFI/BOOT/
  bootfiles/EFI/BOOT/x86_64-efi/*;EFI/BOOT/x86_64-efi/ \
  bzImage-initramfs-${MACHINE}.bin;bzImage-initramfs \
  bzImage-initramfs-${MACHINE}.bin.sig;bzImage-initramfs.sig \
"
```

At this point, we encountered several problems with our build.

With `GRUB_SIGN_VERIFY` variable enabled, every GRUB component needed to be
signed so that grub could use it. The recipes from `meta-efi-secure-boot` take
care of generating the signatures. However, the `grubenv` signature was missing
from our output files.  `grubenv` is a file, which allows defining environment
variables for GRUB. As it turns out, the layer does not automatically sign that
file. We had to append that feature to the `grub-efi` recipe:

```bitbake
# grub-efi_%.bbappend

fakeroot python do_sign:append:class-target() {
    uks_bl_sign(dir + 'grubenv', d)
}

fakeroot do_chownboot:append() {
    chown root:root -R "${D}${EFI_BOOT_PATH}/grubenv${SB_FILE_EXT}"
}

do_deploy:append:class-target () {
    # deploy missing grubenv.sig file
    install -m 0600 "${D}${EFI_BOOT_PATH}/grubenv${SB_FILE_EXT}" "${DEPLOYDIR}"
}
```

Another issue was that Poky has its own `grub-efi` recipe, where it installs its
own `grub-efi-grubx64.efi` file. It conflicted with the boot files from
`meta-efi-secure-boot`, so we had to remove it:

```bitbake
# grub-efi_%.bbappend

do_deploy:append:class-target () {
    # remove default grub-efi-grubx64.efi file deployed by .bb from poky; when
    # it is left in deploydir, bootimg-efi plugin picks it up after cloning
    # files from IMAGE_BOOT_FILES list
    # see: https://git.yoctoproject.org/poky/tree/scripts/lib/wic/plugins/source/bootimg-efi.py?id=00c04394cbc5ecaced7cc1bc8bc8787e621f987d#n360
    rm -rf ${DEPLOYDIR}/${GRUB_IMAGE_PREFIX}${GRUB_IMAGE}
}
```

Now the files get signed automatically during the build. They are deployed along
with their signatures. By default, they are signed using the sample keys from
[meta-signing-key](https://github.com/Wind-River/meta-secure-core/tree/master/meta-signing-key/files/uefi_sb_keys).
This is extremely unsafe and should only be used for testing. In public key
infrastructure a private key should never be made public. The person who knows
the private key corresponding to a certificate can impersonate the certificate's
owner. Therefore you should always generate your own private-public key pair and
keep the private part safe. `meta-signing-key` provides a
[script](https://github.com/Wind-River/meta-secure-core/blob/master/meta-signing-key/scripts/create-user-key-store.sh),
which generates custom user keys.

The script will prompt the user to provide boot key information, such as the
email address and password. Note that not all generated keys will be used with
UEFI Secure Boot, as some of them are only compatible with MOK Secure Boot.
The script finishes by printing lines to be added to your layer's configuration.

```sh
Enter Boot GPG keyname (use dashes instead of spaces) [default: BOOT-SecureCore]:
Enter Boot GPG e-mail address [default: SecureCore@foo.com]:
Enter Boot GPG comment [default: Bootloader Signing Key]:
Using boot loader gpg name: BOOT-SecureCore
Using boot loader gpg email: SecureCore@foo.com
Using boot loader gpg comment: Bootloader Signing Key
Enter boot loader GPG passphrase: pass
Enter boot loader locked configuration password(e.g. grub pw): pass
Creating the user keys for UEFI Secure Boot

(...)

## The following variables need to be entered into your local.conf
## in order to use the new signing keys:

MASTER_KEYS_DIR = "/path/to/user-keys"

BOOT_KEYS_DIR = "${MASTER_KEYS_DIR}/boot_keys"
MOK_SB_KEYS_DIR = "${MASTER_KEYS_DIR}/mok_sb_keys"
SYSTEM_TRUSTED_KEYS_DIR = "${MASTER_KEYS_DIR}/system_trusted_keys"
SECONDARY_TRUSTED_KEYS_DIR = "${MASTER_KEYS_DIR}/secondary_trusted_keys"
MODSIGN_KEYS_DIR = "${MASTER_KEYS_DIR}/modsign_keys"
UEFI_SB_KEYS_DIR = "${MASTER_KEYS_DIR}/uefi_sb_keys"
GRUB_PUB_KEY = "${MASTER_KEYS_DIR}/boot_keys/boot_pub_key"
GRUB_PW_FILE = "${MASTER_KEYS_DIR}/boot_keys/boot_cfg_pw"

BOOT_GPG_NAME = "BOOT-SecureCore"
BOOT_GPG_PASSPHRASE = "pass"
SIGNING_MODEL = "user"

## Please save the values above to your local.conf
## Or copy and uncomment the following line:
# require /path/to/user-keys/keys.conf
```

Follow the instructions above to use the generated keys in your build.

## Demo

The demo below shows the process of enrolling custom keys and booting the signed
system. The following steps are performed:

- UEFI Secure Boot is disabled
- UEFI is set to Setup Mode
- The system is booted
- Automatic Certificate Provisioning is triggered
- After restart UEFI Secure Boot is enabled
- The system is booted correctly
- Another system, which is not signed by the custom keys, is selected
- The system cannot boot due to incorrect signatures

[![asciicast](https://asciinema.org/a/654241.svg)](https://asciinema.org/a/654241)

## Summary

We managed to show that utilizing UEFI Secure Boot on MPL PIP4x platforms is
feasible, although some features, such as verifying that the certificate used to
sign bootable files has not expired, are not supported. The `meta-secure-core`
layer helps developers implement automatic file signing and verification with
relative ease.

UEFI Secure Boot integration and all other features described in this post will
be featured in [Zarhus OS](https://docs.zarhus.com/) - a cutting-edge, adaptable
and secure operating system designed for embedded systems, which is being
developed by 3mdeb.

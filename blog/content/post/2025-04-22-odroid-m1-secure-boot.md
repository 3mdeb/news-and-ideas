---
title: Enabling Secure Boot on ODROID M1 (RK3568B)
abstract: 'This blog post describes how to enable Secure Boot on
ODROID-M1(RK3568B). Read how to write hash of public key to OTP memory, how to
sign loader and how to build signed U-Boot with enabled signature verification.'
cover: /covers/rockchip-logo.jpg
author: michal.iwanicki
layout: post
published: true
date: 2025-04-22
archives: "2025"

tags:
  - bootloader
  - secure-boot
  - rockchip
  - u-boot
categories:
  - Firmware
  - Security

---

## Introduction

Recently, I was tasked with implementing Secure Boot on the ODROID M1
(RK3568B).
In this post, I will describe how I managed to store the hash of the public key
in the OTP memory and enabled verification of the pre-loader's signature
(Rockchip TPL + U-Boot SPL) as well as the verification of the U-Boot's
configuration by SPL, which includes hashes of all images contained in the FIT
image.

## Enabling Secure Boot

Enabling Secure Boot on ARM is based on storing the public key in a secure
place known by the BootROM so it can be used to verify the pre-loader
signature. Typically it is eFuse, OTP or PUF those are scarce and expensive
resources. On a RK3568 SoC, instead of storing the public key, we only store
its hash in OTP (One Time Programmable) memory, while the public key is
embedded inside the pre-loader, which contains TPL (Tertiary Program Loader)
and SPL (Secondary Program Loader).

When booting after Secure Boot is enabled, BootROM first calculates the hash of
the public key that's stored in the pre-loader and checks if it's identical to
the hash stored inside OTP memory. After successful hash verification, it uses
this key to verify TPL and SPL signatures. If signatures match, then Boot ROM
boots verified image. Verification process looks as on following
image[^rk-sig-ver-process]:

![Rockchip signature verification](/img/secure-boot-process.png)

### Plan

When starting this endeavor, I planned to achieve 2 things:

* Enable [stage 2 (TPL & SPL)](https://opensource.rock-chips.com/wiki_Boot_option#Boot_flow)
signature verification by BootROM
* Boot fairly new mainline U-Boot with stage 3 (U-Boot itself) verification by
U-Boot SPL

Most of this blog post deals with the first part, as it is the one that took me
the longest.
It can be split into a couple of stages:

* Generate RSA keys and certificate
* Build U-Boot SPL that can write hash to OTP
* Add previously generated public key to the U-Boot SPL signature node and sign
U-Boot
* Add `burn-key-hash = 0x1` parameter to the U-Boot SPL signature node
* Write U-Boot SPL and U-Boot to Odroid-M1
* Verify that Secure Boot was enabled

After booting, U-Boot SPL should detect `burn-key-hash` parameter in the
signature node during signature verification and initiate writing public key
hash to OTP memory, after which unsigned images shouldn't be able to boot.

### Preparation

#### Repositories

To complete this stage, I needed a couple of repositories:

* [Rockchip U-Boot](https://github.com/rockchip-linux/u-boot/tree/63c55618fbdc36333db4cf12f7d6a28f0a178017)
\- This U-Boot version contains a function that saves the hash of the public key
to OTP memory, to be exact, it's
[rsa_burn_key_hash](https://github.com/rockchip-linux/u-boot/blob/63c55618fbdc36333db4cf12f7d6a28f0a178017/lib/rsa/rsa-verify.c#L600).
[Hardkernel U-Boot](https://github.com/hardkernel/u-boot/tree/odroidm1-v2017.09)
also contains this functionality. I didn't test this version, but it should work
with minimal changes to other steps.
* [rkbin](https://github.com/rockchip-linux/rkbin/tree/a2a0b89b6c8c612dca5ed9ed8a68db8a07f68bc0)
\- Contains needed files: `Rockchip TPL`, `BL31`, `boot_merger` and `rk_sign_tool`.
* [upgrade_tool](https://github.com/hardkernel/rk3568-linux-tools/tree/1a32bc776af52494144fcef6641a73850cee628a/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool)
\- We need this version of the tool because `upgrade_tool` and `rkdeveloptool`
contained in the rkbin repository can't handle loaders generated with a new idb
header.

I used the newest commits available in those repositories.

#### Generating RSA Keys and certificate

To enable Secure Boot, I needed to generate RSA 2048-bit key. While the SoC
datasheet says that RK3568 `Supports up to 4096 bits PKA mathematical operations
for RSA/ECC` I had to use 2048 bits because it's the only key length accepted by
`rsa_burn_key_hash`:

```C
if (info->crypto->key_len != RSA2048_BYTES)
  return -EINVAL;
```

To generate RSA keys and certificates, I decided to use the `openssl` tool.

```shell
openssl genrsa -out keys/dev.key 2048
openssl rsa -in keys/dev.key -pubout -out keys/dev.pubkey
openssl req -batch -new -x509 -key keys/dev.key -out keys/dev.crt
```

#### Final directory structure

This is my final directory structure, which contains the needed repositories and
tools. I also created a symlink to upgrade_tool to make commands shorter.

```shell
tree -FL 1
./
├── Linux_Upgrade_Tool/
├── rkbin/
├── u-boot/
├── keys/
└── upgrade_tool -> Linux_Upgrade_Tool/upgrade_tool
```

#### Dependencies

Below are the packages needed to build U-Boot on Debian.

```shell
apt install gcc make bison flex libncurses-dev python3 python3-dev \
  python3-setuptools python3-pyelftools swig libssl-dev device-tree-compiler python2 bc
```

To build Rockchip U-Boot, I also needed a cross-compiler. By default, `make.sh`
script uses Linaro 6.3.1 toolchain. At first, I tried to use a cross-compiler
installed from the apt package manager, but unfortunately, the build ended in
errors.
Fixing one error led to another, so I chose to use
[Linaro](https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/)
compiler.

### Configuration

#### rkbin

In `rkbin/RKBOOT/RK3568MINIALL.ini`, I had to update FlashBoot to point to the
`u-boot-spl.bin` file. Later this `.ini` file will be used by the `boot_merger`
tool to create the `rk356x_spl_loader_v1.21.113.bin` file, containing U-Boot
SPL. It'll then be written to SPI flash memory.

```diff
diff --git a/RKBOOT/RK3568MINIALL.ini b/RKBOOT/RK3568MINIALL.ini
index ef6d071bc5ac..c80d817f4b94 100644
--- a/RKBOOT/RK3568MINIALL.ini
+++ b/RKBOOT/RK3568MINIALL.ini
@@ -15,7 +15,7 @@ NUM=2
 LOADER1=FlashData
 LOADER2=FlashBoot
 FlashData=bin/rk35/rk3568_ddr_1560MHz_v1.21.bin
-FlashBoot=bin/rk35/rk356x_spl_v1.13.bin
+FlashBoot=../u-boot/spl/u-boot-spl.bin
 [OUTPUT]
 PATH=rk356x_spl_loader_v1.21.113.bin
 [SYSTEM]
```

#### U-Boot

I had to update the cross-compiler path in the `CROSS_COMPILE_ARM64` variable in
the `make.sh` file in the U-Boot repository, so it pointed to where my
cross-compiler was installed.

```diff
-CROSS_COMPILE_ARM64=../prebuilts/gcc/linux-x86/aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
+CROSS_COMPILE_ARM64=/opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
```

ODROID-M1 uses RK3568B SoC, so I used `rk3568_defconfig` configuration file as a
base.

```shell
make rk3568_defconfig
```

SPL will store key's hash in OTP memory if the signature node containing the
public key has the property `burn-key-hash = 0x1`. To add a node with the public
key to SPL, we can use the `mkimage` tool. During my first attempt, I used a
tool from the mainline U-Boot that I had on hand because without changes to the
configuration, `mkimage` from the Rockchip repository cannot add the key.
Unfortunately, the created signature node had an incorrect format. I checked the
contents of the signature node using the command:

```shell
fdtget -p spl/u-boot-spl.dtb /signature/key-dev
```

In the left column is a signature node created using `mkimage` from
mainline U-Boot, and in the right column is the correct signature node created
with `mkimage` built from the Rockchip repository. The mainline U-Boot signature
node lacks some properties that the `rsa_burn_key_hash` function requires, e.g.,
`rsa,c`.

```text
required        required
algo            algo
rsa,r-squared   rsa,np
rsa,modulus     rsa,c
rsa,exponent    rsa,r-squared
rsa,n0-inverse  rsa,modulus
rsa,num-bits    rsa,exponent-BN
key-name-hint   rsa,exponent
                rsa,n0-inverse
                rsa,num-bits
                key-name-hint
```

To build `mkimage` from the Rockchip repository that can add a public key to
SPL, I had to set
[CONFIG_FIT_SIGNATURE](https://github.com/rockchip-linux/u-boot/blob/63c55618fbdc36333db4cf12f7d6a28f0a178017/Kconfig#L224)
and
[CONFIG_SPL_FIT_SIGNATURE](https://github.com/rockchip-linux/u-boot/blob/63c55618fbdc36333db4cf12f7d6a28f0a178017/Kconfig#L309)

### Building U-Boot

I used `make.sh` script to build U-Boot. The build was completed successfully
before setting the `FIT_SIGNATURE` and `SPL_FIT_SIGNATURE` variables. After
setting those variables, the `make.sh` script ended in error, but fortunately,
everything I needed was built correctly. The error only happened when trying to
add signatures to the image.
Build output should show `Platform RK3568 is build OK, with exist .config`
message along with either one of those errors:

* When there are no keys in `u-boot/keys` directory

  ```text
  ERROR: No keys/dev.key
  ```

* When there are keys in `u-boot/keys` directory

  ```text
  Failed: external offset 0x1000 overlaps FIT length 0x1200
  ./tools/mkimage Can't add hashes to FIT blob: -22
  ```

The files we need are `spl/u-boot-spl.dtb` and `u-boot.itb`.

Now it's time to add a public key to `u-boot-spl.dtb`

```shell
tools/mkimage -F -k ../keys -K spl/u-boot-spl.dtb -r u-boot.itb
FIT description: FIT Image with ATF/OP-TEE/U-Boot/MCU
Created:         Fri Apr 12 13:02:03 2024
(...)
 Default Configuration: 'conf'
 Configuration 0 (conf)
  Description:  rk3568-evb
  Kernel:       unavailable
  Firmware:     atf-1
  FDT:          fdt
  Loadables:    uboot
                atf-2
                atf-3
                atf-4
                atf-5
                atf-6
                optee
```

To verify whether the signature node with the public key was added to SPL, we
can use the `fdtget` command that I used [before](#u-boot).

Now that I had SPL with the public key, I needed to add the `burn-key-hash`
property to this node. When SPL sees this property, it'll try to write the
public key hash to OTP memory.

```shell
fdtput -tx spl/u-boot-spl.dtb /signature/key-dev burn-key-hash 0x1
```

After that, I created a new `u-boot-spl.bin` file.

```shell
cat spl/u-boot-spl-nodtb.bin spl/u-boot-spl.dtb > spl/u-boot-spl.bin
```

### Creating loader

In this step, I created a loader which will be used to write a pre-loader
(U-Boot TPL and SPL) to SPI flash memory.
I used the `boot_merger` tool from the rkbin repository to create a loader as
the one created when building U-Boot contains old SPL without a signature node.
To do that, I used `RKBOOT/RK3568MINIALL.ini` config file that was modified in
[configuration](#rkbin) step

```shell
tools/boot_merger RKBOOT/RK3568MINIALL.ini
********boot_merger ver 1.34********
Info:Pack loader ok.
```

There should now be a `rk356x_spl_loader_v1.21.113.bin` file in the rkbin
folder.
It should contain my pre-loader (TPL + SPL) and the `rk356x_usbplug_vX.Y.bin`
image that will allow me to write the pre-loader to SPI memory.

### Sending loader to ODROID

I needed to enter MaskROM mode on ODROID to write the pre-loader to SPI flash
memory. Restarting the device while pressing the recovery button is the easiest
way. This way, ODROID will try to boot the pre-loader from eMMC/SD memory.
If no eMMC/SD is connected, the platform will enter MaskROM mode.

#### Clearing SPI

This step could most likely be skipped. I'll describe it because during my
attempts to enable Secure Boot, I cleared SPI memory multiple times.
I used `upgrade_tool` from Hardkernel.

```shell
sudo ./upgrade_tool ef rkbin/rk356x_spl_loader_v1.21.113.bin
Using /home/user/odroid/Linux_Upgrade_Tool/config.ini
Program Log will save in the /root/upgrade_tool/log
Loading loader...
Erase flash ok.
```

On the UART console, there should be output from the loader:

```text
Boot1 Release Time: Apr 14 2023 10:04:54, version: 1.17
support nand flash type: slc
...nandc_flash_init enter...
No.1 FLASH ID:ff ff ff ff ff ff
sfc nor id: c2 25 38
read_lines: 2
UsbBoot ...8851
powerOn 906
```

Now restart the platform and enter MaskROM mode again.

#### Upgrading pre-loader

To upgrade the pre-loader, I had to send the loader to ODROID. The upgrade is
done with one command that first boots the `usbplug.bin` file embedded in the
loader image, which allows `upgrade_tool` to write the pre-loader to SPI flash
memory.

```shell
sudo ./upgrade_tool ul rkbin/rk356x_spl_loader_v1.21.113.bin
Using /home/user/odroid/Linux_Upgrade_Tool/config.ini
Program Log will save in the /root/upgrade_tool/log
Loading loader...
Support Type:RK3568    Loader ver:1.01 Loader Time:2024-04-11 12:37:19
Upgrade loader ok.
```

### Writing key hash to OTP

The pre-loader created in the previous step will write the hash to OTP memory
when it encounters the `burn-key-hash` property inside the `signature` node.
It'll only happen when trying to verify the signature of the next boot stage,
i.e., U-Boot.
In my case, there was nothing in SPI flash except the pre-loader, so I had to
also flash the U-Boot image. I decided to do it on an SD card because it was
easier and faster.
To do that, I created 3 partitions:

|  Partlabel   | Starting sector |  size  |
|--------------|-----------------|--------|
|      spl     |         64      |   4M   |
|    uboot     |      16384      |   4M   |
|     misc     |      24576      |   4M   |

* `spl` - I'll use this partition in later steps to write mainline U-Boot
pre-loader, i.e., `idbloader.img` file. In this step, it can remain empty.
* `uboot` - partition containing U-Boot. In this step, I also flashed
`u-boot.itb` image to this partition.
* `misc` - Rockchip U-Boot SPL needs this partition. Without it, booting fails
  before verification, and the key hash is written.

After inserting the SD card into ODROID-M1 and restarting it, I got this output
on UART console:

```text
U-Boot SPL board init
U-Boot SPL 2017.09-g63c55618fb-240223-dirty #iwans (Apr 11 2024 - 14:53:32)
Trying to boot from MMC2
No bootable slots found, use lastboot.
Trying fit image at 0x4000 sector
## Verified-boot: 0

sha256,rsa2048:dev
## Verified-boot: 0
RSA: Write RSA key hash successfully.
+
```

From this moment, ODROID stopped booting any image that wasn't signed with the
correct keys.

### Verification

To verify whether the platform verifies signatures, I tried to run unsigned
loader/pre-loader and ones signed with the wrong keys. We can also check if
Secure Boot is enabled by booting the ramboot loader, which contains TPL and the
`rk3568_ramboot_v1.08.bin` file.

#### Generating ramboot loader

To check the SecureMode state, we need to run the ramboot loader. To do that, I
used the `boot_merger` tool with the `RK3568MINIALL_RAMBOOT.ini` config file to
create `rk356x_ramboot_loader_v1.21.108.bin`:

```shell
tools/boot_merger RKBOOT/RK3568MINIALL_RAMBOOT.ini
Info:Pack loader ok.
```

#### Signing loader

Now we need to sign the generated `rk356x_ramboot_loader_v1.21.108.bin` loader.
To do that, I used `rk_sign_tool` from the rkbin repository.
First, I needed to configure this tool with the correct SoC and keys.

```shell
 tools/rk_sign_tool cc --chip 3568 && tools/rk_sign_tool lk --key ../keys/dev.key --pubkey ../keys/dev.pubkey
********sign_tool ver 1.4********
set chip is 3568
setting chip ok.
********sign_tool ver 1.4********
private key is ../keys/dev.key
public key is ../keys/dev.pubkey
loading key ok.
```

After which, I signed the loader.

```shell
tools/rk_sign_tool sl --loader rk356x_ramboot_loader_v1.21.108.bin
********sign_tool ver 1.4********
Loader is rk356x_ramboot_loader_v1.21.108.bin
signing usbhead...
failed to get key = sign_algo
signing flashhead...
failed to get key = sign_algo
signing rk356x_ramboot_loader_v1.21.108 ok
```

The loader was signed correctly even though the tool printed some failures.

#### Sending ramboot loader

I again used `upgrade_tool` to send the ramboot loader, but this time with the
`db` option.

```shell
./upgrade_tool db rkbin/rk356x_ramboot_loader_v1.21.108.bin
```

I got this output on the UART console.

```text
Boot1 Release Time: Apr 20 2021 18:00:11, version: 1.08 USB BOOT
ChipType = 0x18, 271
SecureMode = 1
atags_set_bootdev: ret:(0)
UsbBoot ...684
powerOn 931
```

Before writing hash to OTP memory, the ramboot loader returned `SecureMode = 0`.

## Mainline U-Boot with signature verification

Now that we have pre-loader (TPL + SPL) signature verification, we can use the
pre-loader to verify the next steps.

To complete this stage, I decided to use v2024.01
[mainline
U-Boot](https://github.com/3mdeb/u-boot/tree/2024.01-odroid-m1-sb-rk3568) with a
couple of changes. I also needed the rkbin repository, RSA keys, and certificate
(copied into the u-boot directory). It's possible to use the same key as earlier
or create a new one.

### U-Boot configuration

The main changes needed in my commit were just adding `signature` and
`u-boot-spl-pubkey-dtb` node in
[rockchip-u-boot.dtsi](https://github.com/3mdeb/u-boot/blob/b5f0de18708112ce61a56526e6081796045e1763/arch/arm/dts/rockchip-u-boot.dtsi)
and changing `CONFIG_SPL_STACK_R_MALLOC_SIMPLE_LEN` config variable to
`0x150000` to fix `alloc space exhausted` error when booting.

```text
U-Boot SPL 2024.01-dirty (Jan 01 1970 - 00:00:00 +0000)
Trying to boot from MMC2
alloc space exhausted
FIT buffer size: 1199104 bytes
Could not get FIT buffer of 1199104 bytes
        check CONFIG_SPL_SYS_MALLOC_SIZE
```

To configure U-Boot, it's enough to use
[odroid-m1-sb-rk3568_defconfig](https://github.com/3mdeb/u-boot/blob/2024.01-odroid-m1-sb-rk3568/configs/odroid-m1-sb-rk3568_defconfig)
config and set couple variables.

```shell
export CROSS_COMPILE=aarch64-linux-gnu-
export BL31=<path/to/rkbin>/bin/rk35/rk3568_bl31_v1.44.elf
export ROCKCHIP_TPL=<path/to/rkbin>/bin/rk35/rk3568_ddr_1560MHz_v1.21.bin
```

I used the `gcc-aarch64-linux-gnu` cross-compiler from the Debian package
manager this time.

### Build

After configuration, we build it using `make`. It should build a signed U-Boot
with a public key embedded inside SPL.

```text
make odroid-m1-sb-rk3568_defconfig
make -j$(nproc)
(...)
 Default Configuration: 'config-1'
 Configuration 0 (config-1)
  Description:  rk3568-odroid-m1.dtb
  Kernel:       unavailable
  Firmware:     atf-1
  FDT:          fdt-1
  Loadables:    u-boot
                atf-2
                atf-3
                atf-4
                atf-5
                atf-6
  Sign algo:    sha256,rsa2048:dev
  Sign value:   c05e2589eb863bfb9b5b5c87ea9f99042c4cb78797a6cd0d772a68bfac21bc621790cb977bd414928b7b88a50273d336aea4afb7a1a4008834e1c3c18eb08fb617bb71205e6773904f42e81364a15eb5c581425f22d6be5e30dd1a44cbe7fa626b7fb34a3eb742c03b0ec47c19dd957358949764f82ffb24f9359efe083ea04ada512f8cab0f469cac28d08da3dfffbde1516cb225b3011f36495c959793d11b8c4bde234caca5ac1d779f7983dcf865be92c2ac3300e4cdf536e51fa398c8930dafbdd0a3258ba4704eebc063e5e57533a962a2da5c7eaf447b1244f9720adb3dc775d95b4c6dc99f6b9bd73ebe992095429510b86dd5ac912c24a8cec64841
  Timestamp:    Mon May 27 15:08:11 2024
Signature written to 'u-boot.itb', node '/configurations/config-1/signature'
  OFCHK   .config
```

By default, `odroid-m1-sb-rk3568_defconfig` enables signing of only
configuration. Anyone interested why can read more on
[https://github.com/u-boot/u-boot](https://github.com/u-boot/u-boot/blob/master/doc/usage/fit/signature.rst#signed-configurations).

### Signing idbloader

Signing idbloader is similar to the [Signing Loader](#signing-loader) section
except with the `sb --idb` argument. It's important to remember to sign
idbloader with the same keys used in that section (in case the current ones are
different).

```shell
tools/rk_sign_tool sb --idb ../u-boot/idbloader.img
********sign_tool ver 1.4********
IDB binary is ../u-boot/idbloader.img
signing idbhead...
failed to get key = sign_algo
signing idbloader ok
```

You can verify whether `idbloader.img` is signed correctly by using:

```shell
tools/rk_sign_tool vb --idb ../u-boot/idbloader.img
********sign_tool ver 1.4********
IDB binary is ../u-boot/idbloader.img
verifying idbloader ok
```

In case of an unsigned file, the command would return an `invalid idblock tag`.

### U-Boot Verification

To check if SPL is signed correctly and verifies U-Boot correctly, I have
written `idbloader.img` file to `spl` partition created in [Writing key hash to
OTP](#writing-key-hash-to-otp). I also flashed the `u-boot.itb` file to the
`uboot` partition.

After writing the needed files and inserting the SD card into ODROID, I
restarted the platform while pressing the recovery button.

```text
U-Boot SPL 2024.01-dirty (Apr 11 2024 - 09:15:28 +0200)
Trying to boot from MMC2
## Checking hash(es) for config config-1 ... sha256,rsa2048:dev+ OK
## Checking hash(es) for Image atf-1 ... sha256+ OK
## Checking hash(es) for Image u-boot ... sha256+ OK
## Checking hash(es) for Image fdt-1 ... sha256+ OK
## Checking hash(es) for Image atf-2 ... sha256+ OK
## Checking hash(es) for Image atf-3 ... sha256+ OK
## Checking hash(es) for Image atf-4 ... sha256+ OK
## Checking hash(es) for Image atf-5 ... sha256+ OK
## Checking hash(es) for Image atf-6 ... sha256+ OK
(...)
=>
```

The expected output should contain `sha256,rsa2048:dev+ OK`, which means the
signature was verified correctly (`+` sign).

## What's next

While I had managed to enable Secure Boot on Odroid, it would be good to test
its security and capabilities more thoroughly.
Some of the questions that I would like to find answers to are whether there
really isn't any way to overwrite the key hash stored in OTP and if it's
possible to store more than one.
OTP has 8k bits of memory based on the RK3568 datasheet, while hashes are only
256 bits, so theoretically, we could store 32 different hashes.

A good next step would be to have an upstream capability of writing hash to OTP
from Rockchip U-Boot to mainline U-Boot, simplifying the whole implementation.

## Conclusion

Please let us know your experience integrating and provisioning Root of Trust
and Chain of Trust technologies on ARM-based platforms, especially Rockchip.

For any questions or feedback, feel free to contact us at
<contact@3mdeb.com> or hop on our community channels:

- [Zarhus Matrix Workspace](https://matrix.to/#/#zarhus:matrix.3mdeb.com)
- join our [Zarhus Developers Meetup](https://events.dasharo.com/event/4/zarhus-developers-meetup-0x1)

To join the discussion.

[^rk-sig-ver-process]: http://resource.milesight-iot.com/files/Rockchip-Secure-Boot-Application-Note-V1.9.pdf#page=3

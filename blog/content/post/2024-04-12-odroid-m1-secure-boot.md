---
title: Enabling Secure Boot on ODROID M1 (RK3568B)
abstract: 'This blog post describes how to enable Secure Boot on
ODROID-M1(RK3568B). Read how to write hash of public key to OTP memory, how to
sign loader and how to build signed U-Boot with enabled signature verification.'
cover: /covers/rockchip-logo.jpg
author: michal.iwanicki
layout: post
published: true
date: 2024-04-12
archives: "2024"

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
configuration by SPL which includes hashes of all images contained in the FIT
image.

## Enabling Secure Boot

Enabling Secure Boot is based on storing the public key in a secure place
known by the Boot ROM so it can be used to verify pre-loader signature.
On a RK3568 SoC instead of storing the public key we only store its hash in OTP
(One Time Programmable) memory, while the public key is embedded inside the
pre-loader which contains TPL and SPL.

When booting after Secure Boot is enabled Boot ROM first calculates hash of the
public key that's stored in the pre-loader and checks if it's identical to the
hash stored inside OTP memory. After successful hash verification, it uses this
key to verify TPL and SPL signatures. If signatures match then Boot ROM boots
verified image.

![Rockchip signature verification](/img/rockchip_secure_boot.jpg)

### Preparation

#### Repositories

To complete this stage I needed a couple of repositories:

* [Rockchip U-Boot](https://github.com/rockchip-linux/u-boot/) - This U-Boot
version contains a function that saves the hash of the public key to OTP memory,
to be exact it's
[rsa_burn_key_hash](https://github.com/rockchip-linux/u-boot/blob/63c55618fbdc36333db4cf12f7d6a28f0a178017/lib/rsa/rsa-verify.c#L600).\
[Hardkernel U-Boot](https://github.com/hardkernel/u-boot/tree/odroidm1-v2017.09)
also contains this functionality. I didn't test this version but it should work
with minimal changes to other steps.
* [rkbin](https://github.com/rockchip-linux/rkbin) - Contains needed files,
`Rockchip TPL`, `BL31`, `boot_merger` and `rk_sign_tool`.
* [upgrade_tool](https://github.com/hardkernel/rk3568-linux-tools/tree/master/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool) -
We need this version of the tool because `upgrade_tool` and `rkdeveloptool`
contained in rkbin repository can't handle loaders generated with new idb
header.

I used the newest commits in default branches. Below are hashes of commits used.

* U-Boot - 63c55618fbdc36333db4cf12f7d6a28f0a178017
* rkbin - a2a0b89b6c8c612dca5ed9ed8a68db8a07f68bc0
* upgrade_tool - 1a32bc776af52494144fcef6641a73850cee628a

#### Generating RSA Keys and certificate

To enable Secure Boot I needed to generate RSA 2048 bit key. While SoC datasheet
says that RK3568
`Supports up to 4096 bits PKA mathematical operations for RSA/ECC` I had to use
2048 bits because it's the only key length accepted by `rsa_burn_key_hash`:

```C
if (info->crypto->key_len != RSA2048_BYTES)
  return -EINVAL;
```

To generate RSA keys and certificate I decided to use `openssl` command.

```shell
openssl genrsa -out keys/dev.key 2048
openssl rsa -in keys/dev.key -pubout -out keys/dev.pubkey
openssl req -batch -new -x509 -key keys/dev.key -out keys/dev.crt
```

#### Final directory structure

This is my final directory structure that contains needed repositories and
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

Below are packages needed to build U-Boot on Debian 11 (bullseye) OS.

```shell
apt install gcc make bison flex libncurses-dev python3 python3-dev \
  python3-setuptools python3-pyelftools swig libssl-dev device-tree-compiler python2 bc
```

To build Rockchip U-Boot I also needed cross-compiler. In `make.sh` file u-boot
uses Linaro 6.3.1 toolchain. At first, I tried to use cross-compiler installed
from apt package manager but unfortunately build ended in errors. Fixing one
error led to another so I chose to use
[Linaro](https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/)
compiler.

### Configuration

#### rkbin

In `rkbin/RKBOOT/RK3568MINIALL.ini` I had to update FlashBoot so it points to
`u-boot-spl.bin` file. Later this `.ini` file will be used by `boot_merger` tool
to create `rk356x_spl_loader_v1.21.113.bin` file which will contain U-Boot SPL.
It'll then be written to SPI flash memory.

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

I had to update cross-compiler path in `CROSS_COMPILE_ARM64` variable in
`make.sh` file in U-Boot repository so it pointed to where my cross-compiler was
installed.

```diff
-CROSS_COMPILE_ARM64=../prebuilts/gcc/linux-x86/aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
+CROSS_COMPILE_ARM64=/opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
```

ODROID-M1 uses RK3568B SoC so I used `rk3568_defconfig` configuration file as
base.

```shell
make rk3568_defconfig
```

SPL will store the hash of the key in OTP memory if the signature node
containing the public key has the property `burn-key-hash = 0x1`. To add
a node with the public key to SPL we can use the `mkimage` tool. During my
first attempt, I used tool from the mainline U-Boot that I had on hand
because without changes to the configuration `mkimage` from the Rockchip
repository does not have the capability to add the key.
Unfortunately, the created signature node had an incorrect format.
I checked the contents of the signature node using the command:

```shell
fdtget -p spl/u-boot-spl.dtb /signature/key-dev
```

In the left column is signature node that was created by using `mkimage` from
mainline U-Boot and in the right column is correct signature node created
with `mkimage` built from Rockchip repository. Mainline U-Boot signature node
lacks couple of properties that `rsa_burn_key_hash` function requires
e.g. `rsa,c`.

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

To build `mkimage` that can add public key to SPL I had to set
[CONFIG_FIT_SIGNATURE](https://github.com/rockchip-linux/u-boot/blob/63c55618fbdc36333db4cf12f7d6a28f0a178017/Kconfig#L224).
Additionally I also set
[CONFIG_SPL_FIT_SIGNATURE](https://github.com/rockchip-linux/u-boot/blob/63c55618fbdc36333db4cf12f7d6a28f0a178017/Kconfig#L309)

### Building U-Boot

I used `make.sh` script to build U-Boot. Before setting `FIT_SIGNATURE` and
`SPL_FIT_SIGNATURE` variables build completed successfully, after setting those
variables `make.sh` script ends in error but fortunately everything I needed
was built correctly. Error only happened after U-Boot was built when trying to
add signatures to image. Build output should show
`Platform RK3568 is build OK, with exist .config` message along with error:

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

Now it's time to add public key to u-boot-spl.dtb

```shell
tools/mkimage -F -k ../keys -K spl/u-boot-spl.dtb -r u-boot.itb
FIT description: FIT Image with ATF/OP-TEE/U-Boot/MCU
Created:         Fri Apr 12 13:02:03 2024
 Image 0 (uboot)
  Description:  U-Boot
  Created:      Fri Apr 12 13:02:03 2024
  Type:         Standalone Program
  Compression:  gzip compressed
  Data Size:    590701 Bytes = 576.86 KiB = 0.56 MiB
  Architecture: AArch64
  Load Address: 0x00a00000
  Entry Point:  unavailable
  Hash algo:    sha256
  Hash value:   646283aaf9152fb852230b29261f97645526b24ae8e1bff3204dd1cac1cb7117
 Image 1 (atf-1)
  Description:  ARM Trusted Firmware
  Created:      Fri Apr 12 13:02:03 2024
  Type:         Firmware
  Compression:  gzip compressed
  Data Size:    57097 Bytes = 55.76 KiB = 0.05 MiB
  Architecture: AArch64
  Load Address: 0x00040000
  Hash algo:    sha256
  Hash value:   6b7aa1822c907c53c1dbd8f6afe1f25c62592f940fd853892ed3b1a64afabbc0
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

To verify whether signature node with public key was added to SPL we can use
`fdtget` command that I used [before](#u-boot).

Now that I had SPL with public key I needed to add `burn-key-hash` property
to this node. When SPL sees this property it'll try to write hash of public key
to OTP memory.

```shell
fdtput -tx spl/u-boot-spl.dtb /signature/key-dev burn-key-hash 0x1
```

After that I created new `u-boot-spl.bin` file

```shell
cat spl/u-boot-spl-nodtb.bin spl/u-boot-spl.dtb > spl/u-boot-spl.bin
```

### Creating Loader

To create loader I used `boot_merger` tool from rkbin repository. Loader that
was created when building u-boot contains old SPL without signature node so I
needed to create new one. To do that I used `RKBOOT/RK3568MINIALL.ini` config
file that was modified in [configuration](#rkbin) step

```shell
tools/boot_merger RKBOOT/RK3568MINIALL.ini
********boot_merger ver 1.34********
Info:Pack loader ok.
```

There should now be `rk356x_spl_loader_v1.21.113.bin` file in rkbin folder.

### Sending loader to ODROID

To update/write SPL to SPI flash memory I needed to enter MaskROM mode on
ODROID. Easiest way to do that is to restart device while pressing recovery
button. This way ODROID will try to load SPL from eMMC/SD memory. If there is
no eMMC/SD connected then platform will enter MaskROM mode.

#### Clearing SPI

This step could most likely be skipped. I'll describe it because during my tries
to enable Secure Boot I cleared SPI memory multiple times.
I used `upgrade_tool` from hardkernel.

```shell
sudo ./upgrade_tool ef rkbin/rk356x_spl_loader_v1.21.113.bin
Using /home/user/odroid/Linux_Upgrade_Tool/config.ini
Program Log will save in the /root/upgrade_tool/log
Loading loader...
Erase flash ok.
```

On UART console there should be output from loader:

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

Now restart platform and enter MaskROM mode again.

#### Upgrading loader

Upgrading loader was very easy and was done in just one command.

```shell
sudo ./upgrade_tool ul rkbin/rk356x_spl_loader_v1.21.113.bin
Using /home/user/odroid/Linux_Upgrade_Tool/config.ini
Program Log will save in the /root/upgrade_tool/log
Loading loader...
Support Type:RK3568    Loader ver:1.01 Loader Time:2024-04-11 12:37:19
Upgrade loader ok.
```

### Writing key hash to OTP

If there was U-Boot in SPI memory then SPL should try to boot it and should
write key hash into OTP memory and write `RSA: Write RSA key hash successfully.`
to UART console if writing was successfull.

In my case there was nothing in SPI flash so I had to also flash U-Boot image.
I decided to do it on SD card. To do that I created 3 partitions:

|  Partlabel   | Starting sector |  size  |
|--------------|-----------------|--------|
|      spl     |         64      |   4M   |
|    uboot     |      16384      |   4M   |
|     misc     |      24576      |   4M   |

`spl` partition will be used later to write `idbloader.img`. SPL needs `uboot`
and `misc` partition to correctly try to boot U-Boot and write key hash to OTP
memory.

I flashed `u-boot.itb` image to `uboot` partition and left `mics` partition
empty.

```shell
sudo dd if=u-boot.itb of=/dev/disk/by-partlabel/uboot
```

After inserting SD card into ODROID-M1 and restarting it I got this output on
UART console:

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

From this moment ODROID stopped booting any image that wasn't signed with
correct keys.

### Verification

To verify whether platform really verifies signatures I tried to run unsigned
loader/pre-loader and also ones signed with wrong keys.

#### Generating ramboot loader

To check SecureMode state we need to run ramboot loader. To do that I used
`boot_merger` tool with `RK3568MINIALL_RAMBOOT.ini` config file

```shell
tools/boot_merger RKBOOT/RK3568MINIALL_RAMBOOT.ini
```

#### Signing loader

Now we need to sign generated `rk356x_ramboot_loader_v1.21.108.bin` loader.
To do that I used `rk_sign_tool` from rkbin repository.
First I needed to configure this tool with correct SoC and keys

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

After which I signed loader.

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

#### Sending ramboot loader

Now I sent ramboot loader to ODROID.

```shell
./upgrade_tool db rkbin/rk356x_ramboot_loader_v1.21.108.bin
```

On UART console I had gotten this output

```text
Boot1 Release Time: Apr 20 2021 18:00:11, version: 1.08 USB BOOT
ChipType = 0x18, 271
SecureMode = 1
atags_set_bootdev: ret:(0)
UsbBoot ...684
powerOn 931
```

Before writing hash to OTP memory ramboot loader returned `SecureMode = 0`.

## Mainline U-Boot with signature verification

Now that we have pre-loader (TPL + SPL) signature verification we can use
pre-loader to verify next steps.

To complete this stage I decided to use
[mainline U-Boot](https://github.com/u-boot/u-boot). I also needed rkbin
repository and RSA keys and certificate. It's possible to use the same key as
earlier or create new one.

Keys and certificates should be copied to u-boot directory.
I checked out tag `v2024.01` in U-Boot repository.

### U-Boot configuration

To build U-Boot I used `odroid-m1-rk3568_defconfig` configuration. The only
change I needed to make to this configuration was changing
`CONFIG_SPL_STACK_R_MALLOC_SIMPLE_LEN` to `0x150000`. Without this change
it's impossible to boot U-Boot:

```text
U-Boot SPL 2024.01-dirty (Jan 01 1970 - 00:00:00 +0000)
Trying to boot from MMC2
alloc space exhausted
FIT buffer size: 1199104 bytes
Could not get FIT buffer of 1199104 bytes
        check CONFIG_SPL_SYS_MALLOC_SIZE
```

To add signature verification I needed to add `signature` node in configuration
node and also `u-boot-spl-pubkey-dtb` node to automatically add public key
to SPL. Changes needed to `arch/arm/dts/rockchip-u-boot.dtsi` file are below

```diff
diff --git a/arch/arm/dts/rockchip-u-boot.dtsi b/arch/arm/dts/rockchip-u-boot.dtsi
index c8c928c7e508..0c176a07e575 100644
--- a/arch/arm/dts/rockchip-u-boot.dtsi
+++ b/arch/arm/dts/rockchip-u-boot.dtsi
@@ -30,6 +30,15 @@
 			};
 #endif
 			u-boot-spl {
+				type = "section";
+
+				u-boot-spl-nodtb {
+				};
+				u-boot-spl-pubkey-dtb {
+					algo = "sha256,rsa2048";
+					key-name-hint = "dev";
+					required = "conf";
+				};
 			};
 		};

@@ -162,6 +171,12 @@
 					fit,firmware = "op-tee", "u-boot";
 #endif
 					fit,loadables;
+
+					signature {
+						algo = "sha256,rsa2048";
+						key-name-hint = "dev";
+						sign-images = "fdt", "firmware", "loadables";
+					};
 				};
 			};
 		};
```

Before building U-Boot I also needed to set couple variables

```shell
export CROSS_COMPILE=aarch64-linux-gnu-
export BL31=<path/to/rkbin>/bin/rk35/rk3568_bl31_v1.44.elf
export ROCKCHIP_TPL=<path/to/rkbin>/bin/rk35/rk3568_ddr_1560MHz_v1.21.bin
```

This time I used `gcc-aarch64-linux-gnu` cross-compiler from Debian package
manager.

### Signing U-Boot

To sign U-Boot I used mkimage:

```shell
tools/mkimage -F -k . u-boot.itb
FIT description: FIT image for U-Boot with bl31 (TF-A)
Created:         Tue Apr 16 17:37:12 2024
 Image 0 (u-boot)
  Description:  U-Boot
  Created:      Tue Apr 16 17:37:12 2024
  Type:         Standalone Program
  Compression:  uncompressed
  Data Size:    854080 Bytes = 834.06 KiB = 0.81 MiB
  Architecture: AArch64
  Load Address: 0x00a00000
  Entry Point:  0x00a00000
  Hash algo:    sha256
  Hash value:   c51061551a3183de5b1d2c7ec792d782af89530663ea9bd6a47c6e2e3340b99f
(...)
 Image 7 (fdt-1)
  Description:  fdt-rk3568-odroid-m1
  Created:      Tue Apr 16 17:37:12 2024
  Type:         Flat Device Tree
  Compression:  uncompressed
  Data Size:    79264 Bytes = 77.41 KiB = 0.08 MiB
  Architecture: Unknown Architecture
  Hash algo:    sha256
  Hash value:   d3a940c539c62eb5702efafe73a41fb4f4a25c00db556ba7e33d2f86f1f18643
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
  Sign value:   17f41ebae64c17bac98ac03220048c0c87cf82ccd8a145ab828f766a07a0526a88d9cdf2699422b99b9ad6ba6981921d1ace9e938a8c94cd8c9f9c032a8422666fd076efb21e62f8311b5443245cd7aa78ecedce13f463a9dadec0635d9c63dd195d8bf948e2abd79f3b252aa71e34719bb9debd5bece717661d6128fe68c9b98dbb2f429abc00c2b7e5bee7cdda2fed1ac95c5dc378d69cc06448de68e3588acfc1055af96193866be383b3c48e7946dafe214d634a597aaae84496c1e53259078d34181de32fb7a9c902540bf891c4d31e6ba956a31b875123e90cb4430d093895b218f4aba6a361a0e8e7cf339e60c8eb38ad38480df171c082e1a578f692
  Timestamp:    Tue Apr 16 17:43:41 2024
Signature written to 'u-boot.itb', node '/configurations/config-1/signature'
```

### Signing idbloader

To sign idbloader I used once again `rk_sign_tool` from rkbin repository.
Keys used to sign idbloader need to be the same that we used with Rockchip
U-Boot in previous stage.

```shell
tools/rk_sign_tool sb --idb ../u-boot/idbloader.img
********sign_tool ver 1.4********
IDB binary is ../u-boot/idbloader.img
signing idbhead...
failed to get key = sign_algo
signing idbloader ok
```

### U-Boot Verification

To check if SPL is signed correctly and that it correctly verifies U-Boot I have
written idbloader.img file to `spl` partition created in
[Writing key hash to OTP](#writing-key-hash-to-otp). I also flashed `u-boot.itb`
file to `uboot` partition.

After writing needed files and inserting SD card into ODROID i restarted
platform while keeping recovery button pressed.

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
```

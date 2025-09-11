---
title: AMD PSP blob analysis on Gigabyte MZ33-AR1 Turin system
abstract: 'The blog post describes the analysis of PSP blobs on Gigabyte.
           MZ33-AR1. The analysis covers various aspects of stitching AMD
           firmware BIOS images and how a support for stitching Turin blobs
          was developed in coreboot.'
cover: /covers/gigabyte_mz33_ar1.webp
author: michal.zygowski
layout: post
published: true
date: 2025-09-12
archives: "2025"

tags:
 - coreboot
 - firmware
 - AMD
 - Turin
 - MZ33-AR1
 - open-source
categories:
 - Firmware

---
## Introduction

In the [previous
post](https://blog.3mdeb.com/2025/2025-08-07-gigabyte_mz33_ar1_part1/), we
showed coreboot running on Gigabyte MZ33-AR1 with Turin CPU, the current,
newest family of AMD server processors. However, we faced various obstacles
and problems. Despite AMD publishing a set of blobs required for the Turin
system initialization, they turned out to be not enough to release the CPU
from reset by PSP. We were forced to do a workaround by injecting coreboot
into the vendor firmware image and flashing it back. The whole process is far
from ideal; thus, it forced us to perform an analysis, where we demystify and
explain the problems and solutions we came up with.

## AMD PSP firmware structure

Nowadays, the x86 CPUs are not the first entities that begin code execution
after pressing the power button. The design of the processors and silicon
overall drifted towards adding many co-processors, which perform a specialized
subset of actions and have a very specific role in the system. For example:
Intel Management Engine (ME) on Intel platforms and AMD Platform Security
Processor (PSP), also known as AMD Security Processor (ASP). These
co-processors run their own firmware, which is usually stored in the same
flash memory as the BIOS for an x86 CPU. Often these firmwares contain other
firmwares for yet another co-processors or IP blocks. This is true for both
Intel and AMD. We will not dive into Intel specifics, but if you are curious,
just open an Intel firmware image in
[UEFITool](https://github.com/LongSoft/UEFITool) and expand the Intel ME
region. You will see how many various applications or firmwares reside there.

The situation is no different on an AMD system, although the separation of x86
BIOS and PSP firmware/blobs is not as clean as on Intel systems. AMD PSP does
not have any separate flash region for its own use. Instead, the PSP blobs are
packed into specific directory structures, which you can read a bit about
[here](https://doc.coreboot.org/soc/amd/psp_integration.html).

To understand how it is supposed to work on the Turin system, we have to go
through each structure of the PSP firmware and analyze it, starting with
Embedded Firmware Structure (EFS), through PSP directories up to the BIOS
directories.

## Embedded Firmware Structure

Embedded Firmware Structure is like a header that indicates the location of
PSP and BIOS directories. It is used by PSP during power-on to locate the
blobs and configure certain properties of the system, e.g., SPI interface
speeds, eSPI bus configuration, etc. The tool responsible for creating EFS,
PSP and BIOS directories in coreboot are amdfwtool. The coreboot build system
uses this utility during the build process to stitch all blobs together into a
bootable image.

There has been some activity around this tool recently, which has enhanced
its debugging and analysis capabilities:

- [util/amdfwtool/amdfwread: add initial parsing for EFW
 structure](https://review.coreboot.org/c/coreboot/+/88610)
- [util/amdfwtool/amdfwread: fix offset decision for PSP/BIOS directory
 lookup](https://review.coreboot.org/c/coreboot/+/88868)

Seeing this opportunity, I have reviewed and tested the patches, even added
more information to be dumped, and fixed parsing of the images for Turin
processors, to serve the purpose of my analysis:

- [util/amdfwtool: Extend parsing of embedded firmware structures and dirs](https://review.coreboot.org/c/coreboot/+/89040)
- [util/amdfwtool: Handle address mode properly for Turin](https://review.coreboot.org/c/coreboot/+/89039)

With those improvements in place, I was able to dump information about
coreboot images as well as vendor images. When something does not work, one of
the best and easiest ways is to compare a faulty case with a known good
reference. And so by dumping the information on both images, we could spot
some major differences, which potentially could cause the image to be
unbootable.

Since the outputs from amdfwtool are quite long, I have added them as a paste:

- `./util/amdfwtool/amdfwread -d --ro-list build/coreboot.rom`
  - [paste](https://paste.dasharo.com/?f50b4cf19df5fbe0#3gKWXUYa18TfQVDw6zZXu6xYqvB24En3yEHVa7W8hGG9)
- `./util/amdfwtool/amdfwread -d --ro-list MZ33-AR1_R11_F08/SPI_UPD/image.bin`
  - [paste](https://paste.dasharo.com/?5872a639d2237976#DHKBEW8aHHNGHKsVAmwHAVJZ7FX4qPfADeZ2uitciFuo)

The second dump comes from the latest BIOS update package for the Gigabyte MZ33-AR1
which can be downloaded from the vendor's site.

Right now, we are interested in everything that comes before `Table: FW Offset
Size` line, since it represents the EFS. We can see that many fields are
different. Also, we have to remember that vendor image is a dual BIOS for
Genoa and Turin platforms. `amdfwread` prints only the contents of the first
BIOS image (first 16MB). So the `image.bin` has to be split into two 16MB
files, and the dump should be taken from the second file:

```bash
split -b 16M image.bin
```

- `./util/amdfwtool/amdfwread -d --ro-list xab`
  - [paste](https://paste.dasharo.com/?0c29e91f5fed6c40#HMazBMCVihDRjNM9D9ryUfpnsygAyzyRe9zcFCR6Xrwc)

Now we can start comparing the output. Pointers to directories or firmwares
that are either 00000000 or ffffffff can be omitted, since both should
indicate an invalid pointer. Most notable differences are SPI speeds, eSPI
config and Multi Gen EFS value.

Fixing SPI speeds is pretty much straightforward. The board code should supply
the following Kconfig values to match vendor firmware:

```txt
config EFS_SPI_READ_MODE
 default 0 # Normal read 33MHz

config EFS_SPI_SPEED
 default 0 # 66MHz

config EFS_SPI_MICRON_FLAG
 default 0

config NORMAL_READ_SPI_SPEED
 default 1 # 33MHz

config ALT_SPI_SPEED
 default 1 # 33MHz

config TPM_SPI_SPEED
 default 1 # 33MHz
```

Having a correct SPI speed may be crucial for the proper operation of the
system components and flawless communication on the SPI bus interface.

The eSPI configuration fields are configuration values that the PSP will use
to configure the ESPI bus before the reset vector. The eSPI bus is important
because the Baseboard Management Controller is connected to it. With BMC, we
can use the serial port to debug problems, so we have to match the
configuration. Support for setting the ESPI configuration has been implemented
by me in the [patch that adds Turin support to
amdfwtool](https://review.coreboot.org/c/coreboot/+/88709/3). With these
modifications in place, I could define the Kconfig values again in board code
(only one value is enough, because the rest is 0xff - default):

```txt
config EFS_ESPI0_CONFIG
 default 0x0e
```

The only difference left to cover is the Multi Gen EFS value. The usage of
this field is described in the NDA documentation only. For the purpose of the
analysis and explaining its importance, let's say this value is specific to
the processor family, and PSP uses it to match whether the given EFS is
appropriate for the given CPU. These values are fixed for a given CPU family,
and for Turin it has to be 0xffffffe3.

Covering these differences was not enough to allow the PCU to be released from
reset using the public blobs. So we have to proceed further with the analysis,
that is, to the PSP and BIOS directories.

## PSP and BIOS directories

In the coreboot paste, we can see that PSP and BIOS directories have the same
attributes as in the vendor image, but there are fewer entries in them than in
the vendor image. For comparison:

- Vendor BIOS:
  - PSPL1: 53 entries
  - PSPL2: 48 entries
  - BIOSL1: 25 entries
  - BIOSL2: 34 entries
- coreboot:
  - PSPL1: 30 entries
  - PSPL2: 41 entries
  - BIOSL1: 17 entries
  - BIOSL2: 19 entries

The difference is, of course, dictated by the number of blobs AMD published
[here](https://github.com/openSIL/amd_firmwares/tree/turin_poc/Firmwares/Turin).
Also, a subset of entries is duplicated between level 1 (L1) and level 2 (L2)
directories of the same type. Level 1 directory is typically considered a
recovery, and the level 2 is the main directory. However, for some reason,
Gigabyte puts more blobs into the level 1 PSP directory than the level 2. To
proceed further, we had no other choice but to eliminate the differences by
extracting the blobs from the vendor image and integrating the missing ones.
Extracting the blobs is possible with
[PSPTool](https://github.com/PSPReverse/PSPTool):

```bash
psptool -X -r 1 ~/Projects/amd/MZ33-AR1_R11_F08/SPI_UPD/image.bin -o MZ33-AR1_R11_F08
```

We have to take the extra `-r 1` parameter because we want to extract the
Turin blobs, which live in the second 16MB half of the image, due to the dual
BIOS nature of the firmware images for this platform. When the blobs are
extracted, they have to be put into
`coreboot/3rdparty/amd_firmwares/Firmwares/Turin/` directory to replace the
public blobs. Also, the `coreboot/src/soc/amd/turin_poc/fw.cfg` file had to be
modified to point to the missing files. On top of that, the `amdfwtool` had to
be extended with the new blob types. It has also been done as part of the
[patch with Turin support](https://review.coreboot.org/c/coreboot/+/88709/3).
However, to obtain full information on how these missing blobs should be
included, I needed the subprogram and instance numbers. These numbers are used
by PSP to distinguish the same type of program/blob, but for a different CPU
variant. For example, we may have multiple SMU firmwares, but only one will be
loaded on a given processor family, based on the subprogram and instance
numbers.

However, I had no tooling to dump these numbers. So again, I had to implement
something myself. Thankfully, the PSPTool was very close to what I needed, and
I simply extended it to print the subprogram and instance numbers for each
blob:

- `psptool -E  MZ33-AR1_R11_F08/SPI_UPD/image.bin`
  - [paste](https://paste.dasharo.com/?319c7a7578256b4d#3RsryGpN9659Ljjmag2idX2yF86wkGjJYJLG5EV1hUhf)

Based on the dump from the vendor image, I have modified
`coreboot/src/soc/amd/turin_poc/fw.cfg` and `amdfwtool` to stitch the
components extracted from the vendor image. Only then was I able to obtain a
bootable coreboot image (CPU has been released from reset by PSP). Now having
the known good reference and a working tool, I could go back to the public
blobs.

I haven't yet published the patches with PSPTool modifications. They will
follow very soon, so stay tuned.

## Running coreboot with public PSP blobs

Before proceeding with reverting to public PSP blobs, I have made one
additional safety measure. I flashed back the vendor BIOS and enabled PSP
verbose debug output. This can be done with the `ABL Console Out` options in
the `SOC Miscellaneous Control` described in the [board
manual](https://download.gigabyte.com/FileList/Manual/server_manual_mz33ar1_e_v3.0.pdf)
(section 2-3-6). Booted the platform with debug options enabled, and on the
serial console port, I could see verbose debugging messages almost immediately
after pressing the power button. This debug output will help me quickly
determine if the public blobs are even consumed by PSP or not. If I don't see
anything on the serial port, it will mean they are not consumed. The debug
switches are stored inside APCB blobs, so I dumped the BIOS image, extracted
the APCBs with PSPTool and copied them in place on the old ones in the board
code. First, I confirmed whether they are working with the blobs extracted
from the vendor image, to avoid any mistakes later. And fortunately, it also
gave me debug output with the coreboot image. Then I proceeded with replacing
the vendor image blobs with the public ones, stitched the image again, and
flashed it on the board. But nothing happened on the serial console,
unfortunately. This was very unexpected and left me at a loss. After many
hours of analysis and comparisons, what else might be wrong or different, I
noticed something strange in the PSPTool output made from the current coreboot
image:

- `psptool -E  build/coreboot.rom`
  - [paste](https://paste.dasharo.com/?1584611f605c0789#69dbaSVmgMoD1o6UHWfP8XLypPWDDFR2Gzoq1FfHq1p4)

The most worrying is the first entry of PSPL1, which corresponds to AMD Root
Key. This Root Key is the main key used to sign PSP blobs and derive other
keys to sign other components:

```txt
+--+---+-------+----------+---------+---------------------------------------------------+------------+----------+----------+--------------+-------------------------------------------------------------------+
|  |   | Entry |  Address |    Size |                                              Type | Subprogram | Instance | Magic/ID | File Version |                                                         File Info |
+--+---+-------+----------+---------+---------------------------------------------------+------------+----------+----------+--------------+-------------------------------------------------------------------+
|  |   |     0 |  0x41400 |   0x440 |                                AMD_PUBLIC_KEY~0x0 |        0x0 |      0x0 |     9F9D |            1 |                                                     AMD_CODE_SIGN |
|  |   |     1 | 0x311400 | 0x26580 |                            PSP_FW_BOOT_LOADER~0x1 |        0x0 |      0x0 |     $PS1 |    0.29.0.9B |                           veri-failed(9F9D), encrypted, sha256_ok |
|  |   |     2 |  0x41900 | 0x26580 |                   PSP_FW_RECOVERY_BOOT_LOADER~0x3 |        0x0 |      0x0 |     $PS1 |   FF.29.0.9B |                           veri-failed(9F9D), encrypted, sha256_ok |
```

Here we can see that the AMD Root Key has an ID `9F9D`. The very same key is
used to verify PSP FW bootloader and PSP FW recovery bootloader
(`veri-failed(9F9D)`, not sure why the verification fails, but it could be one
of the reasons why it is not working). When I looked closer at the output of
PSPTool from the vendor image, the verification of the PSP FW recovery boot
loader passed with the AMD Root Key:

```txt
+--+---+-------+-----------+---------+---------------------------------------------------+------------+----------+----------+--------------+-------------------------------------------------------------------+
|  |   | Entry |   Address |    Size |                                              Type | Subprogram | Instance | Magic/ID | File Version |                                                         File Info |
+--+---+-------+-----------+---------+---------------------------------------------------+------------+----------+----------+--------------+-------------------------------------------------------------------+
|  |   |     0 | 0x1042400 |   0x440 |                                AMD_PUBLIC_KEY~0x0 |        0x0 |      0x0 |     D05C |            1 |                                                     AMD_CODE_SIGN |
|  |   |     1 | 0x131b000 | 0x30000 |                            PSP_FW_BOOT_LOADER~0x1 |        0x0 |      0x0 |     $PS1 |    0.3D.0.6C |                 veri-failed(D05C), encrypted, sha384_inconsistent |
|  |   |     2 | 0x1042900 | 0x1b1a0 |                             PSP_FW_TRUSTED_OS~0x2 |        0x0 |      0x0 |     $PS1 |    0.3D.0.6C | compressed(size=0x1b0a0), veri-failed(4260), encrypted, sha384_ok |
```

The second significant difference is the key ID. The key ID in the vendor
image was different (`D05C`)! At first, I suspected that Gigabyte could have
created their own key to sign PSP blobs and got it signed by the AMD Root Key.
But what is really possible?

To be 100% sure, I have attempted to build the coreboot image with the latest
AMD PSP blobs available in the Turin PI package (NDA only). This is the
package with the silicon initialization source code and the set of PSP blobs
required to build a bootable image. So I updated
`coreboot/src/soc/amd/turin_poc/fw.cfg` again for the blobs from the Turin PI
package and dumped the directories with PSPTool. To my surprise, the AMD Root
Key was the same as in Gigabyte vendor firmware (full paste
[here](https://paste.dasharo.com/?5c824661ef37b6da#DPV3LmWkszemDDj3boNDMSXkgJvSPmNxF62KYWtGRjaD)):

```txt
+--+---+-------+----------+---------+---------------------------------------------------+------------+----------+----------+--------------+-------------------------------------------------------------------+
|  |   | Entry |  Address |    Size |                                              Type | Subprogram | Instance | Magic/ID | File Version |                                                         File Info |
+--+---+-------+----------+---------+---------------------------------------------------+------------+----------+----------+--------------+-------------------------------------------------------------------+
|  |   |     0 |  0x31000 |   0x440 |                                AMD_PUBLIC_KEY~0x0 |        0x0 |      0x0 |     D05C |            1 |                                                     AMD_CODE_SIGN |
|  |   |     1 |  0x31500 |  0x4220 |                            PSP_FW_BOOT_LOADER~0x1 |        0x0 |      0x0 |     $PS1 |    0.3D.0.7A |                           veri-failed(D05C), encrypted, sha384_ok |
|  |   |     2 |  0x35800 | 0x1b1a0 |                             PSP_FW_TRUSTED_OS~0x2 |        0x0 |      0x0 |     $PS1 |    0.3D.0.7A | compressed(size=0x1b0a0), veri-failed(4260), encrypted, sha384_ok |
|  |   |     3 |  0x3ea00 |  0x4220 |                   PSP_FW_RECOVERY_BOOT_LOADER~0x3 |        0x0 |      0x0 |     $PS1 |   FF.3D.0.7A |                           veri-failed(D05C), encrypted, sha384_ok |
```

This means my hypothesis about the custom root key was incorrect. AMD simply
published a different set of blobs, or blobs that are signed with
pre-production key (that would make sense, since the PoC code was proven on
the AMD CRB platform, which most likely uses a pre-production CPU). I have
filed an [issue on the
repository](https://github.com/openSIL/amd_firmwares/issues/1) requesting to
update the blobs to the newest ones from the Turin PI package.

While using public blobs proved to be impossible for now, I still decided to
prove that blobs from official sources are working properly and can eventually
replaced the incorrect blobs from the repo. So I flashed the freshly produced
image with blobs from the Turin PI package, and thankfully, the CPU was
released from reset, and I saw debug messages from coreboot's bootblock!

With these results, we have fulfilled the goals of the following milestones in
the project:

- Task 2. Public blobs integration
  - Milestone a. Analysis of vendor's image

    We have thoroughly analyzed the vendor image and eliminated any
    differences in the integrated PSP blobs that could have hindered the boot
    process with coreboot. We also learned about the inappropriate blobs
    published by AMD. Their usage is currently impossible.

  - Milestone b. Update coreboot's amdfwtool

    Thanks to the extensive analysis of the vendor image, the amdfwtool is now
    successfully creating a bootable image for the Turin system. A
    [patch](https://review.coreboot.org/c/coreboot/+/88709) has been uploaded
    and the "work in progress" state got removed, indicating the change is
    ready to review and functional.

## Summary

The journey of porting Gigabyte MZ33-AR1 seems to be still quite long. Lots of
surprises probably still await us. Stay tuned for more blog posts where
further porting efforts will be shown and explained.

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the
hidden benefits of your hardware. And if you want to stay up-to-date on all
things firmware security and optimization, be sure to sign up for our
newsletter:

{{< subscribe_form "dbbf5ff3-976f-478e-beaf-749a280358ea" "Subscribe" >}}

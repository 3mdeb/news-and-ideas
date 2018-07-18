---
ID: 63066
post_title: >
  SWUpdate for feature-rich IoT
  applications
author: Maciej Pijanowski
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/app-dev/swupdate-for-feature-rich-iot-applications/
published: true
post_date: 2017-05-21 12:00:00
tags:
  - linux
  - Update
  - Swupdate
categories:
  - App Dev
---
When you work with embedded systems long enough, sooner or later you realize that some sort of update mechanism is required. This is especially true when more complex systems, running with an operating system, are taken into account. Nowadays [Linux is being picked increasingly][1] as operating system for embedded IoT devices. In following post we will focus on those in particular. In fact, from my experience update mechanism is vital part of many embedded applications. When project is aimed to be maintained in a long run, it is one of the first features being developed. 
## Update IoT device vs update on desktop On standard Linux machines updates are generally performed using one of the package managers. This approach may seem tempting, but for embedded devices it usually leads to more issues than it has advantages. When number of possible packages reaches hundreds or thousands, it becomes impossible to test application stability with various revisions of those packages. Approach where we release one thoroughly tested rootfs image is both more reliable and less time consuming in a long term. 

## Our vision of update system In most of our project where software is concerned, we are heading towards 

[double copy][2] approach. The main idea is to have two separate rootfs partitions, which always leaves us with at least one copy of correct software. Core of developed update systems is usually similar to the one presented on the graph below. ![update_flow][3] 
## What is SWUpdate?

[SWUpdate][4] is application designed for updating embedded Linux devices. It is strongly focused on reliability of each update. Every update should be consistent and atomic. Major goal is to make it completely power-cut safe. Power-off in any phase of an update should not brick the device and we always should end up having fully-functional system. 
## Purpose of this post My goal is not to rewrite 

[SWUpdate documentation][5] here. Instead, I plan to point out it's interesting features and present the way how it is being used in `3mdeb`. This is why I will often leave a link to related chapter in [SWUpdate documentation][5] for more information. In the end I will give short example of implementation of such update system used in `3mdeb`. 
## SWUpdate example features

### SWU image

`*.swu` image is a `cpio` container which contains all files needed during update process (images, scripts, single files and so on). In addition it requires [sw-description][6] file to be present. This file describes `.swu` image content and allows to plan various update scenarios through setting appropriate flags in each section. 
### Software collections

`SWUpdate` supports dual image approach by providing [software collections][7] in `sw-description` file. Such simple collection inside can be written as: 
    software =
    {
            version = "1.0.0";
            stable:
            {
                    mmcblk0p2:
                    {
                            images: (
                            {
                                    filename = "example-rootfs-image.ext4";
                                    device = "/dev/mmcblk0p2";
                            }
                            );
                    };
                    mmcblk0p3:
                    {
                            images: (
                            {
                                    filename = "example-rootfs-image.ext4";
                                    device = "/dev/mmcblk0p3";
                            }
                            );
                    };
            };
    }
     As you can see below, there are two software modes to choose from: * 

`stable,mmcblk0p2` will install rootfs image into `/dev/mmcblk0p2` partition * `stable,mmcblk0p3` will install rootfs image into `/dev/mmcblk0p3` partition Selection of given mode is made by using `-e` command line switch, e.g.: 
    swupdate -e "stable,mmcblk0p2" -i example.swu-image.swu
     In double copy approach we are using software collections mainly to point to target partition on which update will be performed. File (image) name is usually the same in both. 

### Hardware compatibility It can be used to exclude the risk of installing software on the wrong platform. 

`sw-descrption` should contain list of compatible hardware revisions: 
    hardware-compatibility = [ "1.0.1", "1.0.0", "1.0.2" ];
     Hardware revision is saved in file (by default 

`/etc/hwrevision`) using following format: 
    board_name board_revision
     When I last checked this, only 

`board_revision` string was taken into account when it came to checking for image compatibility. So in these terms, boards: `board1 revA` and `board2 revA` would be compatible. The first string (`board_name`) was only used for [board specific settings][8]. As for `hwrevision` file - when using Yocto, I usually ship it through `swupdate` bbappend file - specific for each target machine. 
#### Image downloading Basic usage of 

`SWUpdate` involves executing it from command line, passing several arguments. In this scenario image can either be downloaded from given URL, or obtained from local file shipped on USB stick for example. For obvious reason in case of multiple IoT devices we are rather interested in downloading images. Download support is provided by [curl][9] library. In current SWUpdate implementation it supports fetching from `http(s)` or `ftp`. However [curl][9] supports many other protocols. In fact, at the moment we are using SWUpdate with fetching from `sftp` server with no source code modification. In this case, private key (`id_dsa`) must be located in `$HOME/.ssh` path as explained in curl documentation regarding [CURLOPT_SSH_PUBLIC_KEYFILE][10]. This behavior could be documented in SWUpdate documentation or even another command line parameter added for key location. This could be in scope of further contribution into the project. To download image from given URL, following command line parameters should be passed: 
    swupdate -d "-u http://example.com/mysoftware.swu"
    

> Note that there's been syntax change a while ago. In previous releases (for example in the one present in Yocto krogoth release, which is still in use) it was just: `swupdate -d http://example.com/mysoftware.swu` 
### Compressed images One of the concerns while using whole rootfs image update approach may be the size of single update image. SWUpdate offers handling of 

[gzip][11] compressed images as well. From my experience, size of such compressed images is not grater than 50 - 100 MB, depending on complexity of given application. With today's network speed is not that much as long as there is no serious connection restrictions. When delivering compressed image, `copressed` flag must be set in corresponding `sw-description` section. It may look like below: 
    images: (
    {
            filename = "rootfs-image-name.img.gz";
            device = "/dev/sda3";
            compressed = TRUE;
    }
    );
     I always use this feature, as it drastically decreases update image size. Thing to remember is that you need to compress rootfs image itself (not whole SWU image). Also it requires 

`gz` compression, so use [gzip][11] application. 
### Streaming images SWUpdate offers 

[streaming feature][12] that allows to stream downloaded image directly onto second partition, without temporary copy in `/tmp`. This might be especially desired when RAM amount is not enough to store whole rootfs image. This can be enabled by setting `installed-directly` flag in given `image` section. In this case it would look like this: 
    images: (
    {
            filename = "rootfs-image-name.img.gz";
            device = "/dev/sda3";
            compressed = TRUE;
            installed-directly = TRUE;
    }
    );
     By default, temporary copy is done by 

`SWUpdate` to check for image correctness. I feel that with dual copy approach it is not really necessary as if anything goes wrong we are always left with working software and ready to perform update again. This is why we tend to use this feature pretty often. 
### GRUB support When developing application for embedded system there can be a problem with not enough of hardware platforms for testing. Testing on host can also be faster and more efficient. When using 

[Virtualbox][13], even update system could be tested. The issue was that, it usually uses [GRUB][14] as a bootloader and `SWUpdate` was supporting `U-Boot` only. With little effort we managed to add basic support for GRUB environment update in `SWUpdate` project and this feature [has been recently upstreamed][15]. 
## Complete example I will try to present an example setup that allows to experience mentioned 

`SWUpdate` features. It can be a base (and usually it is in case for our projects) for actual update system. Below example fits for any embedded device running Linux with U-Boot as bootloader. In my case [Hummingboard][16] from Solidrun was used. ![hb2_gate][17] 
### Rootfs image Of course you need a rootfs image to perform update with it. It can be prepared in may ways. For test purpose, you can even perform 

`dd` command to obtain raw image from SD card. An example command would be: 
    sudo dd if=/dev/mmcblk0 of=rootfs-image.img bs=16M
     However, preferred method would be to use 

[Yocto][18] build system. Along with [meta-swupdate][19] it allows for automated building of rootfs image, as well as `.swu` containter image in one run. In this case, `krogoth` revision of `Yocto` was used. 
### U-Boot boot script In dual image approach goal is to pass information to bootloader after update has finished successfully. In case of 

`U-Boot` we can tell which partition to use as rootfs when booting. With below script we will boot into newly updated software once. 
    # if fback is not defined yet, boot from 2 partition as default
    if test x${fback} != x; then
        boot_part=${fback}
    else
        boot_part=2
    fi
    
    # Boot once into new system after update
    if test x${next_entry} != x; then
        boot_part=${next_entry}
        setenv next_entry
    fi
    
    saveenv
    
    setenv bootargs "console=ttymxc0,115200n8 rootfstype=ext4 rootwait panic=10 root=/dev/mmcblk0p${boot_part}"
    ext4load mmc 0:${boot_part} 0x13000000 boot/${fdtfile}
    ext4load mmc 0:${boot_part} 0x10800000 boot/zImage
    bootz 0x10800000 - 0x13000000
     When booted into newly updated partition, some sort of sanity checks can be made. If passed, new software is marked as default by setting 

`fback` environment variable to point to this partition. We can modify bootloader environment using SWU image with just `sw-description` file. Below is an example of such: 
    software =
    {
            version = "1.0.0";
    
            hardware-compatibility = [ "Hummingboard", "som-v1.5" ];
            confirm =
            {
                    mmcblk0p3:
                    {
                            uboot: (
                            {
                                    name = "fback";
                                    value = "3";
                            }
                            );
                    };
                    mmcblk0p2:
                    {
                            uboot: (
                            {
                                    name = "fback";
                                    value = "2";
                            }
                            );
                    };
            }
    }
    

### Prepare sw-description file Below is an example 

`sw-description` file including features mentioned above: 
    software =
    {
            version = "1.0.0";
            hardware-compatibility = [ "Hummingboard", "som-v1.5" ];
            stable:
            {
                    mmcblk0p2:
                    {
                            images: (
                            {
                                    filename = "example-rootfs-image.ext4.gz";
                                    device = "/dev/mmcblk0p2";
                                    installed-directly = TRUE;
                                    compressed = TRUE;
                            }
                            );
                            uboot: (
                            {
                                    name = "next_entry";
                                    value = "2";
                            },
                            {
                                    name = "fback";
                                    value = "3";
                            }
                            );
                    };
                    mmcblk0p3:
                    {
                            images: (
                            {
                                    filename = "example-rootfs-image.ext4.gz";
                                    device = "/dev/mmcblk0p3";
                                    installed-directly = TRUE;
                                    compressed = TRUE;
                            }
                            );
                            uboot: (
                            {
                                    name = "next_entry";
                                    value = "3";
                            },
                            {
                                    name = "fback";
                                    value = "2";
                            }
                            );
                    };
            };
    }
    

### Creation of SWU image

#### Yocto based

*   Follow with setup from [building with Yocto][20] section
*   Create recipe for SWU image, e.g. `recipes-extended/images/test-swu-image.bb`. It could be based on [bbb-swu-image][21] recipe from `meta-swupdate` repository. `sw-desciption` file should end up in `images/test-swu-image` directory. If another files (such as scripts) should as well be part of compound SWU image, they should also go there. Assuming that `hummingboard` is our machine name in Yocto, such recipe could look like below:

    # Copyright (C) 2015 Unknown User <unknow@user.org>
    # Released under the MIT license (see COPYING.MIT for the terms)
    
    DESCRIPTION = "Example Compound image for Hummingboard"
    SECTION = ""
    
    # Note: sw-description is mandatory
    SRC_URI_hummingboard= "file://sw-description 
               "
    inherit swupdate
    
    LICENSE = "MIT"
    LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690 
                        file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
    
    # IMAGE_DEPENDS: list of Yocto images that contains a root filesystem
    # it will be ensured they are built before creating swupdate image
    IMAGE_DEPENDS = ""
    
    # SWUPDATE_IMAGES: list of images that will be part of the compound image
    # the list can have any binaries - images must be in the DEPLOY directory
    SWUPDATE_IMAGES = " 
                    core-image-full-cmdline 
                    "
    
    # Images can have multiple formats - define which image must be
    # taken to be put in the compound image
    SWUPDATE_IMAGES_FSTYPES[core-image-full-cmdline] = ".ext4"
    
    COMPATIBLE = "hummingboard"
    

*   SWU image can be build with following command:

    bitbake test-swu-image
     It can be found in standard directory for built images: 

`tmp/deploy/images/${MACHINE}`. 
#### Manual Refer to 

[building a single image][22] section from SWUpdate documentation. 
### Perform update Assuming SWU image is already uploaded and current partition is 

`/dev/mmcblk0p2`: 
    swupdate -d http://example.com/mysoftware.swu -e "stable,mmcblk0p3"
    

## Conclusion I have only shortly described features that we commonly use. These are of course not all that are available. You can find out more in the 

[list of supported features][23]. Definitely worth to mention would be: 
*   [suricatta daemon mode][24] with HawkBit backend
*   [update from verified source][25]
*   [encrypted images][26]
*   [checking software version][27]

`SWUpdate` provides really powerful and reliable update mechanism. It's job is only to download and reliably perform update according to metadata written into `sw-description` file. The rest such as picking right software from collection, getting current and available partitions, preparing bootloader scripts etc. is up to user. It may be overwhelming at first, but it is the reason why `SWUpdate` can be so flexible. You can pick features from (still growing) list to design update system that is perfect for your needs. `SWUpdate` will only assure that it is safe and reliable. 
## Summary We hope that content of this blog post was entertaining and useful for you. If you have any comments or questions do not bother to drop us a note below. If you feel this blog post contains something useful please share with the others. As 3mdeb we are always ready to give you professional support. Just let us know by sending an email to 

`contact@3mdeb.com`.

 [1]: https://www.arrow.com/en/research-and-events/articles/iot-operating-systems
 [2]: https://sbabic.github.io/swupdate/overview.html#double-copy-with-fall-back
 [3]: https://3mdeb.com/wp-content/uploads/2017/07/update_flow-1.png
 [4]: https://github.com/sbabic/swupdate
 [5]: hhttps://sbabic.github.io/swupdate/swupdate.html#swupdate-software-update-for-embedded-system
 [6]: https://sbabic.github.io/swupdate/sw-description.html#swupdate-syntax-and-tags-with-the-default-parser
 [7]: https://sbabic.github.io/swupdate/swupdate.html?highlight=collection#software-collections
 [8]: https://sbabic.github.io/swupdate/sw-description.html?highlight=compatibility#board-specific-settings
 [9]: https://curl.haxx.se/
 [10]: https://curl.haxx.se/libcurl/c/CURLOPT_SSH_PUBLIC_KEYFILE.html
 [11]: http://www.gzip.org/
 [12]: https://sbabic.github.io/swupdate/swupdate.html#images-fully-streamed
 [13]: https://www.virtualbox.org/
 [14]: https://www.gnu.org/software/grub/
 [15]: https://github.com/sbabic/swupdate/commit/830692a5e6ad40d6382557f2b9a4dcc74227afcc
 [16]: https://www.solid-run.com/freescale-imx6-family/hummingboard/
 [17]: https://3mdeb.com/wp-content/uploads/2017/07/hb2_gate.jpg
 [18]: http://www.yoctoproject.org/docs/2.1/yocto-project-qs/yocto-project-qs.html
 [19]: https://github.com/sbabic/meta-swupdate
 [20]: https://sbabic.github.io/swupdate/swupdate.html#building-with-yocto
 [21]: https://github.com/sbabic/meta-swupdate/blob/krogoth/recipes-extended/images/bbb-swu-image.bb
 [22]: https://sbabic.github.io/swupdate/swupdate.html#building-a-single-image
 [23]: https://sbabic.github.io/swupdate/swupdate.html#list-of-supported-features
 [24]: https://sbabic.github.io/swupdate/suricatta.html
 [25]: https://sbabic.github.io/swupdate/signed_images.html#update-images-from-verified-source
 [26]: https://sbabic.github.io/swupdate/encrypted_images.html#symmetrically-encrypted-update-images
 [27]: https://sbabic.github.io/swupdate/sw-description.html#checking-version-of-installed-software
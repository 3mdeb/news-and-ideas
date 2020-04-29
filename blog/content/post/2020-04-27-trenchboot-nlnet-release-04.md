---
title: 'TrenchBoot: Open Source DRTM.'
abstract:
cover: /covers/trenchboot-logo.png
author: piotr.kleinschmidt
layout: post
published: false
date: 2020-04-27
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

[Previous article](https://blog.3mdeb.com/2020/2020-04-03-trenchboot-nlnet-lz-validation/)
showed how to enable DRTM on PC Engines apu2 platform and NixOS operating
system. As project is constantly developed by us, there are regularly new
features implemented. This article is showing how to update your DRTM and verify
next project's requirements. Typically, new updates should be published every
month as form of following blog posts and they will develop already configured
system components. Therefore, **we strongly encourage to keep project up-to-date
and keep track of TrenchBoot blog posts series**. If you haven't read previous
articles, we recommend to catch up.

At this point, we have already introduce project's motivation and goals.
Moreover, we have shown what platform and operating system we use for
development and tests. Finally, we have enabled DRTM on our platform and
prepared exact step-by-step procedure, so you can enable it too!

## What's new

We have made following changes since last release:

    1. general **DRTM update in NixOS** (including landing-zone, Linux kernel
    and Grub)
    1. enabled DRTM in Yocto custom Linux built - **meta-trenchboot**
    1. introduced **CI/CD system** to build each TrenchBoot components

Each from above points is described with details later in this article. It is
divided into sections:

    1. Update DRTM in NixOS
    1. Enable DRTM in custom Linux built
    1. CI/CD system

Depending on specific section, there are already met project's requirements
mentioned and ways to verify them.

## Update DRTM in NixOS

Since last release, there are improvements in **landing-zone, grub and Linux
kernel**. All of these components should be updated. Following procedure is
showing how to do this properly.

>Remember, that everything is done in NixOS and further verification is done for
system precisely configured this way.

1. Pull `3mdeb/nixpkgs` repository.

    ```
    $ cd ~/nixpkgs
    $ git branch trenchboot_support_2020.03
    $ git pull
    ```

2. Pull `3mdeb/nixos-trenchboot-configs` repository.

    ```
    $ cd ~/nixos-trenchboot-configs
    $ git branch master
    $ git pull
    ```

3. Copy all configuration files to `/etc/nixos/` directory.

    ```
    $ cp nixos-trenchboot-configs/*.nix /etc/nixos
    ```

4. Update system.

    ```
    $ sudo nixos-rebuild switch -I nixpkgs=~/nixpkgs
    building Nix...
    building the system configuration...
    ```

5. Reboot platform

    ```
    $ reboot
    ```


#### Requirements verification - LZ content and layout

There are two requirements which LZ must met:

    1. bootloader information header in LZ should be moved at the end of the LZ
    binary or the end of code section of the LZ;

    1. the size of the measured part of the SLB must be set to the code size only;

Bootloader information header is special data structure which layout is
hardcoded in [landing-zone source code](https://github.com/TrenchBoot/landing-zone/blob/master/include/boot.h#L50).
The requirement is to keep that data in `lz_header.bin` file after code section.
Hence, when SKINIT instruction makes measurements of the Landing Zone, only code
section is measured. Verification of above requirements can be carried out like
this:

1. Check the value of second word of `lz_header.bin` file using `hexdump`
tool.

    ```
    $ hexdump -C lz_header.bin | head                                                    
    00000000  d4 01 00 d0 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    000001d0  00 00 00 00 89 c5 8d a5  00 02 00 00 b9 14 01 01  |................|
    000001e0  c0 0f 32 83 e0 f9 0f 30  01 ad bc 27 00 00 01 ad  |..2....0...'....|
    000001f0  52 02 00 00 01 ad 00 90  00 00 01 ad 00 80 00 00  |R...............|
    00000200  01 ad 08 80 00 00 01 ad  10 80 00 00 01 ad 18 80  |................|
    00000210  00 00 01 ad 00 40 00 00  0f 01 95 ba 27 00 00 b8  |.....@......'...|
    00000220  10 00 00 00 8e d8 8e c0  0f 20 e1 83 c9 20 0f 22  |......... ... ."|
    00000230  e1 8d 85 00 90 00 00 0f  22 d8 b9 80 00 00 c0 0f  |........".......|
    ```

    > Value of second word (`00 d0`) is size of code section and concurrently
    offset (address) of bootloader information header. Used notation is
    little-endian so the value is actually `0xd000` (NOT 0x00d0).

2. Check the content of `lz_header.bin` file from `0xd000` address.

    ```
    $ hexdump -C -s 0xd000 lz_header.bin | head                                          
    0000d000  78 f1 26 8e 04 92 11 e9  83 2a c8 5b 76 c4 cc 02  |x.&......*.[v...|
    0000d010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    0000d030  04 00 00 00 10 00 00 00  05 00 00 00 47 4e 55 00  |............GNU.|
    0000d040  01 00 00 c0 04 00 00 00  01 00 00 00 00 00 00 00  |................|
    0000d050
    ```

    > As you can see, there is `78 f1 26 8e 04 92 11 e9  83 2a c8 5b 76 c4 cc
    02` data under 0xd000 address.

3. If above data is the same as in data structure in
[landing-zone source code](https://github.com/TrenchBoot/landing-zone/blob/master/include/boot.h#L50)
then it is **bootloader information header**. In given example, it is
placed after code section in LZ.

    Debug version of landing zone can be checked exactly the same way. Just
    make sure, you read address properly, as it probably isn't the same
    value as in non-debug landing-zone.

1. Check value of second word of `lz_header_debug.bin` file using
`hexdump` tool.

    ```
    $ hexdump -C lz_header_debug.bin | head                                              
    00000000  d4 01 00 e0 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    000001d0  00 00 00 00 89 c5 8d a5  00 02 00 00 b9 14 01 01  |................|
    000001e0  c0 0f 32 83 e0 f9 0f 30  01 ad ac 2b 00 00 01 ad  |..2....0...+....|
    000001f0  52 02 00 00 01 ad 00 a0  00 00 01 ad 00 90 00 00  |R...............|
    00000200  01 ad 08 90 00 00 01 ad  10 90 00 00 01 ad 18 90  |................|
    00000210  00 00 01 ad 00 50 00 00  0f 01 95 aa 2b 00 00 b8  |.....P......+...|
    00000220  10 00 00 00 8e d8 8e c0  0f 20 e1 83 c9 20 0f 22  |......... ... ."|
    00000230  e1 8d 85 00 a0 00 00 0f  22 d8 b9 80 00 00 c0 0f  |........".......|
    ```

    > Value of the second word (`00 e0`) is size of code section and
    concurrently offset (address) of bootloader information header. Used
    notation is little-endian so the offset is actually `0xe000` (NOT 0x00e0).

2. Check the content of `lz_header_debug.bin` file from `0xe000` address.

    ```
    $ hexdump -C -s 0xe000 lz_header_debug.bin | head                                    
    0000e000  78 f1 26 8e 04 92 11 e9  83 2a c8 5b 76 c4 cc 02  |x.&......*.[v...|
    0000e010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    0000e030  04 00 00 00 10 00 00 00  05 00 00 00 47 4e 55 00  |............GNU.|
    0000e040  01 00 00 c0 04 00 00 00  01 00 00 00 00 00 00 00  |................|
    0000e050
    ```

    > As you can see, there is `78 f1 26 8e 04 92 11 e9  83 2a c8 5b 76 c4 cc
    02` data under 0xe000 address.

3. If above data is the same as in data structure in
[landing-zone source code](https://github.com/TrenchBoot/landing-zone/blob/master/include/boot.h#L50)
then it is **bootloader information header**. In given example, it is
placed after code section in LZ.

## Enable DRTM in custom Linux built

Our custom Linux built is called **meta-trenchboot**. To use it on your PC
Engines apu2 platform, all you need to have is:

    1. SSD disk to store image
    1. Linux operating system (e.g. Debian) with `bmaptool` tool to flash SSD
      disk
    1. [tb-minimal-image.wic.bmap](https://cloud.3mdeb.com/index.php/s/3c5QNHbNRx5gpY5/download)
      file
    1. [tb-minimal-image.wic.gz](https://cloud.3mdeb.com/index.php/s/xd9z3iDS3gkPrmQ/download)
      file

Procedure that will be presented shortly is conventional *disk flashing process
with usage of `bmaptool`*. Therefore, steps 1-3 can be carried out on any
machine with Linux. In this particular example, we are using only PC Engines
apu2 platform with iPXE enabled and SSD disk included.

1. Boot to Linux based operating system.

    In our case it is Debian Stable 4.16 booted via iPXE.

2. Download *tb-minimal-image.bmap* and *tb-minimal-image.gz* files.

    ```
    $ wget -O tb-minimal-image.wic.bmap https://cloud.3mdeb.com/index.php/s/3c5QNHbNRx5gpY5/download
    $ wget -O tb-minimal-image.wic.gz https://cloud.3mdeb.com/index.php/s/xd9z3iDS3gkPrmQ/download
    ```

3. Using `bmaptool` flash SSD disk with downloaded image.

    > **IMPORTANT**: Make sure to use proper target device - /dev/sdX. In our
    case it is /dev/sda, but can be different for you.

    Usage of bmaptool is: `bmaptool copy --bmap <image.wic.bmap> <image.wic.gz> </dev/sdX>`

    ```
    $ bmaptool copy --bmap tb-minimal-image.wic.bmap tb-minimal-image.wic.gz /dev/sda
    [ 1076.049347]  sda: sda1 sda2
    bmaptool: info: block map format version 2.0
    bmaptool: info: 532480 blocks of size 4096 (2.0 GiB), mapped 48007 blocks (187.5 MiB or 9.0%)
    bmaptool: info: copying image 'tb-minimal-image.wic.gz' to block device '/dev/sda' using bmap file 'tb-minimal-image.wic.bmap'
    (...)
    bmaptool: info: 99% copied
    [ 1120.645490]  sda: sda1 sda2
    ```

4. Reboot platform and boot from just flashed SSD disk.

    You should see GRUB menu with 2 entries:

    - boot - it is 'normal' boot without DRTM
    - secure-boot - it is boot with **DRTM enabled**

5. Choose `secure-boot` entry, verify bootlog and enjoy platform with DRTM!

    At the beginning, there should be similar output:

    ```
    grub_cmd_slaunch:122: check for manufacturer
    grub_cmd_slaunch:126: check for cpuid
    grub_cmd_slaunch:136: set slaunch
    grub_cmd_slaunch_module:156: check argc
    grub_cmd_slaunch_module:161: check relocator
    grub_cmd_slaunch_module:170: open file
    grub_cmd_slaunch_module:175: get size
    grub_cmd_slaunch_module:180: allocate memory
    grub_cmd_slaunch_module:192: addr: 0x100000
    grub_cmd_slaunch_module:194: target: 0x100000
    grub_cmd_slaunch_module:196: add module
    grub_cmd_slaunch_module:205: read file
    grub_cmd_slaunch_module:215: close file
    grub_slaunch_boot_skinit:41: real_mode_target: 0x8b000
    grub_slaunch_boot_skinit:42: prot_mode_target: 0x1000000
    grub_slaunch_boot_skinit:43: params: 0xcfe2391
    code32_start 0x0000000001000000:
    (...)
    ```

    > It indicates that DRTM is enabled and executed. For details about bootflow
    and DRTM verification we refer to [previous article](https://blog.3mdeb.com/2020/2020-04-03-trenchboot-nlnet-lz-validation/)
    in which it is precisely described.

## CI/CD system

As it is mentioned in the beginning of this post, int this release we have
introduced **CI/CD system** to build each TrenchBoot components. It is a big
step towards fully-automated development, validation and deployment. Besides
building advantages, it is a convenient way to deliver all necessary up-to-date
binaries. This section describes how this environment is built, what tools do we
use and how you can utilize our system.

### Continuous Integration / Continuous Delivery - theory

Before you get acquainted with our particular system, we will get you familiar
with **Continuous Integration / Continuous Delivery** concept. What is behind
this idea and how it improves quality of work and final product.

##### Continuous Integration (CI)

Basically this practice is used in development stage of project and greatly
simplify release process. Let's consider cyclic, monthly release of our
`TrenchBoot: Open Source DRTM` project. Throughout the whole month, there are
code changes in all repositories related to project. Over time verification of
introduced changes manually  becomes too complex and too uncomfortable. Imagine
building same binaries every time when there is even slight change. It must be
done, but it is ineffective when delegated person must do it by hand. At this
point, **CI** comes with help! It is a system which *automatically builds and
tests specific component* in response to a defined event. This event is mostly
new commit, tag release or merge - it is defined by the owner and adapted to
project's needs. As a result, every code change is automatically checked against
crash and hereby gives quick feedback to developers.

##### Continuous Delivery (CD)

**Continuous Delivery (CD)** is a successor of CI phase. As mentioned, CI checks
the build and validate its correctness. However, the end products are always
binary files (applications) which should be provided to users. That is the
scope of CD part. *It releases and publishes* final deliveries called artifacts,
so it can be freely used by user. Moreover, you are sure that those deliveries
(binary files mostly) have passed build and test phases (in CI), which confirms
their correctness in operation.

### Our CI/CD system

Now, when you are familiar with CI/CD concept, let us introduce our own prepared
environment. We decided to use **GitLab CI** tools. For our usage it is most
convenient solution and (in opposition as the name suggest) it works seamlessly
with GitHub repositories too. Please refer to the *TrenchBoot CI/CD
infrastructure* diagram to see the details.

![TrenchBoot CI/CD infrastructure](img/tb_gitlab_ci.png)
*TrenchBoot CI/CD infrastructure*

As you can see our environment is divided into 3 main layers:

1. **Cloud**

    It is a 'gate to the external word' or 'frontend' of our CI/CD system.
    The effects of work of CI/CD are visible in this layer. Also it joins
    together:

    1. All TrenchBoot Github repositories
    1. GitLab CI master (actual CI/CD tool)
    1. Document with reports and status of builds

2. **3mdeb/TrenchBoot infrastructure**

    It is a core of our CI/CD system. When build request is triggered,
    GitLab CI runner is doing entire job. Results of its work are delivered
    in 3 ways:

    1. Publish artifacts (binaries) to the Cloud layer.
    1. Publish Yocto cached components which are utilized in
    `meta-trenchboot` builds.
    1. Run tests on hardware included in 3mdeb lab.

    As you can see, that layer gathers all parts together. It is  connector
    between high-level Cloud (frontend) and low-level hardware which
    actually use TrenchBoot.

3. **3mdeb lab**

    This layer includes all platforms (Device Under Test) on which builds
    are automatically tested. They are physically placed in our 3mdeb
    office. So far there is only PC Engines apu2, but as mentioned in
    previous articles, as the project develops, new platforms will be added.

Our CI/CD system is still under development and it is constantly expanded and
improved. It still demands more tests and greater integration between elements.
However, it is already used by us with good and promising results. Therefore,
let's find out how it works in practice and what benefits it brings to users.

### Example of usage

As we mentioned, we use GitLab CI tools in our system. The entry point in this
example is then [GitLab CI repository](https://gitlab.com/trenchboot1) set up
by us. It contains 2 groups of repositories:

    1. `TrenchBoot` which contains **mirrors of offcial TrenchBoot upstream
    repositories**

    1. `3mdeb` which contains **mirrors of 3mdeb/TrenchBoot repositories**

![GtiLab CI repositories](img/tb-gitlab-ci-repositories.png)
*GtiLab CI repositories*

Whenever there are changes in any of above repository, related CI/CD process
(called pipeline) is triggered. Its result is indicated as `passed` or `failed`
and dedicated artifacts are published and can be download by user. Let's
analyze it with details on the example of `3mdeb/landing-zone` repository.
Follow the procedure:

1. Open [trenchboot1/3mdeb/landing-zone](https://gitlab.com/trenchboot1/3mdeb/landing-zone/)
repository.

2. Navigate through left sidebar to `CI/CD->Pipelines` page.

    Here you can see all pipelines which were run from the very beginning of
    CI/CD system. Most important indicators are:

        1. Status - passed/failed/canceled;
        1. Pipeline - unique ID of build, which can be entered to see details;
        1. Commit - exact commit which triggered the pipeline;
        1. Stages - what stages were done by pipeline; so far there are `build`
        and `test` stages implemented; in this particular example only `build`
        stage is being done;

    > `Build stage` builds binaries from given repository. `Test stage` tests
    those binaries on real hardware. So far test stage is implemented only in
    [trenchboot1/3mdeb/meta-trenchboot](https://gitlab.com/trenchboot1/3mdeb/meta-trenchboot/)
    pipelines. The test checks if PC Engines apu2 platform boots with just built
    meta-trenchboot operating system.

3. Check details of one of pipelines, e.g. [#140929156](https://gitlab.com/trenchboot1/3mdeb/landing-zone/pipelines/140929156)

    Once again there are builds of particular element which were done. Go to
    details of one of them, e.g.
    [build_debug_enabled-passed](https://gitlab.com/trenchboot1/3mdeb/landing-zone/-/jobs/531119883)

4. Analyze particular build job.

    ![GtiLab CI build job](img/tb-gitlab-ci-build-job.png)
    *GtiLab CI build job details*

    As you can see, there is console with logs informing what job has been done,
    how it was executed and what is final result. On the right panel, there is
    `Job artifacts` section, where you can browse all artifacts and download
    them. For this particular job there is `lz_header.bin` file. As job's name
    suggest it is debug version of it. Via build job's artifacts you can freely
    download all necessary components to update DRTM in your system.

5. Play around and analyze another pipelines, builds and jobs to have better
insight in our CI/CD infrastructure and, the most important, to obtain all
up-to-date binaries of all TrenchBoot components.

### Requirements verification

##### LZ, Bootloader and operating system is built with CI/CD system.

Each element's newest pipeline ends up with artifacts, which can be
downloaded. For details analyze build job logs and browse artifacts if
available.

1. [3mdeb/Landing Zone](https://gitlab.com/trenchboot1/3mdeb/landing-zone/pipelines)

    1. [Non-debug lz_header.bin](https://gitlab.com/trenchboot1/3mdeb/landing-zone/-/jobs/531119881)

    1. [Debug lz_header.bin](https://gitlab.com/trenchboot1/3mdeb/landing-zone/-/jobs/531119883)

    1. [Non-debug landing-zone nixpkg](https://gitlab.com/trenchboot1/3mdeb/nixos-trenchboot-configs/-/jobs/531120101)

    1. [Debug landing-zone nixpkg](https://gitlab.com/trenchboot1/3mdeb/nixos-trenchboot-configs/-/jobs/531120105)

2. [3mdeb/GRUB Bootloader](https://gitlab.com/trenchboot1/3mdeb/grub/pipelines)

    1. [grub build and install](https://gitlab.com/trenchboot1/3mdeb/grub/-/jobs/531110389)

    1. [grub build as nixpkg and install](https://gitlab.com/trenchboot1/3mdeb/nixos-trenchboot-configs/-/jobs/531110460)

3. [3mdeb/Linux kernel](https://gitlab.com/trenchboot1/3mdeb/linux/pipelines)

    1. [bzImage build](https://gitlab.com/trenchboot1/3mdeb/linux/-/jobs/531115909)

    1. [Linux kernel as nixpkg](https://gitlab.com/trenchboot1/3mdeb/nixos-trenchboot-configs/-/jobs/531115939)

4. [3mdeb/meta-trenchboot](https://gitlab.com/trenchboot1/3mdeb/meta-trenchboot/pipelines)

    1. [meta-trenchboot all images](https://gitlab.com/trenchboot1/3mdeb/meta-trenchboot/-/jobs/531049490)

##### CI/CD system SHALL automatically check for regressions of upstream patches to related projects.

Some pipelines besides build triggers test case, which checks component
correctness on PC Engines apu2 platform. Currently it is done for
*meta-trenchboot image*. The test flash SSD disk with meta-trenchboot operating
system with DRTM enabled and boots platform to it. Test is passed if platform
boots correct.

[meta-trenchboot test](link-to-test-stage)

# Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

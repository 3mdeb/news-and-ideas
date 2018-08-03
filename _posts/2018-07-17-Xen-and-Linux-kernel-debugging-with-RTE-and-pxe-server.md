---
post_title: Xen and Linux kernel debugging with RTE and pxe-server
author: Piotr Król
layout: post
published: true
post_date: 2018-07-17 13:20:00

tags:
	- ansible
	- xen
  - linux
categories:
	- Firmware
	- OS Dev
---

We continue our effort to enable IOMMU and as side effect I have to play with
various technologies to exercise reliable development environment which base on
[RTE](TBD: marketing website).

In this blog post I would like to present semi-automated technique to debug
firmware, Xen and Linux kernel. The goal is to have set of tools that help in
enabling various features in Debian-based dom0.

We would like:

* update Linux kernel which is exposed over iPXE server
* update rootfs served over NFS

I will use following components:

* [PC Engines apu2c](http://pcengines.ch/apu2c2.htm)
* [RTE](TBD: link to RTE marketing website)
* [pxe-server](https://github.com/3mdeb/pxe-server) - our dockerized iPXE and
  NFS server
* Xen 4.8
* Linux kernel 4.14.y

My workstation environment is QubesOS 4.0 with Debian stretch VMs, but it should
not make any difference. I had to workaround one obstacle related to our
environment, which is behind VPN, but I also wanted to access outside world in
my fw-dev VM. More information about there can be found [here](https://groups.google.com/d/msg/qubes-users/UakrAG9Frpc/MP9r6XjtAwAJ)

First, I assume that you have working `pxe-server` and [RTE connected to apu2](TBD: blog post based on apu2 theory of operation).

We will start with automation of Linux kernel deployment since this is crucial
while debugging.

Initially this blog post was motivated with [coreboot development effort to enable IOMMU](https://review.coreboot.org/#/c/coreboot/+/26116/).
And error I get with 4.14.50 kernel and mentioned coreboot patches:

```
[ 0.176137] Translation was enabled for IOMMU:0 but we are not in kdump mode 
[ 0.184000] AMD-Vi: Command buffer timeout
[ 0.184000] AMD-Vi: Command buffer timeout
[ 0.184000] AMD-Vi: Command buffer timeout
[ 0.184000] AMD-Vi: Command buffer timeout
[ 0.184000] AMD-Vi: Command buffer timeout
[ 0.184000] AMD-Vi: Command buffer timeout
[ 0.184000] AMD-Vi: Command buffer timeout
```

# Building kernel with Xen support for apu2

```shell
git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
cd linux-stable
git checkout linux-4.14.y
wget https://raw.githubusercontent.com/pcengines/apu2-documentation/master/configs/config-4.14.50 -O .config
make oldconfig
make menuconfig
make -j$(nproc) bzImage deb-pkg
```

Config fetched from github has couple features enabled that make it work as
dom0 e.g. `CONFIG_XEN_DOM0`.

Options that are worth enabling when debugging IOMMU support in Linux kernel is
`Enable IOMMU debugging` aka `CONFIG_IOMMU_DEBUG`.

# Ansible for Linux kernel development

Typically manual procedure of deploying new kernel and rootfs to pxe-server and
NFS would look like below:

1. Compile new kernel as described above
2. Update rootfs using `*.deb` packages from point 1
3. Update kernel using `bzImage` from point 1
4. Boot new system over iPXE

`*.deb` packages and `bzImage` packages have to be deployed to NFS server and
installed inside rootfs what typically mean `chroot`. Installation with system
booted over NFS is way slower.

We assume that server we working with is dedicated for developers. In our
infrastructure we have 2 VMs one with production `pxe-server` and one with
development `pxe-server-dev`. After exercising configuration on
`pxe-server-dev` we applying them to production.

## Flat ansible playbook

I'm not familiar with Ansible design patters so I made it for now flat
playbook. Rough steps of what was done in below scripts are like this:

1. copy all `*.deb` files mentioned in command line to pxe-server
2. mount required subsystems into Debian Dom0 rootfs
3. create script that would be executed in chroot (upgrade and kernel installation)
4. umount subsystems from point 2
5. copy `bzImage` to `/var/netboot/kernels/vmlinuz-dev`
6. force to update netboot to revision that has support for `*-dev` menu
   options

Things left out:
* automatic selection of `*.deb` packages that were created by build process
* previous kernels cleanup in rootfs
* modification of `menu.ipxe` - we rely now on branch in `netboot` repository,
  this not the best solution, because all modifications go through repository

My Xen rootfs looks like that:

```ansible
---
- hosts: my_host
  user: debian
  become: yes
  become_user: root
  become_method: su
  
  tasks:
    # first copy all *.deb files to remote machine
    - name: copy headres
      copy:
        src: "{{ headers }}"
        dest: /var/xen/linux-headers.deb
        group: debian
        owner: debian
    - name: copy linux image
      copy:
        src: "{{ image }}"
        dest: /var/xen/linux-image.deb
        group: debian
        owner: debian
    - name: copy linux image dbg
      copy:
        src: "{{ image_dbg }}"
        dest: /var/xen/linux-image-dbg.deb
        group: debian
        owner: debian
    - name: copy libc
      copy:
        src: "{{ libc }}"
        dest: /var/xen/libc.deb
        group: debian
        owner: debian
    # let's mount required subsystems before chroot
    - name: mount /proc
      mount:
        src: /proc
        path: /var/xen/proc
        opts: bind
        fstype: proc
        state: mounted
    - name: mount /dev
      mount:
        src: /dev
        path: /var/xen/dev
        opts: bind
        fstype: devtmpfs
        state: mounted
    - name: mount /dev/pts
      mount:
        src: /dev/pts
        path: /var/xen/dev/pts
        opts: bind
        fstype: devpts
        state: mounted
    # let's create chroot script
    - name: create script for chroot
      copy:
        content: |
          #!/bin/bash
          apt-get update
          apt-get upgrade
          dpkg -i /*.deb
          apt-get clean
          rm -rf /*.deb
        dest: /var/xen/update_rootfs.sh
        mode: "0755"
    - name: execute script in chroot
      command: "chroot /var/xen /update_rootfs.sh"
    # unmount previously mounted subsystems
    - name: mount /proc
      mount:
        src: /proc
        path: /var/xen/proc
        opts: bind
        fstype: proc
        state: unmounted
    - name: mount /dev/pts
      mount:
        src: /dev/pts
        path: /var/xen/dev/pts
        opts: bind
        fstype: devpts
        state: unmounted
    - name: mount /dev
      mount:
        src: /dev
        path: /var/xen/dev
        opts: bind
        fstype: devtmpfs
        state: unmounted
    # let's add our development kernel and required entry to menu.ipxe
    - name: copy bzImage
      copy:
        src: "{{ bzImage }}"
        dest: /var/netboot/kernels/vmlinuz-dev
        group: debian
        owner: debian
    # force changed version of netboot repo to provide
    # necessary menu.ipxe modifications
    - name: Get netboot repository
      git:
        repo: https://github.com/3mdeb/netboot.git
        version: 5ee81ad561d7898c59ceb422ef19b32b4bcfea56
        dest: /var/netboot
        force: yes
    # replace IP in netboot/menu.ipxe
    - name: Set NFS server IP in netboot/menu.ipxe
      replace:
        path: /var/netboot/menu.ipxe
        regexp: 'replace_with_ip'
        replace: "{{ ansible_default_ipv4.address }}"
```

Running above code with commend similar to:

```
ansible-playbook -b --ask-become-pass xen-rootfs-update.yml --extra-vars \
" \
headers=/mnt/projects/2018/pcengines/apu/src/linux-headers-4.14.56+_4.14.56+-14_amd64.deb \
image=/mnt/projects/2018/pcengines/apu/src/linux-image-4.14.56+_4.14.56+-14_amd64.deb \
image_dbg=/mnt/projects/2018/pcengines/apu/src/linux-image-4.14.56+-dbg_4.14.56+-14_amd64.deb \
libc=/mnt/projects/2018/pcengines/apu/src/linux-libc-dev_4.14.56+-14_amd64.deb \
bzImage=/mnt/projects/2018/pcengines/apu/src/linux-stable/arch/x86/boot/bzImage \
"
```

This command is convoluted and for sure need simplification, but for now I
didn't manage to figure out better solution.

This script should update rootfs and add required kernel. Now we would like to
test what we did with RTE.

# Run Xen Linux dev with RTE

Internally we developed extensive infrastructure that can leverage various
features of RTE for example:

* reserve device under test so one else with intercept test execution - this is
  great in shared environment
* check hardware configuration if it makes sense to run this test
* automatically support all OSes exposed by `pxe-server`

To verify our new kernel we would like to use last feature. Simplest `dev.robot` may
look like that:

```
*** Settings ***
Library     SSHLibrary    timeout=20 seconds
Library     Telnet    timeout=20 seconds
Library     Process
Library     OperatingSystem
Library     String
Library     RequestsLibrary
Library     Collections

Suite Setup            Open Connection And Log In
Suite Teardown         SSHLibrary.Close All Connections

Resource    rtectrl-rest-api/rtectrl.robot
Resource    variables.robot
Resource    keywords.robot

*** Test Cases ***

DEV1.1 Boot Xen Linux dev
    Run iPXE shell
    iPXE menu    ${pxe_ip}     ${http_port}    ${filename}
    iPXE boot entry    Xen Linux dev
    Serial root login Linux    debian
```

There are couple interesting things to explain here:

* we use `rtectrl-rest-api/rtectrl-rest-api.robot` - this library provide
  control over GPIO, it is quite easy to implement your own if you have RTE since
  it is just interaction with `sysfs`
* `Run iPXE shell`, `iPXE menu`, `iPXE boot entry` came from our iPXE library,
  which just parse PC Engines apu2 serial, it works only with `pxe-server` and
  firmware released by 3mdeb at [pcengines.github.io](https://pcengines.github.io/).
* `Serial root login Linux` is just login prompt wrapper with password as
  parameter

Also to run above test you need modified Robot Framework which you can find [here](https://github.com/3mdeb/robotframework/tree/get_line_number_containing_string).

If you are interested in RTE usage please feel free to contact us. Having RTE
you can achieve the same goal using various other methods (without our RF
scripts).

We plan to provide some working examples of RTE and Robot Framework during our
[workshop session](TBD) on [Open Source Firmware Conference](https://osfc.io/).

# How RTE-supported development workflow look like?

Typically you work on your kernel modification and want to run it on hardware,
so you point above ansible to deploy code to pxe-server.

You may ask: _why use some external pxe-server and not just install everything locally?_ 
This implies couple problems:
* target hardware have to be connected to your local network
* every time you reboot computer you have some additional steps to finish setup
* you can start container automatically, but still it consume resources on your
  local machine which you may use for other purposes (e.g. compilation)

RTE if first about __remote__ and second about __automation__. Of course RTE
and `pxe-server` should always be behind VPN.

Getting back to workflow. It may look like that:

* build custom kernel as described above - time highly depends on your
  hardware
* deploy kernel to pxe-server - time: 1min15s
* run test - e.g. booting Xen Linux dev over iPXE RTE time: 1min40s
* rebuild firmware - assuming you use [pce-fw-builder](https://github.com/pcengines/pce-fw-builder) RTE time: ~5min
* firmware flashing and verification - RTE time: 

Please note that:
* rebuilding firmware is not just building coreboot, but putting together all
  components (memtest, SeaBIOS, sortbootorder, iPXE) to make sure we didn't
  messed something `pce-fw-builder` preform `distclean` everytime, we plan to
  change that so optionally it will reuse cached repositories, please track
  [this issue](https://github.com/pcengines/pce-fw-builder/issues/16)

Then you can run `dev.robot` to see
how boot log look like. In my case mentioned at the begging I wanted initially
to get better logs from kernel to continue investigation of repeating:

```
AMD-Vi: Command buffer timeout 
```

# Summary

We strongly believe in automation in firmware and embedded systems development.
We think there is not enough validation in coming IoT era. Security requires
reproducibility and validation. Because of that we try to automate our
workflows, what is time consuming, but left us with some automation that always
can be helpful in streamlining everyday work. We never know how many iteration
given debugging session will take, why not to automate it? Or even better why
not to try Test Driven Bug Fixing?

If you think we can help in validation of your firmware or you looking for
someone who can boot your product by leveraging advanced features of used
hardware platform feel free to drop us email to `contact<at>3mdeb.com`.


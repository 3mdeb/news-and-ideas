---
post_title: pxe-server release v1.0.0
author: Piotr Król
layout: post
published: true
post_date: 2018-08-17 16:00:00

tags:
	- pxe
	- apu2
	- coreboot
categories:
	- Firmware
    - OS Dev
---

We mentioned many times that [pxe-server](https://github.com/3mdeb/pxe-server)
helps us in embedded firmware development as well as in debugging various
issues. `pxe-server` is part of our infrastructure and we keep maintaining it,
since we rely on it during regression tests of PC Engines firmware.

Recently I enter land of IOMMU and Xen, this lead me to need of Linux kernel as
well as Xen kernel debugging and development. It happen that our `pxe-server`
is not exactly prepared to help in seamless development, because of that we
created `pxe-server-dev` which will serve as testing/development area before
things can go to production `pxe-server`.

Because of that I decided to publish instruction and all required scripts to
provide more mature infrastructure for our regressions test and firmware
development.

Overall we have to support 2 different workflows:

* `pxe-server` releases - this means we building everything from scratch and
  tag all possible components. The procedure for that is as follows:
    - build rootfs
    - build kernels
    - install kernels in rootfs
    - create release candidate package (compressed rootfs)
    - perform validation
    - if tests passed install package in production
* development - this workflow requires quick, typically simple changes like:
    - adding/removing packages
    - changing configuration
    - updating Linux or Xen kernel
    all those actions should be handled on top of release rootfs, to handle
    things reasonably fast we have to keep rootfs release in cache

# Proxmox

Internally we have Proxmox setup on Dell PowerEdge R610, which we use for
production `pxe-server` as well as `pxe-server-dev`. I started setup with
`pxe-server-dev` since I need some place to work on streamlining of whole
infrastructure, which were used in production.

`pxe-server-dev`:
* Memory: 2GiB
* Processors: 2
* Based on: template-debian-9.4.0-amd64-netinst (Linked clone)
* HDD: 32GB
* Networking: bridged

`template-debian-9.4.0-amd64-netinst` is just plain netinstall without
additional configuration, except:
* SSH server which is required for ansible
* `apt-transport-https` package
* removing cdrom, which is initially required for installation iso

Over time we should think about using `proxmox_kvm` to setup things. On the
other hand I'm not huge fan of KVM and think Xen have much more sense, so in
future we may plan to move away from Proxmox.

# pxe-server release process

So far there was no `pxe-server` release process we just pushed modifications
to master and live with that. Whole `pxe-server` architecture is convoluted.
First it is not just `pxe-server`, to be more precise it is HTTP and NFS
container with running servers, which as parameters take directories with
content that should be served.

After setting up `pxe-server-dev` we prepared first release of `pxe-server` to
make sure both machine have the same stable operating system. We also employed
RTE to perform regression tests for server quality confirmation.

# rootfs issues

Typically we use quite modified rootfs for testing purposes. Our Debian rootfs
contain Xen, modules for 4.14.y, 4.15.y and 4.16.y, that means couple things
required to prepare rootfs:

* kernels compilation - typically we use `deb-pkg` target to get debian
  packages.
* various packages installation - truly we made a mess over 2 years of using
  `pxe-server`, packages were randomly installed and we lost control and rootfs
  reproducibility, initially we tracked modifications in plain text files, but
  it quickly happen to be not scalable

Also because of multiple rootfses deployment time was quite long 14min.

## Reproducible environment for Debian rootfs

Running `debootstrap` and `chroot` on workstation or even dedicated server
doesn't seem to be good approach, since either you have OS on workstation in
unknown state either you have to have separate server that perform just rootfs
build. So we thought about running procedures in Docker, but it has some problems:

* `debootstrap` requires `chroot`
* `chroot` requires container with `--priveleged` flag
* calling shell script for building rootfs feels like getting back to where we
  came from (aka scripts not maintainable over long time)

Because of above we decided that creation of `debian-rootfs-builder`
mini-project, which rely on Ansible playbook is the right path to go.

## stretch-backports

It is important to note that using `FROM debian:stable` may not deliver
expected package versions. For example Ansible in Debian stable is `2.2.1`
which is way too old to have nice features like `archive`

There is `backports` repository for Debian stable and can be added to
`Dockerfile` in following way `FROM debian:stretch-backport`. Please remember
that to utilize backports repository you have to explicitly mention it in `apt`
command as follows:

```
apt -t stretch-backports install ansible
```

This should give you recent ansible version.

## rootfs deployment considerations

Having `tar.gz` package with native Debian rootfs is not all, since now the
question is "what should be correct deployment and modification procedure?".

* Shall we have base rootfs, which we keep in safe place and all further
  modifications are automatically deployed on top of it?
* Shall we have generate rootfs each time we do modification?

Because of Debian nature there may be changes in between 2 rootfses creation,
that means 2 subsequent `debootstrap` calls doesn't have to give the same
result. This behavior may introduce additional point of failure. On the other
hand we should use whatever users are using and users should have what most
recent official repositories contain. Functionally there should be no
difference between 2 subsequent `debootstrap` calls.

# pxe-server release workflow

## build rootfs

Building plain Debian rootfs means just 2 calls of `debootstrap`. This was
implemented in [debian-rootfs-builder](https://github.com/3mdeb/debian-rootfs-builder/pull/1/files#diff-4fc81d767cf7386881dd85189214bdd2).

## build kernels

We decide that testing makes sense for 2 top longterm stable kernels (4.9.y and
4.14.y). If there will be customers or users requests we will reconsider that
approach.

Ansible role that makes compilation possible is
[here](https://github.com/3mdeb/debian-rootfs-builder/pull/1/files#diff-5b89c53e63924bf47ad5a38922d99c67).

It is important to note that our `pxe-server` not only need kernel installed in
rootfs, but also `bzImage` that can be fetched directly from HTTP. That's why we
also build `bzImage` and preserve it for further use.

## install software, kernels and configure system

Role `packages` contain task installing all required software for our rootfs.
`config` modify fstab to mount `proc` and `sys` filesystem as well as configure
password.

For kernel `dpkg -i` call makes the thing. It is important to clean up after
installation so no artifact will be left in release package.

We have separate roles for each of those tasks. It is important to correctly
play with `connection` parameters since some roles should be executed in
container and some in chroot.

## create release candidate package (compressed rootfs)

Finally we compress rootfs with and add `rootfs_version` in package name. This
package and kernels should be deployed to `pxe-server`, of course we first use
testing environment, which is called `pxe-server-dev`.


## perform validation

All `menu.ipxe` options should work. In `v1.0.0` we have following menu:

```
Xen
Xen dev
Xen Linux dev
Debian stable netboot dev
Debian stable netboot 4.9.y
Debian stable netboot 4.14.y
Debian stable netinst
Debian i386 stable netinst
Voyage netinst 0.11.0
Ubuntu LTS netinst
Core OS  netinst
Core 6.4
```

Those 11 tests should pass before we can deploy release to production.
`netinst` tests can be performed only when device has required hardware.

## deploy to production

Deployment can be done using `pxe-server.yml` from `pxe-server` repository.
Workflow should look as follows:

# Performance

For [debian-rootfs-builder](https://github.com/3mdeb/debian-rootfs-builder) I
have following performance statistics:

```
Tuesday 21 August 2018  16:01:58 +0000 (0:00:51.188)       0:42:09.618 ********
===============================================================================
linux-kernel --------------------------------------------------------- 1341.78s
packages -------------------------------------------------------------- 798.20s
debootstrap ----------------------------------------------------------- 327.46s
command ---------------------------------------------------------------- 51.19s
setup ------------------------------------------------------------------- 8.85s
config ------------------------------------------------------------------ 1.93s
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
total ---------------------------------------------------------------- 2529.40s
Tuesday 21 August 2018  16:01:58 +0000 (0:00:51.188)       0:42:09.617 ********
===============================================================================
packages : install packages ------------------------------------------- 798.20s
linux-kernel : make deb-pkg ------------------------------------------- 613.37s
linux-kernel : make deb-pkg ------------------------------------------- 565.16s
debootstrap : debootstrap second stage -------------------------------- 193.23s
debootstrap : debootstrap first stage --------------------------------- 115.25s
compress rootfs -------------------------------------------------------- 51.19s
linux-kernel : make mrproper ------------------------------------------- 30.88s
linux-kernel : decompress Linux "4.9.122" ------------------------------ 22.09s
linux-kernel : decompress Linux "4.14.65" ------------------------------ 20.01s
linux-kernel : get Linux "4.9.122" ------------------------------------- 19.28s
debootstrap : install packages ----------------------------------------- 18.97s
linux-kernel : get Linux "4.14.65" ------------------------------------- 17.15s
linux-kernel : remove everything except artifacts ---------------------- 14.65s
linux-kernel : make mrproper ------------------------------------------- 13.45s
linux-kernel : make olddefconfig ---------------------------------------- 9.12s
linux-kernel : remove everything except artifacts ----------------------- 6.58s
Gathering Facts --------------------------------------------------------- 4.62s
Gathering Facts --------------------------------------------------------- 4.23s
linux-kernel : make olddefconfig ---------------------------------------- 3.94s
linux-kernel : copy bzImage to known location --------------------------- 1.91s
Playbook run took 0 days, 0 hours, 42 minutes, 9 seconds
```

As you can see most time consuming are package installation, kernel compilation
and debootstrap. Possible ways for addressing those bottlenecks:

* apt-get caching proxy like [apt-cacher-ng](https://wiki.debian.org/AptCacherNg)
* second needs `ccache` configuration, difference between build time may
  indicate that container indeed used `ccache`, since it is installed, but we
  probably should think about mounting cache from outside world - interesting
  statistics can be found [here](https://nickdesaulniers.github.io/blog/2018/06/02/speeding-up-linux-kernel-builds-with-ccache/)
* third, may be speed up by apt-get cache and some improvements that are on the
  way to Debian - [discussed here](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=871835), or use things like
  [eatmydata](https://stackoverflow.com/questions/36330942/is-it-possible-to-speed-up-debootstrap-by-disabling-fsync)

When rootfs and kernels were prepared we can deploy to `pxe-server-dev` and
test. Deployment performance looks like this (assuming prepared VM in Proxmox):

```

```

# TODO

* `proxmox_kvm` - for VM automation
* there should better way to install debian in proxmox, right now it contain
  cdrom in source.list
* performance improvements
    - ansible measure performance
    - ccache for kernel compilation
    - ideas for improving debootstrap speed, there are some patches [here](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=871835)
* syntax and best practice
    - ansible lint
* 

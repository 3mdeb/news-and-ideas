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


# TODO

* `proxmox_kvm` - for VM automation
* there should better way to install debian in proxmox, right now it contain
  cdrom in source.list

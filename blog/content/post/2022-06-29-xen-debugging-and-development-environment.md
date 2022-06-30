---
title: Infrastructure for Xen development and debugging
cover: /covers/SW.png
author:
    - piotr.krol
    - norbert.kaminski
layout: post
published: false
date: 2022-06-30

tags:
  - xen
  - coreboot
categories:
  - Firmware
  - OS Dev
  - Security

---

# Intro

In the 2018th [OSFC](https://2018.osfc.io), we were presented AMD IOMMU enabling
for PC Engines apuX (GX-412TC) platforms. You can watch the presentation video
[here](https://www.youtube.com/watch?v=5JoEuh9qXx0&list=PLJ4u8GLmFVmoRCX_gFXV6fhWmsOQ5cmuj&index=14)
Our hypervisor of choice was Xen and we used it to verify the PCI pass-through
feature. Unfortunately, the booting process was not exactly stable and the
platform from time to time hung on the same log:

```bash
(XEN) HVM: SVM enabled
(XEN) HVM: Hardware Assisted Paging (HAP) detected
(XEN) HVM: HAP page sizes: 4kB, 2MB, 1GB
(XEN) HVM: PVH mode not supported on this platform
(XEN) spurious 8259A interrupt: IRQ7.
(XEN) CPU1: No irq handler for vector e7 (IRQ -2147483648)
(XEN) CPU2: No irq handler for vector e7 (IRQ -2147483648)
(
```

Always the same place in code, it seems to start printing `(XEN) Brought up 4
CPUs`, so suspicious code is probably right after [this log](https://xenbits.xen.org/gitweb/?p=xen.git;a=blob;f=xen/arch/x86/setup.c;h=468e51efef7a848f24acab43d69d74ab126b4b0e;hb=4507bb6ae2b778a484394338452546c1e4fc6ae5#l1544).

We started to write that post quite long ago, but because recent Xen 4.16.1
release we decide to get back to the problem and see what is the current state.

# Debugging environment considerations

Because of that, I decided to debug Xen, but first I had to get through the
compilation and deployment procedure. In general, I saw a couple of options for
Xen compilation:

* Debian package modification - get sources through `apt source xen` and
continue with the Debian way of building packages - this can be done either on
a host, in rootfs, or Docker container
* directly from Xen source tree using `make debball` - this can be done either
on the host or in the container
* directly from Xen source tree using `make build-xen` and installation
with `sudo make install-xen`

Internet is not straightforward about the best method
([Xen documentation](https://wiki.xenproject.org/wiki/Compiling_Xen_From_Source)).
The third option was the only option for me to build Xen. Here is the
step-by-step instruction on how to build and install Xen from the source:

1. Install build essential:
    ```bash
    $ sudo apt-get install build-essential
    ```
2. Enable source code in the `software-properties-gtk`
3. Install the python config package
    ```bash
    $ pip3 install python-config
    ```
4. Clone Xen source
    ```bash
    $ git clone git@github.com:xen-project/xen.git
    ```
5. Configure project
    ```bash
    $ cd xen && ./configure
    ```
6. Build Xen
    ```bash
    $ make build-xen
    ```
7. Install Xen
    ```bash
    $ sudo make install-xen
    ```

More to that all of the methods can be applied through frameworks.
Debian rootfs can be built using [isar](https://github.com/ilbers/isar) and
there is always a way to narrow everything to OpenEmbedded/Yocto meta layer
which should build only what we need. The last option is good for production,
but development may be hard in a limited environment that Yocto produces by
default.

## Xen dockerized building environment

I chose the second option for that purpose. I have prepared a Docker
container with all required packages
([3mdeb/xen-docker](https://github.com/3mdeb/xen-docker)):

```bash
$ git clone git@github.com:3mdeb/xen-docker.git
$ cd xen-docker
$ docker build -t 3mdeb/xen-docker .
```

I cloned the Xen source and I run the docker container.

```bash
$ git clone git@github.com:xen-project/xen.git
$ cd xen
$ docker run --rm -it -v $PWD:/home/xen -w /home/xen 3mdeb/xen-docker /bin/bash
```
Then I built the Xen package:

```
(docker-container)$ git checkout <version>
(docker-container)$ ./configure --enable-githttp --enable-systemd
# there is time now to customize .config
(docker-container)$ make debball
```

> Note: `--enable-systemd` requires a `libsystemd-dev` package to be installed
> in the container.

Build result will be placed in `$XEN_SRC_DIR/dist` as
`xen-upstream-<version>.deb`. For Debian-based systems, it is easy to install
it with `dpkg` or `apt`. The package contains all necessary components for
the host OS along with the Xen kernel.

> Note that the host OS still will require Dom0 Kernel for Xen

To update the pxe-server with new Xen image, install the
`xen-upstream-<version>.deb` in rootfs which hosts the VMs and copy the Xen
kernel from `/boot/xen-<version>.gz` to tftpboot/httpboot directory (gunzip the
kernel first).

After whole this effort, I was able to boot my freshly built Xen on apu2c4 with
Debian host and Debian guest OS. Now that I have prepared the developing
procedure I can start narrowing down all the issues.

## Possible use cases

The ability to build Xen with custom changes opens the door to creating
[custom solutions and products](https://3mdeb.com/hypervisors-development/).
In addition, it provides an opportunity to workaround well-known problems and
helps fix them in the mainline in the long term. A adequate example of this
approach is [adding support for the Trenchboot in the Xen](https://blog.3mdeb.com/2020/2020-10-15-xen-implementation-for-trenchboot/).
As described in the blog post, our engineers added workaround support in Xen for
Secure Startup via SKINIT. With the help of Andrew Cooper (Xen maintainer),
after a few code changes, the
[patch](https://xenbits.xen.org/gitweb/?p=xen.git;a=commit;h=e4283bf38aae6c2f88cdbdaeef0f005a1a5f6c78)
was merged into the main.

As a long-time maintainer of PC Engines platforms, 3mdeb sees the opportunity to
create hardened router products that help maintain the security of the corporate
network. In addition, custom Xen gives ability to verify various firmware
features e.g. IOMMU configuration and many others which are verified by Xen
kernel while booting.

Furthermore, once a custom Xen design has been created, the stability of the
solution must be ensured. The easiest way to achieve this is to create a CI/CD
that builds and tests the solution. Our test automation team has historically
provided Xen tests for our PC Engines platform in every release. This is now
outdated, as the tests were run using Xen 4.8 (the current version of Xen
at the date of this blog post is 4.17). We plan to improve the transparent
validation infrastructure for [Dasharo-compatible](https://dasharo.com/)
products soon.

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of the used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email to `contact<at>3mdeb<dot>com`. If you are interested in
similar content feel free to [sign up for our newsletter](http://eepurl.com/gfoekD).

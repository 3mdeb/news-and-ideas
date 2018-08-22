---
post_title: Optimize performance in Docker containers used by Embedded Systems Consulting business
author: Piotr Król
layout: post
published: true
post_date: 2018-08-22 15:00:00

tags:
	- docker
categories:
	- Firmware
	- Miscellaneous

---

In 3mdeb we use Docker heavily. Main tasks that we perform using it are:

* firmware and embedded software building - each software in Embedded System
  requires little bit different building environment, configuring those
  development environments on your host quickly made mess in your system for
  daily use, because of that we created various containers which I enumerate
  below
* trainings/workshops - when we perform trainings we don't want to waste time
  for users to reconfigure environment. In general we have 2 choices: VM or
  containers. Since we use containers for building and development we prefer
  containers or containers in VMs while performing trainings.
* rootfs building for infrastructure deployment - we maintain [pxe-server](https://github.com/3mdeb/pxe-server)
  project which helps us in firmware testing and development in that project we
  have need for custom rootfs and kernels, we decided to combine Docker and
  Ansible for reliable building of that infrastructure

To list some of our repositories:

* [yocto-docker](https://github.com/3mdeb/yocto-docker) - container for
  building Yocto
* [edk2-docker](https://github.com/3mdeb/edk2-docker) - container for building
  edk2 UEFI specification open source implementation
* [xen-docker](https://github.com/3mdeb/xen-docker) - container for building
  Xen hypervisor
* [debian-rootfs-builder](https://github.com/3mdeb/debian-rootfs-builder) -
  container for building Debian rootfs and Linux kernels
* [armbian-docker](https://github.com/3mdeb/armbian-docker) - docker for
  building Armbian Debian distribution for various ARM platforms
* [zephyr-docker](https://github.com/3mdeb/zephyr-docker) - container for
  building Zephyr RTOS
* [esp-open-sdk-docker](https://github.com/3mdeb/esp-open-sdk-docker) -
  container for bulding ESP Open SDK Espressify Open RTOS
* [docker-mbed-cli](https://github.com/3mdeb/docker-mbed-cli) - container for
  building and running CLI of mbedOS
* [arch-pkg-builder](https://github.com/3mdeb/arch-pkg-builder) - container for
  building Arch packages

Some are actively maintained some are not, some came from other projects, some
where created from scratch, but all of them have value for Embedded Systems
Developers.

Those solutions are great but we think it is very important in all those use
cases to optimize performance. To clarify we have to distinguish most time
consuming tasks in above containers:

* code compilation - there are books about that topic, but since we use mostly
  Linux, we think that key factor is to have support for
  [ccache](https://ccache.samba.org/) and this is our first goal in this post

* packages installation - even when you using `httpredir` for `apt` you still
  will spent significant amount of time installing and downloading, because of
  that it is very important to have locally or on server in LAN `apt` caching
  proxy like `apt-cacher-ng`, we will show how to use it with Docker on build
  and runtime

# ccache

Following example will show `ccache` usage with `xen-docker`. Great post about
that topic was published by Tim Potter [here](http://frungy.org/docker/using-ccache-with-docker).

# apt-cacher-ng

There 2 use case for `apt-cacher-ng` in our workflows. One is Docker build
time, which can be time consuming since all packages and its dependencies are
installed in base image. Second it runtime, when you need some package that may
have extensive dependencies e.g. `xen-systema-amd64`.

First let's setup `apt-cacher-ng`. Some guide may be found in [Docker documentation](https://docs.docker.com/engine/examples/apt-cacher-ng/), but we will modify it little bit.

Ideally we would like to use `docker compose` to setup `apt-cacher-ng`
container whenever it is not set, or have dedicated VM which server this
purpose. In this post we consider local cache. Dockerfile may look like this:

```
FROM        ubuntu

RUN     apt-get update && apt-get install -y apt-cacher-ng

EXPOSE      3142
CMD     chmod 777 /var/cache/apt-cacher-ng && /etc/init.d/apt-cacher-ng start && tail -f /var/log/apt-cacher-ng/*
```

Build and run:

```
docker build -t apt-cacher .
docker run -d -p 3142:3142 -v $PWD/apt_cache:/var/cache/apt-cacher-ng --name cacher-container apt-cacher
docker logs -f cacher-container
```

Output should look like this:

```
* Starting apt-cacher-ng apt-cacher-ng
WARNING: No configuration was read from file:sfnet_mirrors
   ...done.
   ==> /var/log/apt-cacher-ng/apt-cacher.err <==

   ==> /var/log/apt-cacher-ng/apt-cacher.log <==
```

We should also see that cacher listen on port `3142`:

```
[16:40:01] pietrushnic:~ $ netstat -an |grep 3142 
tcp6       0      0 :::3142                 :::*                    LISTEN 
```

Now we can run docker building with appropriate parameters:

```
docker build --build-arg HTTP_PROXY=http://192.168.4.112:3142/ -t 3mdeb/xen-docker .| ts -s '[%.T]'
```

## performance measures

`xen-docker` container build without `apt-cacher-ng`. To measure what is going
on during container build we using `ts` from `moreutils` package.

Without cacher:

```
docker build -t 3mdeb/xen-docker .| ts -s '[%.S]'
```

With clean cacher:

With filled cacher:

```
docker build --build-arg http_proxy=http://<CACHER_IP>:3142/ -t 3mdeb/xen-docker .| ts -s '[%.T]'
```


# Summary

If you have other ideas about optimizing code compilation or container build
time please feel free to comment.

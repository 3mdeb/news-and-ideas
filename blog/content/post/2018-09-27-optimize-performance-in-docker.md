---
title: Optimize performance in Docker containers used by Embedded Systems Consulting business
author: piotr.krol
layout: post
published: true
date: 2018-09-27

tags:
  - docker
categories:
  - Firmware
  - Miscellaneous

---

In 3mdeb we use Docker heavily. Main tasks that we perform using it are:

* firmware and embedded software building - each software in Embedded System
  requires little bit different building environment, configuring those
  development environments on your host may quickly make a mess in your system for
  daily use, because of that we created various containers which I enumerate
  below
* trainings/workshops - when we perform trainings we don't want to waste time
  for users to reconfigure the environment. In general, we have 2 choices: VM or
  containers. Since we use containers for building and development we prefer
  containers or containers in VMs while performing trainings.
* rootfs building for infrastructure deployment - we maintain [pxe-server](https://github.com/3mdeb/pxe-server)
  project which helps us in firmware testing and development. In that project we
  have a need for custom rootfs and kernels, we decided to combine Docker and
  Ansible for a reliable building of that infrastructure

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

Some are actively maintained, some are not, some came from other projects, some
were created from scratch, but all of them have value for Embedded Systems
Developers.

Those solutions are great but we think it is very important in all those use
cases to optimize performance. To clarify we have to distinguish the most
time-consuming tasks in above containers:

* code compilation - there are books about that topic, but since we use mostly
  Linux, we think that key factor is to have support for
  [ccache](https://ccache.samba.org/) and this is our first goal in this post

* packages installation - even when you are using `httpredir` for `apt` you
  still will spent a significant amount of time installing and downloading,
  because of that it is very important to have locally or on server in LAN `apt`
  caching proxy like `apt-cacher-ng`, we will show how to use it with Docker on
  build and runtime

# ccache

Following example will show `ccache` usage with `xen-docker`. Great post about
that topic was published by Tim Potter [here](http://frungy.org/docker/using-ccache-with-docker).

Of course, to use `ccache` in our container we need it installed, so make sure
your `Dockerfile` contains that package. You can take a look at [xen-docker Dockerfile](https://github.com/3mdeb/xen-docker/blob/master/Dockerfile#L15).

I installed `ccache` on my host to control its content:

```
cache directory                     /home/pietrushnic/.ccache
primary config                      /home/pietrushnic/.ccache/ccache.conf
secondary config      (readonly)    /etc/ccache.conf
cache hit (direct)                     0
cache hit (preprocessed)               0
cache miss                             0
cache hit rate                      0.00 %
cleanups performed                     0
files in cache                         0
cache size                           0.0 kB
max cache size                       5.0 GB
```

Moreover it is important to pay attention to directory structure and
volumes, because we can easy end up with not working `ccache`. Of course clear
indication that `ccache` works is that it show some statistics. Configuration
of `ccache` in Docker files should look like this:

```
ENV PATH="/usr/lib/ccache:${PATH}"
RUN mkdir /home/xen/.ccache && \
	chown xen:xen /home/xen/.ccache
```

Then to run container with `ccache` we can pass our `~/.ccache` as volume. For
single-threaded compilation assuming you checked out correct code and called
`./configure`:

```

```

Before  we start testing performance we also have to mention terminology little
bit, below we use terms `cold cache` and `hot cache`, this was greatly
explained on [StackOverflow](https://stackoverflow.com/questions/22756092/what-does-it-mean-by-cold-cache-and-warm-cache-concept)
so I will not repeat myself. In short cold means empty and hot means that there
are some values from previous runs.


## Performance measures

No `ccache` single-threaded:

```
docker run --rm -it -v $PWD:/home/xen -w /home/xen 3mdeb/xen-docker \
make debball| ts -s '[%.T]'
(...)
[00:13:10.006206] dpkg-deb: building package 'xen-upstream' in 'xen-upstream-4.8.4.deb'.
```

No `ccache` multi-threaded:

```
docker run --rm -it -v $PWD:/home/xen -w /home/xen 3mdeb/xen-docker \
make -j$(nproc) debball| ts -s '[%.T]'
(...)
[00:07:53.910527] dpkg-deb: building package 'xen-upstream' in 'xen-upstream-4.8.4.deb'.
```

Let's make sure ccache is empty

```
[22:52:57] pietrushnic:~ $ ccache -zcC
Statistics cleared
Cleaned cache
Cleared cache
```

Cold cache:

```

docker run --rm -it -e CCACHE_DIR=/home/xen/.ccache -v $PWD:/home/xen  \
-v $HOME/.ccache:/home/xen/.ccache -w /home/xen 3mdeb/xen-docker make -j$(nproc) \
debball | ts -s '[%.T]'
(...)
[00:07:37.440563] dpkg-deb: building package 'xen-upstream' in 'xen-upstream-4.8.4.deb'.
```

And the stats of `ccache`:

```
cache directory                     /home/pietrushnic/.ccache
primary config                      /home/pietrushnic/.ccache/ccache.conf
secondary config      (readonly)    /etc/ccache.conf
stats zero time                     Wed Aug 22 23:29:32 2018
cache hit (direct)                    38
cache hit (preprocessed)              19
cache miss                          3750
cache hit rate                      1.50 %
called for link                      133
called for preprocessing            1498
compiler produced empty output        61
compile failed                         6
preprocessor error                    12
bad compiler arguments                10
unsupported source language            2
autoconf compile/link                 56
unsupported compiler option            2
output to stdout                       4
no input file                       5998
cleanups performed                     0
files in cache                      8887
cache size                         203.1 MB
max cache size                       5.0 GB
```

Hot cache:

```
docker run --rm -it -e CCACHE_DIR=/home/xen/.ccache -v $PWD:/home/xen  \
-v $HOME/.ccache:/home/xen/.ccache -w /home/xen 3mdeb/xen-docker make -j$(nproc) \
debball | ts -s '[%.T]'
(...)
[00:05:40.766517] dpkg-deb: building package 'xen-upstream' in 'xen-upstream-4.8.4.deb'.
```

And the stats of `ccache`:

```
cache directory                     /home/pietrushnic/.ccache
primary config                      /home/pietrushnic/.ccache/ccache.conf
secondary config      (readonly)    /etc/ccache.conf
stats zero time                     Wed Aug 22 23:29:32 2018
cache hit (direct)                  3557
cache hit (preprocessed)             229
cache miss                          3767
cache hit rate                     50.13 %
called for link                      266
called for preprocessing            2945
compiler produced empty output       122
compile failed                        12
preprocessor error                    14
bad compiler arguments                14
unsupported source language            4
autoconf compile/link                 64
unsupported compiler option            4
output to stdout                       8
no input file                       8811
cleanups performed                     0
files in cache                      9023
cache size                         204.4 MB
max cache size                       5.0 GB
```

I'm not `ccache` expert and cannot explain all results e.g. why hit rate is so
low, when we compile the same code?

To conclude, we can gain even 30% with hot cache. Biggest gain we have when
using multithreading, but this highly depends on CPU, in my case I had 8 jobs
run simultaneously and gain was 40% in compilation time.

# apt-cacher-ng

There 2 use case for `apt-cacher-ng` in our workflows. One is Docker build
time, which can be time-consuming since all packages and its dependencies are
installed in the base image. Second is runtime, when you need some package that
may have extensive dependencies e.g. `xen-systema-amd64`.

First, let's setup `apt-cacher-ng`. Some guide may be found in [Docker documentation](https://docs.docker.com/engine/examples/apt-cacher-ng/), but we will modify it a little bit.

Ideally, we would like to use `docker compose` to set up `apt-cacher-ng`
container whenever it is not set, or have dedicated VM which serves this
purpose. In this post, we consider local cache. Dockerfile may look like this:

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

The output should look like this:

```
* Starting apt-cacher-ng apt-cacher-ng
WARNING: No configuration was read from file:sfnet_mirrors
   ...done.
   ==> /var/log/apt-cacher-ng/apt-cacher.err <==

   ==> /var/log/apt-cacher-ng/apt-cacher.log <==
```

We should also see that cacher listens on port `3142`:

```
[16:40:01] pietrushnic:~ $ netstat -an |grep 3142
tcp6       0      0 :::3142                 :::*                    LISTEN
```

Dockerfile should contain following environment variable:

```
ENV http_proxy ${http_proxy}
```

Now we can run docker building with appropriate parameters:

```
docker build --build-arg http_proxy=http://<CACHER_IP>:3142/ -t 3mdeb/xen-docker .| ts -s '[%.T]'
```

## performance measures

`xen-docker` container build without `apt-cacher-ng`. To measure what is going
on during container build we are using `ts` from `moreutils` package.

Without cacher:

```
docker build -t 3mdeb/xen-docker .| ts -s '[%.S]'
(...)
[00:07:13.723282] Successfully tagged 3mdeb/xen-docker:latest
```

With cold cache:

```
docker build --build-arg http_proxy=http://<CACHER_IP>:3142/ -t 3mdeb/xen-docker .| ts -s '[%.T]'
(...)
[00:06:55.051968] Successfully tagged 3mdeb/xen-docker:latest
```

With hot cache:

```
docker build --build-arg http_proxy=http://<CACHER_IP>:3142/ -t 3mdeb/xen-docker .| ts -s '[%.T]'
(...)
[00:05:50.237480] Successfully tagged 3mdeb/xen-docker:latest
```

Assuming that the network conditions did not change between runs to extent of
30s delay we can conclude:

* using cacher even with cold cache is better than nothing, it gives the
  speedup of about 5%
* using hot cache can spare ~20% of normal container build time, if significant
  amount of that time is package installation

Of course, those numbers should be confirmed statistically.

# Let's try something more complex

Finally we can try to run much more sophisticated stuff like our
[debian-rootfs-builder](https://github.com/3mdeb/debian-rootfs-builder). This
code contain mostly compilation and package installation through `apt-get`.

Initial build statistics were quite bad:

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

After adding `apt-cacher` this improved a lot - 37%!:

```
Tuesday 21 August 2018  22:48:46 +0000 (0:00:53.340)       0:26:40.226 ********
===============================================================================
linux-kernel --------------------------------------------------------- 1272.91s
debootstrap ----------------------------------------------------------- 265.41s
command ---------------------------------------------------------------- 53.34s
setup ------------------------------------------------------------------- 8.29s
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
total ---------------------------------------------------------------- 1599.95s
Tuesday 21 August 2018  22:48:46 +0000 (0:00:53.341)       0:26:40.225 ********
===============================================================================
linux-kernel : make deb-pkg ------------------------------------------- 608.31s
linux-kernel : make deb-pkg ------------------------------------------- 510.51s
debootstrap : debootstrap second stage -------------------------------- 194.68s
compress rootfs -------------------------------------------------------- 53.34s
debootstrap : debootstrap first stage ---------------------------------- 52.27s
linux-kernel : decompress Linux "4.14.65" ------------------------------ 25.45s
linux-kernel : make mrproper ------------------------------------------- 24.57s
linux-kernel : decompress Linux "4.9.122" ------------------------------ 22.61s
debootstrap : install packages ----------------------------------------- 18.45s
linux-kernel : get Linux "4.14.65" ------------------------------------- 17.44s
linux-kernel : get Linux "4.9.122" ------------------------------------- 16.96s
linux-kernel : make mrproper ------------------------------------------- 12.19s
linux-kernel : make olddefconfig --------------------------------------- 10.54s
linux-kernel : remove everything except artifacts ----------------------- 7.96s
linux-kernel : remove everything except artifacts ----------------------- 7.15s
Gathering Facts --------------------------------------------------------- 4.62s
Gathering Facts --------------------------------------------------------- 3.68s
linux-kernel : make olddefconfig ---------------------------------------- 3.63s
linux-kernel : copy bzImage to known location --------------------------- 1.67s
linux-kernel : copy bzImage to known location --------------------------- 1.58s
Playbook run took 0 days, 0 hours, 26 minutes, 40 seconds
```

After adding `ccache` with hot cache:

`ccache` stats:

```
cache directory                     /home/pietrushnic/.ccache
primary config                      /home/pietrushnic/.ccache/ccache.conf
secondary config      (readonly)    /etc/ccache.conf
cache hit (direct)                  4595
cache hit (preprocessed)              89
cache miss                          4871
cache hit rate                     49.02 %
called for link                      178
called for preprocessing           12551
compiler produced no output           12
ccache internal error                  2
unsupported code directive            21
no input file                       3687
cleanups performed                     0
files in cache                     14582
cache size                           1.5 GB
max cache size                       5.0 GB
```


```
Thursday 23 August 2018  00:41:15 +0000 (0:02:02.608)       0:23:19.962 *******
===============================================================================
linux-kernel ---------------------------------------------------------- 701.42s
packages -------------------------------------------------------------- 246.51s
debootstrap ----------------------------------------------------------- 243.14s
command --------------------------------------------------------------- 123.05s
linux-install ---------------------------------------------------------- 72.47s
setup ------------------------------------------------------------------ 10.10s
config ------------------------------------------------------------------ 3.21s
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
total ---------------------------------------------------------------- 1399.91s
Thursday 23 August 2018  00:41:15 +0000 (0:02:02.608)       0:23:19.961 *******
===============================================================================
linux-kernel : make deb-pkg ------------------------------------------- 388.91s
packages : install packages ------------------------------------------- 246.51s
linux-kernel : make deb-pkg ------------------------------------------- 223.72s
debootstrap : debootstrap second stage -------------------------------- 189.56s
compress rootfs ------------------------------------------------------- 122.61s
linux-install : install Linux "4.14.65" -------------------------------- 37.36s
debootstrap : debootstrap first stage ---------------------------------- 36.00s
linux-install : install Linux "4.9.122" -------------------------------- 35.12s
debootstrap : install packages ----------------------------------------- 17.58s
linux-kernel : get Linux "4.9.122" ------------------------------------- 16.67s
linux-kernel : get Linux "4.14.65" ------------------------------------- 16.18s
linux-kernel : decompress Linux "4.14.65" ------------------------------ 13.82s
linux-kernel : decompress Linux "4.9.122" ------------------------------ 12.72s
linux-kernel : make mrproper -------------------------------------------- 8.21s
linux-kernel : make mrproper -------------------------------------------- 6.55s
Gathering Facts --------------------------------------------------------- 4.81s
linux-kernel : remove everything except artifacts ----------------------- 3.40s
linux-kernel : remove everything except artifacts ----------------------- 3.11s
linux-kernel : make olddefconfig ---------------------------------------- 3.08s
Gathering Facts --------------------------------------------------------- 2.74s
Playbook run took 0 days, 0 hours, 23 minutes, 19 seconds
```

This is not significant but we gain another 13% and now build time is
reasonable. Still most time-consuming tasks belong to compilation and package
installation bucket.

# Summary

If you have any other ideas about optimizing code compilation or container
build time please feel free to comment. If this post will gain popularity we
would probably reiterate it with best advices from our readers.

If you looking for Embedded Systems DevOps, who will optimize your firmware or
embedded software build environment, look no more and contact us
[here](https://3mdeb.com/contact/).

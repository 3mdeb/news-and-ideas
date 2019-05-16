---
ID: 62806
title: >
  Yet another quick build of
  arm-unknown-linux-gnueabi
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/yet-another-quick-build-of-arm-unknown-linux-gnueabi/
published: true
date: 2013-04-03 19:00:00
year: "2013"
tags:
  - crosstool-ng
  - embedded
  - linux
  - toolchain
  - arm-unknown-linux-gnueabi
  - arm
categories:
  - OS Dev
  - App Dev
---
So I decide to check what is going on with [crosstool-ng][1] and refresh my [old
post][2] about building `arm-unknown-linux-gnueabi` toolchain. Last post was
pretty popular, so definitely this is direction I should follow :). I will not
repeat myself, so if you encounter any problems please check last post, section
with known problems in crosstool-ng `doc/` directory or RTFM. Let's begin:

### Get the latest crosstool-ng

As usual I'm trying to use latest version possible. Following the crosstool-ng
page:

    hg clone http://crosstool-ng.org/hg/crosstool-ng
    cd crosstool-ng
    ./bootstrap

At the time of writing this article my changeset was `3200:0fc56e62cecf` 16 Mar
2013, two weeks old.

### Installation

I prefer to use local directory for `ct-ng` in case it will change in feature I
will not need to mess with `/usr` subsystem. Simply tryin' to keep it clean when
I can.

    mkdir $HOME/ct-ng
    ./configure --prefix=$HOME/ct-ng
    make
    make install

No problems on my up to date Debian wheezy. You will probably want to add
`$HOME/ct-ng` to your `PATH`

    export PATH="$HOME/ct-ng/bin:${PATH}"

Add bash completion as it is advised in message at the end of compilation
process. My `.bashrc` automatically sources `$HOME/.bash_completion` so there is
a place for local code completion.

    cat ct-ng.comp >> $HOME/.bash_completion


### Build sample toolchain

There is a long list of predefined samples toolchains which you can get build.
If `ct-ng` bash completion was correctly added, than you can explore it by
`<Tab>` or simply `ct-ng list-samples`. Let's try to build
`arm-unknown-linux-gnueabi`:

    mkdir -p $HOME/embedded/arm-unknown-linux-gnueabi
    cd $HOME/embedded/arm-unknown-linux-gnueabi
    ct-ng arm-unknown-linux-gnueabi

Before you start build consider some debugging options to make build process
easier to continue when problems encountered.

### Additional debugging options

crosstool-ng contain interesting mechanism of saving finished phases of
toolchain. This helps when for some reason our build process failed. To enable
this feature simply enter menuconfig:

    ct-ng menuconfig

Mark option `Paths and mix options -> Debug crosstool-NG -> Save intermediate
steps` as enabled. If something goes wrong you can check what last state was by:

    ls -lt .build/arm-unknown-linux-gnueabi/state

Directory on top with the latest modification date is now your first state where
you should restart after fail. To restart build in given point:

    ct-ng <state>+ #assuming that <state> is where we fail last time

Ordered list of possible states can be retrieved by `ct-ng list-steps`.

### Start build

    ct-ng build.4


`4` is the number of concurrent jobs and depends on your setup performance.
Building process takes a while so make coffee or anything else to drink :).

### Known problems

I encounter few different problems than during [previous building][2].

#### Missing expat library

Signature looks like that:

    [ERROR]    configure: error: expat is missing or unusable
    [ERROR]    make[3]: *** [configure-gdb] Error 1
    [ERROR]    make[2]: *** [all] Error 2

Simply install `libexpat`:

sudo apt-get install libexpat1-dev


#### gcj internal error

Few times I encountered something like this:

    [ERROR]    gcj: internal compiler error: Killed (program jc1)
    [ERROR]    make[5]: *** [ecjx] Error 4
    [ERROR]    make[4]: *** [all-recursive] Error 1
    [ERROR]    make[3]: *** [all-target-libjava] Error 2
    [ERROR]    make[2]: *** [all] Error 2

The reason is that `oom_kiler` takes care about `gcj`. It means that you run out
of memory during compilation Java related code. I experience that when trying to
build toolchain with 512MB of RAM :) So this was short reminder. I work on new
post about creating virtual embedded development environment based on [qemu][3].
I was inspired by [this article][4]. Hope this article was useful. If you have
any comments or difficulties please comment below. If think this post was useful -
share.

 [1]: http://crosstool-ng.org
 [2]: /2012/03/14/quick-build-of-arm-unknown-linux
 [3]: http://wiki.qemu.org/Main_Page
 [4]: http://www.elinux.org/Virtual_Development_Board

# kas: how to manage bitbake (Yocto) BSP

## Introduction

If you are using the , you certainly have encountered the hassle of managing
multiple [layers] and tracking their revisions.

I've been using the [Yocto Project] for nearly 3 years by now and have mostly
been using the tool
for this purpose. While I'm not a huge fan of it, it is relatively simple to
use and gets the job of fetching layers and controlling their revisions done
properly.

The only alternative I knew so far was the
[combo-layer](https://wiki.yoctoproject.org/wiki/Combo-layer), although it's
feature set was not enough for me to give up on [repo] and switch over.

## kas

According to the
[git history](https://github.com/siemens/kas/commit/daf0abab5e0c61d81eee1c6ad69a8040adc2c1870l),
the first public release of the project was at the Jun 14, 2017. I haven't
heard much about it. From my perspective, it gained some traction a couple of
months ago - I've been seeing some mentions of the [kas] tool here and there on
the various [Yocto Project] related mailing lists since then.

It seems to be a little bit more than just a tool for fetching and checking out
a set of layers to given revisions. The feature set covers:

* clone and checkout `bitbake` layers,
* create default `bitbake` settings (machine, distro etc.),
* launch minimal build environment, reducing the risk of host contamination
  (`docker` container),
* initiate `bitbake` build process.

So far, we've mostly been doing the above with a mixture of the [repo], our
[yocto-docker] container and a set of shell scripts to automate things. It
seems most of it can already be achieved using [kas], as it has been developed
specifically for managing and configuring the `bitbake` based projects.

## Installation

According to the [kas usage documentation], it can be installed natively via
`pip` (`python3` is required) or can be run inside `docker` container. I prefer
the latter whenever possible, so I'm going to start with this one.

There are actually
[two containers available](https://hub.docker.com/u/kasproject):

* [kasproject/kas] - for standard [Yocto Project] builds,
* [kasproject/kas-isar] - for [isar] builds.

Although in this case we are interested in the [kasproject/kas] container, I am
happy to see the [kasproject/kas-isar] to be present, as we already have some
use-cases for the [isar] project as well.

Although not mentioned in the
[usage documentation](https://kas.readthedocs.io/en/0.19.0/userguide.html#usage),
[it is advised](https://github.com/siemens/kas/pull/6#issuecomment-448166242)
to use the `kas` via the
[kas-docker](https://github.com/siemens/kas/blob/master/kas-docker) script.
For convenience, I'm placing it in my `~/bin` directory, so it is available in
the `PATH`:

```
ln -s /storage/projects/kas/kas-docker ~/bin/kas-docker
```

## kas configuration

The `kas` file syntax and the project configuration process is nicely described
int the
[kas project configuration documentation].

An even better way of understanding it may be to take a look at some real
examples. I can advise taking a look at the
[kas.yml from the meta-iot2000](https://github.com/siemens/meta-iot2000/blob/master/meta-iot2000-bsp/kas.yml).

## Transition from repo manifest to kas file

As mentioned earlier, I've been using [repo] to manage the layers and some
sample configuration files and a set of shell scripts to manage the build
configurations. In the case of [kas], all of it can be included in a single
`kas` file.

### Layers in repo manifest

The [repo] manifest contains a list of layers to fetch and their revisions. For
example:

```
    <project path="poky"
     name="poky"
     remote="yocto"
     revision="rocko"/>

    <project path="poky/meta-openembedded"
      name="openembedded/meta-openembedded"
      remote="github"
      revision="rocko"/>

    <project path="poky/meta-sunxi"
      name="linux-sunxi/meta-sunxi"
      remote="github"
      revision="rocko"/>

    <project path="poky/meta-rte"
      name="3mdeb_rte/meta-rte"
      remote="gitlab"
      revision="refs/tags/v0.4.1"/>

    <project path="poky/meta-swupdate"
     name="sbabic/meta-swupdate"
     remote="github"
     revision="rocko"/>
```

Additionally, we needed an example `bblayers.conf` file or some kind of shell
script to enable the layers we need and adjust the paths to given build
environment.

### Layers in kas file

The equivalent excerpt from the `kas` file would look like:

```
repos:
  # This repo contains the kas.yml file - there is no need to fetch it again.
  # It's current revision will be used to perform the build.
  meta-rte:

  poky:
    url: https://git.yoctoproject.org/git/poky
    refspec: 623b77885051174d0e05198843e739110977bd18
    layers:
      meta:
      meta-poky:
      meta-yocto-bsp:

  meta-sunxi:
    url: https://github.com/linux-sunxi/meta-sunxi
    refspec: 29b20da5e8cdea846c26d47a930d16114d71e0ca

  meta-openembedded:
    url: http://git.openembedded.org/meta-openembedded
    refspec: 8760facba1bceb299b3613b8955621ddaa3d4c3f
    layers:
      meta-oe:
      meta-python:
      meta-networking:

  meta-swupdate:
    url: https://github.com/sbabic/meta-swupdate
    refspec: f2d65d87485ada5a2d3a744fd7b9e46ec7e6b9f2
```

Note that it not only tells which repositories to fetch and which revisions to
use. Based on the above information, `kas` will also automatically generate the
[bblayers.conf]() file with the required layers enabled there.

## Transition from shell scripts to kas file

### Build configuration in sample files and shell scripts

It is quite a common practice to ship some kind of sane, example build config
file (i.e. [local.conf]() file) when providing the `Yocto BSP`. Sometimes,
when some conditional logic is necessary, shell scripts are being incorporated
to modify the configuration files based on the user input.

### Build configuration in kas file

All configurations can be maintained in a single `kas` file. In more complicated
examples, it can be maintained in a set of `kas` files by using the
[include feature](https://kas.readthedocs.io/en/0.19.0/userguide.html#including-in-tree-configuration-files).

#### bblayers.conf

This will be at the top of the [bblayers.conf] file. Refer to the
[kas project configuration documentation] for `_header` directive explanation.

```
bblayers_conf_header:
  standard: |
    POKY_BBLAYERS_CONF_VERSION = "2"
    BBPATH = "${TOPDIR}"
    BBFILES ?= ""
```

#### local.conf

This will be at the top of the [local.conf] file. Refer to the
[kas project configuration documentation] for `_header` directive explanation.

```
local_conf_header:
  standard: |
    CONF_VERSION = "1"
    PACKAGE_CLASSES = "package_rpm"
    SDKMACHINE = "x86_64"
    USER_CLASSES = "buildstats image-mklibs image-prelink"
    PATCHRESOLVE = "noop"
  debug-tweaks: |
    EXTRA_IMAGE_FEATURES = "debug-tweaks"
  diskmon: |
    BB_DISKMON_DIRS = "\
        STOPTASKS,${TMPDIR},1G,100K \
        STOPTASKS,${DL_DIR},1G,100K \
        STOPTASKS,${SSTATE_DIR},1G,100K \
        STOPTASKS,/tmp,100M,100K \
        ABORT,${TMPDIR},100M,1K \
        ABORT,${DL_DIR},100M,1K \
        ABORT,${SSTATE_DIR},100M,1K \AC
        ABORT,/tmp,10M,1K"
```

#### MACHINE and DISTRO

As you probably know, it is essential to set the set the
[MACHINE](https://www.yoctoproject.org/docs/current/ref-manual/ref-manual.html#var-MACHINE)
and
[DISTRO](https://www.yoctoproject.org/docs/current/ref-manual/ref-manual.html#var-DISTRO).
In `kas` file it is as simple as that:

```
machine: orange-pi-zero
distro: rte
```

#### target

This is the default recipe which will be built during the `kas build` action.
Usually, it will be the main image of our `BSP`. For example:

```
target: core-image-minimal
```

## Usage

It seems that when using `docker` container, we have two modes of operation:

* build the target image with a single command,
* enter system shell and work directly from there.

### Shell

This mode can certainly be useful for debugging (both issues with our `Yocto`
build and `kas` configuration).

Below command will make sure that the repositories specified in the `kas` file
are properly fetched and checked out. Then it will give us access to the
container's system shell.

```
kas-docker shell meta-rte/kas.yml
```

I'm using the `zsh` and faced below error:

```
2019-01-11 14:49:51 - ERROR    - [Errno 2] No such file or directory: '/usr/bin/zsh'
Traceback (most recent call last):
  File "/usr/local/lib/python3.5/dist-packages/kas/kas.py", line 161, in main
    sys.exit(kas(sys.argv[1:]))
  File "/usr/local/lib/python3.5/dist-packages/kas/kas.py", line 149, in kas
    if plugin().run(args):
  File "/usr/local/lib/python3.5/dist-packages/kas/shell.py", line 112, in run
    macro.run(ctx, args.skip)
  File "/usr/local/lib/python3.5/dist-packages/kas/libcmds.py", line 63, in run
    command.execute(ctx)
  File "/usr/local/lib/python3.5/dist-packages/kas/shell.py", line 137, in execute
    cwd=ctx.build_dir)
  File "/usr/lib/python3.5/subprocess.py", line 247, in call
    with Popen(*popenargs, **kwargs) as p:
  File "/usr/lib/python3.5/subprocess.py", line 676, in __init__
    restore_signals, start_new_session)
  File "/usr/lib/python3.5/subprocess.py", line 1282, in _execute_child
    raise child_exception_type(errno_num, err_msg)
FileNotFoundError: [Errno 2] No such file or directory: '/usr/bin/zsh'
```

It seems that the `kas-docker` script respects our `SHELL` environment
variable. This can be easily overridden with:

```
SHELL=bash kas-docker shell meta-rte/kas.yml
```

### build

The default build can be performed with below command. It will fetch the
required layers, make sure they have desired revisions, modify the configuration
files accordingly and execute the `bitbake` task to build the recipe specified
by the `target` reference in the `kas` configuration file.

```
kas-docker build meta-rte/kas.yml
```

The build output log looks like:

```
WARNING: Generation of wic images will fail!

Your docker host setup uses broken aufs as storage driver. Adjust the docker
configuration to use a different driver (overlay, overlay2, devicemapper). You
may also need to update the host distribution (e.g. Debian Jessie -> Stretch).

2019-01-11 19:26:11 - INFO     - kas 0.19.0 started
2019-01-11 19:26:11 - INFO     - /repo$ git rev-parse --show-toplevel
2019-01-11 19:26:11 - INFO     - /repo$ git rev-parse --show-toplevel
2019-01-11 19:26:11 - INFO     - Using /repo as root for repository meta-rte
2019-01-11 19:26:11 - INFO     - /work$ git clone -q https://github.com/linux-sunxi/meta-sunxi /work/meta-sunxi
2019-01-11 19:26:11 - INFO     - /work$ git clone -q http://git.openembedded.org/meta-openembedded /work/meta-openembedded
2019-01-11 19:26:11 - INFO     - /work$ git clone -q https://github.com/sbabic/meta-swupdate /work/meta-swupdate
2019-01-11 19:26:11 - INFO     - /work$ git clone -q https://git.yoctoproject.org/git/poky /work/poky
2019-01-11 19:26:13 - INFO     - Repository meta-swupdate cloned
2019-01-11 19:26:13 - INFO     - Repository meta-sunxi cloned
2019-01-11 19:26:49 - INFO     - Repository poky cloned
2019-01-11 19:29:19 - INFO     - Repository meta-openembedded cloned
2019-01-11 19:29:19 - INFO     - /repo$ git rev-parse --show-toplevel
2019-01-11 19:29:19 - INFO     - Using /repo as root for repository meta-rte
2019-01-11 19:29:19 - INFO     - /work/meta-sunxi$ git status -s
2019-01-11 19:29:19 - INFO     - /work/meta-sunxi$ git rev-parse --verify HEAD
2019-01-11 19:29:19 - INFO     - 72ece33639990d8dccdf0513a07f444c2fe0192c
2019-01-11 19:29:19 - INFO     - /work/meta-sunxi$ git checkout -q 29b20da5e8cdea846c26d47a930d16114d71e0ca
2019-01-11 19:29:19 - INFO     - /work/meta-openembedded$ git status -s
2019-01-11 19:29:19 - INFO     - /work/meta-openembedded$ git rev-parse --verify HEAD
2019-01-11 19:29:19 - INFO     - a8aef12ce69ac9cf09b562e59f3c39db9576ecaa
2019-01-11 19:29:19 - INFO     - /work/meta-openembedded$ git checkout -q 8760facba1bceb299b3613b8955621ddaa3d4c3f
2019-01-11 19:29:20 - INFO     - /work/meta-swupdate$ git status -s
2019-01-11 19:29:20 - INFO     - /work/meta-swupdate$ git rev-parse --verify HEAD
2019-01-11 19:29:20 - INFO     - 6e9d7c524d3972db02d333d09678eaae919c42c4
2019-01-11 19:29:20 - INFO     - /work/meta-swupdate$ git checkout -q f2d65d87485ada5a2d3a744fd7b9e46ec7e6b9f2
2019-01-11 19:29:20 - INFO     - /work/poky$ git status -s
2019-01-11 19:29:20 - INFO     - /work/poky$ git rev-parse --verify HEAD
2019-01-11 19:29:20 - INFO     - 46f6f6a5f9de5e7f8f32f6ae768af61ec20ade4a
2019-01-11 19:29:20 - INFO     - /work/poky$ git checkout -q 623b77885051174d0e05198843e739110977bd18
2019-01-11 19:29:20 - INFO     - /repo$ git rev-parse --show-toplevel
2019-01-11 19:29:20 - INFO     - Using /repo as root for repository meta-rte
2019-01-11 19:29:20 - INFO     - /work/poky$ /tmp/tmp0a881010 /work/build
2019-01-11 19:29:20 - INFO     - /repo$ git rev-parse --show-toplevel
2019-01-11 19:29:20 - INFO     - Using /repo as root for repository meta-rte
2019-01-11 19:29:20 - INFO     - /repo$ git rev-parse --show-toplevel
2019-01-11 19:29:20 - INFO     - Using /repo as root for repository meta-rte
2019-01-11 19:29:20 - INFO     - /work/build$ /work/poky/bitbake/bin/bitbake -k -c build core-image-minimal
2019-01-11 19:30:37 - INFO     - Parsing recipes...done.
2019-01-11 19:30:37 - INFO     - Parsing of 2036 .bb files complete (0 cached, 2036 parsed). 2904 targets, 131 skipped, 0 masked, 0 errors.
2019-01-11 19:30:37 - INFO     - NOTE: Resolving any missing task queue dependencies
```

Note the warning at the top of the log output. Despite using the `aufs` as the
storage driver for `docker`, the `wic` image built well on my setup. The
explanation of the warning can be found in
[this kas commit](https://github.com/siemens/kas/commit/7f1ccba5ea4f1ade36a669c90bbfcffac293edb5#diff-1ef23235cac064dd5e12b4b13bea9e11)

My host setup was:

```
OS: Ubuntu 16.04.1
kernel: 4.15.0-43-generic
docker: 18.09.0
```

## Private repositories

When fetching from private repositories is needed (either during the layers
fetching or during the build process itself), we need to expose access keys
(usually `SSH` keys) somehow. It seems that the preferred way (at least when
using the `kas-docker`) is to use the `-ssh-dir` switch of the script:

```
kas-docker --ssh-dir ~/ssh-keys shell meta-rte/kas.yml
```

The contents of the `~/ssh-keys` can look like:

```
config
github_key_ro
github_key_ro.pub
gitlab_key_ro
gitlab_key_ro.pub
```

And the `~/ssh-key/config` file:

```
Host gitlab.com
    HostName       gitlab.com
    User           git
    IdentityFile   ~/.ssh/gitlab_key_ro
    StrictHostKeyChecking no
    IdentitiesOnly yes

Host github.com
    HostName       github.com
    User           git
    IdentityFile   ~/.ssh/github_key_ro
    StrictHostKeyChecking no
    IdentitiesOnly yes
```

## Final example

The final `kas` file for `meta-rte` can be found in the
[meta-rte repository](TBD). The documentation on how to build the system for the
[rte](https://3mdeb.com/rte/) using `kas` can be found in the
[meta-rte README](TBD).

## Conclusion

After some initial work with the [kas], it seems like a great tool for managing
`bitbake` based `BSP`. It seems that it is capable of replacing most of our
legacy way of managing `bitbake` layers and configuration.

In my opinion, the [kas] project definitely deserves some more popularity. At
the moment it has less than 30 stars on
[github](https://github.com/siemens/kas). I can't wait to see how it would fit
in some more complex use-cases we have.

## References

* [kas]
* [kas documentation]
* [isar]
* [kasproject/kas]
* [kasproject/kas-isar]

[kas]: https://github.com/siemens/kas
[kas usage documentation]: https://kas.readthedocs.io/en/0.19.0/userguide.html#usage
[kas project configuration documentation]: https://kas.readthedocs.io/en/0.19.0/userguide.html#project-configuration
[kas documentation]: https://kas.readthedocs.io/en/0.19.0/intro.html
[isar]: https://github.com/ilbers/isar
[kasproject/kas]: https://hub.docker.com/r/kasproject/kas
[kasproject/kas-isar]: https://hub.docker.com/r/kasproject/kas-isar
[repo]: https://source.android.com/setup/develop/repo
[yocto-docker]: https://github.com/3mdeb/yocto-docker
[bblayers.conf]: https://www.yoctoproject.org/docs/current/ref-manual/ref-manual.html#migration-1.3-bblayers-conf
[local.conf]: https://www.yoctoproject.org/docs/current/ref-manual/ref-manual.html#structure-build-conf-local.conf
[Yocto Project]: https://www.yoctoproject.org/
[layers]: https://www.yoctoproject.org/software-overview/layers/

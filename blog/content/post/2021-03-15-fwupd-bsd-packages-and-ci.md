---
title: Creating ports for BSD distributions
abstract: 'In this blog post, we will present how to build packages for
           FreeBSD, DragonFlyBSD, NetBSD, and OpenBSD. Also, we will show
           you how to create CI for FreeBSD distribution with the use of
           GitHub action.'
cover: /covers/fwupd_bsd.png
author:
    - norbert.kaminski
    - piotr.konkol
layout: post
published: true
date: 2021-03-15
archives: "2021"

tags:
  - nlnet
  - BSD
  - fwupd
  - firmware
  - fwupd-for-BSD
  - pkg
  - pkgsrc
categories:
  - Firmware

---
If you haven’t read previous blog posts from the fwupd for the BSD series,
I strongly encourage you to catch up on them. The best way is to search under
the [fwupd-for-BSD tag](https://blog.3mdeb.com/tags/fwupd-for-BSD/).
In this blog post, we will present how to build packages for FreeBSD, DragonFlyBSD,
NetBSD, and OpenBSD. Also, we will show you how to create CI for FreeBSD
distribution with the use of GitHub action.
Our first attempt was to create a universal package, that will be buildable on
each BSD distribution. Differences between BSD distributions make us
give up this idea. We decided to adjust the fwupd port to each distribution.
We achieved that goal, but you have to remember that is the early WIP stage,
and only basic functionalities works (get-plugins, get-version, get-devices).
So let's take a look at the FreeBSD package manager.

# Providing package for FreeBSD

The FreeBSD ports are based on pkg, which is a package management tool. It is
used to manage local packages installed from ports and install/upgrade packages
from remote repositories. For debugging reasons, it is important to
use repository *Latest*, instead of *Quarterly*. To swap the remote repository
copy the `/etc/pkg/FreeBSD.conf` to `/usr/local/etc/pkg/repos/FreeBSD.conf`,
and change the repo URL to:

```
url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest",
```

Now you have to fetch the port sources. Go to the `/usr` directory and clone
our freebsd-ports fork:

```
# git clone git@github.com:3mdeb/freebsd-ports.git -b fwupd-port ports
```

The one thing you have to do before building the package is updating the
`libtasn1` library. The 4.16.0 version of this library is built with `-02`
optimization flag. Because of that it has broken certificate parse
functionality. The 4.16.0_1 version of this library is built with `-01`
clang flag optimization with fixes the problem:

```
# pkg upgrade libtasn1
```

Now it's time to build and install fwupd package. Change directory to
`/usr/ports/sysutils/fwupd`:

```
$ cd /usr/ports/sysutils/fwupd
```

Now you if you want, you can manually install dependencies:

```
pkg install glib meson pkgconf gobject-introspection vala gtk-doc json-glib gpgme gnutls sqlite3 curl gcab libarchive
```

Or you can skip the previous step and build everything from the source.
It could take a couple of hours depending on your hardware configuration.
Finally, you can build and install the fwupd package:

```
# make install
```

If you want to test your fwupd package, you have to enable D-Bus. You can achieve
that by setting:

```
dbus_enable="YES"
```

in the `/etc/rc.conf`. To apply the configuration you need to reboot the system.
The second option is to run the D-Bus service:

```
# service dbus onestart
```

Now you can run fwupd daemon and test basic functionalities.
The build logs are similar for each system and were presented in the previous
blog.

# Providing fwupd support for DragonFlyBSD and building package

DragonFlyBSD ports are based on the FreeBSD pkg. The most challenging part was
setting up the operating system for ports compilation. I agree with DPort
documentation that says: *Building a DPort from source is not generally
encouraged. It is suggested to use the official pre-built binaries instead.*

So in the first part of this chapter, I will show you how to set up your
DragonFly to build the DPort packages. There are two main problems with that.
The first problem is connected to the `sh` version. The older version of `sh`
is not able to set the pipefail option. To check if your DragonFly is capable
to do that, run the following command:

```
# sh -c 'set -o pipefail'
```

If it ends with 0 status you are a lucky guy. If it is not, you need a couple of
hours to update your `sh` from the system source. At first, go to `/usr`
directory and download `src`:

```
# make src
```

Then go to `/usr/src` and build all userland programs:

```
# make buildworld
```

Now you can take your time and drink some coffee (it will take a bunch of
hours). Once it is done you can install the programs:

```
# make installworld
```

Reboot your system and check if you can set properly the pipefail option.
The second problem is pkg upgrade. Once it is upgraded from 1.14.x to 1.16.x,
you'll get the following error:

```
pkg: Failed to execute lua script: [string "-- args:
etc/pkg.conf.sample..."]:12: attempt to call a nil value (field
'stat')
pkg: lua script failed
No active remote repositories configured.
```

To fix the pkg remote simply copy the sample mirror config file over:

```
# cp /usr/local/etc/pkg/repos/df-latest.conf.sample \
    /usr/local/etc/pkg/repos/df-latest.conf
```

And now you are ready to build the package. At first move to `/usr` directory
and fetch the source:

```
# git clone git@github.com:3mdeb/DPorts.git -b fwupd-port
```

Then go to `/usr/dports/sysutils/fwupd` and install the package:

```
make install
```

Run D-Bus:

```
# service dbus onestart
```

And now you can test basic functionalities.

# Providing fwupd support for NetBSD

NetBSD package is based on pkgsrc and it was forked from the FreeBSD ports
collection in 1997. It mainly supports the NetBSD distribution but some ports
are buildable on different BSD distros. Our first thought was to create the
pkgsrc port, that would run on every BSD distro, but because the dependencies
do not build properly on DragonFly and OpenBSD, we have decided to create
four not so different ports for every distro.

Like before, go to the `/usr` directory and fetch the pkgsrc:

```
git clone git@github.com:NetBSD/pkgsrc.git
```

Run the bootstrap in the `/usr/pkgsrc/bootstrap`:

```
./bootstrap
```

Go back to the `/usr/pkgsrc` and clone wip pkgs.

```
git clone git@github.com:3mdeb/pkgsrc-wip.git -b fwupd-wip wip
```

Now move to the `/usr/pkgsrc/wip/fwupd` and install the package:

```
/usr/pkg/bin/bmake install
```

It will build and install fwupd and its dependencies. Once it's done
run D-Bus:

```
service dbus start
```

And now you can check basic functionalities.

# Providing fwupd support for OpenBSD

The OpenBSD pkg_* utilities are written by Marc Espie and OpenBSD ports are
based on the separate port tree.

At first go to `/usr` directory and fetch the ports source:

```
git clone git@github.com:3mdeb/ports.git -b fwupd-port ports
```

Set up the `/etc/mk.conf`:

```
WRKOBJDIR=/usr/obj/ports
DISTDIR=/usr/distfiles
PACKAGE_REPOSITORY=/usr/packages
```

You can install manually dependencies to save your time.

```
pkg_add pkgconf pkgconf intltool pkgconf vala gettext-tools \
    gobject-introspection gtk-doc glib2 json-glib gpgme gnutls \
    sqlite3 curl gcab libarchive libgpg-error libusb-compat dbus
```

Go to the `/usr/ports/sysutils/fwupd` and build and install the package:

```
make install
```

Run D-Bus:

```
/etc/rc.d/messagebus start
```

Now you can test basic functionalities.

# Conclusions about BSD package systems

The BSD port managers are pretty similar, but each distro comes up with its own
idea of how to solve the problem of the ports. The main difference which
generates the biggest number of problems was libusb which differs
from distro to distro.

# Continuous Integration for FreeBSD package

Running CI/CD scripts on FreeBSD is not the most common DevOps tasks, that's
why we were lucky to find out that Github Actions already had a way to run
something in FreeBSD without setting up your own local runner. It was also
already used by fwupd upstream for performing build on multiple distros,
fuzzing and verifying ABI.

However, the way in which we are able to use this FreeBSD on a shared runner is
very interesting. We used
[vmactions/freebsd-vm](https://github.com/vmactions/freebsd-vm) which itself is
based on MacOS shared runner which is the OS chosen in CI code.  MacOS is used
here to start virtualbox in which FreeBSD machine is running.  The commands we
specify for the continuous integration script are executed through SSH and then
the resulting output files are rsync'ed back to MacOS runner.  Even though it's
based on workarounds it performs it task ok.

MacOS runners have 3 CPU cores and 14GB of RAM which is the best spec available
for the shared GA runners. This is enough to build fwupd itself from ports in
acceptable amount of time, however trying to build it with all the dependencies
using pkgsrc would take ages. Lucky thing about this runner is that it's free
for Open Source projects. For private repositories it costs 10 times as much
per minute as Linux runner and virtualbox itself takes few minutes to get
running.

As opposed to pkgsrc based build which we tried to implement in the CI before
ports based build uses dependencies from binary packages available from `pkg`
and there is no need to build or manually cache dependencies. Next thing we
needed to do was obtain the up-to-date ports sources with fwupd. As a temporary
workaround, until fwupd will be available in the freebsd ports upstream we
clone our fork and use it as a base to build the package. The Makefile is made
for the tagged release version, so there is a slight complication. To get past
it we needed to `sed` through the file setting github related parameters
accordingly with the branch from which CI was started.

# References

* FreeBSD port: https://github.com/3mdeb/freebsd-ports/pull/1
* OpenBSD port: https://github.com/3mdeb/ports/pull/1
* NetBSD port: https://github.com/3mdeb/pkgsrc-wip/pull/1
* DragonflyBSD port: https://github.com/3mdeb/DPorts/pull/1
* fwupd upstream PR: https://github.com/fwupd/fwupd/pull/2874
* Continuous integration PR: https://github.com/fwupd/fwupd/pull/3031
* Successful CI job: https://github.com/3mdeb/fwupd/runs/2114100114

Note that the ports will change after the merge of fwupd upstream PR.
After that, we will start the upstream to the official CVS of each distro.

## Summary

If you have any questions, suggestions, or ideas, feel free to share them in
the comment section. If you are interested in similar content, I encourage you
to [sign up for our newsletter](http://eepurl.com/doF8GX).

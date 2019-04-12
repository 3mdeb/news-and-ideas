---
title: debos in docker - the second attempt
cover: /covers/docker-logo.png
author: maciej.pijanowski
layout: post
published: true
date: 2018-08-23 16:00:00

tags:
    -Debian
    -linux
    -build
    -docker
categories:
    -OS Dev
---

## Intro

In
[the previous post](https://3mdeb.com/os-dev/our-first-look-at-debos-new-debian-images-generator/),
I have shared my first experience with the Debian images builder -
[debos](https://github.com/go-debos/debos). I have posted my current results on
the [issue](https://github.com/go-debos/debos/issues/9) but since there was no
response, I've decided to try to move forward by myself.

Just to remind - I was stuck at the following error (when building for `arm64`):

```
2018/07/26 18:36:39 Debootstrap (stage 2) | chroot: failed to run command '/debootstrap/debootstrap': Exec format error
2018/07/26 18:36:39 debootstrap.log | gpgv: Signature made Thu Jul 26 14:21:51 2018 UTC
2018/07/26 18:36:39 debootstrap.log | gpgv:                using RSA key A1BD8E9D78F7FE5C3E65D8AF8B48AD6246925553
2018/07/26 18:36:39 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (7.0/wheezy) "
2018/07/26 18:36:39 debootstrap.log | gpgv: Signature made Thu Jul 26 14:21:51 2018 UTC
2018/07/26 18:36:39 debootstrap.log | gpgv:                using RSA key 126C0D24BD8A2942CC7DF8AC7638D0442B90D010
2018/07/26 18:36:39 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (8/jessie) "
2018/07/26 18:36:39 debootstrap.log | gpgv: Signature made Thu Jul 26 14:21:51 2018 UTC
2018/07/26 18:36:39 debootstrap.log | gpgv:                using RSA key 16E90B3FDF65EDE3AA7F323C04EE7237B7D453EC
2018/07/26 18:36:39 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (9/stretch) "
2018/07/26 18:36:39 Action `debootstrap` failed at stage Run, error: exit status 126
Powering off.
```

## Potential solution

After some research, it seemed like the
[binfmt_misc](https://en.wikipedia.org/wiki/Binfmt_misc) support might be
missing in my setup. Links with similar issues which were useful:

* [lack of binfmt_misc module during Raspbian building](https://github.com/RPi-Distro/pi-gen/issues/133)
* [similar error on the multiarch-docker-image-generation](https://github.com/osrf/multiarch-docker-image-generation/issues/6#issuecomment-282943316)
* [QemuUser page on the Debian wiki](https://wiki.debian.org/QemuUserEmulation)

At first, it seemed to be necessary to install `binfmt-support` into the `docker`
image. It is necessary to note, that `binfmt_misc` module on the host must be
loaded (which is not always the case). With those modifications in place, my
`debos` build inside `docker` container failed at:

```
2018/08/21 19:17:06 Debootstrap (stage 2) | W: Failure trying to run:  mount -t proc proc /proc
2018/08/21 19:17:06 Debootstrap (stage 2) | W: See //debootstrap/debootstrap.log for details
2018/08/21 19:17:06 debootstrap.log | gpgv: Signature made Tue Aug 21 14:20:20 2018 UTC
2018/08/21 19:17:06 debootstrap.log | gpgv:                using RSA key A1BD8E9D78F7FE5C3E65D8AF8B48AD6246925553
2018/08/21 19:17:06 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (7.0/wheezy) <ftpmaster@debian.org>"
2018/08/21 19:17:06 debootstrap.log | gpgv: Signature made Tue Aug 21 14:20:20 2018 UTC
2018/08/21 19:17:06 debootstrap.log | gpgv:                using RSA key 126C0D24BD8A2942CC7DF8AC7638D0442B90D010
2018/08/21 19:17:06 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (8/jessie) <ftpmaster@debian.org>"
2018/08/21 19:17:06 debootstrap.log | gpgv: Signature made Tue Aug 21 14:20:20 2018 UTC
2018/08/21 19:17:06 debootstrap.log | gpgv:                using RSA key 16E90B3FDF65EDE3AA7F323C04EE7237B7D453EC
2018/08/21 19:17:06 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (9/stretch) <ftpmaster@debian.org>"
2018/08/21 19:17:06 debootstrap.log | mount: /proc: permission denied.
2018/08/21 19:17:06 Action `debootstrap` failed at stage Run, error: exit status 1
```

To overcome this `/proc` access issue I have decided to run the container in
the
[privileged mode](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities).
Generally, I try to avoid doing that whenever not strictly required. Scoping
the actual access requirements and reducing the container access to the host
system might be another task to look at. For now, I'm sticking with the
`privileged` mode enabled without much deeper analysis.

## One more issue

One more issue to solve was:

```
2018/08/21 14:17:53 debootstrap.log | Processing triggers for libc-bin (2.27-5) ...
2018/08/21 14:17:53 debootstrap.log | /debootstrap/debootstrap: 1363: /debootstrap/debootstrap: cannot open //var/lib/apt/lists/debootstrap.invalid_dists_buster_main|contrib|no
n-free_binary-arm64_Packages: No such file
2018/08/21 14:17:53 Action `debootstrap` failed at stage Run, error: exit status 2
Powering off.
```

It appears that there is a
[debootstrap bug report](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=806780)
hanging in the `Debian` bug tracker since the `Dec 2015`. The issue
[was resolved](https://salsa.debian.org/installer-team/debootstrap/commit/792ab830a892ccfaaca156eace00172d3432023a)
in the `debootstrap`  `1.0.96`. Unfortunately, the `debootstrap` version shipped
in my `Debian Stretch` container is `1.0.89`. As a quick solution, I decided to
provide the patch manually:

```
COPY files/0001-Fix-multiple-components-usage-for-foreign.patch /usr/share/debootstrap
RUN cd /usr/share/debootstrap && \
    patch < 0001-Fix-multiple-components-usage-for-foreign.patch && \
    rm /usr/share/debootstrap/0001-Fix-multiple-components-usage-for-foreign.patch && \
    apt-get autoremove -y patch && \
    rm -rf /var/lib/apt/lists/*
```

A much cleaner solution would be to install `debootstrap` from
[stretch-backports](https://packages.debian.org/stretch-backports/debootstrap),
which bumps the version to `1.0.100`:

```
RUN printf "deb http://httpredir.debian.org/debian stretch-backports main non-free\ndeb-src http://httpredir.debian.org/debian stretch-backports main non-free" > /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get -t stretch-backports install -y debootstrap && \
    rm -rf /var/lib/apt/lists/*
```

## First success

Finally, the `debos` build for `arm64` inside the `docker` container finishes
successfully:

```
2018/08/21 19:22:48 ==== overlay ====
Overlaying /root/doc/examples/overlays/sudo on /scratch/root
2018/08/21 19:22:48 ==== run ====
2018/08/21 19:22:48 echo debian > /etc/hostname | host's /etc/localtime is not a symlink, not updating container timezone.
2018/08/21 19:22:48 ==== pack ====
2018/08/21 19:22:48 Compression to /root/debian-stretch-arm64.tgz
Powering off.
2018/08/21 19:23:01 ==== Recipe done ====
```

I have not (yet) run the image on the real hardware, but it is certainly one of
the things I would like to do next.

My `Dockerfile`, scripts and some `README` can be found in the
[3mdeb github debos fork](https://github.com/3mdeb/debos/tree/add-dockerfile/docker).

## Conclusion

After some struggle, I finally was able to build the image inside the `docker`
container. I consider it quite useful as it may enable more users (who do not
own the native `Debian` machine) to take advantage of the `debos` utility.
Hopefully, I can manage to push this idea upstream and some more people will
take advantage of my work.

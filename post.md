## What is debos

`debos` is quite a new tool allowing for easier Debian images generation.  It
seems to be following current trends - it is written in `Go`, using `YAML` as
an input format. The idea of taking away `debootstrap` shell scripts and
replacing it with single, simple `YAML` file looks tempting enough to give it a
try.  Full feature description can be found in
[this introductory post](https://www.collabora.com/news-and-blog/blog/2018/06/27/introducing-debos/)
on Collabora's blog.

## First approach - Ubuntu host

In order to get started I followed with the installation steps as given in the
[installation section](https://github.com/go-debos/debos#installation-under-debian)
from the
[github repo README](https://github.com/go-debos/debos#installation-under-debian).
The installation commands are for `Debian` but I thought it will work just fine
(as usual) on my fresh `Ubuntu 18.04` laptop. Well, not quite. So the
installation looks like:

> I have decided to skip the GOPATH export and stick to the default `GOPATH=~/go`

```
sudo apt install golang
sudo apt install libglib2.0-dev libostree-dev
go get -u github.com/go-debos/debos/cmd/debos
```

I thought that a first sanity test would be to build the example recipe:

```
~/go/bin/debos ~/go/src/go-debos/debos/doc/examples/example.yaml
```

The first problems appears at the same beginning:

```
2018/07/17 18:02:17 open failed: /lib/modules/4.15.0-24-generic/kernel/drivers/char/virtio_console.ko - open /lib/modules/4.15.0-24-generic/kernel/drivers/char/virtio_console.ko: no such file or directory
```

I have `virtio_console` driver compiled in kernel, so the error message seems
really confusing:

```
cat /boot/config-4.15.0-24-generic | grep VIRTIO_CONSOLE
CONFIG_VIRTIO_CONSOLE=y
```

It seems to be known issue, which is described in
[one of the fakemachine's github issues](https://github.com/go-debos/fakemachine/issues/12)
[fakemachine](https://github.com/go-debos/fakemachine) is another module
written in `Go`, which is a dependency of `debos`. It seems to be a wrapper for
`qemu-system` in order to allow for running image building phases as an
unprivileged user. It may not be obvious at first, as this thing does not
even have a single README.

So, it seems that it just won't work on the `Ubuntu`? Running on any other
distro is also questionable. It seems that there are
[more unsolved issues](https://github.com/go-debos/fakemachine/issues/13)
when running on distros other than Debian. And those issues were open back in
Nov 2017, so it is definitely not a priority to make it work properly on
distros other than `Debian`.

## Second approach - Debian VirtualBox

I decided to give it another chance and try running inside `VirtualBox`.
I went with fresh Debian 9.3 Strech box
[from osboxes](https://www.osboxes.org/debian/)


```
sudo apt install golang
sudo apt install libglib2.0-dev libostree-dev
mkdir ~/go
export GOPATH=~/go
go get -u github.com/go-debos/debos/cmd/debos
```

`git` was another dependency for installation:

```
sudo apt install git
```

```
~/go/bin/debos ~/go/src/github.com/go-debos/debos/doc/examples/example.yaml
```

Output from the firs run:

```
2018/07/26 13:13:09 fakemachine not supported, running on the host!
2018/07/26 13:13:09 ==== debootstrap ====
2018/07/26 13:13:09 debootstrap.log | cat: /home/osboxes/.debos-873708939/root/debootstrap/debootstrap.log: No such file or directory
2018/07/26 13:13:09 Action `debootstrap` failed at stage Run, error: exec: "debootstrap": executable file not found in $PATH
```

```
sudo apt install debootstrap
```

Still no lick after second try:

```
2018/07/26 13:17:25 fakemachine not supported, running on the host!
2018/07/26 13:17:25 ==== debootstrap ====
2018/07/26 13:17:25 debootstrap.log | cat: /home/osboxes/.debos-909422932/root/debootstrap/debootstrap.log: No such file or directory
2018/07/26 13:17:25 Action `debootstrap` failed at stage Run, error: exec: "debootstrap": executable file not found in $PATH
```

The first message (`fakemachine not supported`) from log above appears
[when there is no `/dev/kvm` device present](https://github.com/go-debos/fakemachine/blob/master/machine.go#L89).
Although, I'm not sure if this is a strict requirement in order to run `qemu`.

It seems `debootstrap` is at `/usr/sbin/debootstrap` - so not in user's default
`PATH`:

```
export PATH=$PATH:/usr/sbin
```

Another try:

```
2018/07/26 13:54:37 fakemachine not supported, running on the host!
2018/07/26 13:54:37 ==== debootstrap ====
2018/07/26 13:54:37 Debootstrap | E: debootstrap can only run as root
2018/07/26 13:54:37 debootstrap.log | cat: /home/osboxes/.debos-418422200/root/debootstrap/debootstrap.log: No such file or directory
2018/07/26 13:54:37 Action `debootstrap` failed at stage Run, error: exit status 1
```

Of course. I don't mind running as root to see how far can we go this time (we
are in `VirtualBox` after all):

```
sudo ~/go/bin/debos ~/go/src/github.com/go-debos/debos/doc/examples/example.yaml
```

The privileged run failed at:

```
2018/07/26 13:36:38 Debootstrap (stage 2) | chroot: failed to run command ‘/debootstrap/debootstrap’: Exec format error
2018/07/26 13:36:38 debootstrap.log | gpgv: Signature made Thu Jul 26 10:21:51 2018 EDT
2018/07/26 13:36:38 debootstrap.log | gpgv:                using RSA key A1BD8E9D78F7FE5C3E65D8AF8B48AD6246925553
2018/07/26 13:36:38 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (7.0/wheezy) <ftpmaster@debian.org>"
2018/07/26 13:36:38 debootstrap.log | gpgv: Signature made Thu Jul 26 10:21:51 2018 EDT
2018/07/26 13:36:38 debootstrap.log | gpgv:                using RSA key 126C0D24BD8A2942CC7DF8AC7638D0442B90D010
2018/07/26 13:36:38 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (8/jessie) <ftpmaster@debian.org>"
2018/07/26 13:36:38 debootstrap.log | gpgv: Signature made Thu Jul 26 10:21:51 2018 EDT
2018/07/26 13:36:38 debootstrap.log | gpgv:                using RSA key 16E90B3FDF65EDE3AA7F323C04EE7237B7D453EC
2018/07/26 13:36:38 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (9/stretch) <ftpmaster@debian.org>"
2018/07/26 13:36:38 Action `debootstrap` failed at stage Run, error: exit status 126
```

It seems to me that no correct `qemu-static` is called in order to run
`arm64` binary.

When building for the host archtiecture:

```
sudo ~/go/bin/debos  -t architecture:"amd64" ~/go/src/github.com/go-debos/debos/doc/examples/example.yaml
```

After a while, **almost** success:

```
2018/07/26 14:00:39 Debootstrap | I: Base system installed successfully.
2018/07/26 14:00:39 Action `debootstrap` failed at stage Run, error: exec: "systemd-nspawn": executable file not found in $PATH
```

Another package missing, namely `systemd-container`:

```
sudo apt install systemd-container
```

And finally, we have our image:

```
2018/07/26 14:11:45 ==== overlay ====
Overlaying /home/osboxes/go/src/github.com/go-debos/debos/doc/examples/overlays/sudo on /home/osboxes/.debos-414397177/root
2018/07/26 14:11:45 ==== run ====
2018/07/26 14:11:45 ==== pack ====
2018/07/26 14:11:45 Compression to /home/osboxes/debian-stretch-amd64.tgz
2018/07/26 14:11:56 ==== Recipe done
```

```
88M     debian-stretch-amd64.tgz
```

## Third approach - docker container

With above problems in mind, it seems like o mandatory to package all those
things in a portable, easy-to-use container. In fact, this is one of the items
from the
[project's TODO list](https://github.com/go-debos/debos/blob/master/TODO#L12)
Thanks to the `VirtualBox` triage I am already armed with a list of
dependencies and potential issues to come.
o

I've noticed that `fakemachine` already has a
[Dockerfile](https://github.com/go-debos/fakemachine/blob/master/Dockerfile),
so I had something to take a look at. However, it seems to be used to build
`fakemachine` at container runtime, which is exactly our target if we want to
push the functional `debos` image to the `dockerhub`.

I went with
[multi-stage-buld](https://docs.docker.com/develop/develop-images/multistage-build/)
in order to reduce image size (do not include build dependencies into the
image, only the runtime ones).

I ended up with
[the following Dockerfile](https://github.com/3mdeb/debos/blob/add-dockerfile/docker/Dockerfile).

```
./docker/run.sh -t architecture:"amd64" doc/examples/example.yaml
```

```
2018/07/26 18:36:39 Debootstrap (stage 2) | chroot: failed to run command '/debootstrap/debootstrap': Exec format error
2018/07/26 18:36:39 debootstrap.log | gpgv: Signature made Thu Jul 26 14:21:51 2018 UTC
2018/07/26 18:36:39 debootstrap.log | gpgv:                using RSA key A1BD8E9D78F7FE5C3E65D8AF8B48AD6246925553
2018/07/26 18:36:39 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (7.0/wheezy) <ftpmaster@debian.org>"
2018/07/26 18:36:39 debootstrap.log | gpgv: Signature made Thu Jul 26 14:21:51 2018 UTC
2018/07/26 18:36:39 debootstrap.log | gpgv:                using RSA key 126C0D24BD8A2942CC7DF8AC7638D0442B90D010
2018/07/26 18:36:39 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (8/jessie) <ftpmaster@debian.org>"
2018/07/26 18:36:39 debootstrap.log | gpgv: Signature made Thu Jul 26 14:21:51 2018 UTC
2018/07/26 18:36:39 debootstrap.log | gpgv:                using RSA key 16E90B3FDF65EDE3AA7F323C04EE7237B7D453EC
2018/07/26 18:36:39 debootstrap.log | gpgv: Good signature from "Debian Archive Automatic Signing Key (9/stretch) <ftpmaster@debian.org>"
2018/07/26 18:36:39 Action `debootstrap` failed at stage Run, error: exit status 126
Powering off.
```

And the build for host architecture:

```
./docker/run.sh -t architecture:"amd64" doc/examples/example.yaml
```

Finished just fine:

```
2018/07/26 19:20:30 ==== overlay ====
Overlaying /root/doc/examples/overlays/sudo on /scratch/root
2018/07/26 19:20:30 ==== run ====
2018/07/26 19:20:30 echo debian > /etc/hostname | host's /etc/localtime is not a symlink, not updating container timezone.
2018/07/26 19:20:30 ==== pack ====
2018/07/26 19:20:30 Compression to /root/debian-stretch-amd64.tgz
Powering off.
2018/07/26 19:20:44 ==== Recipe done ====
```

So, when building for non-host architecture, we have the same error as was in
case of `VirtualBox`. I'm not sure whether what might be the issue: either
the proper `qemu-static` is not used, or some virtualisation problems? Debugging
of what's going on beneath is not easy, especially if there is no way to have
more debug output from the `debos` or `fakemachine` tools (at least I have not
found any).

## Conclusion

`debos` seems like a really cool tool for Debian images building without
tinkering with `debootrap` and `chroot` script that much. Unfortunately, I was
unable to build any image for `arm` or `arm64` so far (which is my main
interest). Maybe on the native installed `Debian` it would just work perfectly
- I did not have opportunity to try it this way. I think that having a docker
container with `debos` tool fits perfectly to this case and would allow many
more people to benefit from using it. I will try to push my work upstream and
discuss, so the cross-building issues will be hopefully resolved.

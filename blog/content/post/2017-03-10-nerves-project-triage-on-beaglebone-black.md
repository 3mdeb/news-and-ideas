---
ID: 63051
title: Nerves project triage on BeagleBone Black Black
author: piotr.krol
post_excerpt: ""
layout: post
private: false
published: true
date: 2017-03-10 22:53:55
archives: "2017"
tags:
  - embedded
  - linux
  - arm
  - BeagleBone
categories:
  - Firmware
  - OS Dev
---

Recently one of my customers brought to my attention
[Nerves](http://nerves-project.org). It aims to simplify use of Elixir
(functional language leveraging Erlang VM) in embedded systems. This system has
couple interesting features that are worth of research and blog post.

First is booting directly to application which is running in BEAM (Erlang VM).
Nerves project replace systemd process with programming language virtual machine
running application code. Concept is very interesting and I wonder if someone
tried to use that with other VMs ie. JVM.

Second Nerves seems to utilize dual image update procedure. In my opinion any
development of modern embedded system should start with update system. Any
design that you can to your system update arsenal will be useful.

Third, Nerves use Buildroot as build system, which will I'm familiar with. Using
popular build systems means simplified support for huge set of platforms (at
point of writing this article Buildroot have 142 config files).

## Let's start with documentation

If you don't want to go through all
[installation steps](https://hexdocs.pm/nerves/installation.html) and you use
Debian testing, you can run:

```bash
sudo apt-get install erlang elixir ssh-askpass squashfs-tools \
git g++ libssl-dev libncurses5-dev bc m4 make unzip cmake
```

### Erlang

Checking exact Erlang version for non Erlang developers is trivial:

```bash
$ erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), \
"releases", erlang:system_info(otp_release), "OTP_VERSION"])), \
io:fwrite(Version), halt().' -noshell
19.2.1
```

### Elixir

Checking Elixir version:

```bash
$ elixir --version
Erlang/OTP 19 [erts-8.2.1] [source] [64-bit] [smp:4:4] [async-threads:10] [kernel-poll:false]

Elixir 1.3.3
```

Unfortunately Nerves Project requires at least `1.4.0`, what can be solved by:

```bash
sudo apt-get remove elixir
wget https://packages.erlang-solutions.com/erlang/elixir/FLAVOUR_2_download/elixir_1.4.1-1\~debian\~jessie_all.deb
sudo dpkg -i elixir_1.4.1-1~debian~jessie_all.deb
$ elixir --version
Erlang/OTP 19 [erts-8.2.1] [source] [64-bit] [smp:4:4] [async-threads:10] [kernel-poll:false]

Elixir 1.4.1
```

### fwup

`fwup` have to be installed from `deb` package:

```bash
wget https://github.com/fhunleth/fwup/releases/download/v0.13.0/fwup_0.13.0_amd64.deb
sudo dpkg -i fwup_0.13.0_amd64.deb
```

I don't understand why Nerves Projects used `fwup`, when software like
`swupdate` from Denx is available. I don't see difference in feature set and
would say that `swupdate` is more flexible and covers more use cases. It looks
like Nerves Project is main user of `fwup`.

Maybe it would be worth to consider comparison of `fwup` and `swupdate` ?

### nerves_bootstrap

```bash
mix local.hex
mix local.rebar
mix archive.install https://github.com/nerves-project/archives/raw/master/nerves_bootstrap.ez
```

## hello_nerves for BeagleBone Black

```bash
mix nerves.new hello_nerves
export MIX_TARGET=bbb
cd hello_nerves
mix deps.get
mix firmware
```

### Flashing to SD card

```bash
mix firmware.burn -d /dev/sdX
```

### booting

```bash
U-Boot SPL 2016.03 (Mar 07 2017 - 18:34:42)
Trying to boot from MMC
reading args
spl_load_image_fat_os: error reading image args, err - -1
reading u-boot.img
reading u-boot.img


U-Boot 2016.03 (Mar 07 2017 - 18:34:42 +0000)

       Watchdog enabled
I2C:   ready
DRAM:  512 MiB
Reset Source: Power-on reset has occurred.
MMC:   OMAP SD/MMC: 0, OMAP SD/MMC: 1
Using default environment

Net:   <ethaddr> not set. Validating first E-fuse MAC
cpsw, usb_ether
Press SPACE to abort autoboot in -2 seconds
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
reading /boot.scr
2308 bytes read in 5 ms (450.2 KiB/s)
## Executing script at 80000000
Running Nerves U-Boot script
reading uEnv.txt
** Unable to read file uEnv.txt **
reading zImage
4350536 bytes read in 243 ms (17.1 MiB/s)
reading am335x-boneblack.dtb
55541 bytes read in 9 ms (5.9 MiB/s)
Kernel image @ 0x82000000 [ 0x000000 - 0x426248 ]
## Flattened Device Tree blob at 88000000
   Booting using the fdt blob at 0x88000000
   Loading Device Tree to 8ffef000, end 8ffff8f4 ... OK

Starting kernel ...

[    0.000508] clocksource_probe: no matching clocksources found
[    0.377452] wkup_m3_ipc 44e11324.wkup_m3_ipc: could not get rproc handle
[    0.587493] omap_voltage_late_init: Voltage driver support not added
[    0.691687] bone_capemgr bone_capemgr: slot #0: No cape found
[    0.735661] bone_capemgr bone_capemgr: slot #1: No cape found
[    0.779680] bone_capemgr bone_capemgr: slot #2: No cape found
[    0.823659] bone_capemgr bone_capemgr: slot #3: No cape found
Erlang/OTP 19 [erts-8.2] [source] [async-threads:10] [kernel-poll:false]

Interactive Elixir (1.4.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

It look that things work out of the box and Elixir started and D2 LED blinks
continuously.

## Nerves booting

It looks like developers configured Linux kernel `bootargs` used by U-Boot to
run `elrinit` as init process. `erlinit` is relatively simple application that
can parse configuration file and do some basic system initialization. Depending
on needs this may be considered quite weird approach. Of course adding `systemd`
is not best approach for all solutions. For sure having custom init binary
remove need for complex init system and makes updates much smaller. Also this
solution targets dedicated embedded systems that whole purpose is running Elixir
application.

Using custom init binary also limit attack vector to small amount of code. In
typical build from Buildroot or Yocto final image contain quite a lot of process
run by default. Nerves limit that to one that is needed for very specific use
case that can be fully handled by Elixir application. Of course still some
hardware setup is needed. In that case only Linux kernel or Elixir application
can be attacked.

As one of my associate mention this is very similar approach to `Busybox`
although here we replace shell with Elixir interpreter, but idea is similar to
have one application that is entry point to the system.

From performance perspective this is also good solution since there a no daemons
working in background that consuming resources. Lack of additional processes
means that all server type of work have to be written in Elixir.

It would be very interesting to see how this approach can work for other VMs and
if there are real world use cases for that.

## erlinit & erlexec

`erlinit` is MIT licensed `/sbin/init` replacement. In general it:

- setup pseudo-filesystems like `/dev`, `/proc` and `/sys`
- setup serial console
- register signal hendlers (`SIGPWR`, `SIGUSR1`, `SIGTERM`, `SIGUSR2`)
- forks into cleanup process and new that start `erlexec`

`elrexec` is mix of C++ and Erlang that aim to control OS processes from Erlang
application.

Source code can be found on Github:
[erlinit](https://github.com/nerves-project/erlinit) and
[erlexec](https://github.com/saleyn/erlexec).

## Note about building natively

Recently I'm huge fan of containers and way this technology can be utilized by
embedded software developers. Installing all dependencies in your environment is
painful and can cause problems if you do not pay attention. Containers give you
ability to separate tools for each project. In that way you create one
`Dockerfile` for whole development environment and then share it with your
peers. I believe Nerves Project shall share containers to build system images
instead of maintaining documentation explaining how to setup development for lot
of various environments.

For example steps for Debian required more of jumping between pages and googling
then it was worth since correct set of packages solve issue.

## Summary

Do you plan to use Nerves in your next embedded systems project ? Maybe you
struggle with adapting similar approach for different VM ? Feel free to share
your ideas and issues in comments. If you think content valuable please share
this help us in providing more content to our blog.

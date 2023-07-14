---
title: Measuring memory and CPU usage on Orange Pi with Yocto & Armbian
abstract: 'This article will show you how to perform and interpret measurements
           CPU usage, temperature and memory on OrangePi Zero'
cover: /covers/rte-new-revision.jpg
author: piotr.konkol
layout: post
published: true
date: 2020-05-14
archives: "2020"

tags:
  - yocto
  - rte
  - linux
  - arm
categories:
  - IoT
  - Miscellaneous

---

## Intro

This article will show you how to perform and interpret measurements of some of
embedded systems computational resources. Case covered here will be an attempt
to resolve a question whether our configuration will be sufficient for the given
tasks, or an upgrade of the hardware specification will be necessary. IoT and
embedded systems often tend to overgrow in terms of device number. It is
necessary to perform such analysis and match the specification exactly with the
planned workload and the profit from such action will show as the system grows
larger.

Hardware configuration we will use is based on [RTE](https://3mdeb.com/products/open-source-hardware/rte/)
with Orange Pi Zero 256MB. This is the default configuration with which the device
is shipped. A question may be made, whether 256MB of memory is sufficient, or
should alternative, 512MB Orange Pi Zero be worth upgrading to. We will compare
the usage of memory on the two operating systems - Armbian and Yocto. We've used Armbian
version: 5.32.170919. Armbian binaries can be downloaded [here](https://dl.armbian.com/_old/orangepizero/archive/).
[Yocto meta-rte](https://github.com/3mdeb/meta-rte) which we used can be found
[here](https://cloud.3mdeb.com/index.php/s/myTkar9CgrgKG9m/download).
Memory will be checked before and during the run of regression test suite.

## Tools we will use

### Basic tools

These should be available on virtually every system.

#### free

`free` displays the total amount of free and used physical and swap
memory in the system, as well as the buffers and caches used by  the
kernel.  The information is gathered by parsing `/proc/meminfo`. Running
it with `-m` option will print the values in mebibytes, which often get
confused with megabytes. The difference is that the former are express the
values as powers of two, while the latter express the values as powers of ten.

To get real-time readings we will combine it with `watch` command, which will
print the result of command supplied to it with the freqency specified by
number passed to `-n` parameter in seconds. The final command is
`watch -n 1 free -m`

#### top

`top` program provides a dynamic real-time view of a running system. It can
display system summary information as well as a list of tasks currently
being managed by the Linux kernel. Its output is complete enough so that
we won't be specifying any additional parameters.

#### /sys/class/thermal/thermal_zone

Thermal sysfs provides us with information about readings from various temperature
sensors installed. Different sensors are available as thermal_zone[0-*] files.
You can check the sensor type by reading `type` file from thermal_zone directory.
In our case the CPU thermal_zone has number `0`. Temperature is stored in
`temp` file as an integer.  To get the output in a more accessible format
of Celcius degrees we will use such command:

```
echo $((`cat /sys/class/thermal/thermal_zone0/temp | cut -c 1-2`)).$((`cat /sys/class/thermal/thermal_zone0/temp | cut -c 3-5`))
```

### Other tools that might be useful

`armbianmonitor` is a simple CLI monitoring program for armbian system which
shows CPU load, percentage usage of: cpu, sys (processes executing in kernel
mode), usr (normal processes executing in user mode), nice (niced processes
executing in user mode), io (waiting for I/O to complete), irq (servicing
interrupts) and CPU temperature.

`vmstat` reports information about processes, memory, paging, block IO, traps,
disks and cpu activity. The first report produced gives averages since the last
reboot. Additional reports give information on a sampling period of length
delay. The process and memory reports are instantaneous in either case.

## Case study - memory and cpu usage during running regression tests

### Armbian

`free` output before tests:

```
total  used  free  shared  buff/cache  available
Mem:   242M   39M   41M     14M        162M       164M
Swap:  127M    0B  127M
```

`free` output during tests:

```
total  used  free  shared  buff/cache  available
Mem:   242M   65M   13M     14M        163M       137M
Swap:  127M    0B  127M
```

```
total  used  free  shared  buff/cache  available
Mem:   242M   35M   43M     14M        163M       167M
Swap:  127M    0B  127M
```

`top` output before tests:

```
load average: 0.00, 0.00, 0.00
Tasks: 123 total,   1 running, 122 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.3 us,  0.4 sy,  0.0 ni, 99.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :   248564 total,    41848 free,    40556 used,   166160 buff/cache
KiB Swap:   131068 total,   131068 free,        0 used.   168392 avail Mem
```

`top` output during tests:

```
load average: 0.53, 0.30, 0.12
Tasks: 132 total,   1 running, 131 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni, 99.9 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :   248564 total,    38644 free,    42900 used,   167020 buff/cache
KiB Swap:   131068 total,   131068 free,        0 used.   165280 avail Mem
```

```
load average: 0.03, 0.13, 0.10
Tasks: 125 total,   1 running, 124 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.2 us,  0.6 sy,  0.0 ni, 99.2 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :   248564 total,    44672 free,    36524 used,   167368 buff/cache
KiB Swap:   131068 total,   131068 free,        0 used.   171404 avail Mem
```

#### Comparison chart

![Armbian](/img/Armbian_load&mem_usage_chart.svg)

### Yocto
`free` output before tests:

```
total  used  free  shared  buff/cache   available
Mem:    244    31   140       9          72         195
Swap:     0     0     0
```

`free` output during tests:

```
total  used  free  shared  buff/cache   available
Mem:    244    35   139       9          72         194
Swap:     0     0     0
```

`top` output before tests:

```
load average: 0.01, 0.03, 0.01
Tasks:  88 total,   1 running,  47 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.3 us,  0.8 sy,  0.0 ni, 98.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :   250680 total,   144612 free,    31752 used,    74316 buff/cache
KiB Swap:        0 total,        0 free,        0 used.   200956 avail Mem
```

`top` output during tests:

```
load average: 0.05, 0.04, 0.01
Tasks:  90 total,   1 running,  49 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.2 us,  0.9 sy,  0.0 ni, 98.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :   250680 total,   142676 free,    33552 used,    74452 buff/cache
KiB Swap:        0 total,        0 free,        0 used.   199148 avail Mem
```

```
load average: 0.08, 0.12, 0.06
Tasks:  90 total,   1 running,  49 sleeping,   0 stopped,   0 zombie
%Cpu(s):  4.1 us,  8.9 sy,  0.0 ni, 87.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :   250680 total,   144328 free,    32124 used,    74228 buff/cache
KiB Swap:        0 total,        0 free,        0 used.   200580 avail Mem
```

#### Comparison table

![Yocto](/img/Yocto_load&mem_usage_chart.svg)

## Summary
As we can see, 256MB of RAM is beyond enough for current feature-set on the
RTE both on Armbian and Yocto, yet there are significant differences between
them as the former had almost twice as high maximal memory usage as the latter.
A similar difference was seen in the maximal spike in cpu load, which on Armbian
was over 4 times that of Yocto. As Yocto is not really an embedded Linux
distribution, but a framework for creating your own, suited specifically to
your goals and hardware it is able to provide much better performance. Armbian
is a good choice for early prototyping, as it's popular and easy to use, but
for final product it is worth considering using Yocto.

3mdeb is a registered Yocto Participant and provides embedded system validation
services.
If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

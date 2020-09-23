---
title: Raspberry Pi and Docker for your home's entertainment and work.
abstract: "Have you ever been trying to automate something at home or at work?
Here it comes for the rescue Raspberry Pi working with Docker!
With these tools, you can create a lot of projects with small effort."
cover: /covers/raspberrypi_docker.png
author: dawid.zebacki
layout: post
published: true
date: 2020-09-23
archives: "2020"

tags:
  - raspberrypi
  - docker
  - miniature computers
  - embedded systems programming
  - embedded systems
  - embedded
  - virtualization
  - microcontrollers
  - raspberry pi projects
  - raspberry pi ideas
  - raspberry pi docker
  - 3mdeb raspberry pi
  - 
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - App Dev
---

Have you ever been trying to automate something at home or at work?
Here it comes for the rescue Raspberry Pi along with Docker! With these tools,
you can create a lot of projects of small effort and low cost.

### What is Raspberry Pi?

Raspberry Pi represents of a small computer. It has all the basic
hardware components like memory, processor, etc. and extensions like USB, Wi-FI,
sound controller. Components of this device depend on the model that
you are using.Due to its small size, availability and low price
it is a very popular device that can perform everything you would expect from
typical PC. For example, you can play videos, browse the internet,
or even play some simple games. However, don't expect the Raspberry Pi
to be as good as the best PC on the market. It is decent computer with some
limitations and it would have some issues loading complex websites
or running more aggravating games, but still the possibilities of this device are
very impressive. For example, with Raspberry Pi you can create:

- Retro Gaming Console,
- Google Home,
- The Parent Detector,
- Weather Station,
- Robots

and a lot more!

### What is Docker?

Docker is an open source project helping developers that helps to create, deploy,
and run applications in a much simpler way by operating on so-called containers.
They are lightweight execution environments that share operating system kernel.
Except for sharing system kernel, containers are running in isolation
with each other. Containers allow us to store libraries, dependencies,
etc. in one place. By that, we can assume that the application will run
on any other device without worries of possible customized settings of
this particular machine.

___

### How to run Docker on Raspberry Pi?

Installation Docker on Raspberry Pi is really fast and easy. Follow these steps:

Download:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
```

Execute script:
```bash
sh get-docker.sh
```

This script will detect OS, install packages, and run Docker.
This operation may take a while so you need to wait. In the end,
the script will output all necessary information about Docker and how to use it.
Additionally, if you want to run commands without prepending sudo
(as a non-root user) you have to add the user name to the Docker group.

Add user to Docker group:
```bash
sudo usermod -aG docker \$USER
```

**Note:** ```$USER``` variable holds your username.
It comes from the environment.

Now Docker is set up on Raspberry Pi and finally,
you can do some cool stuff!

### How to use Docker?

The basic concepts of Docker are **images** and **containers**. The first is
made of filesystem layers that allow to execute applications.
Images contain source code, dependencies, libraries, tools, or instructions for
installing and running an application. Dockerfile image is just a binary file
that is immutable for the user. The second one - containers are mutable beings
that are using Docker images as templates. images and containers may be
compared to classes and instances of this particular class in object-oriented
programming.

![Docker Containers](/img/containersdocker.png)

Docker images are available at a cloud-based registry service called
[Docker Hub](https://hub.docker.com/).
To search for an image (e.g. Debian), use the following commands:

```bash
sudo docker search debian
```

To start, manage, remove, and stop a container you will always
use```docker container``` command.
At this example, we will run Debian from the previous code.

```bash
sudo docker container run debian
```

This container will stop after executing, it doesn't have long-running processes.
To simplify let's say that there were two states:

- booting up -> booted,
- running commands -> empty command.

Then exit process. To interact with the container you have to use flag ```-it```.

```
sudo docker container run -it debian /bin/bash
```

To show all running Docker Containers use:

```
sudo docker container ls
```

To show all containers use flag ```-a```:

```
sudo docker container ls -a
```

To delete container use (pass your container ID):

```
sudo docker container rm CONTAINER_ID
```

### What are the advantages of using Docker with Raspberry Pi?

Docker is giving you the ability to deploy applications with its main
dependencies without needing to reinstall the operating system or undoing
a botched upgrade. These two things are very important for embedded applications
and devices. They may need some redeployments which could brick a device.
Docker on AMR (Advanced RISC Machine) brings hardware products closer to the
 SaaS (Software-as-a-Service) deployment. Continuous updates on the SaaS model
are something very obvious and taken for granted. Docker also allows sending
container differences to the device saving lots of bandwidth. This is another
important thing for embedded devices which they can be often poorly connected.
Another benefit of using Docker with Raspberry Pi is that you can run multiple
capabilities in isolated containers. It is like an ecosystem of dockerfiles
where each of them is adding new functionality to our device.

### Docker security best practices

Docker is not like traditional infrastructure where
applications are hosted on virtual machines or bare-metal servers.
As a result, using containers is breaking some prior assumptions about
visibility. Regular maintenance and proper configuration are highly recommended
to organize servers and containers without any blind spots. There is a list of
best practices about optimizing the Docker environment.

- Use images from a trusted source.
There are a lot of poorly configured containers or they can be infected
with malware. To avoid this enable
[Docker Content Trust (DCT)](https://docs.docker.com/engine/security/trust/content_trust/).

- Harden the host.
You can consider using distributions of OS only for running containers.
Because of that even if someone will hack one container, the other ones will be safe.

- Don't mix containers to protect data.
It is a good practice to avoid mixing containers with different security
requirements. Sharing container infrastructures for multiple customers demand
a very high level of monitoring security.

- Use containers which are lightweight and short-living.
It is a bad practice to continually adding files to one container,
there will be a larger attack surface with not maintained areas.

- Use Docker Bench Security.
[Docker Bench Security](https://hub.docker.com/r/docker/docker-bench-security)
is an analyzing tool of your configuration settings.

- Use seccomp to filter system calls.
Every container is using a Linux kernel. If there are some vulnerabilities
with it our Docker host is also vulnerable. Seccomp (secure computing mode)
filters are enabling to you which system calls a container is allowed to make
to the Linux kernel. Because of that, we are limiting the attack surface.


### Raspberry Pi projects and ideas:

There are some interesting projects which can be done by anyone who has
Raspberry Pi and some engineering skills. Every project has step by
step guide so the entry threshold is very low.

#### Yocto Project

The Yocto Project is an open-source collaboration project that helps
developers build custom Linux-based systems despite the hardware architecture.
The project gives a manageable set of tools and space. Embedded developers can
share configurations, software stacks, technologies, and best practices that can
be used to perform tailored Linux images for embedded and IoT devices,
or anywhere a customized Linux OS is needed. As an open-source project,
the Yocto Project works with a hierarchical governance structure based on
meritocracy and managed by its chief architect. [There](https://www.yoctoproject.org/)
you can read more about this project.

#### RPI build

RPI build is an open-source project that 3mdeb have participated in.
It is a tool to build, install and release Linux kernels
for the Raspberry Pi platform. Check documentation
[here](https://github.com/notro/rpi-build).

#### Smart home hub
The IoT technology connects smart home devices like lights, locks, or security
cameras but you have to control them by something. Often you can use just
a phone to monitor and change states of these devices but if you use multiple
products from different services they might not communicate well with each other.
The hub is a center of your home automation system, it allows you to control
them easily. Nowadays smart technology is a common feature using everywhere.
If you are a person who wants to automate a lot of processes in your home there
is an easy way to do it at a low cost using Raspberry Pi. There is a 
[step by step guide](https://www.forbes.com/sites/forbes-personal-shopper/2018/07/12/everything-you-need-to-set-up-raspberry-pi-home-automation/#4bf1a2f74cdb) written on Forbes magazine how to set up Raspberry Pi
for a smart home hub.

#### AI assistant
An artificial intelligence assistant is a software agent which means that
is a computer program acting for a user or other program in a relationship
of agency. AI assistant is performing tasks for an individual based on questions
or commands. Now you can create one using Raspberry Pi instead of buying
expensive devices from big corporations like Google or Amazon.
Google established cooperation with [The MagPi](https://magpi.raspberrypi.org/),
official Raspberry Pi magazine. This cooperation has provided addons that enable
producers to add artificial intelligence and voice control to
Raspberry Pi projects. There is an official 
[documentation](https://developers.google.com/assistant/sdk/overview)
of Google Assistant on Raspberry Pi.

#### Smart TV
If you have some old TV without Smart technology you can connect
it to the internet with all features with Raspberry Pi. Your new Smart TV will
have new abilities like streaming Netflix, play media from USB storage, search
the web through Google, or check news and weather. Buying a brand new TV
is expensive, there is always a cheaper way if you have some skills
as an engineer. However, don't bother if you are a newbie to Raspberry Pi.
There are a lot of information on the internet and instructions are mostly
written clearly. There is a
[step by step guide](https://www.instructables.com/id/Make-any-Dumb-TV-a-Smart-TV/)
how to create Smart TV from regular TV using Raspberry Pi
and free software called Kodi.

#### Garage opener with plate recognition
There are many projects with openers on the button but we want to automate
it a little bit more. In this project, Raspberry Pi will help us detect which
car is standing in front of our garage door and then check if this particular
car has permissions to access. Everything can be created easily with a simple
camera and [OpenALPR](https://www.openalpr.com/) service of plate verification.
There is a
[guide](https://randomnerdtutorials.com/car-plate-recognition-system-with-raspberry-pi-and-node-red/)
with all prerequisites.

## Summary
Raspberry Pi is a very powerful, small, and cheap device. The number of projects
is infinitely big and the only barrier is your imagination.
There are a lot of add-ons, tools, and controllers which are working perfectly
with Raspberry Pi. I think that every developer or engineer should interest
in this subject and try to do some stuff on his own. The entry threshold is very
low because of a large number of projects on the internet. You can find all the
things you need to develop projects. If you are a newbie I would recommend you
follow instructions on some projects of the previous list. There are also a lot
of open-source projects of Raspberry Pi which can be very interesting. You can
find them [here](https://awesomeopensource.com/projects/raspberry-pi).
If you finish some projects you can try to extend one from the open-source list.
3mdeb is highly recommending open source software because working with these
kinds of projects is strongly developing you to be a better engineer.
The code is publicly accessible and modifiable which allows you to expand
it for your purposes without any restrictions. If you are interested in an
open-source you can check where we have contributed.
[3mdeb open-source](https://opensource.3mdeb.com/)

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)
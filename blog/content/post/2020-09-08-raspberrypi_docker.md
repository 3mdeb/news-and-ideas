---
title: Raspberry PI and Docker for your home's entertainment and work.
abstract: "Did you ever was figuring out how to automate something at home or
work? Here it comes for the rescue Raspberry Pi working with Docker!
With these tools, you can create a lot of projects with small effort."
cover: /covers/raspberrypi_docker.png
author: dawid.zebacki
layout: post
published: true
date: 2020-09-08
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
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - App Dev
---

Did you ever was figuring out how to automate something at home or work?
Here it comes for the rescue Raspberry Pi working with Docker! With these tools,
you can create a lot of projects with small effort and low cost.

### What is Raspberry Pi?

Raspberry PI is a representation of a small computer. Because of littleness
(size like credit-card) and cheapness, it is a very popular device to do
everything that you would expect from a typical PC. For example,
you can play videos, browse the internet, or even play some simple games.
However, don't expect the Raspberry Pi to be as good as a PC. It would have
some issues loading complex websites or running more aggravating games.
The possibilities of this device are infinitely great. There are some
examples of projects that I will discuss furthermore.

Retro Gaming Console,
Google Home,
Control lights with your voice,
The Parent Detector,
Weather Station.

### What is Docker?

Docker open source project helping developers to create, deploy,
and run applications a lot easier by concept named 'containers.'
They are lightweight execution environments sharing operating system kernel.
Except for this case they are running in isolation.
Containers allow us to package up libraries, dependencies, etc. in one place.
By that, we can assume that the application will run on any other device
without worries of possible customized settings of this particular machine.

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
This operation may take a while so you need to wait. At the end script will
output all necessary information about Docker and how to use it.
Additionally, if you want to run commands without prepending sudo
(as a non-root user) you have to add the user name to the Docker group.

Add user to Docker group:
sudo usermod -aG docker \$USER

**Note:** ```$USER``` variable holds your username.
It comes from the environment.

Now Docker is set up on Raspberry Pi and finally,
you are able to do some cool stuff!

### How to use Docker?

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

---
title: Raspberry Pi and Docker for your home's entertainment and work.
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

Did you ever was figuring out how to automate something at home or work?
Here it comes for the rescue Raspberry Pi working with Docker! With these tools,
you can create a lot of projects with small effort and low cost.

### What is Raspberry Pi?

Raspberry Pi is a representation of a small computer. It has all the basic
hardware components like memory, processor, etc. and extensions like USB, Wi-FI,
sound controller. Components of this device depending on the model that
you are using. Because of littleness (size similar to credit-card) and cheapness,
it is a very popular device to do everything that you would expect from
a typical PC. For example, you can play videos, browse the internet,
or even play some simple games. However, don't expect the Raspberry Pi
to be as good as a PC. It would have some issues loading complex websites
or running more aggravating games. The possibilities of this device are
infinitely great. For example with Raspberry Pi you can create:

- Retro Gaming Console,
- Google Home,
- The Parent Detector,
- Weather Station,
- Robots

and a lot more!

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

The basic concepts of Docker are Images and Containers. The first of them
is made of filesystem layers that make a possibility to execute applications.
Inside it are source code, dependencies, libraries, tools, or instructions for
installing and running an application. Dockerfile image is just a binary file
that is immutable for the user. The second one - containers are mutable beings.
They are using Docker Images like templates. If you are a developer you can
think that Docker Image is a class and Container is an instance
of this particular class.

![Docker Containers](/img/containersdocker.png)

Docker images are available at a cloud-based registry service called
[Docker Hub](https://hub.docker.com/).
To search for an image (e.g. Debian), use the following commands.

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

### Raspberry Pi project ideas:

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

#### Automatic Cat Feeder
This project is my favorite because I'm an animal lover and I find
it very useful. The main reason for uprising this device was that when we know
that we will be outside a long amount of time we can feed our animals
remotely or by setting a timer. There is no need to fill a couple of animal
bowls. However, this is not the best way, because we are ruining the schedule
of meals and our animals and they can eat all of the food instantly and starve
later. There is a
[step by step guide](https://storiknow.com/automatic-cat-feeder-using-raspberry-pi/)
by David Bryan, creator of this device.
Following the instructions of his, you will be able to create
a Raspberry Pi feeder for animals.

#### Multi-Room Music Player
In the past home, multi-room would have a lot of wires hidden under the carpet
or into the walls. The future of development technology provides smarter
solutions. Using Raspberry Pi you can connect your speakers remotely and play
audio in multiple rooms. You don't need to use a lot of cables and install
complex control systems now. Expensive way would be just buy a device from
bigger corporations but if you have a soul of an engineer and you love to tinker
this project will be great for you. You can read how to do it under 100$
[here](https://www.instructables.com/id/Raspberry-Pi-Multi-Room-Music-Player/).

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

#### Desktop Notifier
This project provides us a notification manager. It could be used for checking
how many emails, issues, or messages are unread. I find it very helpful when you
are busy working on some projects and you are turning off all notifications.
This notifier just displays the number of unread messages that require our
attention without disturbing us. This device can be modified easily if you want
to track some other things like twitter followers or facebook likes. There is a
[step by step guide](https://www.instructables.com/id/Raspberry-Pi-Desk-Notifier/)
with the required tools and components on how to set up the device.

#### Doorbell Notifier
If you are not at home a lot of time and you want to see who is ringing to your
doorbell, you don't want to open door for some people, or even if someone
is making tricks to you ringing and then run away this device will be perfect
for you. The main goal of this project is that the doorbell notifier will send
an email to your account every time someone rings the bell with a photo of this
person. There are 
[instructions](https://harizanov.com/2013/07/raspberry-pi-emalsms-doorbell-notifier-picture-of-the-person-ringing-it/)
how to set up all of this.

#### Plants watering
This project is similar to the Automatic Cat Feeder which I've discussed before.
There we are not feeding animals but we are controlling the irrigation of plants
with Raspberry Pi. The main goal is to watering the plants only when
it is necessary. This particular project is based on the weather service.
Assuming when the device knows that it will be raining then watering
is not necessary. If there is a sunny day with high temperatures then Raspberry
Pi will enable the schedule of watering the plants. There is a
[guide](https://www.techradar.com/how-to/computing/how-to-automatically-water-your-plants-with-the-raspberry-pi-1315059)
with required tools and components to complete this project.

#### Garage opener with plate recognition
There are many projects with openers on the button but we want to automate
it a little bit more. In this project, Raspberry Pi will help us detect which
car is standing in front of our garage door and then check if this particular
car has permissions to access. Everything can be created easily with a simple
camera and [OpenALPR](https://www.openalpr.com/) service of plate verification.
There is a
[guide](https://randomnerdtutorials.com/car-plate-recognition-system-with-raspberry-pi-and-node-red/)
with all prerequisites.

#### Arcade table
Raspberry Pi is working great with video games emulator. You can connect
joysticks or some other controllers and play old-school games. This particular
project draws attention to the great design of a table. If you are a DIY
enthusiast you will be pleased to create this project. Projects like that are
a personal journey to the past. You can play great old-school games
on an old-school table. I think that is a must-have for every house-parties
and integrations.
[There](https://www.instructables.com/id/Raspberry-Pi-Coffe-Table-Arcade/)
you can see the process of developing this device.

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
Working with open-source projects strongly develops you to be a better engineer
because of working with all the people from the world who also want to helps.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)
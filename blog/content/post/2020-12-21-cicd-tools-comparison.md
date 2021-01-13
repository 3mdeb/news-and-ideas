---
title: 'Comparing popular CI/CD tools for on-premise configuration'
abstract: 'Comparing CI/CD tools: Drone, Buildbot, Tekton, Concourse.
           Self-hosted and open-source alternatives to Jenkins'
cover: /covers/image-file.png
author: piotr.konkol
layout: post
published: true
date: 2020-12-21
archives: "2020"

tags:
  - devops
  - ci
  - cd
  - constant-integration
  - contant-delivery
  - infrastructure
  - on-premise
  - self-hosted
categories:
  - App Dev

---

As constant integration/constant delivery workflow has grown in popularity in
recent years a multitude of tools intended for simplifying this task. As we
are supportive and passionate for open-source and self-hosted solutions we
will compare some of the most interesting projects available that may act
as an alternative to the most popular one, Jenkins or the multitude of
proprietary tools.

## Drone.io

* Github stars: 22.3k
* Written in Go
* Natively handles secrets
* yaml configuration

Drone uniqueness comes from its approach to execution of functionality. Every
step runs as a separate conatiner and is isolated from others. This allows
for easier debugging and less coupling between steps. Containerization helps
with resource conflicts and bottlenecks.

Drone has both free OSS Communnity Edition and Enterprise Edition which free
for inidividuals, students and companies with annual gross revenue less than $1
million US dollars. The Community Edition has stripped functionality with no
Kubernetes integration, SQLite as the only database backend available and no
secret management. It is also limited to single machine and does not support
autoscaling.

## Buildbot

* Github stars: 4.5k
* Written in python
* Project with long history
* python configuration

Buildbot is a project with long history, as first release dates back to 2003.
Initially it was destigned as a build test automation tool.  While its
popularity is much lower than Jenkins it was adopted in many notable projects
such as Yocto project. Buildbots configuration is written in Python, so while
it adds complexity it also gives much greater power to the user. It describes
itself as a job scheduling system. It is not a specific application that
allow to fill in specific details and works well until something not envisioned
by the authors is needed to be done. It is a powerful framework that can grow
as necessary in more complex cases. 
[It is used in many projects](https://github.com/buildbot/buildbot/wiki/SuccessStories)
such as `Yocto Project`, `Python`, `Blender` or `GDB (GNU Debugger)`

## Concourse

* Github stars: 5.4k
* Written in Go
* yaml configuration

Concourse just as Drone is quite young (first released in 2014). It has steep
learning curve, but according to the devs the goal of this project is for the
curve to flatten out shortly after. It has quite unique approach to job
execution based on `Resources` which represent all external inputs nad outputs
of jobs in the pipeline. They allow to abstract external factors like git
repositories and s3 buckets. It's goal is to get rid of itself out of the
way as much as possible and make the server disposable. Artifacts and data
from each step of the process must be passed explicitly. This allows to
get rid of hidden assumptions that may cause problem with understanding
of the worklfow.

## Tekton

* Github stars: 5.8k
* CI/CD framework for Kubernetes

Tekton is a part of cd.foundtaion - a Linux Foundation project. It describes
itself as cloud-native solution for building CI/CD pipelnies. Tekton is
installed and ran on Kubernets cluset. It comprises of a set of Kubernetes
Custom Resources. After installation it can be accessed by Kubernetes CLI
and API calls. Its builtin integration with Kuberentes may be an advantage
if there is already expertise and infrastructre for running it, hovewer
that may not be the case in on-premise setup.

> post cover image should be located in `blog/static/covers/` directory or may be
  linked to `blog/static/img/` if image is used in post content

## Summary

While Jenkins became the CI standard through time, security and scaling issues
may lead us to consider alternatives.  There is no lack of available free and
open options for hosting your own CI/CD server. You can choose between new and
innovative solutions coming fresh to the market or time tested ones. In the
next post I will describe implementation of a chosen CI server.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

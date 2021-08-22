---
title: 'Comparing popular CI/CD tools for on-premise configuration'
abstract: 'Comparing CI/CD tools: Drone, Buildbot, Tekton, Concourse.
           Self-hosted and open-source alternatives to Jenkins'
cover: /covers/ci-cd-icon.png
author:
  - piotr.konkol
  - artur.raglis
layout: post
published: true
date: 2021-08-22
archives: "2021"

tags:
  - devops
  - ci
  - cd
  - infrastructure
  - on-premise
  - self-hosted
categories:
  - App Dev

---

![](/covers/ci-cd-icon.png)

As continuous integration/continuous delivery workflow has grown in popularity
in recent years a multitude of tools intended for simplifying this task has
appeared on the market. As we are supportive and passionate about open-source
and self-hosted solutions we will compare some of the most interesting projects
available that may act as an alternative to the most popular one, Jenkins or the
multitude of proprietary tools.

## [Drone.io](https://www.drone.io/)

![](/img/drone-io-logo.png)

* [GitHub](https://github.com/drone/drone) stars: 23.7k
* Written in Go
* Natively handles secrets
* yaml configuration

Drone uniqueness comes from its approach to the execution of functionality.
Every step runs as a separate container and is isolated from others. This allows
for easier debugging and less coupling between steps. Containerization helps
with resource conflicts and bottlenecks.

The Drone has both free OSS Community Edition and Enterprise Edition which is
free for individuals, students and companies with annual gross revenue of less
than $1 million US dollars. The Community Edition has stripped functionality
with no Kubernetes integration, SQLite as the only database backend available
and no secret management. It is also limited to a single machine and does not
support autoscaling.

## [Buildbot](https://buildbot.net/)

![](/img/buildbot-logo.png)

* [GitHub](https://github.com/buildbot/buildbot) stars: 4.7k
* Written in Python
* Project with long history
* Python configuration

Buildbot is a project with a long history, as the first release dates back to
2003. Initially, it was designed as a build test automation tool. While its
popularity is much lower than Jenkins it was adopted in many notable projects
such as the Yocto Project. Buildbots configuration is written in Python, so
while it adds complexity it also gives much greater power to the user. It
describes itself as a job scheduling system. It is not a specific application
that allows to fill in specific details and works well until something not
envisioned by the authors is needed to be done. It is a powerful framework that
can grow as necessary in more complex cases. [It is used in many
projects](https://github.com/buildbot/buildbot/wiki/SuccessStories) such as the
`Yocto Project`, `Python`, `Blender` or `GDB (GNU Debugger)`

## [Concourse](https://concourse-ci.org/)

![](/img/concourse-logo.png)

* [GitHub](https://github.com/concourse/concourse) stars: 5.8k
* Written in Go
* yaml configuration

Concourse just as Drone is a more recent tool (first released in 2014). It has a
steep learning curve, but according to the devs, the goal of this project is for
the curve to flatten out shortly after. It has quite a unique approach to job
execution based on `Resources` which represent all external inputs and outputs
of jobs in the pipeline. They allow abstracting external factors like git
repositories and s3 buckets. Its goal is to get rid of itself out of the way as
much as possible and make the server disposable. Artifacts and data from each
step of the process must be passed explicitly. This allows getting rid of hidden
assumptions that may cause a problem with understanding the workflow.

## [Tekton](https://tekton.dev/)

![](/img/tekton-logo.png)

* [GitHub](https://github.com/tektoncd/pipeline) stars: 6.5k
* CI/CD framework for Kubernetes

Tekton is a part of cd.foundation - a Linux Foundation project which greatly
raises its significance for us. It describes itself as a cloud-native solution
for building CI/CD pipelines. Tekton is installed and ran on the Kubernetes
cluster. It comprises a set of Kubernetes Custom Resources. After installation,
it can be accessed by Kubernetes CLI and API calls. Its built-in integration
with Kubernetes may be an advantage if there is already expertise and
infrastructure for running it, however, that may not be the case in an
on-premise setup.

## Summary

While Jenkins became the CI standard through time, security and scaling issues
may lead us to consider alternatives.  There is no lack of available free and
open options for hosting your own CI/CD server. You can choose between new and
innovative solutions coming fresh to the market or time-tested ones.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with
us](https://calendly.com/3mdeb/consulting-remote-meeting) or drop us email to
`contact<at>3mdeb<dot>com`. If you are interested in similar content feel free
to [sign up to our
newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

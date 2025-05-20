---
title: Open Source DRTM with TrenchBoot for AMD processors. Introduction.
abstract: This article starts an entire series of articles related to title
          project. By reading this blog post, you will find out why we have
          started such project and who is supporting us. Also, we bring you
          closer to main concept and goals.
cover: /covers/nlnet-logo.png
author: piotr.kleinschmidt
layout: post
published: true
date: 2020-03-28
archives: "2020"

tags:
  - trenchboot
  - open-source
  - coreboot
categories:
  - Firmware
  - Security

---

## Introduction

Our company's activity is to provide secure firmware and embedded systems to our
customers. 3mdeb strategy is to use, contribute and spread open source solutions
as much as possible. Factor, motivating to further work and showing the
legitimacy of the adopted philosophy, is a great community response. Big kudos
to Marek Marczykowski-Górecki (QubesOS) and Thierry Laurion (Insurgo) who
encouraged us to apply for NLnet founds.

We are glad to inform, that we have received a grant from **NLnet Foundation**
for *Open Source DRTM implementation with TrenchBoot for AMD processors*
project. Under the subsidy, **3mdeb Embedded Systems Consulting** wants to
contribute these solutions to the public good, not as proprietary products, but
as free and open source technologies that any person or application can use
without restrictions and modify to their own needs and the needs of others.

This article is an introduction, which should bring you closer to the overall
project's concept and describe goals, which we want to achieve. Also, this blog
post starts a series of articles describing and verifying our progress at work.
Thanks to that, you can observe development process and always be up-to-date
about the project.

## Our goal

Our goal is twofold:

- Implement DRTM with TrenchBoot for AMD processors.
- Create a test environment with test suites for the community.

Above issues will be described later. Both, as already mentioned, will be fully
open-source and available for everybody. Solution which we provide will be
intended for AMD processors because it doesn't include any closed software
components. To do something similar on Intel processors, components called ACM
(Authenticated Code Module) are required. More precisely, first is ACM SINIT
which can be downloaded from Intel website, but is not redistributable. Second
is ACM BIOS which can be obtained only as OEM under CNDA with Intel. Hence, it
denies open-source idea. Also, ACMs are different for every CPU and must be
individually requested from Intel. Moreover, being delivered in a binary form,
there is no way to audit its code. In summary, there are many more problems with
Intel than with AMD.

Now, let me briefly discuss each goal, so you can better understand the project.
Of course, we won't focus on details and all requirements now. Those will be
systematically updated and presented to community.

### DRTM with TrenchBoot

[TrenchBoot](https://github.com/TrenchBoot) _is a framework that allows
individuals and projects to build security engines to perform launch integrity
actions for their systems._ In other words, it provides tools to create the
desirable solution. We will use a technology which measures and verifies running
environment. To obtain that, TrenchBoot utilizes **Dynamic Root of Trust for
Measurements** (DRTM). It is very complex topic and understanding it could take
too much time. What you need to know (or take our word for it) is that those
measurements are done for given piece of code (given piece of system) and are
stored in **Trusted Platform Module** (TPM) special registers. It gives the
possibility to automatically verify them against corruption or malicious
modifications, and eventually proceed or stop further booting.

Also, the user has possibility to check if the measurements are valid. It can be
done from OS level using dedicated tools. So, as you can see, TrenchBoot is
critical piece of bootloader and operating system, if you want to make it
secure. Also, its implementation is fully open-source, so everyone can inspect
it and contribute.

#### Test environment

All requirements of project are automatically or manually validate during
development. For this purpose, we need to create entire testing infrastructure
with suitable hardware and software components. Moreover, all tests will be
published for users, so they can verify development stage on their own
platforms.

Final results, most likely at the end of each month, will be presented in form
of blog articles. Everything should be clearly pointed out and explained. All
used tools, all carried out procedures, all prepared configurations - everything
user can inspect, revise, build, reproduce and finally use. The goal is to have
a user-friendly and trust-worthy environment, so community can be sure about the
quality of the solution we provide.

## Summary

Once again, we would like to thank **NLnet Foundation** for their support. We
believe that our project will benefit the open-source community and will be a
big step in development of firmware security. Also we would like to thank
everyone who significantly develops TrenchBoot project - committers and
reviewers. Special thanks to Daniel Kiper, Andrew Cooper, Daniel P. Smith, Ross
Philipson, Eric Snowberg and others.

As I mentioned in introduction section, above article is just the beginning of
the entire series about **DRTM implementation with TrenchBoot**. So stay tuned
and wait for other articles!

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up for our
newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

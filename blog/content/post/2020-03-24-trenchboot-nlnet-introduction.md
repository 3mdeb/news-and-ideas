---
title: Open Source DRTM with TrenchBoot on AMD processors. Introduction.
abstract:
cover: /covers/nlnet-logo.png
author: piotr.kleinschmidt
layout: post
published: false
date: 2020-03-24
archives: "2020"

tags:
  - trenchboot
  - security
  - open-source
  - coreboot
categories:
  - Firmware
  - Security

---

## Introduction

Our company activity is to provide secure firmware and embedded systems to our
customers. Our strategy is to use, contribute and spread open source solutions
as much as possible. Factor, motivating to further work and showing the
legitimacy of the adopted philosophy, is feedback in the form of satisfied
customers, community and incoming foundations.

We are glad to inform, that we have received a grant from  **NLnet Foundation**
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
1. Implement DRTM on TrenchBoot for AMD processors.
2. Create test environment with test suites for users.

Above issues will be described later. Both, as already mentioned, will be fully
open-source and available for all users. Solution, which we provide will be
intended for AMD processors. It's because it doesn't include any closed
components.

Now, let me briefly discuss each goal, so you can better understand the project.
Of course, we won't focus on details and all requirements now. Those will be
systematically updated and presented to community.

#### DRTM on TrenchBoot

TrenchBoot is one of the stages of boot process. It runs directly after firmware
(coreboot in our case) execution ended. It is a technology which measures and
verifies running environment. To obtain that, TrenchBoot utilizes **Dynamic Root
of Trust for Measurements** (DRTM). It is very complex topic and understanding
it could take too much time. What you need to know (or trust us about) is that
those measurements are done for given piece of code (given piece of system) and
are stored in Trusted Platform Module (TPM) special registers. It gives
possibility to automatically verify them against corruption and eventually
proceed or stop further booting. Also, the user has possibility to check if
measurements are valid. It can be done from OS level using dedicated tools. So,
as you can see, TrenchBoot is critical piece of firmware, if you want to make it
secure. Also, its implementation is fully open-source, so everyone can inspect
that there are no hidden back doors or malware.

#### Test environment

All requirements of project are automatically or manually validate after
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

As I mentioned in introduction section, above article is just the beginning of
the entire series about **DRTM on TrenchBoot implementation**. So stay tuned and
wait for other articles!

Once again, we would like to thank **NLnet Foundation** for their support. We
believe that our project will benefit the open-source community and will be a
big step in development of firmware security.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with
us](https://calendly.com/3mdeb/consulting-remote-meeting) or drop us email to
`contact<at>3mdeb<dot>com`. If you are interested in similar content feel free
to [sign up to our newsletter](http://eepurl.com/gfoekD)

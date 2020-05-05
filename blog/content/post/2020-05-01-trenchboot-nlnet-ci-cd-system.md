---
title: 'TrenchBoot: Open Source DRTM. CI/CD system.'
abstract: How to improve development and validation process in our project?
          Automation? Of course! Let us introduce our CI/CD system. Find out how
          it actually works and what advantages it has.
cover: /covers/trenchboot-logo.png
author: piotr.kleinschmidt
layout: post
published: true
date: 2020-05-01
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

In this `TrenchBoot: Open Source DRTM` release we have introduced **CI/CD
system** to build each TrenchBoot components. It is a big step towards
fully-automated development, validation and deployment. Besides building
advantages, it is a convenient way to deliver all necessary up-to-date binaries.
This article describes how this environment is built, what tools do we use and
how you can utilize our system.

## Continuous Integration / Continuous Delivery - theory

Before you get acquainted with our particular system, we will get you familiar
with **Continuous Integration / Continuous Delivery** concept. What is behind
this idea and how it improves quality of work and final product.

#### Continuous Integration (CI)

Basically this practice is used in the development stage of project and greatly
simplifies release process. Let's consider cyclic, monthly release of our
`TrenchBoot: Open Source DRTM` project. Throughout the whole month, there are
code changes in all repositories related to project. Over time verification of
introduced changes manually  becomes too complex and too uncomfortable. Imagine
building same binaries each time when there is even slight change. It must be
done, but it is ineffective when delegated person must do it by hand. At this
point, **CI** comes with help! It is a system which *automatically builds and
tests specific component* in response to a defined event. This event is mostly
new git commit, tag or merge - it is defined by the owner and adapted to
project's needs. As a result, every code change is automatically checked against
crash and hereby gives quick feedback to the developers.

#### Continuous Delivery (CD)

**Continuous Delivery (CD)** is a successor of CI phase. As mentioned, CI checks
the build and validates its correctness. However, the end products are always
binary files (applications) which should be provided to the users. That is the
scope of CD part. *It releases and publishes* final deliverables called artifacts,
so it can be freely used by user. Moreover, you are sure that those deliveries
(binary files mostly) have passed build and test phases (in CI), which confirms
their correctness in operation.

## Our CI/CD system

Now, when you are familiar with CI/CD concept, let us introduce you to our
environment. We decided to use the **GitLab CI**. For our usage it is most
convenient solution and (in opposition as the name suggest) it works seamlessly
with GitHub repositories too. Please refer to the *TrenchBoot CI/CD
infrastructure* diagram to see the details.

![TrenchBoot CI/CD infrastructure](img/tb_gitlab_ci.png)
*TrenchBoot CI/CD infrastructure*

As you can see our environment is divided into 3 main layers:

1. **Cloud**

    It is a 'gate to the external word' or 'frontend' of our CI/CD system.
    The effects of work of CI/CD are visible in this layer. Also it joins
    together:

    1. All TrenchBoot Github repositories
    1. GitLab CI master (actual CI/CD tool)
    1. Document with reports and status of builds

2. **3mdeb/TrenchBoot infrastructure**

    It is a core of our CI/CD system. When build request is triggered,
    GitLab CI runner is doing the entire job. Results of its work are delivered
    in 3 ways:

    1. Publish artifacts (binaries) to the Cloud layer.
    1. Publish Yocto cached components which are utilized in
    `meta-trenchboot` builds.
    1. Run tests on hardware included in 3mdeb lab.

    As you can see, that layer gathers all parts together. It is  connector
    between high-level Cloud (frontend) and low-level hardware which
    actually use TrenchBoot.

3. **3mdeb lab**

    This layer includes all platforms (Devices Under Test) on which builds
    are automatically tested. They are physically placed in our 3mdeb
    office. So far there is only PC Engines apu2, but as mentioned in
    previous articles, as the project develops, new platforms will be added.

Our CI/CD system is still under development and it is constantly expanded and
improved. It still demands more tests and greater integration between elements.
However, it is already used by us with good and promising results. Therefore,
let's find out how it works in practice and what benefits it brings to users.

### Example of usage

As we mentioned, we use GitLab CI tools in our system. The entry point in this
example is the [GitLab CI organization](https://gitlab.com/trenchboot1) set up
by us. It contains 2 groups of repositories:

1. `TrenchBoot` which contains **mirrors of offcial TrenchBoot upstream
repositories**

1. `3mdeb` which contains **mirrors of 3mdeb/TrenchBoot repositories**

![GtiLab CI repositories](img/tb-gitlab-ci-repositories.png)
*GtiLab CI repositories*

Whenever there are changes in any of the above repository, related CI/CD process
(called pipeline) is triggered. Its result is indicated as `passed` or `failed`
and dedicated artifacts are published and can be download by user. Let's
analyze it with details on the example of `3mdeb/landing-zone` repository.
Follow the procedure:

1. Open [trenchboot1/3mdeb/landing-zone](https://gitlab.com/trenchboot1/3mdeb/landing-zone/)
repository.

2. Navigate through left sidebar to `CI/CD->Pipelines` page.

    Here you can see all pipelines which were run from the very beginning of
    CI/CD system. Most important indicators are:

    1. Status - passed/failed/canceled;
    1. Pipeline - unique ID of build, which can be entered to see details;
    1. Commit - exact commit which triggered the pipeline;
    1. Stages - what stages were done by pipeline; so far there are `build`
    and `test` stages implemented; in this particular example only `build`
    stage is being done;

    > `Build stage` builds binaries from given repository. `Test stage` tests
    those binaries on real hardware. So far test stage is implemented only in
    [trenchboot1/3mdeb/meta-trenchboot](https://gitlab.com/trenchboot1/3mdeb/meta-trenchboot/)
    pipelines. The test checks if PC Engines apu2 platform boots with just built
    meta-trenchboot operating system.

3. Check details of one of pipelines, e.g. [#140929156](https://gitlab.com/trenchboot1/3mdeb/landing-zone/pipelines/140929156)

    There are builds (jobs) of particular element which were done. Go to
    details of one of them, e.g.
    [build_debug_enabled-passed](https://gitlab.com/trenchboot1/3mdeb/landing-zone/-/jobs/531119883)

4. Analyze particular build job.

    ![GtiLab CI build job](img/tb-gitlab-ci-build-job.png)
    *GtiLab CI build job details*

    As you can see, there is console with logs informing what job has been done,
    how it was executed and what is final result. On the right panel, there is
    `Job artifacts` section, where you can browse all artifacts and download
    them. For this particular job there is `lz_header.bin` file. As job's name
    suggest it is debug version of it. Via build job's artifacts you can freely
    download all necessary components to update DRTM in your system.

5. Play around and analyze another pipelines, builds and jobs to have better
insight in our CI/CD infrastructure and, the most important, to obtain all
up-to-date binaries of all TrenchBoot components.

### Requirements verification

##### LZ, Bootloader and operating system is built with CI/CD system.

Each new commit in given repository is automatically built. You can check the
build status in corresponding repositories. You can also download artifacts
there if they are available.

1. [3mdeb/Landing Zone](https://gitlab.com/trenchboot1/3mdeb/landing-zone/pipelines)

2. [3mdeb/GRUB Bootloader](https://gitlab.com/trenchboot1/3mdeb/grub/pipelines)

3. [3mdeb/Linux kernel](https://gitlab.com/trenchboot1/3mdeb/linux/pipelines)

4. [3mdeb/meta-trenchboot - operating system images](https://gitlab.com/trenchboot1/3mdeb/meta-trenchboot/pipelines)

##### CI/CD system SHALL automatically check for regressions of upstream patches to related projects.

Some pipelines besides build triggers test case, which checks component
correctness on PC Engines apu2 platform. Currently it is done for
**meta-trenchboot**. The test flash SSD disk with meta-trenchboot operating
system with DRTM enabled and boots platform to it. Test is passed if platform
boots correct.

[meta-trenchboot test](https://gitlab.com/trenchboot1/3mdeb/meta-trenchboot/-/jobs/538548815)

# Summary

Now, you should be familiar with CI/CD concept and advantages it brings.
Moreover, we have introduced our custom CI/CD infrastructure to you. Remember,
it is beginning of its development. Every next release would probably extend it
and maybe make it more complex. Therefore, it is good to understand it well now,
so you will smoothly move in this environment in the future.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

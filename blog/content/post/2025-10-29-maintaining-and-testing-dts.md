---
title: 'Dasharo Tools Suite: the story about scalability and stability, roadmap'
abstract: 'Nowadays, every software technology is subject to entropy that causes
a cutting-edge technology to become legacy code. This blog post covers Dasharo
Tools Suite automation and testing technologies designed to fight problems,
costs, and bureaucracy in its development process. After that, we will take a
look at the upcoming DTS releases roadmap.'
cover: /covers/maintaining-and-testing-dts.png
author: daniil.klimuk
layout: post
published: true    # if ready or needs local-preview, change to: true
date: 2025-10-29    # update also in the filename!
archives: "2025"

tags:               # check: https://blog.3mdeb.com/tags/
  - DTS
  - Dasharo
  - firmware
  - monolith
  - architecture
categories:         # choose 1 or multiple from the list below
  - Firmware
  - Miscellaneous
  - OS Dev
  - App Dev

---

## What is Dasharo Tools Suite?

![DTS main menu screen](/img/maintaining-and-testing-dts-imgs/dts-main-menu-screen.png)

Dasharo Tools Suite (i.e. DTS) was initially designed for two purposes:

* Support end-users while deploying Dasharo firmware.
* Support Dasharo firmware developers during firmware development.

Hence, DTS is an important part of [Dasharo Universe][dasharo-universe-url] and
to achieve these goals it provides, among others, the following functionalities:

* Dasharo Zero Touch Initial Deployment (i.e. DZTID), that is, a list of
  automated workflows:
  * Initial deployment for Dasharo firmware.
  * Update for Dasharo firmware.
  * Transition for Dasharo firmware.
* Dasharo Hardware Compatibility List Report (i.e. Dasharo HCL or DTS HCL; you
  can find more about it [here][dasharo-hcl-docs]).
* Fusing workflow for some Dasharo firmware (for more information about
  fusing check [Dasharo documentation][fusing-docs].
* Firmware recovery workflow.

DTS is Linux destribution built upon Yocto Project tecnologies with
[`Dasharo/meta-dts`][meta-dts-url] as a core layer, and
[`Dasharo/dts-scripts`][dts-scripts-url] as a core software repository. Apart
from this DTS uses [other layers][kas-common-url] and a [separate
repository][dts-configs] for metadata. The DTS documentation is a part of
[docs.dasharo.com][dts-docs].

And the list of features and the codebase are constantly growing bigger. Lest me
explain how we are holding all this togather.

[dasharo-universe-url]: https://www.dasharo.com/
[meta-dts-url]: https://github.com/dasharo/meta-dts
[dts-scripts-url]: https://github.com/dasharo/dts-scripts
[kas-common-url]: https://github.com/Dasharo/meta-dts/blob/develop/kas/common.yml
[dts-configs]: https://github.com/dasharo/dts-configs
[dts-docs]: https://docs.dasharo.com/dasharo-tools-suite/overview/
[fusing-docs]: https://docs.dasharo.com/glossary/#dasharo-trustroot
[dasharo-hcl-docs]: https://docs.dasharo.com/glossary/#dasharo-hardware-compatibility-list-report

## The challenges

There are two main facts about DTS that causes most of the challenges:

1. It is a software that operates on hardware (that is, flashing firmware,
  reading firmware state, reading hardware state, etc.).
2. It has a monolithic architecture.

The first fact results from the DTS goals described before: it was developed for
Dasharo firmware that is being developed for specific hardware. While the
hardware can be a problem for example during testing by adding hardware setup
overhead, the challenges it broughts up can be at least partially solved via
mocking mechanisms and emulation. In DTS it was solved by designing an automated
testing framework, that uses organization features from [Robot
Framework][robot-framework-url], the DTS hardware and firmware states mocking
infrastructure, and emulation powers of [QEMU][qemu-url].

The second fact is caused by a popular development flow: firstly design software
to reach the goal and then think how to maintain and scale it. The general
consequences of monolithic software design are well known. But the main point
in DTS that cause problems durign development is not well controlled software
execution flow. Let me explain this on a diagram.

![dts-mess-diagram](/img/maintaining-and-testing-dts-imgs/dts-mess-diagram.svg)

As you can see the DTS code can be divided in some groups, responsible for
different functionalities, on one side: remote access, signatures and hashes
verification, etc.. The problem is, that `Non-firmware/hardware -specific code`
are mixed with `Firmware/hardware -specific code`, causing several problems:

* Non-linear execution flow.
* `Firmware/hardware -specific code` is mixed with `Non-firmware/hardware
  -specific code`.
* The amount of `Non-firmware/hardware -specific code` growing togather
  with amount of platforms supported by DTS, that is caused by mixed logic.

All this led to a scalability headache, because, the entire codebase had a
dependency on amount of supported platforms:

![dts-mess-in-scalability-diagram](/img/maintaining-and-testing-dts-imgs/dts-mess-in-scalability-diagram.svg)

The goal right now is to switch from a monolith to microservices architecture
to:

1. Decrease amount of surplus code by separating `Firmware/hardware -specific
  code` and `Non-firmware/hardware -specific code`.
2. Linearise execution flow.
3. Separate distinctive pieces of codebase to make adding unit testing possible.
4. Reuse some pieces of codebase in other projects (e.g. the DTS UI).

Perfectly this should look like this:

![dts-not-mess](/img/maintaining-and-testing-dts-imgs/dts-not-mess.svg)

So we can design and validate the `Non-firmware/hardware -specific code` and
`Firmware/hardware -specific code` separately:

![dts-not-mess-in-scalability](/img/maintaining-and-testing-dts-imgs/dts-not-mess-in-scalability.svg)

How to achieve this? The key is **to add a proper testing** before doing any
changes. Why? Because currently DTS has a huge list of workflow per platform,
and any changes in code without proper automatedregression testing is a problem.

{{< details summary="List of DTS workflows per platform for the curious ones." >}}

```bash
~/Projects/DTS/open-source-firmware-validation on develop ● λ robot -L TRACE -v dts_config_ref:refs/heads/main -t "E2EH003.001*" dts/dts-e2e-helper.robot
==============================================================================
Dts-E2E-Helper
==============================================================================
E2EH003.001 Print names of test cases to be generated :: Print out...
..msi-pro-z790-p-ddr5 Initial Deployment - DPP
msi-pro-z790-p-ddr5 UEFI Update - DPP
msi-pro-z790-p-ddr5 UEFI->Heads Transition - DPP
optiplex-7010 Initial Deployment - DPP
optiplex-7010 UEFI Update - DPP
optiplex-9010 Initial Deployment - DPP
optiplex-9010 UEFI Update - DPP
pcengines-apu2 UEFI Update - DPP
pcengines-apu2 SeaBIOS Update - DPP
pcengines-apu2 SeaBIOS->UEFI Transition - DPP
pcengines-apu3 UEFI Update - DPP
pcengines-apu3 SeaBIOS Update - DPP
pcengines-apu3 SeaBIOS->UEFI Transition - DPP
pcengines-apu4 UEFI Update - DPP
pcengines-apu4 SeaBIOS Update - DPP
pcengines-apu4 SeaBIOS->UEFI Transition - DPP
pcengines-apu6 UEFI Update - DPP
pcengines-apu6 SeaBIOS Update - DPP
pcengines-apu6 SeaBIOS->UEFI Transition - DPP
novacustom-nuc_box-125H Initial Deployment - DCR
novacustom-nuc_box-155H Initial Deployment - DCR
novacustom-v560tu Initial Deployment - DCR
novacustom-v560tu UEFI Update - DCR
novacustom-v560tu UEFI->Heads Transition - DPP
novacustom-v560tu Fuse Platform - DCR
msi-pro-z690-a-ddr5 Initial Deployment - DCR
msi-pro-z690-a-ddr5 Initial Deployment - DPP
msi-pro-z690-a-ddr5 UEFI Update - DCR
msi-pro-z690-a-ddr5 UEFI Update - DPP
msi-pro-z690-a-ddr5 UEFI->Heads Transition - DPP
msi-pro-z690-a-wifi-ddr4 Initial Deployment - DCR
msi-pro-z690-a-wifi-ddr4 Initial Deployment - DPP
msi-pro-z690-a-wifi-ddr4 UEFI Update - DCR
msi-pro-z690-a-wifi-ddr4 UEFI Update - DPP
msi-pro-z690-a-wifi-ddr4 UEFI->Heads Transition - DPP
novacustom-ns50mu Initial Deployment - DCR
novacustom-ns50mu UEFI Update - DCR
novacustom-ns50pu Initial Deployment - DCR
novacustom-ns50pu UEFI Update - DCR
novacustom-ns70mu Initial Deployment - DCR
novacustom-ns70mu UEFI Update - DCR
novacustom-ns70pu Initial Deployment - DCR
novacustom-ns70pu UEFI Update - DCR
novacustom-nv41mb Initial Deployment - DCR
novacustom-nv41mb UEFI Update - DCR
novacustom-nv41mz Initial Deployment - DCR
novacustom-nv41mz UEFI Update - DCR
novacustom-nv41pz Initial Deployment - DCR
novacustom-nv41pz UEFI Update - DCR
novacustom-nv41pz UEFI->Heads Transition - DPP
odroid-h4-plus Initial Deployment - DPP
odroid-h4-plus UEFI Update - DPP
odroid-h4-plus Dasharo (coreboot+UEFI) to Dasharo (Slim Bootloader+UEFI) Transition - DPP
odroid-h4-plus Dasharo (Slim Bootloader+UEFI) Initial Deployment - DPP
novacustom-v540tnd Initial Deployment - DCR
novacustom-v540tnd UEFI Update - DCR
novacustom-v540tu Initial Deployment - DCR
novacustom-v540tu UEFI Update - DCR
novacustom-v540tu UEFI->Heads Transition - DPP
novacustom-v540tu Fuse Platform - DCR
novacustom-v560tnd Initial Deployment - DCR
novacustom-v560tnd UEFI Update - DCR
novacustom-v560tne Initial Deployment - DCR
novacustom-v560tne UEFI Update - DCR
E2EH003.001 Print names of test cases to be generated :: Print out... | PASS |
------------------------------------------------------------------------------
Dts-E2E-Helper                                                        | PASS |
1 test, 1 passed, 0 failed
==============================================================================
Output:  /home/danillklimuk/Projects/DTS/open-source-firmware-validation/output.xml
Log:     /home/danillklimuk/Projects/DTS/open-source-firmware-validation/log.html
Report:  /home/danillklimuk/Projects/DTS/open-source-firmware-validation/report.html
```

{{< /details >}}

[robot-framework-url]: https://robotframework.org/
[qemu-url]: https://www.qemu.org/

## Testing

To continue developing DTS without constantly facing regressions we have
developed a testing methodology called End to End testing (i.e. E2E). The goals
of this methodology are:

1. Cover already exiting functionalities in DTS as is.
2. Let developers introduce internal DTS architecture changes without testing
  methodology restrictions.

The intire methodology relies on one core concept - **black box testing** (i.e.
specification-based testing). In short, black box testing is based on three
things: a system input parameters format, a system output results format, and
relations between groups of input parameters and output parameters. For the DTS
there are three input parameters:

1. **User input** (e.g. which workflow the user choses, what data the user
  provides, etc.).
2. **Hardware state** at the beginning of a DTS workflow (e.g. used CPU or RAM,
  etc.).
3. **Firmware state** at the beginning of a DTS workflow (e.g. firmware
  provider, firmware version, `SMMSTORE` presence, etc.).

And there are two output parameters:

1. **Output for user** (e.g. warnings, errors, decisions, etc.).
2. **Firmware state modifications** (e.g. what parts of firmware were written,
  was `SMMSTORE` migrated or not, etc.).

By manipulating the input parameters and monitoring the output parameters we can
test DTS without caring too much about what is going on inside until the format
of these parameters stays the same, that is:

![dts-e2e-black-box](/img/maintaining-and-testing-dts-imgs/dts-e2e-black-box.svg)

And there is another conccept under DTS E2E testing methodology: **use case
testing**. The `use case` means that the set of tested input parameters are
restricted and divided to two distinct groups:

1. **Success paths** - this are **the execution flows** that are triggered by a
  **specific cobinations of the input parameters** that provide a **specific
  sets of output parameters** that result in **the firmware and hardware states
  after the DTS workflow finishes** to **be expected and correct**.
2. **Error paths** - this are **the execution flows** that are triggered by a
  **specific cobinations of the input parameters** that provide a **specific
  sets of output parameters** that result either in a **DTS workflow fail** or
  **the firmware and hardware states after the DTS workflow finishes** to **be
  unexpected and/or incorrect**.

The definitions could be exlained by the following deagram, where &#x1F642;
outlines the success paths and &#x1F480; outlines the error paths:

![dts-e2e-success-and-error-paths](/img/maintaining-and-testing-dts-imgs/dts-e2e-success-and-error-paths.svg)

The overal goal is to maintain the **success paths** and make sure the **error
paths** are properly handled (e.g. terminated and communicated to the user). But
enough theory, lets get to the tech and implementation details.

### Testing infrastructure and testing theory

<!-- What to test? How to test? In which way to test? -->

### Mocking and QEMU

<!-- DTS mocking infrastructure explanation -->

### Test cases

<!-- OSFV and test cases generation -->

### Adding news tests

<!-- Example in text or a demo -->

### Automation

<!-- OSFV and test cases generation yet again? -->

### Results

#### Example deevlopment flow

<!-- Some demos testing upcoming/latest changes using the E2E tests. --->

#### Publishing results

<!-- TODO -->

## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help. [Schedule
a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to sign up for our newsletter:

{{< subscribe_form "UUID" "Subscribe to 3mdeb Newsletter" >}}

> (TODO AUTHOR) Depending on the target audience, update `UUID` and button text
> from the section above to one of the following lists:
>
> * 3mdeb Newsletter: `3160b3cf-f539-43cf-9be7-46d481358202`
> * Dasharo External Newsletter: `dbbf5ff3-976f-478e-beaf-749a280358ea`
> * Zarhus External Newsletter: `69962d05-47bb-4fff-a0c2-7355b876fd08`

---
title: 'Dasharo Tools Suite: the story about scalability and stability, roadmap'
abstract: 'Check out latest DTS upatest and roadmap. I will start from intro to
DTS and the feature that are coming to it: hardware attestation, Chain of Trust
and Root of Trust provisioning and verification, new hardware support. Then the
brand new DTS E2E testing methodology, that help us maintain and further develop
DTS, will be introduced and explained in details.'
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

DTS is a Linux distribution built upon Yocto Project technologies with
[`Dasharo/meta-dts`][meta-dts-url] as a core layer, and
[`Dasharo/dts-scripts`][dts-scripts-url] as a core code and logic repository.
Apart from this, DTS uses [other layers][kas-common-url] and a [separate
repository][dts-configs] for metadata. The DTS documentation can be found in
[docs.dasharo.com][dts-docs].

## Dasharo Tools Suite and Dasharo Universe

![dts-in-dasharo-universe](/img/maintaining-and-testing-dts-imgs/dts-in-dasharo-universe.png)

Dasharo Tools Suite (i.e., DTS) was initially designed for two purposes:

* Support end-users while deploying Dasharo firmware (the `DTS Prod` on the
  image above).
* Support Dasharo firmware developers during firmware development (the `Dasharo
  Tools Suite (DTS) dev` on the image above).

Hence, DTS is an integral part of [Dasharo Universe][dasharo-universe-url], and
to achieve these goals, it provides, among others, the following
functionalities:

* [Dasharo Zero Touch Initial Deployment][dztid], that is, a list of automated
  workflows:
  * Initial deployment for Dasharo firmware.
  * Update for Dasharo firmware.
  * Transition for Dasharo firmware.
* Dasharo Hardware Compatibility List Report (i.e., Dasharo HCL or DTS HCL; you
  can find more about it [here][dasharo-hcl-docs]).
* Fusing workflow for some Dasharo firmware (for more information about
  fusing, check [Dasharo documentation][fusing-docs]).
* Firmware recovery workflow.

Furthermore, the future DTS releases will add even more functionalities:

* Some platforms will get a Dasharo firmware update (check
  [milestones][dasharo-milestones] for more information). The future releases
  will also include support for server platforms. To get in touch with the
  latest Dasharo and Zarhus teams' success in that field, check the following
  posts:
  * [Porting Gigabyte MZ33-AR1 server board with AMD Turin CPU to
    coreboot][gigabyte-1].
  * [AMD PSP blob analysis on Gigabyte MZ33-AR1 Turin system][gigabyte-2].
  * [Mapping and initializing USB and SATA ports on Gigabyte
    MZ33-AR1][gigabyte-3].
  * [Gigabyte MZ33-AR1 Porting Update: PCIe Init, BMC KVM Validation, and HCL
    Improvements][gigabyte-4].
  * [Gigabyte MZ33-AR1 Porting Update: ACPI and bugfixes][gigabyte-5].
* Full platforms metadata migration from DTS code to
  [Dasharo/dts-configs][dts-configs] that will reduce costs per DTS release and
  increase issue resolution rate.
* The DTS test results can soon be viewed on the [OSFV Dashboard results
  repository][osfv-dashboard] (including the DTS E2E test results).
* As the DTS codebase clean-up will continue, some of its code will be shared
  with other Dasharo and Zarhus projects. Right now, the first one in the queue
  is the DTS UI, which will be shared with the Zarhus Provisioning Box.
* Integration of `fwupd`.
* Further integration with Zarhus Provisioning Box for Root of Trust and Chain
  of Trust provisioning and verification.
  * Check out Zarhus Team talk ["Stop dreading NIS2: Unlock your firmware
  digital sovereignty with Zarhus"][zdm3-nis2] at ZDM#3 for more information
  about Zarhus Provisioning Box.
  * Or Qubes OS Summit talk ["Qubes Air: Opinionated Value Proposition for
    Security-Conscious Technical Professionals"][qubes-os-summit-talk] for more
    information about isolation and management of security artifacts.
* Attestation of Dasharo-supported platforms via procedures and attestation
  infrastructure.
  * Check out [the opening of ZDM#3][zdm3-opening] for more information about
    attestation.

And the list of features and the codebase are constantly growing bigger. Let me
explain how we are holding all this together.

[dasharo-universe-url]: https://www.dasharo.com/
[meta-dts-url]: https://github.com/dasharo/meta-dts
[dts-scripts-url]: https://github.com/dasharo/dts-scripts
[kas-common-url]: https://github.com/Dasharo/meta-dts/blob/develop/kas/common.yml
[dts-configs]: https://github.com/dasharo/dts-configs
[dts-docs]: https://docs.dasharo.com/dasharo-tools-suite/overview/
[fusing-docs]: https://docs.dasharo.com/glossary/#dasharo-trustroot
[dasharo-hcl-docs]: https://docs.dasharo.com/glossary/#dasharo-hardware-compatibility-list-report
[dasharo-milestones]: https://github.com/Dasharo/dasharo-issues/milestones
[osfv-dashboard]: https://github.com/Dasharo/osfv-results
[gigabyte-1]: https://blog.3mdeb.com/2025/2025-08-07-gigabyte_mz33_ar1_part1/
[gigabyte-2]: https://blog.3mdeb.com/2025/2025-09-11-gigabyte-mz33-ar1-blob-analysis/
[gigabyte-3]: https://blog.3mdeb.com/2025/2025-09-12-sata-usb-port-mapping-gigabyte-mz33-ar1/
[gigabyte-4]: https://blog.3mdeb.com/2025/2025-10-10-pcie-mapping-gigabyte-mz33-ar1/
[gigabyte-5]: https://blog.3mdeb.com/2025/2025-11-05-gigabyte-mz33-ar1-acpi-and-bugfixes/
[zdm3-nis2]: https://youtu.be/ewmxq5a0YPQ?si=Z7oxhZ9rA_TUYI2B
[zdm3-opening]: https://youtu.be/rRLcwEN--lg?si=8e86cSmhNsc2q0PP
[qubes-os-summit-talk]: https://cfp.3mdeb.com/qubes-os-summit-2025/talk/CRK7EM/
[dztid]: https://docs.dasharo.com/dasharo-tools-suite/documentation/features/#dasharo-zero-touch-initial-deployment

## The challenges

There are two main facts about DTS that cause most of the challenges:

1. It is a software that operates on hardware (that is, flashing firmware,
  reading firmware state, reading hardware state, etc.).
2. It has a monolithic architecture.

The first fact results from the DTS goals described
[before](#what-is-dasharo-tools-suite): it was developed for Dasharo firmware
that is being developed for specific hardware. While the hardware can be a
problem, for example during testing by adding hardware setup overhead, the
challenges it brings up can be at least partially solved via mocking mechanisms
and emulation. In DTS, it was solved by designing an automated testing framework
that uses automation features from [Robot Framework][robot-framework-url], the
DTS hardware and firmware states mocking infrastructure, and the emulation
powers of [QEMU][qemu-url].

The second fact is caused by a popular development flow that starts by
developing a monolithic script and then trying to scale it. The general
consequences of monolithic software design are well known. But the main point in
DTS that causes problems during development is not well-controlled software
execution flow. Let me explain this on a diagram.

![dts-mess-diagram](/img/maintaining-and-testing-dts-imgs/dts-mess-diagram.png)

As you can see, the DTS code can be divided into some groups, responsible for
different functionalities, on one side: remote access, signatures and hashes
verification, etc.. The problem is that `Non-firmware/hardware-specific code`
is mixed with `Firmware/hardware-specific code`, causing several problems:

* Non-linear execution flow.
* `Firmware/hardware-specific code` is mixed with
  `Non-firmware/hardware-specific code`; therefore it is hard to reuse generic
  code.
* The amount of `Non-firmware/hardware-specific code` growing together
  with amount of platforms supported by DTS, that is caused by mixed logic.

All this led to a scalability headache, because the entire codebase had a
dependency on the number of supported platforms:

![dts-mess-in-scalability-diagram](/img/maintaining-and-testing-dts-imgs/dts-mess-in-scalability-diagram.png)

But as software develops, the monolith architecture key issues arise: "How to
scale the software?" and "How to make sure there are no regressions?". This is
especially important for DTS, because as a key component of the Dasharo Universe
that is responsible for deploying Dasharo firmware, it **must be** stable and
secure. Hence, the goal right now is to switch from a monolith to a
microservices-like architecture to:

1. Decrease the amount of surplus code and improve code reusability by
  separating `Firmware/hardware-specific code` and
  `Non-firmware/hardware-specific code`, which should generally improve the
  scalability of DTS and decrease the features implementation and bug fixing
  delays.
2. Linearise execution flow, fixing the stability problems.
3. Separate distinctive pieces of codebase to make adding unit testing possible,
  further increasing stability and scalability.
4. Reuse some pieces of codebase in other Dasharo and Zarhus projects (e.g., the
  DTS UI shared with Zarhus Provisioning Box), so other projects will invest in
  the DTS source code evolution.

![dts-zpb-ui-meme](/img/maintaining-and-testing-dts-imgs/dts-zpb-ui-meme.png)

Ideally, the DTS codebase should look like this:

![dts-not-mess](/img/maintaining-and-testing-dts-imgs/dts-not-mess.png)

So we can design and validate the `Non-firmware/hardware-specific code` and
`Firmware/hardware-specific code` separately:

![dts-not-mess-in-scalability](/img/maintaining-and-testing-dts-imgs/dts-not-mess-in-scalability.png)

How to achieve this? The key is **to develop a proper testing methodology**
before making any changes. Why? Currently DTS has a huge list of workflows
per platform, and any change in code without proper automated regression testing
is a problem. And the proper testing methodology will both: **decrease costs of
development** by saving time needed for testing, and **help in keeping the
codebase stable** during global changes.

<details><summary> List of DTS workflows per platform for the curious ones. </summary>

```bash
$ robot -L TRACE -v dts_config_ref:refs/heads/main -t "E2EH003.001*" \
dts/dts-e2e-helper.robot
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

Launched according to [DTS OSFV documentation][osfv-dts-docs].

</details>

[robot-framework-url]: https://robotframework.org/
[qemu-url]: https://www.qemu.org/
[osfv-dts-docs]: https://github.com/Dasharo/open-source-firmware-validation/blob/develop/docs/dts-tests.md

## Testing

To continue developing DTS without constantly facing regressions, we have
developed a testing methodology called End to End testing (i.e., E2E). The goals
of this methodology are:

1. Cover already existing functionalities in DTS without the need to adjust them
  to the testing methodology.
2. Let developers introduce internal DTS architecture changes without testing
  methodology restrictions.

The entire methodology relies on two core concepts: **black box testing** (i.e.,
specification-based testing) and **use case testing**. In short, black box
testing is based on three things: a system input parameters format, a system
output results format, and relations between sets of input parameters and output
parameters. For the DTS, there are three input parameters:

1. **User input** (e.g., which workflow the user chooses, what data the user
  provides, etc.).
2. **Hardware state** at the beginning of a DTS workflow (e.g., used CPU or RAM,
  etc.).
3. **Firmware state** at the beginning of a DTS workflow (e.g., firmware
  provider, firmware version, `SMMSTORE` presence, etc.).

And there are two output parameters:

1. **Output for user** (e.g., warnings, errors, questions, etc.).
2. **Firmware state modifications** (e.g., what parts of firmware were written,
  whether `SMMSTORE` was migrated or not, etc.).

By manipulating the input parameters and monitoring the output parameters, the
DTS can be tested without bothering about what is going on inside until the
format of these parameters stays the same, that is:

![dts-e2e-black-box](/img/maintaining-and-testing-dts-imgs/dts-e2e-black-box.png)

And the second concept under DTS E2E testing methodology: **use case testing**.
The `use case` means that the entire set of DTS execution flows triggered by
input parameters is divided into two distinct groups:

1. **Success paths** - these are **the execution flows** that are triggered by
  specific combinations of the input parameters that provide a specific sets of
  output parameters that result in **the firmware and hardware states after the
  DTS workflow finishes** to **be expected and correct**.
2. **Error paths** - these are **the execution flows** that are triggered by
  specific combinations of the input parameters that provide a specific sets of
  output parameters that result either in a **DTS workflow fail** or **the
  firmware and hardware states after the DTS workflow finishes** to **be
  unexpected and/or incorrect**.

The definitions could be visualized by the following diagram, where &#x1F642;
outlines the success paths and &#x1F480; outlines the error paths:

![dts-e2e-success-and-error-paths](/img/maintaining-and-testing-dts-imgs/dts-e2e-success-and-error-paths.png)

The overall goals are **to maintain** the success paths and make sure the error
paths **are properly handled** (e.g., terminated and communicated to the user).
But enough theory, let's get to the tech and implementation details.

### Testing infrastructure

Currently, we have three DTS testing architectures:

![dts-testing-architectures](/img/maintaining-and-testing-dts-imgs/dts-testing-architecture.png)

Where:

* The `Testing on real hardware` is covered by
  [OSFV/dasharo-compatibility][dts-dasharo-compatibility] or done manually.
* The `Testing on QEMU` and `Testing in CI/CD workflows` are covered by
  [OSFV/dts][osfv-dts-e2e]. These testing architectures are available due to the
  presence of the DTS E2E methodology, as its development triggered the
  development of several testing technologies.
* The OSFV stands for **Open Source Firmware Validation**: it is a testing
  framework developed as a part of Dasharo Universe and based on [Robot
  Framework][robot-framework-url]. For more information, check the
  [Dasharo/open-source-firmware-validation repository][dasharo-osfv].

Two different testing workflows apply to these architectures. For the `Testing
on real hardware`, the following general workflow applies:

![dts-testing-on-hardware-workflow](/img/maintaining-and-testing-dts-imgs/dts-testing-on-hardware-workflow.png)

For the `Testing on QEMU` and `Testing in CI/CD workflows`, the following
workflow applies:

![dts-testing-on-qemu-workflow](/img/maintaining-and-testing-dts-imgs/dts-testing-on-qemu-workflow.png)

Every testing flow and architecture has its own advantages and disadvantages:

* The `Testing on real hardware` advantage is that it is the **closest
 reflection of a real user experience**, hence it is the most trusted
 architecture.
* The `Testing on real hardware` disadvantage is that it has a **dependency on
  hardware**. It is not only that a developer or a tester needs to prepare
  hardware once before testing (that, even if done once, costs around 90% of the
  time spent on actual testing), but also if the hardware causes false positives
  or false negatives, the **entire testing**, including the `Prepare hardware`
  step, **should be redone**. And I am not even mentioning the delays caused by
  bricked hardware, which sometimes forces software developers to wait for
  the hardware team's help.
* `Testing on QEMU` or `Testing in CI/CD workflows` advantages are:
  * It can be done **entirely automatically** (e.g., in [GitHub
    Actions][dts-github-actions-testing]) whenever a developer wants to test
    something.
  * It **does not depend on hardware**, hence there is no `Prepare hardware`
    step overhead or any false negatives (e.g. bad hardware connection that
    cause test to fail) caused by hardware.
    Therefore, it **optimizes the developer's inner loop** by **reducing the
    time** needed for testing.
* `Testing on QEMU` or `Testing in CI/CD workflows` disadvantage is, that the
  test results obtained from testing on mocked hardware **must be proven to be
  trustworthy**.

By connecting the testing infrastructure with the **black box concept** of the
DTS E2E testing methodology and the inputs/outputs described at the beginning of
the [Testing chapter](#testing) with OSFV, I can provide some examples:

* The OSFV controls the `User input` and `Output for user` parameters by
  communicating with the DTS UI. [Example OSFV keyword][osfv-kw] for reading and
  writing to DTS UI:

    ```text
    Wait For Checkpoint And Write
        [Documentation]    This KW waits for checkpoint (first argument)
        ...    and writes specified answer (second argument), with logging all
        ...    output before the checkpoint.
        [Arguments]    ${checkpoint}    ${to_write}    ${regexp}=${FALSE}
        ${out}=    Wait For Checkpoint And Write Bare
        ...    ${checkpoint}    ${to_write}${ENTER}    ${regexp}
        Log    Waited for """${checkpoint}""" and written "${to_write}"
        RETURN    ${out}
    ```

* The `Hardware state`, and `Firmware state` inputs are set:
  * For `Testing on real hardware` - by the `Prepare hardware` step (that
    actually [can be done by the
    OSFV][osfv-prep-kw]).
  * For `Testing on QEMU` or `Testing in CI/CD workflows` - by the `Mock
    hardware` step (that [is done by OSFV][osfv-e2e-prep-kw]).
* The `Firmware state` output is verified:
  * For `Testing on real hardware` - by the tester.
  * For `Testing on QEMU` or `Testing in CI/CD workflows` - [by the
  OSFV][osfv-profile-ver-kw].

But how does the mocking work, and how does the OSFV verify the `Firmware state`
output?

[dts-dasharo-compatibility]: https://github.com/Dasharo/open-source-firmware-validation/blob/develop/dasharo-compatibility/dasharo-tools-suite.robot
[osfv-dts-e2e]: https://github.com/Dasharo/open-source-firmware-validation/tree/develop/dts
[dasharo-osfv]: https://github.com/Dasharo/open-source-firmware-validation
[dts-github-actions-testing]: https://github.com/Dasharo/meta-dts/blob/62795064aef813a8b2269c3a4e52dcd0fa775140/.github/workflows/test.yml#L46
[osfv-kw]: https://github.com/Dasharo/open-source-firmware-validation/blob/84f491882f977a5f895ad2b87dd747d32ce62a5e/lib/dts-zarhus.robot#L30
[osfv-prep-kw]: https://github.com/Dasharo/open-source-firmware-validation/blob/84f491882f977a5f895ad2b87dd747d32ce62a5e/lib/dts-lib.robot#L475
[osfv-e2e-prep-kw]: https://github.com/Dasharo/open-source-firmware-validation/blob/84f491882f977a5f895ad2b87dd747d32ce62a5e/dts/dts-e2e.robot#L510
[osfv-profile-ver-kw]: https://github.com/Dasharo/open-source-firmware-validation/blob/84f491882f977a5f895ad2b87dd747d32ce62a5e/dts/dts-e2e.robot#L565

### Mocking on QEMU

DTS mocking system is quite an important piece of DTS E2E methodology, as it
helps to provide the mocked configurable `Hardware state` and `Firmware state`
inputs on QEMU, as well as play a key role in proving the trustworthiness of
the test results obtained from testing on QEMU.

As was explained before, DTS has the `Firmware/hardware-specific code` that
consists of calls to `Firmware/hardware-specific tools` that do two things:

* **Get data** from hardware or firmware (that is, the way the DTS code acquires
  the data from the `Hardware state` and `Firmware state` inputs). An example
  tool call:

    ```bash
    flashrom -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} \
    -r "$tmp_rom" >>"$FLASH_INFO_FILE" 2>>"$ERR_LOG_FILE"
    ```

    That dumps the currently-flashed firmware from the platform for further
    parsing and analysis.

* **Modify the firmware state** (that is, the way the DTS code manipulates the
  `Firmware state` output). An example tool call:

    ```bash
    flashrom -p "$PROGRAMMER_EC" ${FLASH_CHIP_SELECT} \
    -w "$EC_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
    ```

    That writes the EC (i.e., Embedded Controller) firmware.

The idea is to separate the calls in the DTS code from the actual tool calls by
[a wrapper][toolwrapper-url]:

```bash
tool_wrapper() {
  # Usage: tool_wrapper TOOL_NAME MOCK_FUNC_NAME TOOL_ARGS
  #
  #    TOOL_NAME: the name of the tool being wrapped
  #    MOCK_FUNC_NAME: the name of mocking function (optional, check comments
  #    below for more inf.)
  #    TOOL_ARGS: the arguments that the tool gets if being called, for example
  #    for dmidecode -s system-vendor it will be "-s system-vendor".
  #
  # This function is a bridge between common DTS logic and hardware-specific DTS
  # logic or functions. There is two paths a call to this function can be
  # redirected to: real HAL for running on real platform and Tests HAL for testing
  # on QEMU (depends on whether the var. DTS_TESTING is set or not).
  #
  # The real HAL are the real tools e.g. cbfstool, etc.. The testing HAL are the
  # mocking functions. There are several types of mocking functions, with every
  # type having a specific name syntax:
  #
  # FUNCTIONNAME_mock(){...}: mocking functions specific for every platform, those
  # are stored in $DTS_MOCK_PLATFORM file which is sourced at the beginning of
  # this file.
  # TOOLNAME_FUNCTIONNAME_mock(){...}: mocking functions common for all platforms
  # but specific for some tool, those are stored in $DTS_MOCK_COMMON file, which
  # is being sourced at the beginning of this file.
  # TOOLNAME_common_mock(){...}: standard mocking functions for every tool that
  # are common for all platforms, those are stored in $DTS_MOCK_COMMON file, which
  # is being sourced at the beginning of this file.
  # common_mock(){...}: common mocking function, in case we need to use mocking
  # function for a tool but we do not care about its output.
  #
  # This tool wrapper should only be used with tools which communicate with
  # hardware or firmware (read or write, etc.).
  #
  # TODO: this wrapper deals with arguments as well as with stdout, stderr, and $?
  # redirection, but it does not read and redirect stdin (this is not used in any
  # mocking functions or tools right now).
  # Gets toolname, e.g. poweroff, dmidecode. etc.:
  local _tool="$1"
  # Gets mocking function name:
  local _mock_func="$2"
  # It checks if _mock_func contains smth with _mock at the end, if not -
  # mocking function is not provided and some common mocking func. will be used
  # instead:
  if ! echo "$_mock_func" | grep "_mock" &>/dev/null; then
    unset _mock_func
    shift 1
  else
    shift 2
  fi
  # Other arguments for this function are the arguments which are sent to a tool
  # e.g. -s system-vendor for dmidecode, etc.:
  local _arguments=("$@")

  if [ -n "$DTS_TESTING" ]; then
    # This is the order of calling mocking functions:
    # 1) dont_mock - use original command
    # 2) FUNCTIONNAME_mock;
    # 3) TOOLNAME_FUNCTIONNAME_mock;
    # 4) TOOLNAME_common_mock;
    # 5) common_mock - last resort.
    if [ "$_mock_func" = "dont_mock" ]; then
      dont_mock "$_tool" "${_arguments[@]}"
    elif [ -n "$_mock_func" ] && type $_mock_func &>/dev/null; then
      $_mock_func "${_arguments[@]}"
    elif type ${_tool}_${_mock_func} &>/dev/null; then
      ${_tool}_${_mock_func} "${_arguments[@]}"
    elif type ${_tool}_common_mock &>/dev/null; then
      ${_tool}_common_mock "${_arguments[@]}"
    else
      common_mock $_tool
    fi
  else
    # If not testing - call tool with the arguments instead:
    $_tool "${_arguments[@]}"
  fi
  # !! When modifying this function, make sure this is return value of wrapped
  # tool (real of mocked)
  ret=$?
  echo "${_tool} ${_arguments[*]} $ret" >>/tmp/logs/profile
  echo "${BASH_SOURCE[1]}:${FUNCNAME[1]}:${BASH_LINENO[0]} ${_tool} ${_arguments[*]} $ret" >>/tmp/logs/debug_profile

  return $ret
}
```

That is a part of [DTS HAL][dts-hal-url] that defines most of its rules:

```bash
# For testing, every hardware-specific tool must utilize DTS_TESTING
# variable, which is declared in dts-environment and set by user. If DTS_TESTING
# is not "true" - HAL communicates with hardware and firmware via specific tools
# otherwise it uses mocking functions and tool_wrapper to emulate behaviour of
# some of the tools.
#
# Real HAL is placed in $DTS_HAL* (* means that, apart from common HAL funcs.
# there could be, in future, files with platform-specific HAL funcs) and the
# Tests HAL is placed in $DTS_MOCK* (* means that, apart from common mocks,
# there could be, in future, files with platform-specific mocking functions).
```

The following flow diagram could explain the general execution flow of the
wrapper:

![tool-wrapper-flow](/img/maintaining-and-testing-dts-imgs/tool-wrapper-flow.png)

And with the `tool_wrapper`, the aforementioned `flashrom` calls will change to:

* For the **get data** call:

    ```bash
    $FLASHROM flashrom_read_firm_mock -p "$PROGRAMMER_BIOS" \
    ${FLASH_CHIP_SELECT} -r "$tmp_rom" >>"$FLASH_INFO_FILE" 2>>"$ERR_LOG_FILE"
    ```

* For the **modify the firmware state** call:

    ```bash
    $FLASHROM -p "$PROGRAMMER_EC" ${FLASH_CHIP_SELECT} \
    -w "$EC_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
    ```

Because of the [`flashrom` tool wrapping][flashrom-wrapping]:

```bash
FLASHROM="tool_wrapper flashrom"
```

Hence, for the calls, the following mocks will be executed if the `DTS_TESTING`
has some value assigned:

* For the **get data** call:

    ```bash
    flashrom_read_firm_mock() {
      # Emulating dumping of the firmware the platform currently uses. Currently it is
      # writing into text file, that should be changed to binary instead (TODO).
      # For -r check flashrom man page:
      local _file_to_write_into
      flashrom_verify_internal_chip "$@" || return 1
      _file_to_write_into=$(parse_for_arg_return_next "-r" "$@")

      echo "Test flashrom read." >"$_file_to_write_into"

      return 0
    }
    ```

* For the **modify the firmware state** call:

    ```bash
    common_mock() {
      # This mocking function is being called for all cases where mocking is needed,
      # but the result of mocking function execution is not important.
      local _tool="$1"

      echo "${FUNCNAME[0]}: using ${_tool}..."

      return 0
    }
    ```

One could ask: "But every platform gets different data via the `Hardware state`
and `Firmware state` inputs, do you write a separate mocking function for every
combination of input data?". The answer is no, every mocking function can be
configured via, though not named so officially, the `DTS HAL mocking API`, that
is, a set of Bash variables (whose names begin with `TEST_`) that are set either
by a tester or a testing automation tool. Hence, the `Hardware state` and
`Firmware state` DTS inputs for a mocked hardware are controlled via the `DTS
HAL mocking API`. Here is an example of a `flashrom` mocking function that uses
the variables:

```bash
flashrom_check_intel_regions_mock() {
  # For flash regions check emulation, for more inf. check check_intel_regions
  # func.:
  flashrom_verify_internal_chip "$@" || return 1
  if [ "$TEST_BOARD_HAS_FD_REGION" = "true" ]; then
    echo -n "Flash Descriptor region (0x00000000-0x00000fff)"

    if [ "$TEST_BOARD_FD_REGION_RW" = "true" ]; then
      echo " is read-write"
    else
      echo " is read-only"
    fi
  fi

  if [ "$TEST_BOARD_HAS_ME_REGION" = "true" ]; then
    echo -n "Management Engine region (0x00600000-0x00ffffff)"

    if [ "$TEST_BOARD_ME_REGION_RW" = "true" ]; then
      echo -n " is read-write"
    else
      echo -n " is read-only"
    fi

    [ "$TEST_BOARD_ME_REGION_LOCKED" = "true" ] && echo -n " and is locked"
    echo ""
  fi

  if [ "$TEST_BOARD_HAS_GBE_REGION" = "true" ]; then
    echo -n "Gigabit Ethernet region (0x00001000-0x00413fff)"

    if [ "$TEST_BOARD_GBE_REGION_RW" = "true" ]; then
      echo -n " is read-write"
    else
      echo -n " is read-only"
    fi

    [ "$TEST_BOARD_GBE_REGION_LOCKED" = "true" ] && echo -n " and is locked"
    echo ""
  fi

  return 0
}
```

Let me introduce a quick definition before continuing. **DTS mocking
configuration** (or just **mocking configuration** later in this blog post) - is
a set of the `DTS HAL mocking API` variables that properly mocks **hardware X**
for **DTS workflow Y**. And here is an example for a complete mocking
configuration for platform [MSI PRO Z690-A DDR4][msi-z690-dasharo] (the
`msi-pro-z690-a-wifi-ddr4` part) for DTS Initial Deployment workflow without DPP
access (that is marked by DCR string, i.e. Dasharo Community Release; the
`Initial Deployment - DCR` part):

```bash
$ robot -L TRACE -v dts_config_ref:refs/heads/main \
-v config:msi-pro-z690-a-wifi-ddr4 -t "E2EH002.001*" dts/dts-e2e-helper.robot
==============================================================================
Dts-E2E-Helper
==============================================================================
E2EH002.001 Print names and exports of test cases to be generated ...
.--------------------------------------------------
msi-pro-z690-a-wifi-ddr4
--------------------------------------------------
---------------
msi-pro-z690-a-wifi-ddr4 Initial Deployment - DCR
---------------
export TEST_BIOS_VERSION="v0.0.0"
export DTS_CONFIG_REF="refs/heads/main"
export DTS_TESTING="true"
export TEST_SYSTEM_MODEL="MS-7D25"
export TEST_BOARD_MODEL="PRO Z690-A WIFI DDR4(MS-7D25)"
export TEST_SYSTEM_VENDOR="Micro-Star International Co., Ltd."
export TEST_BIOS_VENDOR="3mdeb"
export TEST_CPU_VERSION="TBD_variable_not_set_and_should_be_defined_in_platform_config_if_needed"
export TEST_INTERNAL_PROGRAMMER_CHIPNAME="Opaque flash chip"
export TEST_USING_OPENSOURCE_EC_FIRM="false"
export TEST_BOARD_HAS_BOOTSPLASH="false"
export TEST_VBOOT_KEYS="true"
export TEST_FMAP_REGIONS=""
export TEST_SOUND_CARD_PRESENT="false"
export TEST_BOARD_HAS_GBE_REGION="false"
export TEST_HCI_PRESENT="true"
---------------
(...)
```

For information on how it works on the OSFV side, refer to [its
documentation][osfv-dts-docs].

Here is a workflow on how to construct such a mocking configuration for
**platform X** and **DTS workflow Y**:

![dts-mock-conf-constr](/img/maintaining-and-testing-dts-imgs/dts-mock-conf-constr.png)

But in such a workflow the mocking configuration that controls the `Hardware
state` and `Firmware state` inputs for running DTS on QEMU with mocked hardware
is being prepared by verifying it not against `Hardware state` and `Firmware
state` inputs collected from running DTS on real hardware, but against `User
input` and `Output for user` from running DTS on real hardware. Because the
`User input` and `Output for user` cannot be directly mapped on mocked
`Hardware state` and `Firmware state` inputs (because, the former is literally
input and output of DTS UI, and the latter is information read from firmware
or hardware). This fact results in the aforementioned need for the test results
obtained from testing on mocked hardware **to be proved to be trustworthy**.

[toolwrapper-url]: https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/hal/dts-hal.sh#L66
[dts-hal-url]: https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/hal/dts-hal.sh#L7
[flashrom-wrapping]: https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/hal/dts-hal.sh#L29
[msi-z690-dasharo]: https://docs.dasharo.com/variants/msi_z690/releases/

### DTS profiles and QEMU testing results trustworthiness

Now we know how to mock the `Hardware state` and `Firmware state` inputs, let's
clarify to prove the correctness of the mocking, hence proving the
trustworthiness of the DTS E2E test results on mocked hardware. Ideally, we want
to measure the `Hardware state` and `Firmware state` directly, so we can treat
the measurements as an ultimate source of trust when preparing the mocking
configuration:

![dts-mock-conf-constr-refined](/img/maintaining-and-testing-dts-imgs/dts-mock-conf-constr-refined.png)

And it is actually possible! Do you remember the word `profile` that has already
been mentioned several times in this blog post? The `profile`, or, more
precisely, `DTS profile`, is a tool that was developed for measuring `Hardware
state` and `Firmware state` inputs for **proving the results' trustworthiness**.

As was mentioned before, the `DTS profile` is being collected by
`tool_wrapper()`. Here is [an example of a `profile`][dts-profile-example] that
is used to prove the trustworthiness of the mocking configuration for the
aforementioned DTS E2E test case `msi-pro-z690-a-wifi-ddr4 Initial Deployment -
DCR`:

```bash
dmidecode -s system-manufacturer 0
dmidecode -s system-product-name 0
dmidecode -s baseboard-product-name 0
dmidecode -s processor-version 0
dmidecode -s bios-vendor 0
dmidecode -s bios-version 0
fsread_tool test -f /sys/firmware/efi/efivars/FirmwareUpdateMode-d15b327e-ff2d-4fc1-abf6-c12bd08c1359 1
dmidecode -s system-manufacturer 0
dmidecode -s system-product-name 0
dmidecode -s baseboard-product-name 0
dmidecode -s processor-version 0
dmidecode -s bios-vendor 0
dmidecode -s bios-version 0
dmidecode  0
dmidecode -s system-manufacturer 0
dmidecode -s system-product-name 0
dmidecode -s baseboard-product-name 0
dmidecode -s processor-version 0
dmidecode -s bios-vendor 0
dmidecode -s bios-version 0
lspci -nnvvvxxxx 0
lsusb -vvv 0
superiotool -deV 0
ectool -ip 0
msrtool  1
dmidecode  0
dmesg  0
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
fsread_tool test -f /sys/class/sound/card0/hw*/init_pin_configs 1
flashrom -p internal --flash-name 0
flashrom -p internal --flash-size 0
flashrom -p internal 0
flashrom -V -p internal:laptop=force_I_want_a_brick -r logs/rom.bin --ifd -i fd -i bios -i me 0
dmesg  0
cbmem  1
cbmem -1 1
mei-amt-check  1
intelmetool -m 0
dmidecode -s system-manufacturer 0
dmidecode -s system-product-name 0
dmidecode -s bios-version 0
dmidecode -s system-product-name 0
dmidecode -s system-manufacturer 0
dmidecode -s system-manufacturer 0
dmidecode -s system-product-name 0
dmidecode -s baseboard-product-name 0
dmidecode -s processor-version 0
dmidecode -s bios-vendor 0
dmidecode -s bios-version 0
fsread_tool test -f /sys/class/mei/mei0/fw_status 0
fsread_tool cat /sys/class/mei/mei0/fw_status 0
flashrom -p internal --flash-name 0
flashrom -p internal --flash-size 0
fsread_tool test -e /sys/class/power_supply/AC/online 1
flashrom -p internal 0
flashrom -p internal -r /fw_backup/rom.bin --ifd -i fd -i bios -i me 0
flashrom -p internal 0
flashrom -p internal 0
ifdtool -d /tmp/biosupdate 1
fsread_tool test -d /sys/class/pci_bus/0000:00/device/0000:00:16.0 0
setpci -s 00:16.0 42.B 0
cbfstool /tmp/biosupdate extract -r COREBOOT -n config -f /tmp/biosupdate_config 0
cbfstool /tmp/biosupdate layout -w 0
flashrom -p internal -r /tmp/dasharo_dump.rom --ifd -i fd -i bios -i me --fmap -i FMAP -i BOOTSPLASH 1
cbfstool /tmp/dasharo_dump.rom extract -r BOOTSPLASH -n logo.bmp -f /tmp/logo.bmp 1
dmidecode -s system-uuid 0
dmidecode -s baseboard-serial-number 0
cbfstool /tmp/biosupdate layout -w 0
cbfstool /tmp/biosupdate layout -w 0
cbfstool /tmp/biosupdate layout -w 0
cbfstool /tmp/biosupdate add -f /tmp/serial_number.txt -n serial_number -t raw -r COREBOOT 0
cbfstool /tmp/biosupdate add -f /tmp/system_uuid.txt -n system_uuid -t raw -r COREBOOT 0
cbfstool /tmp/biosupdate expand -r FW_MAIN_A 0
cbfstool /tmp/biosupdate add -f /tmp/serial_number.txt -n serial_number -t raw -r FW_MAIN_A 0
cbfstool /tmp/biosupdate add -f /tmp/system_uuid.txt -n system_uuid -t raw -r FW_MAIN_A 0
cbfstool /tmp/biosupdate truncate -r FW_MAIN_A 0
cbfstool /tmp/biosupdate expand -r FW_MAIN_B 0
cbfstool /tmp/biosupdate add -f /tmp/serial_number.txt -n serial_number -t raw -r FW_MAIN_B 0
cbfstool /tmp/biosupdate add -f /tmp/system_uuid.txt -n system_uuid -t raw -r FW_MAIN_B 0
cbfstool /tmp/biosupdate truncate -r FW_MAIN_B 0
flashrom -p internal -N --ifd -i bios -w /tmp/biosupdate_resigned.rom 0
reboot  0
dmidecode  0
```

The above profile presents the commands that are used for:

* Acquiring information via `Hardware state` input, e.g.:

    ```bash
    fsread_tool test -e /sys/class/power_supply/AC/online 1
    ```

    That checks the power adapter presence.

* Acquiring information via `Firmware state` input, e.g.:

    ```bash
    flashrom -p internal -r /tmp/dasharo_dump.rom --ifd -i fd -i bios -i me --fmap -i FMAP -i BOOTSPLASH 1
    ```

    That dumps some firmware regions for further analysis.

* Does some firmware state modifications via `Firmware state` output, e.g.:

    ```bash
    flashrom -p internal -N --ifd -i bios -w /tmp/biosupdate_resigned.rom 0
    ```

    That flashes Dasharo firmware.

There are other commands that, at first glance, cannot be assigned to any of the
mentioned inputs and outputs. Because the commands do not contact the firmware
or hardware states directly (that is, via drivers or any middleware, but with
real hardware or firmware), but rather use previously dumped into a file data,
or use files for any other operations. For example, the command:

```bash
cbfstool /tmp/biosupdate layout -w 0
```

That reads information about the Dasharo firmware image (that is stored in a
file) layout. Or:

```bash
cbfstool /tmp/dasharo_dump.rom extract -r BOOTSPLASH -n logo.bmp -f /tmp/logo.bmp 1
```

That extracts the bootsplash logo from the dumped firmware. We consider such
commands a part of the DTS inputs (the `Firmware state` input for these two
cases). And the commands:

```bash
cbfstool /tmp/biosupdate add -f /tmp/serial_number.txt -n serial_number -t raw -r COREBOOT 0
cbfstool /tmp/biosupdate add -f /tmp/system_uuid.txt -n system_uuid -t raw -r COREBOOT 0
```

That add hardware serial number and system UUID to the to be flashed Dasharo
firmware image. We consider such commands a part of the DTS `Firmware state`
output.

Okay, now it is clear how the DTS inputs and outputs are being measured, but how
to **prove the trustworthiness** of the DTS E2E test results on mocked hardware?
Well, several conditions should be met before stating that the results are
trustworthy:

1. There should be **a trusted up-to-date** `DTS profile` collected from **real
  hardware**.
2. The DTS E2E test workflow should provide a `DTS profile` **collected during
  testing on QEMU with mocked hardware**.
3. The profiles from the **first condition** and the **second condition** should
  match.

The profiles can be collected from the real hardware either manually or using
automatic or semi-automatic [OSFV helpers][dts-gen-profiles]. The workflow with
the OSFV helpers is as follows:

![dts-gen-profiles-osfv-helpers](/img/maintaining-and-testing-dts-imgs/dts-gen-profiles-osfv-helpers.png)

Where `DTG` is a part of OSFV test case ID (an example of a complete ID can be
found [here][osfv-dtg])For collecting the profiles manually, the workflow is as
follows:

![dts-gen-profiles-manually](/img/maintaining-and-testing-dts-imgs/dts-gen-profiles-manually.png)

Where:

* `S1`: specific for every hardware (check [Dasharo Supported hardware
  page][dasharo-sup-hard-page] for more information).
* `S2.2`: specific for every hardware and firmware (check [Dasharo Supported
  hardware page][dasharo-sup-hard-page] for more information).
* `S2.3`: according to [DTS documentation][dts-running] or according to [OSFV
  scripts][osfv-ipxe-script] (for custom-built DTS).
* `S2.4`: enable SSH server in DTS and enter shell, then remove logs and
  profiles:

    ```bash
    rm -rf /tmp/logs/*profile
    ```

    Then create a fake `reboot` command:

    ```bash
    mkdir -p /tmp/bin
    echo '#!/bin/bash' >/tmp/bin/reboot
    chmod +x /tmp/bin/reboot
    ```

    Boot DTS again:

    ```bash
    PATH="/tmp/bin:$PATH" dts-boot
    ```

* `S2.5`: run chosen DTS workflow.
* `S2.6`: after DTS finishes press `Enter` and, **without touching DUT** (i.e.,
  Device Under Test), copy the profile via SSH from the DUT to the host:

    ```bash
    scp root@<DUT_IP>:"/tmp/logs/*profile" ./
    ```

* `S7`: copy the profile to the [OSFV directory with
  profiles][osfv-profiles-dir], naming it according to [OSFV
  documentation][osfv-dts-docs] (in a format `OSFV_TEST_CASE_NAME.profile`).
* `S8`: developer verifies that the state of hardware and firmware is expected
  and correct.

Now OSFV has access to the profile acquired from real hardware, and you can
create a mocking configuration according to the workflows described previously.
After the mocking configuration is created, you should add an OSFV DTS E2E test
case that will use the profile you generated, according to [OSFV DTS
documentation][osfv-dts-docs]. After that, you can launch the test case you have
prepared according to the same documentation and check the results. You should
expect one of the following results:

* Test passes.
* `User input` or `Output for user` fail: OSFV will report to you that it
  detected unexpected DTS UI behaviour; This could be caused by issues in the
  used mocking configuration or a DTS bug. Example:

    ```bash
    ------------------------------------------------------------------------------
    E2E008: novacustom-v540tnd Fuse Platform - DCR                        | FAIL |
    No match found for 'Fusing is irreversible. Are you sure you want to continue? [n/y]' in 2 minutes
    Output:

    7
    Gathering flash chip and chipset information...
    Flash information: Opaque flash chip
    Flash size: 2M
    Waiting for network connection ...
    Network connection have been established!
    Downloading board configs repository...
    Checking if board is Dasharo compatible.
    Getting platform specific GPG key... Done
    No release with fusing support is available for your platform.
    Press Enter to continue..
    ------------------------------------------------------------------------------
    ```

    Here OSFV expects the DTS to print `Fusing is irreversible. Are you sure you
    want to continue? [n/y]`. But DTS does not print the string, because to do
    so, the platform `novacustom-v540tnd` should have fusing support, but at the
    time of testing, the platform did not support the fusing. Hence, the fail is
    expected.

* `Hardware state` input, `Firmware state` input, or `Firmware state` output
  fail: will be signalled by profiles mismatch, e.g:

    ```bash
    ------------------------------------------------------------------------------
    E2E043: msi-pro-z690-a-wifi-ddr4 UEFI->Heads Transition - DPP         | FAIL |
    Teardown failed:
    Profiles are not identical!: 1 != 0
    ------------------------------------------------------------------------------
    ```

    This means either **the profile collected from hardware is not up to date**,
    **an issue in the used mocking configuration**, or **a bug in DTS**. This
    particular fail [was caused by an issue][dts-profile-issue]. The comment in
    the profile means that though the DTS on QEMU returns exactly the same
    profile, the profile from the real `msi-pro-z690-a-wifi-ddr4` platform for
    DTS workflow `UEFI->Heads Transition - DPP` was not proved trustworthy
    because of the linked issue. Hence, the trustworthiness of the test result
    on QEMU cannot be proved.

* Some OSFV bug: try to fix it or report via the [OSFV issues
  page][osfv-issues].

#### A note about error paths

All the explanations from the chapters before apply to both the `success paths`
and the `error paths`, because the mocking, profiles, testing on QEMU,
and all other technologies presented could be used for testing both paths. The
only difference is in the test cases implementations:

* `Success paths`: the execution flow starts when the user selects a DTS
  workflow and finishes when the chosen workflow finishes and the platform is
  ready to be rebooted (an example case, not every DTS workflow causes such a
  state at the end). Hence, the entire testing technology stack is involved
  (including the mocking configuration, profiles, etc.).
* `Error paths`: the execution flow starts when the user selects a DTS workflow,
  but finishes at any point of DTS workflow execution flow. Hence, a test case
  for an `error path` could use a subset of testing technologies mentioned here.

Some `error paths` test cases examples:

* [A test case][error-path-no-mocking] that does not mock a specific platform:

    ```text
    E2E013.001 Verify that FUM update doesn't start automatically
        [Documentation]    Test that booting via FUM doesn't start update without
        ...    user input
        Execute Command In Terminal    export DTS_TESTING="true"
        Execute Command In Terminal    export TEST_FUM="true"
        Write Into Terminal    dts-boot

        Wait For Checkpoint    You have entered Firmware Update Mode
        Wait For Checkpoint    ${DTS_ASK_FOR_CHOICE_PROMPT}
    ```

    This test case covers an `error path` that is not platform-dependent and
    appears at the very beginning of the DTS execution flow: in the
    `Non-firmware/hardware-specific code` part. Hence, it does not need
    specific mocking or profile checking.

* [A test case][error-path-no-profile] that mocks a specific platform, but does
  not use profiles:

    ```text
    E2E010.001 Failure to read flash during update should stop workflow
        [Documentation]    Test that update stops if flash read in
        ...    set_flashrom_update_params function fails.
        Export Shell Variables For Emulation
        ...    UEFI Update
        ...    DCR
        ...    ${DTS_PLATFORM_VARIABLES}[novacustom-v540tu]
        ...    ${DTS_CONFIG_REF}
        Execute Command In Terminal    export TEST_LAYOUT_READ_SHOULD_FAIL="true"
        Write Into Terminal    dts-boot

        VAR    @{checkpoints}=    @{EMPTY}
        Add Checkpoint And Write    ${checkpoints}    ${DTS_CHECKPOINT}    ${DTS_DEPLOY_OPT}    bare=${TRUE}
        Add Optional Checkpoint And Write    ${checkpoints}    ${DTS_HEADS_SWITCH_QUESTION}    N
        Add Checkpoint And Write    ${checkpoints}    ${DTS_SPECIFICATION_WARN}    Y
        Add Checkpoint And Write    ${checkpoints}    ${DTS_DEPLOY_WARN}    Y
        Wait For Checkpoints    ${checkpoints}
        Wait For Checkpoint    Couldn't read flash
        Wait For Checkpoint    ${ERROR_LOGS_QUESTION}
    ```

    There is no need to prove the test result trustworthiness or mocking
    correctness via profiles, because [a specific case][dts-specific-case] is
    being tested that defines the exact things that should be mocked on the
    `Hardware state` and `Firmware state` inputs (in this, case only the
    `Firmware state` actually). And there is no need to check what will land on
    the `Firmware state` output when the `error path` triggers DTS workflow
    execution stopping, because the test case only needs to confirm the
    execution will stop and [the user will be informed
    accordingly][dts-user-informed] (including asking to report the issue by
    sending debug logs to 3mdeb, via `${ERROR_LOGS_QUESTION}`). Hence, checking
    only the `Output for user` is sufficient.

[dts-gen-profiles]: https://github.com/Dasharo/open-source-firmware-validation/blob/develop/dts/dts-gen-profile.robot
[dts-profile-example]: https://github.com/Dasharo/open-source-firmware-validation/blob/develop/dts/profiles/msi-pro-z690-a-wifi-ddr4%20Initial%20Deployment%20-%20DCR.profile
[dasharo-sup-hard-page]: https://docs.dasharo.com/variants/overview/
[dts-running]: https://docs.dasharo.com/dasharo-tools-suite/documentation/running/
[osfv-ipxe-script]: https://github.com/Dasharo/open-source-firmware-validation/blob/develop/scripts/ci/ipxe-run.sh
[osfv-profiles-dir]: https://github.com/Dasharo/open-source-firmware-validation/tree/develop/dts/profiles
[osfv-issues]: https://github.com/Dasharo/open-source-firmware-validation/issues
[dts-profile-issue]: https://github.com/Dasharo/open-source-firmware-validation/blob/2a7a70c3aea701903bc7d0fcdff8d6d3853a226f/dts/profiles/msi-pro-z690-a-wifi-ddr4%20UEFI-%3EHeads%20Transition%20-%20DPP.profile#L1
[error-path-no-mocking]: https://github.com/Dasharo/open-source-firmware-validation/blob/2a7a70c3aea701903bc7d0fcdff8d6d3853a226f/dts/dts-e2e.robot#L383
[error-path-no-profile]: https://github.com/Dasharo/open-source-firmware-validation/blob/2a7a70c3aea701903bc7d0fcdff8d6d3853a226f/dts/dts-e2e.robot#L318
[dts-specific-case]: https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/dts-functions.sh#L931
[dts-user-informed]: https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/dts-functions.sh#L949
[osfv-dtg]: https://github.com/Dasharo/open-source-firmware-validation/blob/8eae542634f11287a7a9489573574ba614a1e922/dts/dts-gen-profile.robot#L22

## Summary

![dts-e2e-meme](/img/maintaining-and-testing-dts-imgs/dts-e2e-meme.png)

If you have got here, then I can congratulate you, you are really brave! The DTS
E2E testing methodology has been out helping the Zarhus Team maintain DTS for
quite some time, for example, by [detecting issues during
releases][dts-v270-issue] and [fixing it as soon as possible][hotfix] or helping
us omit overhead from testing on hardware during [huge hardware-related
changes][dts-metadata-migration]. And we are very positive that it will be a
game-changer for maintaining DTS code and adding the aforementioned
functionalities in future!

If you want to get even deeper and check all details of DTS E2E testing
methodology implementation or any other updates on DTS, then I suggest you to
star and watch activities on the following repositories:

* [Dasharo/open-source-firmware-validation][osfv-url] for further development of
  DTS E2E testing methodology.
* [Dashro/meta-dts][meta-dts-url] for updates on DTS.
* [Dasharo/dasharo-issues][dasharo-issues-url] for tracking activities about all
  Dasharo projects.
* [Dasharo/dts-scripts][dts-scripts] for updates on the core DTS codebase.

Check out other repositories under the [Dasharo][dasharo-url] and
[Zarhus][zarhus-url] organizations. I am sure you will find something
interesting to contribute to. Consider joining the DTS [Matrix
community][dts-matrix] to share your experience and help us make this world more
stable and secure.

If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help. [Schedule
a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to sign up for our newsletter:

{{< subscribe_form "dbbf5ff3-976f-478e-beaf-749a280358ea" "Subscribe" >}}

[dts-v270-issue]: https://github.com/Dasharo/meta-dts/pull/279#issuecomment-3309155476
[dts-metadata-migration]: https://github.com/Dasharo/dts-configs/pull/20
[dasharo-issues-url]: https://github.com/Dasharo/dasharo-issues
[osfv-url]: https://github.com/dasharo/open-source-firmware-validation
[dts-scripts]: https://github.com/dasharo/dts-scripts
[dasharo-url]: https://github.com/Dasharo
[zarhus-url]: https://github.com/Zarhus
[dts-matrix]: https://matrix.to/#/#dasharo-tools-suite:matrix.org
[hotfix]: https://github.com/Dasharo/dts-configs/pull/16

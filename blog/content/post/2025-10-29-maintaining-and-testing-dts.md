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

math: true

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

The overall goal is to maintain the **success paths** and make sure the **error
paths** are properly handled (e.g. terminated and communicated to the user). But
enough theory, lets get to the tech and implementation details.

### Testing infrastructure

Currently we have three DTS testing architectures:

![dts-testing-architectures](/img/maintaining-and-testing-dts-imgs/dts-testing-architecture.svg)

Where:

* The `Testing on real hardware` is covered by
  [OSFV/dasharo-compatibility][dts-dasharo-compatibility].
* The `Testing on QEMU` and `Testing in CI/CD workflows` are covered by
  [OSFV/dts][osfv-dts-e2e]. These testing architecctures are available due to
  DTS E2E methodology presence.
* The OSFV states for **Open Source Firmware Validation**: it is a testing
  framework developed as a part of Dasharo Universe and based on [Robot
  Framework][robot-framework-url]. For more information check
  [Dasharo/open-source-firmware-validation repository][dasharo-osfv].

Two different testing worklows apply to these architectures. For the `Testing on
real hardware` the following general workflow applies:

![dts-testing-on-hardware-workflow](/img/maintaining-and-testing-dts-imgs/dts-testing-on-hardware-workflow.svg)

For the `Testing on QEMU` and `Testing in CI/CD workflows` the following
workflow applies:

![dts-testing-on-qemu-workflow](/img/maintaining-and-testing-dts-imgs/dts-testing-on-qemu-workflow.svg)

Every testing flow and architecture have its own advantages and disadvanteges:

* `Testing on real hardware` advantage is, that it is the **closest reflection
  of a real user experience**, hence it is the most trusted methodology.
* `Testing on real hardware` disadvantege is, that it has **dependency on
  hardware**. It is not only that a developer or a tester needs to prepare
  hardware once before testing (that even if done once, cost around 90% of the
  time spent on actual test), but also if the hardware causes false positives
  or false negatives the **entire testing**, including the `Prepare hardware`
  step, **should be redone**.
* `Testing on QEMU` or `Testing in CI/CD workflows` advantages are:
  * It can be done **fully automatically** (e.g. in [GitHub
    Actions][dts-github-actions-testing]).
  * It **does not depend on hardware**, hence there is no `Prepare hardware`
    step overhead or any false positives/negatives caused by hardware. Therefore
    it **optimizes the developer's inner loop** by reducing time needed for
    testing.
* `Testing on QEMU` or `Testing in CI/CD workflows` disadvantage is, that the
  test results obtained from testing on mocked hardware **must be proved to be
  trustworthy**.

Connecting the testing infrastructure with the **black box concept** of the DTS
E2E testing methodology and the inputs/outputs described at the beginning on
[Testing chapter](#testing):

* The OSFV controls the `User input` and `Output for user` parameters by
  communication with the DTS UI. [Example OSFV keyword][osfv-kw] for reading and
  writing:

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

* The `Hardware state` and `Firmware state` inputs are set:
  * For `Testing on real hardware` - by the `Prepare hardware` step (that
    actually [can be done by the
    OSFV][osfv-prep-kw].
  * For `Testing on QEMU` or `Testing in CI/CD workflows` - by the `Mock
    hardware` step (that [is done by OSFV][osfv-e2e-prep-kw].
* The `Firmware state` output is verified:
  * For `Testing on real hardware` - by the tester.
  * For `Testing on QEMU` or `Testing in CI/CD workflows` - [by the
  OSFV][osfv-profile-ver-kw].

But how does the mocking work and how does the OSFV verify the `Firmware state`
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

DTS mocking system is quite an important piece of code, as it helps to provide
the `Hardware state` and `Firmware state` inputs as well as play a key role in
proving trustoworthiness of the test results obtained from testing on QEMU.

As was explained before, DTS hase the `Firmware/hardware -specific code` that
consists of calls to `Firmware/hardware -specific tools` that do two things:

* **Get data** from hardware or firmware (that is the way the DTS code acuires
  the data from the `Hardware state` and `Firmware state` inputs). An example:

    ```bash
    flashrom -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} -r "$tmp_rom" >>"$FLASH_INFO_FILE" 2>>"$ERR_LOG_FILE"
    ```

    That dumps the currently-flashed firmware from the platform for further
    parsing and analysis.

* **Modify the firmware state** (that is the way the DTS code manipulates the
  `Firmware state` otuput). An example:

    ```bash
    flashrom -p "$PROGRAMMER_EC" ${FLASH_CHIP_SELECT} -w "$EC_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
    ```

    That writes the EC (i.e. Embedded Controller) firmware.

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

The general execution flow of the wrapper could be explained by the following
flow diagram:

![tool-wrapper-flow](/img/maintaining-and-testing-dts-imgs/tool-wrapper-flow.svg)

And with the `tool_wrapper` the beforementioned `flashrom` calls will change to:
* For the **get data** call:

    ```bash
    $FLASHROM flashrom_read_firm_mock -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} -r "$tmp_rom" >>"$FLASH_INFO_FILE" 2>>"$ERR_LOG_FILE"
    ```
* For the **modify the firmware state** call:

    ```bash
    $FLASHROM -p "$PROGRAMMER_EC" ${FLASH_CHIP_SELECT} -w "$EC_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
    ```

Because of the [`flashrom` tool wrapping][flashrom-wrapping]:

```bash
FLASHROM="tool_wrapper flashrom"
```

Hence for the calls the following macks will be executed if the `DTS_TESTING` is
set:
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
configured via, though not named so offitially, the `DTS HAL mocking API`, that
is a set of Bash variables (that names begin with `TEST_`) that is set either by
a tester or a testing automation tool. Hence the `Hardware state` and `Firmware
state` DTS inputs for a mocked hardware are controlled via `DTS HAL mocking
API`. Here is an exaple of a `flashrom` mocking function that uses the
variables:

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
configuration** (or just mocking configuration later in this blog post) - is a
set of the `DTS HAL mocking API` variables for **hardware X** and **DTS workflow
Y**. And here is an example for a complete mocking configuration for platform
[MSI PRO Z690-A DDR4][msi-z690-dasharo] (the `msi-pro-z690-a-wifi-ddr4` part)
for DTS Initial Deployment workflow without DPP access (that is marked by DCR
string, i.e. Dasharo Community Release; the `Initial Deployment - DCR` part):

```bash
(venv) danillklimuk in ~/Projects/DTS/open-source-firmware-validation on develop ● λ robot -L TRACE -v dts_config_ref:refs/heads/main -v config:msi-pro-z690-a-wifi-ddr4 -t "E2EH002.001*" dts/dts-e2e-helper.robot
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

For information on how it works on OSFV side reffer to [its
documentation][osfv-dts-docs].

Here is a workflow on how to construct such a mocking configuration for
**platform X** and **DTS worklfow Y**:

![dts-mock-conf-constr](/img/maintaining-and-testing-dts-imgs/dts-mock-conf-constr.svg)

But in such a workflow we are preparing the mocking configuration that controls
the `Hardware state` and `Firmware state` for running DTS on QEMU with mocked
hardware by verifying it not against `Hardware state` and `Firmware state`
inputs collected from running DTS on real hardware, but against `User input`
and `Output for user` from running DTS on real hardware. To be more precise the
situation could be explained via mathematical equation. We want:

![dts-we-want](/img/maintaining-and-testing-dts-imgs/dts-we-want.png)

But we get:

![dts-we-get](/img/maintaining-and-testing-dts-imgs/dts-we-get.png)

Where:
* `FSm`: is the mocked `Firmware state` input;
* `HSm`: is the mocked `Hardware state` input;
* `FS`: is the `Firmware state` input for a real hardware;
* `HS`: is the `Hardware state` input for a real hardware;
* `UI`: is the `User input` input;
* `OU`: is the `Ouput for user` output;
* `f1` and `f2`: are function that showcase non-linear relations;
* `X1`, `X2`, and `Z`: are coeficients that represent human error while
  interpreting `User input` and `Output for user` (because these are graphical
  inputs and outputs, where human can ommit some string or provide incorrect
  answer to a question).

The fact that there are non-linear relations and human error coeficients between
the real inputs and the mocked inputs results in the beforementioned need for
the test results obtained from testing on mocked hardware **to be proved to be
trustworthy**.

[toolwrapper-url]: https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/hal/dts-hal.sh#L66
[dts-hal-url]: https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/hal/dts-hal.sh#L7
[flashrom-wrapping]: https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/hal/dts-hal.sh#L29
[flashrom-example]: https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/hal/common-mock-func.sh#L128-L169
[msi-z690-dasharo]: https://docs.dasharo.com/variants/msi_z690/releases/
[osfv-dts-docs]: https://github.com/Dasharo/open-source-firmware-validation/blob/develop/docs/dts-tests.md

### DTS profiles and QEMU testing results trustworthiness

Now we know how to mock the `Hardware state` and `Firmware state` inputs, lets
clarify how to prove 


<!-- DTS mocking infrastructure explanation -->

### Test cases

<!-- OSFV and test cases generation, adding new test cases -->

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

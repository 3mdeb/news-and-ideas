---
title: Implementing UEFI Secure Boot on MPL PIP4x
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: pawel.langowski
layout: post
published: true
date: 2024-03-15
archives: "2024"

tags:
  - secure boot
  - uefi
  - mpl
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

MPL is a Swiss company, which designs and manufactures embedded computer and
microcontroller hardware for rugged environment, extended temperature range
and with long term availability. Their PIP is a family of low power, read-to-use
embedded computers manufactured by MPL. Recently we tackled the problem of
implementing UEFI Secure Boot on platforms from the PIP4x series. The goal of
the project was to verify that the platform in question is compatible with
Secure Boot and to enable automatic signing of system components during build in
Yocto.

## Secure Boot overview

## Verifying Secure Boot compatibility

The first step we took was verifying that Secure Boot could indeed be
implemented on the platform and identifying potential issues and vulnerabilities.
To do that, we developed and executed various automated tests within the Dasharo
OSFV
([Open Source Firmware Validation](https://github.com/Dasharo/open-source-firmware-validation))
environment. It utilizes the [Robot Framework](https://robotframework.org/) – an
open-source automation framework, which simplifies the creation and execution
of test cases.

### Setup

In order to prepare the host machine for Dasharo OSFV infrastructure, follow
these steps:

- Install the following packages:

   ```bash
   sudo apt-get install git virtualenv python3-pip
   ```

- Clone the OFSV repository and update linked submodules

  ```bash
  git clone https://github.com/Dasharo/open-source-firmware-validation
  cd open-source-firmware-validation
  git submodule update --init --checkout
  ```

- Prepare virtualenv

  ```bash
  python3 -m virtualenv venv
  source venv/bin/activate
  pip install -r requirements.txt
  ```

### Test implementation

Development of test cases in the Robot Framework consists of defining
reusable keywords and utilizing them in concrete scenarios. Dasharo OSFV
introduces many such keywords, which allow reading and writing to the terminal,
navigating menus, etc. This allows the developer to implement test cases with
much more ease. Below is an example of a test case, which verifies that Secure
Boot does not allow booting files that are not signed.

```robot
SBO004.001 Attempt to boot file without the key from Shell (firmware)
    [Documentation]    This test verifies that Secure Boot blocks booting a file
    ...    without a key.
    Skip If    not ${TESTS_IN_FIRMWARE_SUPPORT}    SBO004.001 not supported
    Mount ISO As USB    ${CURDIR}/../scripts/secure-boot/images/NOT_SIGNED.img
    # 1. Make sure that SB is enabled
    Power On
    ${sb_menu}=    Enter Secure Boot Menu And Return Construction
    Enable Secure Boot    ${sb_menu}
    # Save Changes And Reset
    # Changes to Secure Boot menu takes action immediately, so we can just reset
    Reset System
    Boot Efi File Should Fail    hello.efi    NOT_SIGNED
```

As you can see, the test case is brief and easily readable thanks to its use of
predefined keywords.

The test suite can be found in the
[OSFV repository](https://github.com/Dasharo/open-source-firmware-validation/blob/main/dasharo-security/secure-boot.robot)
and the detailed description of each test is available on the
[Unified Test Documentation](https://docs.dasharo.com/unified-test-documentation/dasharo-security/206-secure-boot)
page.

The test suite can be run using the following command:

```bash
robot -L TRACE \
  -v ansible_config:yes \
  -v rte_ip:<rte_ip> \
  -v snipeit:no \
  -v config:mpl-pip4 \
  -v device_ip:<device_ip> \
  dasharo-security/secure-boot.robot
```

### Results

The following images show the test suite results:
![uefi-sb-results-report](/img/uefi-sb-results-pt1.png)
![uefi-sb-results-report](/img/uefi-sb-results-pt2.png)

The results lead to the following conclusions:
- The state of UEFI Secure Boot functionality can be freely modified from the
UEFI BIOS Menu, and it is correctly detected from the operating system.
- Verification of launched images works correctly when UEFI Secure Boot is
enabled. The firmware allows the execution of files signed with the appropriate
keys but blocks the booting of unsigned files or files signed with keys not
present in the database (DB) or files with hashes not stored in the database
(DB).
- The firmware correctly recognizes the chain of trust when intermediate
certificates are used, allowing their use in the verification process.
- Keys intended for UEFI Secure Boot must be generated using the RSA
cryptographic algorithm and sizes 2048, 3072, and 4096. Keys generated with the
ECDSA cryptographic algorithm are not correctly supported.
- The firmware does not verify the expiration date of certificates during the
verification of launched files. It means that enrolled certificates may expire
and will not affect the ability to boot files verified by them.
- The firmware only allows the resetting of enrolled certificates when they
have been added from the UEFI BIOS Menu. If they are added from the operating
system, the certificates are marked as External, and only a full firmware
reset (for example, by removing the CMOS battery) allows their removal.
- Certificates enrolled through the Automatic Certificate Provisioning method
are correctly used to verify launched files.
- The sbctl tool can be used to manage UEFI Secure Boot certificates.
- Automatic tests of the sbctl tool and the Automatic Certificate Provisioning
methods have been omitted due to their logic, assuming that firmware can remove
certificates enrolled this way from the UEFI BIOS Menu.

The conclusions allowed us to proceed with Secure Boot integration in the
Yocto layer.

## Automatic signing of system components in Yocto

## Summary


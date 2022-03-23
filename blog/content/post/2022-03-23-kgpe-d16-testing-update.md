---
title: ASUS KGPE-D16 Dasharo testing update
abstract: 'This blog post describes the updates in the validation process of
           Dasharo for ASUS KGPE-D16. You will read about new tests and newly
           detected issues.'
cover: /covers/kgpe_d16.png
author: michal.zygowski
layout: post
published: true
date: 2022-03-23
archives: "2022"

tags:
  - coreboot
  - KGPE-D16
  - firmware
  - Dasharo
  - Validation
  - Testing
categories:
  - Firmware

---

# Introduction

Software testing is very important in every type of project to ensure the
quality reaches the desired level and the product is in production state.
Unlike software testing, firmware testing does not only verify whether the code
behaves as it is supposed to, but also covers functional verification if
hardware works as it should. It makes firmware validation much harder than any
software application as we may face many unexpected and not always reproducible
issues. The firmware industry constantly tries to improve itself in the field
of validation and quality assurance, so is Dasharo. This time we made a huge
leap in ASUS KGPE-D16 testing.

# New tests

One may check the testing results for each release in the [spreadsheet](https://docs.google.com/spreadsheets/d/1rsJECHmYrpkPSByTyt7jmMuQnExE20zW7Zk6c8oMk6E/edit#gid=0).
We have added a bunch of new tests which were conducted on the most recent
v0.3.0 release binary (yes, the test have been repeated on the same binary).
The new test have the 23.03.2022 date appended in the header.

The scope has been extended with the following tests:

* [Dasharo Security: Verified Boot](https://docs.dasharo.com/unified-test-documentation/dasharo-security/201-verified-boot/) booting from slot A
* [Dasharo Compatibility: Platform Suspend and Resume](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31M-platform-suspend-and-resume/)
* [Dasharo Compatibility: Flash Write protection](https://docs.dasharo.com/unified-test-documentation/dasharo-compatibility/31P-flash-write-protection/)
* [Dasharo Performance: Boot measure](https://docs.dasharo.com/unified-test-documentation/dasharo-performance/400-coreboot-boot-measure/)

## Verified boot

The basic tests conducted earlier simply checked if vboot is enabled and the
platform boots. It missed the verification of real vboot functionality. So the
tests have been extended to check whether vboot select firmware partition A to
boot from. It tells us whether vboot verified the firmware correctly and it has
not been tampered with. Additionally we have simulated the attack on firmware
partition A by modifying it inside flash. In such case vboot should detect
tampering with the firmware and request recovery mode. Unfortunately it does
not happen, the platform is stuck in a boot loop unable to request the recovery
mode. The issue has been described [here](https://github.com/Dasharo/dasharo-issues/issues/66)

## Platform suspend resume

Our validation also covers testing of the ACPI S3 suspend/resume. The platform
performs 30 cycles of suspend and resume to OS from RAM. ACPI S3 resume follows
slightly different boot path than normal boot and different issues may be
detected in the process. Fortunately the platform passes the test without issues.

## Flash Write protection

Our KGPE-D16 setups contain DIP8 to SOIC8 flash adapters wit ha header for WP
pin jumper. It allows us to set a write protection range and lock it by
shorting the WP pin with a jumper. Our tests automate the process of setting
the protected ranges. However, the configuration with W25Q128FV 16MB flash
failed the test probably due to a missing or buggy implementation of the write
protection for this particular chip in flashrom. Issue has bee described
[here](https://github.com/Dasharo/dasharo-issues/issues/67). The W25Q64FV 8MB
flash works well. Locking the flash part allows creating a Static Root of Trust.

## Measuring boot time

coreboot has a built-in mechanism to gather timestamps from the platform
initialization steps and calculate thee booting time. Our test automates the
process of extracting those timestamps/measurements and calculates the total
booting time. These values are pretty high right now (25s) since the serial
console debug output is enabled. The BMC also takes a few seconds to be
detected as non-functional (our setups do not have the BMC firmware module).

## Summary

In total we have increased the number of conducted tests by 16 (8 on each
platform setup) of which 12 passed and 4 failed. Specifications of these have
also been prepared which may always be found on the [Dasharo documentation page](https://docs.dasharo.com/unified-test-documentation/overview/).

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

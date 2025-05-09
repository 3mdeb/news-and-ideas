---
title: 'Automating Firmware Security: CI for DBX and Microcode Updates in Dasharo'
abstract: 'Microcode and DBX are critical components in establishing the
          security of your platform. This blog post will discuss how Dasharo
          automates their updates, making our firmware more transparent and
          your platform more secure.'
cover: /covers/dasharo-sygnet.svg
author: michal.kopec
layout: post
published: true
date: 2025-05-07
archives: "2025"

tags:
  - coreboot
  - uefi
categories:
  - Firmware
  - Security

---

## Introduction

From the moment you press the power button, the security of your device begins
with your boot firmware. It plays a critical role in establishing the
trustworthiness of your device.

Dasharo is our open-source firmware distribution based on coreboot, which is
a lightweight initial bootloader that initializes the hardware platform before
passing control to a secondary bootloader. In Dasharo, the secondary bootloader
is typically TianoCore EDK2, which is an implementation of UEFI.

One of the responsibilities of coreboot is to provide microcode updates for the
processor. Microcode updates are critical for firmware security, as they contain
fixes and mitigations for many classes of exploits, like
[Spectre and Meltdown](https://meltdownattack.com/).

On the UEFI side, there is UEFI Secure Boot, which is a method for
cryptographically verifying OS bootloaders before executing them. One of the
components of UEFI Secure Boot is a revocation database, which is called DBX.
It contains hashes of revoked binaries, such as bootloaders with known security
vulnerabilities like [GRUB and the BootHole exploit](https://eclypsium.com/blog/theres-a-hole-in-the-boot/),
but also revoked signing keys certificates. This mechanism provides a way to
revoke entities that were previously considered trusted.

When it comes to overall firmware security trust chain, microcode sits at the
very beginning, and UEFI Secure Boot sits at the very end, just before the OS
starts to load. This is why updating these components regularly is crucial for
platform security, and why we need automatic checks that ensure these components
are up to date.

In this blog post we'll explore how GitHub actions can ensure that these
critical security components are always up-to-date, helping us deliver a secure
firmware solution for our users.

## The components

Both Intel Microcode binaries and the UEFI DBX file are publicly available, by
Intel and the UEFI forum respectively.

Intel Microcode updates are available at Intel's GitHub page:
[link](https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files).

From their readme:

> The Intel Processor Microcode Update (MCU) Package provides a mechanism to
> release updates for security advisories and functional issues, including
> errata.

The microcode is typically provided by coreboot in a Firmware Interface Table
(FIT). This table is parsed before the x86 cores begin to execute code located
at the reset vector, which means that the update is performed before coreboot
has even had a chance to start.

In addition, modern CPUs often depend on ucode updates to _function at all_.
Due to the amount of erratas, a processor may simply refuse to do anything if
a microcode update is not provided.

The OS is also able to load microcode updates, but due to how late in the boot
process that is done, it might be too late to patch some security
vulnerabilities or erratas. One example of such vulnerabilities is the
[INTEL-SA-01139](https://www.intel.com/content/www/us/en/security-center/advisory/intel-sa-01139.html)
advisory. That is why having the latest available version of microcode present
in your firmware is important.

UEFI DBX is available at UEFI Forum's website: [link](https://uefi.org/revocationlistfile).
The page describes what the DBX updates are:

> UEFI Revocation List files contain the, now-revoked, signatures of previously
> approved and signed firmware and software used in booting systems with UEFI
> Secure Boot enabled.

There is also a GitHub repository hosted by Microsoft, hosting the same files:
[link](https://github.com/microsoft/secureboot_objects). For convenience, we
will be using the Microsoft repository, as a git repo is easier to work with
than a HTML page.

## The automation

Dasharo repositories are hosted on GitHub, which means we have access to GitHub
Actions. GH Actions provide a convenient way to write CI workflows in YAML.

Let's start with the microcode workflow. This is the part that performs the
check if the microcode updates are out of date:

```yaml
name: Refresh Intel µcode submodule

on:
  schedule:
    # At 23:35 on every day-of-week from Sunday through Saturday
    # https://crontab.guru/#35_23_*_*_0-6
    - cron: '35 23 * * 0-6'
  workflow_dispatch:

jobs:
  check:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Code
      uses: actions/checkout@v4

    - name: Check if µcode submodule is up to date
      run: |
        git submodule update --init --checkout 3rdparty/intel-microcode
        pushd 3rdparty/intel-microcode
        current=$(git log -1 --pretty=format:"%H")
        git checkout main
        new=$(git log -1 --pretty=format:"%H")
        if [[ $current == $new ]]; then
          echo "Intel µcode submodule is up-to-date."
        else
          echo "Intel µcode submodule is out of date!"
          exit 1
        fi
        popd
```

The logic is easy to understand: checkout the microcode submodule, get the git
revision, checkout the main branch, and check if the revision is different.

Now for the second part, the actual update:

```yaml
  update:
    runs-on: ubuntu-latest
    needs: check
    if: |
      always() && needs.check.result == 'failure'
    steps:
    - name: Checkout Code
      uses: actions/checkout@v4

    - name: Update µcode submodule
      run: |
        git submodule update --init --checkout 3rdparty/intel-microcode
        pushd 3rdparty/intel-microcode
        git checkout main
        popd
    - name: Set current date
      run: |
        pushd 3rdparty/intel-microcode
        echo "RELEASE_DATE=$(git log -1 --pretty='format:%cs')" >> ${GITHUB_ENV}
        popd
    - name: Submit pull request
      uses: peter-evans/create-pull-request@v7.0.7
      with:
        base: dasharo
        branch: update_ucode_${{ env.RELEASE_DATE }}
        title: Update µcode ${{ env.RELEASE_DATE }}
        commit-message: "[automated change] Update µcode ${{ env.RELEASE_DATE }}"
```

If the previous step failed (the microcode is outdated), check out the submodule
to the main branch and create a pull request.

This is how an automatically created PR looks:

![GitHub PR](/img/ucode_workflow.png)

The UEFI automation uses the same ideas:

```yaml
name: Refresh UEFI Secure Boot revocation list

on:
  schedule:
    # At 23:35 on every day-of-week from Sunday through Saturday
    # https://crontab.guru/#35_23_*_*_0-6
    - cron: '35 23 * * 0-6'
  workflow_dispatch:

jobs:
  check:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Code
      uses: actions/checkout@v4
      with:
        path: edk2

    - name: Checkout microsoft/secureboot_objects
      uses: actions/checkout@v4
      with:
        repository: microsoft/secureboot_objects
        path: secureboot_objects

    - name: Check if DBX is out-of-date
      run: |
        old=$(sha256sum edk2/DasharoPayloadPkg/SecureBootDefaultKeys/DBXUpdate.bin | awk '{ print $1 }')
        new=$(sha256sum secureboot_objects/PostSignedObjects/DBX/amd64/DBXUpdate.bin | awk '{ print $1 }')
        if [ "$old" = "$new" ]; then
          echo 'UEFI DBX is up-to-date.'
        else
          echo 'UEFI DBX is out of date.'
          exit 1
        fi

  update:
    runs-on: ubuntu-latest
    needs: check
    if: |
      always() && needs.check.result == 'failure'

    steps:
    - name: Checkout Code
      uses: actions/checkout@v4
      with:
        path: edk2

    - name: Checkout microsoft/secureboot_objects
      uses: actions/checkout@v4
      with:
        repository: microsoft/secureboot_objects
        path: secureboot_objects

    - name: Update DBX blob
      run: |
        cp secureboot_objects/PostSignedObjects/DBX/amd64/DBXUpdate.bin edk2/DasharoPayloadPkg/SecureBootDefaultKeys/DBXUpdate.bin

    - name: Set current date
      run: |
        pushd secureboot_objects
        echo "RELEASE_DATE=$(git log -1 --pretty='format:%cs' PostSignedObjects/DBX/amd64/DBXUpdate.bin)" >> ${GITHUB_ENV}
        popd

    - name: Submit pull request
      uses: peter-evans/create-pull-request@v7.0.7
      with:
        path: edk2
        base: dasharo
        branch: update_dbx_${{ env.RELEASE_DATE }}
        title: Update DBX ${{ env.RELEASE_DATE }}
        commit-message: "[automated change] Update DBX ${{ env.RELEASE_DATE }}"
```

We see the same overall logic:

- Clone the secureboot objects repo
- Make a checksum of the current dbx
- Make a checksum of the latest dbx
- Compare them
- If the sums don't match:
  - update the file
  - create PR

That's pretty much it. These two GitHub workflows automate updates of both
microcode and the revocation database.

## Closing thoughts

Introducing these automatic checks makes our firmware not only more secure,
but also more transparent. As the repositories and their CI workflows are open,
each user can see for themselves when the microcode and DBX were last updated,
and build from the main branch themselves with a guarantee that these components
will be up to date each time.

Other BIOS firmware vendors typically don't provide this information, and if
they do, it's buried in the release notes. It's often not clear if the microcode
is indeed the latest version available from the CPU vendor. Meanwhile, Dasharo
release notes [contain detailed SBoM](https://docs.dasharo.com/variants/novacustom_v540tu/releases_heads/#v090-2025-03-20)
(Software Bill of Materials) sections describing exactly what microcode you're
getting:

![V540TU Heads v0.9.0 SBoM](/img/v540tu_sbom.png)

We hope the
introduction of these checks will make our firmware safer and more worthy of
our users' trust.

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to
[sign up for our newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

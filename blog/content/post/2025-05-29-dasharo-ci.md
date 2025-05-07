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
date: 2025-05-29
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
but also revoked signing keys certificates. Revoking certificates is crucial
because it invalidates all binaries signed by that key, effectively blocking
potentially many compromised tools or bootloaders with a single update, rather
than having to blacklist each individual binary hash.

The firmware chain of trust starts with the earliest code executed (like
microcode) and extends through each subsequent stage (coreboot, UEFI,
bootloader, OS), with each stage verifying the next. A weakness in any link can
compromise the entire system. In terms of the firmware trust chain, microcode
sits at the very beginning, and UEFI Secure Boot sits at the very end, just
before the OS starts to load. This is why updating these components regularly is
crucial for platform security, and why we need automatic checks that ensure
these components are up to date.

Manually tracking updates for numerous components across multiple platforms is
error-prone and time-consuming. Different vendors release updates on varying
schedules and through different channels. Automation, as implemented for
microcode and DBX, addresses these challenges by ensuring consistency, reducing
the risk of oversight, and freeing up developer resources for other critical
tasks.

In this blog post we'll explore how GitHub actions can ensure that these
critical security components are always up-to-date, helping us deliver a secure
firmware solution for our users.

## The components

Here is an abridged version of the Dasharo boot diagram:

![Dasharo boot diagram with ucode and DBX](/img/dasharo_boot_diagram.png)

Both Intel Microcode binaries and the UEFI DBX file are publicly available, by
Intel and the UEFI forum respectively.

Intel Microcode updates are available at Intel's GitHub page:
[link](https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files).

From their readme:

> The Intel Processor Microcode Update (MCU) Package provides a mechanism to
> release updates for security advisories and functional issues, including
> errata.

The microcode is typically provided by coreboot in a Firmware Interface Table
(FIT). The FIT is a standardized structure within the firmware that allows the
processor to locate and apply these critical updates seamlessly before executing
any other firmware code. This means that the update is performed before coreboot
has even had a chance to start.

In addition, modern CPUs often depend on ucode updates to _function at all_.
Due to the amount of erratas, a processor may simply refuse to do anything if
a microcode update is not provided. This highlights that microcode is not just
for security patches but is often fundamental for basic CPU operation and
stability on modern complex processors.

The OS is also able to load microcode updates, but due to how late in the boot
process that is done, it might be too late to patch vulnerabilities that could
be exploited during the early boot phases, or to address errata that affect the
firmware's own initialization. Applying updates as early as possible in the boot
process, at the firmware level, provides the most comprehensive protection. Here
are some examples of vulnerabilities patched by microcode:

- [INTEL-SA-01139](https://www.intel.com/content/www/us/en/security-center/advisory/intel-sa-01139.html)
  - Insufficient input validation in UEFI modules, including XmlCli and
    CseVariableStorageSmm, may allow privilege escalation. Without this
    microcode update, an attacker with local access could potentially escalate
    privileges by exploiting flaws in UEFI module input validation.
- [INTEL-SA-01166](https://www.intel.com/content/www/us/en/security-center/advisory/intel-sa-01166.html)
  - Improper Finite State Machines in hardware logic may allow Denial of Service
- [INTEL-SA-01045](https://www.intel.com/content/www/us/en/security-center/advisory/intel-sa-01045.html)
  - Incorrect calculation in microcode keying mechanism may allow information
    disclosure via local access

UEFI DBX is available at UEFI Forum's website: [link](https://uefi.org/revocationlistfile).
The page describes what the DBX updates are:

> UEFI Revocation List files contain the, now-revoked, signatures of previously
> approved and signed firmware and software used in booting systems with UEFI
> Secure Boot enabled.

There is also a GitHub repository hosted by Microsoft, hosting the same files:
[link](https://github.com/microsoft/secureboot_objects). For convenience, we
will be using the Microsoft repository, as a git repo is easier to work with
than a HTML page.

Interestingly, while this file should be the same between Microsoft's GitHub
and UEFI Forum's website, it appears that they're actually different:

```bash
user@work:~/Downloads$ sha256sum DBXUpdate.bin dbxupdate_x64.bin
37c3d45caa6b061825612215c6dbd06aaacb6f0e426c00bb62b8aee6dd0128de  DBXUpdate.bin
2378fdfe035a8373529ce9acb013fc31b59d3a71d4f9bbbc590bfc8536f90787  dbxupdate_x64.bin
```

This is because the file was recently updated on the GitHub repo, but the UEFI
Forum website was not updated at the same time: [commit](https://github.com/microsoft/secureboot_objects/commit/ef78acc1b2257bb892655381f8272e6e32d31c3e).
This lag highlights the importance of\ choosing a reliable and promptly updated
source for critical security data, and why automation often benefits from
sources with programmatic access and version history, like Git repositories.

Here is a list of some of the vulnerabilities that have been mitigated in the
last few DBX updates:

- [CVE-2022-21894 BlackLotus](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2022-21894)
  - Persistent UEFI bootkit that could bypass Secure Boot
- [CVE-2024-23593 Lenovo System Recovery Bootloader Vulnerability](https://cve.mitre.org/cgi-bin/cvename.cgi?name=2024-23594)
  - A buffer overflow in Lenovo's recovery software could lead to Secure Boot
    bypass and arbitrary code execution
- [CVE-2023-28005 Trend Micro Disk Encryption Vulnerability](https://nvd.nist.gov/vuln/detail/CVE-2023-28005)
  - A vulnerability in Trend Micro's Full Disk Encryption software could lead
    secure boot bypass and arbitrary code execution

The BlackLotus bootkit, for instance, was particularly dangerous as it could
bypass Secure Boot and persist even after OS reinstallation, making its
revocation via DBX updates essential.

## The automation

Dasharo repositories are hosted on GitHub, which means we have access to GitHub
Actions. GH Actions provide a convenient way to write CI workflows in YAML.

GitHub Actions was chosen for its tight integration with our codebase hosting,
its declarative YAML syntax for defining workflows, and the wide range of
community-supported actions available, such as the one used for creating pull
requests.

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
to the main branch and create a pull request. Using a Git submodule for the
Intel microcode repository allows us to pin specific versions and track changes
transparently within our own version control. The automation checks if our
pinned commit diverges from the latest main branch of the upstream microcode
repository, signaling a need for an update.

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

For the DBX, we directly fetch the latest binary from the Microsoft
secureboot_objects repository. A checksum comparison is a straightforward and
effective method to detect changes in this single-file artifact. This approach
avoids the need to clone the entire repository if only the DBX file is of
interest for this specific check, though we do clone it in the workflow for
ease of access.

Once an automated pull request is generated, it undergoes the standard Dasharo
review and testing process. This typically involves developers reviewing the
changes, ensuring the updated components integrate correctly, and running tests
on relevant hardware platforms before the PR is merged into the dasharo branch.
This human oversight combined with automation ensures both timeliness and
stability.

That's pretty much it. These two GitHub workflows automate updates of both
microcode and the revocation database.

## Closing thoughts

Introducing these automatic checks makes our firmware not only more secure,
but also more transparent. This transparency extends beyond just seeing the
update status; it allows the community to understand our security posture,
audit our processes, and even adapt these methods for their own coreboot or
EDK2 based projects. As the repositories and their CI workflows are open,
each user can see for themselves when the microcode and DBX were last updated,
and build from the main branch themselves with a guarantee that these components
will be up to date each time.

In contrast to many proprietary firmware solutions where update contents and
schedules can be opaque, Dasharo's open approach, exemplified by these automated
CI checks and detailed SBoMs, aims to build a higher level of trust and empower
users with more knowledge about the software running on their hardware's deepest
levels. Dasharo release notes [contain detailed SBoM](https://docs.dasharo.com/variants/novacustom_v540tu/releases_heads/#v090-2025-03-20)
(Software Bill of Materials) sections describing exactly what microcode you're
getting:

![V540TU Heads v0.9.0 SBoM](/img/v540tu_sbom.png)

We hope the introduction of these checks will make our firmware safer and more
worthy of our users' trust.

For any questions or feedback, feel free to contact us at
<contact@3mdeb.com> or hop on our community channels:

- [Dasharo Matrix Space](https://matrix.to/#/#dasharo-general:matrix.org)
- join the [Dasharo Users Group](https://events.dasharo.com/event/5/dasharo-user-group-dug-10-and-dasharo-developers-vpub-0xf)

to join the discussion.

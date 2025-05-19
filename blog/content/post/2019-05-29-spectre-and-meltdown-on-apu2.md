---
title: Meltdown and Spectre on PC Engines apu2
abstract: As a continuation the Meltdown and Spectre blog post, this post
          present the vulnerability status and mitigation with microcode
          update on PC Engines apu2. Read the post and get to know the open
          source tools for vulnerability and mitigation checks, as well as
          exploiting proof of concepts.
cover: /covers/spectre_apu2.png
author: michal.zygowski
layout: post
published: true
date: 2019-05-29
archives: "2019"

tags:
    - meltdown-spectre
    - apu
    - PC Engines
    - coreboot
categories:
    - Firmware
    - Security

---

## Meltdown and Spectre

In the
[previous post](https://blog.3mdeb.com/2019/2019-03-14-meltdown-and-spectre-vulnerabilities/)
I have introduced the Meltdown and Spectre vulnerabilities of modern x86
processors and what threat do they pose to security and safety of the data. As a
continuation of the last post, I will demonstrate the state of Meltdown and
Spectre vulnerabilities on PC Engines apu2 platforms. Some time ago we have
added a microcode update feature to PC Engines firmware so I will show how
microcode update improves mitigation and present results using public tools,
proof of concepts known to exploit the vulnerability.

## State of Meltdown and Spectre on apu2

Let's take v4.9.0.1 firmware release as a reference for initial testing. In this
post I will use Debian stable release installed on mSATA SSD:

```bash
uname -a
Linux apu2 4.9.0-8-amd64 #1 SMP Debian 4.9.130-2 (2018-10-27) x86_64 GNU/Linux
```

Firstly let's check the state of the vulnerabilities on the system. I will use
the
[spectre meltdown checker](https://github.com/speed47/spectre-meltdown-checker)
and [Spectre PoC by Ryan Crosby](https://github.com/crozone/SpectrePoC) which
was proven to work on AMD GX-412TC SoC (apu2 platforms processor). For details
see [README Tweaking section.](https://github.com/crozone/SpectrePoC#tweaking)

## Spectre meltdown checker

Let's start with spectre meltdown checker:

```bash
git clone https://github.com/speed47/spectre-meltdown-checker.git
cd spectre-meltdown-checker
```

Or:

```bash
wget https://meltdown.ovh -O spectre-meltdown-checker.sh
```

> SHA256 of the script used:
> b0f884be51f0eb49ed61854f0e011a2f89f44c35699e07a705b0ec6f98fa29b5

Now load `msr` module, give execution permission to the script and run it:

```bash
chmod +x spectre-meltdown-checker.sh
sudo modprobe msr
sudo ./spectre-meltdown-checker.sh
```

The result is as follows

1. Hardware support for mitigation techniques:
  ![Hardware support (CPU microcode) for mitigation techniques](/img/spectre_hw.png)

1. Spectre variants mitigation checks:
  ![Spectre variants mitigation checks](/img/spectre_variants.png)

What is worth noticing here is that script reports that system is not vulnerable
due to mitigation presence, however:

```bash
* CPU microcode is the latest known available version:  NO  (latest version is 0x7030106 dated 2018/02/09 according to builtin MCExtractor DB v84 - 2018/09/27)

...

  * Vulnerable to CVE-2017-5753 (Spectre Variant 1, bounds check bypass):  YES
  * Vulnerable to CVE-2017-5715 (Spectre Variant 2, branch target injection):  YES

...

 * IBPB enabled and active:  NO

...

IBPB is considered as a good addition to retpoline for Variant 2 mitigation,
but your CPU microcode doesn't support it
```

One can see that mitigation can still be improved by microcode updates.

> One can check current microcode patch level in dmesg:
>
> ```bash
> microcode: CPU0: patch_level=0x07030105
> microcode: CPU1: patch_level=0x07030105
> microcode: CPU2: patch_level=0x07030105
> microcode: CPU3: patch_level=0x07030105
> ```bash
>
> Be sure to use recent kernels with implemented mitigation (dmesg output):
>
> ```bash
> Spectre V2 : Mitigation: Full AMD retpoline
> Spectre V2 : Spectre v2 / SpectreRSB mitigation: Filling RSB on context
> switch
> Speculative Store Bypass: Mitigation: Speculative Store Bypass disabled via
> prctl and seccomp
> ```

## Spectre PoC

In order to prove that the script wrongly reports that the platform is not
vulnerable, we will perform proof of concept with the usage of Spectre PoC:

```bash
git clone https://github.com/crozone/SpectrePoC.git
cd SpectrePoC
make
```

I have run the executable with two different parameters.

```bash
./spectre.out 20
Version: commit 856f80f2937f2bb812cab68d45c149272a1783d5
Using a cache hit threshold of 20.
Build: RDTSCP_SUPPORTED MFENCE_SUPPORTED CLFLUSH_SUPPORTED INTEL_MITIGATION_DISABLED LINUX_KERNEL_MITIGATION_DISABLED
Reading 40 bytes:
Reading at malicious_x = 0xffffffffffdfeeb8... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeeb9... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeeba... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeebb... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeebc... Success: 0xFF=’?’ score=0
...
Reading at malicious_x = 0xffffffffffdfeedb... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeedc... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeedd... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeede... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeedf... Success: 0xFF=’?’ score=0
```

> One can see that the secret string was not disclosed (0xFF=? everywhere).
> Let's increase the cache hit threshold.

```bash
./spectre.out 70
Version: commit 856f80f2937f2bb812cab68d45c149272a1783d5
Using a cache hit threshold of 70.
Build: RDTSCP_SUPPORTED MFENCE_SUPPORTED CLFLUSH_SUPPORTED INTEL_MITIGATION_DISABLED LINUX_KERNEL_MITIGATION_DISABLED
Reading 40 bytes:
Reading at malicious_x = 0xffffffffffdfeeb8... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeeb9... Success: 0x68=’h’ score=2
Reading at malicious_x = 0xffffffffffdfeeba... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeebb... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeebc... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeebd... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeebe... Success: 0x67=’g’ score=2
...
Reading at malicious_x = 0xffffffffffdfeed9... Success: 0x69=’i’ score=2
Reading at malicious_x = 0xffffffffffdfeeda... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeedb... Success: 0x72=’r’ score=2
Reading at malicious_x = 0xffffffffffdfeedc... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeedd... Success: 0x67=’g’ score=2
Reading at malicious_x = 0xffffffffffdfeede... Success: 0xFF=’?’ score=0
Reading at malicious_x = 0xffffffffffdfeedf... Success: 0xFF=’?’ score=0
```

One can see that positive results are obtained with a larger value of cache hit
threshold (with 70 some characters have not been obtained - score 0, 100 is
sufficient to get whole string - score 2 everywhere). It is related to CPU
performance.

> For those more interested in details of the attack, please refer to
> [Spectre Attacks](https://spectreattack.com/spectre.pdf) or to my
> [previous post](https://blog.3mdeb.com/2019/2019-03-14-meltdown-and-spectre-vulnerabilities/)
> introducing the Meltdown and Spectre.

Let's also check out the kernel mitigation. Rebuild the PoC with:

```bash
make clean
CFLAGS=-DLINUX_KERNEL_MITIGATION make
```

After trying to run the PoC with 20/70/100 the string is not disclosed. But what
if the kernel we use does not have the mitigation? The answer is firmware and
microcode for full hardware mitigation.

## Microcode update and spectre

To present results of Spectre vulnerability without kernel mitigation, we will
need the microcode update. For details how to build PC Engines apu2 coreboot
firmware with microcode update, please refer to this
[guide](https://github.com/pcengines/apu2-documentation/blob/master/docs/microcode_patching.md)

Building the firmware is pretty easy and the guide shows step by step solution
to obtain binary.

You may also watch how to build coreboot with microcode update for apu2:

[![asciicast](https://asciinema.org/a/222252.svg)](https://asciinema.org/a/222252?speed=10)

Flashing coreboot is possible with flashrom:

```bash
flashrom -p internal -w apu2_v4.9.0.1_microcode.rom
```

> Watch out! Flashing the SPI ROM carelessly may lead to hardware damage. Also
> be sure You have a recovery method available, for example
> [SPI1a](https://www.pcengines.ch/spi1a.htm) Be sure to do a full power cycle
> (with power supply detaching) after firmware update, simple reboot is not
> advised.

`dmesg` should now report new patch level:

```bash
microcode: CPU0: patch_level=0x07030106
microcode: CPU1: patch_level=0x07030106
microcode: CPU2: patch_level=0x07030106
microcode: CPU3: patch_level=0x07030106
```

## Spectre meltdown checker with microcode update

Let's run the spectre meltdown checker with updated microcode.

For convenience, I will paste only the differences between the result with and
without microcode:

Before microcode patching:

```bash
* PRED_CMD MSR is available:  NO
* CPU indicates IBPB capability:  NO
...
* IBPB enabled and active:  NO
```

After microcode patching:

```bash
* PRED_CMD MSR is available:  YES
* CPU indicates IBPB capability:  YES  (IBPB_SUPPORT feature bit)
...
* IBPB enabled and active:  YES
```

One may notice that the values regarding `Indirect Branch Prediction Barrier`
have been updated and platform gained slightly better protection.

## Spectre PoC with microcode update

Let's try now the Spectre PoC on Debian booted on firmware with microcode
update:

> Try various cache hit thresholds like before 20/70/100 and even more.
> Unfortunately, the secret is still revealed without kernel mitigation.

```bash
./spectre.out 100
Version: commit 856f80f2937f2bb812cab68d45c149272a1783d5
Using a cache hit threshold of 100.
Build: RDTSCP_SUPPORTED MFENCE_SUPPORTED CLFLUSH_SUPPORTED INTEL_MITIGATION_DISABLED LINUX_KERNEL_MITIGATION_DISABLED
Reading 40 bytes:
Reading at malicious_x = 0xffffffffffdfeeb8... Success: 0x54=’T’ score=2
Reading at malicious_x = 0xffffffffffdfeeb9... Success: 0x68=’h’ score=2
Reading at malicious_x = 0xffffffffffdfeeba... Success: 0x65=’e’ score=2
Reading at malicious_x = 0xffffffffffdfeebb... Success: 0x20=’ ’ score=2
Reading at malicious_x = 0xffffffffffdfeebc... Success: 0x4D=’M’ score=2
Reading at malicious_x = 0xffffffffffdfeebd... Success: 0x61=’a’ score=2
...
Reading at malicious_x = 0xffffffffffdfeedb... Success: 0x72=’r’ score=2
Reading at malicious_x = 0xffffffffffdfeedc... Success: 0x61=’a’ score=2
Reading at malicious_x = 0xffffffffffdfeedd... Success: 0x67=’g’ score=2
Reading at malicious_x = 0xffffffffffdfeede... Success: 0x65=’e’ score=2
Reading at malicious_x = 0xffffffffffdfeedf... Success: 0x2E=’.’ score=2
```

But let's check another[tool](https://github.com/opsxcq/exploit-cve-2017-5715)
aimed to exploit `CVE-2017-5715`. Following the README:

```bash
git clone https://github.com/opsxcq/exploit-cve-2017-5715
cd exploit-cve-2017-5715
taskset -c 1 ./exploit
```

> Change the `#define CACHE_HIT_THRESHOLD 80` to the value of 200 before
> compiling to be sure to trigger the vulnerability.

Result without microcode update:

```bash
[+] Testing for Spectre
[+] Dumping memory from 0xffffffffffdfeea8 to 0xffffffffffdfeec2
[+] Dumped bytes match the expected value
[+] System vulnerable to spectre
```

Result with updated microcode:

```bash
[+] Testing for Spectre
[+] Dumping memory from 0xffffffffffdfeea8 to 0xffffffffffdfeec2
[+] Dumped bytes match the expected value
[+] System vulnerable to spectre
```

The `exploit-cve-2017-5715` does not seem to use the kernel mitigation thus we
obtain the same result as with Spectre PoC without compiled mitigation.

## Summary

In the light of my experiments, it looks like microcode does not fully mitigate
the Meltdown and Spectre vulnerabilities. It seems to enable
`Indirect Branch Prediction Barrier` which is just a small part of the
vulnerability protection.

Most of the protection is achieved by using the kernel with proper mitigation.
Although some of the mitigation look to be inactive due to lack of hardware
support (`Indirect Branch Restricted Speculation`).

Used scripts and tools give only overall insight into the status of the Meltdown
and Spectre. They are not official tools proving system vulnerability, they were
designed to give information on present mitigation (spectre meltdown checker) or
to try exploiting the vulnerabilities based on an
[article](https://spectreattack.com/spectre.pdf).

It has to be noted that AMD and Intel processors are affected differently. AMD
processors are "marked" to not be vulnerable for some variants. AMD has even
released a [statement regarding the speculative
execution.](https://developer.amd.com/wp-content/resources/Managing-Speculation-on-AMD-Processors.pdf)

During experiments, different results have been obtained. It proves that only
combined mitigation in firmware/microcode and kernel give the best protection.
Although microcode update seems to not improve the situation in this particular
case.

I hope this post was useful for you. Please feel free to share your opinion and
if you think there is value, then share with friends.

If you think we can help in improving the security of your firmware or you
looking for someone who can boot your product by leveraging advanced features of
used hardware platform, feel free to [book a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up for our
newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

---
title: How TwPM is tested
abstract: 'This post shows how we tested simple commands on TwPM, which is our
          attempt at making TPM more open.'
cover: /covers/image-file.png
author: krystian.hebel
layout: post
published: true
date: 2023-08-21
archives: "2023"

tags:
  - TPM
  - TwPM
  - testing
categories:
  - Firmware
  - Security

---

TwPM project aims to increase the trustworthiness of the TPM module (hence the
TwPM), by providing the open-source firmware implementation for the TPM device,
compliant to the TCG PC Client Specification. Project aims to use already
available open-source software components whenever possible (such as TPM
simulators for TPM commands handling), while developing new code when necessary
(such as LPC FPGA module, or low-level TPM FIFO interface handling).

This project was funded through the [NGI Assure Fund](https://nlnet.nl/assure),
a fund established by [NLnet](https://nlnet.nl/) with financial support from the
European Commission's [Next Generation Internet](https://ngi.eu/) programme,
under the aegis of DG Communications Networks, Content and Technology under
grant agreement No 957073.

The project just entered a phase in which all basic components can communicate
with each other. This should be enough to test simplest commands that don't
require use of parts that aren't implemented yet. Nonvolatile storage, true
randomness source and primary keys' certificates manufacturing process are yet
to be implemented. As such, in current state TwPM cannot be used for all use
cases of TPM, but we're slowly getting there.

## SBOM

TDB: add links and revisions to code:
- TPM stack - Zephyr etc.
- top module
- TPM registers module
- LPC module

That said, we cheated a bit to get as much passes as possible. Some changes were
made to various components to make it slightly faster. In order for Linux to
detect TPM, it must return proper results to the commands executed both by OS
and firmware. Those commands work generally, but the results is returned after a
long time (e.g. `TPM2_SelfTest()` took about 40 minutes), so firmware times out
and marks TPM as not present. It is possible to tell Linux to do the detection
even if firmware says that TPM was not detected, but it would just fail for the
same reason.

Those changes are mostly temporary hacks made to test proper execution of
commands, including proper LPC communication which proved to be more difficult
than expected, more on that later in this post. For the final solution, we will
have to make the code work reasonably fast without having to disable mandatory
features. [This issue](https://github.com/Dasharo/TwPM_toplevel/issues/23)
briefly describes what modifications were made, as well as the problem with
enabling data cache. Slow access to data located on stack and heap seems to be
the bottleneck, we're hoping that working cache will improve execution speed
significantly.

## Connecting to the mainboard

For testing we used [Protectli VP4670](https://docs.dasharo.com/variants/protectli_vp46xx/overview/)
platform. It is a nice small PC that can easily fit on a developer's desk along
with all equipment necessary for flashing and testing. Most importantly, it has
LPC header specifically for the TPM, so neither hardware nor software mods on
the platform side had to be made.

[Orange Crab](https://github.com/orangecrab-fpga/orangecrab-hardware) can be
connected to the board by following the [mainboard connection
tutorial](https://twpm.dasharo.com/tutorials/mainboard-connection/). We didn't
connect `LRESET#` and `SERIRQ` signals. First of those would reset TwPM on each
platform reset - it is a requirement according to the TPM specification to
provide resistance to reset attacks, but since we don't store TPM stack in
nonvolatile memory yet, this wouldn't allow us to execute any commands early
after booting. The other signal, `SERIRQ`, is used to generate an interrupt for
host on one of the configured events. TPM is able to work without it (although
Linux kernel generates a warning), and it can generate enough electromagnetic
noise that other lines' signal quality may drop.

On the subject of noise, it is important to keep wires as short as possible.
`LCLK` and `LAD` next to each other is almost always bound to result in read
errors, so it is suggested to separate them with `GND`.

This is a photo of TwPM connected to the platform:

![TwPM connected to the platform](/img/twpm_connection.png)

Ideally, this should be enough for a working solution, but for deployment we
need to connect UART and USB to (preferably) another PC in order to flash FPGA
bitstream and TPM software.

## Compiling and flashing

Compiling and flashing process is described in [TwPM_toplevel repository](https://github.com/dasharo/TwPM_toplevel/#twpm_toplevel).
Follow those instructions till the very end. You will be asked to connect the
UART and USB to the programming PC. When doing so, it sometimes help to keep
UART ground signal disconnected - the same ground is applied through USB and
[ground loops](https://en.wikipedia.org/wiki/Ground_loop_(electricity)) are bad,
especially for interfaces like LPC that weren't designed with protection against
external interference in mind.

An example of development connection can be seen below. Notice that only two
wires are connected to UART converter. Also, remember that Orange Crab and LPC
work on 3.3V signals, the same voltage must be supported by the UART converter.

![Development connection](/img/twpm_connection_dev.png)

## Test suite

Tests that were run can be found in the [Dasharo OSFV repository](https://github.com/Dasharo/open-source-firmware-validation/blob/main/dasharo-security/tpm2-commands.robot).
The results of running a subset of those tests can be found [here](https://twpm.dasharo.com/test-results/2024_01_11_orange_crab_without_create_primary.html).

We've created a [page in TwPM documentation](https://twpm.dasharo.com/development/testing/)
for keeping tests and their results in one place. As of writing this, this post
and linked documentation is very similar, but with development of new phases the
documentation will be updated.

## Known issues and limitations

Some issues were mentioned already in [SBOM](#sbom) section, I won't repeat them
here.

As mentioned above, only a subset of created tests was run. The rest required
executing a long command (usually `TPM2_CreatePrimary()`). Due to slow execution
a timeout was detected by `tpm2-tools`. As we don't support cancellation of
commands (yet?), these commands were still being processed by TwPM, even though
next test from the suite wanted to start new commands. Those in turn failed,
even if they would pass if started as a single test. For this reason we decided
to skip problematic tests for now instead of dealing with false negatives for
unrelated tests. With that in mind, all tests that were skipped (5 out of 13)
should be treated as failures, even if that isn't presented in the log as such.

NV tests will also have to be modified in the future. Right now they just test
whether NV functions work, that is, if NV object can be defined, written and
read back. What they fail to check is whether created object is actually
nonvolatile, i.e. whether it is still available after power loss. With current
implementation, NV storage is emulated, it is stored in very much volatile DRAM.
Its content is lost after a few seconds without power.

## Summary

As you can see, TwPM gets closer and closer to being a usable TPM. There are
still some major obstacles to overcome, but test results run at this stage with
proof-of-concept quality implementation show some potential. Next phases will
focus on making it without need for flashing every time, as well as implementing
missing functionalities and improving performance.

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

---
title: Enabling ECC on PC Engines platforms
cover: /covers/ecc-vs-nonecc.png
author: krystian.hebel
layout: post
private: false
published: true
date: 2018-10-16
archives: "2018"

tags:
    - PC Engines
    - apu
categories:
    - Firmware

---

In this post I want to share some findings about ECC on PC Engines apu
platforms. I'll try to shortly describe what ECC is, why is it so desired, what
problems with enabling this feature were encountered and how to test whether ECC
works or not using MemTest86.

## Introduction

Sometimes a bit in RAM changes its value spontaneously due to electrical or
magnetic interference. It can be caused by background radiation, cosmic rays or
recently
[attacks](https://googleprojectzero.blogspot.com/2015/03/exploiting-dram-rowhammer-bug-to-gain.html)
using [row hammering](https://en.wikipedia.org/wiki/Row_hammer).
[Error-correcting code (ECC) memory](https://en.wikipedia.org/wiki/ECC_memory)
helps with mitigation of this problem by adding more data storage for storing
information that makes detection and correction of errors possible. Memory
controller scans whole ECC enabled memory, reading every piece of data, checking
(and correcting if necessary) for errors and writing data back to memory. This
process is called memory scrubbing. As ECC can correct only limited number of
flipped bits scrubbing has to be done periodically, before multiple errors
within one ECC word can occur - time between scrubs isn't fixed, and according
to
[BKDG, 52740 Rev 3.06](https://www.amd.com/system/files/TechDocs/52740_16h_Models_30h-3Fh_BKDG.pdf):

> There are many factors which influence scrub rates. Among these are:
>
> - The size of memory or cache to be scrubbed
> - Resistance to upsets
> - Geographic location and altitude
> - Alpha particle contribution of packaging
> - Performance sensitivity
> - Risk aversion

Usually, ECC can fix only single bit, and detect two changed bits in ECC word,
but with AMD Embedded G series GX-412TC SoC included in PC Engines apu2 platform
a variation named `x4 ECC` is used:

> The x4 code uses thirty-six 4-bit symbols to make a 144-bit ECC word made up
> of 128 data bits and 16 check bits. The x4 code is a single symbol correcting
> (SSC) and a double symbol detecting (DSD) code. This means the x4 code is able
> to correct 100% of single symbol errors (any bit error combination within one
> symbol), and detect 100% of double symbol errors (any bit error combination
> within two symbols).

ECC feature requires support from the memory controller (on SoC), memory banks,
connections between them on a motherboard (memory bus is wider to support
reading check bits at the same time as main data) and firmware which sets
everything up. Further operation is transparent to operating systems, but it is
possible for them to gather information about how often errors are being
corrected.

It is possible to turn off ECC check and error reporting for one range of
memory. This range is used as a framebuffer for integrated GPU - scrubbing could
have an impact on framerate and things like V-sync, and one changed pixel
visible only for a fraction of second is acceptable.

## Testing for ECC support

To be sure that ECC works one must notice a corrected ECC error. There are few
problems to this:

- ECC has to be available and properly configured
- ECC error reporting must be enabled
- there must be a correctable ECC error

First two points are something that can and has to be done in firmware as long
as a hardware is compatible, so enabling it takes some work and a whole lot of
research, but is definitely possible.

The last issue is actually the hardest one. It is impossible to reliably
simulate e.g. a cosmic ray, and row hammering takes a lot of time and requires
specific knowledge of the internal structure of a memory bank. To help with
testing vendors of memory controllers (and SoCs) provide ways of introducing an
error for test and debug purposes. This feature enables tools like
[MemTest86](https://www.memtest86.com/) to inject ECC errors when running tests
\- keep in mind that ECC injection is available only in paid versions of
MemTest86 run from UEFI (so coreboot built with tianocore payload was used for
testing in my research) and needs to be enabled either from the menu or in the
configuration file. The most important settings in this file are:

```bash
DISABLEMP=1     # support for multiprocessor in tianocore payload is buggy, disable
ECCPOLL=1       # poll for ECC errors after each test
ECCINJECT=1     # inject ECC errors before each test
```

Running this test on unmodified coreboot resulted in something like the
following lines in log file:

```bash
(...)
2018-09-25 14:01:31 - Finished searching PCI for SMBus Controller
2018-09-25 14:01:31 - Getting SMBIOS Memory Device info...
2018-09-25 14:01:31 - Found 0 Memory Devices
2018-09-25 14:01:31 - Getting memory controller info
2018-09-25 14:01:31 - find_mem_controller - found AMD Steppe Eagle (1022:1582) at 0-24-2
2018-09-25 14:01:31 - AMD 10h and greater chipset init
2018-09-25 14:01:31 - DRAM config low=83090000
2018-09-25 14:01:32 - MCA NB config=48700044
2018-09-25 14:01:32 - NbMcaLogEn is disabled. Enabling...
2018-09-25 14:01:32 - MC4_CTL=0000000000000000
2018-09-25 14:01:32 - MC4_CTL_MASK=0000000004000000
2018-09-25 14:01:32 - MCG_CTL low=00000000
2018-09-25 14:01:32 - find_mem_controller - AMD Steppe Eagle (1022:1582) at 0-24-2
2018-09-25 14:01:32 - find_mem_controller - AMD Steppe Eagle ECC mode: detect: yes, correct: yes, scrub: no, chipkill: no
2018-09-25 14:01:33 - ECC polling enabled
2018-09-25 14:01:33 - Found configuration file
2018-09-25 14:01:33 - [CONFIG] Tests Selected: 3 5 13
2018-09-25 14:01:33 - [CONFIG] Number of passes: 2
2018-09-25 14:01:33 - [CONFIG] Disable multiprocessor support: yes
2018-09-25 14:01:33 - [CONFIG] ECC polling: enabled
2018-09-25 14:01:33 - [CONFIG] ECC injection: enabled
2018-09-25 14:01:34 - [CONFIG] Auto mode: enabled
2018-09-25 14:01:34 - [CONFIG] Skip splash screen: true
2018-09-25 14:01:34 - [CONFIG] Console mode: 0
2018-09-25 14:01:34 - Applying configurations
2018-09-25 14:01:34 - [CONFIG] This platform has 1 logical processors of which 1 are enabled.
2018-09-25 14:01:34 - Console size = 80 x 25
2018-09-25 14:01:34 - Screen resolution is too low (800 x 600). Setting screen size to the minimum 1024 x 768
2018-09-25 14:01:35 - Unable to set screen size
2018-09-25 14:01:35 - Screen size = 800 x 600
2018-09-25 14:01:35 - Char width=8 height=19
2018-09-25 14:01:35 - Loading images
2018-09-25 14:01:35 - AMD 10h and greater chipset init
2018-09-25 14:01:35 - DRAM config low=83090000
2018-09-25 14:01:35 - MCA NB config=C8700044
2018-09-25 14:01:35 - MC4_CTL=0000000000000000
2018-09-25 14:01:35 - MC4_CTL_MASK=0000000004000000
2018-09-25 14:01:35 - MCG_CTL low=00000010
2018-09-25 14:01:35 - *** TEST SESSION - 2018-09-25 14:01:35 ***
2018-09-25 14:01:35 - CPU selection mode = 0
2018-09-25 14:01:35 - Starting pass #1 (of 2)
2018-09-25 14:01:35 - Running test #3 (Test 3 [Moving inversions, ones & zeroes])
2018-09-25 14:01:35 - MtSupportRunAllTests - Injecting ECC error
2018-09-25 14:01:35 - inject_amd64 - new nb_arr_add = 80000000
2018-09-25 14:01:35 - inject_amd64 - new dram_ecc = 0012000F
2018-09-25 14:01:35 - MCA NB Status High=00000000
2018-09-25 14:01:35 - inject_amd64 - new nb_arr_add = 80000002
2018-09-25 14:01:35 - inject_amd64 - new dram_ecc = 0012000F
2018-09-25 14:01:35 - MCA NB Status High=00000000
2018-09-25 14:01:35 - inject_amd64 - new nb_arr_add = 80000004
2018-09-25 14:01:36 - inject_amd64 - new dram_ecc = 0012000F
2018-09-25 14:01:36 - MCA NB Status High=00000000
2018-09-25 14:01:36 - MtSupportRunAllTests - Setting random seed to 0x50415353
2018-09-25 14:01:36 - MtSupportRunAllTests - Start time: 422 ms
2018-09-25 14:01:36 - ReadMemoryRanges - Available Pages = 1035072
2018-09-25 14:01:36 - MtSupportRunAllTests - Enabling memory cache for test
2018-09-25 14:01:36 - MtSupportRunAllTests - Enabling memory cache complete
2018-09-25 14:01:36 - Start memory range test (0x0 - 0x12F000000)
2018-09-25 14:01:36 - Pre-allocating memory ranges >=16MB first...
2018-09-25 14:01:36 - All memory ranges successfully locked
2018-09-25 14:02:54 - Cleanup - Releasing all memory ranges...
2018-09-25 14:02:54 - MtSupportRunAllTests - Test execution time: 78.372 (Test 3 cumulative error count: 0)
(...)
```

As you can see, MemTest86 injects ECC errors (or at least tries to) in lines
starting with `inject_amd64`, but these errors are not reported - according to
[MemTest86 troubleshooting page](https://www.memtest86.com/troubleshooting.htm#eccerrors)
a line with either memory address or the DRAM rank/bank/row/column should be
printed here, as well as in the generated report, as shown in
[this sample](https://www.memtest86.com/MemTest86-Report-Sample.html). This
means that something is wrong. There is a lot of relevant debug information
included, but names differ slightly between log and register names in BKDG. More
information about reported values and their impact on the issue will be revealed
in the next sections.

## Issues with ECC enabling

According to previous work on this issue, ECC error injection fails due to a
range of memory that is used by APUs integrated graphics being excluded from ECC
support, which means that it is impossible to test in a reliable way whether ECC
works. This feature is controlled by a couple of registers, one of them is
D18F5x240, which has bit EccExclEn (see page 496 of
[BKDG](https://www.amd.com/system/files/TechDocs/52740_16h_Models_30h-3Fh_BKDG.pdf)).
This bit is set by [AGESA](https://en.wikipedia.org/wiki/AGESA) as 1 soon after
memory training and excluded range is incorrectly set as a whole memory for
systems without integrated graphics.

As AGESA is included as a binary blob it can't be fixed in its code and some
workarounds were needed.

## Potential workarounds

[AGESA specification](https://support.amd.com/TechDocs/44065_Arch2008.pdf)
mentions a build time option:

> BLDCFG_UMA_ALLOCATION_MODE Supply the UMA memory allocation mode build time
> customization, if any. The default mode is Auto.
>
> - UMA_NONE — no UMA memory will be allocated.
> - UMA_SPECIFIED — up to the requested UMA memory will be allocated.
> - UMA_AUTO — allocate the optimum UMA memory size for the platform.
>
> For APUs with integrated graphics, this will provide the optimum UMA
> allocation for the platform and for other platforms will be the same as NONE

There is also a runtime option `UmaMode` in `MemConfig`, which is a parameter
for `AmdInitPost`, but it isn't clear if AGESA uses data received from host or
changes it along the way before memory initialization. However, the initial
value of `UmaMode` already is `UMA_NONE`, and neither changing it before calling
`AmdInitPost` nor in any callout functions doesn't change the outcome.

Clearing bit EccExclEn in register D18F5x240 from coreboot after it gets set by
AGESA seemed to work on a tested platform (apu2). Description of this register
in
[BKDG](https://www.amd.com/system/files/TechDocs/52740_16h_Models_30h-3Fh_BKDG.pdf)
informs that

> BIOS must quiesce all other forms of DRAM traffic when configuring this range.
> See MSRC001_001F\[DisDramScrub\].

Although it did work without disabling scrubbing (perhaps because of all memory
was excluded from ECC anyway) we followed the process described in BKDG just to
be safe.

## Additional required fixes

Somewhere between memory training and setting UMA I receive
`WARNING Event: 04012200 Data: 0, 0, 0, 0`. According to AGESA specification
`04012200` corresponds to:

> MEM_WARNING_BANK_INTERLEAVING_NOT_ENABLED

I don't know if this is connected in any way to problems with ECC enabling.

Later test on different platforms gave some additional findings. Implemented fix
did work on apu2 and apu4, but not on apu3 or apu5. Luckily MemTest86 leaves
enough data to find out what's wrong, it was only a question of interpreting log
files. First, part of log from apu4 where this fix worked:

```bash
(...)
2018-09-31 01:01:01 - Running test #3 (Test 3 [Moving inversions, ones & zeroes])
2018-09-31 01:01:01 - MtSupportRunAllTests - Injecting ECC error
2018-09-31 01:01:01 - inject_amd64 - new nb_arr_add = 80000000
2018-09-31 01:01:01 - inject_amd64 - new dram_ecc = 0012000F
2018-09-31 01:01:01 - MCA NB Status High=00000000
2018-09-31 01:01:02 - inject_amd64 - new nb_arr_add = 80000002
2018-09-31 01:01:02 - inject_amd64 - new dram_ecc = 0012000F
-> 2018-09-31 01:01:02 - MCA NB Status High=846FC000
2018-09-31 01:01:02 - inject_amd64 - new nb_arr_add = 80000004
2018-09-31 01:01:02 - inject_amd64 - new dram_ecc = 0012000F
-> 2018-09-31 01:01:02 - MCA NB Status High=846FC000
2018-09-31 01:01:02 - MtSupportRunAllTests - Setting random seed to 0x50415353
2018-09-31 01:01:02 - MtSupportRunAllTests - Start time: 406 ms
2018-09-31 01:01:02 - ReadMemoryRanges - Available Pages = 1035011
2018-09-31 01:01:02 - MtSupportRunAllTests - Enabling memory cache for test
2018-09-31 01:01:02 - MtSupportRunAllTests - Enabling memory cache complete
2018-09-31 01:01:02 - Start memory range test (0x0 - 0x12F000000)
2018-09-31 01:01:02 - Pre-allocating memory ranges >=16MB first...
2018-09-31 01:01:02 - All memory ranges successfully locked
-> 2018-09-31 01:01:02 - MCA NB Status=846FC000F2080A13
-> 2018-09-31 01:01:02 - MCA NB Address=00000000CFE528E0
-> 2018-09-31 01:01:02 - [MEM ERROR - ECC] Test: 3, Address: CFE528E0, ECC Corrected: yes, Syndrome: F2DF, Channel/Slot: N/A
2018-09-31 01:02:27 - Cleanup - Releasing all memory ranges...
2018-09-31 01:02:27 - MtSupportRunAllTests - Test execution time: 84.838 (Test 3 cumulative error count: 0)
(...)
```

Lines marked with `->` are the ones that differ from the previous log.
`MCA NB Status High` corresponds to `D18F3x4C MCA NB Status High` in BKDG, which
is an alias of `MSR0000_0411 MC4 Machine Check Status`. You can find more info
about this register there, but basically, when the most significant bit (Val) is
set, a valid error has been detected, so we're good. The bottom lines report
status (full 64 bits this time, again, refer to BKDG for full description) and
address of injected error, as well as a more human-friendly error message, that
would also be visible on screen and in the generated report. Note that reported
error count is still 0, as this error was detected and corrected by hardware
before any read operation (by MemTest86, OS or any other application) on this
address was performed.

This is output from apu5, where forementioned fix didn't work, with important
lines marked with `->`:

```bash
(...)
2018-09-31 01:02:46 - Running test #3 (Test 3 [Moving inversions, ones & zeroes])
2018-09-31 01:02:46 - MtSupportRunAllTests - Injecting ECC error
-> 2018-09-31 01:02:46 - inject_amd64 - new nb_arr_add = 8C000000
2018-09-31 01:02:46 - inject_amd64 - new dram_ecc = 0012000F
-> 2018-09-31 01:02:46 - MCA NB Status High=00000000
-> 2018-09-31 01:02:46 - inject_amd64 - new nb_arr_add = 8C000002
2018-09-31 01:02:46 - inject_amd64 - new dram_ecc = 0012000F
-> 2018-09-31 01:02:46 - MCA NB Status High=00000000
-> 2018-09-31 01:02:46 - inject_amd64 - new nb_arr_add = 8C000004
2018-09-31 01:02:46 - inject_amd64 - new dram_ecc = 0012000F
-> 2018-09-31 01:02:46 - MCA NB Status High=00000000
2018-09-31 01:02:46 - MtSupportRunAllTests - Setting random seed to 0x50415353
2018-09-31 01:02:46 - MtSupportRunAllTests - Start time: 455 ms
2018-09-31 01:02:46 - ReadMemoryRanges - Available Pages = 1035000
2018-09-31 01:02:46 - MtSupportRunAllTests - Enabling memory cache for test
2018-09-31 01:02:46 - MtSupportRunAllTests - Enabling memory cache complete
2018-09-31 01:02:46 - Start memory range test (0x0 - 0x12F000000)
2018-09-31 01:02:46 - Pre-allocating memory ranges >=16MB first...
2018-09-31 01:02:46 - All memory ranges successfully locked
2018-09-31 01:04:05 - Cleanup - Releasing all memory ranges...
2018-09-31 01:04:05 - MtSupportRunAllTests - Test execution time: 78.773 (Test 3 cumulative error count: 0)
(...)
```

As you can see, none of injection attempts succeeded so reported value of
`MCA NB Status High` was `00000000`. Also value of `nb_arr_add` (aka
`D18F3xB8 NB Array Address` in BKDG) differs, so next logical step was clearing
this register's value in coreboot as well. After doing so ECC errors were
reported:

```bash
(...)
2018-10-01 01:01:16 - Running test #3 (Test 3 [Moving inversions, ones & zeroes])
2018-10-01 01:01:16 - MtSupportRunAllTests - Injecting ECC error
2018-10-01 01:01:16 - inject_amd64 - new nb_arr_add = 80000000
2018-10-01 01:01:16 - inject_amd64 - new dram_ecc = 0012000F
2018-10-01 01:01:16 - MCA NB Status High=00000000
2018-10-01 01:01:16 - inject_amd64 - new nb_arr_add = 80000002
2018-10-01 01:01:16 - inject_amd64 - new dram_ecc = 0012000F
2018-10-01 01:01:16 - MCA NB Status High=00000000
2018-10-01 01:01:16 - inject_amd64 - new nb_arr_add = 80000004
2018-10-01 01:01:16 - inject_amd64 - new dram_ecc = 0012000F
2018-10-01 01:01:16 - MCA NB Status High=846FC000
2018-10-01 01:01:16 - MtSupportRunAllTests - Setting random seed to 0x50415353
2018-10-01 01:01:16 - MtSupportRunAllTests - Start time: 515 ms
2018-10-01 01:01:16 - ReadMemoryRanges - Available Pages = 1035000
2018-10-01 01:01:16 - MtSupportRunAllTests - Enabling memory cache for test
2018-10-01 01:01:16 - MtSupportRunAllTests - Enabling memory cache complete
2018-10-01 01:01:16 - Start memory range test (0x0 - 0x12F000000)
2018-10-01 01:01:16 - Pre-allocating memory ranges >=16MB first...
2018-10-01 01:01:16 - All memory ranges successfully locked
2018-10-01 01:01:17 - MCA NB Status=846FC000F2080813
2018-10-01 01:01:17 - MCA NB Address=00000000CFE528D0
2018-10-01 01:01:17 - [MEM ERROR - ECC] Test: 3, Address: CFE528D0, ECC Corrected: yes, Syndrome: F2DF, Channel/Slot: N/A
2018-10-01 01:02:21 - MCA NB Status=846FC000F2080813
2018-10-01 01:02:21 - MCA NB Address=00000000CE320540
2018-10-01 01:02:21 - [MEM ERROR - ECC] Test: 3, Address: CE320540, ECC Corrected: yes, Syndrome: F2DF, Channel/Slot: N/A
2018-10-01 01:02:36 - Cleanup - Releasing all memory ranges...
2018-10-01 01:02:36 - MtSupportRunAllTests - Test execution time: 80.088 (Test 3 cumulative error count: 0)
(...)
```

## Summary and additional findings

After the last fix, ECC is enabled as well as ECC error injection on all
supported hardware (that is, every apu platform with 4 GB of memory). Generated
reports should look like this:

![Report showing corrected ECC errors](/img/memtest_ecc.png)

Every corrected ECC error has the same syndrome - F2DF. It is caused by
MemTest86 setting D18F3xBC_x8 (DRAM ECC) to `0012000F`. More info about the
meaning of these is available in
[BKDG](https://www.amd.com/system/files/TechDocs/52740_16h_Models_30h-3Fh_BKDG.pdf)
on pages 172-174 (ECC syndromes) and 456 (DRAM ECC register, NB Array Address).

Another thing is that sometimes more than one ECC error for a test is injected.
It is caused by internal work of injection - only bits inside a cache line can
be chosen, but an error is injected on next non-cached operation at accessed
address, which can change or not between any of three attempts to inject an
error.

Changes in code can be found
[here](https://github.com/pcengines/coreboot/pull/207/files), we're also
planning to push it upstream soon. We would also think about adding an option to
disable ECC injection if the community decides that it is needed, as even
[some of the MemTest86 developers](https://www.passmark.com/forum/memtest86/5984-how-do-you-verify-ecc-error-injection-working?p=32922#post32922)
believe that injection should be enabled for debug purposes only.

---
title: How to enable Core Performance Boost on AMD platforms?
author: michal.zygowski
layout: post
published: true
date: 2019-02-14 12:00:00

tags:
    - PC Engines
    - apu2
    - boost
    - performance
    - coreboot
categories:
    - Firmware

---

# Pushing hardware to its limits

In the epoch of efficient and fast processors, performance becomes one of the
most crucial aspects when choosing and working with hardware. We want our
computers to execute their tasks with possibly highest speeds. But what really
influences the performance of our platforms? It's the processor's manufacturer
design one may say. In this post, I will show You how firmware may boost Your
silicon to higher performance level. On the example of PC Engines apu2c4
platform, I will present Core Performance Boost feature.

## Core Performance Boost

![BOOST](https://3mdeb.com/wp-content/uploads/2017/07/boost_gauge.jpg)

Core Performance Boost (CPB) is a feature that allows increasing the frequency
of the processor's core exceeding its nominal values. Similarly to Intel's
Turbo Boost Technology, AMD Core Performance Boost temporarily raises the
frequency of a single core when the operating system requests the highest
processor performance.

Enabling the CPB feature is relatively easy since coreboot uses proprietary
initialization code from AMD for the apu2 processor called AGESA, which have
support for CPB initialization.

In order to enable CPB feature one must add following lines to OEM Customize
in `src/mainboard/pcengines/apu2/OemCustomize.c`:

```
VOID
OemCustomizeInitEarly (
    IN  OUT AMD_EARLY_PARAMS    *InitEarly
    )
{
    InitEarly->GnbConfig.PcieComplexList = &PcieComplex;
+    InitEarly->PlatformConfig.CStateMode = CStateModeC6;
+    InitEarly->PlatformConfig.CpbMode = CpbModeAuto;
}
```

These values will be passed to AGESA, which will handle initialization of the
CPB feature.

## Performance tests

How to prove the performance gain without tests and benchmarks? First of all,
I have performed a few tests using memtest86+ in BIOS and Linux OS utilities
like stress/stress-ng, dd etc. Furthermore, I have launched one benchmark in
order to show how performance increased by enabling the CPB feature.

All test have been performed on Debian Linux installed on mSATA SSD:

```
Linux apu2 4.9.0-8-amd64 #1 SMP Debian 4.9.130-2 (2018-10-27) x86_64 GNU/Linux
```

### CPB disabled

First, let's try reference v4.9.0.1 firmware without CPB:

```
$ stress -c 1 &
$ watch -n 1  cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq

600000
600000
1000000
600000

$ stress-ng --cpu 1 --cpu-method matrixprod --timeout 30 --metrics

stress-ng: info:  [493] stressor       bogo ops real time  usr time  sys time   bogo ops/s   bogo ops/s
stress-ng: info:  [493]                           (secs)    (secs)    (secs)   (real time) (usr+sys time)
stress-ng: info:  [493] cpu                 580     30.02     29.99      0.00        19.32        19.34
```

One can see that the frequency during the stress test is limited to 1000MHz and
total bogo ops are equal 580 for single core.

Another test may be a raw memory dd:

```
dd if=/dev/zero of=/dev/null bs=64k count=1M
68719476736 bytes (69 GB, 64 GiB) copied, 30.2523 s, 2.3 GB/s
```

#### Memtest86+

Memtest86+:

```
Memtest86+ 5.01 coreboot 002| AMD GX-412TC SOC
CLK: 998.2MHz  (X64 Mode)   | Pass  1%
L1 Cache:   32K  14058 MB/s | Test 66% #########################
L2 Cache: 2048K   5015 MB/s | Test #3  [Moving inversions, 1s & 0s Parallel]
L3 Cache:  None             | Testing: 2048M - 3327M   1279M of 4078M
Memory  : 4078M   1434 MB/s | Pattern:   00000000           | Time:   0:00:43
----------------------------------------------------------------------
Core#: 0 (SMP: Disabled)  |  CPU Temp  | RAM: 666 MHz (DDR3-1333) - BCLK: 100
State: - Running...       |    56 C    | Timings: CAS 9-9-10-24 @ 64-bit Mode
Cores:  1 Active /  1 Total (Run: All) | Pass:       0        Errors:      0
------------------------------------------------------------------------------
...
                                PC Engines apu2
(ESC)exit  (c)configuration  (SP)scroll_lock  (CR)scroll_unlock
```

Notice the cache and memory speeds:

```
L1 Cache:   32K  14058 MB/s
L2 Cache: 2048K   5015 MB/s
Memory  : 4078M   1434 MB/s
```

#### UnixBench benchmark

I have also selected the [UnixBench](https://github.com/kdlucas/byte-unixbench)
to test the processor performance.

How to run:

```
# it may be necessary to install few packages
apt-get install libx11-dev libgl1-mesa-dev libxext-dev perl perl-modules make git
git clone https://github.com/kdlucas/byte-unixbench.git
cd byte-unixbench/UnixBench/
./Run
```

> Running the benchmark takes a while. Be patient.

Results:

```
========================================================================
   BYTE UNIX Benchmarks (Version 5.1.3)

   System: apu2: GNU/Linux
   OS: GNU/Linux -- 4.9.0-8-amd64 -- #1 SMP Debian 4.9.130-2 (2018-10-27)
   Machine: x86_64 (unknown)
   Language: en_US.utf8 (charmap="UTF-8", collate="UTF-8")
   CPU 0: AMD GX-412TC SOC (1996.8 bogomips)
          Hyper-Threading, x86-64, MMX, AMD MMX, Physical Address Ext, SYSENTER/SYSEXIT, AMD virtualization, SYSCALL/SYSRET
   CPU 1: AMD GX-412TC SOC (1996.8 bogomips)
          Hyper-Threading, x86-64, MMX, AMD MMX, Physical Address Ext, SYSENTER/SYSEXIT, AMD virtualization, SYSCALL/SYSRET
   CPU 2: AMD GX-412TC SOC (1996.8 bogomips)
          Hyper-Threading, x86-64, MMX, AMD MMX, Physical Address Ext, SYSENTER/SYSEXIT, AMD virtualization, SYSCALL/SYSRET
   CPU 3: AMD GX-412TC SOC (1996.8 bogomips)
          Hyper-Threading, x86-64, MMX, AMD MMX, Physical Address Ext, SYSENTER/SYSEXIT, AMD virtualization, SYSCALL/SYSRET
   16:11:24 up 2 min,  1 user,  load average: 0.05, 0.07, 0.02; runlevel 2019-01-21

------------------------------------------------------------------------
Benchmark Run: Sat Jan 19 2019 16:11:24 - 16:39:27
4 CPUs in system; running 1 parallel copy of tests

Dhrystone 2 using register variables        5792755.2 lps   (10.0 s, 7 samples)
Double-Precision Whetstone                     1007.6 MWIPS (10.1 s, 7 samples)
Execl Throughput                                746.9 lps   (30.0 s, 2 samples)
File Copy 1024 bufsize 2000 maxblocks        117729.6 KBps  (30.0 s, 2 samples)
File Copy 256 bufsize 500 maxblocks           33167.2 KBps  (30.0 s, 2 samples)
File Copy 4096 bufsize 8000 maxblocks        296813.6 KBps  (30.0 s, 2 samples)
Pipe Throughput                              335334.9 lps   (10.0 s, 7 samples)
Pipe-based Context Switching                  16882.6 lps   (10.0 s, 7 samples)
Process Creation                               1652.4 lps   (30.0 s, 2 samples)
Shell Scripts (1 concurrent)                   1823.6 lpm   (60.0 s, 2 samples)
Shell Scripts (8 concurrent)                    604.5 lpm   (60.0 s, 2 samples)
System Call Overhead                         432478.6 lps   (10.0 s, 7 samples)

System Benchmarks Index Values               BASELINE       RESULT    INDEX
Dhrystone 2 using register variables         116700.0    5792755.2    496.4
Double-Precision Whetstone                       55.0       1007.6    183.2
Execl Throughput                                 43.0        746.9    173.7
File Copy 1024 bufsize 2000 maxblocks          3960.0     117729.6    297.3
File Copy 256 bufsize 500 maxblocks            1655.0      33167.2    200.4
File Copy 4096 bufsize 8000 maxblocks          5800.0     296813.6    511.7
Pipe Throughput                               12440.0     335334.9    269.6
Pipe-based Context Switching                   4000.0      16882.6     42.2
Process Creation                                126.0       1652.4    131.1
Shell Scripts (1 concurrent)                     42.4       1823.6    430.1
Shell Scripts (8 concurrent)                      6.0        604.5   1007.6
System Call Overhead                          15000.0     432478.6    288.3
                                                                   ========
System Benchmarks Index Score                                         258.7

------------------------------------------------------------------------
Benchmark Run: Sat Jan 19 2019 16:39:27 - 17:07:34
4 CPUs in system; running 4 parallel copies of tests

Dhrystone 2 using register variables       21225450.9 lps   (10.0 s, 7 samples)
Double-Precision Whetstone                     3641.0 MWIPS (10.0 s, 7 samples)
Execl Throughput                               3435.4 lps   (29.9 s, 2 samples)
File Copy 1024 bufsize 2000 maxblocks        148725.9 KBps  (30.0 s, 2 samples)
File Copy 256 bufsize 500 maxblocks           38379.1 KBps  (30.0 s, 2 samples)
File Copy 4096 bufsize 8000 maxblocks        412590.3 KBps  (30.0 s, 2 samples)
Pipe Throughput                             1204545.3 lps   (10.0 s, 7 samples)
Pipe-based Context Switching                 103110.0 lps   (10.0 s, 7 samples)
Process Creation                               7676.4 lps   (30.0 s, 2 samples)
Shell Scripts (1 concurrent)                   5091.8 lpm   (60.0 s, 2 samples)
Shell Scripts (8 concurrent)                    643.2 lpm   (60.2 s, 2 samples)
System Call Overhead                        1469507.7 lps   (10.0 s, 7 samples)

System Benchmarks Index Values               BASELINE       RESULT    INDEX
Dhrystone 2 using register variables         116700.0   21225450.9   1818.8
Double-Precision Whetstone                       55.0       3641.0    662.0
Execl Throughput                                 43.0       3435.4    798.9
File Copy 1024 bufsize 2000 maxblocks          3960.0     148725.9    375.6
File Copy 256 bufsize 500 maxblocks            1655.0      38379.1    231.9
File Copy 4096 bufsize 8000 maxblocks          5800.0     412590.3    711.4
Pipe Throughput                               12440.0    1204545.3    968.3
Pipe-based Context Switching                   4000.0     103110.0    257.8
Process Creation                                126.0       7676.4    609.2
Shell Scripts (1 concurrent)                     42.4       5091.8   1200.9
Shell Scripts (8 concurrent)                      6.0        643.2   1072.0
System Call Overhead                          15000.0    1469507.7    979.7
                                                                   ========
System Benchmarks Index Score                                         688.9
```

> Pay attention to System Benchmarks Index Scores

### CPB enabled

Let's now try the firmware with CPB enabled:

```
$ stress -c 1 &
$ watch -n 1  cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq

600000
600000
1000000
600000
```

The frequency reported by sysfs, unfortunately, did not change. Let's try
stress-ng:

```
$ stress-ng --cpu 1 --cpu-method matrixprod --timeout 30 --metrics

stress-ng: info:  [526] stressor       bogo ops real time  usr time  sys time   bogo ops/s   bogo ops/s
stress-ng: info:  [526]                           (secs)    (secs)    (secs)   (real time) (usr+sys time)
stress-ng: info:  [526] cpu                 591     30.03     30.00      0.00        19.68        19.70
```

Stress-ng launched on 1 core reported 591 bogo ops, which is 2% more than
without CPB (was 580 bogo ops). Not a difference at all.

Raw memory dd:

```
dd if=/dev/zero of=/dev/null bs=64k count=1M
68719476736 bytes (69 GB, 64 GiB) copied, 23.5088 s, 2.9 GB/s
```

We can see that the speed increased from ~2.5Gb/s to ~3.0Gb/s (~20% increase).
Compared to the results without CPB enabled, these actually prove that the
feature works, because when the boost is on, the core frequency should
increase, along with performance.

#### Memtest86+

Launching memtest86+ in BIOS:

```
Memtest86+ 5.01 coreboot 002| AMD GX-412TC SOC
CLK: 998.2MHz  (X64 Mode)   | Pass  0%
L1 Cache:   32K  21699 MB/s | Test 38% ##############
L2 Cache: 2048K   6980 MB/s | Test #3  [Moving inversions, 1s & 0s Parallel]
L3 Cache:  None             | Testing: 1024K - 2048M   2047M of 4078M
Memory  : 4078M   1992 MB/s | Pattern:   ffffffff           | Time:   0:00:19
------------------------------------------------------------------------------
Core#: 0 (SMP: Disabled)  |  CPU Temp  | RAM: 666 MHz (DDR3-1333) - BCLK: 100
State: - Running...       |    52 C    | Timings: CAS 9-9-10-24 @ 64-bit Mode
Cores:  1 Active /  1 Total (Run: All) | Pass:       0        Errors:      0
------------------------------------------------------------------------------
...
                                PC Engines apu2
(ESC)exit  (c)configuration  (SP)scroll_lock  (CR)scroll_unlock
```

Notice how the memory and cache speeds changed:

```
L1 Cache:   32K  14058 MB/s  --->   L1 Cache:   32K  21699 MB/s  (~54% change)
L2 Cache: 2048K   5015 MB/s  --->   L2 Cache: 2048K   6980 MB/s  (~39% change)
Memory  : 4078M   1434 MB/s  --->   Memory  : 4078M   1992 MB/s  (~39% change)
```

The lowest performance gain from CPB is 40%, which is quite significant.

#### UnixBench benchmark

Running the benchamrk with boost enabled:

```
========================================================================
   BYTE UNIX Benchmarks (Version 5.1.3)

   System: apu2: GNU/Linux
   OS: GNU/Linux -- 4.9.0-8-amd64 -- #1 SMP Debian 4.9.130-2 (2018-10-27)
   Machine: x86_64 (unknown)
   Language: en_US.utf8 (charmap="UTF-8", collate="UTF-8")
   CPU 0: AMD GX-412TC SOC (1996.1 bogomips)
          Hyper-Threading, x86-64, MMX, AMD MMX, Physical Address Ext, SYSENTER/SYSEXIT, AMD virtualization, SYSCALL/SYSRET
   CPU 1: AMD GX-412TC SOC (1996.1 bogomips)
          Hyper-Threading, x86-64, MMX, AMD MMX, Physical Address Ext, SYSENTER/SYSEXIT, AMD virtualization, SYSCALL/SYSRET
   CPU 2: AMD GX-412TC SOC (1996.1 bogomips)
          Hyper-Threading, x86-64, MMX, AMD MMX, Physical Address Ext, SYSENTER/SYSEXIT, AMD virtualization, SYSCALL/SYSRET
   CPU 3: AMD GX-412TC SOC (1996.1 bogomips)
          Hyper-Threading, x86-64, MMX, AMD MMX, Physical Address Ext, SYSENTER/SYSEXIT, AMD virtualization, SYSCALL/SYSRET
   15:03:32 up 1 min,  1 user,  load average: 0.32, 0.10, 0.03; runlevel 2019-01-21

------------------------------------------------------------------------
Benchmark Run: Sat Jan 19 2019 15:03:32 - 15:31:32
4 CPUs in system; running 1 parallel copy of tests

Dhrystone 2 using register variables        7074813.7 lps   (10.0 s, 7 samples)
Double-Precision Whetstone                     1278.1 MWIPS (10.0 s, 7 samples)
Execl Throughput                                846.3 lps   (30.0 s, 2 samples)
File Copy 1024 bufsize 2000 maxblocks        151426.3 KBps  (30.0 s, 2 samples)
File Copy 256 bufsize 500 maxblocks           42870.3 KBps  (30.0 s, 2 samples)
File Copy 4096 bufsize 8000 maxblocks        384498.1 KBps  (30.0 s, 2 samples)
Pipe Throughput                              430439.7 lps   (10.0 s, 7 samples)
Pipe-based Context Switching                  19094.7 lps   (10.0 s, 7 samples)
Process Creation                               1869.1 lps   (30.0 s, 2 samples)
Shell Scripts (1 concurrent)                   1934.0 lpm   (60.0 s, 2 samples)
Shell Scripts (8 concurrent)                    612.1 lpm   (60.1 s, 2 samples)
System Call Overhead                         572974.4 lps   (10.0 s, 7 samples)

System Benchmarks Index Values               BASELINE       RESULT    INDEX
Dhrystone 2 using register variables         116700.0    7074813.7    606.2
Double-Precision Whetstone                       55.0       1278.1    232.4
Execl Throughput                                 43.0        846.3    196.8
File Copy 1024 bufsize 2000 maxblocks          3960.0     151426.3    382.4
File Copy 256 bufsize 500 maxblocks            1655.0      42870.3    259.0
File Copy 4096 bufsize 8000 maxblocks          5800.0     384498.1    662.9
Pipe Throughput                               12440.0     430439.7    346.0
Pipe-based Context Switching                   4000.0      19094.7     47.7
Process Creation                                126.0       1869.1    148.3
Shell Scripts (1 concurrent)                     42.4       1934.0    456.1
Shell Scripts (8 concurrent)                      6.0        612.1   1020.2
System Call Overhead                          15000.0     572974.4    382.0
                                                                   ========
System Benchmarks Index Score                                         310.2

------------------------------------------------------------------------
Benchmark Run: Sat Jan 19 2019 15:31:32 - 15:59:38
4 CPUs in system; running 4 parallel copies of tests

Dhrystone 2 using register variables       21308677.1 lps   (10.0 s, 7 samples)
Double-Precision Whetstone                     3647.7 MWIPS (10.0 s, 7 samples)
Execl Throughput                               3445.1 lps   (30.0 s, 2 samples)
File Copy 1024 bufsize 2000 maxblocks        144800.2 KBps  (30.0 s, 2 samples)
File Copy 256 bufsize 500 maxblocks           40507.7 KBps  (30.0 s, 2 samples)
File Copy 4096 bufsize 8000 maxblocks        399019.8 KBps  (30.0 s, 2 samples)
Pipe Throughput                             1203354.7 lps   (10.0 s, 7 samples)
Pipe-based Context Switching                 103772.6 lps   (10.0 s, 7 samples)
Process Creation                               7718.8 lps   (30.0 s, 2 samples)
Shell Scripts (1 concurrent)                   5093.9 lpm   (60.0 s, 2 samples)
Shell Scripts (8 concurrent)                    644.0 lpm   (60.2 s, 2 samples)
System Call Overhead                        1471125.8 lps   (10.0 s, 7 samples)

System Benchmarks Index Values               BASELINE       RESULT    INDEX
Dhrystone 2 using register variables         116700.0   21308677.1   1825.9
Double-Precision Whetstone                       55.0       3647.7    663.2
Execl Throughput                                 43.0       3445.1    801.2
File Copy 1024 bufsize 2000 maxblocks          3960.0     144800.2    365.7
File Copy 256 bufsize 500 maxblocks            1655.0      40507.7    244.8
File Copy 4096 bufsize 8000 maxblocks          5800.0     399019.8    688.0
Pipe Throughput                               12440.0    1203354.7    967.3
Pipe-based Context Switching                   4000.0     103772.6    259.4
Process Creation                                126.0       7718.8    612.6
Shell Scripts (1 concurrent)                     42.4       5093.9   1201.4
Shell Scripts (8 concurrent)                      6.0        644.0   1073.4
System Call Overhead                          15000.0    1471125.8    980.8
                                                                   ========
System Benchmarks Index Score                                         689.8
```

We clearly see that the overall score has increased:

* for 1 parallel copy of tests score increased from 258.7 to 310.2 (20% change)
* for 4 parallel copy of tests score increased from 688.9 to 689.8 (~0% change)

# Summary

Enabling the CPB feature resulted in the performance increase and my
experiments show, that it is true. Although some methods did not report any
change, it is still software which may not report it correctly. `stress` and
`stress-ng` seems not to be the right tools to measure the performance.

Another reason of wrong reports is that the core performance states (P-states)
in boosted mode are not described in ACPI (Advanced Configuration and Power
Interface) system (and they shouldn't be as AMD BIOS and Kernel Developer Guide
states). As a result operating system does not know about the fact of
processor's transition to the state with higher, boosted performance.

CPB feature increases frequency only of one single core if the rest of the
cores is not stressed. The overall boost result is 20%, which implies the
frequency increase from 1000MHz to 1200MHz. However, the processor
specification states, that the frequency should be 1400MHz. A similar result
has been achieved with memtest86+ (approximately 40% memory speed gain). The
benchamrk result is also biased by the background operations that OS must do
besides the tests.

The feature will be introduced in v4.9.0.2 firmware release for PC Engines.

I hope this post was useful for you. Please try it out yourselves and feel free
to share your results.

If you think we can help in improving the performance of your platform or you
looking for someone who can boot your product by leveraging advanced features
of used hardware platform, feel free to [boot a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. Are You interested in similar
content? Feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

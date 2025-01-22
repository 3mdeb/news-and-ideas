---
title: Research of RAM data remanence times, part 2
abstract: "Continuing from where we left off, we've run the same tests on
          different hardware, both platforms and memory modules. This blog post
          skips all the theory and description of how the measurements were
          obtained, please read the previous one if you're interested in these
          details."
cover: /covers/DRAM_Cell.png
author: krystian.hebel
layout: post
published: true
date: 2025-01-21
archives: "2025"

tags:
  - testing
categories:
  - Miscellaneous

---

This is a continuation of research of RAM data remanence times.
[Previous post](https://blog.3mdeb.com/2024/2024-12-13-ram-data-decay-research/)
has the description of goal, methodology and implementation of tool used for
this research, as well as some DRAM theory. It is a strongly suggested reading,
it should help with understanding the results and the way in which they were
presented.

## Updates to the testing app

Previous tests showed some inefficiencies of the [RAM data remanence
tester](https://github.com/Dasharo/ram-remanence-tester), caused in big part
because of sheer amount of results produced. The only metadata that was saved
used to be the (UTC) time encoded in filename, which was just enough to not
overwrite old results on consecutive runs, and all other information about
hardware, test parameters and environment had to be manually noted elsewhere.

[First of the changes](https://github.com/Dasharo/ram-remanence-tester/pull/3)
added automatic detection of platform name and, after the test finished, asked
the user to input temperature and time without the power. There is very little
validation of user input, but other than creating another column to saved CSV,
there is nothing more that can be done by wrong input. This was deemed to be
acceptable for our use case.

[Second improvement](https://github.com/Dasharo/ram-remanence-tester/pull/5)
added automatic detection of installed DIMM. In theory, it should store all the
information needed to store unique DIMM part number and slot it was installed
in, but it requires SMBIOS data to be properly filled. This exposed
[few](https://github.com/Dasharo/dasharo-issues/issues/1205)
[Dasharo](https://github.com/Dasharo/dasharo-issues/issues/1206)
[issues](https://github.com/Dasharo/dasharo-issues/issues/741#issuecomment-2603136021)
that would have to be fixed, otherwise data on affected platforms is incomplete.
Until then, part number of `None` has to be manually updated in few CSV files.

[Last but not least](https://github.com/Dasharo/ram-remanence-tester/pull/4),
CSV files are parsed and plots are generated from it with Python script, instead
of manually. This saves **a lot** of time, especially when some part of the
diagram has to be modified after a number of plots was already generated. It
also has an option to export PNG versions, something that used to be done
manually.

## Changes to methodology

With rough idea about what to expect, we slightly modified (or rather specified
more precisely) the methodology. As we've seen two very different results, we
have to somehow decide on time increase between iterations, and when to stop.

Average percentage of bits that changed their value on first iteration (when
power was reapplied as soon as possible) is used to decide whether next
iterations will be performed with 1 or 10 seconds increase. As a threshold we
are using 25% - everything equal or lower will cause 10s increases, and values
above that we will use 1s increments.

As a cutoff point, we're using 49.5%. Results are asymptotically getting closer
to 50% with increasing time, but at slower rate with each iteration. Note than
for many modules this value was obtained on the first measurement (~0s) already,
and no further testing was done in such cases.

We haven't changed the way measurements were obtained. We still don't control
the temperature, so the same thermometer was used as before for consistency. As
for time measurements, the previous result showed either ranges in order of
minutes, for which any timer is good enough, or below one second, at which point
we can't switch the power with enough precision anyway.

## Tested hardware

We've added two new platforms, and extended the list of tested modules to 3 per
platform. For each combination, platform was powered off in two ways: by
physically cutting the power of running platform, and by gracefully shutting
down the platform using UEFI services.

For MSI platforms, `physical` power off method means flipping the switch on PSU.
In case of laptops, the battery was disconnected to allow for cutting the power
by removing the power cord, instead of keeping the power button pressed for few
seconds. Cable was removed from the laptop, to avoid impact from any leftover
electricity stored in the cables and power supply. It was also easier to
disconnect than wall plug. This made the time measurements a bit more precise,
although given the results, it probably wasn't precise enough anyway.

<!-- FIXME after https://github.com/3mdeb/news-and-ideas/issues/625 -->

<style>
.content table {
  margin: auto;
  width: fit-content;
}
.content table tr td:first-child {
  vertical-align: middle;
}
</style>

| Platform | RAM modules                                                                          | Power off method                            |
|:--------:|:------------------------------------------------------------------------------------:|:-------------------------------------------:|
| NV41PZ   | <ul><li>78.B2GFR.4000B</li><li>78.D2GG7.4010B</li><li>TMKS4G56ALFBZH-2133P</li></ul> | <ul><li>physical</li><li>graceful</li></ul> |
| V540TND  | <ul><li>W-NM56S508G</li><li>W-NM56S516G</li><li>M425R1GB4BB0-CWMOD</li></ul>         | <ul><li>physical</li><li>graceful</li></ul> |
| MSI DDR4 | <ul><li>KF432C16BB/4</li><li>KF432C16BB/8</li><li>F4-2400C15S-4GNT</li></ul>         | <ul><li>physical</li><li>graceful</li></ul> |
| MSI DDR5 | <ul><li>CT8G48C40U6</li><li>CT16G48C40U5</li><li>PSD58G480041</li></ul>              | <ul><li>physical</li><li>graceful</li></ul> |

This gives 24 combinations in total, 2 of which were tested in the previous
phase. 2 modules from the same vendor, but with different sizes, and one from
another vendor with the same size as the smaller one (to save a bit of testing
time) were used for each platform.

## Results

Below are raw results from the research. If you're just interested in comparison
between models and power off methods, feel free to skip to [the final section
of results](#comparisons). For all of the tests, humidity oscillated between 33
and 35%.

### NV41PZ

Both Apacer modules behaved similarly, losing most of the data after about
5 seconds if the platform was gracefully shut down. In case of disconnecting the
power, even after reconnecting it immediately, the memory contents were gone on
larger one, but maintained for 2 seconds on 4 GB module.

TBD: charts

Tigo TMKS4G56ALFBZH-2133P module shows full and immediate loss of data,
regardless of method of powering off the platform.

TBD: charts

### V540TND

W-NM56S508G was tested previously, this time only graceful shutdown was tested.
It held a significant amount of data when powered on immediately, but after 1s
it was already gone. W-NM56S516G, a bigger variant from the same manufacturer,
preserved memory for a while longer, but not by much.

TBD: charts

Samsung M425R1GB4BB0-CWMOD module shows full and immediate loss of data,
regardless of method of powering off the platform.

TBD: charts

### MSI DDR4

4 GB Kingston Fury KF432C16BB/4 module behaved similarly after graceful shutdown
as it did for immediate power cut, holding some data for up to 2 minutes.

TDB: charts

Despite the same vendor, 8 GB Kingston Fury lost all of its data almost
immediately. In case of immediate start after a graceful shutdown, 49.49% of
bits were changed, which is just below threshold assumed by us as a total loss.
G.Skill F4-2400C15S-4GNT module shows full and immediate loss of data,
regardless of method of powering off the platform.

TBD: charts

### MSI DDR5

TBD

### Comparisons

TBD
- MSI DDR4 S vs AC
- NV41PZ 4G vs 16G

## Conclusions

So far, only one of tested modules was capable of holding the data for more than
a few seconds, by a huge margin. Interestingly, a bigger module from the same
family was not capable of doing the same.

DDR4 on laptops seems to retain data for longer time than DDR5, however, it may
be impacted by other factors. For example, DIMM slots are located closer to the
CPU in DDR5 laptop. It also has a dedicated graphics card, which is another
source of heat.

Grouping into slices of 8 bits is clearly visible across all tested cases,
except for those that show full data loss immediately after power off. In case
of DDR5 in laptops, it can be seen that upper and lower 32 bits are mirrored.

There is a visible, consistent disproportion of `1to0` and `0to1` changes,
especially on bits 31-36. It doesn't depend on module nor platform. There are
few possible explanations:

- Poor LFSR implementation. Some bit patterns may be more common than others.
- Patterns seeded from a physical address of a page. This causes lower 12 bits
  to be always the same.
- Similar memory address space layout on all x86 platforms. Addresses just below
  4 GB are reserved for MMIO, there are also some smaller holes below 1 MB for
  legacy devices.
- Similar pattern of firmware memory allocations. All of the tested platforms
  were running coreboot with edk2 payload. This combination allocates memory
  from the top of available memory in lower 4 GB, which may further expand a
  hole reserved for MMIO.

## Summary

TBD

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

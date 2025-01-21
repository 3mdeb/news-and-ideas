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
| NV41PZ   | <ul><li>TMKS4G56ALFBZH-2133P</li><li>78.B2GFR.4000B</li><li>78.D2GG7.4010B</li></ul> | <ul><li>physical</li><li>graceful</li></ul> |
| V540TND  | <ul><li>M425R1GB4BB0-CWMOD</li><li>W-NM56S516G</li><li>W-NM56S508G</li></ul>         | <ul><li>physical</li><li>graceful</li></ul> |
| MSI DDR4 | <ul><li>KF432C16BB/8</li><li>KF432C16BB/4</li><li>F4-2400C15S-4GNT</li></ul>         | <ul><li>physical</li><li>graceful</li></ul> |
| MSI DDR5 | <ul><li>CT8G48C40U6</li><li>CT16G48C40U5</li><li>PSD58G480041</li></ul>              | <ul><li>physical</li><li>graceful</li></ul> |

This gives 24 combinations in total, 2 of which were tested in the previous
phase.

## Results

TBD

## Conclusions

TBD

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

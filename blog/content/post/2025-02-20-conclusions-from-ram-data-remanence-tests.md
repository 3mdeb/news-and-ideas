---
title: Conclusions from RAM data remanence tests
abstract: 'A practical summary from the two previous blog posts presenting results of RAM data remanence tests.'
cover: /covers/image-file.png
author:
  - maciej.pijanowski
  - krystian.hebel
layout: post
published: true
date: 2025-02-20
archives: "2025"
cover: /covers/DRAM_Cell.png

tags:
  - testing
categories:
  - Firmware
  - Miscellaneous

---

This is a summary of research of RAM data remanence times. [First post](
https://beta.blog.3mdeb.com/2024/2024-12-13-ram-data-decay-research/) has
the description of goal, methodology and implementation of tool used for this
research, as well as some DRAM theory. [Second part](
https://beta.blog.3mdeb.com/2025/2025-01-24-ram-data-decay-research-part2/
) presented revision of
testing application and methodology, testing results, and finally an impact on
readability of the data persisting.

## General recommendation

General recommendation regarding leaving your device (with DDR4/DDR5 non-ECC
RAM) unattended after shutdown, considering the risks of cold boot attack:

- once device was shutdown, and left indoors at a room temperature, it's
  unlikely that any useful data can be extracted after < 10s for most memory
  modules,
  - for some specific memory modules this time may be higher; we have came
    across one specific module in which case it would be recommended to wait
    2 minutes until the data decays to a sufficient extent,
  - therefore the recommendation would be to wait 2 minutes until leaving
  device unattended, unless you have done prior testing of your specific setup
  using e.g. [this test app](https://github.com/Dasharo/ram-remanence-tester).

## Graceful vs forced shutdown

For practical application, there is no significant difference in RAM decay rate
between graceful (`shutdown` system command) or forced (cutting off the power)
shutdown.

## Impact of the notebook battery

Once notebook is shutdown (either via `shutdown` command, or via power button),
the presence of battery **does not** mean that the data in RAM is still being
refreshed. It can be only refreshed when notebook is powered on, or in suspend
(`S3`), not in shutdown state.

Recommendation: whether the battery is present in the notebook, or not, it does
not negatively impact user concerned of the cold boot attack. There is no
significant difference in RAM decay rate here for a practical application.

## DDR4 vs DDR5 (non-ECC)

For practical application, there is no significant difference in RAM decay rate
between DDR4 and DDR5 modules.

## ECC memory

Reading from uninitialized ECC memory would cause errors to be detected by the
controller, which in turn would stop the machine execution. To avoid it, whole
memory is written with a predefined pattern, usually consisting of all zeros,
[during firmware initialization](https://github.com/Dasharo/coreboot/blob/raptor-cs_talos-2/rel_v0.7.0/src/soc/ibm/power9/istep_14_1.c#L459).

Because of that, testing on ECC memory doesn't provide usable results (only
`1to0` transitions, always in roughly 50% of total memory), as seen in this
graph obtained for Supermicro X11SSH:

![Testing on ECC memory](/img/ram_remanence_plots/with_ecc.png)

## Memory clearing

For certain use-cases,
[memory clearing](https://doc.coreboot.org/security/memory_clearing.html)
feature can be implemented in boot firmware. It makes the initial boot longer,
and must be implemented on the machine where the modules would be placed for
data extraction.

Therefore, it might prevent these types of attacks, where memory modules are
not swapped to another machine.

## Summary

This research has been supported by [Power Up Privacy](https://powerupprivacy.com/)
, a privacy advocacy group
that seeks to supercharge privacy projects with resources so they can complete
their mission of making our world a better place.

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to sign up for our newsletter:

{{< subscribe_form "3160b3cf-f539-43cf-9be7-46d481358202" "Subscribe" >}}

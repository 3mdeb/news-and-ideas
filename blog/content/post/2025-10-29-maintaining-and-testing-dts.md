---
title: 'Dasharo Tools Suite: the story about scalability and stability'
abstract: 'Nowadays every software technology is subject to entropy that causes
a cutting-edge technology to become legacy code faster and faster. The
architecture initially developed for scalability becomes harder and harder to
maintain. The initially added functionalities become outdated and unstable. In
such rough times, it is important to develop a correct strategy for developing
and maintaining your software. This blog post covers Dasharo Tools Suite
automation and testing technologies designed to fight problems, costs, and
bureaucracy in its development process.'
cover: /covers/maintaining-and-testing-dts.png
author: daniil.klimuk
layout: post
published: true    # if ready or needs local-preview, change to: true
date: 2025-10-29    # update also in the filename!
archives: "2025"

tags:               # check: https://blog.3mdeb.com/tags/
  - DTS
  - Dasharo
  - firmware
  - monolith
  - architecture
categories:         # choose 1 or multiple from the list below
  - Firmware
  - Miscellaneous
  - OS Dev
  - App Dev

---

## What is Dasharo Tools Suite?

![DTS main menu screen](/img/maintaining-and-testing-dts-imgs/dts-main-menu-screen.png)

Dasharo Tools Suite (i.e. DTS) was initially designed for two purposes:

* Support end-users while deploying Dasharo firmware.
* Support Dasharo firmware developers during firmware development.

Hence, DTS is an important part of [Dasharo Universe][dasharo-universe-url] and
to achieve these goals it provides, among others, the following functionalities:

* Dasharo Zero Touch Initial Deployment (i.e. DZTID), that is, a list of
  automated workflows:
  * Initial deployment for Dasharo firmware.
  * Update for Dasharo firmware.
  * Transition for Dasharo firmware.
* Dasharo Hardware Compatibility List Report (i.e. Dasharo HCL or DTS HCL; you
  can find more about it [here][dasharo-hcl-docs]).
* Fusing workflow for some Dasharo firmware (for more information about
  fusing check [Dasharo documentation][fusing-docs].
* Firmware recovery workflow.

And this list is constantly growing bigger.

DTS is Linux destribution built upon Yocto Project tecnologies with
[`Dasharo/meta-dts`][meta-dts-url] as a core layer, and
[`Dasharo/dts-scripts`][dts-scripts-url] as a core software repository. Apart
from this DTS uses [other layers][kas-common-url] and a [separate
repository][dts-configs] for metadata. The DTS documentation is a part of
[docs.dasharo.com][dts-docs].

[dasharo-universe-url]: https://www.dasharo.com/
[meta-dts-url]: https://github.com/dasharo/meta-dts
[dts-scripts-url]: https://github.com/dasharo/dts-scripts
[kas-common-url]: https://github.com/Dasharo/meta-dts/blob/develop/kas/common.yml
[dts-configs]: https://github.com/dasharo/dts-configs
[dts-docs]: https://docs.dasharo.com/dasharo-tools-suite/overview/
[fusing-docs]: https://docs.dasharo.com/glossary/#dasharo-trustroot
[dasharo-hcl-docs]: https://docs.dasharo.com/glossary/#dasharo-hardware-compatibility-list-report

## The challenges

<!-- The challenges, the solutions ideas, motivation, etc.. -->

## Testing

### Testing infrastructure and testing theory

<!-- What to test? How to test? In which way to test? -->

### Mocking and QEMU

<!-- DTS mocking infrastructure explanation -->

### Test cases

<!-- OSFV and test cases generation -->

### Adding news tests

<!-- Example in text or a demo -->

### Automation

<!-- OSFV and test cases generation yet again? -->

### Results

#### Example deevlopment flow

<!-- Some demos testing upcoming/latest changes using the E2E tests. --->

#### Publishing results

<!-- TODO -->

## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help. [Schedule
a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to sign up for our newsletter:

{{< subscribe_form "UUID" "Subscribe to 3mdeb Newsletter" >}}

> (TODO AUTHOR) Depending on the target audience, update `UUID` and button text
> from the section above to one of the following lists:
>
> * 3mdeb Newsletter: `3160b3cf-f539-43cf-9be7-46d481358202`
> * Dasharo External Newsletter: `dbbf5ff3-976f-478e-beaf-749a280358ea`
> * Zarhus External Newsletter: `69962d05-47bb-4fff-a0c2-7355b876fd08`

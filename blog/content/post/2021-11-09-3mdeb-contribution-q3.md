---
title: 3mdeb contribution 2021'Q3
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: daria.zakrzewska
layout: post
published: true
date: 2021-11-09
archives: "2021"

tags:
  - contribution
  - patches
  - coreboot
  - opensource
categories:
  - Miscellaneous

---
## Intro 

We are back with a post about corporate contributions, now focusing on the third
quarter of 2021. It is usually said that work during summer is more difficult
because of the beautiful weather outside, which does not allow you to focus on
tasks. With us, however, it is possible to combine everything that is important,
without neglecting the sense of the obligation to contributing in open source
communities. The third quarter was active and we are so glad to take part in
such important projects. What exactly? We invite you to read below, where you
will find all the details! 

But let’s start with a small riddle! 

If you change, add, multiple some numbers in `2021’Q3` what will you get?
 
## 2180 

YES! all added lines in all project! Remember, not the quantity but
quality is what we care about!

1. Trenchboot Landing Zone

Open source implementation of Secure Loader for AMD Secure Startup.

Author | Category | Patch | URL
Krystian Hebel | ?iommu | initial implementation| (LINK)[https://github.com/TrenchBoot/landing-zone/pull/63]
Krystian Hebel | Build | Event log | (LINK)[https://github.com/TrenchBoot/landing-zone/pull/65]
Krystian Hebel | Security | fix order of outb() arguments | (LINK)[https://github.com/TrenchBoot/landing-zone/pull/66]
Krystian Hebel | README | Adding Multiboot2 support | (LINK)[https://github.com/TrenchBoot/landing-zone/pull/64]
Krystian Hebel | Main | Headers Redesign | (LINK)[https://github.com/TrenchBoot/landing-zone/pull/68]
Krystian Hebel | ??? | Xen support | (LINK)[https://github.com/TrenchBoot/landing-zone/pull/60]

1. Freebsd 

FreeBSD is an operating system used to power modern servers, desktops, and
embedded platforms. A large community has continually developed it for more than
thirty years. Its advanced networking, security, and storage features have made
FreeBSD the platform of choice for many of the busiest web sites and most
pervasive embedded networking and storage devices.

Author | Category | Patch | URL
Pavel Balaev | ?iommu | Add efitable(8), a userspace tool to fetch and parse EFI tables | (LINK)[https://reviews.freebsd.org/R10:24f398e7a153a05a7e94ae8dd623e2b6d28d94eb]
Pavel Balaev | Build | EFI RT: resurrect EFIIOC_GET_TABLE | (LINK)[https://reviews.freebsd.org/R10:d12d651f8692cfcaf6fd0a6e8264c29547f644c9]

1. Fwupd 

This project aims to make updating firmware on Linux automatic, safe and
reliable.

Author | Category | Patch | URL
Norbert Kamiński | ?iommu | FreeBSD CI fix | (LINK)[https://github.com/fwupd/fwupd/pull/3650]

1. Flashrom

Flashrom is a utility for detecting, reading, writing, verifying and erasing
flash chips. It is often used to flash BIOS/EFI/coreboot/firmware images
in-system using a supported mainboard, but it also supports flashing of network
cards (NICs), SATA controller cards, and other external devices which can
program flash chips.

Author | Category | Patch | URL
Michał Żygowski | ?iommu | Add missing Comet Point in usage | (LINK)[https://review.coreboot.org/c/flashrom/+/55993]

1. Gubes-app-linux-split-gpg2

Author | Category | Patch | URL
Piotr Król | ?iommu | fix typos, white space and clarify some sections | (LINK)[https://github.com/HW42/qubes-app-linux-split-gpg2/commit/a5e2dd2757557f6bc11e350d92d70134733be44d]

1. Coreboot

Author | Category | Patch | URL
Krystian Hebel | ?iommu | define use of big endian | (LINK)[https://review.coreboot.org/c/coreboot/+/55037]



Your post content

> any special characters (e.q. hashtags) in the post title and abstract should be
  wrapped in the apostrophes

> avoid using quotation marks in the title, because search-engine will broke

> post abstract in the header is required for the posts summary in the blog list
  and must contain from 3 to 5 sentences, please note that abstract would be used
  for social media and because of that should be focused on keywords/hashtags

> post cover image should be located in `blog/static/covers/` directory or may be
  linked to `blog/static/img/` if image is used in post content

> author meta-field MUST be strictly formatted (lowercase, non-polish letters):

```
author: artur.raglis
```

> if post has multiple authors, author meta-field MUST be strictly formatted:

```
author:
    - name.surname
    - name.surname
```

> remove unused categories

> remember about newlines before lists, tables, quotes blocks (>) and blocks of
  text (\`\`\`)

> copy all post images to `blog/static/img` directory. Example usage:

![alt-text](/img/file-name.jpg)

> example usage of asciinema videos:

[![asciicast](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO.svg)](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO?speed=1)

> embed responsive YouTube player (copy the address after `v=`):

{{< youtube UQ-6rUPhBQQ >}}

> embed vimeo player (extract the `ID` from the video’s URL):

{{< vimeo 146022717 >}}

> embed Instagram post (you only need the photo’s `ID`):

{{< instagram BWNjjyYFxVx >}}

> embed Twitter post (you need the `URL` of the tweet):

{{< tweet 1247072310324080640 >}}

> or centered (temporary hack):

<div style="display:table;margin:auto">{{< tweet 1247072310324080640 >}}</div>

## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

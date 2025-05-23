---
title: 'Template post title'
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: name.surname
layout: post
published: false
date: YYYY-MM-DD
archives: "YYYY"

tags:
  - tag 1
  - tag 2
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

Your post content

> any special characters (e.q. hashtags) in the post title and abstract should
> be wrapped in the apostrophes
> avoid using quotation marks in the title, because search-engine will broke
> post abstract in the header is required for the posts summary in the blog list
> and must contain from 3 to 5 sentences, please note that abstract would be
> used for social media and because of that should be focused on
> keywords/hashtags
> post cover image should be located in `blog/static/covers/` directory or may
> be linked to `blog/static/img/` if image is used in post content
> author meta-field MUST be strictly formatted (lowercase, non-polish letters):

```bash
author: name.surname
```

> if post has multiple authors, author meta-field MUST be strictly formatted:

```bash
author:
    - name.surname
    - name.surname
```

> remove unused categories
> remember about newlines before lists, tables, quotes blocks (>) and blocks of
> text (\`\`\`)
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

{{< tweet user="3mdeb_com" id="1247072310324080640" >}}

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
firmware security and optimization, be sure to [sign up for our
newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html). Don't let your
hardware hold you back, work with 3mdeb to achieve more!

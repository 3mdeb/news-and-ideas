---
title: 'Template post title'
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: name.surname
layout: post
published: false    # if ready or needs local-preview, change to: true
date: YYYY-MM-DD    # update also in the filename!
archives: "YYYY"

tags:               # check: https://blog.3mdeb.com/tags/
  - tag 1
  - tag 2
categories:         # choose 1 or multiple from the list below
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

Your post content

> 1. Any special characters (e.q. hashtags) in the post title and abstract
> should be wrapped in the apostrophes
> 2. Avoid using quotation marks in the title, because search-engine will broke
> 3. Post abstract in the header is required for the posts summary in the blog
> list and must contain from 3 to 5 sentences, please note that abstract would
> be used for social media and because of that should be focused on
> keywords/hashtags
> 4. Post cover image should be located in `blog/static/covers/` directory or
> may be linked to `blog/static/img/` if image is used in post content. Example
> usage:
>
>     ```md
>     ![alt-text](/img/file-name.jpg)
>     ```
>
> 5. Author meta-field MUST be strictly formatted (lowercase, non-polish
>    letters):
>
>    ```yml
>    author: name.surname
>    ```
>
> 6. If post has multiple authors, author meta-field MUST be strictly formatted:
>
>    ```yml
>    author:
>        - name.surname
>        - name.surname
>    ```
>
> 7. Remember about newlines before lists, tables, quotes blocks (>) and blocks
> of text (\`\`\`)
> 8. Example usage of asciinema videos:
> [![asciicast](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO.svg)](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO?speed=1)
> 9. Embed responsive YouTube player (copy the address after `v=`):
>
>    ```md
>    {{< youtube UQ-6rUPhBQQ >}}
>    ```
>
> 10. Embed vimeo player (extract the `ID` from the video’s URL):
>
>     ```md
>     {{< vimeo 146022717 >}}
>     ```
>
> 11. Embed Twitter post (you need the `URL` of the tweet):
>
>     ```md
>     {{< tweet user="3mdeb_com" id="1247072310324080640" >}}
>     ```
>
> 12. Embed Listmonk newsletter subscription form (you can split to multiline to
> comply with 80-line pre-commit rule):
>
>     ```md
>     {{< subscribe_form
>         "TARGET_LIST_UUID"
>         "TEXT TO BE RENDERED AS BUTTON TEXT"
>     >}}
>     ```
>
> 13. Use HTML details:
>
>     ```md
>     <details><summary> Some summary </summary>
>
>     some details...
>
>     ```bash
>     sudo dmesg
>     ```
>
>     </details>
>     ```

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

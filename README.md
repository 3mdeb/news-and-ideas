# 3mdeb blog documentation

## Table of contents

<!-- toc -->

- [Deployment status](#deployment-status)
- [Good practices](#good-practices)
  * [Grammarly](#grammarly)
  * [`post.md` file](#postmd-file)
  * [Post template](#post-template)
  * [Available categories](#available-categories)
    + [Tags](#tags)
  * [Markdown](#markdown)
  * [SEO best known methods](#seo-best-known-methods)
  * [Images optimization - WordPress](#images-optimization---wordpress)
    + [Images optimization step-by-step](#images-optimization-step-by-step)
- [Publishig post](#publishig-post)
  * [Local preview](#local-preview)
  * [Deployment on `beta` blog](#deployment-on-beta-blog)
  * [Deployment on `production` blog](#deployment-on-production-blog)

<!-- tocstop -->

## Deployment status

Production deploy status:

[![Build Status](https://travis-ci.com/3mdeb/news-and-ideas.svg?branch=master)](https://travis-ci.com/3mdeb/news-and-ideas)

Beta deploy status:

[![Build Status](https://travis-ci.com/3mdeb/news-and-ideas.svg?branch=develop)](https://travis-ci.com/3mdeb/news-and-ideas)

## Good practices

### Grammarly

Grammarly is a great, free tool for all bloggers and anyone who needs to write
documentation in English.
It will let you know if you skipped a coma or made a typo, as well, as it will
check advanced grammar mistakes, too. Bear in mind, that the free version has
its limits, so you need to keep an eye on it at all times and still, you are
the one who distinguishes when to use a/an or the, as it only suggests changes.

Two versions of Grammarly are available: a plugin for Chrome/Chromium or online
application. You need to create an account (it's for free) to be able to use
Grammarly.

Visit the website [Grammarly](https://app.grammarly.com/) and create an account.

>It is a MUST-HAVE application for anyone who writes posts or documentation, so
feel obliged to use it.

---

### `post.md` file

We used to name our files containing articles `post.md` because they used to
adjust their names with the use of a Wordpress Sync plugin. However, this
plugin is not up-to-date and we have switched to Hugo static pages generator.
Thus, we no more place it in the general folder, but instead, we place it in the
`blog/content/post` folder.

The proper name of the file should looks like that:

`2018-04-19-readme-instuctions-for-posts.md`

That is, `date-FileName.md`. If you are having any doubts, or want to see more
examples, simply see the `blog/content/post` folder.

>Do not add any additional files like images here. [TBD]
>Do not add `post.md` file.

### Post template

The post must have a few information, that will be crucial for `Hugo` static
pages generator:

```
---
title: Lorem ipsum
author: Name Surname
layout: post
published: true
date: YYYY-MM-DD HH:MM:SS

tags:
	- tag 1
	- tag 2
categories:
	- cat 1
	- cat 2
---

Your post
```

Feel free to use template: `blog/content/post/YYYY-MM-DD-template-post.md`

### Available categories

We have several categories you can choose from:

- Firmware
- IoT
- Miscellaneous
- OS Dev
- App Dev
- Security
- Manufacturing

#### Tags

Basically, there is a huge pool of tags we have, and you can add any tags you
like.

---

### Markdown

There is on the internet a great tool for anyone writing posts, that is
[Markdown
Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).
It is awesome because it is short and clear.

However, here are some most important commands:

- #, ##, ###, ####, #####, ###### - headers (just like in HTML `<h1><h2><h3>`
etc.)
- `- some text` - it is simply a list item for an unordered list. - `<li>` in
HTML
- `1. some text` - an ordered list. Number does not matter, it will be ordered
automatically.
- `[Visible text](URL)` - a link
- `![alt text](URL)` - in-built image. Alt text will be displayed if the image
is unavailable
- ` - inline code. Can be used as an inline quote
- ` x3 - block of code. You can write, next to it (connected) a programming
language

**Remember about newlines before markdown tables, lists, quotes (>) and blocks
of text (\`\`\`).**

I hope this will help. To see more, visit [Markdown
Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)

>You can write attach inline HTML into Markdown and it will work!
>`<span style="color: blue">Some text</span>`

### SEO best known methods

* Meta description - each post should have single-sentence description with
  proper keywords (try to add as many keywords as possible)
> previously [TBD - how to set them now] was set in the Yoast SEO plugin

* Tags selection - use proper tags (good examples are tags for articles of our
	competition and results from the Google first site)

* Graphic/image title - description with keywords related to whole article. All
images uploaded to WordPress should be edited in terms of SEO (WP-admin panel in
the `Media` tab). It is required to complete the `Caption` field and add tags
with `Meta Tag manager` -> `Add Meta Tag` (at the bottom).
> TBD - test if images added with markdown file path can be used

### Images optimization - WordPress

When you write an article and want to add some photos, you need to remember
about optimizing your photos. If you don't do that, your readers will need to
download heavy images in order to read your articles. Also, that impacts our
score on PageSpeed Insights. Besides, without losing any quality, you can
reduce (for example) a file size from 2MB to 300KB, which is an enormous
difference.

If you want a photo to be optimized, you can simply send it to Wordpress
Administrator, or do it by yourself, if only you have access to Wordpress.

#### Images optimization step-by-step

1. Once you have a photo you'd like to be in your post, log in to 3mdeb
Wordpress using your credentials.
2. Go to `Media` on the left-hand side of your screen and select `Add New`.
3. Upload the photo of your choice.
4. When the photo is uploaded, you can either go back to `Media Library` or you
can click `Edit` on the right-hand side of your screen. Either way, you need to
click `Edit`.
5. Copy the `File URL` which is placed on the right-hand side of your screen.
6. Visit the [PageSpeed
Insights](https://developers.google.com/speed/pagespeed/insights/) and paste
the URL.
7. On the bottom of the page, you will get a downloadable content which will
include a folder `Images`.
8. After you download the content, you will need to replace the current image
with the new one.
9. Once again, `Edit` the image you previously uploaded and just below the
`Description` text field, you will see a button `Upload a new file`.
10. Select `Replace the file, use new file name and update all links` and
Choose the file you have just downloaded from PageSpeed Insights.
11. Press `Upload`.

The image did not change its URL, it was only replaced with the optimized
version of it. Now, you can use it in your article.

>In case you don't have access to uploading images in Wordpress, contact
Wordpress Administrator.
>Remember to ALWAYS optimize all your images! It impacts the score heavily.

## Publishig post

To add new post to our blog, first make sure that post written in Markdown is
properly formatted and has all required information in the header (see
[post template](#post-template) section). Please also make sure to go through
the rest of the [good practices](#good-practices) section first.

When ready, add the markdown file to `blog/content/post` and commit changes.

### Local preview

1. Remove `public` directory: `rm -rf blog/public`
1. Generate blog: `docker run --rm -it -v $PWD/blog:/src -u hugo jguyomard/hugo-builder hugo`
1. Generated files can be found in `blog/public`

There is possibility to check whether new post is well formatted:
1. Run local server: `docker run --rm -it -v $PWD/blog:/src -p 1313:1313 -u hugo jguyomard/hugo-builder hugo server -w --bind=0.0.0.0`
1. Go to [http://localhost:1313/](http://localhost:1313/) to view the changes.

### Deployment on `beta` blog

1. Push commits with your blog post to your branch. There are no strict rules
   for branch naming. It should refer to the post title.

1. Create a Pull Request, targetting `develop` branch.

1. Once your Pull Request gets merged to `develop`, the blog should be
   automatically deployed to the [beta](https://beta.blog.3mdeb.com). You can
   check the deploy job status on the
   [travis-ci.com](https://travis-ci.com/3mdeb/news-and-ideas)

### Deployment on `production` blog

When the blog's status in [beta](https://beta.blog.3mdeb.com) is acceptable,
we can deploy to [production](https://blog.3dmeb.com). To do that, simply
create the Pull Request from `develop` to `master`. Once it gets merge, the
same version of blog should be deployed to
[production](https://blog.3mdeb.com).

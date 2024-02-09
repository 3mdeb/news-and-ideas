# 3mdeb blog documentation

> Important note: The author needs to verify the content using
> [Grammarly](#grammarly---a-must-have-for-content-verification) before
> requesting review. Ask your supervisor for the premium account access

## Table of contents

<!-- toc -->

- [Deployment status](#deployment-status)
- [Usage](#usage)
  - [Add new post](#add-new-post)
    - [Categories](#categories)
    - [Tags](#tags)
  - [Local preview](#local-preview)
  - [Deployment on https://beta.3mdeb.com](#deployment-on-beta-blog)
  - [Deployment on `production` blog](#deployment-on-production-blog)
  - [Add new profile page](#add-new-profile-page)
- [Good practices](#good-practices)
  - [Grammarly](#grammarly---a-must-have-for-content-verification)
  - [Markdown](#markdown)
  - [Single or multiple authors](#single-or-multiple-authors)
  - [SEO best known methods](#seo-best-known-methods)

<!-- tocstop -->

## Deployment status

Production deploy status:

![Build Status](https://github.com/3mdeb/news-and-ideas/workflows/Build%20news-and-ideas/badge.svg?branch=master)

Beta deploy status:

![Build Status](https://github.com/3mdeb/news-and-ideas/workflows/Build%20news-and-ideas/badge.svg?branch=develop)

## Usage

### Add new post

To add new post to our blog, first prepare local repository:

1. Clone repository: `git clone git@github.com:3mdeb/news-and-ideas.git`
1. Change directory: `cd news-and-ideas`
1. Change branch to development: `git checkout develop`
1. Create new unique branch: `git checkout -b <unique_branch_name>`
1. Run and follow the script instructions: `./scripts/new-post.sh`
1. Check the name of the created file: `git status`
1. Edit post: `vim blog/content/post/<filename>.md`

Some valuable information:

- Familiarize yourself with [good practices](#good-practices) section.
- Use [Markdown](#markdown) to write your blog post.
- You can use [local preview](#local-preview)
- Finished blog post should get reviewed - please create Github Pull Request to
  `develop` branch as described [here](#deployment)
- If deployment to beta doesn't show any issues please ask maintainer for sync
  to [master](#deployment).

#### Categories

We have several categories you can choose from:

- Firmware
- IoT
- Miscellaneous
- OS Dev
- App Dev
- Security
- Manufacturing

#### Tags

Basically, we have a huge pool of tags available. Before creating a new tag,
check the currently [available tags](https://blog.3mdeb.com/tags/). If there is
no tag that properly describes your blog, create a **one** new tag.

### Local preview

1. Generate blog: `./scripts/local-build.sh`
1. Generated files can be found in `blog/public`

There is possibility to check whether new post is well formatted:

1. Run local server: `./scripts/local-preview.sh`
1. Go to [http://localhost:1313/](http://localhost:1313/) to view the changes.

## Deployment

### Deployment on beta blog

1. Push commits with your blog post to your branch. There are no strict rules
   for branch naming. It should refer to the post title.

1. Create a Pull Request, targeting `develop` branch.

1. Once your Pull Request gets merged to `develop`, the blog should be
   automatically deployed to the [beta](https://beta.blog.3mdeb.com). You can
   check the deploy job status on the
   [github action](https://github.com/3mdeb/news-and-ideas/actions/workflows/build.yml)

### Deployment on `production` blog

When the blog's status in [beta](https://beta.blog.3mdeb.com) is acceptable, we
can deploy to [production](https://blog.3mdeb.com). To do that, simply create
the Pull Request from `develop` to `master`. Once it gets merged, the same
version of blog should be deployed to [production](https://blog.3mdeb.com). You
can check the deploy job status on the
[github action](https://github.com/3mdeb/news-and-ideas/actions/workflows/build.yml)

### Add new profile page

Employees and post authors profile pages are now implemented to our Hugo blog.
To add new profile page, follow steps below:

1. Add `_index.md` file to `blog/content/authors/name-surname/` with the content
   about the author (look at other profile pages for template).
1. Add `name.surname.json` file to `blog/data/authors/` with the content about
   the author for the post footer (look for other .json files for template)
1. Add `name.surname.png` image to `blog/static/authors/` for profile image.
1. After rebuilding the site (locally), new profile should be visible in the
   authors list page: <http://localhost:1313/authors/>

## Good practices

### Broken links checker

Currently we are using [lychee](https://github.com/lycheeverse/lychee) a fast,
async, stream-based link checker written in Rust. The automatic check is
triggered on each push to the master pull request.

You can also run it locally using a docker image:

```bash
$ docker run --init -it --rm -w $(pwd) -v $(pwd):$(pwd) lycheeverse/lychee
    --max-redirects 10 -a 403,429,500,502,503,999 .
```

We also use the Lychee Log Parser, which evaluates whether the problems detected
by lychee are actual problems with the site or server. Whenever you add
changes, it is your responsibility to fix all problems (even if the erroneous
links are in a part of the code that you have not changed). In this way,
together we will maintain the quality of the links and fix the errors that
occur.

To fix an error, open the job that crashed. In the log you will find
information about which file the error is in and which link is affected:

```bash
2024-02-07 02:08:54 - ERROR - Broken links found!
2024-02-07 02:08:54 - ERROR - ---
2024-02-07 02:08:54 - ERROR - Broken links in "BROKEN.md":
2024-02-07 02:08:54 - ERROR - ---
2024-02-07 02:08:54 - ERROR - Broken link: https://use.fontawesome.com/
2024-02-07 02:08:54 - ERROR - Failed: Network error: 404
2024-02-07 02:08:54 - ERROR - ---
```

In this case, the file is `"BROKEN.md"` and the invalid link is
`https://use.fontawesome.com/`. Check whether the path has changed or the
page has expired. If the page has expired, use <https://web.archive.org/> to
restore the older version. Lychee automatically suggests url fix for the broken
links:

```shell
 2024-02-09 13:02:52 - ERROR - ---
2024-02-09 13:02:52 - INFO - Check if broken URL server is expired. If it's no longer available, you can fix broken links using the suggestions below:
2024-02-09 13:02:52 - INFO - ---
2024-02-09 13:02:52 - INFO - Suggestions for the "BROKEN.md"
2024-02-09 13:02:52 - INFO - ---
2024-02-09 13:02:52 - INFO - https://use.fontawesome.com/ - http://web.archive.org/web/20211220191310/https://use.fontawesome.com/
2024-02-09 13:02:52 - INFO - ---
```

If the page does not have a saved version in the archive, remove the link and
add an annotation.

If you think that the error that appeared is not an error of the site but
of the server you are connecting to, please open an issue and we will help
you solve the problem.

### Relative links

Please avoid using relative like:

```md
[contact](../../pages/contact/)
```

Instead, use absolute links:

```md
[contact](https://www.dasharo.com/pages/contact/)
```

### pre-commit hooks

- [Install pre-commit](https://pre-commit.com/index.html#install), if you
  followed [local build](#local-preview) procedure `pre-commit` should be
  installed

- [Install go](https://go.dev/doc/install)

- Install hooks into repo:

```shell
pre-commit install --hook-type commit-msg
```

- Enjoy automatic checks on each `git commit` action!

- (Optional) Run hooks on all files (for example, when adding new hooks or
  configuring existing ones):

```shell
pre-commit run --all-files
```

#### To skip verification

In some cases, it may be needed to skip `pre-commit` tests. To do that, please
use:

```shell
git commit --no-verify
```

### Grammarly - a must have for content verification

Grammarly is a great, free tool for all bloggers and anyone who needs to write
documentation in English. It will let you know if you skipped a coma or made a
typo, as well, as it will check advanced grammar mistakes, too. Bear in mind,
that the free version has its limits, so you need to keep an eye on it at all
times and still, you are the one who distinguishes when to use a/an or the, as
it only suggests changes.

Two versions of Grammarly are available: a plugin for Chrome/Chromium or online
application. You need to create an account (it's for free) to be able to use
Grammarly.

Visit the website [Grammarly](https://app.grammarly.com/) and create an account.

> It is a MUST-HAVE application for anyone who writes posts or documentation, so
> feel obliged to use it.

### Markdown

There is on the internet a great tool for anyone writing posts, that is
[Markdown Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).
It is awesome because it is short and clear.

However, here are some most important commands:

- #, ##, ###, ####, #####, ###### - headers (just like in HTML `<h1><h2><h3>`
  etc.)
- `- some text` - it is simply a list item for an unordered list. - `<li>` in
  HTML
- `1. some text` - an ordered list. Number does not matter, it will be ordered
  automatically.
- `[Visible text](URL)` - a link
- \` - inline code. Can be used as an inline quote
- \` x3 - block of code. You can write, next to it (connected) a programming
  language. Supported aliases for language highlighting are listed
  [here](https://gohugo.io/content-management/syntax-highlighting/#list-of-chroma-highlighting-languages)

If your post includes any images, they must be located in `blog/static/img`
directory. To link them in file written in Markdown, use the format below:

```bash
![alt text](/img/image_name.jpg)
```

**Remember about newlines before markdown tables, lists, quotes (>) and blocks
of text (\`\`\`).**

I hope this will help. To see more, visit
[Markdown Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)

> You can write attach inline HTML into Markdown and it will work!
> `<span style="color: blue">Some text</span>`

### Single or multiple authors

In general, author meta-field MUST be strictly formatted (lowercase, non-polish
letters):

```bash
author: name.surname
```

If post has multiple authors, author meta-field MUST be formatted as below:

```bash
author:
    - name.surname
    - name.surname
```

### SEO best known methods

- Meta description - each post should have single-sentence description with
  proper keywords (try to add as many keywords as possible)

> previously set in the Yoast SEO plugin \[TBD - how to set them now\]

- Tags selection - use proper tags (good examples are tags for articles of our
  competition and results from the Google first site)

- Graphic/image title - description with keywords related to whole article. All
  images uploaded to WordPress should be edited in terms of SEO (WP-admin panel
  in the `Media` tab). It is required to complete the `Caption` field and add
  tags with `Meta Tag manager` -> `Add Meta Tag` (at the bottom).

### Creating titles - Emotional Marketing Value Headline Analyzer

<https://www.aminstitute.com/headline/>

The free tool, which analyze headline to determine the Emotional Marketing Value
(EMV) score. Headline is analyzed and scored based on the total number of EMV
words it has in relation to the total number of words it contains. This will
determine the EMV score of headline. Most professional copywriters' headlines
will have 30%-40% EMV Words in their headlines, while the most gifted
copywriters will have 50%-75% EMV words in headlines.

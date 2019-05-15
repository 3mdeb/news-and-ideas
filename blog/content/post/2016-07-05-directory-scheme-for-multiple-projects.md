---
ID: 62961
title: Directory scheme for multiple projects
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/directory-scheme-for-multiple-projects/
published: true
date: 2016-07-05 23:31:33
year: "2016"
tags:
  - productivity
categories:
  - Miscellaneous
---
How to keep clean organization while working on multiple projects ?
-------------------------------------------------------------------

Answer to this question depends on workflow and nature of projects itself.

Below I would like to present my approach to manage sanity while having
multiple projects going simultaneously. This would be Embedded Systems
Consultant view and will mostly show directory organization, but I think it can
be adopted to other programmers workflow.

Directory organization
----------------------

Usually I have up to 10 projects from external customer running and ~3
internal. Obviously better organization minimize overhead related to searching
and wondering where to put recently obtained file. During last 3 years I
collected over 60 projects for 45 customers.

Based on that experience I created directory structure that work pretty good
for above numbers. Scheme looks like this:

```
${HOME}/projects/<year>/<customer>/<project-name>/{logs,images,releases,src}
```


## Customer/year order

One flaw that this setup has is for project that last more then year. I don't
think making it `<customer>/<year>` improve things, because then I would have
tens of even hundred of directories in `projects`. Splitting it by year makes
searching focused. For now, when I deal with project longer then year I just
copy relevant part from previous year. By relevant part I mean something that I
really have to use, not one time reference. This can be for example particular
SD card image that is still used as development base.

## Customer

Customer part is trivial, although sometimes can cause confusion. There are
situation where I start research not knowing what company I work for, because I
was reached not from company domain. There are also cases when someone reach me
over freelance portals (Upwork, Guru etc.) that information provided are
outdated or simply invalid.

Having correct customer name is important only at invoicing stage, before that
if I'm not clear I just place some made up string that can uniquely identify
customer. Usually this is company name and contact person name, if company
unknown.

## Project name

Usually prototype projects doesn't have marketing name, but project can be
called by SoC/CPU/dev board + main feature ie. `a20_camera`, `bbb_canbus_reader`
etc.

What most embedded projects needs ?
-----------------------------------

After couple years I found that couple thing are typically needed:

* `logs` - this directory is used most of the times, I tend to run `minicom` in
  it with enabled logging, you never know when you will need information form
  this directory, naming convention for log files is something I still struggle

* `images` - this is directory for OS images, typically I have here SD card
  images and ISO images of distros used in project, sometimes you may end up
  keeping multiple instance of the same OS in various projects, but with 1TB
  disc this should not be big concern, you can always search for duplicates,
  knowing where your OS is and avoiding downloading it again can save some time

* `releases` - this directory contain all releases, developers usually use work
  in progress code, but customer receive release version of deliverables and
  usually will report bugs against particular release version

* `src` - this directory keep all source code related to project, those are
  mostly git repositories cloned inside directory

Sample directory structure may look like that:

```
.
└── projects
    ├── 2015
    │   └── acme1
    │       ├── foo1
    │       │   ├── images
    │       │   ├── logs
    │       │   ├── releases
    │       │   └── src
    │       └── foo2
    │           ├── images
    │           ├── logs
    │           ├── releases
    │           └── src
    └── 2016
        └── acme2
            ├── foo1
            │   ├── images
            │   ├── logs
            │   ├── releases
            │   └── src
            └── foo2
                ├── images
                ├── logs
                ├── releases
                └── src
```

Summary
-------

I hope this concept is somehow useful for you. I want to keep above information
for self reference, because I was asked couple times how to organize multiple
projects. Explaining this each time leads to this article. Of course whole
organization is very subjective and may not work good for everyone.

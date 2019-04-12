---
ID: 62756
title: 'Mutt tutorial part 3 - sidebar, URLs in e-mails'
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/mutt-tutorial-part-3-sidebar-urls-in-e-mails/
published: true
date: 2012-05-13 15:43:00
tags:
  - linux
  - mutt
  - gpg
  - password
categories:
  - Miscellaneous
---
Information in this post came from [lunar linux page][1]. Kudos to its author.
In this post I want to discuss two topics: sidebar and how to open urls form
inside mutt. Sidebar is mutt feature delivered in mutt-patched package in
Debian. It cause to split standard mutt window in two parts. In first we can
find list of folders defined in the `$HOME/.muttrc` file, second window is a
known old window with the list of posts. Mutt window with sidebar looks like on
the picture below:

![][2]

To use side bar we need to install mutt-patched packed in Debian:

<pre><code class="bash">sudo apt-get install mutt-patched
</code></pre>

To make side bar more accessible I use default settings from lunar linux page.
Add below lines to `$HOME/.muttrc`:

<pre><code class="bash">set sidebar_width = 30
set sidebar_visible = yes
color sidebar_new yellow default
bind index CP sidebar-prev
bind index CN sidebar-next
bind index CO sidebar-open
bind pager CP sidebar-prev
bind pager CN sidebar-next
bind pager CO sidebar-open
</code></pre>

First line sets width of side bar it depends on how long are your folder names.
Second line makes sidebar by default visible. Third makes folders with new
messages yellow. Other lines create shortcuts for navigating sidebar. Note that
C is not Ctrl but uppercase 'c' key. Second topic I want to discuss is how to
open urls from inside e-mails. To do this we can use tip from [mutt site][3]. As
it said we need urlview application:

<pre><code class="bash">sudo apt-get install urlview
</code></pre>

To correctly configure this tool you need to create `$HOME/.urlview` file. So:

<pre><code class="bash">vim $HOME/.urlview
</code></pre>

In this file we define two things. First will be regular expression which match
urls and second will be command line to run when regexp was matched. File looks
like below:

<pre><code class="bash">REGEXP (((https?|ftp|gopher)://|(mailto|file|news):)[^? "]+|(www|web|w3).[-a-z0-9.]+)[^? .,;":] COMMAND chromium %s
</code></pre>

Chromium is my browser of choice but you can use firefox, lynx or anything you
want.

 [1]: http://www.lunar-linux.org/mutt-sidebar/
 [2]: /img/mutt-screenshot.png
 [3]: http://www.mutt.org/doc/manual/manual-4.html#ss4.13

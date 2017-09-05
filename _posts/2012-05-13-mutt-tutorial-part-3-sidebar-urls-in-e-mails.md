---
ID: 62756
post_title: 'Mutt tutorial part 3 &#8211; sidebar, URLs in e-mails'
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/mutt-tutorial-part-3-sidebar-urls-in-e-mails/
published: true
post_date: 2012-05-13 15:43:00
tags:
  - linux
  - mutt
  - gpg
  - password
categories:
  - Miscellaneous
---
Information in this post came from [lunar linux page](http://www.lunar-linux.org/mutt-sidebar/). Kudos to its author. In this 
post I want to discuss two topics: sidebar and how to open urls form inside 
mutt. Sidebar is mutt feature delivered in mutt-patched package in Debian. It 
cause to split standard mutt window in two parts. In first we can find list of 
folders defined in the `$HOME/.muttrc` file, second window is a known old window 
with the list of posts. Mutt window with sidebar looks like on the picture 
below:

  ![](http://lunar-linux.org/~tchan/mutt/mutt-screenshot.png)

To use side bar we need to install mutt-patched packed in Debian:
```bash
sudo apt-get install mutt-patched
```

To make side bar more accessible I use default settings from lunar linux page. 
Add below lines to `$HOME/.muttrc`:
```bash
set sidebar_width = 30
set sidebar_visible = yes
color sidebar_new yellow default
bind index CP sidebar-prev
bind index CN sidebar-next
bind index CO sidebar-open
bind pager CP sidebar-prev
bind pager CN sidebar-next
bind pager CO sidebar-open
```

First line sets width of side bar it depends on how long are your folder names. 
Second line makes sidebar by default visible. Third makes folders with new 
messages yellow. Other lines create shortcuts for navigating sidebar. Note that 
C is not Ctrl but uppercase 'c' key. Second topic I want to discuss is how to 
open urls from inside e-mails. To do this we can use tip from [mutt site](http://www.mutt.org/doc/manual/manual-4.html#ss4.13). As it said we need 
urlview application:
```bash
sudo apt-get install urlview
```
To correctly configure this tool you need to create `$HOME/.urlview` file. So:
```bash
vim $HOME/.urlview
```
In this file we define two things. First will be regular expression which match
urls and second will be command line to run when regexp was matched. File looks like below:
```bash
REGEXP (((https?|ftp|gopher)://|(mailto|file|news):)[^? &quot;]+|(www|web|w3).[-a-z0-9.]+)[^? .,;&quot;:] COMMAND chromium %s
```
Chromuim is my browser of choice but you can use firefox, lynx or anything you want.
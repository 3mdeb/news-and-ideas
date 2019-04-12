---
ID: 62761
title: 'Mutt tutorial part 4 - html mails, address book and other useful features'
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/mutt-tutorial-part-4-html-mails-address-book-and-other-useful-features/
published: true
date: 2012-05-13 17:21:00
tags:
  - linux
  - mutt
  - gpg
  - password
categories:
  - Miscellaneous
---
How mutt can handle mails in html format ? Takling about html mail handling is
talking about handling any type of [Multipurpose Internet Mail Extensions](http://en.wikipedia.org/wiki/MIME).
Mutt supports handling for all MIME types in one place for all programs. This
place is `.mailcap` file. Googling a little bit I found below mailcap file
configuration (kudos to [Bart Nagel](http://trembits.blogspot.com/2011/12/viewing-html-in-mutt.html)).
```
text/html; pandoc -f html -t markdown; copiousoutput; description=HTML Text; test=type pandoc >/dev/null
text/html;lynx -stdin -dump -force\_html -width 70; copiousoutput; description=HTML Text; test=type lynx >/dev/null
text/html; w3m -dump -T text/html -cols 70; copiousoutput; description=HTML Text; test=type w3m >/dev/null
text/html; html2text -width 70; copiousoutput; description=HTML Text; test=type html2text >/dev/null
```
Of course we need to install all applications to make mailcap work correct:
```bash
sudo apt-get install pandoc lynx w3m html2text
```
To bring address book functionality to mutt we need abook application:
```bash
sudo apt-get install abook
```
Also few new line in `$HOME/.muttrc` will be needed:
```bash
# add alias file for addresses
set alias_file=~/.mutt/alias source ~/.mutt/alias
# configure addressbook
set query_command= "abook --mutt-query '%s'"
macro index,pager A "<pipe-message>
abook --add-email-quiet<return>" "add the sender address to abook"
```
Adding new address simply create entry in alias file. During adding new alias
abook asks about alias name, e-mail address, personal name and confirmation for
given data.  Some this fields could be filled automatically by interaction
between abook and mutt. Of course file `$HOME/.mutt/alias` have to exist before
running mutt:
touch `$HOME/.mutt/alias` To access saved aliases simply click <Tab> button in
cc, to or bcc filed.  There is few more options that I found useful. To find it
please go to my [workspace](https://github.com/pietrushnic/workspace) scripts at
github. Also if you have any issues with the configuration or comments please
let me know by commenting below the post.

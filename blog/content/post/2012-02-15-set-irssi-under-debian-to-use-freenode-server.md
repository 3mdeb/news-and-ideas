---
ID: 62680
title: Set irssi under debian to use freenode server
author: piotr.krol
post_excerpt: ""
layout: post
published: true
date: 2012-02-15 20:25:00
archives: "2012"
tags:
  - linux
categories:
  - Miscellaneous
---
Very short manual on how to set up irssi to work with freenode servers.  
Fist, install irssi:  

    sudo apt-get install irssi

Run:  

    irssi

For freenode write:  

    /connect holmes.freenode.net

Send register command for your {nickname} and add information about your {e-mail}:  

    /msg nickserv register {nickname} {e-mail}

Copy and paste line, which you get from freenode registration server to your
mailbox, to irssi. After that add freenode network:  

    /network add freenode

Add what should be automaticali send to server after connecting, remeber to
correctly write your {nickname} and {password}, password will be stored in plain
text:  

    /network add -autosendcmd '^nick {nickname};/msg nickserv identify {password}' freenode

Auto-connect everytime when irssi will be run:  

    /server ADD -auto -network freenode holmes.freenode.net 6667

Channel autologin:  

    /channel ADD -auto #debian freenode

After all we should save settings:  

    /save

That's all, enjoy!  

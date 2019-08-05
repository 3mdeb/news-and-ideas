---
ID: 62744
title: Vim as a Blogger editor
author: piotr.krol
post_excerpt: ""
layout: post
published: true
date: 2012-04-21 12:55:00
archives: "2012"
tags:
  - productivity
categories:
  - Miscellaneous
---

[Blogger.vim](https://github.com/ujihisa/blogger.vim) is a vim plugin for
interfacing with Google's Blogger. Below I will use my workspace git
[repository](https://github.com/pietrushnic/workspace). To use this plugin we
need pretty new ruby >= 1.9.2 and gems nokogiri and net-https-wrapper. Let's
install latest possible ruby for Debian, before that make sure you have latest
updates:  

    sudo apt-get update sudo apt-get upgrade sudo apt-get dist-upgrade

And ruby:  

    sudo apt-get install ruby1.9.3

Before we install gems , we need to resolve some dependencies:  

    sudo apt-get install libxml2-dev libxslt1-dev

Latest nokogiri 1.5.2 have some issues, so we need to use 1.5.0 which is stable:  

    sudo gem install nokogiri --version 1.5.0

And the wrapper for https:  

    sudo gem install net-https-wrapper

Finally also pandoc will be neded to display web pages in vim:  

    sudo apt-get install pandoc

Right now we are able to run vim with blogger support. First we need to
configure vim, add below lines to your $HOME/.vimrc file:  

    let g:blogger\_blogid = 'your\_blogid\_here' let g:blogger\_email = 'your\_email\_here' let g:blogger\_pass = 'your\_blogger\_password\_here'

Run vim and try to list your blogger posts by typing:  

    :e blogger:list

If list of you see all your posts than it seems that plugin works good. Finally
check writing feature. Create file with some text and type:  

    :w blogger:create

Few things doesn't work as it should. Meybe I will find enough time to fix it.
This article was created by using blogger.vim script.

---
ID: 62786
post_title: >
  Short hint for all those who use vim and
  pathogen
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/short-hint-for-all-those-who-use-vim-and-pathogen/
published: true
post_date: 2013-01-15 11:51:00
tags:
  - linux
  - productivity
  - vim
categories:
  - Miscellaneous
---
Today, after updating my wokspace to latest version I encounter below error during vim running:
```
Error detected while processing function pathogen#runtime_append_all_bundles:
line 1:
E121: Undefined variable: source_path
E116: Invalid arguments for function string(source_path).&#039;) to pathogen#incubate(&#039;.string(source_path.&#039;/{}&#039;).&#039;)&#039;) 
E116: Invalid arguments for function 4_warn
Press ENTER or type command to continue
```
Quick look on pathogen runtime_append_all_bundles function and I found:
```bash
call s:warn(&#039;Change pathogen#runtime_append_all_bundles(&#039;.string(a:1).&#039;) to pathogen#incubate(&#039;.string(a:1.&#039;/{}&#039;).&#039;)&#039;)
```
So simply replacing:
```bash
call pathogen#runtime_append_all_bundles()
```
with:
```bash
call pathogen#incubate() in $HOME/.vimrc fix the problem.
```
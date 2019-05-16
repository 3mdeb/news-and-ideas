---
ID: 62786
title: >
  Short hint for all those who use vim and
  pathogen
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/short-hint-for-all-those-who-use-vim-and-pathogen/
published: true
date: 2013-01-15 11:51:00
year: "2013"
tags:
  - linux
  - productivity
  - vim
categories:
  - Miscellaneous
---
Today, after updating my wokspace to latest version I encounter below error during vim running:

    Error detected while processing function pathogen#runtime_append_all_bundles:
    line 1:
    E121: Undefined variable: source_path
    E116: Invalid arguments for function string(source_path).') to pathogen#incubate('.string(source_path.'/{}').')')
    E116: Invalid arguments for function 4_warn
    Press ENTER or type command to continue

Quick look on pathogen runtime_append_all_bundles function and I found:

<pre><code class="bash">call s:warn('Change pathogen#runtime_append_all_bundles('.string(a:1).') to pathogen#incubate('.string(a:1.'/{}').')')
</code></pre>

So simply replacing:

<pre><code class="bash">call pathogen#runtime_append_all_bundles()
</code></pre>

with:

<pre><code class="bash">call pathogen#incubate() in $HOME/.vimrc fix the problem.
</code></pre>

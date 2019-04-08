---
ID: 62796
title: >
  Tmux multiplexer and vi-like keys in
  copy-mode
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/tmux-multiplexer-and-vi-like-keys-in-copy-mode/
published: true
date: 2013-03-19 16:30:00
tags:
  - linux
  - tmux
  - copy-mode
categories:
  - Miscellaneous
---
So I tried to write second post for my new blog but to effectively work using
terminal I need terminal multiplexer. I switched to tmux from screen because I
reach point that I can't do some things in it in easy way and performance was
poor. Also activity of tmux developers is better than for gnu screen. I also
experienced annoy buffer crashing especially after come back from lock mode or
cmatrix much but after reading few articles about alternative for screen I
switched to tmux. It seems that in wheezy(testing) version of tmux is outdated
(1.6.2). Last tag on tmux [sourceforge repo][1] is 1.7 and there is almost 300
additional commits on top of the master branch. Debian unstable contain version
1.7.2 it is pretty new. Awesome thing in tmux is emacs/vi keybiding for
copy-mode. It really helps with writing technical articles about linux stuff
with this console outputs and logs excerpts. To enable copy-mode in vi like way
put to `$HOME/.tmux.conf`: 

<pre><code class="bash"># use vi-like keys
setw -g mode-keys vi
</code></pre>

 [1]: http://sourceforge.net/p/tmux/tmux-code/?source=navbar

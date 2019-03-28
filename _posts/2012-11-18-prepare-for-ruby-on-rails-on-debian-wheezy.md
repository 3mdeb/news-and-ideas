---
ID: 62771
title: >
  Prepare for Ruby on Rails on Debian
  wheezy
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/app-dev/prepare-for-ruby-on-rails-on-debian-wheezy/
published: true
date: 2012-11-18 18:18:00
tags:
  - Ruby on Rails
  - Ruby
  - Rails
  - Debian
categories:
  - App Dev
---
I start to learn Ruby on Rails. As always when you learn new programming language toolchain is required. In this tutorial I will try to go through toolchain preparation for my Debian wheezy. Of course I based on Vim as my editor of choice. Second requirement will be using some parts of toolchain in latest greatest version. As a beginner point for learning Ruby on Rails I choose [this tutorial][1]. I will try to use their methods of setting environment adding my comments where it is needed. Also will resolve Debian and Vim specific issues. So let's begin. After quick look at RoR tutorial I have to switch to [this site][2] for installation for Ubuntu 12.04 LTS. But instructions don't work as expected for my Debian. So after quick: 
<pre><code class="bash">sudo apt-get install git curl
</code></pre> I realized that I need proxy for curl and not only temporary but permanent. I added below line to my 

`$HOME/.curlrc:` 
<pre><code class="bash">proxy=proxy.server.com:8080
</code></pre> After that I was able to download and install stable version of rvm: 

<pre><code class="bash">curl -L get.rvm.io | bash -s stable
</code></pre> Next I sourced configuration: 

<pre><code class="bash">source ~/.rvm/scripts/rvm
</code></pre> Output which I get was: 

    pietrushnic@lothlann:~/src/node$ rvm requirements
    Requirements for Linux "Debian GNU/Linux wheezy/sid"
    NOTE: 'ruby' represents Matz's Ruby Interpreter (MRI) (1.8.X, 1.9.X)
                 This is the *original* / standard Ruby Language Interpreter
          'ree'  represents Ruby Enterprise Edition
          'rbx'  represents Rubinius
    
    bash >= 4.1 required
    curl is required
    git is required (>= 1.7 for ruby-head)
    patch is required (for 1.8 rubies and some ruby-head's).
    
    To install rbx and/or Ruby 1.9 head (MRI) (eg. 1.9.2-head),
    then you must install and use rvm 1.8.7 first.
    
    Additional Dependencies:
    # For Ruby / Ruby HEAD (MRI, Rubinius, & REE), install the following:
    ruby: /usr/bin/apt-get install build-essential openssl libreadline6 
    libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev 
    libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev 
    automake libtool bison subversion pkg-config
    
    # For JRuby, install the following: jruby: /usr/bin/apt-get install curl g++ 
    openjdk-6-jre-headless jruby-head: /usr/bin/apt-get install ant openjdk-6-jdk # 
    For IronRuby, install the following: ironruby: /usr/bin/apt-get install curl 
    mono-2.0-devel
     I need Ruby so copy&paste line for it and: 

<pre><code class="bash">sudo apt-get install build-essential openssl libreadline6 libreadline6-dev curl 
git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 
libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison 
subversion pkg-config
</code></pre> Next thing we need is Node.js because this code of JavaScript runtime is under active development (latest version is 0.8.14 and Debian provided for sid 0.6.19) we use its latest greatest version from git repository. 

<pre><code class="bash">git clone https://github.com/joyent/node.git
</code></pre> Following by: 

<pre><code class="bash">cd node;./configure;make;make test
</code></pre> In my configuration only one test failed test-tls-server-verify: 

    Running 'Allow both authed and unauthed connections with CA1'
      throw new assert.AssertionError({
              ^
      AssertionError: agent1 rejected, but should NOT have been
         at ChildProcess.<anonymous> 
          (/home/pietrushnic/src/node/test/simple/test-tls-server-verify.js:217:14)
              at ChildProcess.EventEmitter.emit (events.js:96:17)
          at Process.ChildProcess._handle.onexit 
          (child_process.js:698:12)
          at process._makeCallback (node.js:248:20)
          </anonymous>
     This is known issue probably we have to wait for update of OpenSSL library in wheezy. Ignore this problem and install node.js: 

<pre><code class="bash">sudo make install
</code></pre> Because of RoR tutorial requirements we install version 1.9.3: 

<pre><code class="bash">rvm get head && rvm reload rvm install 1.9.3
</code></pre> Next thing will be adding vim-ruby for our favorite editor Vim. I organize my dotfiles using git. I also use pathogen to control Vim plugins (as described 

[here][3]), so : 
<pre><code class="bash">cd workspace
git submodule add https://github.com/tpope/vim-rails.git 
dotfiles/vim/bundle/vim-rails
git submodule init && git submodule update
git commit -m "vim-rails submodule added"
</code></pre> Finally we have ready to use Ruby on Rails development environment based on Vim. I suggest to take a look at this 

[movie][4] and after that dive into  [tutorial][5].

 [1]: http://ruby.railstutorial.org/ruby-on-rails-tutorial-book
 [2]: http://blog.sudobits.com/2012/05/02/how-to-install-ruby-on-rails-in-ubuntu-12-04-lts/
 [3]: http://pietrushnic.blogspot.com/2012/02/improve-productivity-by-tracking-work_20.html
 [4]: https://www.youtube.com/watch?v=30P8DSNOZuU
 [5]: http://ruby.railstutorial.org/
---
ID: 62776
title: Sqlite3 gem not supported on Heroku
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/app-dev/sqlite3-gem-not-supported-on-heroku/
published: true
date: 2012-11-18 21:16:00
tags:
  - Ruby on Rails
  - Ruby
  - Rails
  - Debian
categories:
  - App Dev
---
When I tried to deploy second part of [RoR tutorial][1] to Heroku I get this error: 
    An error occurred while installing sqlite3 (1.3.5), and Bundler cannot continue.  
    Make sure that `gem install sqlite3 -v '1.3.5'` succeeds before bundling.
    !
    !  Failed to install gems via Bundler.
    !
    ! Detected sqlite3 gem which is not supported on Heroku.
    !  http://devcenter.heroku.com/articles/how-do-i-use-sqlite3-for-development
    !
    !  Heroku push rejected, failed to compile Ruby/rails app
    To git@heroku.com:thawing-beyond-7283.git 
    ! [remote rejected] master -> master (pre-receive hook declined)
    error: failed to push some refs to 'git@heroku.com:thawing-beyond-7283.git'
     I searched a little bit about this error and find 

[this][2] stackoverflow post. But when I look more carefully on the Gemfile syntax I found a mistake. I used simply: 
<pre><code class="ruby">gem 'sqlite3', '1.3.5'
</code></pre> But I should have: 

<pre><code class="ruby">group :development do
  gem 'sqlite3', '1.3.5'
end
group :production do
  gem 'pg', '0.12.2'
end
</code></pre> As RoR tutorial states.

 [1]: http://ruby.railstutorial.org/chapters/a-demo-app#top
 [2]: http://stackoverflow.com/questions/3747002/heroku-rails-3-and-sqlite3
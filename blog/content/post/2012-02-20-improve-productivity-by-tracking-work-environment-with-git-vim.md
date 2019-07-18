---
title:   Improve productivity by tracking work environment with git - vim
abstract: In this post I try to describe my vim configuration procedure and how it is
connected with git. The whole concept is based on keeping all the configuration
files in a separate directory. These files are connected using symbolic links in
places where system or application requires it.
author: piotr.krol
layout: post
published: true
date: 2012-02-20
archives: "2012"

tags:
  - linux
  - productivity
categories:
  - Miscellaneous
---
In this post I try to describe my vim configuration procedure and how it is
connected with git. The whole concept is based on keeping all the configuration
files in a separate directory. These files are connected using symbolic links in
places where system or application requires it (eg `$HOME/.vimrc ->
/home/jdoe/workspace/dotfiles/vimrc`). So first let's create local directory for
vim:

    cd ~/workspace/dotfiles;mkdir vim  


### Pathogen

The first plugin that will be installed is pathogen created by tpope and
accessible through github. Pathogen is a vim script to manage all vim plugins
with ease. Below line add pathogen as submodule to our workspace repository
created in [previous post][1]:

    git submodule add https://github.com/tpope/vim-pathogen.git dotfiles/vim/pathogen

Initialize repository and update it:

    git submodule init && git submodule update

Create additional directories need to complete pathogen installation, change
directory to autoload:

    cd dotfiles/vim;mkdir {autoload,bundle};cd autoload

In autoload directory pathogen should be installed, bundle directory is a place
for all plugins installed in future. Finally we need to link vim script from
pathogen submodule to current directory ( `dotfiles/vim/autoload`):

    ln -s ../pathogen/autoload/pathogen.vim .

Directory structure should look like below:

    pietrushnic@eriador:~/workspace/dotfiles$ tree .
    ??? vim
    ??? autoload
    ?   ??? pathogen.vim -> ../pathogen/autoload/pathogen.vim
    ??? bundle
    ??? pathogen
    ??? autoload
    ?   ??? pathogen.vim
    ??? README.markdown

At the end of pathogen installation few lines to `$HOME/.vimrc` should be added.
Of course following rules about dotfiles management `.vimrc` should be created
as separate file in `~/workspace/dotfiles` and linked to `$HOME/.vimrc`.

    touch vimrc;ln -s $PWD/vimrc $HOME/.vimrc

Add below lines to `$HOME/.vimrc`:

    call pathogen#infect()
    call pathogen#runtime_append_all_bundles()
    call pathogen#helptags()
    syntax on
    filetype plugin
    indent on


### Fuzzyfinder

This is second plugin without which I cannot work. It speeds up searching though
files, directories and tags. Has multiple useful features. RTFM if you want knew
them. I will be also added as a git submodule:

    git submodule add https://github.com/vim-scripts/FuzzyFinder.git dotfiles/vim/bundle/fuzzyfinder

Additional plugin is needed to correctly install fuzzyfinder:

    git submodule add https://github.com/vim-scripts/L9.git dotfiles/vim/bundle/l9

Initialize and update submodules:

    git submodule init && git submodule update

Configuration I suggest to configure fuzzyfinder with accordance to example
provided in help. 

*   Run vim and type :h fuf@en<enter>. </enter>
*   Choose tag fuf-vimrc-example and press Ctrl-]. 
*   Mark whole keybindings copy and paste to `~/.vimrc`

Right now I think it is enough with vim configuration. Of course I use plenty of
other plugins but I don't have to time to describe my them all (maybe in future
posts). Don't forget to commit your changes, there could be a lot of them,
however, to deal with the distribution of these changes and improve your skills
try to use git add -p interface, suggesting after linux code style - each commit
should contain separate logical part of the changes, personally I add prefix to
my commits (eg . vim, git, etc.) to ease deal with git log. Notes:

*   vim helpfiles generates tags files, which should be ignored by git, so I
recommend to create .gitignore in every module with blow content:

    .gitignore
    tags*

*   by default fuzzyfinder operate on unfriendly color palette espessicaly when
using it through putty, highlighted pattern could be changed by added below
lines to .vimrc (9 = black)

```
" fuzzy-finder - fix colors highlight PmenuSel ctermbg=9
```

 [1]: /2012/02/19/improve-productivity-by-tracking-work/

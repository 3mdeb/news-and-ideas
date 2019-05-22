---
ID: 62856
title: 'Workflow imporovement with Open Source tools - part 1'
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/workflow-imporovement-with-open-source-tools-part-1/
published: true
date: 2013-05-16 22:16:00
archives: "2013"
tags:
  - mutt
  - productivity
  - open source
  - workflow
  - taskwarrior
categories:
  - Miscellaneous
---
### Introduction

I want to start a series of articles to describe how I improve my workflow with
geeky Open Source applications. I will concentrate on terminal applications that
I try to use in my GTD process.

### Terminal

#### Solarized gnome-terminal

If you already don't know what solarized color scheme is then please take a look
at [this page][1]. To install solarized colorscheme in gnome-terminal simply
follow instruction from this [git repository][2].

### Mutt again

During last days I spent a lot of time to tweak my mutt configuration. Here I
will give you few hints about things that I learned.

#### Solarized mutt

To enable solarized colorscheme in mutt simply download one of scheme files from
[github][3]. If you installed dark scheme for your gnome-terminal then I suggest
`mutt-colors-solarized-dark-16.muttrc`. Copy this file for example to
`$HOME/.mutt` and source it in muttrc file:

    source $HOME/.mutt/mutt-colors-solarized-dark-16.muttrc


#### Width of From column

Usually from field in today's emails is longer than 19 characters. If this
happens mutt by default will not display whole string. To change this behavior
you can manipulate

`index_format` variable. I set mine to 30: {% raw %}
    set index_format="%4C %Z %{%b %d} %-30.30L (%4l) %s"
     {% endraw %}

#### Sidebar

Finally I gave up sidebar for using latest code without annoying
`tls_socket_read` error. Switching between IMAP folders is not so bad, you can
quickly display all folders by `c<Tab><Tab>` or simply `y`

#### Offline imap

This is probably best program to synchronize your emails with local storage. It
also has feature that allow synchronization between different IMAP servers but
I'm not using it. Few things are crucial when using `offlineimap`:

*   probably easiest way to keep passwords secret is using python hooks for
gnome-keyring, detailed description how to integrate it with `offlineimap` is
[here][4]. Debian name of `gnome-python2-gnomekeyring` is different: `python-gnomekeyring`.
*   Use meaningful `localfolders` because you will use it in `mutt` configuration

Typical configuration of `$HOME/.offlineimaprc`:

    [mbnames]
    enabled = yes
    filename = ~/.mutt/muttrc.mailboxes
    header = "mailboxes "
    peritem = "+%(accountname)s/%(foldername)s"
    sep = " "
    footer = "n"

    [general]
    metadata = ~/.offlineimap
    maxsyncaccounts = 5
    maxconnections = 2
    accounts = account1, account2
    status_backend = sqlite
    pythonfile = ~/.mutt/offlineimap.py

    [Account account1]
    autorefresh = 3
    localrepository = acc1_local
    remoterepository = acc1_remote

    [Repository acc1_local]
    type = Maildir
    localfolders = ~/.mail/account1

    [Repository acc2_remote]
    type = Gmail
    remoteusereval = get_username("account1")
    remotepasseval = get_password("account1")
    sslcacertfile = /etc/ssl/certs/ca-certificates.crt

    [Account account2]
    autorefresh = 3
    localrepository = acc2_local
    remoterepository = acc2_remote

    [Repository acc2_local]
    type = Maildir
    localfolders = ~/.mail/account2

    [Repository acc2_remote]
    type = Gmail
    remoteusereval = get_username("account2")
    remotepasseval = get_password("account2")
    sslcacertfile = /etc/ssl/certs/ca-certificates.crt

What this means by section:

*   `[mbnames]` - automatically create mailboxes folders according to your configuration on IMAP server
*   `[general]` - most important things here are self explanatory accounts variable and `max{syncaccounts,connections}`, first said how many accounts should be synchronized and second how many simultaneous connections should be used
*   `[Account *]` - contain sync refresh time in minutes (`autorefresh`) and link to local and remote repository definitions (`localrepository` and `remoterepository`)
*   `[Repository *]` - for local folder and its type and for remote gnome-keyring configuration

#### Multiple account configuration

To simplify multiple accounts configuration I added two things:

*   separated account files configuration - in my case placed in `$HOME/.mutt/accounts`

    set postponed   = +account1@server.com/Drafts
    set spoolfile   = +account1@server.com/INBOX
    set record      = +account1@server.com/Sent
    set from        = 'account1@server.com'
    set realname    = 'My Name'
    set smtp_url    = smtps://acc1@smtp.server.com:587
    set smtp_pass   = $my_pass
    set signature   = "~/.mutt/signature.example"


*   folder hooks for particular account - it cause automatic loading of configurations when folder was changed (in `$HOME/muttrc`):

    folder-hook 'account1@server.com' 'source $HOME/.mutt/accounts/account1'

#### Separate mailing list file

I keep my mailing list configuration file separated and source it in my
`$HOME/.muttrc`. I'm not mailing list advanced user, so right now I have
manually created IMAP folders and Gmail filters to move mails from mailing list
to this folders. On the mutt side I use `subscribe` command to indicate that
particular mail id is a mailing list.

### Personal informations

Some informations in my configuration files shouldn't be available for all. I
mean my email account configuration, my todo list, passwords and things like
that. To store this informations I use additional private git repository and use
it as a submodule for my workspace configuration. I wrote post about keeping
configuration using git [here][5] and [here][6].

### Taskwarrior and vit

I really like `taskwarrior` as a GTD tool but I was tired of writing everything
every time I wanted to change sth. I found `vit`. Vit is a vi-like interface to
task list generated by `taskwarrior` it works really great. Mostly it is written
in perl and there is no official repository for its code base but latest version
is from April 2013. I use lot of `project:` and `+flag` to update my TODO list.
I prefer `long` filter.

#### My taskwarrior projects and flags

I have few ongoing projects like `blog`, `productivity` and `ideas`. In addition
I use few flags like `ideas`, `finish`, `enhancement`, `fix` or `bug`. So when I
connect project and flag I get few categories like:

*   `blog ideas` for new articles ideas
*   `blog finish` for articles that should be finished ASAP
*   `blog bug/fix` for articles that have to be changed for some reason
*   `productivity bug/fix` for productivity tools configuration improvements
*   `productivity ideas` for new improvements

### Summary

I think this is enough for first post from this series. Hope it was helpful. If
yes then please share, if no then comment what I should improve. Thanks for
reading.

 [1]: http://ethanschoonover.com/solarized
 [2]: https://github.com/sigurdga/gnome-terminal-colors-solarized
 [3]: https://github.com/altercation/mutt-colors-solarized
 [4]: http://www.clasohm.com/blog/one-entry?entry_id=90957
 [5]: /2012/02/19/improve-productivity-by-tracking-work
 [6]: /2012/02/20/improve-productivity-by-tracking-work_20

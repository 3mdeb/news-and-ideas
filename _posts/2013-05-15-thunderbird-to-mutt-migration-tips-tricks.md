---
ID: 62846
post_title: 'Thunderbird to Mutt migration &#8211; tips &amp; tricks'
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/thunderbird-to-mutt-migration-tips-tricks/
published: true
post_date: 2013-05-15 18:40:00
tags:
  - mutt
  - productivty
categories:
  - Miscellaneous
---
### Preface I migrate with my working environment to laptop. My workstation going older and I don't have time to maintain few systems to keep it clean and in sync. I probably have to improve my work flow but right now I have different problems. Few weeks ago after changing environment to mobile and powerful laptop I also changed OS to Ubuntu and mail client to Thunderbird. I have to admit that both choices were mistake and I want to came back to Debian and Mutt. This post is about throwing out Thunderbird and a logical continuation of Mutt tutorial (part 

[1][1], [2][2], [3][3] and [4][4]). So what was wrong with Thunderbrid ? 
*   Not clear configuration settings - for example I tried to wrap word at 80th character, default value was set to 72 but it seems not work anyway. I try to use few googled hints but nothing works.
*   Setting up Thunderbird to work as a community developer tool was not so obvious.
*   Junk messages was marked but default filter show everything so for some IMAP boxes I get lot of spam and had hard time to find anything out there.
*   Conversation mode should be easily toggled.
*   GUI slow switching between different modes.
*   Lack of my editor of choice. If I decide to use GUI tool for some reason I require from it to be intuitive and most of my options should be available at few clicks. Probably most of my problems I could solve by giving enough effort to google it but if I have to choose hard to configure MUA I will probably be in favor of terminal tool like Mutt. So right now I'm back with Mutt and determination to adjust Mutt to my work flow. 

### Git and undelete old configuration I won't go through whole Mutt tutorial once more time. I remember that there was muttrc in my workspace git repository. So first goolge query returned what needed I found 

[this][5] stackoverflow post. I reverted muttrc and other related files deletion. 
### Short informations

*   In Ubuntu there is no `gpg` package, to get encryption you can use `gpgsm`.
*   If your e-mail account provider require user name with `@` (at sign), then you can pass it in mutt using below pattern:

    set folder = imaps://[login]@[imap_server]/ # i.e. imaps://foo@bar.pl@imap.srv.pl/
    

*   You can debug Mutt using `-d 5` parameter, this option creates `$HOME/.muttdebug0` file with verbose output, debug option can be changed in range 1-5.
*   Use latest-greatest version compiled from source instead version provided by distribution repository. It can help you get rid of problems like `tls_socket_read (Decryption has failed.)`.
*   Some accounts will not work with authenticating method presented in my previous post about gpg ([mutt tutorial part 2][2]). To workaround this you can use different format of folder variable:

    set folder = imaps://[login]:[passwd_var]@[imap_server]/ # i.e. imaps://foo:$my_bar_passwd@bar.pl@imap.srv.pl/
    

### Compile Mutt from source If you looking for latest Mutt version consider compiling mutt by yourself. First, download sources: 

    hg clone http://dev.mutt.org/hg/mutt#HEAD
    hg update -C HEAD
    hg pull -u
     There are lot of options to prepare Mutt compilation, but right now I can suggest this parameters: 

    cd mutt
    ./prepare --with-ssl --enable-debug --enable-imap --enable-smtp --enable-pop 
    -enable-hcache --with-gss --with-gnutls --with-sasl
    make && sudo make install
     If make will complain about 

`gssapi/gssapi.h: No such file or directory` then you need to install `libkrb5-dev`: 
    sudo apt-get install libkrb5-dev
    

### Summary That's all in this post but I'm sure that there will be next in this topic. I hope to improve my whole workflow and write few posts about improving productivity using open source tools.

 [1]: /2012/05/13/mutt-tutorial-part-1-setup-imap-account
 [2]: /2012/05/13/mutt-tutorial-part-2-secure-login
 [3]: /2012/05/13/mutt-tutorial-part-3-sidebar-urls-in-e
 [4]: /2012/05/13/mutt-tutorial-part-4-html-mails-address
 [5]: http://stackoverflow.com/questions/953481/restore-a-deleted-file-in-a-git-repo
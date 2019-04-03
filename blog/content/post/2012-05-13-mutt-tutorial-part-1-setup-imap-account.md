---
ID: 62749
title: 'Mutt tutorial part 1 - setup IMAP account'
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/mutt-tutorial-part-1-setup-imap-account/
published: true
date: 2012-05-13 11:43:00
tags:
  - linux
  - mutt
  - gpg
  - password
categories:
  - Miscellaneous
---
Mutt is one of those programs that make people call you a linux geek, nerd or a snob. This is because using TUI or command line tools in world of fancy GUI for most people is wierd. What's so great about mutt? I probably still have not found much of its advantages, but at first glance we can notice a few things. First, it keeps Unix convention of small programs for specific task ["Make each program to one thing well"][1] or [KISS][2]. This means that mutt is only [MUA][3], which is used to retrieve e-mails and for other tasks you need to use another application. However, due to the philosophy most applications are well suited to each other and usually everything works good. So you can easily combine it with Vim as the mail editor, abook as a address book, urlview as a browser launcher for html and graphics elements and so on. Third, it has support for IMAP which gives very nice usage model for most of e-mail account providers. Fourth, is used by such notables as Greg Kroah-Hartman and as [kernel documentation suggest][4] by other kernel developers. So lets start to discover mutt. Below I will discuss some basic features that until now (few days of using mutt) I found useful. 
1.  Big kudos to Shinobu for [this][5] post it helps me a lot. So first of all we need support for multiple accounts. In my case I have 4 accounts. Three of them got working IMAP access. 4th provider screw up something and access to IMAP server doesn't work so I need to workaround this with one of the Gmail features. At the beginning we create `$HOME/.muttrc` file:

<pre><code class="bash">vim $HOME/.muttrc
</code></pre> IMAP account configuration for looks like that: 

<pre><code class="bash"># unset important variables
account-hook . "unset imap_user; unset imap_pass"
account-hook "imaps://&lt;account_name&gt;@&lt;imap_server_address&gt;/" "
    set imap_user = &lt;e-mail_address&gt;
        imap_pass = &lt;e-mail_password&gt;"

# Setup for &lt;e-mail_address&gt;:
set folder = imaps://&lt;account_name&gt;@&lt;imap_server_address&gt;/ 
# setup needed folders
mailboxes = +INBOX =&lt;folder_name&gt;
set spoolfile = +INBOX 
folder-hook imaps://&lt;account_name&gt;@&lt;imap_server_address&gt;/ "
   set folder = imaps://&lt;account_name&gt;@&lt;imap_server_address&gt;/ 
   spoolfile = +INBOX  
   postponed = +[Gmail]/Drafts
   record = +[Gmail]/'Sent Mail' 
   from = '&lt;your_name&gt; &lt;e-mail_address&gt; ' 
   realname = '&lt;real_name&gt;' 
   smtp_url = smtps://&lt;account_name&gt;@&lt;smpt_server_address&gt; 
   smtp_pass =  unset important variables
</code></pre>

`<account_name>` - for foo.bar@gmail.com it will be foo.bar `<imap_server_address>` - this information you can get from your e-mail provider help pages or from the settings of web e-mail client, for Gmail it is imap.gmail.com `<e-mail_address>` - your e-mail address `<e-mail_password>` - your e-mail password, later we will discuss how to store this more secure than plain text :) `<folder_name>` - any folder (for gmail account also filters) you have on you IMAP account, so for gmail account it could be Drafts, Starred, Important or others. `<your_name>` - your real name or nick anything you want to show in from field `<real_name>` - could be the same as `<your_name>` `<smpt_server_address>` - your SMTP server address, for gmail users it will be smtp.gmail.com 
1.  If your e-mail provider have only pop3 access and you have gmail account you can use one of gmail account features to make your pop3 account visible as a IMAP folder. To do this got to Settings -> Accounts and Import and in the section "Check mail from other accounts" add your POP3 account. After that make sure to label your mails from POP3 account. Try to not use '@' in the label name because this cause problems during mutt configuration. If you set label for your POP3 account check if your label in Label tab have "Show in IMAP" marked, if yes everything was set correctly. To use this label in mutt simply add another `<folder_name>` to mailboxes line.

 [1]: http://www.faqs.org/docs/artu/ch01s06.html
 [2]: http://en.wikipedia.org/wiki/KISS_principle
 [3]: http://en.wikipedia.org/wiki/Mail_user_agent
 [4]: http://www.mjmwired.net/kernel/Documentation/email-clients.txt
 [5]: http://zuttobenkyou.wordpress.com/2010/11/05/mutt-multiple-gmail-imap-setup/

---
ID: 62751
post_title: 'Mutt tutorial part 2 &#8211; secure login'
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/mutt-tutorial-part-2-secure-login/
published: true
post_date: 2012-05-13 14:13:00
tags:
  - linux
  - mutt
  - gpg
  - password
categories:
  - Miscellaneous
---
This is second post of mutt tutorial series. As in the [previous post](/2012/05/13/mutt-tutorial-part-1-setup-imap-account)
for below information I need to thank Kousik for posts about [gpg](http://nixtricks.wordpress.com/2009/10/04/introduction-to-encryption-of-files-using-gpg/)
and [using it with mutt](http://nixtricks.wordpress.com/2010/05/05/mutt-configure-mutt-to-receive-email-via-imap-and-send-via-smtp/).
But probably the most important to simplify this method was Fau comment [here](http://nixtricks.wordpress.com/2010/05/20/mutt-multiple-email-accounts-using-hooks/#comment-162). 
So going to the point of secure login for mutt we need gpg. First of all we need 
to install it by simply:
```bash
sudo apt-get install gpg
```
After that we generate our keys by:
```bash
gpg --gen-key
```
I choose all default answers. So first is key type: `'RSA and RSA'`. 
Second - `keysize: 2048`. Third - time for key expiration: `'0 = key does not expire'`.
After that you need to identify your key with some data. This data will be used
to find your key so IMHO it should be short and simple but meaningful. At the end
of this process you will be asked about pass phrase, which will be used to decrypt
files encrypted with generated key. When you end with key generation you can
encrypt file with passwords. Best way to do this is to write some script that will
be sourced by mutt after decryption. For storing passwords I create directory in my `$HOME`:
```bash
mkdir $HOME/.passwd
```
Inside this directory I create text file with the script, which look like below:
```bash
vim $HOME/.passwd/mutt.txt
set my_isp1 = &quot;password1&quot;
set my_isp2 = &quot;password2&quot;
set my_isp3 = &quot;password3&quot;
```
This script of course mean to set value of variable name `my_isp{1,2,3}` to some 
password string. Remember to use `my_` prefix because this is the way that user 
variables should be defined in mutt scripts. After writing this file we need to 
encrypt it.
```bash
gpg -e -o mutt.gpg mutt.txt
```
Now we should delete txt file. To use our newly created encrypted password script
we need to add some lines to `$HOME/.muttrc`. So `vim $HOME/.muttrc`. Line that
we need before sourcing encrypted scripts is declaration of variables in the script:
```bash
set my_isp1 = &quot;&quot;
set my_isp2 = &quot;&quot; 
set my_isp3 = &quot;&quot;
```
After this line we can source and decrypt out file with the passwords:
```bash
source "gpg --textmode -d ~/.passwd/mutt.gpg |"
```
At the end wee need to replace all out plain text passwords (`smtp_pass` and
`imap_pass` variables) with variables defined in out encrypted file. This
settings will cause that mutt during start will run gpg to ask about password
to decrypt password script file. In the [next post](/2012/05/13/mutt-tutorial-part-3-sidebar-urls-in-e/) 
I will discuss mutt with sidebar and how to open html files from inside mutt.
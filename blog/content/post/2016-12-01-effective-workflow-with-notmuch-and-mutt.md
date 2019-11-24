---
author: Piotr Król
layout: post
title: "Effective workflow with notmuch and mutt"
date: 2016-12-01 12:15:07 +0100
comments: true
categories: mutt linux notmuch
---

I use mutt/mutt-kz, offlineimap, afew, msmtp and notmuch for couple years, but
some thing started to cause problems for me. First thing is extensive use of
tags I use lot of them starting with spam and ending with shopping, social
media etc. Tool that should handle that is [afew](https://github.com/teythoon/afew) unfortunately it is no maintained well
enough and I encounter too much problems with it (building filters, rules
adding automation etc.). I also had not time to investigate source code despite `afew` was written in Python.

I decided to simplify things a little bit and rely more on on notmuch not on
intermediate software. Of course I was not sure if this will not evolve in
direction that will lead to use intermediate tool.

Best would be to have filter rules in tool that is dedicated to that, but only
simplicity and understanding what are the problems lead to effective usage of
those kind of tools.

## Extracting rules from afew config

I had to do little bit of vim hacking to extract rules from afew config.
Finally I get to couple files in notmuch batch file format:

```
+<tag>|-<tag> <search-term>
```

`<tag>` part is tag that you want apply or remove and `<search-term>` format is
described in:

```
notmuch help search-terms
```

You can add or remove multiple tags just by placing them with space separator
one by one:

```
+tag1 -tag2 +tag3 <search-term>
```

So after extracting rules I had couple files in `$HOME/.mutt/notmuch_filters`.
Each file contained group of rules: spam, shopping, finances and so on. I
started with one emails per line for easy of adding from `mutt` macros.

## Mutt macro for adding emails to notmuch filters

I added those macros in `mutt-kz`:

```
macro index S "<pipe-message>/home/pietrushnic/.mutt/add-to-spam.sh<enter><modify-labels-then-hide>+spam -inbox\n<sync-mailbox>"
macro index <Esc>m "<pipe-message>/home/pietrushnic/.mutt/add-to-sm.sh<enter><modify-labels-then-hide>+sm -inbox\n<sync-mailbox>"
macro index <Esc>f "<pipe-message>/home/pietrushnic/.mutt/add-to-finances.sh<enter><modify-labels-then-hide>+finances -inbox\n<sync-mailbox>"
macro index <Esc>s "<pipe-message>/home/pietrushnic/.mutt/add-to-shopping.sh<enter><modify-labels-then-hide>+shopping -inbox\n<sync-mailbox>"
```

Each `add-to-*.sh` script looks the same. This was easy to optimize, but I
started as simple as possible. Script example looked like that:

```
#!/bin/sh

email=$(egrep '^From' $*|cut -d "<" -f2 | cut -d ">" -f1)
if grep -Fq "$email" ~/.mutt/notmuch_filters/notmuch_spam; the
    echo "$email exist
    read -r -p "Press space to continue..." key
else
  echo "-inbox +spam from:$email" >> ~/.mutt/notmuch_filters/notmuch_spam
fi
```

What it does is checking if email extracted from piped message exist in given
filter, if not filter is added. Then filtered files are used by `offlineimap`
posthook script, which initially look like that: 

```
time notmuch new
time afew --tag -vvv --new
time notmuch tag --batch --input=$FILTER_FILE
time notmuch tag --batch --input=$SPAM_FILTER_FILE
time notmuch tag --batch --input=$SM_FILTER_FILE
time notmuch tag --batch --input=$SHOPPING_FILTER_FILE
time notmuch tag --batch --input=$NEWSLETTER_FILTER_FILE
time notmuch tag --batch --input=$FINANCES_FILTER_FILE
time notmuch tag --batch --input=$FREELANCE_FILTER_FILE
time notmuch tag --batch --input=$BT_FILTER_FILE
time notmuch tag --batch --input=$JUNK_FILTER_FILE
time notmuch tag --batch --input=$REVIEW_FILTER_FILE
```

I left `afew` because it is good in detecting mailing lists and I like to
filter some messages by list. `time` is for performance measurement. Time that
this script takes with my 1k search terms to filter can be counted like that:

```
./offlineimap-postsynchook.sh|& grep real|cut -d"m" -f2|tr -d s| paste -sd+ - |bc
```

On my old Core Duo it takes ~9s. Of course there is not optimization there,
but first it should work then can be optimized.

## Offlineimap posthook

You can add `offlineimap` post hook in `$HOME/.offlineimaprc` like that:

```
postsynchook = ~/.mutt/offlineimap-postsynchook.sh
```

## Optimization

### Notmuch

First I put all emails in one file since streams plus one batch call to not
much should be faster then calling notmuch multiple times.

```
TMP_FILTER_FILE=/tmp/notmuch_tmp

cat $BT_FILTER_FILE > $TMP_FILTER_FILE
cat $FINANCES_FILTER_FILE >> $TMP_FILTER_FILE
cat $FREELANCE_FILTER_FILE >> $TMP_FILTER_FILE
cat $FINANCES_FILTER_FILE >> $TMP_FILTER_FILE
cat $JUNK_FILTER_FILE >> $TMP_FILTER_FILE
cat $NEWSLETTER_FILTER_FILE >> $TMP_FILTER_FILE
cat $REVIEW_FILTER_FILE >> $TMP_FILTER_FILE
cat $SHOPPING_FILTER_FILE >> $TMP_FILTER_FILE
cat $SM_FILTER_FILE >> $TMP_FILTER_FILE
cat $SPAM_FILTER_FILE >> $TMP_FILTER_FILE

time notmuch new
time afew --tag -vvv --ne
time notmuch tag --batch --input=$TMP_FILTER_FIL
```

This improved situation to ~7s.


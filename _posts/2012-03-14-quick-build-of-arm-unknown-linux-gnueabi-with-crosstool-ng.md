---
ID: 62712
post_title: >
  Quick build of arm-unknown-linux-gnueabi
  with crosstool-ng
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/quick-build-of-arm-unknown-linux-gnueabi-with-crosstool-ng/
published: true
post_date: 2012-03-14 23:42:00
tags:
  - crosstool-ng
  - embedded
  - linux
  - toolchain
  - arm-unknown-linux-gnueabi
categories:
  - OS Dev
  - App Dev
---
You might be surprised at how much you have to make to correctly build 
`arm-unknown-linux-gnueabi` config based toolchain with [crosstool-ng](http://crosstool-ng.org/). As you can 
see examples of many open source projects, the man's work is a rare resource. 
The result of this economic fact is that the attempt to build configuration 
`arm-unknown-linux-gnueabi` is not a simple task and during an operation you can 
come across many problems. Although I am not afraid of problems and effectively 
try to fight them and of course sharing the results of my work. My build system 
parameters:  `Debian GNU/Linux wheezy/sid 3.2.0-2-amd64`

* Clone crosstools-ng (you need mercurial)
```bash
hg clone http://crosstool-ng.org/hg/crosstool-ng
```
* Create temporary directory and run
```bash
ct-ng arm-unknown-linux-eabi #choose latest kernel (for me it was 3.2.9)
```
* We probably want to change directory to which all stuff will be build (default is `$HOME/x-tools`):
```bash
ct-ng menuconfig
```
And go to:
`Paths and misc options ---> (${HOME}/x-tools/${CT_TARGET}) Prefix directory`
Change it according to your needs. Exit end save configuration.
* Build (number after dot depend on how many command we want to run simultaneously):
`ct-ng build.4`
It can take a lot of time. On my machine with 5k BogoMips it takes over 1h.

### Problems that you can encounter: ###

* `gcj` - latest changeset `2916:6f758ed4c0b9` have trouble finding `gcj` binary,
which it show using following message:
```
[ERROR] Missing: &#039;x86_64-unknown-linux-gnu-gcj&#039; or &#039;x86_64-unknown-linux-gnu-gcj&#039; or &#039;gcj&#039; : either needed!
```
To workaround this install `gcj` and link binary like this:
```
sudo ln -s /usr/bin/gcj-4.6 /usr/bin/gcj
```
* `duma` - mentioned changeset also has problem with url to D.U.M.A library,
apply below changes to workaround problems:
```diff
--- a/scripts/build/debug/200-duma.sh Mon Mar 12 21:19:26 2012 +0100
+++ b/scripts/build/debug/200-duma.sh Wed Mar 14 20:02:22 2012 +0100
@@ -4,7 +4,7 @@ # Downloading an non-existing file from sourceforge will give you an
 # HTML file containing an error message, instead of returning a 404.
 # Sigh... 
- CT_GetFile &quot;duma_${CT_DUMA_VERSION}&quot; .tar.gz http://kent.dl.sourceforge.net/sourceforge/duma/ 
+ CT_GetFile &quot;duma_${CT_DUMA_VERSION}&quot; .tar.gz http://downloads.sourceforge.net/project/duma/duma/2.5.15
 # Downloading from sourceforge may leave garbage, cleanup
 CT_DoExecLog ALL rm -f &quot;${CT_TARBALLS_DIR}/showfiles.php&quot;* }
```
* `mawk` - if mawk return syntax error like this:
```
mawk: scripts/gen-sorted.awk: line 19: regular expression compile failed (bad
class -- [], [^] or [)
```
It could be fixed in two ways. First is to change `line 19` in `/path/to/tmp/dir/.build/src/glibc-2.9/scripts/gen-sorted.awk`
Is:
```
sub(//[^/]+$/, &quot;&quot;, subdir);
```
Should be:
```
sub(//[^/]+$/, &quot;&quot;, subdir);
```
Or simply by installing gawk, reconfigure and recompile `crosstools-ng`.

This was my first post related to linux embedded enviroment. Hope it will be more. Enjoy!
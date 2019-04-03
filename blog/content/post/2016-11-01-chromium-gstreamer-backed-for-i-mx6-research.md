---
ID: 62971
title: >
  Chromium GStreamer backed for i.MX6
  research
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/app-dev/chromium-gstreamer-backed-for-i-mx6-research/
published: true
date: 2016-11-01 00:13:32
tags:
  - embedded
  - linux
  - iMX6
  - Chromium
  - GStreamer
  - QT
  - NXP/Freescale
categories:
  - App Dev
---
Recently I work on i.MX6 based project that requires video hardware decoding in web browser (best case in [QtWebEngine][1], which is entire Chromium platform in Qt). 
### Chromium After some research it appears that Chromium is not interested in providing external support for GStreamer-backed video hardware decoding. Truly going through all discussion related to this topic was very dissapointing. Typically Chromium developers just close thread when discussion started to be noisy and there mass of complaining people raised. If you want to go through that path you can read: 

*   [Enable VAVDA by default on Linux for VA-API-assisted HW video decode][2]
*   [Call vaInitialize() at PreSandbox stage][3]
*   [Remove additional protection of kDisableAcceleratedVideoDecode in bpf_gpu_policy_linux.cc. (Closed)][4]
*   [Use GStreamer as a media backend][5]
*   [Feature Request: Making Gstreamer and FFMPEG coexist in chromium.(atleast in chromium linux)][6] In short Chromium developers are concerned about security and portability issues with their browser. Something more have to be behind the scenes, because this explanation was proved to not be consistent across various Chromium features. As side note for some x86/x86_64 platforms it is possible to enable video hardware decoding. I'm not sure where is the list of available platforms but 

[this post][7] show how to enable that experimental support. On my platform with GeForce GTX 960 it works fine. 
### Firefox This lead me to check what is going on on Firefox side and results were better, but recently GStreamer backend was disabled because of bugs that it leads to. 

*   [(gstreamer) meta Gstreamer support has problems][8]
*   [(Linux) Gstreamer support removed][9]

### Chromium GStreamer backend Despite all above problems surprisingly Samsung came with solution (at least at first glance). Company published 

[Chromium GStreamer Backend][10] project, which doesn't seem to have big community, but recent commits are from September, so 1.5 month old. There 2 main contributors both from Samsung. 
## How I gave up and pivot to other solution I tried to approach Chromium building from scratch as described in Samsung documentation. Unfortunately it consumed a lot of effort. Hardware requirements are ridiculous (>16GB RAM and 100GB storage). Then it happened that procedures are for Ubuntu and do not align great with Debian (especially Sid). On the other hand I broke my system so many time that I'm very resistant to any additional system modification - at this point I'm really in favour of separating environment using Docker. So after realizing how complex Chromium is I reconsidered approach and decided that I have to focus on making GStreamer video hardware acceleration work smoothly in Qt. Final result will be less flexible but will add less headache. 

## Summary I wanted to drop this note for community and 3mdeb further reference. Hope anyone trying similar will read that and can decide if it is worth digging deeper. I had this passivity to pivot, but I assume there were situation when you will have to go deeper, if so please drop me note in comments. Also if you feel that things moved forward in above area it would be great to know.

 [1]: https://wiki.qt.io/QtWebEngine
 [2]: https://bugs.chromium.org/p/chromium/issues/detail?id=137247
 [3]: https://codereview.chromium.org/15955009/
 [4]: https://codereview.chromium.org/176883018/
 [5]: https://bugs.chromium.org/p/chromium/issues/detail?id=32861
 [6]: https://groups.google.com/a/chromium.org/forum/#!topic/chromium-dev/fV_v6fH8nwE
 [7]: http://www.webupd8.org/2014/01/enable-hardware-acceleration-in-chrome.html
 [8]: https://bugzilla.mozilla.org/show_bug.cgi?id=GStreamer
 [9]: http://forums.mozillazine.org/viewtopic.php?f=7&t=3003683
 [10]: https://github.com/Samsung/ChromiumGStreamerBackend
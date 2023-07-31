---
ID: 62729
title: How to download videos from videos.linux.com
author: piotr.krol
layout: post
published: true
date: 2012-04-06 22:48:00
archives: "2012"
tags:
  - linux
categories:
  - Miscellaneous
---

Therefore, I'm leaving for the Easter holidays I wanted to download some lecture
on embedded systems, which was presented at the 2012 Embedded Linux Conference.
Although I regret I found that I could not find as good quality copy in the
network as on the Linux Foundation page. It is unfortunate that linux.com site
does not have the possibility of direct downloading video files. But there is a
workaround. Follow below tutorial:

- Go to page with video - for
  [example](https://web.archive.org/web/20160404115528/http://video.linux.com/videos/to-provide-a-long-term-stable-linux-for-industry)
- Click play on the video and if you using Chrome browser right click on player
  window and inspect this element. Result should look like that:

![img](/img/chrome-inspect1.png)

- Expand div tag marked in red on screenshot above. If video was start you
  should see video tag which contain two links to video files mp4 and webm.

These links are only temporary, so if you want to use them do it as soon as
possible. The sad part of all is that the organization intended to promote one
of the most libertarian solutions in software history does not provide materials
for download.

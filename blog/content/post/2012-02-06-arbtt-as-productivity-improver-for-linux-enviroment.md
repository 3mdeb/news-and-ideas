---
ID: 62675
title: arbtt as productivity improver for Linux environment
author: piotr.krol
post_excerpt: ""
layout: post
published: true
date: 2012-02-06 00:37:00
archives: "2012"
tags:
  - productivity
categories:
  - Miscellaneous
---

As I mentioned in previous
[post](http://pietrushnic.blogspot.com/2012/02/first-steps-to-improve-work.html)
I work a lot on improving my productivity. After FreeMind it is time for
[arbtt](http://darcs.nomeata.de/arbtt/doc/users_guide/). This is small tool
which tracks active windows during your work. It is delivered with distro that
I'm currently using (Debian wheezy). So all I had to do was:

```bash
sudo apt-get install arbtt
```

Below I try describe how I configure arbtt to work with some apps that I use
(Google Chrome, FreeMind, gnome-terminal and screen).

To effectively work with arbtt I had to run a daemon that collects information.
In this way, I found the first problem, namely, it is hard to find a website,
which correctly explains how to execute command during startup on Debian with
GNOME environment. After few tries I realize that I should focus on GNOME
autostart mechanism. This led me to create little file in
`$HOME/.config/autostart` which looks like that:

```bash
[Desktop Entry] Type=Application Encoding=UTF-8 Name=The Automatic Rule-Base Time Tracker Exec=arbtt-capture Terminal=false
```

So I had configured arbtt and it starts to capture data about my work. To
display this data in friendly manner arbtt-stat should be used. Application
complains if $HOME/.arbtt/categorize.cfg wasn't configured for it appropriate.
Detailed documentation about this file can be found on arbtt
[configuration page](http://darcs.nomeata.de/arbtt/doc/users_guide/configuration.html).
The process of writing this file should be iterative, starting point for me was:

- This defines some aliases, to make the reports look nicer:

```bash
aliases ( "sun-awt-X11-XFramePeer" -> "java" )
```

- A rule that probably everybody wants. Being inactive for over a minute causes
  this sample to be ignored by default.

```bash
$idle > 60 ==> tag inactive, current window $program == "sun-awt-X11-XFramePeer" && current window ($title =~ /(.+)\s-\sFreeMind/) ==> tag program:FreeMind-$1, current window $program == "gnome-terminal" && current window ($title =~ /(.+)/) ==> tag term:$1,
```

- Simple rule that just tags the current program

```bash
tag program:$current.program,
```

I'd like to know what web pages in google-chrome I'm working in. So I do not tag
necessarily by the active window title, but the title that contains the specific
string.

```bash
current window $program == "google-chrome" && any window ($program == "google-chrome" && $title =~ /(.+)\s-\sGoogle\sChrome/) ==> tag www:$1,
```

However, after creating a configuration file such statistics were displayed
correctly it was still a big problem to solve - how to combine arbtt with
gnome-terminal and screen. The first one requires only a correctly set the
window's name. Although the synchronization of the terminal window's name with a
window inside the screen was not a trivial task (primarily on the mass of broken
tutorials that can be found on the web). Finally my .screenrc looks like that:

```bash
termcapinfo xterm\* 'hs:ts=\E]0;:fs=\007:ds=\E]0;\007' defhstatus "[screen] ^Et" hardstatus off
# Set the scrollback length:
defscrollback 10000
# Select whether you want to see the copyright notice during startup:
startup\_message off
# Display a caption string below, appearing like tabs and # displaying the window number and application name (by default).
caption always caption string "%{= kG}[ %{G}%H %{g}][%= %{= kw}%?%-Lw%?%{r}(%{W}%n\*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B} %m-%d %{W}%c %{g}]" #"%{= kb}[ %=%{w}%?%-Lw%?%{b}(%{W}%n\*%f %t%?(%u)%?%{b})%{w}%?%+Lw%?%?%= %{b}][%{B} %H %{W}%l %{b}][%{B} %d.%m.%Y %{W}%0c %{b}]" #"%{bw}[%H] [%?%-Lw%?%{wb}%n\*%f%t%{bw}%?%+Lw%?]%=%{bw} [%1`] [%c:%s] [%l]" # "%{kw}%-w%{wr}%n %t%{-}%+w" defhstatus
```

set terminal title and caption keeps data about my open windows in screen.

Every time I open new window or change current one terminal title is updated.
For now that's all. In the future I wanted to write how to synchronize the title
of the window in the screen with vim editor to include information about the
currently edited file.

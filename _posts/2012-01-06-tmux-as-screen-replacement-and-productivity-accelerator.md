---
ID: 62781
post_title: >
  Tmux as screen replacement and
  productivity accelerator
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/tmux-as-screen-replacement-and-productivity-accelerator/
published: true
post_date: 2012-01-06 14:31:00
tags:
  - linux
  - tmux
  - productivity
  - termianl multiplexer
  - solarized
  - pipe-pane
categories:
  - Miscellaneous
---
As I wrote in [previous post][1] I switched from GNU screen to [tmux][2]. I use it for a few moths and have to said that I'm really impressed by simplicity, performance and community support in this project. In this post I want to discuss my configuration and useful additions for it like tmuxinator, session logging, colors or status bar configuration. 
### Basics Debian contain 

`tmux` package but for stable and testing release it is pretty old version. Personally I use `unstable` version where `tmux` was delivered in `1.7~svn2819-1` version. 
    sudo apt-get install tmux
     To start session simply type 

`tmux`. Tmux uses `C-b`/ `Ctrl-b` as a prefix for commands. If you switch from GNU screen then at the beginning you can experience some annoying situations but after few days everything should back to normal. Most used keybiddings: 
*   `C-b c` - create new window
*   `C-b ,` - rename current window
*   `C-b n` - next window
*   `C-b p` - previous window
*   `C-b l` - last window
*   `C-b d` - disconnect
*   `C-b k` - kill current window
*   `C-b K` - kill tmux server
*   `C-b [` - enter copy mode
*   `C-b ]` - paste last copied buffer
*   `C-b :` - tmux command line
*   `C-b w` - windows list
*   `C-b ?` - help Full list can be found 

[here][3]. 
### Configuration Tmux keeps its configuration in 

`$HOME/.tmux.conf`. My configuration mixes some tmux examples with code that I found in the net. This file can be found on my github repository [here][4]. First section contain some general configuration: 
    # confirm before killing a window or the server
    bind-key k confirm kill-window
    bind-key K confirm kill-server
    
    # toggle statusbar
    bind-key b set-option status
    
    # ctrl+left/right cycles thru windows
    bind-key -n C-right next
    bind-key -n C-left prev
    
    # scrollback buffer n lines
    set -g history-limit 10000
    
    # listen for activity on all windows
    set -g bell-action any
    
    # on-screen time for display-panes in ms
    set -g display-panes-time 2000
    
    # start window indexing at one instead of zero
    set -g base-index 1
    
    # enable wm window titles
    set -g set-titles on
    
    # wm window title string (uses statusbar variables)
    set -g set-titles-string "tmux.#I.#W"
    
    # statusbar 
    set -g display-time 2000
     After that I have implemented 

[solarized][5] colors (dark theme): 
    ### COLOUR (Solarized dark)
    
    # default statusbar colors
    set-option -g status-bg black #base02
    set-option -g status-fg yellow #yellow
    set-option -g status-attr default
    
    # default window title colors
    set-window-option -g window-status-fg brightblue #base0
    set-window-option -g window-status-bg default
    #set-window-option -g window-status-attr dim
    
    # active window title colors
    set-window-option -g window-status-current-fg brightred #orange
    set-window-option -g window-status-current-bg default
    #set-window-option -g window-status-current-attr bright
    
    # use vi-like keys
    setw -g mode-keys vi
    
    # pane border
    set-option -g pane-border-fg black #base02
    set-option -g pane-active-border-fg brightgreen #base01
    
    # message text
    set-option -g message-bg black #base02
    set-option -g message-fg brightred #orange
    
    # pane number display
    set-option -g display-panes-active-colour blue #blue
    set-option -g display-panes-colour brightred #orange
     To make solarized colors work on my setup was quite challenging, because there are many things to set (vim, terminal, putty etc.). If you need any advice I can write something about this. Right now it is beyond the scope of this post. At the end of my tmux configuration I've some fancy status bar: 

    # clock
    set-window-option -g clock-mode-colour green #green
    
    # center align the window list
    set -g status-justify centre
    
    # show some useful stats but only when tmux is started 
    # outside of Xorg, otherwise dwm statusbar shows these already
    set -g status-right ""
    set -g status-left ""
    if '[ -z "$DISPLAY" ]' 'set -g status-left "[#[fg=green] #H ][#[default]]"'
    if '[ -z "$DISPLAY" ]' 'set -g status-right "[ #[fg=magenta]#(cat /proc/loadavg | cut -d " " -f 1,2,3)#[default] ][ #[fg=cyan,bright]%a %Y-%m-%d %H:%M #[default]]"'
    if '[ -z "$DISPLAY" ]' 'set -g status-right-length 50'
     I think that mostly this is self explanatory. This how it look in work: 

![tmux-screen][6] 
### tmuxinator I spend some time to realize what is the best way of managing windows and panes in tmux. Especially I was interested in setting some windows at tmux startup. Finally I found 

[tmuxinator][7] small but useful project delivered through `gem` system. Follow tmuxinator page to set it up correctly. If you want to see my primitive configuration it is also available on my github in [werkspace project][4]. 
### Window logging Last hint I found on this 

[blog][8]. How to log your work in console for example to write a blog post :) ? There is a universal method for piping all console output to our program of choice. For example run command like this (command mode available under `C-b :`): 
    pipe-pane -o 'cat >> ~/tmuxcast.#h.#T'
     This will give you file with logged session output (all curses windows, editor windows and so on). Curses output can be unreadable because of control escape sequences. Use 

`cat` it will interpret escape sequences in terminal. As always I hope hints were useful. Please share this content if think its valuable. Comment if you think id needs improvements. Thank you for reading. P.S. I should probably create a footer with last paragraph :)

 [1]: /2013/03/19/debian-switching-to-unstable
 [2]: http://tmux.sourceforge.net
 [3]: http://www.openbsd.org/cgi-bin/man.cgi?query=tmux&sektion=1#KEY+BINDINGS
 [4]: https://github.com/pietrushnic/workspace/blob/master/dotfiles/tmux.conf
 [5]: http://ethanschoonover.com/solarized
 [6]: https://3mdeb.com/wp-content/uploads/2017/07/tmux-screen.png
 [7]: https://github.com/aziz/tmuxinator
 [8]: http://0xfeedface.org/blog/lattera/2012-03-19/using-tmux-screencasting-tool
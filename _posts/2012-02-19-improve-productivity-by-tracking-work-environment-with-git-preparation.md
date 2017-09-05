---
ID: 62685
post_title: 'Improve productivity by tracking work environment with git &#8211; preparation'
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/miscellaneous/improve-productivity-by-tracking-work-environment-with-git-preparation/
published: true
post_date: 2012-02-19 21:12:00
tags:
  - linux
  - productivity
categories:
  - Miscellaneous
---
_Update_: My repository is available 
[here](https://github.com/pietrushnic/workspace.git).

Below is first post from series in which I want to describe my experience gained 
in attempt to enhance my productivity by using git to control the contents of 
some files in my home directory. The first step to improve the productivity 
is good organization of working environment. It happens very often that I work 
on multiple machines both physical and virtual. Therefore I need a 
good mechanism to share knowledge, experience, code, configuration and many 
other things. Configuration described below is only an example that actually 
fits my way of working.  First of all simple concept of directory structure is 
needed. Let's start with:  
```
mkdir -p $HOME/workspace/blog;mkdir -p $HOME/workspace/dotfiles
cd workspace 
```

Write some files (i.e. for your blog) with your favourite editor, initialize 
repository and prepare first commit  
```
git init
git add .;git commit -m &quot;Initial commit for environment tracking&quot; 
```

To avoid information about untracked vim swp files add $HOME/workspace/.gitignore with following content:  
```
.gitignore
*.swp
```
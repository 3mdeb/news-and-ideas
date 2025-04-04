---
post_title: Sentrifugo as 3mdeb HRMS
author: Piotr Król
layout: post
published: true
post_date: 2018-08-07 16:00:00

tags:
	- hrms
categories:
	- Miscellaneous
---

3mdeb is small company and with limited resources, but have deal with typical
problems of growing company. Recently I faced challenges related with
management of over 20 people in 2 organizations and handling over 10 project at
the same time. Of course this quickly start to be overwhelming, so I started to
look for various options for HR tools that can help me offload some work. My
key requirement was that tool have to be open source and can be managed
internally by me and my team.

I think there are 2 viable options on the market [Odoo](https://www.odoo.com/)
and [Sentrifugo](http://www.sentrifugo.com/).

# Odoo

I'm using it as internal CMR just for tracking leads and how those get through
selling funnel, but in the past I faced a lot of problems with it.

* hard to find experts that have time to manage and deploy custom solution -
  most Odoo people I worked with are either not familiar with modern deployment
  environment (Ansible, Docker, AWS etc.) either overloaded with work
* we installed Odoo as standalone server dozen of times, but we always end up
  in crashes caused by installed/uninstalled/reinstalled modules - over time
  Odoo happen to be more of problem then gain, then we switched to free version
  served on odoo.com and it works quite good, of course any extension of free
  version cost amount of money that we cannot afford to pay
* last thing - Odoo is ERP system and not HRMS system, despite it has many
  modules, instead of glueing everything I decided to go try another solution

# Sentrifugo


# Proxmox

We have Proxmox on Xeon E5620 on which I created VM for serving Sentrifugo.

![]()


We use Proxmox VE from some time and truly also this solution doesn't impress
me (as well as Xen Server) and I'm thinking about migration to something that
can expose advanced hardware features - but maybe this is just my Embedded
Firmware mindset.

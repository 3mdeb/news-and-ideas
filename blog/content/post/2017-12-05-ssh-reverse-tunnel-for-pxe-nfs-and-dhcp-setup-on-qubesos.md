---
ID: 63687
title: >
  ssh reverse tunnel for PXE, NFS and DHCP
  setup on Qubes OS
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/ssh-reverse-tunnel-for-pxe-nfs-and-dhcp-setup-on-qubesos/
published: true
date: 2017-12-05 13:19:24
tags:
  - networking
  - PXE
  - QubesOS
  - nfs
  - iptables
  - ssh
categories:
  - OS Dev
---

At some point I stuck in the forest with WiFi connection and no physical access
to router to create nice networking for my coreboot development needs. Recently
I switched my laptop to Qubes OS what give interesting flexibility, but also
additional problems. My key requirement is to boot system over PXE, so I can
easily do kernel development and play with Xen. Because only available
connection for my apu2 platform was directly to my laptop I had to provide
configured DHCP server and PXE server on it. Qubes OS networking is quite
complex and to get to VM you have to pass-through at least `sys-net` VMs. Those
VMs requires `iptables` configuration to correctly pass traffic or some tricks
as I presented below. I don't think much people will face so weird
configuration, but I need following notes for myself and there is some chance
that someone will face similar issues. To summarize my target configuration was
like that:

![qubes-apu2-setup][1]

My initial idea was to have servers on AppVMs, but I didn't have enough time to
get through Qubes OS `iptables` rules. That led to discover interesting
alternative with `proxychains`, which I will describe later in this article.

## Qubes OS network configuration

Let's start with putting together DHCP server:

    git clone https://github.com/3mdeb/dhcp-server.git
    cd dhcp-server
     Please change your network interface in

`start.sh` it doesn't match. Currently set is `eno1` what may be good for Ubuntu
users. The only port that we have to forward for DHCP is 67.

### sys-net setup My routing table look like that:

    default via 192.168.8.1 dev wls6 proto static metric 600
    10.137.0.6 dev vif27.0 scope link metric 32725
    172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
    192.168.8.0/24 dev wls6 proto kernel scope link src 192.168.8.111 metric 600


`wls6` is my wireless interface. apu2 is connected over Ethernet cable using
`ens5` interface. Let's assign static IP to it:

    sudo ip addr add 192.168.42.1/24 dev ens5
     Routing was added automatically:

    default via 192.168.8.1 dev wls6 proto static metric 600
    10.137.0.6 dev vif27.0 scope link metric 32725
    172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
    192.168.8.0/24 dev wls6 proto kernel scope link src 192.168.8.111 metric 600
    192.168.42.0/24 dev ens5 proto kernel scope link src 192.168.42.1

After trying to correctly setup `iptables` in Qubes OS to forward traffic to vm
where DHCP and PXE/NFS containers were started I decided to give up. It would be
much easier to correctly setup `sys-net` for my development needs then spending
hours on figuring out what is wrong with my IP tables.

    git clone https://github.com/3mdeb/dhcp-server.git
    cd dhcp-server
     Adjust your

`dhcp.conf` and `start.sh` to network configuration. In my case it was modified
like below:

    diff --git a/start.sh b/start.sh
    index fb257be..6de7283 100755
    --- a/start.sh
    +++ b/start.sh
    @@ -14,6 +14,6 @@ docker run --rm --name dhcpserver --privileged --net=host
             -p 67:67/udp -p 67:67/tcp
             -v ${PWD}/data:/data
             -t -i 3mdeb/dhcp-server /bin/bash -c
    -        "bash /entrypoint.sh eno1;/bin/bash"
    +        "bash /entrypoint.sh ens5;/bin/bash"
     and

    diff --git a/data/dhcpd.conf b/data/dhcpd.conf
    index 961aef58068d..788d80577c1d 100644
    --- a/data/dhcpd.conf
    +++ b/data/dhcpd.conf
    @@ -1,4 +1,4 @@
    -subnet 192.168.0.0 netmask 255.255.255.0 {
    +subnet 192.168.42.0 netmask 255.255.255.0 {

            allow booting;
            allow bootp;
    @@ -7,29 +7,33 @@ subnet 192.168.0.0 netmask 255.255.255.0 {

            option domain-name "3mdeb.com";
            option subnet-mask 255.255.255.0;
    -   option broadcast-address 192.168.0.255;
    + option broadcast-address 192.168.42.255;
            option domain-name-servers 0.0.0.0;
    -   option routers 192.168.0.1;
    + option routers 192.168.42.1;

            # Group the PXE bootable hosts together
            group {
                    # PXE-specific configuration directives...
    -           next-server 192.168.0.109;
    -           filename "pxelinux.0";
    -           option root-path "/srv/nfs/freebsd";    
    +         # next-server 192.168.42.109;
    +         # filename "pxelinux.0";
    +         # option root-path "/srv/nfs/freebsd";        
                    # You need an entry like this for every host
                    # unless you're using dynamic addresses
                    host router {
                            hardware ethernet 00:02:72:41:35:87;
    -                   fixed-address 192.168.0.1;
    +                 fixed-address 192.168.42.1;
                    }
                    host pxeserver {
                            hardware ethernet B8:CA:3A:A2:1B:3E;
    -                   fixed-address 192.168.0.109;    
    +                 fixed-address 192.168.42.109;
                    }
                    host apu2 {
                            hardware ethernet 00:0D:B9:43:3F:BC;
    -                   fixed-address 192.168.0.101;
    +                 fixed-address 192.168.42.101;
    +         }
    +         host dhcp-server {
    +                 hardware ethernet C8:5B:76:D0:FD:62;
    +                 fixed-address 192.168.42.1;
                    }
            }
     }

On apu2 I booted to iPXE. I'm using `v4.6.3`.

    iPXE> dhcp net0
    Configuring (net0 00:0d:b9:43:3f:bc).................. ok
    PXE> show net0/ip
    net0.dhcp/ip:ipv4 = 192.168.42.101

Please note that MAC of my apu2 was already added to `dhcp.conf`. From that
place I can go to run my PXE and NFS container.

## PXE and NFS server

    git clone https://github.com/3mdeb/pxe-server.git
    cd pxe-server
    NFS_SRV_IP=192.168.42.1 ./init.sh
    ./start.sh

On iPXE side:

    chain https://192.168.42.1:8000/menu.ipxe

This gives couple options during boot:

    ---------------- iPXE boot menu ----------------
    ipxe shell                                                                  
    Debian stable netboot                                                       
    TODO:Debian stable netinst                                                  
    TODO:Debian testing netinst                                                 
    TODO:Debian testing netinst (UEFI-aware)
    TODO:Voyage

Probably more will be available overtime.

## Qubes OS ssh reverse tunnel and port forwarding

I had to resolve that problem just because of my lack of deep understanding of
`iptables` and ability to reconfigure Qubes OS sys-net routing to handle that
case. On the other hand below exercise was very engaging and for sure this
solution can be used in some situations in future. Problem is that my apu2
192.168.42.101 cannot access outside world. This is because its only connection
is to my laptop Ethernet port which is managed by sys-net VM and bunch of
`iptables` rules. Flushing whole `iptables` configuration was not a solution, so
I figured out how to create reverse ssh tunnel and use it to proxy whole traffic
from apu2. The solution came with this [stackoverflow answer][2]. What we doing
here is setting up SOCKS proxy and reverse SSH tunnel for apu2 traffic. On
sys-net I did:

    sudo passwd user #provide password
    ssh -f -N -D 54321 localhost
    ssh root@192.168.42.101 -R 6666:localhost:54321

Then on apu2:

    root@apu2:~# proxychains apt-get update
    ProxyChains-3.1 (http://proxychains.sf.net)
    0% [Working]|DNS-request| ftp.pl.debian.org
    |S-chain|-<>-127.0.0.1:6666-<><>-4.2.2.2:53-<><>-OK
    |DNS-response| ftp.pl.debian.org is 153.19.251.221
    |S-chain|-<>-127.0.0.1:6666-<><>-153.19.251.221:80-<><>-OK
    Ign:1 http://ftp.pl.debian.org/debian stable InRelease
    Hit:2 http://ftp.pl.debian.org/debian stable Release
    Reading package lists... Done

Please note that if, for some reason connection on sys-net will break then you
will have problem resolving DNS. To fix that you have to remove incorrect
default gateway. This have to be automated somehow on sys-net:

    sudo ip r del default via 192.168.42.1

## What we can do now?

You can use that configuration for many purposes, but my idea was to have Xen
dom0 booting over PXE and NFS. I will describe that in other blog post.

## Summary

I'm huge fan of Qubes OS and its approach to security. Unfortunately security
typically came with less convenience, what can be problem in some situations.
Nevertheless if you face some problems with Qubes OS, you need configuration or
enabling support or you are interested in freeing your hardware setup, please do
not hesitate to contact us. If you know how to reliably setup `iptables` in
above situation we would be glad to test it.

 [1]: https://3mdeb.com/wp-content/uploads/2017/07/qubes-apu2-setup.png
 [2]: https://serverfault.com/a/361806/68013

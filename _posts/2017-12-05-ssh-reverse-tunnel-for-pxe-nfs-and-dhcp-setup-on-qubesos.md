---
ID: 63687
post_title: >
  ssh reverse tunnel for PXE, NFS and DHCP
  setup on Qubes OS
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/ssh-reverse-tunnel-for-pxe-nfs-and-dhcp-setup-on-qubesos/
published: true
post_date: 2017-12-05 13:19:24
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
additional problems.

My key requirement is to boot system over PXE, so I can easily do kernel
development and play with Xen. Because only available connection for my apu2
platform was directly to my laptop I had to provide configured DHCP server and
PXE server on it. Qubes OS networking is quite complex and to get to VM you have
to pass-through at least <code>sys-net</code> VMs. Those VMs requires <code>iptables</code>
configuration to correctly pass traffic or some tricks as I presented below.

I don't think much people will face so weird configuration, but I need following
notes for myself and there is some chance that someone will face similar
issues.

To summarize my target configuration was like that:

<img src="https://3mdeb.com/wp-content/uploads/2017/07/qubes-apu2-setup.png" alt="qubes-apu2-setup" />

My initial idea was to have servers on AppVMs, but I didn't have enough time to
get through Qubes OS <code>iptables</code> rules. That led to discover interesting
alternative with <code>proxychains</code>, which I will describe later in this article.

<h2>Qubes OS network configuration</h2>

Let's start with putting together DHCP server:

<pre><code>git clone https://github.com/3mdeb/dhcp-server.git
cd dhcp-server
</code></pre>

Please change your network interface in <code>start.sh</code> it doesn't match. Currently
set is <code>eno1</code> what may be good for Ubuntu users.

The only port that we have to forward for DHCP is 67.

<h3>sys-net setup</h3>

My routing table look like that:

<pre><code>default via 192.168.8.1 dev wls6 proto static metric 600 
10.137.0.6 dev vif27.0 scope link metric 32725 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
192.168.8.0/24 dev wls6 proto kernel scope link src 192.168.8.111 metric 600 
</code></pre>

<code>wls6</code> is my wireless interface. apu2 is connected over Ethernet cable using
<code>ens5</code> interface. Let's assign static IP to it:

<pre><code>sudo ip addr add 192.168.42.1/24 dev ens5
</code></pre>

Routing was added automatically:

<pre><code>default via 192.168.8.1 dev wls6 proto static metric 600 
10.137.0.6 dev vif27.0 scope link metric 32725 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
192.168.8.0/24 dev wls6 proto kernel scope link src 192.168.8.111 metric 600 
192.168.42.0/24 dev ens5 proto kernel scope link src 192.168.42.1 
</code></pre>

After trying to correctly setup <code>iptables</code> in Qubes OS to forward traffic to vm
where DHCP and PXE/NFS containers were started I decided to give up. It would
be much easier to correctly setup <code>sys-net</code> for my development needs then
spending hours on figuring out what is wrong with my IP tables.

<pre><code>git clone https://github.com/3mdeb/dhcp-server.git
cd dhcp-server
</code></pre>

Adjust your <code>dhcp.conf</code> and <code>start.sh</code> to network configuration. In my case it
was modified like below:

<pre><code>diff --git a/start.sh b/start.sh
index fb257be..6de7283 100755
--- a/start.sh
+++ b/start.sh
@@ -14,6 +14,6 @@ docker run --rm --name dhcpserver --privileged --net=host
         -p 67:67/udp -p 67:67/tcp 
         -v ${PWD}/data:/data 
         -t -i 3mdeb/dhcp-server /bin/bash -c 
-        "bash /entrypoint.sh eno1;/bin/bash"
+        "bash /entrypoint.sh ens5;/bin/bash"
</code></pre>

and

<pre><code>diff --git a/data/dhcpd.conf b/data/dhcpd.conf
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
</code></pre>

On apu2 I booted to iPXE. I'm using <code>v4.6.3</code>.

<pre><code>iPXE&gt; dhcp net0
Configuring (net0 00:0d:b9:43:3f:bc).................. ok
PXE&gt; show net0/ip
net0.dhcp/ip:ipv4 = 192.168.42.101
</code></pre>

Please note that MAC of my apu2 was already added to <code>dhcp.conf</code>.

From that place I can go to run my PXE and NFS container.

<h2>PXE and NFS server</h2>

<pre><code>git clone https://github.com/3mdeb/pxe-server.git
cd pxe-server
NFS_SRV_IP=192.168.42.1 ./init.sh
./start.sh
</code></pre>

On iPXE side:

<pre><code>chain https://192.168.42.1:8000/menu.ipxe
</code></pre>

This gives couple options during boot:

<pre><code>---------------- iPXE boot menu ----------------
ipxe shell                                                                  
Debian stable netboot                                                       
TODO:Debian stable netinst                                                  
TODO:Debian testing netinst                                                 
TODO:Debian testing netinst (UEFI-aware)
TODO:Voyage
</code></pre>

Probably more will be available overtime.

<h2>Qubes OS ssh reverse tunnel and port forwarding</h2>

I had to resolve that problem just because of my lack of deep understanding of
<code>iptables</code> and ability to reconfigure Qubes OS sys-net routing to handle that
case. On the other hand below exercise was very engaging and for sure this
solution can be used in some situations in future.

Problem is that my apu2 192.168.42.101 cannot access outside world. This is
because its only connection is to my laptop Ethernet port which is managed by
sys-net VM and bunch of <code>iptables</code> rules. Flushing whole <code>iptables</code>
configuration was not a solution, so I figured out how to create reverse ssh
tunnel and use it to proxy whole traffic from apu2.

The solution came with this <a href="https://serverfault.com/a/361806/68013">stackoverflow answer</a>. What we doing here is setting
up SOCKS proxy and reverse SSH tunnel for apu2 traffic. On sys-net I did:

<pre><code>sudo passwd user #provide password
ssh -f -N -D 54321 localhost
ssh root@192.168.42.101 -R 6666:localhost:54321
</code></pre>

Then on apu2:

<pre><code>root@apu2:~# proxychains apt-get update
ProxyChains-3.1 (http://proxychains.sf.net)
0% [Working]|DNS-request| ftp.pl.debian.org 
|S-chain|-&lt;&gt;-127.0.0.1:6666-&lt;&gt;&lt;&gt;-4.2.2.2:53-&lt;&gt;&lt;&gt;-OK
|DNS-response| ftp.pl.debian.org is 153.19.251.221
|S-chain|-&lt;&gt;-127.0.0.1:6666-&lt;&gt;&lt;&gt;-153.19.251.221:80-&lt;&gt;&lt;&gt;-OK
Ign:1 http://ftp.pl.debian.org/debian stable InRelease
Hit:2 http://ftp.pl.debian.org/debian stable Release
Reading package lists... Done
</code></pre>

Please note that if, for some reason connection on sys-net will break then you
will have problem resolving DNS. To fix that you have to remove incorrect
default gateway. This have to be automated somehow on sys-net:

<pre><code>sudo ip r del default via 192.168.42.1
</code></pre>

<h2>What we can do now ?</h2>

You can use that configuration for many purposes, but my idea was to have Xen
dom0 booting over PXE and NFS. I will describe that in other blog post.

<h2>Summary</h2>

I'm huge fan of Qubes OS and its approach to security. Unfortunately security
typically came with less convenience, what can be problem in some situations.
Nevertheless if you face some problems with Qubes OS, you need configuration or
enabling support or you are interested in freeing your hardware setup, please
do not hesitate to contact us.

If you know how to reliably setup <code>iptables</code> in above situation we would be
glad to test it.
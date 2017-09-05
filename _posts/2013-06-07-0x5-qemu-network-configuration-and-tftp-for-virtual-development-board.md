---
ID: 62831
post_title: '0x5: Qemu network configuration and tftp for Virtual Development Board'
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/0x5-qemu-network-configuration-and-tftp-for-virtual-development-board/
published: true
post_date: 2013-06-07 10:36:00
tags:
  - qemu
  - embedded
  - tftp
  - networking
  - VDB
categories:
  - OS Dev
  - App Dev
---
## Table of contents ##

* [Introduction](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/#intro)
* [Setup tftpd](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/#setup-tftpd)
* [QEMU networking](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/#qemu-networking)
* [Verify all components of Virtual Development Platform](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/#verify-qemu-with-tftp)
* [What next ?](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/#what-next)


<a id="intro"></a>
### Introduction ###
This was not trivial task to me. As usual `google is your friend` and `RTFM` works.
First we will set tftp which we use to download modified kernel for U-Boot.
Second I will show how to setup bridged network for QEMU needs and finally we
will perform some basic test of our setup. Let's go.

<a id="setup-tftpd"></a>
### Setup tftpd ###
First install:
```bash
sudo apt-get install tftpd tftp
```
Make sure that `/srv/tftp` is writable for your user. If directory doesn't exist 
create it and give needed privileges. If you want to change some server options 
edit `/etc/inetd.conf`. Copy or link our kernel to tftp server
directory.
```bash
cd /path/to/kernel/arch/arm/boot
ln -s $PWD/uImage /srv/tftp/uImage
```
Verify if everything works correctly:
```bash
cd             # go to home or any other directory different than arch/arm/boot
tftp 127.0.0.1 # connect to localhost tftp server
get uImage     # get kernel file
q              # quit tftp
```
Check if kernel file is in current directory. If yes than you tftp server is 
configured correctly, if not then google or ask me a question in comments 
section.
_Note_: For Ubuntu follow instructions from 
[here](http://www.davidsudjiman.info/2006/03/27/installing-and-setting-tftpd-in-ubuntu/).

<a id="qemu-networking"></a>
### QEMU networking ###
_Update_: For Ubuntu users please read [this section](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/#ubuntu-issues)

I mixed [this](http://toast.djw.org.uk/qemu.html) BKM and few other resources
that I found in the net. Setting up network depend a lot on your configuration.
I will briefly describe my situation. It is quite possible that this won't fit 
yours.

I've `eth0` with ip `10.0.2.15`. What I want to do is create another interface `tap0` and
bridge `br0` that will connect `eth0` and `tap0`. To do this I need few things:

* `brctl` is provided in Debian by `bridge-utils`
```
sudo apt-get install bridge-utils
```
* check if TUN module was installed
```
grep CONFIG_TUN= /boot/config-`uname -r`
```
you should get `y` or `m`, if it is `m` than `modprobe tun`:
```
sudo modprobe tun
```
* create tun device
```
sudo mknod /dev/net/tun c 10 200
```
* update `/etc/network/interfaces`:
```bash
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# add br0 configuration
auto br0
iface br0 inet dhcp
bridge_ports eth0 # do not forget to attach eth0 to br0
bridge_fd 9
bridge_hello 2
bridge_maxage 12
bridge_stp off

# The primary network interface
allow-hotplug eth0     # comment this
iface eth0 inet dhcp   # and this
```
* use `/etc/qemu-ifup` script to bring up your network:
```bash
#!/bin/sh

echo &quot;Executing /etc/qemu-ifup&quot;
echo &quot;Bringing up $1 for bridged mode...&quot;
sudo /sbin/ifconfig $1 0.0.0.0 promisc up
echo &quot;Adding $1 to br0...&quot;
sudo /sbin/brctl addif br0 $1
sleep 2
```

Give executable permissions for this file:
```
sudo chmod +x /etc/qemu-ifup
```

Restart networking services locally:
```
sudo service networking restart
```

This should prepare you environment for tftp booting in qemu.

<a id="ubuntu-issues"></a>
#### Ubuntu issues ####
I had experienced few problems with my Ubuntu 12.04. 

* First thing was defect that cause looping u-boot during emulation in 
  qemu-system-arm. I checked latest qemu and version delivered in distro 
  repository but qemu wasn't issue. I tried debug problem with gdb and qemu
  `-s -S` switches and find out that u-boot crashes at `__udivsi3` instruction 
  in `serial_init`. I tried to google this issue but found only one comment 
  about this on [Balau blog](http://balau82.wordpress.com/2010/04/12/booting-linux-with-u-boot-on-qemu-arm/):
  {% blockquote [Grant Likely]%}
  For anyone trying to reproduce this, at least on a recent Ubuntu host, you may need to pass ?-cpu all? or ?-cpu cortex-a8? to qemu. The libgcc that gets linked to u-boot appears to be compiled with thumb2 instructions which are not implemented in the Versatile cpu. I don?t get any u-boot console output without this flag, and using gdb I can see that the cpu takes an exception during `__udivsi3()` called from serial_init().
  {% endblockquote %}
  Problem is at least 2-years old and still occurs. Unfortunately Grant's tricks 
  didn't help. I move to toolchain built by my own and problem was fixed. So the 
  moral of the story is: DO NOT USE TOOLCHAIN PROVIDED BY UBUNTU at least in 
  12.04.

* Second thing also involve a lot of debugging time and when I found workaround 
  it was accidentally. I saw that using procedure correct for Debian on Ubuntu I 
  was unable to obtain any packet inside U-Boot. Network traffic analysis show 
  that U-Boot correctly send DHCP discovery and server reply with DHCP offer, 
  but bootloader behaves like no packet was received.  Static configuration also 
  didn't work. Finally I get to information how to capture traffic from inside 
  of emulated setup (parameter `-net dump,file=/path/to/file.pcap` do the 
  thing). Surprisingly for some reason adding dump param fix problem and U-Boot
  received DHCP Offer and ACK. I will try to narrow down this problem for 
  further reading please take a look [qemu](http://lists.nongnu.org/archive/html/qemu-discuss/2013-05/msg00013.html) 
  and [u-boot]() mailing list thread.

<a id="verify-qemu-with-tftp"></a>
#### Verify all components of Virtual Development Platform ####

So right now we should have built [kernel uImage](/2013/06/07/linux-kernel-for-embedded-system), [U-Boot image](/2013/06/07/embedded-board-bootloader),
[configured qemu network](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/#qemu-networking) and [tftp server](/2013/06/07/qemu-network-configuration-and-tftp-for-virtual-development-board/#setup-tftpd). With all this components we can 
verify if our kernel booting on emulated `versatilepb`.

Run your qemu with network using U-Boot image as a kernel.
```bash
sudo qemu-system-arm -kernel /path/to/u-boot/u-boot -net nic,vlan=0 -net tap,vlan=0,ifname=tap0,script=/etc/qemu-ifup -nographic -M versatilepb
```
_NOTE_: We want to use u-boot file instead of u-boot.bin. First is ELF binary 
image and second is raw binary. Raw binary image can be used with `-bios`
parameter for qemu. If you try to give raw binary as a kernel parameter it will result with error:
```
qemu: fatal: Trying to execute code outside RAM or ROM at 0x08000000
```
_NOTE 2_: We have to specify `versatilepb` machine. If we forget it we will get 
error:
```
qemu: hardware error: integratorcm_read: Unimplemented offset 0x1e0000
```

Right now we have u-boot booted. Let's set ip addresses to boot uImage from our 
tftp server. For verification needs we don't want to `autoload` downloaded 
image, so we disable this through environment variable.
```bash
setenv autoload no
dhcp
setenv serverip 192.168.1.2
setenv bootfile uImage
tftpboot
```
Set addresses according to your configuration. For some reason I was unable to 
use u-boot `dhcp` feature. It assign me address that exist in the network.

We can take a close look on out downloaded image with `iminfo` command. 
`tftpboot` and `iminfo` should looks like that:
```
VersatilePB # tftpboot
SMC91111: PHY auto-negotiate timed out
SMC91111: MAC 52:54:00:12:34:56
Using SMC91111-0 device
TFTP from server 10.0.2.15; our IP address is 10.0.2.16
Filename &#039;uImage&#039;.
Load address: 0x7fc0
Loading: #################################################################
         #################################################################
         #################################################################
         #################################################################
         #################################################################
         ##############################################
         0 Bytes/s
done
Bytes transferred = 
1895064 (1cea98 hex)
VersatilePB # iminfo

## Checking Image at 
00007fc0 ...
    Legacy image found
    Image Name:   Linux-3.9.0-rc8
    Image Type:   ARM Linux Kernel Image (uncompressed)
    Data Size:    1895000 Bytes = 1.8 MiB
    Load Address: 00008000
    Entry Point:  00008000
    Verifying Checksum ... OK
```

So, that what we want to see. Pretty new kernel `3.9.0-rc8` compiled as ARM 
image. We can try to boot it but we will end with kernel panic because lack of 
filesystem.

_NOTE 3_: If you want to see anything after booting this image with `bootm` you 
have to pass to kernel additional boot argument with serial device that should 
be used as a console. Before `bootm` set:
```
setenv bootargs console=ttyAMA0
```
You should get something similar to below log:
```
(...)
eth0: SMC91C11xFD (rev 1) at c89c8000 IRQ 57 [nowait]
eth0: Ethernet addr: 52:54:00:12:34:56
mousedev: PS/2 mouse device common for all mice
TCP: cubic registered
NET: Registered protocol family 17
VFP support v0.3: implementor 41 architecture 1 part 10 variant 9 rev 0
VFS: Cannot open root device &quot;(null)&quot; or unknown-block(0,0): error -6
Please append a correct &quot;root=&quot; boot option; here are the available partitions:
1f00           65536 mtdblock0  (driver?)
Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
[&lt;c0018afc&gt;] (unwind_backtrace+0x0/0xf0) from [&lt;c027af8c&gt;] (panic+0x80/0x1d0)
[&lt;c027af8c&gt;] (panic+0x80/0x1d0) from [&lt;c0343c64&gt;] (mount_block_root+0x1a0/0x258)
[&lt;c0343c64&gt;] (mount_block_root+0x1a0/0x258) from [&lt;c0343f08&gt;] (mount_root+0xf0/0x118)
[&lt;c0343f08&gt;] (mount_root+0xf0/0x118) from [&lt;c0344090&gt;] (prepare_namespace+0x160/0x1b4)
[&lt;c0344090&gt;] (prepare_namespace+0x160/0x1b4) from [&lt;c03438ec&gt;] (kernel_init_freeable+0x168/0x1ac)
[&lt;c03438ec&gt;] (kernel_init_freeable+0x168/0x1ac) from [&lt;c027a074&gt;] (kernel_init+0x8/0xe4)
[&lt;c027a074&gt;] (kernel_init+0x8/0xe4) from [&lt;c0013df0&gt;] (ret_from_fork+0x14/0x24)
```
This is expected result. 

<a id="what-next"></a>
### What next ?###
We happily built basic virtual development, what we need right now is some 
[initial filesystem](/2013/06/07/root-file-system-for-embedded-system).
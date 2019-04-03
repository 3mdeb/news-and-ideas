---
ID: 62881
title: Linux, RPi and USB over IP
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/linux-rpi-and-usb-over-ip/
published: true
date: 2014-08-18 21:26:37
tags:
  - linux
  - Raspberry Pi
  - USB
  - Broadcom
categories:
  - Firmware
---
Trying to google 'USB over IP' doesn't give much except some business web pages that give you it as a service. This brings some information about potential on the market IMHO. Main idea is well presented on open source project page for [usbip][1]. I really recommend to read [USB/IP - a Peripheral Bus Extension for Device Sharing over IP Network][2] technical paper it describe briefly technical details and capability. In short USB over IP is a sharing system aim to expose USB devices from server to client encapsulating USB I/O messages in TCP/IP payload. `usbip` contain client and server side (called stub and VHCI (*Virtual Host Controller Interface*). Stub is used on server side to hijack USB traffic from/to connected device and send/receive it over the network. VHCI expose stubbed device on client side and also send and receive data to/from server. We can say that stub-VHCI pair working as intermediate layer in USB stack, giving ability to connect over the netowork. `usbip` project provided both Linux and Windows version. In mid of 2008 `usbip` was introduced to Linux kernel and matured a while in staging directory. Few days ago I read [this][3] were Greg KH mention that if it will be possible he will include `usbip` in `3.17-rc2`. As you can expect the biggest problem with USB over IP is how to handle 480Mbit/s (USB2.0) or more over TCP/IP payload. The answer is it can't. Recommended use case for `usbip` is LAN environment with low latency. Of course you can try to use it over long distance but you will get best effort, which varies according to device and application profile. Author of the idea (Takahiro Hirofuchi) tested his solution and created some models for queue management for different devices - you can read about it in technical paper. Below I present Kingston USB stick test in function of delay. 
## Seting up usbip What I tried to do was setting up my Rasberry Pi and connect it through my home LAN to share USB device (Kingston DataTraveler). My configuration looks like that: 

![usbip-rate][4] First I installed latest [Raspbian][5]. Assuming SD card is `/dev/sdb`: 
    sudo dd bs=4M if=2014-06-20-wheezy-raspbian.img of=/dev/sdb
     With fresh SD card we can boot and push finish on initial setup screen. If you have DHCP set on your router that's great if not you have to manually configure network inside RPi. 

### usbip kernel modules for RPi

`usbip` package is available in Raspbian default repository. Fortunately for our learning purposes, `usbip-core.ko` and `usbip-host.ko` modules are not compiled in the kernel. What you can see when trying to run `usbipd`: 
    usbipd: error: please load usbip-core.ko and usbip-host.ko!
     Let's see if support for USBIP is in kernel: 

    pi@raspberrypi /boot $ zcat /proc/config.gz |grep USBIP
    # CONFIG_USBIP_CORE is not set
     Compiling Linux kernel on RPi can take number of hours. I saw different values like 5-6, 10 and even 22. It depends on many factors. But we should not bother and try to cross compile RPi on development machine. I will use my Y510P laptop with i7 4700MQ 2.4GHz (4 cores). 

    git clone https://github.com/raspberrypi/tools tools-rpi
    git clone --depth=1 https://github.com/raspberrypi/linux linux-rpi
    export PATH=${PWD}/tools-rpi/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin:${PATH}
    cd linux-rpi
    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig
    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
     I compiled kernel on 

`3.12.y` branch. Go to `Device Drivers -> Staging drivers ->
USB/IP support`. I choose to compile usbip-core as loadable module. `Device Drivers->
Staging drivers -> USB/IP support -> Host driver` also is needed it compiles usbip-host module. Optionally `Debug messages for USB/IP` can be set if you want to see kernel debug messages from driver. After saving changes to config file we can start compilation: 
    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j8
     After finishing compilation we can move our image to SD card. First mount your SD card (it won't automatically) and run compile modules with correct install path. 

    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=/media/sdb2 modules
    sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=/media/sdb2 modules_install
    sudo cp /media/sdb1/kernel.img /media/sdb1/kernel-backup.img
    sudo cp arch/arm/boot/Image /media/sdb1/kernel.img
    sudo umount /dev/sdb1
    sudo umount /dev/sdb2
     Now we can connect card to RPi and boot it to check if new kernel was correctly loaded. 

### Running usbip on RPi Now on RPi we can load modules needed for 

`usbipd` and run it: 
    sudo modprobe usbip-core
    sudo modprobe usbip-host
    sudo usbipd -D
     To what USB devices are connected to our system we can use: 

    usbip list -l
     This will show output similar to this: 

    Local USB devices
    =================
     - busid 1-1 (0424:9514)
             1-1:1.0 -> hub
    
     - busid 1-1.1 (0424:ec00)
             1-1.1:1.0 -> smsc95xx
    
     - busid 1-1.2 (0951:1625)
             1-1.2:1.0 -> usbip-host
    

`busid 1-1.2 (0951:1625)` is my Kingstone pendrive. If you are unsure which busid is for device that you want to share compare device id and vendor id with output of `lsusb`. To bind device to `usbip-host.ko` we should use: 
    pi@raspberrypi ~ $ sudo usbip --debug bind -b 1-1.2
    usbip: debug: /build/linux-tools-TqR1ks/linux-tools-3.2.17/drivers/staging/usbip/userspace/src/usbip.c:134:[run_command] running command: `bind'
    usbip: debug: /build/linux-tools-TqR1ks/linux-tools-3.2.17/drivers/staging/usbip/userspace/src/usbip_bind.c:162:[unbind_other] 1-1.2:1.0 -> usb-storage
    usbip: debug: /build/linux-tools-TqR1ks/linux-tools-3.2.17/drivers/staging/usbip/userspace/src/utils.c:65:[modify_match_busid] write "add 1-1.2" to /sys/bus/usb/drivers/usbip-host/match_busid
    bind device on busid 1-1.2: complete
     As you can see communication to 

`usbip-host` module is through writing into sysfs file. *NOTE* : if you will try to bind device without root privileges or when modules are not loaded you will get errors like below: 
    pi@raspberrypi ~ $ usbip bind -b 1-1.2
    usbip: error: could not unbind driver from device on busid 1-1.2
    pi@raspberrypi ~ $ sudo usbip bind -b 1-1.2
    usbip: error: unable to bind device on 1-1.2
    

### usbip - client side Our device should wait for communication. Let's go to client side of our LAN and try to check if we can use our USB device. To check if device is available: 

    [22:29:37] pietrushnic:~ $ sudo usbip list -r 192.168.1.3
    Exportable USB devices
    ======================
     - 192.168.1.3
          1-1.2: Kingston Technology : DataTraveler 101 II (0951:1625)
               : /sys/devices/platform/bcm2708_usb/usb1/1-1/1-1.2
               : (Defined at Interface level) (00/00/00)
               :  0 - Mass Storage / SCSI / Bulk-Only (08/06/50)
     Where 

`192.168.1.3` is an IP of RPi. Everything seems to be ok. So let's try to attach it and do some test: 
    [22:31:11] pietrushnic:~ $ sudo usbip attach -r 192.168.1.3 -b 1-1.2 
    usbip: error: open vhci_driver
    usbip: error: query
     Oops, looks like we don't have driver for client side. Let's see if it is compiled in my kernel as module: 

    grep USBIP /boot/config-`uname -r`
    CONFIG_USBIP_CORE=m
    CONFIG_USBIP_VHCI_HCD=m
    CONFIG_USBIP_HOST=m
    # CONFIG_USBIP_DEBUG is not set
     Great so we can load 

`vhci-hcd`: 
    sudo modprobe vhci-hcd
     And attach pendriver from RPi. What we have to use is IP address and bus id. 

    sudo usbip attach -r 192.168.1.3 -b 1-1.2
     In dmesg we can find information about our device. 

    [  676.126820] usbip_core: module is from the staging directory, the quality is unknown, you have been warned.
    [  676.127246] usbip_core: USB/IP Core v1.0.0
    [  676.127964] vhci_hcd: module is from the staging directory, the quality is unknown, you have been warned.
    [  676.128336] vhci_hcd vhci_hcd: USB/IP Virtual Host Controller
    [  676.128341] vhci_hcd vhci_hcd: new USB bus registered, assigned bus number 5
    [  676.128493] usb usb5: New USB device found, idVendor=1d6b, idProduct=0002
    [  676.128495] usb usb5: New USB device strings: Mfr=3, Product=2, SerialNumber=1
    [  676.128497] usb usb5: Product: USB/IP Virtual Host Controller
    [  676.128498] usb usb5: Manufacturer: Linux 3.14-2-amd64 vhci_hcd
    [  676.128499] usb usb5: SerialNumber: vhci_hcd
    [  676.128603] hub 5-0:1.0: USB hub found
    [  676.128607] hub 5-0:1.0: 8 ports detected
    [  676.128732] vhci_hcd: USB/IP 'Virtual' Host Controller (VHCI) Driver v1.0.0
    [  676.228522] vhci_hcd: changed 0
    [  694.052076] vhci_hcd vhci_hcd: rhport(0) sockfd(3) devid(65540) speed(3)
    [  694.052289] vhci_hcd: changed 1
    [  694.158844] vhci_hcd: changed 0
    [  694.267024] usb 5-1: new high-speed USB device number 2 using vhci_hcd
    [  694.491154] usb 5-1: new high-speed USB device number 3 using vhci_hcd
    [  694.715339] usb 5-1: new high-speed USB device number 4 using vhci_hcd
    [  694.715356] usb 5-1: SetAddress Request (4) to port 0
    [  694.758246] usb 5-1: New USB device found, idVendor=0951, idProduct=1625
    [  694.758251] usb 5-1: New USB device strings: Mfr=1, Product=2, SerialNumber=3
    [  694.758252] usb 5-1: Product: DT 101 II
    [  694.758254] usb 5-1: Manufacturer: Kingston
    [  694.758255] usb 5-1: SerialNumber: 001CC0EC3519EA51A0000017
    [  694.809487] usb-storage 5-1:1.0: USB Mass Storage device detected
    [  694.809582] scsi6 : usb-storage 5-1:1.0
    [  694.809660] usbcore: registered new interface driver usb-storage
    [  695.816239] scsi 6:0:0:0: Direct-Access     Kingston DT 101 II        PMAP PQ: 0 ANSI: 0 CCS
    [  695.816627] sd 6:0:0:0: Attached scsi generic sg2 type 0
    [  695.825894] sd 6:0:0:0: [sdb] 7815168 512-byte logical blocks: (4.00 GB/3.72 GiB)
    [  695.833602] sd 6:0:0:0: [sdb] Write Protect is off
    [  695.833616] sd 6:0:0:0: [sdb] Mode Sense: 03 41 00 00
    [  695.841427] sd 6:0:0:0: [sdb] No Caching mode page found
    [  695.841440] sd 6:0:0:0: [sdb] Assuming drive cache: write through
    [  695.883028] sd 6:0:0:0: [sdb] No Caching mode page found
    [  695.883044] sd 6:0:0:0: [sdb] Assuming drive cache: write through
    [  695.903869]  sdb: sdb1 sdb2 < sdb5 >
    [  695.941208] sd 6:0:0:0: [sdb] No Caching mode page found
    [  695.941211] sd 6:0:0:0: [sdb] Assuming drive cache: write through
    [  695.941214] sd 6:0:0:0: [sdb] Attached SCSI removable disk
     Device show correct informations in 

`lsusb` output and `/proc/partitions`. 
## Testing usbip From technical paper that I mentioned above I understand that probably the most important factor for 

`usbip` performance is latency. Simplest method to emulate WAN delays is `tc` from `iproute2` package. It is available by as default tool in Raspbian: 
    sudo tc qdisc add dev eth0 root netem delay 100ms #add device and set delay
    sudo tc qdisc change dev eth0 root netem delay 10ms #change delay
     To test read speed I used 

`dd` by simply: 
     sudo dd if=/dev/sdb of=/dev/null bs=1M count=5
     So I tried few values with my Kingston pendrive: 

       0ms : 1.7 MB/s
      10ms : 968 kB/s
      20ms : 652 kB/s
      30ms : 495 kB/s
      40ms : 394 kB/s
      50ms : 344 kB/s
     100ms : 177 kB/s
     200ms : 86.0 kB/s
     300ms : 67.5 kB/s
     400ms : 38.1 kB/s
     500ms : 30.6 kB/s
    1000ms : 15.9 kB/s
     And something from 

`gnuplot` noob: ![usbip-rate][4] 
### Cleanup Before we can disconnect device from RPi we have do few things. First detach port to which remote device was connected. Which port ? 

    sudo usbip port
     Next detach device you want to disconnect: 

    sudo usbip detach -p 0
     Finally on RPi you can unbind device: 

    sudo usbip unbind -b 1-1.2
     Now device can be removed. 

## Other devices With various results I tried other devices. 

### Android phone I also tried to connect my Samsung GT-I9070. Unfortunately without luck: 

    hub 5-0:1.0: Cannot enable port 1.  Maybe the USB cable is bad?
    hub 5-0:1.0: unable to enumerate USB device on port 1
     I think it could be related with fact that my smartphone expose multiple devices over one USB connection. What can be observed on 

`usbip` list: 
     - busid 1-1.2 (04e8:6860)
             1-1.2:1.0 -> unknown
             1-1.2:1.1 -> cdc_acm
             1-1.2:1.2 -> cdc_acm
     I see this as opportunity to debug, understand and fix the driver. 

### Arduino There was no problem with Arduino. I was even able to program it successfully. Unfortunately to big delay (in my case 300ms) cause software errors: 

    Binary sketch size: 1,056 bytes (of a 30,720 byte maximum)
    
    avrdude: stk500_getparm(): (a) protocol error, expect=0x14, resp=0x14
    
    avrdude: stk500_getparm(): (a) protocol error, expect=0x14, resp=0x01
    avrdude: stk500_initialize(): (a) protocol error, expect=0x14, resp=0x10
    avrdude: initialization failed, rc=-1
             Double check connections and try again, or use -F to override
             this check.
    

## Summary Looks like 

`usbip` is usable in low delay network. It would be great to test it in real WAN. It is possible to use `usbip` with more sophisticated devices but potential driver tweaking is required. As a telecommunication graduate I cannot say about possible improvements in queue algorithms, like adaptive queueing which depends on data transfer profile. It was interesting experience to play with `usbip` and probably I will back to it especially to testing part of this post. If you have questions, suggestions or comments please let me know.

 [1]: http://usbip.sourceforge.net/
 [2]: https://www.usenix.org/legacy/events/usenix05/tech/freenix/hirofuchi.html
 [3]: http://thread.gmane.org/gmane.linux.kernel/1763771
 [4]: https://3mdeb.com/wp-content/uploads/2017/07/usbip-rate.png
 [5]: http://www.raspberrypi.org/downloads/
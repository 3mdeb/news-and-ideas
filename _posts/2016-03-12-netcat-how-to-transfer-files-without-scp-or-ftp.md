---
ID: 62941
post_title: 'Netcat &#8211; how to transfer files without scp or ftp'
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/app-dev/netcat-how-to-transfer-files-without-scp-or-ftp/
published: true
post_date: 2016-03-12 15:19:44
tags:
  - linux
  - networking
categories:
  - App Dev
---
One of my recent customers provided me hardware with custom Linux system. Distribution used on this hardware was very limited there was no developers tools, file transfer applications (like scp, ftp or even tftp) or communication clients like ssh. I had to deploy some firmware files to the system without modifying it. This was i386 machine. Of course I could compile something and add this software using usb stick or other stoarge, but what if I would not have direct access to hardware ? Also for development and testing purposes it would be much easier to use network transfer, then running with usb stick. When looking for answer I found [this][1]. I heard before about netcat, but more in context of debugging then using it as file transfer application. Luckily `nc` as very small tool is in almost all distributions and it was also available in my small custom distro. 
## File transfer with netcat

`nc` by man page is described as *TCP/IP swiss army knife* , but can be used to transfer files. What have to be done is setting receiving side ie.: 
    nc -l -p 2020 > my_file.bin
     What tell 

`nc` to listen on inbound connection (`-l`) on port 2020 (`-p 2020`) and redirect content of incoming packages to `my_file.bin`. On sender side we pipe `my_file.bin` to nc like that: 
    cat my_file.bin | nc <dest_ip_addr> 2020
     Which cause 

`nc` to create TCP connection to `<dest_ip_addr>` on port `2020` and send everything it gets on standard input. 
## Known flaws From what I saw sometimes 

`nc` doesn't end at `EOF` and just hang waiting for next data, which never come. In that case I just break with `Ctrl-C` on both ends. Then check if all stuff was transfered correctly by verifying MD5 sum on sender and receiver side. In most cases files pass this integrity test.

 [1]: http://stackoverflow.com/questions/17797758/using-nc-to-transfer-large-file
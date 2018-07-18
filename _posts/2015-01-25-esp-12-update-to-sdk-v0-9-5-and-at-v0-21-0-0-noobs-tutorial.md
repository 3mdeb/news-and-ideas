---
ID: 62906
post_title: >
  ESP-12 update to SDK v0.9.5 and AT
  v0.21.0.0 ? noobs tutorial
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/esp-12-update-to-sdk-v0-9-5-and-at-v0-21-0-0-noobs-tutorial/
published: true
post_date: 2015-01-25 22:32:01
tags:
  - embedded
  - ESP8266
  - Espressify
categories:
  - Firmware
  - IoT
---
January 23th Espressif published new ESP IOT SDK on their forum [v0.9.5][1]. My ESP-12 came with with pretty old version so I decide to update it to latest one: 
    AT+RST
    
    OK
    y_RSöfJ[úndor:www.ai-thinker.com Version:0.9.2.4]
    
    ready
    AT+GMR
    0018000902-AI03
    
    OK
    

## ESP-12 firmware update pin configuration

![esp-12-update][2] As picture presents in addition to normal operation we have to pull down GPIO0 and pull up GPIO2. 
## Upgrade using binaries from Espressif To upgrade you can use binaries that where delivered in zip packaged and python 

[esptool](). Run following commands: 
    git clone git@github.com:themadinventor/esptool.git
    wget --content-disposition "http://bbs.espressif.com/download/file.php?id=189"
    unzip esp_iot_sdk_v0.9.5_15_01_23.zip
    cd esp_iot_sdk_v0.9.5/bin
    ../../esptool/esptool.py write_flash 0x00000 boot_v1.2.bin 0x01000 at/user1.512.new.bin 0x3e000 blank.bin 0x7e000 blank.bin
     First we clone 

`esptool` repository, then we get latest SDK release directly from forum and finally we ran `esptool`. If you will get something like this: 
    Connecting...
    Traceback (most recent call last):
      File "../../esptool/esptool.py", line 408, in <module>
        esp.connect()
      File "../../esptool/esptool.py", line 143, in connect
        raise Exception('Failed to connect')
    Exception: Failed to connect
     You can work around this by toggling power to the module right before executing 

`esptool` command. It works on my side. Successful flashing looks like this: 
    [1:00:21] pietrushnic:bin $ ../../esptool/esptool.py write_flash 0x00000 boot_v1.2.bin 0x01000 at/user1.512.new.bin 0x3e000 blank.bin 0x7e000 blank.bin
    Connecting...
    Erasing flash...
    Writing at 0x00000400... (100 %)
    Erasing flash...
    Writing at 0x00034800... (100 %)
    Erasing flash...
    Writing at 0x0003ec00... (100 %)
    Erasing flash...
    Writing at 0x0007ec00... (100 %)
    
    Leaving...
     After disconnecting GPIO0 and GPIO2 you can boot new firmware. Results should look like this: 

    AT+RST
    
    OK
    
     ets Jan  8 2013,rst cause:4, boot mode:(3,4)
    
    wdt reset
    load 0x40100000, len 816, room 16
    tail 0
    chksum 0x8d
    load 0x3ffe8000, len 788, room 8
    tail 12
    chksum 0xcf
    ho 0 tail 12 room 4
    load 0x3ffe8314, len 288, room 12
    tail 4
    chksum 0xcf
    csum 0xcf
    
    2nd boot version : 1.2
      SPI Speed      : 40MHz
      SPI Mode       : QIO
      SPI Flash Size : 4Mbit
    jump to run user1
    
    rN?
    ready
    AT+GMR
    AT version:0.21.0.0
    SDK version:0.9.5
    
    OK
     Of course you will need the toolchain to use new SDK. 

## Toolchain

[esp-open-sdk][3] is probably easiest to use toolchain that I found for ESP8266. `esp-open-sdk` puts together steps created by [ESP8266 Community Forum][4] published in [esp8266-wiki][5] repository. `esp-open-sdk` at the moment of writing this post didn't support `v0.9.5` SDK, but adding this support was pretty straight forward and can be found on my github for of the [repo][6]. There is also [pending PR][7] that hopefully will be merged. Procedure is straight forward to follow: 
    git clone git@github.com:pietrushnic/esp-open-sdk.git #or use https with https://github.com/pietrushnic/esp-open-sdk.git
    cd esp-open-sdk
    git co v0.9.5-support
    sed -i -e '/s0.9.4/s/^/#/g' -e '/s0.9.5/s/^#//g' Makefile
    make
    

`sed` command will cause using `0.9.5` string as `VENDOR_SDK` for default build. On my i7-4700 single threaded compilation takes ~20min. BTW I'm trying to figure out why I cannot use multiple jobs [here][8]. Final message should contain something like: 
    export PATH=/home/pietrushnic/tmp/esp-open-sdk/xtensa-lx106-elf/bin:$PATH
     Just execute this command in your shell. If you missed that message run 

`make` again it should skip all already compiled parts and display final message again. 
## Toolchain usage To use toolchain with example code from 

`v0.9.5` SDK you can simply: 
    cd esp_iot_sdk_v0.9.5 
     Use package like it was presented in "Upgrade using binaries from Espressif" section. Trying to compile exmaples in 

`esp-open-sdk` will give you error like this: 
    ../../Makefile:154: warning: overriding recipe for target 'clean'
    ../Makefile:258: warning: ignoring old recipe for target 'clean'
    You cloned without --recursive, fetching submodules for you.
    git submodule update --init --recursive
    make -C crosstool-NG -f ../Makefile _ct-ng
    make[1]: *** crosstool-NG: No such file or directory.  Stop.
    ../../Makefile:140: recipe for target 'crosstool-NG/ct-ng' failed
    make: *** [crosstool-NG/ct-ng] Error 2
     When inside 

`esp_iot_sdk_v0.9.5`: 
    cp -r examples/at .
    make COMPILE=gcc
     Ommiting 

`COMPILE=gcc` will result in error caused by using differen compiler name: 
    make[1]: Entering directory '/home/pietrushnic/src/espressif/esp_iot_sdk_v0.9.5/at/user'
    DEPEND: xt-xcc -M -Os -g -O2 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals -DICACHE_FLASH -I include -I ./ -I ../../include/ets -I ../include -I ../../include -I ../../include/eagle user_main.c
    /bin/sh: 2: xt-xcc: not found
    xt-xcc -Os -g -O2 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals  -DICACHE_FLASH   -I include -I ./ -I ../../include/ets -I ../include -I ../../include -I ../../include/eagle  -o .output/eagle/debug/obj/user_main.o -c user_main.c
    make[1]: xt-xcc: Command not found
    ../../Makefile:280: recipe for target '.output/eagle/debug/obj/user_main.o' failed
    make[1]: *** [.output/eagle/debug/obj/user_main.o] Error 127
    make[1]: Leaving directory '/home/pietrushnic/src/espressif/esp_iot_sdk_v0.9.5/at/user'
    ../Makefile:266: recipe for target '.subdirs' failed
    make: *** [.subdirs] Error 2
     Correct output looks like this: 

    make[1]: Entering directory '/home/pietrushnic/src/espressif/esp_iot_sdk_v0.9.5/at/user'
    DEPEND: xtensa-lx106-elf-gcc -M -Os -g -O2 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals -DICACHE_FLASH -I include -I ./ -I ../../include/ets -I ../include -I ../../include -I ../../include/eagle user_main.c
    xtensa-lx106-elf-gcc -Os -g -O2 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals  -DICACHE_FLASH   -I include -I ./ -I ../../include/ets -I ../include -I ../../include -I ../../include/eagle  -o .output/eagle/debug/obj/user_main.o -c user_main.c
    xtensa-lx106-elf-ar ru .output/eagle/debug/lib/libuser.a .output/eagle/debug/obj/user_main.o 
    xtensa-lx106-elf-ar: creating .output/eagle/debug/lib/libuser.a
    make[1]: Leaving directory '/home/pietrushnic/src/espressif/esp_iot_sdk_v0.9.5/at/user'
    xtensa-lx106-elf-gcc  -L../lib -nostdlib -T../ld/eagle.app.v6.ld -Wl,--no-check-sections -u call_user_start -Wl,-static -Wl,--start-group -lc -lgcc -lhal -lphy -lpp -lnet80211 -llwip -lwpa -lmain -ljson -lupgrade user/.output/eagle/debug/lib/libuser.a                                    -lat -Wl,--end-group -o .output/eagle/debug/image/eagle.app.v6.out 
    
    !!!
    No boot needed.
    Generate eagle.flash.bin and eagle.irom0text.bin successully in folder bin.
    eagle.flash.bin-------->0x00000
    eagle.irom0text.bin---->0x40000
    !!!
     Now 

`../bin` directory contain `eagle.flash.bin` and `eagle.irom0text.bin`, which you can use to flash your ESP8266 using `esptool`: 
    ../../esptool/esptool.py write_flash 0x00000 eagle.flash.bin 0x40000 eagle.irom0text.bin
    

## Summary Thanks for reading. Hope that this post fill the gap that some of beginner can experience when goolging through straight forward tutorial about playing with ESP. If you like this post please share. If you see some bias or you just want to share some facts, ask question then please leave a comment.

 [1]: http://bbs.espressif.com/viewtopic.php?f=5&t=154
 [2]: https://3mdeb.com/wp-content/uploads/2017/07/esp-12-update.jpg
 [3]: https://github.com/pfalcon/esp-open-sdk
 [4]: http://www.esp8266.com/
 [5]: https://github.com/esp8266/esp8266-wiki/wiki
 [6]: https://github.com/pietrushnic/esp-open-sdk.git
 [7]: https://github.com/pfalcon/esp-open-sdk/pull/18
 [8]: https://github.com/pfalcon/esp-open-sdk/issues/19
---
layout: post
title: "ESP8266 bare-metal development for beginners - blinky example"
date: 2015-08-18 21:36:56 +0200
comments: true
categories: ESP8266,embedded
---

This is another post from famous ESP8266 series. Today we will try to run
[blinky]() example on ESP-01. I use default flash setup as can be found in
various places in the net i.e. [here](). I will also silently assume that you
passed mentioned post or correctly used documentation to setup
[esp-open-sdk]().

##Preparation
Let's clone open source examples:

```
git clone git@github.com:esp8266/source-code-examples.git
```

Note that to compile those examples you need correctly exported path to
toolchain.

I modified `source-code-examples/blinky/Makefile` to match my paths. Git diff
looks like this:

```
diff --git a/blinky/Makefile b/blinky/Makefile
index 2eb212bb16dc..1d9940d5a51e 100644
--- a/blinky/Makefile
+++ b/blinky/Makefile
@@ -18,13 +18,13 @@ BUILD_BASE  = build
 FW_BASE                = firmware
 
 # base directory for the compiler
-XTENSA_TOOLS_ROOT ?= /opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin
+XTENSA_TOOLS_ROOT ?= /home/pietrushnic/src/esp-open-sdk/xtensa-lx106-elf/bin
 
 # base directory of the ESP8266 SDK package, absolute
-SDK_BASE       ?= /opt/Espressif/ESP8266_SDK
+SDK_BASE       ?= /home/pietrushnic/src/esp-open-sdk/sdk
 
 # esptool.py path and port
-ESPTOOL                ?= esptool.py
+ESPTOOL                ?= /home/pietrushnic/src/esptool/esptool.py
 ESPPORT                ?= /dev/ttyUSB0
```

##Compilation and flashing

To compile simply use `make`. Output should look like this:

```
[21:49:50] pietrushnic:blinky git:(master*) $ make
CC user/user_main.c
AR build/app_app.a
LD build/app.out
FW firmware/
```

You can hit self-explanatory errors like this:

```
[21:48:21] pietrushnic:blinky git:(master*) $ make
CC user/user_main.c
make: /home/pietrushnic/src/esp-open-sdk/builds/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc: Command not found
Makefile:137: recipe for target 'build/user/user_main.o' failed
make: *** [build/user/user_main.o] Error 127
```

Incorrect path to toolchain. Fixing XTENSA_TOOLS_ROOT variable should pass this problem.

```
[21:49:23] pietrushnic:blinky git:(master*) $ make
FW firmware/
Error calling xtensa-lx106-elf-readelf, do you have Xtensa toolchain in PATH?
Makefile:112: recipe for target 'firmware/0x00000.bin' failed
make: *** [firmware/0x00000.bin] Error 1
```

Toolchain not in path. Did you forget to export `esp-open-sdk` toolchain or
maybe exported path is incorrect ?

###Flash

To flash you need to connect `GPIO2` to VCC (3.3V) and `GPIO0` to GND. Note
that sometimes 3.3V maybe not enough. It should be secure to have up to 5V VCC.
Usually USB 3.3V was not suitable for flashing ESP-01. I use cheap
(~30USD) [Zhaoxin
RXN-1503D](http://www.zaoxin.com/instruments/pro_info.aspx?PROID=216&PID=55).

Flashing log:

```
[22:15:38] pietrushnic:blinky git:(master*) $ make flash
/home/pietrushnic/src/esptool/esptool.py --port /dev/ttyUSB0 write_flash 0x00000 firmware/0x00000.bin 0x40000 firmware/0x40000.bin
Connecting...
Erasing flash...
Writing at 0x00006400... (100 %)
Erasing flash...
Writing at 0x00069400... (100 %)

Leaving...
```

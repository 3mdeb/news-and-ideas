---
author: Piotr Król
layout: post
title: "CryptoAuth OpenSSL engine and ECC508A"
date: 2016-11-27 23:20:31 +0100
comments: true
categories: openssl ecc508a security iot embedded linux
---

After [failure of my previous approach](2016/11/24/initial-triage-of-atmel-sam-g55-and-ecc508a/) I decide to
switch to something that seems to be more feasible. As project objectives states:

> Customers may buy un-programmed ATECC508A devices, download this project, build it, and establish a TLS1.2 connection without writing any code.
> Customers that buy personalized devices should be able to use these devices without writing any code.

Of course repository is getting older and no update was provided since February 2016. 

There were just 4 contributors where Atmel employee plus one consultant seemed
to provide most of the work. One closed issue, no merge requests no valuable
forks and 13 stars. I would not say this is vibrant community.

My goal was to confirm if project objectives are true and implement AWS Zero
Touch provisioning for Embedded Linux system. Method which utilize ECC508A was
overhyped by embedded news media in August 2016 what I described in [previous
post](2016/11/24/initial-triage-of-atmel-sam-g55-and-ecc508a/).

## Cryptoauth Xplained Pro

Luckily Atmel website provide enough information to continue evaluation of
ECC508A. CryptoAuth Xplained Pro board is a small evaluation board. It has
standard 20pin Atmel header to be compatible with various development boards
from the same vendor.

TODO: photo

Pinout is decribed in [hardware user guide](http://www.atmel.com/Images/Atmel-8893-CryptoAuth-XPro-Hardware-UserGuide.pdf).
Most development board have i2c connection exposed. Wiring is very simple all
you need is connect Vcc, GND, SCL and SDA.

After connecting Cryptoauth Xplained Pro your distro should show difference on
one of i2c buses. In my case it was `/dev/i2c-1`:

```
pi@raspberrypi:~/cryptoauth-openssl-engine $ i2cdetect 1
WARNING! This program can confuse your I2C bus, cause data loss and worse!
I will probe file /dev/i2c-1.
I will probe address range 0x03-0x77.
Continue? [Y/n] 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
50: 50 -- -- -- -- -- -- -- 58 -- -- -- -- -- -- -- 
60: -- -- -- -- 64 -- -- -- -- -- -- -- -- -- -- -- 
70: -- -- -- -- -- -- -- --
```

When tried to read not provisioned device I saw something like this:

```
pi@raspberrypi:~/cryptoauth-openssl-engine $ sudo i2cdump 2 0x50
WARNING! This program can confuse your I2C bus, cause data loss and worse!
I will probe file /dev/i2c-2, address 0x50, mode byte
Continue? [Y/n] 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f    0123456789abcdef
00: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
(...)
f0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
pi@raspberrypi:~/cryptoauth-openssl-engine $ sudo i2cdump 2 0x58
WARNING! This program can confuse your I2C bus, cause data loss and worse!
I will probe file /dev/i2c-2, address 0x58, mode byte
Continue? [Y/n] 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f    0123456789abcdef
00: XX XX XX 04 11 33 43 04 11 33 43 04 11 33 43 04    XXX??3C??3C??3C?
10: 11 33 43 04 11 33 43 04 11 33 43 04 11 33 43 04    ?3C??3C??3C??3C?
(...)
f0: 11 33 43 04 11 33 43 04 11 33 43 04 11 33 43 04    ?3C??3C??3C??3C?
pi@raspberrypi:~/cryptoauth-openssl-engine $ sudo i2cdump 2 0x64
WARNING! This program can confuse your I2C bus, cause data loss and worse!
I will probe file /dev/i2c-2, address 0x64, mode byte
Continue? [Y/n] 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f    0123456789abcdef
00: XX XX XX c9 c9 XX XX c9 c9 XX XX c9 c9 XX XX c9    XXX??XX??XX??XX?
10: c9 XX XX c9 c9 XX XX c9 c9 XX XX c9 c9 XX XX c9    ?XX??XX??XX??XX?
(...)
f0: c9 XX XX c9 c9 XX XX c9 c9 XX XX c9 c9 XX XX c9    ?XX??XX??XX??XX?
```

Lines that repeat were replaced with `(...)`.

## CryptoAuth OpenSSL Engine

This library was created by Atmel to provide support for TLS v1.2 connection by
utilizing ECC508A crypto coprocessor. To skip cross-compilation hassle I decide
to compile natively on my Embedded Linux. If you use development board with
recent SoC this should not be problem. My platform was RaspberryPi 2 with
`2016-11-25-raspbian-jessie`. To prepare my distro I needed additional steps:

```
sudo raspi-config
```

Choose `Advanced Options -> I2C` and enable i2c interface.

```console
sudo apt-get update
sudo apt-get install git vim tmux
```

Clone and compile:

```console
git clone https://github.com/AtmelCSO/cryptoauth-openssl-engine.git
cd cryptoauth-openssl-engine
# this will mesaure compilation time and pipe whole output to build.log
time make |& tee build.log
```

This takes ~17min.

I also run tests to check if everything is working fine:

```
$ make test
```

Not all tests pass:

```
tls1_setup_key_block()
client random
AA 63 C1 66 13 6B 5F 4B DF F3 33 E2 33 EB 33 AD
ED 99 A5 B1 26 E8 8B 33 9D 91 F6 5E AA 08 A4 F1
server random
EE DB BC 1B 79 89 E4 A1 3A 0B DC EF F1 91 2E B6
61 FA 5C D7 B6 EA A0 E7 7A 6E B4 74 5D ED 0B 21
pre-master
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
tls1_generate_key_block() ==> 48 byte master_key =
        000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ERROR in CLIENT
1995519184:error:1411C146:SSL routines:tls1_prf:unsupported digest type:t1_enc.c:276:
1995519184:error:1411C146:SSL routines:tls1_prf:unsupported digest type:t1_enc.c:276:
tls1_enc(1)
TLSv1.2, cipher TLSv1/SSLv3 ECDHE-RSA-AES256-GCM-SHA384, 2048 bit RSA
1 handshakes of 256 bytes done
Makefile:297: recipe for target 'test_ssl' failed
make[2]: *** [test_ssl] Error 1
make[2]: Leaving directory '/home/pi/cryptoauth-openssl-engine/openssl_1_0_2/test'
Makefile:460: recipe for target 'tests' failed
make[1]: *** [tests] Error 2
make[1]: Leaving directory '/home/pi/cryptoauth-openssl-engine/openssl_1_0_2'
Makefile:88: recipe for target 'test_openssl' failed
make: *** [test_openssl] Error 2
```

## Provisioning

Let's switch context to crypto device provisioning. As it can be found in logs,
by dumping registers of i2c devices, chips are not in operational state. 

Unfortunately Root and Signer module can be used only with Windows application.
I had to run it in virtual machine. Of course first thing that came to mind is
to sniff traffic that go through USB bus. To do that Wireshark and `usbmon`
module can be used.

### USB monitor setup

```
sudo modprobe usbmon
```

This should cause additional devices appear in `/dev` like `/dev/usbmon0`,
`/dev/usbmon1` etc. Numbers means bus that you can sniff. So lets identify bus:

```
$ lsusb|grep microchip -i
Bus 003 Device 010: ID 04d8:0f30 Microchip Technology, Inc.
```

Then running Wireshark on `/dev/usbmon3` should show you flying URBs. Analyzing
this traffic should help in developing `Atmel Secure Provisioning Utilies` and
`Atmel Secure Provisioning Server` for Linux and other platforms. Legal
aftermath should be taken into consideration, but AFAIK 2 main points for
reversing USB and TCP/IP communication between provisioning client, server and
USB Root/Signer module are:

* there is not Linux/Mac implementation of this application, so user is forced
  to use Windows
* exact communication is not described and it may be implemented in insecure
  manner (ie. it may contain communication with outside server), so reasonable
  researcher should check if solution sold is good for his/her use

### AT88CKECCROOT

Under Linux it identify itself as:

```
[14344.115498] usb 3-1.3.2: new full-speed USB device number 10 using ehci-pci
[14344.239913] usb 3-1.3.2: New USB device found, idVendor=04d8, idProduct=0f30
[14344.239915] usb 3-1.3.2: New USB device strings: Mfr=1, Product=2, SerialNumber=0
[14344.239916] usb 3-1.3.2: Product: AWS Root dongle
[14344.239917] usb 3-1.3.2: Manufacturer: Microchip
```

### Atmel sales magic

TODO: picture

When taking this apart it happen to be just
[AT88CK590](http://www.atmel.com/tools/AT88CK590.aspx), what is interesting is
that this `AT88CK590` cost 20 USD but `AT88CKECCROOT` that seems to provide
3x`AT88CK590` cost [149.95USD](http://www.atmel.com/tools/AT88CKECCROOT-SIGNER.aspx?tab=overview)
what's even more interesting is that I see no difference between
`AT88CKECCROOT` and `AT88CKECCSIGNER`, but further one cost 99.95USD. This looks like sales magick.

This discovery brings me to conclusion that sniffing USB is not needed since
`AT90USB1287`, which is heart of `AT88CK590` can be supported under Linux.
There are even some signs of it in Google. Documentation also reveal protocol
for communication with server, so the only missing part is OpenSSL handling and
HAL in CryptoAuth Lib for `AT88CK590`. At least this was my understanding at
that point.

Of course I didn't had time to hack solution for Linux, which would be
educational, that's why I tried with Windows VM and Atmel Provisioning Utilies
and Server. Unfortunately Windows VM was not able to detect USB keys, so the
only option was using Windows machine or reverse what is going within
`AT90USB1287` which is heart of `AT88CK590`.

Luckily `AT88CK590` modules have JTAG exposed - more information can be found
on [schematics](http://www.atmel.com/Images/Atmel-CryptoAuth-AT88CK590_Schematics.pdf).

### Using Atmel software

I started with [Quick Start Guide](http://www.atmel.com/Images/Atmel-8966-CryptoAuth-Security-Provisioning-Kits-Quick-Start-Guide.pdf).
But googling lead me also to very interesting documents like [this rs-online traning](http://www.rs-online.com/designspark/assets/ds-assets/uploads/knowledge-items/why-iot-and-everything-else-requires-strong-authentication/Atmel%20Crypto%20Products%20REAL.EASY%20Training%20Manual%202Q2015%20r6.pdf).
And there are even more recent materials that provide a lot of information about Atmel Security chips [here](http://www.slideshare.net/BillBoldt/crypto-products-backgrounder-r0).

### WolfSSL and related work

Digging more in various repositories and documentation lead me to WoldSSL
support for ECC508A. Interesting thing I found in [David Garske
repository](https://github.com/dgarske/atmel) which contain provisioning code
for ECC508A in [provision.c](https://github.com/dgarske/atmel/blob/master/cryptoauthlib/certs/provision.c).
It would be interesting to walk through this and see how this implement
provisioning workflow described in Atmel documentation.

## Atmel Software Framework

Atmel did great work with AVR and community around that. We get all Linux tools
necessary for building application on those small MCUs. But it looks like with
ARMs Atmel lost feeling about things developers need and quality they should
provide. First ASF is provided only after logging in, second it happens that
website is not able to log you in:

```
maintenance.aspx?ErrorCode=ErrorUnknownException&status=AuthenticationFailed
```

Causing blocking issue on embedded engineer side. If someone hit that during
evaluation this can seriously damage brand view of this person.

Finally Atmel finished maintenance and I was able to download
[ASF](http://www.atmel.com/tools/avrsoftwareframework.aspx) and
[Toolchain](http://www.atmel.com/tools/atmel-arm-toolchain.aspx?tab=overview).

Archive for `3.33.0.50` was broken so to unpack recent ASF I needed:

```
sudo apt-get install fastjar
jar xvf asf-standalone-archive-3.33.0.50.zip
```

To extract toolchain:

```
tar xvf arm-gnu-toolchain-5.3.1.487-linux.any.x86_64.tar.gz
export PATH=$PATH:$PWD/arm-none-eabi/bin
```

### Blinky LED on Linux

```
$ cd xdk-asf-3.33.0/sam0/applications/led_toggle/samd21_xplained_pro/gcc
$ make
MKDIR   common/utils/interrupt/
CC      common/utils/interrupt/interrupt_sam_nvic.o
MKDIR   sam0/applications/led_toggle/
CC      sam0/applications/led_toggle/led_toggle.o
MKDIR   sam0/boards/samd21_xplained_pro/
CC      sam0/boards/samd21_xplained_pro/board_init.o
MKDIR   sam0/drivers/port/
CC      sam0/drivers/port/port.o
MKDIR   sam0/drivers/system/clock/clock_samd21_r21_da_ha1/
CC      sam0/drivers/system/clock/clock_samd21_r21_da_ha1/clock.o
CC      sam0/drivers/system/clock/clock_samd21_r21_da_ha1/gclk.o
MKDIR   sam0/drivers/system/interrupt/
CC      sam0/drivers/system/interrupt/system_interrupt.o
MKDIR   sam0/drivers/system/pinmux/
CC      sam0/drivers/system/pinmux/pinmux.o
CC      sam0/drivers/system/system.o
MKDIR   sam0/utils/cmsis/samd21/source/gcc/
CC      sam0/utils/cmsis/samd21/source/gcc/startup_samd21.o
CC      sam0/utils/cmsis/samd21/source/system_samd21.o
MKDIR   sam0/utils/syscalls/gcc/
CC      sam0/utils/syscalls/gcc/syscalls.o
LN      led_toggle_flash.elf
SIZE    led_toggle_flash.elf
led_toggle_flash.elf  :
section              size         addr
.text               0xa58          0x0
.relocate             0x4   0x20000000
.bss                 0x3c   0x20000004
.stack             0x2000   0x20000040
.ARM.attributes      0x28          0x0
.comment             0x2b          0x0
.debug_info        0xa640          0x0
.debug_abbrev      0x1593          0x0
.debug_aranges      0x280          0x0
.debug_ranges       0x190          0x0
.debug_macro      0x17a4b          0x0
.debug_line        0x52fb          0x0
.debug_str        0x89a7b          0x0
.debug_frame        0x4d4          0x0
.debug_loc         0x1644          0x0
Total             0xb6da7


   text    data     bss     dec     hex filename
  0xa58     0x4  0x203c   10904    2a98 led_toggle_flash.elf
OBJDUMP led_toggle_flash.lss
NM      led_toggle_flash.sym
OBJCOPY led_toggle_flash.hex
OBJCOPY led_toggle_flash.bin
```

Now we have binaries and can flash it to samd21 board.

### EDBG programmer

Luckily googling for ASF development under Linux I found [EDBG](https://github.com/ataradov/edbg) project:

```
sudo apt-get install libudev-dev
git clone https://github.com/ataradov/edbg.git
cd edbg
make all
sudo cp 90-atmel-edbg.rules /etc/udev/rules.d
```

Then connect board and you should see something like that in `dmesg`:

```
[47626.485486] usb 3-10.1.1: new high-speed USB device number 9 using xhci_hcd
[47626.585730] usb 3-10.1.1: config 1 interface 2 altsetting 0 bulk endpoint 0x84 has invalid maxpacket 64
[47626.585733] usb 3-10.1.1: config 1 interface 2 altsetting 0 bulk endpoint 0x5 has invalid maxpacket 64
[47626.586072] usb 3-10.1.1: New USB device found, idVendor=03eb, idProduct=2111
[47626.586074] usb 3-10.1.1: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[47626.586075] usb 3-10.1.1: Product: EDBG CMSIS-DAP
[47626.586076] usb 3-10.1.1: Manufacturer: Atmel Corp.
[47626.586076] usb 3-10.1.1: SerialNumber: ATML2130021800025687
[47626.587836] hid-generic 0003:03EB:2111.0004: hiddev0,hidraw3: USB HID v1.11 Device [Atmel Corp. EDBG CMSIS-DAP] on usb-0000:00:14.0-10.1.1/input0
[47626.661842] cdc_acm 3-10.1.1:1.1: ttyACM0: USB ACM device
[47626.662618] usbcore: registered new interface driver cdc_acm
[47626.662621] cdc_acm: USB Abstract Control Model driver for USB modems and ISDN adapters
```

You can request list of available debuggers:

```
$ ./edbg -l                                                                                                                                                                  master 
Attached debuggers:
  ATML2130021800025687 - Atmel Corp. EDBG CMSIS-DAP
```

Backup our flash content:

```
$ ./edbg -b -r -f flash.dump -t atmel_cm0p                                                                                                                                   master 
Debugger: ATMEL EDBG CMSIS-DAP ATML2130021800025687 01.1A.00FB (S)
Target: SAM D21J18A Rev D
Reading................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................... done.
```

To flash our blinky example:

```
$ ./edbg -b -p -v -f /path/to/led_toggle_flash.bin  -t atmel_cm0p 
Debugger: ATMEL EDBG CMSIS-DAP ATML2130021800025687 01.1A.00FB (S)
Target: SAM D21J18A Rev D
Programming.............. done.
Verification.............. done.
```

Then you should see blinking LED0 on your SAMD21 board.

### Crypto examples using ASF on Linux


### Lack of support for Linux i2c device

CryptoAuth OpenSSL Engines published by Atmel covers only one case when
[AT88CK101](http://www.atmel.com/tools/AT88CK101.aspx) development kit is used.
This means that Linux i2c device HAL had to be written and in addition to lack
of full ECC508A without NDA it required relying only on already implemented
HALs. There are dozen of them so it is not big problem, but still additional
work to just evaluate module.

I did comparison of [CryptoAuthLib Firmware Library 20160108](http://www.atmel.com/images/Atmel-CryptoAuthLib-Firmware_20160108.zip)
and what was included in OpenSSL engine implementation. I see quite a lot of
difference:

* Makefiles were added to alldirectories
* Bunch of HALs for non Linux targets (ie. i2c bitbang, samd21, sam4s, samv71,
  swi etc.)
* Documentation improvements and in code comments
* correctly handle SHA length in couple functions
* `atcab_write_pubkey` was added basic module
* `tcatls_get_sn` was added atcatls module
* lots of other minor changes
* diffstat: `83 files changed, 2133 insertions(+), 1342 deletions(-)`

I did fork and update CryptoAuth Library in my repository. You can find update
version
[here](https://github.com/3mdeb/cryptoauth-openssl-engine/tree/cryptoauthlib_20160108)>

I did fork and updated CryptoAuth Library in my repository. You can find update
version [here](https://github.com/3mdeb/cryptoauth-openssl-engine/tree/cryptoauthlib_20160108)>

## Starting with CryptAuthLib under Linux

### libcrypti2c

Further search lead me to [libcrypti2c](https://github.com/cryptotronix/libcrypti2c) from
[Cryptotronix](https://cryptotronix.com/), which itself is very interesting
business which focus on IoT security. I found very interesting pages and
presentation following Cryptotronix:

* [CrypTech Open Hardware Security Module (Alpha Board)](https://www.crowdsupply.com/cryptech/open-hardware-security-module)
* [EClet](https://github.com/cryptotronix/EClet)

I tried to compile library on my Raspbian:

```
sudo apt-get update && sudo apt-get upgrade
# this library installs really long
sudo apt-get install gnulib libgcrypt20-dev libxml2-dev libglib2.0-dev \
build-essential libsodium-dev guile-2.0-dev
git clone https://github.com/cryptotronix/yacl.git
cd yacl
./autogen.sh
./configure --with-libglib -with-guile --with-libsodium --enable-tests
make
sudo make install
cd ..
git clone https://github.com/cryptotronix/libcrypti2c.git
cd libcrypti2c
./autogen.sh
./configure
make -j$(nproc)
sudo make install
```

### EClet

```
sudo apt-get install check markdown html2text
git clone https://github.com/cryptotronix/EClet.git
cd EClet
./autogen.sh
./configure
make
```

Quick check what are the replies from my device CryptoAuth Xplained Pro

```
pi@raspberrypi:~/EClet $ ./eclet -a 0x50 state
eclet: src/i2c.c:100: lca_wakeup: Assertion `lca_is_crc_16_valid(buf, 2, buf+2)' failed.
Aborted
pi@raspberrypi:~/EClet $ ./eclet -a 0x58 state
Personalized
pi@raspberrypi:~/EClet $ ./eclet -a 0x64 state
Personalized
```

It's hard to say if this was correct result. I had to dig deeper to understand
how it works.

I tried to read serial numbers:

```
pi@raspberrypi:~/EClet $ ./eclet -a 0x50 serial-num
eclet: src/i2c.c:100: lca_wakeup: Assertion `lca_is_crc_16_valid(buf, 2, buf+2)' failed.
Aborted
pi@raspberrypi:~/EClet $ ./eclet -a 0x58 serial-num
01237B3D43B2AB9DEE
pi@raspberrypi:~/EClet $ ./eclet -a 0x64 serial-num
0123236C89536F7CEE
```

I also tried `develop` branch which at that point failed even to read serial
number, but didn't assert on ECC508A checking.

Unfortunately those brand new CryptoAuth Xplained Pro boards got `personalized`
status, which seems to no be correct IIUC. I posted [issue to EClet repo](https://github.com/cryptotronix/EClet/issues/17).

### Linux kernel module

Following advise from Josh (owner of Cryptotronix) I tried his Linux kernel
driver on my RPi.

First you need kernel, toolchain and module:

```
git clone https://github.com/raspberrypi/linux.git
git clone https://github.com/raspberrypi/tools.git
git clone https://github.com/cryptotronix/atsha204-i2c.git
export PATH=$PATH:$PWD/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin
```

Get config from your RPi:

```
sudo modprobe configs
zcat /proc/config.gz > rpi_config
scp rpi_config user@myhost:/home/user
```

Copy your config to Raspberry kernel directory:

```
cd linux
cp /home/user/rpi_config .config
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc) deb-pkg
scp ../*.deb pi@192.168.0.100:/home/pi
```

On RPi:

```
sudo dpkg -i *.deb
```

This take some time

`atsha204-i2c` cross-compilation requires patch for Makefile:

```
diff --git a/Makefile b/Makefile
index 8f8a6f52516d..ff489ae09fdf 100644
--- a/Makefile
+++ b/Makefile
@@ -3,13 +3,13 @@ KDIR ?= /lib/modules/`uname -r`/build
 MDIR ?= /lib/modules/`uname -r`/kernel/drivers/char/
 SRC = atsha204-i2c.c atsha204-i2c.h
 # Enable CFLAG to run DEBUG MODE
-#CFLAGS_atsha204-i2c.o := -DDEBUG
+CFLAGS_atsha204-i2c.o := -DDEBUG

 all:
-       make -C $(KDIR) M=$$PWD modules
+       make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -C $(KDIR) M=$$PWD modules
 #      make testing code
-       gcc -c $$PWD/test/test.c
-       gcc $$PWD/test/test.c -o $$PWD/test/test
+       arm-linux-gnueabihf-gcc -c $$PWD/test/test.c
+       arm-linux-gnueabihf-gcc $$PWD/test/test.c -o $$PWD/test/test

 clean:
        make -C $(KDIR) M=$$PWD clean
```

Then module should correctly compile:

```
[14:20:06] pietrushnic:atsha204-i2c git:(master*) $ KDIR=../linux make                    
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -C ../linux M=$PWD modules
make[1]: Entering directory '/home/pietrushnic/path/to/rpi_crypto/linux'
  Building modules, stage 2.
  MODPOST 1 modules
make[1]: Leaving directory '/home/pietrushnic/path/to/rpi_crypto/linux'
arm-linux-gnueabihf-gcc -c $PWD/test/test.c
arm-linux-gnueabihf-gcc $PWD/test/test.c -o $PWD/test/test
```

Copy module to Raspberry:

```
scp atsha204-i2c.ko pi@192.168.0.100:/home/pi
```

On RPi move module to character drivers directory:

```

```


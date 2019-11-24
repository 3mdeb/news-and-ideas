---
author: Piotr Król
layout: post
title: "Initial triage of CryptoAuth Xplained Pro with Raspberry Pi 3"
date: 2017-01-07 14:28:14 +0100
comments: true
categories: crypto ecc508 raspberrypi embedded linux
---


After [failure of my previous approach](2016/11/24/initial-triage-of-atmel-sam-g55-and-ecc508a/) I decide to
switch to something that seems to be [more feasible](https://github.com/AtmelCSO/cryptoauth-openssl-engine). As CryptoAuth
OpenSSL Engine project objectives states:

> Customers may buy un-programmed ATECC508A devices, download this project, build it, and establish a TLS1.2 connection without writing any code.
> Customers that buy personalized devices should be able to use these devices without writing any code.

Of course repository is getting older and no update was provided since February 2016. 

There were just 4 contributors - Atmel employee plus one consultant seemed
to provide most of the work. One closed issue, no merge requests no valuable
forks and 16 stars. I would not say this is vibrant community.

My goal was to confirm if project objectives are true and implement AWS Zero
Touch provisioning for Embedded Linux system. Method which utilize ECC508A was
overhyped by embedded news media in August 2016 what I described in [previous post](2016/11/24/initial-triage-of-atmel-sam-g55-and-ecc508a/).

Key issue was that CryptoAuth library doesn't provide HAL for Linux i2c. Below
I described my experience with solving this issue.

## Cryptoauth Xplained Pro

Luckily Atmel website provide enough information to continue evaluation of
ECC508A. CryptoAuth Xplained Pro board is a small evaluation board. It has
standard 20pin Atmel header to be compatible with various development boards
from the same vendor.

<a class="fancybox" rel="group" href="/assets/images/atmel_crypto.jpg"><img src="/assets/images/atmel_crypto.jpg" alt=""/></a>

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

Addresses detected do not exactly match what should be visible based on PCB
description and code that I saw for SAMD21.

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
version [here](https://github.com/3mdeb/cryptoauth-openssl-engine/tree/cryptoauthlib_20160108)

## Alternative approach from Cryptotronix

Lack of Linux HAL in CryptAuthLib lead me to google research and I found
[Cryptotronix](https://cryptotronix.com/) effort related to ECC508A and other
crypto chips. Cryptotronix is interesting company I recommend to look at their
site and familiarise with this links:

* [CrypTech Open Hardware Security Module (Alpha Board)](https://www.crowdsupply.com/cryptech/open-hardware-security-module)
* [EClet](https://github.com/cryptotronix/EClet)


### libcrypti2c

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

This take some time. After installation procedure you have to point bootloader
to use new version. You can do that adding below line to `/boot/config.txt`:

```
kernel=vmlinuz-4.4.39-v7+
```

Then you can reboot.

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
pi@raspberrypi:~ $ sudo cp atsha204-i2c.ko /lib/modules/`uname -r`/kernel/drivers/char/
pi@raspberrypi:~ $ sudo depmod
pi@raspberrypi:~ $ sudo modprobe atsha204-i2c
pi@raspberrypi:~ $ lsmod|grep atsha204
atsha204_i2c            8374  0 
```

To utilize this module `libcrypti2c` have to be rebuilt with `-DUSE_KERNEL`


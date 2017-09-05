---
ID: 62916
post_title: >
  Building Android 4.2 LiveSuit image for
  Cubietruck (Allwinner A20)
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/building-android-4-2-livesuit-image-for-cubietruck-allwinner-a20/
published: true
post_date: 2015-09-16 23:02:57
tags:
  - embedded
  - linux
  - Cubietruck
  - Android
  - Allwinner
categories:
  - OS Dev
---
Treating A20 boards like outdated piece of HW by vendors makes building Android
for Cubietruck not trivial task. Finding documentation, mailing list or blog
post that clearly describe steps is almost impossible. Most of links to SDK are
broken and instructions outdated. Because of that I decided to leave couple
notes for me and all of you lost in this madness.

Hopefully below steps can build foundation for future development and
improvements.

## Get the code

It took me couple of googling hours to realize that key was to carefully search
cubietech sever. Finally I found [this](http://dl.cubieboard.org/model/cubietruck/Source/Android/README).

So I cloned repos with code:

```
git clone https://bitbucket.org/cubietech/a20-android4.2_android.git lichee
git clone https://bitbucket.org/cubietech/a20-android4.2_android.git
```

Based on other [instruction](http://docs.cubieboard.org/tutorials/ct1/installation/cb3_a20-compiling_android_image_for_cubietruck) that I hit previously (but download link was broken) I run build process:

```
cd lichee
./build.sh -p sun7i_android
```

## Lichee compilation error

World would be too beautiful if everything would work right out of the box, so
I hit this very informative build error:

```
make: Entering directory &#039;/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali&#039;
/home/pietrushnic/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4
make -C DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump CONFIG=ca8-virtex820-m400-1 BUILD=release KDIR=/home/pietrushnic/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4
make[1]: Entering directory &#039;/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump&#039;
make -C /home/pietrushnic/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4 M=/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump modules
make[2]: Entering directory &#039;/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4&#039;
  CC [M]  /home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump/common/ump_kernel_common.o
arm-linux-gnueabi-gcc: error: directory: No such file or directory
arm-linux-gnueabi-gcc: error: directory&quot;: No such file or directory
scripts/Makefile.build:307: recipe for target &#039;/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump/common/ump_kernel_common.o&#039; failed
make[3]: *** [/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump/common/ump_kernel_common.o] Error 1
Makefile:1365: recipe for target &#039;_module_/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump&#039; failed
make[2]: *** [_module_/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump] Error 2
make[2]: Leaving directory &#039;/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4&#039;
Makefile:60: recipe for target &#039;all&#039; failed
make[1]: *** [all] Error 2
make[1]: Leaving directory &#039;/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump&#039;
Makefile:15: recipe for target &#039;build&#039; failed
make: *** [build] Error 2
make: Leaving directory &#039;/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_lichee/linux-3.4/modules/mali&#039;
ERROR: build kernel Failed
```

After some digging I managed to narrow down issue to piece of smart code, that
injected version string through define, which generated above mess. Without
thinking much about fix I just changed incorrectly generated define to driver
version string. This string will be presented in UMP modinfo. Patch which fix
above looks like that:

```
diff --git a/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump/Kbuild b/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump/Kbuild
index 042745d0c757..608a7ba97f95 100755
--- a/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump/Kbuild
+++ b/linux-3.4/modules/mali/DX910-SW-99002-r3p2-01rel2/driver/src/devicedrv/ump/Kbuild
@@ -26,10 +26,10 @@ endif
 UDD_FILE_PREFIX = ../mali/
 
 # Get subversion revision number, fall back to 0000 if no svn info is available
-SVN_REV := $(shell ((svnversion | grep -qv exported &amp;&amp; echo -n &#039;Revision: &#039; &amp;&amp; svnversion) || git svn info | sed -e &#039;s/$$$$/M/&#039; | grep &#039;^Revision: &#039; || echo ${MALI_RELEASE_NAME}) 2&gt;/dev/null | sed -e &#039;s/^Revision: //&#039;)
+# SVN_REV := $(shell ((svnversion | grep -qv exported &amp;&amp; echo -n &#039;Revision: &#039; &amp;&amp; svnversion) || git svn info | sed -e &#039;s/$$$$/M/&#039; | grep &#039;^Revision: &#039; || echo ${MALI_RELEASE_NAME}) 2&gt;/dev/null | sed -e &#039;s/^Revision: //&#039;)
 
-ccflags-y += -DSVN_REV=$(SVN_REV)
-ccflags-y += -DSVN_REV_STRING=&quot;$(SVN_REV)&quot;
+#ccflags-y += -DSVN_REV=$(SVN_REV)
+ccflags-y += -DSVN_REV_STRING=&quot;r3p2-01rel2&quot;
 
 ccflags-y += -I$(src) -I$(src)/common -I$(src)/linux -I$(src)/../mali/common -I$(src)/../mali/linux -I$(src)/../../ump/include/ump
 ccflags-y += -DMALI_STATE_TRACKING=0
```

After above change repeated build command finish without errors.

```
./build.sh -p sun7i_android
```

## Android

I assume you directory layout looks like this:

```
.
??? a20-android4.2_android
??? lichee
```

Go to Android directory and source environment setup script. Android do not
like shells other then bash, so change you shell if you using something
different:

```
cd a20-android4.2_android
bash
source build/envsetup.sh
lunch
```

You will get menu which will look like this:

```
You&#039;re building on Linux

Lunch menu... pick a combo:
     1. full-eng
     2. full_x86-eng
     3. vbox_x86-eng
     4. full_mips-eng
     5. full_grouper-userdebug
     6. full_tilapia-userdebug
     7. mini_armv7a_neon-userdebug
     8. mini_armv7a-userdebug
     9. mini_mips-userdebug
     10. mini_x86-userdebug
     11. full_maguro-userdebug
     12. full_manta-userdebug
     13. full_toroplus-userdebug
     14. full_toro-userdebug
     15. sugar_cubieboard2-eng
     16. sugar_cubietruck-eng
     17. sugar_evb-eng
     18. sugar_ref001-eng
     19. sugar_standard-eng
     20. wing_evb_v10-eng
     21. full_panda-userdebug
```

Of course our target is `sugar_cubietruck-eng`, so type `16`. Then copy kernel
and modules using `extract-bsp` function and start build:

```
extract-bsp
make -j$(nproc)
```

### Wrong make version

Android expects make in version 3.81 or 3.82 and recent distros (like my Debian
stretch/sid) have make>=4.0. Problem signature looks like this:

```
build/core/main.mk:45: ********************************************************************************
build/core/main.mk:46: *  You are using version 4.0 of make.
build/core/main.mk:47: *  Android can only be built by versions 3.81 and 3.82.
build/core/main.mk:48: *  see https://source.android.com/source/download.html
build/core/main.mk:49: ********************************************************************************
build/core/main.mk:50: *** stopping.  Stop.
```

You can workaround this problem using below patch:

```
diff --git a/build/core/main.mk b/build/core/main.mk
index 87488f452a9d..ce366bee6ced 100644
--- a/build/core/main.mk
+++ b/build/core/main.mk
@@ -40,8 +40,7 @@ endif
 # Check for broken versions of make.
 # (Allow any version under Cygwin since we don&#039;t actually build the platform there.)
 ifeq (,$(findstring CYGWIN,$(shell uname -sm)))
-ifeq (0,$(shell expr $$(echo $(MAKE_VERSION) | sed &quot;s/[^0-9.].*//&quot;) = 3.81))
-ifeq (0,$(shell expr $$(echo $(MAKE_VERSION) | sed &quot;s/[^0-9.].*//&quot;) = 3.82))
+ifeq (0,$(shell expr $$(echo $(MAKE_VERSION) | sed &quot;s/[^0-9.].*//&quot;) = 4.0))
 $(warning ********************************************************************************)
 $(warning *  You are using version $(MAKE_VERSION) of make.)
 $(warning *  Android can only be built by versions 3.81 and 3.82.)
@@ -50,7 +49,6 @@ $(warning **********************************************************************
 $(error stopping)
 endif
 endif
-endif
 
 # Absolute path of the present working direcotry.
```

### Java SE 1.6 required

If your distro is not prepared you can hit something like this:

```
************************************************************
You are attempting to build with the incorrect version
of java.
 
Your version is: java version &quot;1.7.0_85&quot;.
The correct version is: Java SE 1.6.
 
Please follow the machine setup instructions at
    https://source.android.com/source/download.html
************************************************************
```

To fix this issues add this repo to your `/etc/apt/sources.list`

```
deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main
deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main
```

Then update and install required Java SDK.

```
sudo apt-get update
sudo apt-get install sun-java6-jdk
```

You also may need to update alternatives if Java SE 1.6 was installed previously:

```
sudo update-alternatives --config java  #correct is /usr/lib/jvm/java-6-oracle/jre/bin/java
sudo update-alternatives --config javac #correct is /usr/lib/jvm/java-6-oracle/bin/javac
```

### Missing dependencies

If you will hit some weird compiler errors like this:

```
In file included from /usr/include/endian.h:60:0,
                 from /home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_android/prebuilts/gcc/linux-x86/host/i686-linux-glibc2.7-4.6/bin/../sysroot/usr/include/sys/types.h:217,
                 from cts/suite/audio_quality/lib/src/FileUtil.cpp:18:
/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_android/prebuilts/gcc/linux-x86/host/i686-linux-glibc2.7-4.6/bin/../sysroot/usr/include/bits/byteswap.h:22:3: error: #error &quot;Never use &lt;bits/bytesw
ap.h&gt; directly; include &lt;byteswap.h&gt; instead.&quot;
In file included from frameworks/native/include/utils/RefBase.h:24:0,
                 from frameworks/native/include/utils/Thread.h:31,
                 from frameworks/native/include/utils/threads.h:35,
                 from cts/suite/audio_quality/lib/include/FileUtil.h:24,
                 from cts/suite/audio_quality/lib/include/Log.h:24,
                 from cts/suite/audio_quality/lib/src/FileUtil.cpp:21:
/usr/include/stdlib.h:760:34: fatal error: bits/stdlib-bsearch.h: No such file or directory
```

This mean that you have missing dependencies. On Debian you can fix this with:

```
sudo apt-get install bison g++-multilib git gperf libxml2-utils make python-networkx zip xsltproc
```

After all above fixes running make again should build the image:

```
make -j$(nproc)
```

It took some time, so you can go for coffee. Final messaged for passed build should look like this:

```
Running:  simg2img out/target/product/sugar-cubietruck/obj/PACKAGING/systemimage_intermediates/system.img out/target/product/sugar-cubietruck/obj/PACKAGING/systemimage_intermediates/unsparse_system.img
Running:  e2fsck -f -n out/target/product/sugar-cubietruck/obj/PACKAGING/systemimage_intermediates/unsparse_system.img
e2fsck 1.41.14 (22-Dec-2010)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
out/target/product/sugar-cubietruck/obj/PACKAGING/systemimage_intermediates/unsparse_system.img: 1506/32768 files (0.0% non-contiguous), 100004/131072 blocks
Install system fs image: out/target/product/sugar-cubietruck/system.img
out/target/product/sugar-cubietruck/system.img+out/target/product/sugar-cubietruck/obj/PACKAGING/recovery_patch_intermediates/recovery_from_boot.p maxsize=548110464 blocksize=4224 total=403588136 reserve=5537664
```

### Pack image

```
pack
```

In output it will tell you where your image is:

```
----------image is at----------

/home/pietrushnic/storage/wdc/projects/3mdeb/cubietruck/cubietruck_android/lichee/tools/pack/sun7i_android_sugar-cubietruck.img

pack finish
/home/pietrushnic/projects/3mdeb/cubietruck/cubietruck_android/a20-android4.2_android
```

## Image installation

Image can be installed using LiveSuit. Flashing instructions can be found on [sunxi wiki](http://linux-sunxi.org/LiveSuit).

## Summary

![ct-android-1](http://3mdeb.com/wp-content/uploads/2017/07/ct-android-1.jpg)

As you can see Android boots to initial screen and it looks like we have
working prcedure for building Cubietech Android SDK. This gives good ground for
future experimentation.

Hopefully above instructions works for you and will not outdate soon. If you
found any problems/errors please let me know in comment. I you think content
can be useful to others please share.

Thanks for reading.
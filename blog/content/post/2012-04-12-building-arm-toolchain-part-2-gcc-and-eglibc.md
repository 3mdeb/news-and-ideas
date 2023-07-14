---
ID: 62734
title: 'Building ARM toolchain? part 2: gcc and eglibc'
author: piotr.krol
layout: post
published: true
date: 2012-04-12 23:54:00
archives: "2012"
tags:
  - toolchain
  - arm
  - embedded
categories:
  - OS Dev
  - App Dev
---

Unfortunately after few tries of cross compiling eglibc using different source
for instructions I alway end with hard to solve issues. Luckily, in the sources
of eglibc I noticed instructions for cross-compiling written long time ago by
Jim Blandy(I know i should start [here][1]). Lot of thanks to him for it. Below
I describe my experience which I gained during eglibc cross compilation for
`arm-unknown-linux-gnueabi` and procedure that I used. Commands below contain
some constants that I used in previous works. See [this post.][2] Eglibc library
and the compiler itself is built with many various parameters this post is not
the place to explain their meaning, please RTFM.

Checkout eglibc from svn (as alwyas I try to use a latest sources possible).
Version used r17815:

```
svn co http://www.eglibc.org/svn/trunk eglibc
```

Link working ports to GNU/Linux on some machine architectures. They are not
maintained in the official glibc source tree so we need to add it in this way:

```bash
ln -s ../ports eglibc/libc/ports/
```

Create eglibc-headers directory:

```bash
mkdir eglib-headers
cd eglib-headers
```

Configure eglibc and preliminary objects:

```bash
BUILD_CC=gcc
CC=arm-unknown-linux-gnueabi-gcc
CXX=arm-unknown-linux-gnueabi-cpp
AR=arm-unknown-linux-gnueabi-ar
RANLIB=arm-unknown-linux-gnueabi-ranlib
../eglibc/libc/configure --prefix=/usr --with-headers=$TARGET/usr/include
    --build=x86_64-pc-linux-gnu --host=arm-unknown-linux-gnueabi --disable-profile
    --without-gd --without-cvs --enable-add-ons
```

Install eglibc headers:

```bash
make install-headers install_root=$TARGET install-bootstrap-headers=yes
```

We need few object file to link shared libraries, which will be built and
installed by hand:

```bash
mkdir -p $TARGET/usr/lib
make csu/subdir_lib cp csu/crt1.o csu/crti.o csu/crtn.o $TARGET/usr/lib
```

To produce libgcc_s.so we need libc.so, but only need its dummy version
because we'll never use it. It doesn't matter what we will point as a libc.so
we use /dev/null as C file.

```bash
arm-unknown-linux-gnueabi-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o
$TARGET/usr/lib/libc.so
```

Get latest gcc sources using git repository mirror. Latest commit while writing
this post was 5b9a8c3:

```bash
cd ..
git clone git://repo.or.cz/official-gcc.git
```

Now, we can build gcc which can compile eglibc.

```bash
mkdir eglibc-gcc
cd eglibc-gcc
../official-gcc/configure --target=arm-unknown-linux-gnueabi
    --prefix=$TARGET/arm-x-tools --with-sysroot=$TARGET --disable-libssp
    --disable-libgomp --disable-libmudflap --enable-languages=c
    --with-gmp=$TARGET/arm-x-tools --with-mpfr=$TARGET/arm-x-tools
    --with-mpc=$TARGET/arm-x-tools --disable-libquadmath --build=$MACHTYPE
    --host=$MACHTYPE --with-local-prefix=$TARGET/arm-x-tools --disable-multilib
    --with-float=soft --with-pkgversion="pietrushnic" --enable-threads=no
    --enable-target-optspace --disable-nls --enable-c99 --enable-long-long
make -j4
make install
```

Configure and compile final version of eglibc.

```bash
mkdir eglibc-final
cd eglibc-final/
BUILD_CC=gcc CC=arm-unknown-linux-gnueabi-gcc CXX=arm-unknown-linux-gnueabi-cpp
AR=arm-unknown-linux-gnueabi-ar
RANLIB=arm-unknown-linux-gnueabi-ranlib
../eglibc/libc/configure --prefix=/usr --with-headers=$TARGET/usr/include
    --build=x86_64-pc-linux-gnu --host=arm-unknown-linux-gnueabi --disable-profile
    --without-gd --without-cvs --enable-add-ons
make
make install install_root=$TARGET
```

Install libelf library

```bash
wget http://www.mr511.de/software/libelf-0.8.13.tar.gz
tar zxvf libelf-0.8.13.tar.gz
cd libelf-0.8.13/
./configure --prefix=$TARGET/arm-x-tools --disable-shared --enable-static
make
make install
```

Prepare final version of gcc.

```bash
cd ..
mkdir final-gcc
cd final-gcc
../official-gcc/configure --target=arm-unknown-linux-gnueabi
    --prefix=$TARGET/arm-x-tools --with-sysroot=$TARGET --disable-libssp
    --disable-libgomp --disable-libmudflap --enable-languages=c,c++ --with-gmp=$TARGET/arm-x-tools
    --with-mpfr=$TARGET/arm-x-tools --with-mpc=$TARGET/arm-x-tools --disable-libquadmath
    --build=$MACHTYPE --host=$MACHTYPE --with-local-prefix=$TARGET/arm-x-tools --disable-multilib
    --with-float=soft --with-pkgversion="pietrushnic" --enable-threads=posix
    --enable-target-optspace --disable-nls --enable-c99 --enable-long-long
    --enable-__cxa_atexit --enable-symvers=gnu --with-libelf=$TARGET/arm-x-tools
    --enable-lto
make
make install
```

Few libraries should be copied manually

```bash
cp -d $TARGET/arm-x-tools/arm-unknown-linux-gnueabi/lib/libgcc_s.so* $TARGET/lib
cp -d $TARGET/arm-x-tools/arm-unknown-linux-gnueabi/lib/libstdc++.so* $TARGET/lib
```

Compile and install chrpath - this is useful tool to remove the rpath or runpath
setting from binary.

```bash
cd ..
sudo apt-get install libc6-i386 gcc-multilib
apt-get source chrpath
cd chrpath-0.13/ CFLAGS=-m32
./configure --prefix=$TARGET/arm-x-tools --program-prefix=arm-unknown-linux-gnueabi-
make
make install
```

Strip debug symbols

```bash
strip --strip-debug $TARGET/arm-x-tools/lib/*
$TARGET/arm-x-tools/arm-unknown-linux-gnueabi/lib/* $TARGET/arm-x-tools/libexec/*
strip --strip-unneeded $TARGET/arm-x-tools/bin/*
$TARGET/arm-x-tools/arm-unknown-linux-gnueabi/bin/*
arm-unknown-linux-gnueabi-strip --strip-debug $TARGET/lib/* $TARGET/usr/lib/*
```

At the end simple test to find out if basic functionality works:

```c
cat > hello.c << EOF
> #include <stdio.h>
> int
> main (int argc, char **argv)
> {
> puts ("Hello, world!");
> return 0;
> }
> EOF
```

Try to cross compile C file:

```bash
$TARGET/arm-x-tools/bin/arm-unknown-linux-gnueabi-gcc -Wall hello.c -o hello
```

```c++
cat > c++-hello.cc <<EOF
> #include <iostream>
> int
> main (int argc, char **argv)
> {
> std::cout return 0;
> }
> EOF
```

Try to cross compile C++ file:

```bash
$TARGET/arm-x-tools/bin/arm-unknown-linux-gnueabi-g++ -Wall c++-hello.cc -o c++-hello
```

Displays the information contained in the ELF header and in the file's segment headers:

```bash
$TARGET/arm-x-tools/bin/arm-unknown-linux-gnueabi-readelf -hl hello $TARGET/arm-x-tools/bin/arm-unknown-linux-gnueabi-readelf -hl c++-hello
```

Result should look like that:

```bash
ELF Header: Magic: 7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00 Class: ELF32 Data: 2's complement, little endian Version: 1 (current) OS/ABI: UNIX - System V ABI Version: 0 Type: EXEC (Executable file) Machine: ARM (...) Flags: 0x5000002, has entry point, Version5 EABI (...) Program Headers: (...) INTERP 0x000134 0x00008134 0x00008134 0x00013 0x00013 R 0x1 [Requesting program interpreter: /lib/ld-linux.so.3] LOAD 0x000000 0x00008000 0x00008000 0x004b8 0x004b8 R E 0x8000 (...) \``\`
```

```bash
$TARGET/arm-x-tools/bin/arm-unknown-linux-gnueabi-readelf -d $TARGET/lib/libgcc_s.so.1
```

Result should look like that:

```
(...)
Tag          Type           Name/Value
0x00000001 (NEEDED) Shared library: [libc.so.6]
0x0000000e (SONAME) Library soname: [libgcc_s.so.1]
0x0000000c (INIT) 0xcc2c (...)
```

I hope you find above manual useful. If you need more detailed descriptions it
can be found [here][3].

 [1]: http://www.eglibc.org/cgi-bin/viewvc.cgi/trunk/libc/EGLIBC.cross-building?revision=2037&view=markup
 [2]: /2012/03/20/building-arm-toolchain-part-1-libs-and
 [3]: http://www.eglibc.org/cgi-bin/viewvc.cgi/trunk/libc/EGLIBC.cross-building?view=markup

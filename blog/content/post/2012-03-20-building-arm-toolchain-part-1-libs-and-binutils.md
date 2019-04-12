---
ID: 62724
title: 'Building ARM toolchain - part 1: libs and binutils'
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/os-dev/building-arm-toolchain-part-1-libs-and-binutils/
published: true
date: 2012-03-20 23:25:00
tags:
  - embedded
categories:
  - OS Dev
  - App Dev
---
Searching the Internet for information on how to build arm toolchain from
scratch I realize that it is very hard to find  information about this matter
(and recent one even harder). I will try to fill this lack of information and
try to build toolchain. My main goal is to use a component based on the GNU
public license, and using them in as the newest version as it is possible. What
is toolchain ? (according to wikipedia):

> In software, a toolchain is the set of programming tools that are used to
create a product (typically another computer program or system of programs). The
tools may be used in a chain, so that the output of each tool becomes the input
for the next, but the term is used widely to refer to any set of linked
development tools.

### Requirements

*   Cross compiler, I create one using corsstool-ng and describe this process in 
[previous post][1]. I will use `arm-unknown-linux-gnueabi` as entry point compiler.
*   $TARGET is defined as my destination directory:

    export TARGET=/home/pietrushnic/sandbox/toolchain  


### Procedure

#### Kernel header files

1.  clone linux git repository
```
git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
```
2.  install headers $TARGET is home of our toolchain
```
make ARCH=arm INSTALL_HDR_PATH=$TARGET/usr headers_install
```

#### Libraries (gmp, mpfr, mpc)

1.  GMP (*GNU Multiple Precision Arithmetic Library*) - changeset used: 14765:0acae62fa162

* As I said before. I use "latest greatest" ;P version, and for gmp we can reach it using:

    hg clone http://gmplib.org:8000/gmp


     - create configuration files


    ./.bootstrap


*   configure

    ./configure --prefix=$TARGET/arm-x-tools --enable-shared=n --enable-static


*   compile

    make && make check && make install


1.  MPFR (*GNU Multiple Precision Floating-Point Reliably*) - version: r8103 - get latest version

    svn checkout svn://scm.gforge.inria.fr/svn/mpfr/trunk mpfr


*   create configuration file

    autoreconf -i


*   configure

    ./configure --prefix=$TARGET/arm-x-tools --enable-thread-safe  --with-gmp=$TARGET/arm-x-tools --disable-shared --enable-static


*   compile

    make && make install


1.  MPC (*Multiple Precision Complex*)- version: r1146 - checkout svn

    svn checkout svn://scm.gforge.inria.fr/svnroot/mpc/trunk mpc


*   create configuration file

    autoreconf -i


*   configure

    ./configure --prefix=$TARGET/arm-x-tools  --with-gmp=$TARGET/arm-x-tools --with-mpfr=$TARGET/arm-x-tools  --disable-shared --enable-static


*   compile

    make && make install


1.  Binutils - collection of a GNU binary tools: - checkout version from anonymous cvs

    cvs -z 9 -d :pserver:anoncvs@sourceware.org:/cvs/src


*   login create directory for checkout

    mkdir binutils
     checkout sources

    cvs -z 9 -d :pserver:anoncvs@sourceware.org:/cvs/src co binutils


*   configure

    LDFLAGS="-Wl,-rpath -Wl,$TARGET/arm-x-tools/lib" ./configure
    --build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu
    --target=arm-unknown-linux-gnueabi --prefix=$TARGET/arm-x-tools
    --disable-nls --disable-multilib --disable-werror --with-float=soft
    --with-gmp=$TARGET/arm-x-tools --with-mpfr=$TARGET/arm-x-tools
    --with-mpc=$TARGET/arm-x-tools --with-sysroot=$TARGET


*   compile

    make configure-host make make install


*   to check if everything was made correctly

    ldd $TARGET/arm-x-tools/bin/arm-unknown-linux-gnueabi-ldd
     it should show that it use library compiled previously by us:

    libz.so.1 => /home/pietrushnic/sandbox/toolchain/arm-x-tools/lib/libz.so.1  (0x00007f0086cc5000)
     This set gives us a solid base to build the compiler. However, it will be in the

[next section][2].

 [1]: /2012/03/14/quick-build-of-arm-unknown-linux
 [2]: /2012/04/12/building-arm-toolchain-part-2-gcc-and

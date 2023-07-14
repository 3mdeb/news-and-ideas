---
ID: 62724
title: 'Building ARM toolchain - part 1: libs and binutils'
author: piotr.krol
layout: post
published: true
date: 2012-03-20 23:25:00
archives: "2012"
tags:
  - embedded
  - toolchain
  - arm
categories:
  - OS Dev
  - App Dev
---

Searching the Internet for information on how to build arm toolchain from
scratch I realize that it is very hard to find  information about this matter
(and recent one even harder). I will try to fill this lack of information and
try to build toolchain. My main goal is to use a component based on the GNU
public license, and using them in as the newest version as it is possible. What
is toolchain? (according to wikipedia):

> In software, a toolchain is the set of programming tools that are used to
create a product (typically another computer program or system of programs). The
tools may be used in a chain, so that the output of each tool becomes the input
for the next, but the term is used widely to refer to any set of linked
development tools.

### Requirements

* Cross compiler, I create one using crosstool-ng and describe this process in 
  [previous post][1]. I will use `arm-unknown-linux-gnueabi` as entry point
  compiler.
* `$TARGET` is defined as my destination directory:

```bash
export TARGET=/home/pietrushnic/sandbox/toolchain  
```

### Procedure

#### Kernel header files

* Clone linux git repository

```bash
git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
```

* Install headers $TARGET is home of our toolchain

```bash
make ARCH=arm INSTALL_HDR_PATH=$TARGET/usr headers_install
```

#### Libraries (gmp, mpfr, mpc)

* GMP (*GNU Multiple Precision Arithmetic Library*) - changeset used:
  14765:0acae62fa162

  - As I said before. I use "latest greatest" ;P version, and for gmp we can reach
  it using:
```bash
hg clone http://gmplib.org:8000/gmp
```

  - create configuration files
```bash
./.bootstrap
```

  - configure
```bash
./configure --prefix=$TARGET/arm-x-tools --enable-shared=n --enable-static
```

  - compile
```bash
make && make check && make install
```
</br>

* MPFR (*GNU Multiple Precision Floating-Point Reliably*) - version: r8103

  - get latest version
```bash
svn checkout svn://scm.gforge.inria.fr/svn/mpfr/trunk mpfr
```

  - create configuration file
```bash
autoreconf -i
```

  - configure
```bash
./configure --prefix=$TARGET/arm-x-tools --enable-thread-safe  --with-gmp=$TARGET/arm-x-tools --disable-shared --enable-static
```

  - compile
```bash
make && make install
```
</br>

* MPC (*Multiple Precision Complex*)- version: r1146

  - checkout svn
```bash
svn checkout svn://scm.gforge.inria.fr/svnroot/mpc/trunk mpc
```

  - create configuration file
```bash
autoreconf -i
```

  - configure
```bash
./configure --prefix=$TARGET/arm-x-tools  --with-gmp=$TARGET/arm-x-tools --with-mpfr=$TARGET/arm-x-tools  --disable-shared --enable-static
```

  - compile
```bash
make && make install
```

* Binutils - collection of a GNU binary tools:

  - checkout version from anonymous cvs
```bash
cvs -z 9 -d :pserver:anoncvs@sourceware.org:/cvs/src
```

  - login create directory for checkout
```bash
mkdir binutils
```

  - checkout sources
```bash
cvs -z 9 -d :pserver:anoncvs@sourceware.org:/cvs/src co binutils
```

  - configure
```bash
LDFLAGS="-Wl,-rpath -Wl,$TARGET/arm-x-tools/lib" ./configure
--build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu
--target=arm-unknown-linux-gnueabi --prefix=$TARGET/arm-x-tools
--disable-nls --disable-multilib --disable-werror --with-float=soft
--with-gmp=$TARGET/arm-x-tools --with-mpfr=$TARGET/arm-x-tools
--with-mpc=$TARGET/arm-x-tools --with-sysroot=$TARGET
```

  - compile
```bash
make configure-host
make
make install
```

To check if everything was made correctly

```bash
ldd $TARGET/arm-x-tools/bin/arm-unknown-linux-gnueabi-ldd
```

It should show that it use library compiled previously by us:

```bash
libz.so.1 => /home/pietrushnic/sandbox/toolchain/arm-x-tools/lib/libz.so.1  (0x00007f0086cc5000)
```

This set gives us a solid base to build the compiler. However, it will be in the
[next section][2].

[1]: /2012/03/14/quick-build-of-arm-unknown-linux
[2]: /2012/04/12/building-arm-toolchain-part-2-gcc-and

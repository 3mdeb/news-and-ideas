---
author: Piotr Król
layout: post
published: true
post_date: 2018-06-13 10:00:00

tags:
	- qemu
	- coreboot
	- tpm
categories:
	- firmware
	- security
---

Inspire by [s3hh blog post](https://s3hh.wordpress.com/2018/06/03/tpm-2-0-in-qemu/) and recent
progress around [TPM2.0 in coreboot](TBD) I decided to give this pair a try.

# Development setup

```
sudo apt install libpixman-1-dev
git clone git://git.qemu.org/qemu.git
cd qemu
git submodule init
git submodule update --recursive
./configure --enable-tpm
make -j$(nproc)
```

There are 2 additional configuration flags that are worth to mention:

* `--enable-tcg-interpreter` - which enables TCG with bytecode interpreter
  giving very low level view of TCTI (?)
* `--enable-debug-tcg` - which enabled TCG debugging


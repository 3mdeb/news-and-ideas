---
post_title: CHIPSEC and BITS as coreboot payloads
author: Piotr Król
layout: post
published: true
post_date: 2018-08-24 13:00:00

tags:
	- bits
	- chipsec
categories:
	- Firmware
	- Security

---

There are many things happen recently around firmware validation and security.
Python and MicroPython projects evolve as industry standard tools for validation.
It is worth to note couple things related to firmware validation that happen recently:

* Our talk about [BITS and CHIPSEC as coreboot payloads](https://osfc.io/talks/bits-and-chipsec-as-coreboot-payloads) were accepted to [OSFC 2018](https://osfc.io/)
* [MicroPython was accepted as technology for UEFI Test Framework](https://software.intel.com/en-us/blogs/2018/03/08/implementing-micropython-as-a-uefi-test-framework)
* We started discussion about [CHIPSEC port to MicroPython](https://github.com/chipsec/chipsec/issues/429), based on [Twitter conversation](https://github.com/chipsec/chipsec/issues/429)

3mdeb want to follow trend and make sure we offer to customer state of the art
framework for firmware validation needs. That's why we worked with our business
partners on enabling [CHIPSEC](https://github.com/chipsec/chipsec) and [BITS](https://github.com/biosbits/bits) in coreboot.

In following post I will describe obstacles we faced while integrating both
projects and what we can do which code in current state.

# BITS host Python compilation

After long and unequal fight with Makfiles, coreboot and Python build systems
we finally figure out correct combination of flags that have to be set to
compile Python for host, which is dependency of BITS.

Our problem was that Python compilation ended up before applying required
implicit rules. It looks like built-in implicit rules use variables which were
set correctly in
[coreboot-sdk:1.52](https://hub.docker.com/r/coreboot/coreboot-sdk/) shell, but
when calling BITS Makefile from higher level Makefile those variables were not
set. This appeared in error log as follows:

```shell
(...)
No rule to make target 'Parser/printgrammar.o', needed by 'Parser/pgen'
(...)
```

If we used `make touch` we ended up with:

```shell
(...)
rm -f libpython2.7.a
ar rc libpython2.7.a Modules/getbuildinfo.o
ar rc libpython2.7.a Parser/acceler.o Parser/grammar1.o Parser/listnode.o
Parser/node.o Parser/parser.o Parser/parsetok.o Parser/bitset.o
Parser/metagrammar.o Parser/firstsets.o Parser/grammar.o Parser/pgen.o
Parser/myreadline.o Parser/tokenizer.o
ar: Parser/acceler.o: No such file or directory
make[3]: *** [Makefile:511: libpython2.7.a] Error 1
make[2]: *** [Makefile:163: build-python-host] Error 2
make[1]: *** [Makefile:39: build] Error 2
make: *** [payloads/external/Makefile.inc:177: bits] Error 2
rm build/util/cbfstool/fmd_parser.c build/util/cbfstool/fmd_scanner.c
```

Crucial tool was code snippet used for dumping Makefile variables form this
[StackOverflow answer](https://stackoverflow.com/a/32768048/587395).

We placed following code in Makefile before all targets:

```
$(foreach v, $(.VARIABLES), $(info $(v) = $($(v))))
```

Finally after comparing variables we narrow down that key one that we have
already set, but incorrectly is `MAKEFLAGS`. Following line in BITS Makefile
solved our problem:

```
$(MAKE) -C bits bits_grub_env MAKEFLAGS="w"
```

# Missing package in coreboot-sdk

Next complain from Python was missing `zip` package in `coreboot-sdk`
container. That was pretty easy to work around, we created `coreboot-sdk-bits`
which extend `coreboot-sdk:1.52` by `zip` package.

This can be as simple as:

```
FROM coreboot/coreboot-sdk:1.52

USER root

RUN \
        apt-get -qq update && \
        apt-get -qqy install \
                zip \
        && apt-get clean

USER coreboot
```



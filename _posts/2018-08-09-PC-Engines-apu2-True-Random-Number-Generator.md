---
post_title: PC Engines apu2 - using True Random Number Generator
author: Piotr Król
layout: post
published: true
post_date: 2018-08-09 16:00:00

tags:
	- linux
    - apu2
categories:
	- firmware
---

AMD SoC on which PC Engines apu2 (GX-412TC) contain PSP, which expose couple
features through Linux CCP (Crypto CoProcessor) driver. Quick look at Kconfig
may give some idea about features this driver may provide:

```
CRYPTO_DEV_CCP_DD
	tristate "Secure Processor device driver"
	depends on CPU_SUP_AMD || ARM64
	default m
	help
	  Provides AMD Secure Processor device driver.
	  If you choose 'M' here, this module will be called ccp.

config CRYPTO_DEV_SP_CCP
	bool "Cryptographic Coprocessor device"
	default y
	depends on CRYPTO_DEV_CCP_DD
	select HW_RANDOM
	select DMA_ENGINE
	select DMADEVICES
	select CRYPTO_SHA1
	select CRYPTO_SHA256
	help
	  Provides the support for AMD Cryptographic Coprocessor (CCP) device
	  which can be used to offload encryption operations such as SHA, AES
	  and more.

config CRYPTO_DEV_CCP_CRYPTO
	tristate "Encryption and hashing offload support"
	default m
	depends on CRYPTO_DEV_CCP_DD
	depends on CRYPTO_DEV_SP_CCP
	select CRYPTO_HASH
	select CRYPTO_BLKCIPHER
	select CRYPTO_AUTHENC
	select CRYPTO_RSA
	help
	  Support for using the cryptographic API with the AMD Cryptographic
	  Coprocessor. This module supports offload of SHA and AES algorithms.
	  If you choose 'M' here, this module will be called ccp_crypto.

config CRYPTO_DEV_SP_PSP
	bool "Platform Security Processor (PSP) device"
	default y
	depends on CRYPTO_DEV_CCP_DD && X86_64
	help
	 Provide support for the AMD Platform Security Processor (PSP).
	 The PSP is a dedicated processor that provides support for key
	 management commands in Secure Encrypted Virtualization (SEV) mode,
	 along with software-based Trusted Execution Environment (TEE) to
	 enable third-party trusted applications.
```

It looks there are quite useful functions that can help in cryptographic
operations. Unfortunately at first glance it is not clean how to use them.
Quick research say that there are in general 2 methods:

* cryptodev - BSD originated methodology
* AF_ALG

# How to measure entropy quality in practice

This is scientific question, but we want to try to answer it in engineering
terms. Ideally it would be to have some tool that can validate or measure
entropy. It happen that there are couple tools that can be found through
stackoverflow suggestions:
https://unix.stackexchange.com/questions/31779/tool-for-measuring-entropy-quality

I decided to test 3:

* ent
* binwalk
* dieharder

# Community discussion

https://forum.ipfire.org/viewtopic.php?f=51&t=16032&p=118000#p118000

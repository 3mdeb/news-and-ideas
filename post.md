---
post_title: fTPM vs dTPM
author: Bartek Pastudzki
layout: post
published: false
post_date: 2018-05-08 15:00:00

tags:
	-TPM
	-firmware
    -hardware
categories:
	-security
---

One of the most important topics in firmware security is TPM. We pay much
attention to it in our trainings. While preparing them, one thing seemed
unclear, what is a practical difference between its implementations: dTPM
(discrete TPM), fTPM (firmware TPM), sTPM (software TPM) and others. It's
quite easy to say what they are: dTPM is a separate chip conforming to the
TPM specification, fTPM and sTPM are pieces of software implementing the
same functions as respectively firmware module and a regular program ran in
the user space, the others are intermediate solutions.

It is much harder to say what is the difference from the security point of
view. We would love to say what guaratees we get from each of them, but it's
not that simple, because it depends a lot on a case. We can say a lot about
dTPM because it is well specified: it's not designed to prevent a physical attack,
it provides essential asymmetric cryptography functions, secure storage,
independent entropy source, secure clock, etc. For other implementations, we
can say that they are faster (because dTPM is slow by design) and less secure.
How much? It depends.

Of course, it depends on the overall security level of the system. If the firmware
is writable for an attacker it could be replaced with other versions. If there is
Secure Boot, another official firmware without fTPM (if exists) could be used.
If there is no Secure Boot, virtually any firmware could be used. Similarly, we
would analyze the OS security level in the case of sTPM.

The much more tricky part is particular functions provided by TPM. For example,
how secure storage is implemented? Perhaps it's in SPI chip? sTPM would probably
need to use regular files, but if we have Intel SGX it could provide secure
storage. On different platforms, we have different security facilities, the most
popular are TXT and SGX for Intel and TrustZone for ARM. There could be other
ones too. 

That's why if we want to reason about fTPM security we have to consider all
security facilities on the platform. There are few documents which do such
considerations: [on ARM platform](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/msr-tr-2015-84.pdf),
[another](https://www.usenix.org/system/files/conference/usenixsecurity16/sec16_paper_raj.pdf).
The documentation of platform features may be useful to estimate which could
be useful: [TXT](https://www.intel.com/content/www/us/en/architecture-and-technology/trusted-execution-technology/trusted-execution-technology-security-paper.html), [SGX](https://software.intel.com/sites/default/files/managed/48/88/329298-002.pdf),
[TPM in short](https://trustedcomputinggroup.org/wp-content/uploads/TPM-2.0-A-Brief-Introduction.pdf),
[TPM spec](https://trustedcomputinggroup.org/tpm-library-specification/). We
should also always think what do we need fTPM for, some of its shortcomings
may be irrelevant if it doesn't affect functions we use.

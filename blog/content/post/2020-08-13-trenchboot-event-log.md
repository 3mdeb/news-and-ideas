---
title: "TrenchBoot: Open Source DRTM. TPM event log all the way."
abstract: We extended the TPM event log support to the Linux kernel. It is now
          possible to print all of the PCR extend operations performed and
          compare the hashes with files to see if anything is wrong.
cover: /covers/trenchboot-logo.png
author: krystian.hebel
layout: post
published: true
date: 2020-08-13
archives: "2020"

tags:
  - open-source
  - trenchboot
  - linux
categories:
  - Firmware
  - Security

---

If you haven't read previous blog posts from _TrenchBoot_ series, we strongly
encourage to catch up on it. Best way, is to search under
[TrenchBoot](https://blog.3mdeb.com/tags/trenchboot/) tag. In this article, we
will take a deeper look into the reworked `extend_all.sh` script, along with
`util.sh` which is sourced by it, to show how it can be used to check if the PCR
values are proper.

## New event log entries

You can follow the
[verification instructions](https://blog.3mdeb.com/2020/2020-07-03-trenchboot-grub-cbfs/#tpm-event-log-verification)
from the previous TrenchBoot post, up to the part where the log entries are read
with `cbmem` tool. Remember that `cbmem` requires kernel built with
`CONFIG_IO_STRICT_DEVMEM` disabled or with `iomem=relaxed` in the command line!

The following instructions assume TPM2.0, for TPM1.2 change `sha256` to `sha1`
in the commands. The output format of the event log is also slightly different.
If in doubt, refer to the previous post.

This is the example log:

```bash
$ ./cbmem -d
DRTM TPM2 log:
        Specification: 2.00
        Platform class: PC Client
        Vendor information:
DRTM TPM2 log entry 1:
        PCR: 17
        Event type: Unknown (0x600)
        Digests:
                 SHA1: f3068ca458dc3da80d4112b8427fe95f54bf36c4
                 SHA256: adf38a252637fcaca26bb89ecceafc6ba75cb0f5237ca8e72294b75a1cff0a0a
        Event data not provided
DRTM TPM2 log entry 2:
        PCR: 17
        Event type: Unknown (0x601)
        Digests:
                 SHA1: e788e8bab7ecbe9a01467b7333b2008f2a2ce807
                 SHA256: 0e2377e55314d964833e2d1f4e64c026e2b72c8f1a608af3e668fcccae73102c
        Event data: Measured Kernel into PCR17
DRTM TPM2 log entry 3:
        PCR: 18
        Event type: Unknown (0x502)
        Digests:
                 SHA256: ab4ebda5c87f7df10e2d1e228ea7b1b88f02570e5d29ceaf9dc39f9728f57275
        Event data: Measured boot parameters into PCR18
DRTM TPM2 log entry 4:
        PCR: 18
        Event type: Unknown (0x502)
        Digests:
                 SHA1: 08737f3626b473b492a06bba574069bb6a47c768
        Event data: Measured boot parameters into PCR18
DRTM TPM2 log entry 5:
        PCR: 18
        Event type: Unknown (0x502)
        Digests:
                 SHA256: 05b7e23226395cd56288998e34ebb641829a172def433f7878b8f5022de1874e
        Event data: Measured Kernel command line into PCR18
DRTM TPM2 log entry 6:
        PCR: 18
        Event type: Unknown (0x502)
        Digests:
                 SHA1: 72e9db8d3005f7a8a74b6abc45f478fd93589fc6
        Event data: Measured Kernel command line into PCR18
DRTM TPM2 log entry 7:
        PCR: 17
        Event type: Unknown (0x502)
        Digests:
                 SHA256: 1f862d0ddc20d8c04b001cbe1d5aed1d839117e8d342913f6dcf161b9329b26d
        Event data: Measured initramfs into PCR17
DRTM TPM2 log entry 8:
        PCR: 17
        Event type: Unknown (0x502)
        Digests:
                 SHA1: 52cb45a1f8012064b689a4aa03a01f0ade165369
        Event data: Measured initramfs into PCR17
```

> This particular entries come from development version, the final hashes are
> different.

You can see that there are new entries. Lets check if those are correct.

### extend_all.sh

This script was used since
[one of the first posts about TrenchBoot](https://blog.3mdeb.com/2020/2020-04-03-trenchboot-nlnet-lz-validation/).
In this release, it was rewritten to be easier to understand, and also to have
option to reuse some of the functions implemented there. This is the source of
that file:

```bash
#!/bin/bash
. util.sh

if [[ $# -eq 2 ]] && [[ -e "$1" ]] && [[ -e "$2" ]] ; then
 extend_sha1 $sha1_zeroes $(sha1_lz) $(sha1_kernel "$1") "$2"
 extend_sha256 $sha256_zeroes $(sha256_lz) $(sha256_kernel "$1") "$2"
elif [[ $# -eq 1 ]] && [[ -e "$1" ]] ; then
 extend_sha1 $sha1_zeroes $(sha1_lz) $(sha1_kernel "$1")
 extend_sha256 $sha256_zeroes $(sha256_lz) $(sha256_kernel "$1")
else
 echo "Usage: $0 path/to/bzImage [path/to/initrd]"
 exit
fi
```

Basically, it is a wrapper for functions in `util.sh`. It calls function
`extend_sha*` which takes hashes or files as arguments. Those arguments in the
first case are, in order: initial PCR value after initialization (all zeros),
hash of measured part of LZ, hash of protected mode part of the kernel and path
to the initramfs.

The second branch accounts for the fact that it is possible to embed the
initramfs image inside the kernel itself. Utility functions called in both cases
will be described later.

We can run this script for our kernel and initramfs and compare the result with
the output of `tpm2_pcrread`:

```bash
$ ./extend_all.sh path/to/bzImage path/to/initrd
545e5cccba8775c28f07f9ed214d73e0167b002d  SHA1
86319148902e0f12fb1fc286c46fec26b3a7b7f0e8480b591c4b0a8d5034356a  SHA256
```

```bash
$ tpm2_pcrread
sha1:
  0 : 0x3A3F780F11A4B49969FCAA80CD6E3957C33B2275
  1 : 0x80CA0AADA4C98E3C9797BE92E5261E106AFD7793
  2 : 0xB22A535AC80CCA8A49AD1AD87729826F492D537E
  3 : 0x3A3F780F11A4B49969FCAA80CD6E3957C33B2275
  4 : 0xA9FDEB07A0C479C74E3DB3E9493D2C3189766507
  5 : 0x3A3F780F11A4B49969FCAA80CD6E3957C33B2275
  6 : 0x3A3F780F11A4B49969FCAA80CD6E3957C33B2275
  7 : 0x3A3F780F11A4B49969FCAA80CD6E3957C33B2275
  8 : 0x0000000000000000000000000000000000000000
  9 : 0x0000000000000000000000000000000000000000
  10: 0x0000000000000000000000000000000000000000
  11: 0x0000000000000000000000000000000000000000
  12: 0x0000000000000000000000000000000000000000
  13: 0x0000000000000000000000000000000000000000
  14: 0x0000000000000000000000000000000000000000
  15: 0x0000000000000000000000000000000000000000
  16: 0x0000000000000000000000000000000000000000
  17: 0x545E5CCCBA8775C28F07F9ED214D73E0167B002D
  18: 0x977C776804B7ABFC751E30083289768B18FF4D08
  19: 0x0000000000000000000000000000000000000000
  20: 0x0000000000000000000000000000000000000000
  21: 0x0000000000000000000000000000000000000000
  22: 0x0000000000000000000000000000000000000000
  23: 0x0000000000000000000000000000000000000000
sha256:
  0 : 0xD27CC12614B5F4FF85ED109495E320FB1E5495EB28D507E952D51091E7AE2A72
  1 : 0x720FC75DDE167872E2424925353EA58DDD0CC9DF2F2F4E935030CC9C758BF24B
  2 : 0xBA872DA33291301EA2B9A61F310743FECF43BC0014075B80D61A0130DA072E94
  3 : 0xD27CC12614B5F4FF85ED109495E320FB1E5495EB28D507E952D51091E7AE2A72
  4 : 0xEEA509AA8A7554B7B4040C44A580660923246633B3593D0547D4FD52841971E0
  5 : 0xD27CC12614B5F4FF85ED109495E320FB1E5495EB28D507E952D51091E7AE2A72
  6 : 0xD27CC12614B5F4FF85ED109495E320FB1E5495EB28D507E952D51091E7AE2A72
  7 : 0xD27CC12614B5F4FF85ED109495E320FB1E5495EB28D507E952D51091E7AE2A72
  8 : 0x0000000000000000000000000000000000000000000000000000000000000000
  9 : 0x0000000000000000000000000000000000000000000000000000000000000000
  10: 0x0000000000000000000000000000000000000000000000000000000000000000
  11: 0x0000000000000000000000000000000000000000000000000000000000000000
  12: 0x0000000000000000000000000000000000000000000000000000000000000000
  13: 0x0000000000000000000000000000000000000000000000000000000000000000
  14: 0x0000000000000000000000000000000000000000000000000000000000000000
  15: 0x0000000000000000000000000000000000000000000000000000000000000000
  16: 0x0000000000000000000000000000000000000000000000000000000000000000
  17: 0x86319148902E0F12FB1FC286C46FEC26B3A7B7F0E8480B591C4B0A8D5034356A
  18: 0x05FE7E92876C349954A766ACC7F5FCE64A1A78FD4C5FC4B4E8D19856AFFD3DBA
  19: 0x0000000000000000000000000000000000000000000000000000000000000000
  20: 0x0000000000000000000000000000000000000000000000000000000000000000
  21: 0x0000000000000000000000000000000000000000000000000000000000000000
  22: 0x0000000000000000000000000000000000000000000000000000000000000000
  23: 0x0000000000000000000000000000000000000000000000000000000000000000

```

No surprise here, the value of PCR 17 matches the one calculated by the script.
Usually this is enough to prove that the platform is in a more or less known
state and there is no reason to check the event log, it is more useful to check
it when those values differ, but we will do this anyway.

### util.sh

This is the file where all the heavy lifting takes place. Below is a description
of that code. All `sha1*` functions and variables have their `sha256*`
counterparts, not listed below.

```bash
SLB_FILE=${SLB_FILE:=lz_header.bin}
SL_SIZE=`hexdump "$SLB_FILE" -s2 -n2 -e '/2 "%u"'`
```

Two constants connected with Landing Zone: `SLB_FILE` is the file name which can
be overrode during invocation of the script. LZ (or SLB using AMD terminology)
starts with two 16b numbers. The first one is the offset to the entry point, the
second one is the length of measured part. That second number is extracted and
saved in `SL_SIZE`.

```bash
sha1_zeroes=`printf "0%.0s" {1..40}`
sha256_zeroes=`printf "0%.0s" {1..64}`
```

Two constants with initial values of PCRs - all zeroes. Included here to avoid
tedious task of repeating and counting zeroes.

```bash
sha1_kernel () {
 local KERNEL_PROT_SKIP=$((`hexdump "$1" -s0x1f1 -n1 -e '/1 "%u"'` * 512 + 512))
 dd if="$1" bs=1 skip=$KERNEL_PROT_SKIP 2>/dev/null | sha1sum | grep -o "^[a-fA-F0-9]*"
}
```

This function takes a path to the Linux kernel as an argument.

Historically, Linux was started in real mode (RM, 16 bits), where it could
gather all necessary information required to boot using the
[BIOS interrupt calls](https://en.wikipedia.org/wiki/BIOS_interrupt_call). It
saved all gathered data in a structure called zero page and jumped into the
protected mode (PM). These two modes are two separate pieces of bzImage file.

Nowadays, the zero page is prepared by the bootloader and the kernel is started
already in the protected mode. The code from the RM part is no longer used,
except for the initial copy of the zero page, because it includes e.g. boot
protocol version to which the bootloader must comply.

Another important field of zero page is the size of the RM part. It is
[specified as the additional number of disk sectors](https://www.kernel.org/doc/html/latest/arch/x86/boot.html#details-of-header-fields)
(512 bytes) that must be loaded, not counting the first sector. This size (in
bytes) is obtained by the first line. The second line reads the other part of
the file (the PM part) and calculates its hash.

```bash
sha1_lz () {
 dd if="$SLB_FILE" bs=1 count=$SL_SIZE 2>/dev/null | sha1sum | grep -o "^[a-fA-F0-9]*"
}
```

Calculates hash of the measured part of the LZ, uses constants defined earlier.

```bash
validate_and_escape_hash () {
 local TRIM=`echo -n "$1" | sed -r -e "s/ .*//"`
 if (( ${#TRIM} != 64 && ${#TRIM} != 40 )); then
  >&2 echo "\"$TRIM\" is not a valid SHA1/SHA256 hash"
  return
 fi
 echo -n $TRIM | sed -r -e "s/([a-f0-9]{2})/\\\x\1/g"
}
```

Removes anything that comes after the hash (usually file name), checks its
length and transforms the hex string into an escaped format.

> Example: '01fe23dc45ba...' is transformed to
> '\\x01\\xfe\\x23\\xdc\\x45\\xba...'

```bash
extend_sha1 () {
 local HASH1
 local HASH2
 case $# in
 [01] ) >&2 echo "extend_sha1 called with not enough arguments provided"
  return
  ;;
 2 ) if [ -f "$2" ]; then
   HASH1="$1"
   HASH2=`dd if="$2" 2>/dev/null | sha1sum`
  else
   HASH1="$1"
   HASH2="$2"
  fi
  ;;
 * ) HASH1=$(extend_sha1 "$1" "$2")
  shift 2
  extend_sha1 "$HASH1" $@
  return
  ;;
 esac
 local HASH1_ESC=$(validate_and_escape_hash "$HASH1")
 local HASH2_ESC=$(validate_and_escape_hash "$HASH2")
 printf "%b" $HASH1_ESC $HASH2_ESC | sha1sum | sed "s/-/SHA1/"
}
```

This function does the extend operation. It takes two or more arguments, which
are either hashes or file names, and performs what the PCR extension would do:
concatenates the old value of PCR (first argument) with the new hash (second
argument) and hashes the result. All of the data is expected to be in binary
form, this is why `validate_and_escape_hash` transforms the string.

`extend_sha*` deliberately does not take the file name as the first argument.
There are no cases where the PCR would have a new value written to it, the only
possible way of changing the PCR (other than reset) is to extend it.

#### Debugging potential issues using DRTM TPM event log

For the sake of argument, lets assume that the current value of PCR 17 is not
what we expected it to be, i.e. not what `extend_all.sh` returns.

We will need the utility functions and variables. It is good to start with
sourcing the file, so we won't have to craft new scripts for every test:

```bash
. util.sh
```

First order of business is to take a look at the event log and check if all of
the expected entries are there. If they end at some point, most likely the
module that was measured most recently is broken - remember that each module is
expected to measure the next one.

If all of the entries appear to be in order, we should check the result of
extending the PCR using the values from the event log. Assuming we are using the
log from [above](#new-event-log-entries), we can do this with command:

```bash
extend_sha256 \
  $sha256_zeroes \
  adf38a252637fcaca26bb89ecceafc6ba75cb0f5237ca8e72294b75a1cff0a0a \
  0e2377e55314d964833e2d1f4e64c026e2b72c8f1a608af3e668fcccae73102c \
  1f862d0ddc20d8c04b001cbe1d5aed1d839117e8d342913f6dcf161b9329b26d
```

This can be done in a single line, but splitting that command makes it easier to
describe. Line 2 "resets" PCR to all zeroes - if we want to check what would be
the PCR value after extending it with new hash, we can put there the current
value instead. Lines 3-5 are hashes from the log **for PCR 17 only**. They must
be passed in order, PCR extend operation is not commutative.

While it is good to always take a look at the log, the same can be done without
copying the hashes manually:

```bash
extend_sha256 $sha256_zeroes \
  `cbmem -d | grep "PCR: 17" -A4 | grep "SHA256: .*" -o | cut -d" " -f2`
```

There are few possible outcomes:

- the result is the same as `extend_all.sh` - there were additional extend
  operations, most likely after the last one (initramfs), but without logging OR
  the TPM extend operation did not succeeded
- the result is the same as the current PCR value - it means that every measured
  component was also logged, so it should be easy to pinpoint the modified one
- none of the above - files passed to `extend_all.sh` are different than the
  ones that were actually run AND not all extend operations were properly logged

For the first one, the debug process using event log ends here, we can't get
anywhere further that way. It may be helpful to check if the PCR value is the
same after a reboot or another DRTM invocation. You may also try running:

```bash
SLB_FILE=/dev/null ./extend_all.sh path/to/bzImage path/to/initrd
```

If the real PCR value is the same as the result of the above script, it may
indicate that the CPU was not in the proper state before DRTM. See also
[troubleshooting](https://blog.3mdeb.com/2020/2020-06-01-ipxe_lz_support/#troubleshooting).

The other two require comparing logged values with ones calculated directly from
files. For the Landing Zone this can be done with one of:

```bash
sha256_lz
SLB_FILE=path/to/lz_header.bin sha256_lz
```

Simple `sha256_lz` measures `lz_header.bin` in the current directory, the second
option lets the user specify another path and name.

To measure the kernel:

```bash
sha256_kernel path/to/bzImage
```

Initramfs is treated as a flat file, it is measured as a whole:

```bash
sha256sum path/to/initrd
```

This hopefully helps to find out which of the components was modified.

## Additional changes

Code for TPM support no longer consists of one big, merged file, it uses the
original form of [tpmlib](https://github.com/TrenchBoot/tpmlib) instead. It is
included as a git submodule, which should make it easier to keep up to date.

This also fixed some issues with extend operation for TPM1.2 - previously it
worked only for the first invocation of the function. Code for TPM2.0 was also
reworked - while it worked, some of the variables had misleading names, and the
buffer management was used in kind of hacky way.

Another change is that the kernel now also extends PCRs with all available hash
algorithms, instead of using only the first one it finds (SHA256 in most cases
for TPM2.0). It can be seen in the event log as additional entries for the same
event, as well as in final PCR values. They now match the ones predicted by
`extend_all.sh`, both for SHA1 and SHA256.

All of the above fixes, along with the fact that the values from the event log,
PCRs and `extend_all.sh` match, assure the correct operation of TPM TIS
interface in the Landing Zone and Linux kernel. This was the requirement we set
for ourselves for the previous month.

We also updated our CI. It should properly test all the changes that are to be
merged into the upstream repositories. Test includes building the Linux kernel,
GRUB2 and Landing Zone, as well as running them on test platforms and comparing
the PCR 17 values with the expected ones.

## Summary

This release made changes introduced in the previous one actually useful. As
shown, it is now possible to check hash of each measured component separately,
instead of relying on single binary output (PCR is either valid or not). This
additional information makes it possible to narrow down the fault search area,
we do not need to resort to shotgun debugging anymore. While this may seem
trivial for this simple case where only LZ, kernel and initrd are measured, this
will greatly help with more complicated cases with many more measured modules.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up for our newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

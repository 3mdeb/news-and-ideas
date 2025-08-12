---
title: "ram-wipe: Further analysis"
abstract: 'The `init_on_free` Linux option ensures rigorous security by
instantly zeroing out memory upon deallocation. In this follow-up, we build on
our prior ram-wipe experiments to rigorously evaluate if `init_on_free` can
serve as a robust safeguard, perhaps supplanting existing, less comprehensive
memory wiping solutions.'
cover: /covers/ram-wipe.png
author: kamil.aronowski
layout: post
published: true
date: 2025-08-12
archives: "2025"

tags:
  - attack
  - dasharo
  - debian
  - encryption
  - firmware
  - linux
  - luks
  - open-source
  - qemu
  - ram
  - uefi
  - warm
  - wipe
categories:
  - Firmware
  - Security

---

This post will follow up on our journey with the secure [ram-wipe
solution](https://github.com/kicksecure/ram-wipe). After [diving deep into its
capabilities recently](https://blog.3mdeb.com/2025/2025-05-20-ram-wipe/), we
are excited to share our heartfelt discoveries of how [our modified, simplified
version](https://github.com/zarhus/ram-wipe/tree/88091fea2c58c7f1345c4a05e92fddfecbe1d807)
fiercely protects your data from unseen RAM-based attacks. Join us in unveiling
this essential defense that could change the future of operational security.

This research has been supported by [Power Up
Privacy](https://powerupprivacy.com/), a privacy advocacy group that seeks to
provide support to privacy projects so they can accomplish their objective of
improving the world.

## Introduction

The `init_on_free` boot option enables a mechanism in Linux that zeroes out
memory after it has been freed. According to [its relevant thread in the Linux
Kernel Mailing
List](https://lore.kernel.org/all/20190617151050.92663-1-glider@google.com/),

> Enabling init_on_free also guarantees that pages and heap objects are
> initialized right after they're freed, so it won't be possible to access
> stale data by using a dangling pointer.
>
> [...]
>
> The init_on_free feature is regularly requested
> by folks where memory forensics is included in their thread models.

A good approach to operational security involves the knowledge of how exactly
one's tools operate and what their limitations are. It would be disastrous to
expect a workstation with anti-memory forensics mechanisms to fail at the most
unexpected time and place. As the [Kicksecure documentation on
ram-wipe](https://www.kicksecure.com/wiki/Dev/RAM_Wipe#ram-wipe_improvements)
suggests, several ram-wipe components might require improvements.

Today, we will explore an alternative: whether it's sufficient to replace the
aforementioned troublesome mechanisms with the kernel-supplied `init_on_free`
option to protect against user space information disclosure.  We'll try to
perform the same [warm boot attack as last
time](https://blog.3mdeb.com/2025/2025-05-20-ram-wipe/#introduction-to-ram-attacks)
and see how much data we can recover.

## Testing methodology and tools

Just like in [our earlier
exploration](https://blog.3mdeb.com/2025/2025-05-20-ram-wipe/#testing-methodology-and-tools),
we will experiment with the same [EFI
application](https://github.com/zarhus/ram-dump-efi) for determining the
locations of EFI structures and dumping the memory after a system reboot.
Furthermore, we will use the [Dasharo firmware,
v0.2.1](https://docs.dasharo.com/variants/qemu_q35/releases/#v021-2025-05-30),
which has proven itself as a stable, mature solution for both production use
and test platforms. We will modify the [ram-wipe
tooling](https://github.com/Kicksecure/ram-wipe/tree/2a7ff83a19714b68496d696aeb83fe2f0da5103b)
by removing the [non-robust sdmem mechanism and the second wipe
pass](https://www.kicksecure.com/wiki/Dev/RAM_Wipe#ram-wipe_improvements), and
relying on the `init_on_free` option [supplied as a GRUB
drop-in](https://github.com/Kicksecure/ram-wipe/blob/2a7ff83a19714b68496d696aeb83fe2f0da5103b/etc/default/grub.d/40_ram-wipe.cfg).
At last, we will analyze the dumped memory, if no user space information
disclosure took place, especially the LUKS secret key.

From power on to power down, this diagram provides a high-level overview of the
updated ram-wipe installation in action.

![ram-wipe-further-analysis-flowchart](/img/ram-wipe-further-analysis/ram-wipe-further-analysis-flowchart.svg)

<!-- The flowchart above was created by 3mdeb and adheres to ISO-5807. -->

## Testing environment

We will [once
again](https://blog.3mdeb.com/2025/2025-05-20-ram-wipe/#testing-environment)
use [Debian Trixie](https://wiki.debian.org/DebianTesting) installed on [QEMU
with Dasharo](https://docs.dasharo.com/variants/qemu_q35/overview/) as our test
system, with `rootfs` and `swap` space encrypted with LUKS. Then, we will
install [our modified version of ram-wipe with no `sdmem` mechanism, and only
one wiping
stage](https://github.com/zarhus/ram-wipe/tree/88091fea2c58c7f1345c4a05e92fddfecbe1d807).

After Debian has been installed, we can dump the LUKS secret key for future
comparison:

```bash {linenos=inline hl_lines=["17-20"]}
user@debian:~$ sudo cryptsetup luksDump --dump-master-key /dev/sda3

WARNING!
========
The header dump with volume key is sensitive information
that allows access to encrypted partition without a passphrase.
This dump should be stored encrypted in a safe place.

Are you sure? (Type 'yes' in capital letters): YES
Enter passphrase for /dev/sda3:
LUKS header information for /dev/sda3
Cipher name:    aes
Cipher mode:    xts-plain64
Payload offset: 32768
UUID:           00b4b79c-209a-4dcf-adf3-7e310778f583
MK bits:        512
MK dump:        88 fb 2f aa 42 be 5c cd 6b f0 2f 32 5d e8 e6 4a
                b6 31 41 67 62 35 79 ab 56 ca 65 ce 18 ff b5 18
                60 1a 95 c1 0f 7e ea 5c c4 9d 8e 62 42 b8 50 ca
                af 80 a9 87 84 f7 cb 3c 25 d4 15 f1 c6 1f 6b 6a
```

> **Important note**: This is a laboratory setting, hence why the key
> disclosure was done on purpose. Do not share your secrets in production
> environments.

Currently, the initramfs-tools utility supplied by Debian [does not support the
functionality required by
ram-wipe](https://www.kicksecure.com/wiki/Dev/RAM_Wipe#Status_of_initramfs-tools_Support).
Therefore, we migrate to `dracut`:

```bash
sudo sed -i 's@deb cdrom@#deb cdrom@g' /etc/apt/sources.list
sudo apt-get update -y
sudo apt-get install -y dracut
sudo dracut -f
```

Then, as the [Kicksecure documentation](https://www.kicksecure.com/wiki/Dracut)
suggests, we add the text

```console
hostonly=yes
hostonly_mode=sloppy
```

to `/etc/dracut.conf.d/fix.conf` and regenerate initrd:

```bash
sudo dracut -f
```

Next, we install the [modified version of
ram-wipe](https://github.com/zarhus/ram-wipe/tree/88091fea2c58c7f1345c4a05e92fddfecbe1d807)
and its `helper-scripts` dependency:

```bash
$ sudo apt-get install -y build-essential debhelper debhelper-compat dh-python\
dh-apparmor config-package-dev git
$ git clone https://github.com/Kicksecure/helper-scripts.git
$ cd helper-scripts/
$ git checkout 3541096b268da484b9481a06fa642d7a24f71089
$ dpkg-buildpackage -b
$ cd -
$ sudo apt install ./helper-scripts_35.0-1_all.deb
$ git clone https://github.com/Zarhus/ram-wipe.git
$ cd ram-wipe/
$ git checkout 88091fea2c58c7f1345c4a05e92fddfecbe1d807
$ dpkg-buildpackage -b
$ cd -
$ sudo apt install ./ram-wipe_3.6-1_all.deb
$ sudo dracut -f
$ sudo reboot
```

We can confirm that `dracut` is being used, as well as ram-wipe being executed
just before the system is restarted:

```console {linenos=inline hl_lines=["12-15"]}
Broadcast message from root@debian on pts/0 (Thu 2025-08-14 03:28:17 EDT):

The system will reboot now!

user@debian:~$
device-mapper: core: CONFIG_IMA_DISABLE_HTABLE is disabled. Duplicate IMA measurements will not be recorded in the IMA log.
at24 0-0050: supply vcc not found, using dummy regulator
[  OK  ] Stopped session-2.scope - Session 2 of User user.
[  OK  ] Stopped user@110.service - User Manager for UID 110.
[...]
[   42.017416] watchdog: watchdog0: watchdog did not stop!
[   42.474323] dracut INFO: wipe-ram.sh: RAM extraction attack defense... Starting RAM wipe pass during shutdown...
[   42.501159] dracut INFO: wipe-ram.sh: RAM wipe pass completed, OK.
[   42.502837] dracut INFO: wipe-ram.sh: Checking if there are still mounted encrypted disks...
[   42.508801] dracut INFO: wipe-ram.sh: Success, there are no more mounted encrypted disks, OK.
[   42.530125] reboot: Restarting system
```

## Modified ram-wipe's warm boot attack tests

The testing steps are the same as in [our earlier
laboratory](https://blog.3mdeb.com/2025/2025-05-20-ram-wipe/#ram-wipe-tests),
except there is only one stage.
We will

1. Boot to [our EFI application](https://github.com/zarhus/ram-dump-efi) and
   choose option 1 to write the pattern.
1. Reboot to the application and select option 2 to exclude RAM modified by
   firmware.
1. Reboot to our Debian installation, decrypt the `rootfs` volume, and reboot to
   run ram-wipe.
1. Reboot to the application and dump memory.

The available memory ranges received by the EFI application are:

```console
Available RAM [            1000 -            86FFF]
Available RAM [           88000 -            9FFFF]
Available RAM [          100000 -           7FFFFF]
Available RAM [         1630000 -         7BD1FFFF]
Available RAM [        7BD40000 -         7D65DFFF]
Available RAM [        7D7EE000 -         7D825FFF]
Available RAM [        7E2F2000 -         7E36AFFF]
Available RAM [        7E380000 -         7E38FFFF]
Available RAM [        7E39B000 -         7E3A0FFF]
Available RAM [        7E3A2000 -         7E3A3FFF]
Available RAM [        7FC00000 -         7FC58FFF]
Available RAM [        7FD20000 -         7FD2EFFF]
Found 510173 pages of available RAM (1992 MB)
```

With the following pages and addresses excluded (reserved for firmware):

```console
Exclude modified by firmware was selected
...   0%
Excluding range @ 0x10000, 119 pages

Excluding range @ 0x88000, 24 pages
...  98%
Excluding range @ 0x7BD40000, 8 pages
...  99%
Excluding range @ 0x7D7EE000, 56 pages

Excluding range @ 0x7E2F2000, 121 pages

Excluding range @ 0x7E380000, 16 pages

Excluding range @ 0x7E39B000, 6 pages

Excluding range @ 0x7E3A2000, 2 pages
... 100%
Exclude modified by firmware done
```

By reading `/proc/iomem`, we can see that the kernel is loaded under the
following addresses, which should be excluded from the analysis:

```console
[...]
00100000-7d763017 : System RAM
  40200000-411fffff : Kernel code
  41200000-41d82fff : Kernel rodata
  41e00000-4206d87f : Kernel data
  4292a000-42dfffff : Kernel bss
7d763018-7d79d057 : System RAM
[...]
```

Now that we have the memory dump in the files:

- `2025_08_14_07_28_0x0000000000001000.csv`
- `2025_08_14_07_28_0x0000000000100000.csv`
- `2025_08_14_07_28_0x0000000001630000.csv`
- `2025_08_14_07_29_0x000000007BD48000.csv`
- `2025_08_14_07_29_0x000000007FC00000.csv`
- `2025_08_14_07_29_0x000000007FD20000.csv`

it's time to analyze them.
The idea is simple: check the dumps for the memory being zeroed, or containing
[the pattern written by the EFI
application](https://github.com/zarhus/ram-dump-efi/blob/361b3637218c72f5b3b23e09455df63daafffb84/app.c#L5).
Otherwise, check them for information, which could be related to user space
memory. Most importantly, check if there are keys still residing, in particular
the LUKS secret key we printed earlier.

The following regions are indeed zeroed or contain [the
pattern](https://github.com/zarhus/ram-dump-efi/blob/361b3637218c72f5b3b23e09455df63daafffb84/app.c#L5):

```hexdump
$ hexdump -C 2025_08_14_07_28_0x0000000000001000.csv
00000000  be ef de ad be ef de ad  be ef de ad be ef de ad  |................|
*
0000f000

$ hexdump -C 2025_08_14_07_28_0x0000000000100000.csv
00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00700000
```

The next ones are more complex. One idea for a basic static analysis is to run
the `strings` program on them and analyze the printed text. While there are
some human-readable text snippets, there is no indication of user space memory
being present.

```console
$ strings 2025_08_14_07_29_0x000000007FC00000.csv
!aP}
!qP}
c!Q}
c1Q}
!a@}
!q@}
c!A}
c1A}
WPWU
 BOOT_IMAGE=/vmlinuz-6.12.38+deb13-amd64
BOOT_IMAGE=/vmlinuz-6.12.38+deb13-amd64
root=/dev/mapper/debian--vg-root
init_on_alloc=1
init_on_free=1
quiet
console=ttyS0
115200n8
console=tty0
BOOT_IMAGE=/vmlinuz-6.12.38+deb13-amd64 root=/dev/mapper/debian--vg-root ro init_on_alloc=1 init_on_free=1 quiet console=ttyS0,115200n8 console=tty0

$ strings 2025_08_14_07_29_0x000000007FD20000.csv
IOAPIC 0
HPET 0
```

The last two files are quite big. Therefore, it might be worthwhile to
decompose the analysis into multiple steps: let's extract the human-readable
text to separate files first, and then check those files for any user space
information disclosure.

There is a lot of relevant text, too much for the post. Some more interesting
portions have been provided below as part of the listing. In particular, we can
see mentions of:

- `audit` events about `apparmor_parser` (while running primarily in the kernel
  space, the disclosed information is about the user space utility for loading
  AppArmor profiles)

```console
$ strings 2025_08_14_07_28_0x0000000001630000.csv > 2025_08_14_07_28_0x0000000001630000.strings
$ strings 2025_08_14_07_29_0x000000007BD48000.csv > 2025_08_14_07_29_0x000000007BD48000.strings
$ cat 2025_08_14_07_28_0x0000000001630000.strings 2025_08_14_07_29_0x000000007BD48000.strings

heckns" pid=985 comm="apparmor_parser"r"pparmor_parser"ars/HibernateLocation-8cf2644b-4b0b-428f-9387-6d876050dc67).IBFDISK +PCRE2 +PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD +BPF_FRAMEWORK +BTF -XKBCOMMON -UTMP +SYSVINIT +LIBARCHIVE)
audit: type=1400 audit(1755156467.556:2): apparmor="STATUS" operation="profile_load" profile="unconfined" name="Discord" pid=967 comm="apparmor_parser"r"
audit: type=1400 audit(1755156467.556:3): apparmor="STATUS" operation="profile_load" profile="unconfined" name="1password" pid=966 comm="apparmor_parser"r"
audit: type=1400 audit(1755156467.560:4): apparmor="STATUS" operation="profile_load" profile="unconfined" name="QtWebEngineProcess" pid=972 comm="apparmor_parser"r"
audit: type=1400 audit(1755156467.560:5): apparmor="STATUS" operation="profile_load" profile="unconfined" name=4D6F6E676F444220436F6D70617373 pid=971 comm="apparmor_parser"r"
audit: type=1400 audit(1755156467.568:6): apparmor="STATUS" operation="profile_load" profile="unconfined" name="balena-etcher" pid=977 comm="apparmor_parser"r"
audit: type=1400 audit(1755156467.572:7): apparmor="STATUS" operation="profile_load" profile="unconfined" name="brave" pid=980 comm="apparmor_parser"r"
audit: type=1400 audit(1755156467.580:8): apparmor="STATUS" operation="profile_load" profile="unconfined" name="buildah" pid=982 comm="apparmor_parser"r"
audit: type=1400 audit(1755156467.584:9): apparmor="STATUS" operation="profile_load" profile="unconfined" name="busybox" pid=983 comm="apparmor_parser"r"
audit: type=1400 audit(1755156467.584:10): apparmor="STATUS" operation="profile_load" profile="unconfined" name="Xorg" pid=976 comm="apparmor_parser"r"
audit: type=1400 audit(1755156467.588:11): apparmor="STATUS" operation="profile_load" profile="unconfined" name="ch-checkns" pid=985 comm="apparmor_parser"r"
[...]
```

- X11 X Keyboard Extension rules or symbols

```console
partial alphanumeric_keys
xkb_symbols "tib_asciinum" {
    include "cn(tib)"
    name[Group1]= "Tibetan (with ASCII numerals)";
    key <AE01> { [ 1, 0x1000f21, 0x1000f04, 0x1000f76 ] }; # 1
    key <AE02> { [ 2, 0x1000f22, 0x1000f05, 0x1000f77 ] }; # 2
    key <AE03> { [ 3, 0x1000f23, 0x1000f7e, 0x1000f78 ] }; # 3
    key <AE04> { [ 4, 0x1000f24, 0x1000f83, 0x1000f79 ] }; # 4
    key <AE05> { [ 5, 0x1000f25, 0x1000f37, 0x1000f81 ] }; # 5
    key <AE06> { [ 6, 0x1000f26, 0x1000f35, 0x1000f09 ] }; # 6
    key <AE07> { [ 7, 0x1000f27, 0x1000f7f, 0x1000f0a ] }; # 7
    key <AE08> { [ 8, 0x1000f28, 0x1000f14, 0x1000f0f ] }; # 8
    key <AE09> { [ 9, 0x1000f29, 0x1000f11, 0x1000f10 ] }; # 9
    key <AE10> { [ 0, 0x1000f20, 0x1000f08, 0x1000f12 ] }; # 0
[...]
```

- udev, along with devices' UUIDs

```console
I:10114000
E:ID_MM_CANDIDATE=1
S:disk/by-id/dm-uuid-CRYPT-LUKS2-00b4b79c209a4dcfadf37e310778f583-sda3_crypt
S:disk/by-diskseq/5
S:mapper/sda3_crypt
S:disk/by-id/dm-name-sda3_crypt
S:disk/by-id/lvm-pv-uuid-78RIi0-DgUk-hNem-SDJL-5yGt-wrpF-r1ukGo
I:7431001
E:DM_UDEV_DISABLE_LIBRARY_FALLBACK_FLAG=1
E:DM_UDEV_PRIMARY_SOURCE_FLAG=1
E:DM_UDEV_RULES_VSN=3
E:DM_UDEV_DISABLE_OTHER_RULES_FLAG=
E:DM_ACTIVATION=1
E:DM_NAME=sda3_crypt
E:DM_UUID=CRYPT-LUKS2-00b4b79c209a4dcfadf37e310778f583-sda3_crypt
E:ID_FS_UUID=78RIi0-DgUk-hNem-SDJL-5yGt-wrpF-r1ukGo
E:ID_FS_UUID_ENC=78RIi0-DgUk-hNem-SDJL-5yGt-wrpF-r1ukGo
E:ID_FS_VERSION=LVM2 001
E:ID_FS_TYPE=LVM2_member
E:ID_FS_USAGE=raid
E:LVM_VG_NAME_COMPLETE=debian-vg
[...]
S:input/by-path/platform-i8042-serio-1-event-mouse
I:10254400
E:ID_INPUT=1
E:ID_INPUT_MOUSE=1
E:ID_BUS=i8042
E:ID_SERIAL=noserial
E:ID_PATH=platform-i8042-serio-1
E:ID_PATH_TAG=platform-i8042-serio-1
E:LIBINPUT_DEVICE_GROUP=11/2/13:isa0060/serio1
[...]
```

- systemd units

```console
#  SPDX-License-Identifier: LGPL-2.1-or-later
#  This file is part of systemd.
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
[Unit]
Description=Switch Root
AssertPathExists=/etc/initrd-release
DefaultDependencies=no
Wants=initrd-switch-root.service
Before=initrd-switch-root.service
AllowIsolate=yes
Wants=initrd-udevadm-cleanup-db.service initrd-root-fs.target initrd-fs.target systemd-journald.service initrd-cleanup.service
After=initrd-udevadm-cleanup-db.service initrd-root-fs.target initrd-fs.target emergency.service emergency.target initrd-cleanup.service
[...]
```

- PAM (Pluggable Authentication Modules)

```console
PAM %s: NULL pam handle passed
audit_log_acct_message() failed: %m
_pam_auditlog() should never get here
[...]
pam_start: failed to initialize environment
pam_start: failed to initialize handlers
Critical error - immediate abort
Insufficient credentials to access authentication data
Authentication service cannot retrieve authentication info
User not known to the underlying authentication module
[...]
/etc/pam.d/%s
/usr/lib/pam.d/%s
strdup failed
%s/%s
asprintf failed
pam_sm_setcred
pam_sm_authenticate
pam_sm_close_session
pam_sm_open_session
pam_sm_acct_mgmt
pam_sm_chauthtok
<*unknown module*>
[...]
_pammodutil_getgrgid_%ld_%d
_pammodutil_getgrnam_%s_%d
_pammodutil_getlogin
_pammodutil_getpwnam_%s_%d
_pammodutil_getpwuid_%ld_%d
_pammodutil_getspnam_%s_%d
[...]
```

Most importantly, searching the memory dump results in **no secret keys** being
found. In particular, the secret LUKS key we intentionally disclosed earlier
was **not** located in the dumped memory:

```bash
$ while read -r file ; do echo -e "Checking file: $file" ; \
aeskeyfind -v $file ; done < <(ls ./*.csv)

Checking file: ./2025_08_14_07_28_0x0000000000001000.csv
Keyfind progress: 100%
Checking file: ./2025_08_14_07_28_0x0000000000100000.csv
Keyfind progress: 100%
Checking file: ./2025_08_14_07_28_0x0000000001630000.csv
Keyfind progress: 100%
Checking file: ./2025_08_14_07_29_0x000000007BD48000.csv
Keyfind progress: 100%
Checking file: ./2025_08_14_07_29_0x000000007FC00000.csv
Keyfind progress: 100%
Checking file: ./2025_08_14_07_29_0x000000007FD20000.csv
Keyfind progress: 100%
```

## Summary

Protecting private information, especially in the context of confidential work,
is quite a challenging task. While [the `init_on_free` mechanism in Linux,
replacing `sdmem` and the second stage in the ram-wipe
solution](https://github.com/zarhus/ram-wipe/tree/88091fea2c58c7f1345c4a05e92fddfecbe1d807),
**successfully protects the user's LUKS secret key against warm boot attacks**,
there is still partial information disclosure, which could be detrimental to
the user's security.

The considerations on how to resolve this challenge include:

- Improving the `init_on_free` mechanism. A diagnosis, how it works, what
  information is not zeroed, and enhancing the zeroing mechanism with support
for that kind of information might be sufficient. [A thread on this matter has
been started on the Linux Kernel Mailing
List](https://lore.kernel.org/all/bfe72929-ba4c-4732-9f80-25cc7b95a0c8@3mdeb.com/),
where future research and conversations might take place.

- Building up on current `sdmem` technology or running the second stage:
  [continued maintenance and future
improvements](https://3mdeb.com/software-and-hardware-security/#softwaresecurity)
might ensure the robustness of the mechanisms.

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help. [Schedule
a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to sign up for our newsletter:

{{< subscribe_form "3160b3cf-f539-43cf-9be7-46d481358202" "Subscribe" >}}

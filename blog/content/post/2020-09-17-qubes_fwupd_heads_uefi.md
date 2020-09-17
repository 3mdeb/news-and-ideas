---
title: Reasonably secure way to update your system firmware
abstract: 'As you may know from the previous blog post, the qubes-fwupd is the
          wrapper that allows you to update the firmware of your devices in the
          Qubes OS. This time I will briefly describe the new features, whereby
          you will securely update your system firmware.'
cover: /covers/qubes&3mdeb_logo.png
author: norbert.kaminski
layout: post
published: true
date: 2020-09-17
archives: "2020"

tags:
  - qubes
  - fwupd
  - firmware
  - security
  - os-dev
  - heads
  - UEFI
categories:
  - Firmware
  - OS Dev
  - Security

---

As you may know from the previous
[blog post](https://blog.3mdeb.com/2020/2020-07-14-qubesos-fwupd-core/),
the qubes-fwupd is the wrapper that allows you to update the firmware of your
devices in the Qubes OS. This time I will briefly describe the new
features, whereby you will securely update your system firmware.

## UEFI update capsule

During the UEFI update process, fwupd daemon decompresses the cabinet archive
and extracts a firmware blob in the EFI capsule file format. The main difference
between the firmware update of the external USB devices and the UEFI is GUID
generation. The GUIDs are the labels used by fwupd daemon to recognize a device.
The UEFI GUID is generated from the information contained in the ESRT tables.
That causes trouble. Qubes OS is a fully virtualized operating system that works
under the Xen hypervisor. The admin VM - dom0 is a
[PVH domain](https://wiki.xen.org/wiki/Xen_Project_Software_Overview#PVH), that
has limited access to the memory tables. In default, dom0 kernel has blocked
read access of the ESRT, though the dom0 cannot create
[sysfs](https://en.wikipedia.org/wiki/Sysfs) entries. In that case, the fwupd
daemon assigns the default GUID value for the system firmware and sets the error
flag. To work around this problem we need to add the
[patch](https://github.com/3mdeb/qubes-fwupd/blob/master/misc/0017-esrt-Add-paravirtualization-support.patch)
to the dom0 kernel that gives access to the ESRT tables if the OS is
paravirtualized. Big kudos to Marek Marczykowski-Górecki, who helped us solve
this problem.

```
$ sudo qubes-fwupdmgr update
```

[![asciicast](https://asciinema.org/a/XH8SKNt4vEez6iIXEIhSxdZxC.svg)](https://asciinema.org/a/XH8SKNt4vEez6iIXEIhSxdZxC)

If you want to reproduce our results, have a look at the
[documentation](https://github.com/3mdeb/qubes-fwupd/blob/master/doc/uefi_capsule_update.md).

## Heads update

Referring to the Heads documentation, it is an open source custom firmware and
OS configuration for laptops and servers that aims to provide slightly better
physical security and protection for data on the system. The Qubes OS is the
preferred operating system that should be used under the Heads.
If you are installing Heads for the first time, you need to take apart your
laptop. Then you need to use the SPI programmer to flash BIOS chips. A firmware
update could be done in the same way, but there are easier ways to provide it.
The first option is to build the Heads update file from the source and deliver
the firmware with a USB drive. qubes-fwupd wrapper offers another way to update
the Heads firmware. The fwupd daemon reads BIOS information from the DMI. Then
the wrapper compares the current version of firmware with the latest one
that exists in the [LVFS](https://fwupd.org/). If the update is available,
the qubes-fwupd downloads and extracts the cabinet archive. The wrapper
verifies and copies the ROM file to `/boot` directory. During the update
process, Heads detects the update file and asks the user if he wants to flash
the BIOS.

```
sudo qubes-fwupdmgr update-heads --device=x230 --url=https://fwupd.org/downloads/firmware-3c81bfdc9db5c8a42c09d38091944bc1a05b27b0.xml.gz
```

[![asciicast](https://asciinema.org/a/RVXLOe2CkHtkYqjJumsy0Hw5d.svg)](https://asciinema.org/a/RVXLOe2CkHtkYqjJumsy0Hw5d)

If you want to reproduce our results, have a look at the
[documentation](https://github.com/3mdeb/qubes-fwupd/blob/master/doc/heads_udpate.md).

## Whonix support

Last but not least feature we added is the Whonix flag. It allows a user to use
`sys-whonix` as a updateVM. `sys-whonix` ensures advanced anonymity during the
downloads due to the TOR connection.

```
$ sudo qubes-fwupdmgr refresh --whonix
```

[![asciicast](https://asciinema.org/a/5zJhIZeATwx9OYVOELoK69ZMo.svg)](https://asciinema.org/a/5zJhIZeATwx9OYVOELoK69ZMo)

## Summary

If you have any questions, suggestions, or ideas, feel free to share them in
the comment section. If you are interested in similar content, I encourage you
to [sign up for our newsletter](http://eepurl.com/doF8GX).

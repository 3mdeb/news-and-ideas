---
title: 'Project status of the fwupd/LVFS support for Qubes OS'
abstract: 'During the QubesOS minisummit, I have presented the initial status
          of the fwupd/LVFS support for the Qubes OS. Now it is time to share
          some more information about the progress.'
cover: /covers/qubes&3mdeb_logo.png
author: norbert.kaminski
layout: post
published: true
date: 2020-07-14
archives: "2020"

tags:
  - lvfs
  - fwupd
  - Qubes OS
  - firmware
  - virtualization
  - QubesOS
categories:
  - Firmware
  - OS Dev
  - Security

---

During the QubesOS minisummit, I have presented the initial status of the
fwupd/LVFS support for the Qubes OS. Now it is time to share some more
information about the progress.

## Tool overview

We have used the suggestions, that we got during the Qubes OS minisummit and we
have rethought the whole architecture concept. We decided to create a wrapper,
which will adapt fwupd to the Qubes OS requirements. There is no need to show
all the connections in the one diagram. A more straightforward approach to
the subject will be focusing on the functionalities one by one.

### Development platform

We have used following setup during the development process:

1. OS version: Qubes OS R4.1

2. Dom0:
    - fwupd:
      - client version: 1.3.9
      - gusb: 0.3.4
      - efivar: 37
      - daemon version: 1.3.9
    - python: 3.7.6

3. sys-usb (usbVM):
    - fwupd:
      - client version: 1.2.12
      - gusb: 0.3.1
      - efivar: 37
      - daemon version: 1.2.12
    - python: 3.7.6

Required packages in the dom0 and the TemplateVM:

- cabextract

Differences in the fwupd version may cause problems in the future. I will write
more about solving this issue in the development roadmap.

### qubes-fwupdmgr refresh

The refresh command downloads, verifies, and updates metadata in the dom0 and
usbVM. Let's take a look at the architecture diagram.

![qubes_fwupdmgr-refresh](/img/qfwupd-refresh.png)

Everything starts in `qubes_fwupdmgr`. It is the main python script, where
a user is communicating his needs. Downloading the metadata is initialized by
the `_download_metadata` method. It calls subprocess, that runs
`fwupd-dom0-update` with a `--metadata` argument.

`fwupd-dom0-update` is the bash script, that initializes the processes in
UpdateVM. During the updating metadata, `fwupd-dom0-update` clears existing
cache files. Afterward, it creates cache directories in updateVM with the
corresponding ownerships. Then it calls the `fwupd-download-updates.sh`, that
verifies and provides the metadata update files to UpdateVM. In the next step,
`fwupd-dom0-update` runs a `fwupd_receive_updates`, that is responsible for
checking signature. If everything is as expected it copies files to
dom0.

In the end, the whole process comes back to `qubes_fwupdmgr`. The main script
checks the usbVM flag. If it is true, it copies files to usbVM and runs
`fwupd_usbvm_validate`. It validates metadata update files. If we have no error
code to that point, `qubes_fwupdmgr` uses the fwupd client to refresh
"manually" metadata.

The refresh process is presented in the following video.

[![asciicast](https://asciinema.org/a/8ZHBnq5COvqx1LdA1hnScKNfL.svg)](https://asciinema.org/a/8ZHBnq5COvqx1LdA1hnScKNfL)

### qubes-fwupdmgr get-devices

The `get-devices` command shows information about connected devices.

![qubes_fwupdmgr-devices](/img/qfwupd-get-devices.png)

`qubes_fwupdmgr` calls a `fwupdagent get-devices` in the usbVM and dom0.
The agent provides a JSON output that contains device information. The main
script parses the output and shows the information in the structured form.

### qubes-fwupdmgr get-updates

The `get-updates` command shows information about possible updates.

![qubes_fwupdmgr-get-updates](/img/qfwupd-get-updates.png)

The main difference between `get-updates` and `get-devices` appears in the older
version of the `fwupdagent`. 1.3.9 client version has dedicated command
`fwupdagent get-updates`, which generates information about possible updates in
the JSON form. 1.2.12 version has no such command. At first, we need to acquire
devices information from `fwupdagent get-devices`. Updates details are obtained
in the comparison of the current device version with versions in a release
list.

### qubes-fwupdmgr update

During the update process, a user gets a list of devices with information about
possible updates. The user chooses the device number, which will be updated to
the newest version. Then the tool downloads, validates, and installs firmware
update `.cab` archive.

![qubes_fwupdmgr-update](/img/qfwupd-update.png)

Downloading a firmware archive and the metadata updates vary in the verification
process. `fwupd-download-updates.sh` checks the checksum of the archive in the
updateVM. Then the `fwupd_receive_updates` copies the firmware to dom0 and it
verifies the checksum once again. The script unpacks the archive and checks the
signature of the firmware. Also during the system firmware update,
`qubes_fwupdmgr` verifies DMI details with the information contained in firmware
metadata. If the device is connected in usbVM, `qubes_fwupdmgr` copies
the firmware file to sys-usb. The main script initializes
`fwupd_usbvm_validate`, that verifies the firmware in usbVM before it will be
installed.

The update process of the device connected in dom0 is shown below.

[![asciicast](https://asciinema.org/a/cv2Iyv10EkF9lqrRtfkVLvGja.svg)](https://asciinema.org/a/cv2Iyv10EkF9lqrRtfkVLvGja)

Here is the update process of the device connected in sys-usb.

[![asciicast](https://asciinema.org/a/v7ZiSG3Xp9fauzwFkMNZgmHgt.svg)](https://asciinema.org/a/v7ZiSG3Xp9fauzwFkMNZgmHgt)

### qubes-fwupdmgr downgrade

The downgrade process is similar to updating. A user chooses the device number
and the firmware version, that will be installed on the downgraded device. Then
the tool downloads, validates, and installs firmware downgrade `.cab` archive.
The firmware installation proceeds with `--allow-older` flag.

![downgrade-usbvm](/img/qfwupd-downgrade.png)

The downgrade process is presented in the following video.

[![asciicast](https://asciinema.org/a/iUc1YK4NBslFCTm0zR6vqkJFw.svg)](https://asciinema.org/a/iUc1YK4NBslFCTm0zR6vqkJFw)

### qubes-fwupdmgr clean

The `clean` command removes cache directories from dom0 and updateVM.

[![asciicast](https://asciinema.org/a/0ZT3Gi2SzcPxUMWgNA56BPYzC.svg)](https://asciinema.org/a/0ZT3Gi2SzcPxUMWgNA56BPYzC)

## Tests

The `qubes_fwupdmgr.py` is covered by python tests. They could be run on any OS.
The unit tests and integration tests, that require Qubes OS or testing device
will be skipped if the requirements aren't met.

Following videos show the testing process on Qubes OS and Ubuntu.

[![asciicast](https://asciinema.org/a/TgHOkLnD2YICxB0U80PVcQGqX.svg)](https://asciinema.org/a/TgHOkLnD2YICxB0U80PVcQGqX)

[![asciicast](https://asciinema.org/a/pafnoJp50uQj0qKESCghS4FYW.svg)](https://asciinema.org/a/pafnoJp50uQj0qKESCghS4FYW)

## Development roadmap

The main issue we are facing now is the difference between fwupd versions in
dom0 and usbVM. The newer version of the tool has different binaries locations.
Also, fwupdagent has more features (`get-updates` command). Therefore the next
step of the development process will be replacing the static paths of
fwupd with the dynamic ones, that will depend on the fwupd version. In addition,
the `get-updates` command should properly obtain details of the update depending
on the fwupd version. Soon we will add support for
[heads updates](http://osresearch.net) and UEFI capsule updates. As well we want
to implement installation by the qubes-builder.

## Summary

If you have any questions, suggestions, or ideas, feel free to share them in
the comment section. If you want to hear more about the Qubes OS support for
fwupd I encourage you to [sign up to our newsletter](http://eepurl.com/gfoekD).

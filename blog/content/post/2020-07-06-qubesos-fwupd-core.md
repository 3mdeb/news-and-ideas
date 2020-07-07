---
title: 'Status fwupd/LVFS support for Qubes OS'
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: norbert.kaminski
layout: post
published: true
date: 2020-07-06
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

During the QubesOS minisummit I have presented the initial status of the
fwupd/LVFS support for the Qubes OS. Now it is the time to share some more
information about the progress.

## Tool overview

We have used the suggestions, that we got during the QubesOS minisummit and we
have rethought the whole architecture concept. We decided to create a wrapper,
which will adapt fwupd to Qubes requirements. There is no need to show all the
connections at the one diagram. More straightforward approach to the subject
will be focusing on the functionalities one by one.

### Development platform

We have used such setup during the development process:

1. OS version: Qubes OS R4.1

2. Dom0:
    * fwupd:
      - client version: 1.3.9
      - gusb: 0.3.4
      - efivar: 37
      - daemon version: 1.3.9
    * python: 3.7.6

3. sys-usb (usbVM):
    * fwupd:
      - client version: 1.2.12
      - gusb: 0.3.1
      - efivar: 37
      - daemon version: 1.2.12
    * python: 3.7.6

Required packages in dom0 and TemplateVM:
  * cabextract

Differences of fwupd version may cause problems in the future. I will write
more about solving this issue in the development roadmap.

### qubes-fwupdmgr refresh

The refresh command downloads, verify and updates metadata in the dom0 and
usbVM. Let's take a look at the architecture diagram.

![qubes-fwupdmgr-refresh](#)

Everything starts in qubes-fwupdmgr. It is main python script, where user is
communicating his needs. Downloading the metadata is initialized by
`_download_metadata` method. It calls subprocess, that runs `fwupd-dom0-update`
with `--metadata` argument.

`fwupd-dom0-update` is the bash script, that initializes the processes in
UpdateVM. During the updating metadata, `fwupd-dom0-update` clears existing
cache files. Afterwards it creates cache directories in updateVM with the
corresponding ownerships. Then it calls the `fwupd-download-updates.sh`, that
verifies and provides the metadata update files to UpdateVM. In the next step
`fwupd-dom0-update` runs a `fwupd-receive-updates`, that is responsible for
checks signature. If everything as expected it copies files to
dom0.

At the end whole process comes back to `qubes-fwupdmgr`. The main script checks
usbVM flag. If it is true, it copies files to usbVM and runs
`fwupd_usbvm_validate`. It validates metadata update files. If nothing to that
point generated an error code, qubes-fwupdmgr uses the fwupd client to refresh
"manually" metadata.

Refresh process is presented in following video.

![refresh](#)

### qubes-fwupdmgr get-devices

`get-devices` command shows information about connected devices.

![qubes-fwupdmgr-devices](#)

`qubes-fwupdmgr` calls `fwupdagent get-devices` in the usbVM and dom0. The agent
provides json output that contains devices information. The main script parses
output and shows the information in the structured form.

### qubes-fwupdmgr get-updates

`get-updates` command shows information about possible updates.

![qubes-fwupdmgr-get-updates](#)

The main difference between `get-updates` and `get-devices` appears in older
version of the `fwupdagent`. 1.3.9 client version has dedicated command
`fwupdagent get-updates`, which generates information about possible updates in
json form. 1.2.12 version has no such command. At first we need to acquire
devices information from `fwupdagent get-devices`. Updates details are obtained
in comparison of current device version with releases versions.

### qubes-fwupdmgr update

During the update process user gets list of devices with information about
possible updates. User chooses the device number, which will be updated to the
highest version. Then the tool downloads, validates, and install firmware update
`.cab` archive.

![qubes-fwupdmgr-update](#)

Downloading a firmware archive and the metadata updates vary in verification
process. `fwupd-download-updates.sh` checks the checksum of the archive in the
updateVM. Then the `fwupd-receive-updates` copies the firmware to dom0 and it
verifies the checksum once again. The script unpack archive and checks the
signature of the firmware. In addition during the system firmware update,
`qubes-fwupdmgr` verifies DMI details with the information in firmware metadata.
If device is connected in usbVM, `qubes-fwupdmgr` copies the firmware file to
sys-usb. The main script initializes `fwupd_usbvm_validate`, that verifies the
firmware in usbVM before it will be installed.

Update process of device connected in dom0 is shown below.

![update-dom0](#)

Here is the update process of device connected in sys-usb.

![update-usbvm](#)

### qubes-fwupdmgr downgrade

The downgrade process is similar to updating. User chooses the device number and
the firmware version, that will be installed on the downgraded device. Then the
tool downloads, validates, and install firmware downgrade `.cab` archive.
The firmware installation proceed with `--allow-older` flag.

Downgrade process is presented in following video.

![downgrade-usbvm](#)

### qubes-fwupdmgr clean

`clean` command removes cache directories from dom0 and updateVM.

![qubes-fwupdmgr-clean](#)

## Tests

The `qubes-fwupdmgr.py` is covered by python tests. They could be run on any OS.
The unit tests and integration tests, that requires Qubes OS or testing device
will skipped if the requirements aren't met.

Following videos show testing process:

![tests](#)

![test-skips](#)

## Development roadmap

The next step of the development process will be replacing the static paths of
fwupd with the dynamic ones, that will depends on the tool version. In the near
future we are planning to add heads update and capsule update support.
As well we want to implement installation by qubes-builder.

## Summary

If you have any questions, suggestions, or ideas, feel free to share them in
the comment section. If you want to here more about the Qubes OS support for
fwupd I encourage you to [sign up to our newsletter](http://eepurl.com/gfoekD)

---
title: How to safely update your firmware - fwupd and LVFS to the rescue!
abstract: Many people come out of the mistaken belief that changing the firmware
          is a very complicated task and fears that they can "brick" their
          platform or personal computer. Others do not know where to find
          matching updates. There is a simple answer - meet fwupd with LVFS.
cover: /covers/wrong-firmware.png
author: artur.raglis
layout: post
published: true
date: 2019-07-11
archives: "2019"

tags:
  - LVFS
  - fwupd
  - Librebox

categories:
  - Firmware
  - Security

---

Recently, the firmware security subject was one of the biggest topics of the IT
environment. As of 2018, almost every computer system is affected by the Spectre
security vulnerability. To fix mentioned security issue it is necessary to
update your platform's firmware provided by trusted vendor. Many people come out
of the mistaken belief that changing the firmware is a very complicated task and
fears that they can "brick" their platform or personal computer. Others do not
know where to find matching updates. Fortunately, there is a tool that enables
secure software updates in a very accessible way - meet fwupd, an open-source
daemon integrated with LVFS.

## LVFS - what does it mean?

The [Linux Vendor Firmware Service][lvfs] is a secure portal that brings
together firmware updates uploaded by renowned hardware vendors. The LVFS
provides reliable firmware alongside with the detailed metadata for clients such
as `GNOME Software` or `fwupdmgr`. Hosting or distribution of mentioned content
is cost-free, so if your hardware vendor is not on the list, feel free to ask
what they think about joining this project. Then there is a possibility to
request an account on the LVFS site, get legal permission to redistribute the
firmware and start uploading new updates.

Single upload contains binary file and at least one XML file with required
metainfo about target device and firmware, all packed as a cabinet archive,
which is consistent with the [Microsoft Update][req] requirements.

![cabinet archive example](/img/lvfs-cabinet-archive.png)

Archives specially prepared by authorized vendors are the key to the whole
update process. Metadata from the LVFS brings the details about available
updates to the user together with patch notes description. The XML file needs to
meet the structure and content standards which can be found in the LVFS examples.

Example of v4.9.0.1 coreboot release for Libretrend LT1000:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright 2019 3mdeb <contact@3mdeb.com> -->
<component type="firmware">
  <id>com.Libretrend.LT1000.firmware</id>
  <name>LT1000 coreboot</name>
  <summary>Firmware for the Libretrend LT1000 platform</summary>
  <description>
    <p>
      The platform can be updated using flashrom (internal programmer).
    </p>
  </description>
  <provides>
    <!-- this is a suitable HWID, found using `fwupdmgr hwids` -->
    <firmware type="flashed">52b68c34-6b31-5ecc-8a5c-de37e666ccd5</firmware>
  </provides>
  <url type="homepage">http://www.3mdeb.com/</url>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>Proprietary</project_license>
  <developer_name>Libretrend</developer_name>
  <releases>
    <release urgency="high" version="4.9.0.1" date="2019-01-26" install_duration="60">
      <checksum filename="com.Libretrend.LT1000.firmware.bin" target="content"/>
      <description>
        <p>This release features:</p>
        <ul>
          <li>Moved console initialization and sign-of-life to bootblock</li>
          <li>Fixed the CBFS size to 6MB</li>
          <li>Minor build fixes</li>
          <li>Rebased on official coreboot repository commit 2ef569a4</li>
        </ul>
      </description>
    </release>
  </releases>

  <custom>
    <value key="LVFS::VersionFormat">quad</value>
    <value key="LVFS::UpdateProtocol">org.flashrom</value>
  </custom>

  <categories>
    <category>X-Device</category>
  </categories>

  <!-- only newer versions of fwupd know how to write to this hardware -->
  <requires>
    <id compare="ge" version="1.1.2">org.freedesktop.fwupd</id>
  </requires>
</component>
```

We can announce, that from the beginning of 2019 we are approved ODM for
Libretrend company and our status can be tracked on LVFS [vendor list][vl].
Until now we have uploaded 4 custom firmware versions: `v4.8.0.2`, `v4.8.0.3`,
`v4.8.0.4` and the newest `v4.9.0.1` specially refined coreboot for Librebox
platforms (LT1000).

![3mdeb vendor list](/img/lvfs-3mdeb-vendor.png)

## Fwupd - end user's powerful tool

The fwupd project provides a system-activated daemon `fwupd` - program that runs
as a background process and in this case, with a D-Bus interface that can be
used by unprivileged clients. End users have an option to use command line tool
called `fwupdmgr` which enables firmware updates via Linux terminals or even on
the headless clients via SSH protocol.

The daemon creates a device with a unique ID and the provider assigns a number
of GUIDs to the device - these are used to match a binary file to a device with
the identification numbers from the metadata. Users can be uncertain if their
hardware is supported by OEMs and LVFS - to be sure there is a [list][dl]
showing all the updates that have been pushed to the stable metadata.

Last week we got the permissions to promote our binaries from private
"embargoed" state to `testing` and `stable` repositories, which are open to the
public! If You are interested in updating your Librebox computer, check uploaded
binaries with release notes of each [fixes and changes][release-notes].

![release-notes-example](/img/lvfs-release-notes-v4.9.0.1.png)

After making sure that platform is supported by fwupd/LVFS, users have a wide
choice of `fwupdmgr` options to run - all of them are listed with `fwupdmgr
--help`:

```bash
fwupdmgr [OPTION?]

clear-history
Erase all firmware update history

clear-offline
Clears any updates scheduled to be updated offline

clear-results DEVICE_ID
Clears the results from the last update

disable-remote REMOTE-ID
Disables a given remote

downgrade [DEVICE_ID]
Downgrades the firmware on a device

enable-remote REMOTE-ID
Enables a given remote

get-details FILE
Gets details about a firmware file

get-devices
Get all devices that support firmware updates

get-history
Show history of firmware updates

get-releases [DEVICE_ID]
Gets the releases for a device

get-remotes
Gets the configured remotes

get-results DEVICE_ID
Gets the results from the last update

get-topology
Get all devices according to the system topology

get-updates
Gets the list of updates for connected hardware

install FILE [ID]
Install a firmware file on this hardware

install-prepared
Install prepared updates now

modify-remote REMOTE-ID KEY VALUE
Modifies a given remote

refresh [FILE FILE_SIG REMOTE_ID]
Refresh metadata from remote server

report-history
Share firmware history with the developers

unlock DEVICE_ID
Unlocks the device for firmware access

update
Updates all firmware to latest versions available

verify [DEVICE_ID]
Gets the cryptographic hash of the dumped firmware

verify-update [DEVICE_ID]
Update the stored metadata with current ROM contents
```

Typical firmware updating process using Linux terminal looks like this:

1. Login to your system.
2. Refresh LVFS metadata from the remote server: `fwupdmgr refresh`
3. Check available updates: `fwupdmgr get-updates`
4. Update firmware to the newest version: `fwupdmgr update`
5. Reboot your system and check installation result: `fwupdmgr get-results`

See for Yourself the fwupd capabilities in the quick asciinema demo:

[![asciicast](https://asciinema.org/a/gQBz0ODK24QAgv2Jib3ZNtuNy.svg)](https://asciinema.org/a/gQBz0ODK24QAgv2Jib3ZNtuNy?speed=1.5)

As you can see, above process is "painless and easy", because required
preparations regarding binary files and security check are done by approved
providers.

## Fancy plugins

The fwupd project supports a great number of plugins:

| Plugin       | Supports                                                            |
|:------------:|:--------------------------------------------------------------------|
| ColorHug     | custom HID protocol                                                 |
| CSR          | Cambridge Silicon Radio protocol                                    |
| Dell         | various devices on Dell hardware                                    |
| DFU          | reads and writes data from USB devices supporting the DFU interface |
| Logitech     | Unifying protocol                                                   |
| SynapticsMST | updating MST hardware from Synaptics                                |
| Thunderbolt  | Thunderbolt controllers and devices                                 |
| UEFI         | adds devices found on the system and schedules an offline update    |
| WacomHID     | Wacom update protocol                                               |
| Flashrom     | **In the near future!**                                             |

In the help from fwupd developers, we (3mdeb) have integrated libflashrom API
creating a new way of running `flashrom` plugin relaying on always up-to-date
flashrom library, rather than simply calling subprocess with hardcoded full
command. More information about flashrom plugin capabilities and upstreaming
process can be tracked in this [PR][pr].

## The conclusion

Despite the complexity of the LVFS and fwupd infrastructure, updating firmware
with fwupd daemon is quite simple. There is now plenty of supported machines
ready to be more secure and reliable in the everyday tasks. I hope that after
this lecture, firmware updating process is not scary anymore and anyone willing
to update their platform will try this individually.

Want to know more about this open-source project or just simply trying to
contribute your priceless code which enables new, needful plugins? Check the
[LVFS website][lvfs].

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

[lvfs]: https://fwupd.org/
[req]: https://docs.microsoft.com/pl-pl/windows-hardware/drivers/bringup/authoring-an-update-driver-package
[vl]: https://fwupd.org/lvfs/vendorlist
[dl]: https://fwupd.org/lvfs/devicelist
[release-notes]: https://fwupd.org/lvfs/device/com.Libretrend.LT1000.firmware
[pr]: https://github.com/hughsie/fwupd/pull/897

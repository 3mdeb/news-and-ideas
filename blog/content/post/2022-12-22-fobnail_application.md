---
title: Fobnail Token - example use case
abstract: 'This phase focused on using Fobnail in a real-life use case, namely
          using it to access LUKS2 decryption key if and only if the PCR
          measurements are valid'
cover: /covers/usb_token.png
author: krystian.hebel
layout: post
published: true
date: 2022-12-22
archives: "2022"

tags:
  - fobnail
  - tpm
  - attestation
  - linux
categories:
  - Security

---

# About the Fobnail project

Fobnail is a project that aims to provide a reference architecture for building
offline integrity measurement verifiers on the USB device (Fobnail Token) and
attesters running in Dynamically Launched Measured Environments (DLME). It
allows the Fobnail owner to verify the trustworthiness of the running system
before performing any sensitive operation. This project was founded by [NlNet
Foundation](https://nlnet.nl/). More information about the project can be found
in the [Fobnail documentation](https://fobnail.3mdeb.com/). Also, make sure to
read other posts related to this project by visiting
[fobnail](https://blog.3mdeb.com/tags/fobnail/) tag.

# Scope of current phase

This phase focused on using Fobnail in a real-life use case, namely using it to
access LUKS2 decryption key if and only if the PCR measurements are valid. In
this post only high-level usage will be described, if you want to know what
happens under the hood or want to modify it to your needs see
[documentation](https://fobnail.3mdeb.com/examples/disk_encryption/).

# Changes

In this phase we completely switched the architecture around. Now the CoAP
server is located on Fobnail Token, instead of each of PC applications. This
way we could implement [API endpoints](https://fobnail.3mdeb.com/fobnail-api/),
including [Fobnail Token Services (FTS)](https://fobnail.3mdeb.com/fobnail-api/#fobnail-token-services),
which allows for more elaborate applications without having to re-flash Token
firmware each time.

As of now, only storage services are fully defined in FTS. Few other endpoints
for working with cryptographic keys were listed, but they are yet to be
implemented. There is also an endpoint `/api/version` which reports all versions
of API supported by Token - the version will be increased only when
backward-incompatible changes are done.

There are now two separate Attester applications - one with provisioning code,
and one without. Former should be used just for initial provisioning, and the
latter for normal use. We hope that by simplifying more frequently used form of
Attester (that is, the application used just for attestation, not provisioning)
we can reduce the surface of attack. It also helps with rare cases when users
inadvertently plugged in unprovisioned Token - in that case Token would also
lit _all-good_ green LED in the end, making it indistinguishable from normal
attestation. For the same reason we also gave up on the idea of unprovisioning
the token by holding the button - neighboring USB device could potentially keep
the button pressed

Speaking of LEDs, we now have to steer them in a non-blocking manner. Simple
delay loops were good enough when the Token was CoAP client, but now it has to
be able to respond to the clients without making them wait too long, especially
for longer signals like attestation result. We took advantage of that forced
change to [expand and standardize](https://fobnail.3mdeb.com/blink-codes/) blink
codes produced by Fobnail Token.

## Building and running

TBD: SBOM

Building hasn't change much since [last time](https://blog.3mdeb.com/2022/2022-05-25-fobnail_provisioning/#building-and-running).
There are some changes done to produce `fobnail-attester-with-provisioning`
along with non-provisioning version, but instructions for building didn't
change.

Despite changes in the architecture, applications are started mostly the same as
before. Main difference is that the applications don't have to (and shouldn't)
be already running when Fobnail Token is being plugged in. Attester changed a
bit more, it now can take arguments which use Fobnail Token Services.
Description of those can be obtained by starting Attester with `--help`:

```
Usage:
    fobnail-attester [CMD]...

Commands:
    --read-file token_fname:local_fname
    -r token_fname:local_fname
        Read file token_fname from Fobnail Token and save it in local_fname.

    --write-file local_fname:token_fname
    -w local_fname:token_fname
        Write file local_fname to token_fname on Fobnail Token.

    --delete-file token_fname
    -d token_fname
        Remove file token_fname from Fobnail Token.

All commands are executed only if the attestation was successful.

Both --read-file and --write-file can take '-' as local_fname to use stdout
and stdin, respectively. If '-' appears in multiple write commands, the same
data is written to all files. If '-' appears in multiple read commands, output
consists of concatenated content of all files, in the order in which they are
read. Use './-' to access regular file named '-'.

Multiple commands may be specified at once, in that case they are executed in
order in which they appear on the command line. Attestation is performed only
once. If any of the commands fails, further commands are not executed.
```

## Preparing encrypted disk image for use with Fobnail

Some preparations have to be done during provisioning by administrator to make
user's life as easy as possible. Following steps were performed on Ubuntu
**TBD**, they may be slightly different for other versions and distributions.

#### Provisioning

Build by [following Fobnail documentation](https://fobnail.3mdeb.com/building/)
and perform Token provisioning. To do so, plug in the Token and make sure it has
properly assigned IP address. It can be added through `*.link` file and
permanent `NetworkManager` connection (see how it's done for Attester below),
but since this is one-time operation it can also be assigned temporarily with:

```
sudo nmcli con add save no con-name Fobnail ifname enp0s26u1u1 type ethernet \
     ip4 169.254.0.8/16 ipv6.method disabled
```

Change `enp0s26u1u1` to the interface name of the Token, it may depend on your
OS, its configuration, presence of other USB Ethernet adapters or even USB port
to which the Token is plugged in. To obtain it, run `sudo dmesg | grep cdc_eem`.
In my case this was the result:

```
[54.928687] cdc_eem 1-1.1:1.0 usb0: register 'cdc_eem' at usb-0000:00:1a.0-1.1, CDC EEM Device, f6:82:61:5e:71:2a
[55.052471] cdc_eem 1-1.1:1.0 enp0s26u1u1: renamed from usb0
[55.153313] cdc_eem 1-1.1:1.0 enp0s26u1u1: unregister 'cdc_eem' usb-0000:00:1a.0-1.1, CDC EEM Device
```

Note that sometimes interface isn't renamed and two last lines aren't printed,
in that case use `usb0` or whatever the original name was. With that out of the
way, start Platform Owner application, with the same arguments as in previous
phases of Fobnail project:

```bash
fobnail-platform-owner path/to/chain.pem path/to/issuer_ca_priv.key
```

Refer to [documentation](https://fobnail.3mdeb.com/keys_and_certificates/#platform-owner-certificate-chain)
for description and example OpenSSL configuration for Platform Owner certificate
chain, if you haven't prepared whole chain during the build process.

Now switch to target platform, but don't connect Fobnail Token yet. To make
further steps easier, start by making the interface name persistent and assign
an IP address to it. Create file `/etc/systemd/network/10-fobnail.link` with
following content:

```
[Match]
# Match against Fobnail VID and PID, this requires SystemD v243 or newer
Property=ID_MODEL_ID=4321 ID_VENDOR_ID=1234

[Link]
Name=fobnail
```

This file can also be found in [fobnail-attester repository](https://github.com/fobnail/fobnail-attester/tree/main/scripts/10-fobnail.link).
Now we can add persistent network configuration for new interface name:

```bash
sudo nmcli con add con-name Fobnail ifname fobnail type ethernet \
     ip4 169.254.0.8/16 ipv6.method disabled
```

Connect the Token and check if it gets its IP correctly, if it does, we can
finally provision the platform. Fobnail Token Services are available even for
Attester with provisioning functions, so encryption key can be written in the
same invocation as platform provisioning. The process of creating disk image,
encryption key, platform provisioning and writing the encryption key to the
Token can be automated with a script. Before it can be used, `cryptsetup` must
be installed:

```bash
sudo apt install cryptsetup-bin
```

Change paths and names in the following script to your expectations, save it and
run with `sudo`:

```bash
#!/bin/bash

# Some configuration variables common to provisioning and attestation, they must
# be the same in 'fobnail.cfg' created later
DISK_IMG="/usr/share/fobnail/disk.img"
MNT_DIR="/mnt/fobnail"
MAPPER_DEV=c1
FOBNAIL_KEY_FNAME=luks_key

# Configuration variables used only by this script
ATTESTER_PROV=/usr/bin/fobnail-attester-with-provisioning
DISK_SIZE_MB=128
TMP_KEY=/tmp/keyfile.bin

# Get user name, regardless of whether script is started with sudo or not
DISK_USER=${SUDO_USER:-$USER}

# Create disk image and mount is as loop device
mkdir -p `dirname $DISK_IMG`
dd if=/dev/zero of=$DISK_IMG bs=1M count=$DISK_SIZE_MB
LOOP_DEV=`losetup -f --show $DISK_IMG`

# Create encryption key and LUKS partition
dd bs=512 count=4 if=/dev/urandom of=$TMP_KEY
cryptsetup luksFormat --type luks2 $LOOP_DEV $TMP_KEY

# Create filesystem on the partition
cryptsetup luksOpen -d $TMP_KEY $LOOP_DEV $MAPPER_DEV
mke2fs -j /dev/mapper/$MAPPER_DEV

# Mount partition and change the owner of root directory
mkdir -p "$MNT_DIR"
mount /dev/mapper/${MAPPER_DEV} "$MNT_DIR"
chown -R $DISK_USER:$DISK_USER "$MNT_DIR"
# Optionally fill the partition with secret stuff
# cp top_secret_file.odt "${MNT_DIR}"
umount "$MNT_DIR"

# Close LUKS partition and underlying loop device
cryptsetup close $MAPPER_DEV
losetup -d $LOOP_DEV

# Write key to Fobnail Token and securely erase it from host
$ATTESTER_PROV --write-file $TMP_KEY:$FOBNAIL_KEY_FNAME && \
    dd if=/dev/urandom of=$TMP_KEY bs=$(stat -c %s $TMP_KEY) count=1 && \
    rm $TMP_KEY
```

Platform is now provisioned and encryption key can be read by calling
`fobnail-attester --read-file luks_key:keyfile.bin`. For better user experience
we can automate this as well with set of relatively simple scripts and
configuration files from [fobnail-attester repository](https://github.com/fobnail/fobnail-attester/tree/main/scripts):

- `fobnail-mount.service` is to be installed in `/lib/systemd/system` or another
directory searched by `systemd`. It contains paths to files listed below, you
can change it in the service file or use defaults.
- `fobnail.cfg` by default is expected to be located in `/etc` directory. It
holds paths and filenames used by Attester, change those if required. Note that
it should use the same values as were used during provisioning, unless any of
files pointet to by configuration were manually moved.
- `mount.sh` and `umount.sh` should be installed in `/usr/share/fobnail` by
default, create this directory if it doesn't exist.
- `99-fobnail.rules` is the file that instructs `udev` (which is now part of
`systemd`) to automatically start the service when Token is plugged in to the
platform. Copy this file to `/etc/udev/rules.d` directory.
- `10-fobnail.link` was already created before platform provisioning. This file
doesn't have configurable location, it always have to live in
`/etc/systemd/network` directory. Note that key used in `[Match]` section
requires `systemd` in version 243 or newer. If you want to use it with older
`systemd` you have to use another key, otherwise this file will be matched by
_every_ link, even `loopback` interface. This would most likely break your
Internet connection. Refer to your version of `man systemd.link` for alternative
keys for `[Match]` if you want to use it with older `systemd`.

To install all mentioned files in their default location with proper permissions
go to `fobnail-attester/scripts` directory and execute in terminal:

```bash
sudo install -m 644 fobnail-mount.service -t /lib/systemd/system/
sudo install -m 644 fobnail.cfg /etc/
sudo install -D *.sh -t /usr/share/fobnail/
sudo install -m 644 99-fobnail.rules -t /etc/udev/rules.d/
# This one should already be done, leaving it here for completeness:
sudo install -m 644 10-fobnail.link -t /etc/systemd/network/
```

Now all that's left is to restart services so changed configuration is actually
used. This can be done by rebooting whole system or restarting them manually
with:

```bash
sudo systemctl reload-or-restart systemd-udevd
```

#### Use

Just plug in the Token, wait few seconds (up to few dozen) for green light and
voila! You should now have access to all your secrets. When the Token is pulled
out, the secure disk should be automatically unmounted.

## Demo

**TBD**

## Known issues

Attester assumes full control over TPM while it's running. This means that no
other application can use TPM together with Attester, including another instance
of Attester. `timeout` is used to work around potential issue with Attester, for
example when it can't access the Token and gets stuck.

## Summary

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

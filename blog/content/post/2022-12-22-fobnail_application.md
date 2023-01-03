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
properly assigned IP address. It can be added as `systemd` configuration (see
how it's done for Attester below), but since this is one-time operation it can
also be assigned manually with `sudo ip a add 169.254.0.8/16 dev usb0`. With
that out of the way, start Platform Owner application, with the same arguments
as before:

```bash
fobnail-platform-owner path/to/cert_chain.pem path/to/po_priv_key.pem
```

Refer to [documentation](https://fobnail.3mdeb.com/keys_and_certificates/#platform-owner-certificate-chain)
for description and example OpenSSL configuration for Platform Owner certificate
chain, if you haven't prepared whole chain during the build process.

Now switch to target platform. To make further steps easier, start by adding IP
address to `systemd-networkd` configuration. Create two files:

- `/etc/systemd/network/10-fobnail.link` (see [known issues](#known-issues)):

  ```
  [Match]
  OriginalName=usb0

  [Link]
  Name=fobnail
  ```

- `/etc/systemd/network/10-fobnail.network`:

  ```
  [Match]
  Name=fobnail

  [Network]
  Address=169.254.0.8/16
  DHCPServer=false
  ```

Restart service with `sudo systemctl reload-or-restart --now systemd-networkd`.
Connect the Token and check if it gets its IP correctly, see [known issues](#known-issues)
if not.

With Token plugged in and with correct IP we can provision the platform. Fobnail
Token Services are available even for Attester with provisioning functions, so
encryption key can be written in the same invocation as platform provisioning.
Following script automates the process of creating disk image, encryption key,
platform provisioning and writing the encryption key to the Token. Change paths
and names to your expectations, save it and run with `sudo`:

```bash
#!/bin/bash

# Some configuration variables - change as needed
DISK_IMG=/home/user/.secure_disk.img
DISK_SIZE_MB=128
MNT_DIR=/home/user/secure_storage
ATTESTER=/usr/bin/fobnail-attester-with-provisioning
MAPPER_DEV=c1
TMP_KEY=/tmp/keyfile.bin
FOBNAIL_KEY_FNAME=luks_key

# Get user name, regardless of whether script is started with sudo or not
DISK_USER=${SUDO_USER:-$USER}

# Create disk image and mount is as loop device
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
$ATTESTER --write-file $TMP_KEY:$FOBNAIL_KEY_FNAME && \
    dd if=/dev/urandom of=$TMP_KEY bs=$(stat -c %s $TMP_KEY) count=1 && \
    rm $TMP_KEY
```

Platform is now provisioned and encryption key can be read by calling
`fobnail-attester --read-file luks_key:keyfile.bin`. For better user experience
we can automate this as well with relatively simple scripts:

- `mount.sh`:

  ```bash
  #!/bin/bash

  # Always use full paths
  DISK_IMG=/home/user/.secure_disk.img
  MNT_DIR=/home/user/secure_storage
  ATTESTER=/usr/bin/fobnail-attester
  LOOP_DEV_FILE=/var/run/fobnail.loopdev
  MAPPER_DEV=c1
  FOBNAIL_KEY_FNAME=luks_key

  # Create loop device and save its path for umount.sh
  LOOP_DEV=`losetup -f --show $DISK_IMG`
  echo -n "$LOOP_DEV" > "$LOOP_DEV_FILE"

  # Give time for networkd service to set up Fobnail Token IP
  sleep 5

  # Get the key and open LUKS partition
  timeout 30 $ATTESTER --read-file ${FOBNAIL_KEY_FNAME}:- | \
      cryptsetup luksOpen -d - $LOOP_DEV $MAPPER_DEV

  # Mount filesystem
  mount /dev/mapper/${MAPPER_DEV} "$MNT_DIR"
  ```

  `sleep` and `timeout` are useful only when this script is started by `udev`
  automatically after Token is plugged in, which we'll do momentarily.

- `umount.sh`:

  ```bash
  #!/bin/bash

  # These must be the same as in mount.sh
  DISK_IMG=/home/user/.secure_disk.img
  MNT_DIR=/home/user/secure_storage
  LOOP_DEV_FILE=/var/run/fobnail.loopdev
  MAPPER_DEV=c1

  # Do a lazy unmount and close LUKS partition
  umount -l "$MNT_DIR"
  cryptsetup close --deferred $MAPPER_DEV

  # Detach loop device and remove file with its path
  losetup -d `cat $LOOP_DEV_FILE`
  rm $LOOP_DEV_FILE
  ```

  Lazy unmounting means that filesystem is unmounted immediately if it's unused,
  or as soon as applications using the filesystem are closed, but no new
  processes can open it anymore. `--deferred` works similarly for `cryptsetup`
  and loop devices are always lazily detached since Linux v3.7.

These two scripts already help a lot, but we can go a step further and make it
fully automated by using `udev` rules. There are some things to remember when
running commands from `udev` rule:

- programs and scripts started by rules are run as different user, e.g. they
  don't have the same `PATH` variable
  - always use full path for custom programs
- commands are executed synchronously
  - further rules wait until earlier ones finish
  - earlier rules might never finish if they are blocked by something depending
    on later rules
  - commands might start other commands in the background e.g. by using `at`
- commands written in rules are executed by `sh`
  - some built-ins behave slightly differently
  - usually easier to just call a script with different shell (e.g. `bash`)
    specified in shebang
  - `at` also executes command in `sh`

For these reasons we will use very simple wrapper scripts (example for mount.sh,
umount.sh will also need similar wrapper):

```bash
#!/bin/bash

echo /full/path/to/mount.sh | at -M now
```

Of course, use your own path to the script. Save it as `mount_wrap.sh`. Now all
that's left to do is starting this scripts on connection and disconnection of
the Token. We can do so by creating `/etc/udev/rules.d/99-fobnail.rules` with
following content:

```
ACTION=="add", SUBSYSTEM=="net", ENV{ID_VENDOR_ID}=="1234", ENV{ID_MODEL_ID}=="4321" RUN+="/full/path/to/mount_wrap.sh"
ACTION=="remove", SUBSYSTEM=="net", ENV{ID_VENDOR_ID}=="1234", ENV{ID_MODEL_ID}=="4321" RUN+="/full/path/to/umount_wrap.sh"
```

Again, use proper paths to scripts. Each rule must be written in one line, they
can't be broken with backslash. `1234` and `4321` (hexadecimal) are vendor and
device IDs [used by Fobnail](https://github.com/fobnail/fobnail/blob/main/pal/pal_nrf/src/usb/mod.rs#L15),
respectively. These may change if we decide to register as USB vendor.

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

Due to complicated ordering done by `systemd`, Fobnail Token sometimes doesn't
have its IP assigned properly, `NetworkManager` complicates things even more.
This can be checked with `networkctl list fobnail` when Token is plugged in -
`routable` is expected state, but sometimes it is `carrier` instead. The latter
case won't work, but usually it fixes itself by unplugging and plugging the
token again.

`systemd` configuration presented above blindly renames `usb0` network interface
to `fobnail`. This won't work if you're using USB network card. Even though
[manual for .link files](https://www.freedesktop.org/software/systemd/man/systemd.link.html)
linked on [official systemd documentation page](https://systemd.io/PREDICTABLE_INTERFACE_NAMES/)
says that we can use `Property=` in `Match` section to check for particular
vendor and device ID, this is not true. Trying to do so results in a warning
being printed to log and **every interface** being matched by this rule,
including the one used to connect to the Internet and even loopback device `lo`.

## Summary

If you think we can help in improving the security of your firmware or you are
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

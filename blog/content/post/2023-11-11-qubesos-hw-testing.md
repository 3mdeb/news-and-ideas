---
title: Hardware setup for testing Qubes OS via openQA
abstract: 'How Qubes OS installation and usage can be automatically tested on
           hardware with open-source software and firmware.'
cover: /covers/qubes-openqa.png
author: sergii.dmytruk
layout: post
published: true
date: 2023-11-11
archives: "2023"

tags:
  - qubesos
  - testing
  - openqa
categories:
  - Miscellaneous
  - OS Dev

---

This post is about testing [Qubes OS][qubesos] on hardware via [openQA][openqa].
It's not the first such setup because it was done before by
[Qubes OS upstream][qubesos-qa], but this one is sufficiently different to
present different challenges.  The original setup has been covered in
[this post][generalhw-setup] ([its video version][generalhw-talk])
and touched upon in another [conference talk][xen-talk].  Additionally, you
can read about one more hardware setup employed by openSUSE
[here][osautoinst-setup].

We'll start by looking at how openQA and PiKVM are structured as that defines
testing setup and should help understand it.

[qubesos]: https://www.qubes-os.org/
[qubesos-qa]: https://openqa.qubes-os.org/
[openqa]: http://open.qa/
[generalhw-setup]: https://www.qubes-os.org/news/2022/05/05/automated-os-testing-on-physical-laptops/#power-control
[generalhw-talk]: https://www.youtube.com/watch?v=IvOG_lm3JII
[xen-talk]: https://www.youtube.com/watch?v=oyLfg7CSaxQ
[osautoinst-setup]: https://github.com/os-autoinst/os-autoinst-distri-opensuse/blob/7491ebdaa058ea3ff620ac6966af62c056920615/data/generalhw_scripts/raspberry_pi_hardware_testing_setup.md

## openQA overview

openQA test run is essentially a sequence of waiting until screen of a system
under test (SUT) matches some predefined screenshot ("needle") followed by
sending that system mouse or keyboard events to make it advance to the next
expected screenshot.  In addition to the screen, matching can also be done on
console's output.

Matching of the screen is mostly done only on parts of needles so that the rest
of the screen can change without affecting the test.  You can also define areas
of needles as clickable or request text recognition.

Tests are written in Perl and are largely a sequence of
[API calls][os-autoinst-api] provided by [os-autoinst][os-autoinst] which is
responsible for processing them.

`os-autoinst` is executed by an openQA worker.  How exactly screen is collected
or input is sent is determined by backend configured for the worker.
`generalhw` backend was added for the purposes of testing Qubes OS and other
systems without the use of some [BMC][bmc-wiki].

There can be multiple workers, local or remote, all of which are managed by
openQA server which also serves a Web interface along with a REST API.

[os-autoinst]: https://github.com/os-autoinst/os-autoinst
[os-autoinst-api]: http://open.qa/api/testapi/
[bmc-wiki]: https://en.wikipedia.org/wiki/Intelligent_Platform_Management_Interface#Baseboard_management_controller

## PiKVM overview

[PiKVM][pikvm] is based on [Arch Linux][arch-linux], so you can install various
software as needed.  However, do remember that Arch Linux doesn't support
partial updates and if installation results in updating anything already
installed you better update every other installed package or things can stop
working.

PiKVM's core is its `kvmd` service combined with auxiliary ones like `kvmd-otg`,
`kvmd-janus`, `kvmd-nginx`, `kvmd-vnc` and `ustreamer` (not necessarily an
exhaustive list).

`kvmd` launches [ustreamer][ustreamer] to capture video stream, encode it (MJPEG
or H.264) and publish it to shared memory.  `ustreamer` includes a plugin for
[Janus][janus] which turns `ustreamer`'s data into a stream source to Janus for
displaying it in Web interface over WebRTC.

PiKVM also supports VNC (disabled by default) that uses the same data published
by `ustreamer`.

[pikvm]: https://pikvm.org/
[arch-linux]: https://archlinux.org/
[ustreamer]: https://github.com/pikvm/ustreamer/
[janus]: https://janus.conf.meetecho.com/

## Overview of the setup

<!--
                                           +============+
           +---------+    +-----------+  +-:USB Keyboard:-+ +---------+
           |cBLU     |    |cYEL       |  | :            : | |cBLU     |
           |         |    |           |<-+-:USB Tablet  :-+-+         |
        AC |         | AC |  System   |  | :            : | |         |
Mains *----* Sonoff  *----*  Under    |  +-:USB Storage :-+ |  PiKVM  |
power      |         |    |  Test     |    +============+   |         |
           |         |    |           +-------------------- >|         |
           |         |    |           |     HDMI output     |         |
           +---------+    +-+---------+                     ++--------+
                 ^          |    ^  ^                        |       ^
          Power  |   Serial |    |  |                        |       |
          control|   output |    |  |Flashing                |       |
                 |          v    |  |                        |       |
             +---+------------+  |  |                        |       |
             |cBLU            |  |  |                        |       |
             |      RTE       +-----+                        |       |
             |                |  |                           |       |
             +----------------+  |SSH          Video stream  |       |
                     ^           |shell     +----------------+       |
                     |Power      |to        |                        |
                     |control    |installer |                        |
                     |&          |or        |    USB devices control,|
                     |flashing   |Qubes OS  v    keyboard and mouse  |
       +---------+---+-----------+--------------+input, power state  |
       |cGRE     |cGRE                          |check               |
       | openQA  |openQA Worker (os–autoinst)   +--------------------+
       |         |                              |
       +---------+------------------------------+

ditaa image.fig openqa-qubesos-setup.png -E
(Don't forget to fix broken arrow above that terminates the comment otherwise.)

-->

![openQA Qubes OS hardware testing setup](/img/openqa-qubesos-setup.png)

Legend:

- yellow - hardware on which Qubes OS is being installed and run (SUT)
- green - openQA server and worker installed on the same openSUSE system
- blue - extra hardware used to control the SUT

### System Under Test (SUT)

In this case it's an [MSI PRO Z690-A DDR5][z690-a] board running open-source
[Dasharo firmware][dasharo].

[z690-a]: https://docs.dasharo.com/variants/msi_z690/releases/
[dasharo]: https://www.dasharo.com/

### Sonoff

[Sonoff power switch][sonoff] is used to cut off power of the board, making it
possible to flash BIOS via an external programmer (RTE in this case, see below).

[sonoff]: https://sonoff.tech/

### RTE

[RTE][rte] is connected to SUT's flash chip, its power control pins and serial
output pins.  There is only serial output without input as that's what the board
exposes.

[rte]: https://shop.3mdeb.com/shop/product/rte/

### openQA server and worker

Both parts of openQA are installed on the same [openSUSE Tumbleweed][tumbleweed]
system in this setup.  You can read about example installation
[here][openqa-vm-setup].

[tumbleweed]: https://en.opensuse.org/Portal:Tumbleweed
[openqa-vm-setup]: https://github.com/QubesOS/openqa-tests-qubesos/blob/3887376a3ac83a7c7b9fb0332d8db0532a8403a1/openqa_vm_setup.md

### PiKVM

PiKVM was initially thought to provide VNC for openQA worker but that didn't
work out (more on that below).

In the absence of serial input PiKVM provides a way to use these MSI boards
(Z690-A and Z790-P) remotely for humans and testing automatically by means
other than openQA ([Robot framework][robot] in case of [OSFV][osfv]).
Mentioning this here because it affects the setup by requiring to effectively
switch some of PiKVM services off while openQA is doing its work.  Otherwise,
it would be possible to install openSUSE on Raspberry Pi and put the worker
there.

[robot]: https://robotframework.org/
[osfv]: https://github.com/Dasharo/open-source-firmware-validation

## Typical test execution flow

Now that components of the setup are known, let's go through an example of
openQA log with comments about what's going on and where.  Every test run uses
all components and calls every script there is, so this should be a nice way to
talk about operation of all of them.  Both large and small parts of the log were
cut out because it contains thousands of lines of output most of which are of no
real interest unless test failure occurs.

For better readability, IP addresses were changed to indicate what device they
belong to but they still look like addresses, for example: `192.168.kvm.ip`.

```log
{{ skipped uninteresting prolog }}}
[2023-10-29T20:29:24.884333+01:00] [debug] [pid:26068] Launching external video encoder: ffmpeg -hide_banner -nostats -r 24 -f image2pipe -vcodec ppm -i - -pix_fmt yuv420p -c:v libsvtav1 -crf 50 -preset 7 'video.webm'
```

Soon after launch OpenQA starts encoding video stream collected while the
test is being run.  This is worth a note to avoid confusion with the video
stream `generalhw` backend receives from the SUT.

```log
[2023-10-29T20:29:24.913187+01:00] [debug] [pid:26068] Calling GENERAL_HW_POWEROFF_CMD
DUT is on
DUT is on
Setting EDID
Setting DV timings
BT timings set
DUT is off
Switched DUT's state from 'on'.
```

The SUT (DUT is "Device Under Test" in the log) is about to be flashed with a
drive image and it should be turned off for that.  In this particular case it
is on and a helper script (more on that later) requests RTE to turn it off and
then waits until SUT reaches the target state.  This does not switch Sonoff,
SUT just gets to S5 [ACPI power state][acpi].

[acpi]: https://en.wikipedia.org/wiki/ACPI#Power_states

```log
[2023-10-29T20:29:38.181467+01:00] [debug] [pid:26068] Calling GENERAL_HW_FLASH_CMD
Enabling OTG (input, storage)
Flashing DUT's ROM...
Flashed DUT's ROM.
Input socket seems working.
```

The verb "flash" should be interpreted loosely here.  It can be any kind of
data writing operation meant to prepare SUT for the test.  In this setup it
means:

1. Setup of USB OTG to provide input and storage via `gadget-control` script
  (done on PiKVM)
2. Flashing of BIOS (done on RTE)
3. Testing that `gadget-control` script is listening for commands

Input is set up here only because `gadget-control` manages both input and
storage.

Testing of input is done just to catch some possible issue.  Flashing BIOS
takes at least a minute, so if `gadget-control` is still not up, something must
have gone wrong.

The BIOS is flashed in order to make sure it's a working one and with settings
necessary to automatically start Qubes OS installer (SUT is mainly used
for testing of Dasharo firmware, so it's not necessarily in a working state
before the test has started).  The image specific to the SUT is stored on RTE
connected to it, it was obtained by making necessary adjustments and reading the
flash (its "bios" region to be specific; done this way because flashing script
writes just this region by default and the rest can be assumed to be OK).

```log
[2023-10-29T20:30:46.620008+01:00] [debug] [pid:26068] Calling GENERAL_HW_POWEROFF_CMD
Setting EDID
Setting DV timings
BT timings set
DUT is off
Skipping rte_ctrl poff
```

Second power off in a row needs an explanation.  For some reason starting "VM"
(which is real hardware in this case) in `generalhw` backend involves a
restart.  This is why it's important to be able to tell SUT's poweron state or
have power on/off commands that don't act as a toggle of the state (which is
how a power button usually works).

```log
[2023-10-29T20:30:54.129104+01:00] [debug] [pid:26068] Calling GENERAL_HW_POWERON_CMD
DUT is off
Setting EDID
Setting DV timings
BT timings set
DUT is on
Switched DUT's state from 'off'.
```

Powering the SUT has a number of prerequisites:

 1. Video input of the PiKVM must be initialized with an appropriate EDID to
    force use of 1024x768 resolution expected by needles in
    [test suite of Qubes OS][qubesos-test-suite]
 2. DV (digital video) timings must be set in order for video capturing to work;
    not doing this will result in `ffmpeg` reporting
    `ioctl(VIDIOC_G_PARM): Inappropriate ioctl for device` and then waiting for
    video data indefinitely
 3. `kvmd-otg` and `kvmd-janus` services need to be stopped
 4. `gadget-control` needs to be started

Steps 3 and 4 are done by the `flash` script.

Steps 1 and 2 are always done on power on/off because querying the state of the
SUT is done by attempting to receive a video stream which won't work if you
won't set timings and you want to set EDID to the right value before setting
timings.  Such a weird way of testing power state of a device was used in the
absence of anything better in a given hardware setup.
If the system is up, it's video output is up and
sends data, so it actually works provided that you take some precautions (more
details in the section on the `power` script).  As a reminder, knowing current
state is required because attempting to power off a system that's powered off
will likely turn it on (and if you send several requests in a row, only the
first one might affect the state and others will be ignored because transition
is in progress, thus making final result a mystery).

A better and more reliable way of checking power state would be monitoring
power LED state (thanks to [marmarek][marmarek] for mentioning this).  The
power script can be simplified once hardware setup is updated accordingly.

By the way, terminology used by openQA can be surprising and its use is not very
consistent.  Just know that test suites like the one linked above are called
"distributions" and shortened to "distri".

[qubesos-test-suite]: https://github.com/QubesOS/openqa-tests-qubesos
[marmarek]: https://github.com/marmarek

```log
Can't exec "v4l2-ctl": No such file or directory at /usr/lib/os-autoinst/consoles/video_stream.pm line 61.
[2023-10-29T20:31:02.728447+01:00] [debug] [pid:26068] DV timings not supported
```

`generalhw` thinks that `/dev/video0` is where openQA worker is running and
attempts to query its DV timings.  Thus this error doesn't indicate any issue.

```log
[2023-10-29T20:31:02.728773+01:00] [debug] [pid:26068] Starting to receive video stream at /dev/video0
```

This is when `generalhw` starts receiving frames from the SUT.

```log
[2023-10-29T20:31:02.735490+01:00] [debug] [pid:26068] Connecting input device
```

There is no corresponding log line but `GENERAL_HW_INPUT_CMD` is invoked here.

```log
GOT GO
```

Not really obvious but it's `os-autoinsts`'s way of saying that tests are about
to start executing.

```log
{{ skipped start of tests and video.webm encoding information }}
[2023-10-29T20:31:18.690773+01:00] [debug] [pid:26062] >>> testapi::_handle_found_needle: found bootloader-uefi-20230104, similarity 1.00 @ 19/75
[2023-10-29T20:31:18.693391+01:00] [debug] [pid:26062] <<< testapi::send_key(key="up", wait_screen_change=0)
[2023-10-29T20:31:18.898098+01:00] [debug] [pid:26062] <<< testapi::send_key(key="e", wait_screen_change=0)
[2023-10-29T20:31:19.101320+01:00] [debug] [pid:26062] <<< testapi::send_key(key="down", wait_screen_change=0)
[2023-10-29T20:31:19.304920+01:00] [debug] [pid:26062] <<< testapi::send_key(key="down", wait_screen_change=0)
[2023-10-29T20:31:19.508011+01:00] [debug] [pid:26062] <<< testapi::send_key(key="down", wait_screen_change=0)
[2023-10-29T20:31:19.711054+01:00] [debug] [pid:26062] <<< testapi::send_key(key="end", wait_screen_change=0)
[2023-10-29T20:31:19.914757+01:00] [debug] [pid:26062] <<< testapi::type_string(string=" inst.sshd inst.ks=http://192.168.kvm.ip:6789/ks.cfg", max_interval=250, wait_screen_change=0, wait_still_screen=0, timeout=30, similarity_level=47)
[2023-10-29T20:31:20.789090+01:00] [debug] [pid:26062] <<< testapi::send_key(key="f10", wait_screen_change=0)
```

We've just got to part specific to Qubes OS setup.  Test suite in addition to
video, mouse and keyboard, also needs access to shells.  QEMU-based tests use
`virtio` consoles, real hardware uses SSH.  The catch is that SSH server is off
by default in the installer and installed system.  In order to automate working
around that a [Kickstart][kickstart-doc] script needs to be supplied to the
installer via kernel parameters.

Original Qubes OS testing setup extracts files from installation ISO and patches
them to achieve this (see [the script][mount-iso]).  That setup also uses
installation over LAN which needs that extraction step anyway (you can see in
the script recreation of ISO as well as some hardware needs an ISO).  This setup
however does it simply by interactively editing GRUB's commands to append
`inst.sshd inst.ks=http://192.168.kvm.ip:6789/ks.cfg`.

`ks.cfg` file is served by [Nginx][nginx] bundled with PiKVM.  It's already
installed, always running and might as well perform this task.  Kickstart file
can run shell commands before and after installation and also has various
[builtin commands][kickstart-commands].

[kickstart-doc]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_8_installation/kickstart-script-file-format-reference_installing-rhel-as-an-experienced-user
[kickstart-commands]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_8_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user
[mount-iso]: https://github.com/QubesOS/tests-hw-setup/blob/aab12ae18820dda692637ef29856f7e53a8221c9/states/openqa-cmds/mount-iso
[nginx]: https://nginx.org/

```log
{{ skipped tests asserts }}
[2023-10-29T20:46:38.088778+01:00] [debug] [pid:26068] Connecting SSH serial console for root@192.168.sut.ip port 22
[2023-10-29T20:46:38.091373+01:00] [debug] [pid:26068] <<< backend::baseclass::new_ssh_connection(hostname="192.168.sut.ip", username="root", use_ssh_agent=0, password="SECRET", port=22)
[2023-10-29T20:46:38.257653+01:00] [debug] [pid:26068] SSH connection to root@192.168.sut.ip established
```

This is the first time worker connects to the SUT.  It happens during
installation process.

```log
{{ skipped tests asserts }}
[2023-10-29T20:46:48.064061+01:00] [debug] [pid:26062] <<< testapi::assert_and_click(mustmatch="installer-install-done-reboot", timeout=30)
[2023-10-29T20:46:48.066576+01:00] [debug] [pid:26062] clicking at 952/738
```

Installer has finished and system is about to be reboot.

```log
{{ skipped tests asserts }}
[2023-10-29T20:59:24.629534+01:00] [debug] [pid:26068] Connecting SSH serial console for root@192.168.sut.ip port 22
[2023-10-29T20:59:24.631819+01:00] [debug] [pid:26068] <<< backend::baseclass::new_ssh_connection(username="root", hostname="192.168.sut.ip", use_ssh_agent=0, port=22, password="SECRET")
[2023-10-29T20:59:24.871345+01:00] [debug] [pid:26068] SSH connection to root@192.168.sut.ip established
[2023-10-29T20:59:25.119391+01:00] [debug] [pid:26062] activate_console, console: root-virtio-terminal, type: virtio-terminal
```

Worker connects to the SUT again after reboot, it's no longer an installer.

```log
{{ skipped tests asserts }}
[2023-10-29T20:59:26.994920+01:00] [debug] [pid:26045] stopping command server 26054 because test execution ended
[2023-10-29T20:59:26.995327+01:00] [debug] [pid:26045] isotovideo: informing websocket clients before stopping command server: http://127.0.0.1:20023/ajAQ0bqHvk14Yvp8/broadcast
[2023-10-29T20:59:27.081067+01:00] [debug] [pid:26045] commands process exited: 0
[2023-10-29T20:59:27.182127+01:00] [debug] [pid:26045] done with command server
[2023-10-29T20:59:27.182423+01:00] [debug] [pid:26045] isotovideo done
[2023-10-29T20:59:27.183791+01:00] [debug] [pid:26045] backend shutdown state: -1
[2023-10-29T20:59:27.187153+01:00] [debug] [pid:26068] Calling GENERAL_HW_POWEROFF_CMD
Setting EDID
Setting DV timings
VIDIOC_S_DV_TIMINGS: failed: Device or resource busy
Setting EDID
Setting DV timings
BT timings set
DUT is off
Switched DUT's state from 'unknown'.
[2023-10-29T20:59:50.930422+01:00] [debug] [pid:26068] Closing SSH connection with 192.168.sut.ip
[2023-10-29T20:59:50.931789+01:00] [debug] [pid:26068] Passing remaining frames to the video encoder
{{ skipped uninteresting epilog }}
```

Tests have finished and SUT is being shut down.  There is "Device or resource
busy" error when attempting to access `/dev/video0` on PiKVM, which prevented
determining initial SUT's state.  This happened because `ffmpeg` process there
was still running.  On the second probe, DUT's/SUT's state was determined to be
off and the script has exited.

## Configuration and scripts

`/etc/openqa/workers.ini` file specifies which workers exist, what kind of
workers they are and their settings.  Here's a possible configuration (if you
change yours, don't forget to restart corresponding worker to apply the changes):

```log
[2]
WORKER_CLASS = generalhw
WORKER_HOSTNAME = unused

GENERAL_HW_CMD_DIR = /var/lib/openqa/share/tests/qubesos/generalhw
GENERAL_HW_VIDEO_STREAM_URL = /dev/video0
GENERAL_HW_VIDEO_CMD_PREFIX = sshpass -proot ssh -q -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oControlMaster=auto -oControlPersist=60 -oControlPath=/tmp/generalhw-%C root@192.168.kvm.ip timeout 4s

GENERAL_HW_FLASH_CMD = flash
GENERAL_HW_FLASH_ARGS = 192.168.rte.ip 192.168.kvm.ip

GENERAL_HW_POWERON_CMD = power
GENERAL_HW_POWERON_ARGS = 192.168.rte.ip 192.168.kvm.ip pon

GENERAL_HW_POWEROFF_CMD = power
GENERAL_HW_POWEROFF_ARGS = 192.168.rte.ip 192.168.kvm.ip poff

GENERAL_HW_SOL_CMD = sol
GENERAL_HW_SOL_ARGS = 192.168.rte.ip 13541

GENERAL_HW_INPUT_CMD = input
GENERAL_HW_INPUT_ARGS = 192.168.kvm.ip

# additional configuration for Qubes OS tests
QUBES_OS_KS_URL = http://192.168.kvm.ip:6789/ks.cfg
QUBES_OS_HOST_IP = 192.168.sut.ip
```

`GENERAL_HW_VIDEO_CMD_PREFIX` here is an extension in a patched version of
`os-autoinst` to be able to run `ffmpeg` via SSH.  The changes can be found
in [this fork][os-autoinst-fork] or in an [upstream PR][os-autoinst-pr].

Workers have numeric names.  You specify worker's class, its hostname (which
seems to be unused when worker and server are on the same machine), where to
find scripts, any other variables and how to invoke the scripts.

The following sections cover the scripts.  The description will be primarily
about what they do and why rather than how because it's unlikely to be
directly applicable in any other setup.

[os-autoinst-fork]: https://github.com/TrenchBoot/os-autoinst/tree/generalhw-remote-video
[os-autoinst-pr]: https://github.com/os-autoinst/os-autoinst/pull/2400

### gadget-control script for PiKVM

It's a script from [Qubes OS test hardware setup][qubesos-hw-setup].  It
provides keyboard, mouse and storage.  Works fine without modification, although
you might find it helpful to comment out [these lines][gadget-control] if you'll
get an error from them (uncomment them back after a successful run).

The script can take commands on standard input or listen to a Unix socket.  The
latter method is used during test runs.

An interesting thing is that after stopping `kvmd-otg` and starting
`gadget-control`, keyboard works in PiKVM's Web-UI as before (but not the
mouse; if you go through materials mentioned at the top, you'll know that
`gadget-control` provides a tablet gadget instead of a mouse).  I didn't check
it but device id probably ends up being the same, which would explain this
behavior.

[qubesos-hw-setup]: https://github.com/QubesOS/tests-hw-setup
[gadget-control]: https://github.com/QubesOS/tests-hw-setup/blob/aab12ae18820dda692637ef29856f7e53a8221c9/states/openqa-cmds/gadget-control#L201-L202

### generalhw script for PiKVM

This is a helper for PiKVM which switches between `gadget-control` and PiKVM.
The most interesting bit about it is cleanup of USB gadgets from `configfs`.

`gadget-control` creates `/sys/kernel/config/usb_gadget/kbd` and `kvmd-otg`
creates `/sys/kernel/config/usb_gadget/kbd`.  Two gadgets can't be both
functional at the same time and if either wasn't cleaned up the other won't be
created.  `generalhw` script does cleanup via

```bash
find /sys/kernel/config/usb_gadget/kbd -delete 2>/dev/null
```

`rm -rf` won't do as it stops the traversal after hitting an error while
`find -delete` treats every deletion independently and does the job.  There is
also a write of empty line to `.../UDC` file inside of gadget's directory to
disable it.

### flash script for openQA worker

SSH as used here and in several other places requires extra options.  The
command looks like this:

```bash
sshpass -pPASSWORD \
        ssh -q -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null USER@HOST ...
```

Devices aren't available on the Internet, so no need to distribute keys and can
use password authentication via `sshpass`.  Trust in target hosts is also
implicit, so avoiding a failure with `StrictHostKeyChecking=no` and disabling
printing warnings with `-q`.  `UserKnownHostsFile=/dev/null` is necessary
because of `$HOME` directory (`/var/lib/empty`) is read-only for openQA worker.
Of course this can be made more secure but you might not want to complicate
things at least at first.

You can read this in `man ssh_config` in relation to `UserKnownHostsFile`:

> A value of none causes ssh(1) to ignore any user-specific known hosts files.

However, setting `UserKnownHostsFile=none` somehow results in authorization
failure in this case while `UserKnownHostsFile=/dev/null` works fine.

In addition to flashing the script is also responsible for starting
`gadget-control` in background on PiKVM.  There are several pitfalls to watch
out for when trying to launch background process remotely.  The correct command
has the following form:

```bash
ssh USER@HOST "openqa/generalhw on /tmp/gadget-control '$image_name' >/var/log/gadget-control 2>&1 &"
```

In short (also [see][ssh-detach]):

- do not drop quotes and accidentally redirect on the client side
- don't bother with `nohup` as no pseudo-terminal is allocated
- don't bother with `setsid` or `detach`
- don't bother with starting terminal multiplexer unless you actually need it
- **make sure that no SSH descriptors are kept open** by the command or calling
  side will wait for them (input isn't redirected above which works fine, but
  it won't always work, so use `</dev/null` or `-n` option if unsure)

[ssh-detach]: https://unix.stackexchange.com/a/30433

### input script for openQA worker

A simple one, just runs this command on PiKVM over SSH:

```bash
socat stdin -u /tmp/gadget-control
```

`/tmp/gadget-control` is a Unix socket on which `gadget-control` script receives
its commands.

### power script for openQA worker

As mentioned earlier, video capturing is used for checking SUT's state.  And
video requires EDID and DV timings to be set.

EDID is set via

```bash
v4l2-ctl --set-edid file=path/to/file
```

Documentation says you can use `-` for file name and pass its contents via
stdin, but this results in checksum failure even when using path to file with
the same content works.  EDID file is stored on PiKVM.  It's original EDID read
via `v4l2-ctl --get-edid` and then updated to use 1024x768 resolution by default.

Setting timings doesn't require any files, but values need to correspond to
EDID:

```bash
v4l2-ctl --set-dv-bt-timings cvt,width=1024,height=768,fps=60,clear,reduced-blanking=1
```

See respective sections below for more information.

### sol script for openQA worker

This is just another application of `socat`, this time without SSH:

```bash
socat -U stdio "TCP:$RTE:13541"
```

RTE makes serial connection available over the network via `ser2net`, so just
need to read from it (do not open the same device via `minicom` on RTE, there
can be only one client).

### Serving ks.cfg via Nginx

Installer needs to download this file from somewhere and PiKVM is a good choice
for the task.  The file doesn't have to be static and can be modified before
starting the installation if it's necessary to change IP address, for example.
`http` section of `/etc/kvmd/nginx/nginx.conf` should be extended with lines
like these:

```nginx
server {
    listen      6789;
    location /ks.cfg {
        root /etc/kvmd/nginx/;
    }
}
```

Then put `/etc/kvmd/nginx/ks.cfg`:

```config
# default settings, to mimic interactive install
keyboard --vckeymap=us
timezone --utc UTC

sshpw --username root --plaintext userpass

%packages
@^qubes-xfce
#@debian
#@whonix
%end

%pre
sed -i '/PasswordAuthentication/s!no!yes!' /etc/ssh/sshd_config.anaconda
systemctl stop sshd.socket
systemctl stop sshd.service
systemctl restart anaconda-sshd
ip addr replace 192.168.sut.ip dev eth0

fdisk /dev/nvme0n1 << FDISK
d
8
d
7
w
FDISK
%end

%post

# enable password root login over SSH
mkdir -p /etc/ssh/sshd_config.d
echo 'PermitRootLogin yes' > /etc/ssh/sshd_config.d/30-openqa.conf

# enable SSH on first boot
cat >/usr/local/bin/post-setup << EOF_POST_SETUP
#!/bin/sh

set -xe

qvm-run -p --nogui -- sys-net nm-online -t 300
qubes-dom0-update -y openssh-server
systemctl enable --now sshd
printf 'qubes.ConnectTCP +22 sys-net dom0 allow\n' >> /etc/qubes/policy.d/30-openqa.policy

qvm-run --nogui -u root -p sys-net 'cat >>/rw/config/rc.local' << EOF_ALLOW_22
nft add rule ip qubes custom-input tcp dport ssh accept
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
qvm-connect-tcp 22:dom0:22
EOF_ALLOW_22
qvm-run --nogui -u root sys-net '/rw/config/rc.local </dev/null &>/dev/null'

systemctl disable post-setup.service
EOF_POST_SETUP
chmod +x /usr/local/bin/post-setup

cat >/etc/systemd/system/post-setup.service << EOF_SERVICE
[Unit]
After=initial-setup.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/post-setup
[Install]
WantedBy=multi-user.target
EOF_SERVICE
systemctl enable post-setup.service
echo enable post-setup.service >> /usr/lib/systemd/system-preset/30-openqa.preset

%end
```

The file is based on [ks.cfg.jinja][ks.cfg.jinja] with some changes:

1. Use of password instead of a key for SSH user account of the installer
2. Allowing password login over SSH in the installer
3. Explicitly setting IP address to enable network
4. Dropping partitions from the previous installation
5. Removing parts related to `is_tcp_serial`

[ks.cfg.jinja]: https://github.com/QubesOS/tests-hw-setup/blob/aab12ae18820dda692637ef29856f7e53a8221c9/states/files/ks.cfg.jinja

## openQA configuration and posting a job

Configuration of openQA has `install-iso-hw` flavor associated with `msi`
machine in job groups like so (there might be a prettier way; also not showing
other lines for brevity):

```yaml
products:
  qubesos-4.2-install-iso-hw-x86_64:
    distri: qubesos
    flavor: install-iso-hw
    version: '4.2'
scenarios:
  x86_64:
    qubesos-4.2-install-iso-hw-x86_64:
    - test-suite:
        machine: msi
```

And `msi` machine has in its configuration:

```config
+WORKER_CLASS=generalhw
```

openQA matches `WORKER_CLASS` value of machines against the same variable in
`/etc/openqa/workers.ini` to figure out which worker should handle a task.

Example command-line for posting a job:

```bash
openqa-cli api -X POST isos ISO=Qubes-R4.2.0-rc1-x86_64.iso \
                            HDD_1=Qubes-R4.2.0-rc1-x86_64.iso \
                            DISTRI=qubesos \
                            VERSION=4.2 \
                            FLAVOR=install-iso-hw \
                            ARCH=x86_64 \
                            BUILD=4.2.0-rc1 \
                            INSTALL_TEMPLATES=fedora
```

`generalhw` backend passes `GENERAL_HW_FLASH_CMD` script only `HDD_*` variables
on invocation, so if you want to use `isos`, you need to duplicate its value in
`HDD_1` and make it available in `/var/lib/openqa/share/factory/hdd` (symlink
works).

## Background information

### EDID

[EDID][edid-wiki] communicates supported capabilities of a video sink (display
or a something like HDMI input in this case).  By default, the highest supported
resolution is picked which might be larger than what openQA expects to work with
(1024x768).

As a workaround one can start with the original EDID and adjust suggested
resolution in it.

Viewing and checking checksum correctness can be done online via
<http://www.edidreader.com/> that supports pasting EDID in a hex dump form.
Default resolution is in `Block 0/Standard Timing Information/Descriptor 1`.
This site won't help with editing though.

Another helpful site is <https://thyge.github.io/edid-editor/>.  It's less
convenient for viewing as you have to select a local file with `.bin` or `.txt`
extension to view (there is no error if extension is wrong, UI will just act
weird), but there is editing support.  UX isn't great and needs an explanation:

1. Click "Browse..."
2. Click "EDIT"
3. I remember unselecting 1280x1024@75 in "Established Timings", but that might
   not be necessary
4. More important is to edit display descriptor:

   1. Remove the top one first to be able to add a new one
   2. Press "CREATE TIMING"
   3. Set "Horizontal/Vertical Pixels"
   4. Click "Add"

5. Click "DOWNLOAD FILE" which will be named `test.bin`
6. Convert binary data to textual format expected by `v4l2-ctl --set-edid ...`:

   ```bash
   hexdump --format '16/1 "%02x " "\n"' test.bin
   ```

While editing, EDID also appears in the top-right corner and it's possible to
copy&paste that as text but in a different format.

[edid-wiki]: https://en.wikipedia.org/wiki/Extended_Display_Identification_Data

### DV timings

In addition to EDID, there is also video format and timings.  Setting video
format didn't help, but timings did make the difference.  If timings are off,
some portion of the screen might be filled with green, so they need to align
with EDID, for example:

```bash
v4l2-ctl --set-dv-bt-timings cvt,width=1024,height=768,fps=60,clear,reduced-blanking=1
```

I initially missed `reduced-blanking` and total width and height were off in
the output of `v4l2-ctl --get-dv-timings` compared to same output when PiKVM was
capturing the video.  I still got partially green screen (like
[here][green-example]) and spent some time trying to match PiKVM's settings with
commands like:

```bash
v4l2-ctl --set-dv-bt-timings cvt,width=1024,height=768,fps=60,reduced-blanking=1,pixelclock=52380160,polarities=0,hfp=0,hs=160,hbp=0,vfp=0,vs=22,vbp=0
```

But in the end that turned out to be unnecessary, green areas are visible in
PiKVM Web-UI as well and are apparently expected for the first frame or two.

Setting video format with `--set-fmt-video` wasn't necessary probably because
default worked fine, but do know that it might be needed.

[green-example]: https://raspberrypi.stackexchange.com/questions/112743/v4l2-ctl-single-frame-capture-produces-image-with-green-ending

### Video hangs

Getting `ffmpeg` to start capturing video doesn't guarantee that it won't stop
doing that.  In particular it seems to happen whenever SUT resets or changes
video settings.  `generalhw` backend works around that by verifying output of
`v4l2-ctl --get-dv-timings` every 3 seconds and restarting `ffmpeg` when change
is detected.

However, that's doesn't seem to be enough (video hangs still occur), so `ffmpeg`
invocation is prefixed with `timeout 4s` which causes `generalhw` to restart it
regularly (it handles death of the process).  SSH connection is
[multiplexed][ssh-mux-wiki] with control master keeping unused connection alive
for 60 seconds to avoid unnecessary delays due to reconnections.

[ssh-mux-wiki]: https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing

## Video capturing

After figuring out EDID and DV timings, the next step is to get video streaming
going.  A variety of approaches were looked at here, because `generalhw` backend
really assumes it works on the same machine that captures the video and I needed
to stream the data over the network.

### PiKVM's VNC

This was the original idea.  In addition to video, VNC was expected to provide
keyboard (after mapping key names) and mouse (maybe not, `generalhw` might
depend on mouse being presented as a tablet to specify absolute coordinates).

After openQA started to fail during VNC login, turned out that `generalhw` needs
to specify PiKVM's password and PiKVM needs to enable VNCAuth security type.

Unfortunately PiKVM's VNC still wouldn't work with openQA because of mismatched
formats.  openQA supports only raw and ZRLE encodings, while PiKVM provides
Tight JPEG and H.264.  Tight JPEG seems to be just: 1 byte of compression type,
1-3 bytes of data length, JPEG file of that length.  `os-autoinst` has a Perl
extension that is written in C++ and uses OpenCV which should do just fine with
parsing JPEG.  So in principle one could add its support to openQA (there were
also some zlib streams, which I didn't get, but it shouldn't complicate things
too much).

### cat /dev/video0 over SSH

You can find a suggestion to do `ssh host cat /dev/video0 | ffmpeg ...` but that
doesn't actually work.  In addition to getting stream of bytes from
`/dev/video0`, there is also a bunch of `ioctl()` calls needed to interpret
them or configure the device.

### Encode stream and send over SSH

You could use a similar approach and move `ffmpeg` to PiKVM and send encoded
data over SSH to then consume it.  In most cases, this resulted in PiKVM
running out of memory and rebooting.

There are a bunch of parameters you can play with or `ffmpeg` version with
Raspberry Pi optimizations, but it didn't seem like a working solution.

Also tried `gstreamer` but it didn't behave noticeably better.

### WebRTC

I was almost certain that [WebRTC][webrtc] was created to make video streaming
easy, turned out it's basically a subset of browser's API which is not generally
usable.  It doesn't provide a way to publish or consume an arbitrary stream
and works only between specific client and specific server that were meant to
work together.  Which is why my idea of using WebRTC stream provided by Janus as
for `generalhw` backend was doomed to fail.

[webrtc]: https://en.wikipedia.org/wiki/WebRTC

### RTMP

Video streaming isn't something new, so it was natural to look up existing
protocols.  Things seem more complicated than I expected (many solutions assume
many-to-many broadcasting with transcoding and other stuff that's unnecessary
here), but because I found [Nginx module][nginx-rtmp-module] for [RTMP][rtmp] I
gave it a try.

Using `ffmpeg` to publish the stream worked, but the delay was about 30 seconds
or even more.  Latency eventually improved but only down to about 10 seconds.
That seems like a common problem, some people manage to combat it, but others
get stuck even when using the same settings.

Modifying plugin of `ustreamer` to send RTMP stream after packing H.264 into
FLV worked partially: server received the stream, but didn't provide it to
clients.  Something must have been wrong, but not sure what.  The point was to
eliminate `ffmpeg` and possibly reduce the latency.

[rtmp]: https://en.wikipedia.org/wiki/Real-Time_Messaging_Protocol
[nginx-rtmp-module]: https://github.com/arut/nginx-rtmp-module/

### Running ffmpeg on PiKVM

Eventually running `ffmpeg` over SSH turned out to work, but not the way it was
tried initially: with 2 frames per second and "encoding" into [PPM][ppm-wiki].

The various attempts wouldn't be necessary if it was known how little openQA
needs, but that part seems to not be documented.

[ppm-wiki]: https://en.wikipedia.org/wiki/Netpbm#File_formats

### More alternatives

There is also [SRS][srs], but it had issues with authentication.

One more possibility is using [v4l2rtspserver][v4l2rtspserver] which isn't
packaged for Raspberry Pi and might have delay issues like RTMP approach.

These were looked at as less resource-hungry alternatives to `ffmpeg` which also
requires a server (there used to be [ffserver][ffserver], but it got removed).

[srs]: https://github.com/ossrs/srs
[v4l2rtspserver]: https://github.com/mpromonet/v4l2rtspserver
[ffserver]: https://trac.ffmpeg.org/wiki/ffserver

## Limitations

The most noticeable is that OpenQA supports grabbing resulting HDD image (via
script set in `GENERAL_HW_IMAGE_CMD` variable) and sharing it between tests.
Upstream's setup abuses LVM snapshots for this (in [openqa-flash][openqa-flash]
script).  This setup doesn't handle image sharing or downloading at the moment.

[openqa-flash]: https://github.com/QubesOS/tests-hw-setup/blob/aab12ae18820dda692637ef29856f7e53a8221c9/states/openqa-cmds/openqa-flash

## Stability

Tests don't always succeed when they should.  There are many moving parts and
sometimes they misbehave with failed test passing on second try.  Some of this
might be hard to address, but other issues should be ironed out once the
reason behind occasional failures is known (debugging a setup spanning multiple
devices is not exactly easy).

## Summary

The post provided another example of using openQA to test Qubes OS on hardware,
this time with opeQA worker being local to the openQA server and remote
relative to PiKVM.

In general, unless you're reproducing an existing working setup exactly, you'll
have to deal with challenges like those covered in this post.  It was written
to document issues, solutions, and possible alternatives
to consider if there will be another need to do something similar in the future
to make it easier.  As practice has demonstrated, setups like these are rare and
hard to get working, so extra help won't hurt.

---
post_title: 
author: Piotr Król
layout: post
tags:
  - Zephyr
  - Nordic
  - nrf52
  - RTOS
  - BLE
categories:
  - Firmware
  - IoT
---

Recently we get back to Nordic chips and found [this blog post](https://devzone.nordicsemi.com/blogs/1059/nrf5x-support-within-the-zephyr-project-rtos/).
There is also official [Zephyr guide for nRF52-DK](http://docs.zephyrproject.org/boards/arm/nrf52_pca10040/doc/nrf52_pca10040.html).
After attending last 3 ELCE conferences we are convinced that Linux Foundation
and rest of Zephyr Project RTOS are serious about making this system well
prepared for embedded systems developers. We wrote couple of times about [Zephyr](https://3mdeb.com/tag/zephyr/).

Probably the most interesting is 


# Prepare environment

I put my whole development environment in Docker container, so you don't have
to get through setup steps, but just pull Docker image and start development. I
assume you have Docker installed and you use it for embedded systems
development, if not please consider it. Great for tools isolation and
development environment separation.

```
docker pull 3mdeb/zephyr-docker
```

If you are interested how it is built you can go to our [github](https://github.com/3mdeb/zephyr-docker).

Depending how you install Zephyr container you will compile application
differently.

To run container use `./init.sh` from Github or type:

```
git clone https://github.com/zephyrproject-rtos/zephyr.git
docker run --rm -t -i --privileged -v /dev/bus/usb:/dev/bus/usb \
-v $PWD/zephyr:/home/build/zephyr 3mdeb/zephyr-docker /bin/bash
```

# Demo application for nRF52-DK

```
cd ~/zephyr
source zephyr-env.sh
cd samples/bluetooth/beacon
mkdir build && cd build
cmake -DBOARD=nrf52_pca10040 ..
make
make flash
```

You should get output on `/dev/ttyACM0` device:

```
Starting Beacon Demo
[bt] [INF] hci_vs_init: HW Platform: Nordic Semiconductor (0x0002)
[bt] [INF] hci_vs_init: HW Variant: nRF52x (0x0002)
[bt] [INF] hci_vs_init: Firmware: Standard Bluetooth controller (0x00) Version 1.10 Build 99
[bt] [INF] show_dev_info: Identity: c5:91:a2:54:e0:c3 (random)
[bt] [INF] show_dev_info: HCI: version 5.0 (0x09) revision 0x0000, manufacturer 0xffff
[bt] [INF] show_dev_info: LMP: version 5.0 (0x09) subver 0xffff
Bluetooth initialized
Beacon started
```

# RPiZW failure

In this section I tried to follow [Nordic Getting Started](http://infocenter.nordicsemi.com/index.jsp?topic=%2Fcom.nordic.infocenter.iotsdk.v0.9.0%2Findex.html),
but some things didn't worked as expected. This section aim to setup IoT
gateway using RPiZW.

First I installed couple packages:

```
sudo apt-get install bluez radvd libcap-ng0 bluetooth blueman
```

Make sure that `radvd` was set according to [this instruction](http://infocenter.nordicsemi.com/index.jsp?topic=%2Fcom.nordic.infocenter.iotsdk.v0.9.0%2Findex.html) and check its
status:

```
pi@raspberrypi:~ $ sudo service radvd status
● radvd.service - Router advertisement daemon for IPv6
   Loaded: loaded (/lib/systemd/system/radvd.service; disabled; vendor preset: enabled)
   Active: active (running) since Sat 2017-12-16 16:07:25 UTC; 6min ago
     Docs: man:radvd(8)
  Process: 953 ExecStart=/usr/sbin/radvd --logmethod stderr_clean (code=exited, status=0/SUCCESS)
  Process: 950 ExecStartPre=/usr/sbin/radvd --logmethod stderr_clean --configtest (code=exited, status=0/SUCCESS)
 Main PID: 955 (radvd)
   CGroup: /system.slice/radvd.service
           ├─955 /usr/sbin/radvd --logmethod stderr_clean
           └─956 /usr/sbin/radvd --logmethod stderr_clean

Dec 16 16:07:25 raspberrypi systemd[1]: Starting Router advertisement daemon for IPv6...
Dec 16 16:07:25 raspberrypi radvd[950]: config file, /etc/radvd.conf, syntax ok
Dec 16 16:07:25 raspberrypi radvd[953]: version 2.15 started
Dec 16 16:07:25 raspberrypi systemd[1]: Started Router advertisement daemon for IPv6.
```

Also `bluetooth` service should work fine, but in my case I saw this error:

```
Dec 16 16:10:28 raspberrypi bluetoothd[997]: Failed to obtain handles for "Service Changed" characteristic
Dec 16 16:10:28 raspberrypi bluetoothd[997]: Sap driver initialization failed.
Dec 16 16:10:28 raspberrypi bluetoothd[997]: sap-server: Operation not permitted (1)
```

Apparently this has something to do with D-Bus after digging little bit I found
[this stackexchange question](https://raspberrypi.stackexchange.com/questions/40839/sap-error-on-bluetooth-service-status#).
If you don't have plans to use `SIM Access Profile` you can disable this plugin
and avoid annoying error. After applying configuration `bluetooth` starts without problems:

```
Dec 16 16:38:12 raspberrypi systemd[1]: Starting Bluetooth service...
Dec 16 16:38:12 raspberrypi bluetoothd[2055]: Bluetooth daemon 5.43
Dec 16 16:38:12 raspberrypi bluetoothd[2055]: Starting SDP server
Dec 16 16:38:12 raspberrypi bluetoothd[2055]: Excluding (cli) sap
Dec 16 16:38:12 raspberrypi bluetoothd[2055]: Bluetooth management interface 1.14 initialized
Dec 16 16:38:13 raspberrypi systemd[1]: Started Bluetooth service.
```

BTW this profile is very interesting according to [wiki](https://en.wikipedia.org/wiki/List_of_Bluetooth_profiles#SIM_Access_Profile_\(SAP,_SIM,_rSAP\)) 
it is used in cars to give car phone  access to Bluetooth enabled phone.

Unfortunately on of my two RPiZW expose `hci0` device. Once stopped to show
`wlan0` device. I'm not sure if this indicates hardware problem, but it appears
to me that this hardware is fragile.

# Zepyr debugging

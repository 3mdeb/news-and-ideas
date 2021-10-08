---
title: Porting fwupd to the BSD distributions - How to compile fwupd on FreeBSD
abstract: 'The security of the whole system is not determined only by the
          software it runs, but also the firmware. We want to provide easy
          firmware update method to BSD distributions.'
cover: /covers/fwupd_bsd.png
author: norbert.kaminski
layout: post
published: true
date: 2021-02-16
archives: "2021"

tags:
  - nlnet
  - BSD
  - fwupd
  - firmware
  - fwupd-for-BSD
categories:
  - Firmware

---

The security of the whole system is not determined only by the software it
runs, but also the firmware. Firmware is a piece of software inseparable
from the hardware. It is responsible for proper hardware initialization as
well as its security features. That means that the safety of the machine
strongly depends on the mitigations of vulnerabilities provided by firmware
(like microcode updates, bug/exploit fixes). For these particular reasons,
the firmware should be kept up-to-date. We want to provide an easy firmware
update method to BSD distributions.

This is the first blog-post from the fwupd port for the BSD distributions series.
We will present here the current status of our work. In this blog post, I will
show you how to compile and run the fwupd on FreeBSD. Please take into
account that this is heavily in **WIP** state and some fwupd functionalities
do not work correctly.

## fwupd overall information

![fwupd-arch](https://lvfs.readthedocs.io/en/latest/_images/architecture-plan.png)

The architecture of the fwupd project could be split into three layers.
The internet layer contains the LVFS database and the content delivery network.
This layer provides firmware and the metadata about the possible updates.
The whole update process is managed by fwupdmgr which exists in the session
layer. The firmware update manager is a CLI client tool, that handles the update
process. It takes the role of connector between the LVFS database and a fwupd
daemon. The fwupd daemon is placed in the third layer of the project
architecture. It is a system-activated daemon with a D-Bus interface,
that can be used by unprivileged clients. The daemon allows users
to perform wide upgrades and downgrades according to security policy.

If you want to know more about how the fwupd works, I encourage you to catch
up my on latest [FOSDEM presentation](https://video.fosdem.org/2021/D.bsd/porting_fwupd_to_the_bsd.webm).
Also, take a look at Artur's [blog post](https://blog.3mdeb.com/2019/2019-07-11-how-to-safely-and-easily-update-your-firmware/).

## Project configuration

We were using the FreeBSD 12.2 release during the development process.
If you want to follow our results, you can use our
[fwupd fork](https://github.com/3mdeb/fwupd/tree/wip/3mdeb/BSD-port).

You need to install fwupd dependencies:

```
# pkg install meson pkgconf libgudev python3 gobject-introspection gtk-doc vala json-glib libarchive gpgme help2man gcab tpm2-tss libelf freetype fontconfig
```

FreeBSD has its implementation of the libusb library. It lacks several
functions that are used in the fwupd subproject -
[libgusb](https://github.com/hughsie/libgusb).
Currently, to work around the problem, we are disabling the code that uses missing
functions. Change `subprojects/gusb.wrap` subproject config to the following:

```
[wrap-git]
directory = gusb
url = https://github.com/3mdeb/libgusb.git
revision = 69f0dab94cb4255216d15bbcf1021f12b52652a5
```

After that, you can configure the fwupd project with the following command:

```
$ meson build -Dplugin_uefi_capsule='false' \
              -Dplugin_dell='false' \
              -Dplugin_redfish='false' \
              -Dplugin_nvme='false' \
              -Dsystemd='false' \
              -Dtests='false' \
              -Dgudev='false' \
              -Dplugin_amt='false' \
              -Dtpm='false' \
              -Dplugin_emmc=false \
              -Dplugin_altos=false \
              -Dplugin_thunderbolt=false \
              -Dplugin_synaptics_mst=false \
              -Dpolkit=false \
              -Dbsd=true
```

Here is the configuration log:

```log
nkaminski@nkaminski:~/projects/fwupd $ meson build -Dplugin_uefi_capsule='false' -Dplugin_dell='false' -Dplugin_redfish='false' -Dplugin_nvme='false' -Dsystemd='false' -Dtests='false' -Dgudev='false' -Dplugin_amt=false -Dtpm=false -Dplugin_emmc=false -Dplugin_altos=false -Dplugin_thunderbolt=false -Dplugin_synaptics_mst=false -Dpolkit=false -Dbsd=true
Version: 0.56.0
Source dir: /usr/home/nkaminski/projects/fwupd
Build dir: /usr/home/nkaminski/projects/fwupd/build
Build type: native build
Project name: fwupd
Project version: 1.5.6
C compiler for the host machine: cc (clang 10.0.1 "FreeBSD clang version 10.0.1 (git@github.com:llvm/llvm-project.git llvmorg-10.0.1-0-gef32c611aa2)")
C linker for the host machine: cc ld.lld 10.0.1
Host machine cpu family: x86_64
Host machine cpu: x86_64
Program git found: YES (/usr/local/bin/git)
Compiler for C supports arguments -Waggregate-return: YES
Compiler for C supports arguments -Wunused: YES
Compiler for C supports arguments -Warray-bounds: YES
Compiler for C supports arguments -Wcast-align: YES
Compiler for C supports arguments -Wclobbered: NO
Compiler for C supports arguments -Wdeclaration-after-statement: YES
Compiler for C supports arguments -Wdiscarded-qualifiers: NO
Compiler for C supports arguments -Wduplicated-branches: NO
Compiler for C supports arguments -Wduplicated-cond: NO
Compiler for C supports arguments -Wempty-body: YES
Compiler for C supports arguments -Wformat=2: YES
Compiler for C supports arguments -Wformat-nonliteral: YES
Compiler for C supports arguments -Wformat-security: YES
Compiler for C supports arguments -Wformat-signedness: NO
Compiler for C supports arguments -Wignored-qualifiers: YES
Compiler for C supports arguments -Wimplicit-function-declaration: YES
Compiler for C supports arguments -Winit-self: YES
Compiler for C supports arguments -Wlogical-op: NO
Compiler for C supports arguments -Wmaybe-uninitialized: NO
Compiler for C supports arguments -Wmissing-declarations: YES
Compiler for C supports arguments -Wmissing-format-attribute: YES
Compiler for C supports arguments -Wmissing-include-dirs: YES
Compiler for C supports arguments -Wmissing-noreturn: YES
Compiler for C supports arguments -Wmissing-parameter-type: NO
Compiler for C supports arguments -Wmissing-prototypes: YES
Compiler for C supports arguments -Wnested-externs: YES
Compiler for C supports arguments -Wno-cast-function-type: NO
[...]
Run-time dependency gnutls found: YES 3.6.15
Has header "sys/utsname.h" : YES
Has header "sys/ioctl.h" : YES
Has header "errno.h" : YES
Has header "sys/socket.h" : YES
Has header "linux/ethtool.h" : NO
Has header "linux/hidraw.h" : NO
Has header "sys/mman.h" : YES
Has header "poll.h" : YES
Has header "fnmatch.h" : YES
Has header "cpuid.h" : YES
Header <cpuid.h> has symbol "__get_cpuid_count" : YES
Checking for function "getuid" : YES
Checking for function "realpath" : YES
Checking for function "sigaction" : YES
Checking for function "memfd_create" : NO
Header <locale.h> has symbol "LC_MESSAGES" : YES
Checking for function "pwrite" : YES
Configuring config.h using configuration
Configuring fwupd-version.h using configuration
Found pkg-config: /usr/local/bin/pkg-config (1.7.3)
Build-time dependency gobject-introspection-1.0 found: YES 1.66.1
Program g_ir_scanner found: YES (/usr/local/bin/g-ir-scanner)
Program g_ir_compiler found: YES (/usr/local/bin/g-ir-compiler)
Program vapigen found: YES (/usr/local/bin/vapigen)
WARNING: Gettext not found, all translation targets will be ignored.
WARNING: Project targeting '>=0.47.0' but tried to use feature introduced in '0.50.0': install arg in configure_file.
Configuring vendor.conf using configuration
Configuring vendor-directory.conf using configuration
Configuring fwupdtool using configuration
Configuring fwupdmgr using configuration
Configuring 85-fwupd using configuration
Program vapigen found: YES (/usr/local/bin/vapigen)
Program glib-compile-resources found: YES (/usr/local/bin/glib-compile-resources)
Program help2man found: YES (/usr/local/bin/help2man)
Compiler for C supports arguments -fcf-protection: YES
Program help2man found: YES (/usr/local/bin/help2man)
Configuring simple_client.py using configuration
Program makensis found: NO
Program codespell found: NO
Build targets in project: 65
WARNING: Project specifies a minimum meson_version '>=0.47.0' but uses features which were added in newer versions:
 * 0.50.0: {'install arg in configure_file'}

 Found ninja-1.10.2 at /usr/local/bin/ninja
 nkaminski@nkaminski:~/projects/fwupd $
```

## Project compilation

To compile the project go to build directory and run ninja:

```log
nkaminski@nkaminski:~/projects/fwupd/build $ ninja
[24/266] Generating symbol file libfwupd/libfwupd.so.2.0.0.p/libfwupd.so.2.0.0.symbols
WARNING: Symbol extracting has not been implemented for this platform. Relinking will always happen on source changes.
[50/266] Compiling C object src/fwupdmgr.p/fu-util.c.o
../src/fu-util.c:2731:20: warning: unused variable 'error_polkit' [-Wunused-variable]
g_autoptr(GError) error_polkit = NULL;
^
1 warning generated.
[67/266] Generating Fwupd-2.0.gir with a custom command
g-ir-scanner: link: cc -pthread -o /usr/home/nkaminski/projects/fwupd/build/tmp-introspect44ijw9pe/Fwupd-2.0 /usr/home/nkaminski/projects/fwupd/build/tmp-introspect44ijw9pe/Fwupd-2.0.o -L. -Wl,-rpath,. -Wl,--no-as-needed -L/usr/home/nkaminski/projects/fwupd/build/libfwupd -Wl,-rpath,/usr/home/nkaminski/projects/fwupd/build/libfwupd -L/usr/local/lib -Wl,-rpath,/usr/local/lib -lfwupd -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lintl -lgmodule-2.0 -ljcat -ljson-glib-1.0 -lcurl -lgirepository-1.0 -L/usr/local/lib -lgio-2.0 -lgobject-2.0 -Wl,--export-dynamic -lgmodule-2.0 -pthread -lglib-2.0 -lglib-2.0 -lintl
../libfwupd/fwupd-release.c:1856: Warning: Fwupd: fwupd_release_to_json: argument builder: Unresolved type: 'JsonBuilder*'
../libfwupd/fwupd-device.c:2284: Warning: Fwupd: fwupd_device_to_json: argument builder: Unresolved type: 'JsonBuilder*'
../libfwupd/fwupd-plugin.c:269: Warning: Fwupd: fwupd_plugin_to_json: argument builder: Unresolved type: 'JsonBuilder*'
../libfwupd/fwupd-security-attr.c:722: Warning: Fwupd: fwupd_security_attr_to_json: argument builder: Unresolved type: 'JsonBuilder*'
[81/266] Generating fwupd.vapi with a custom command
Fwupd-2.0.gir:14375.5-14377.24: warning: Instance methods are not supported in error domains yet
[83/266] Generating fwupdplugin.vapi with a custom command
Fwupd-2.0.gir:14375.5-14377.24: warning: Instance methods are not supported in error domains yet
[112/266] Compiling C object plugins/cpu/libfwupdcethelper.a.p/fu-cpu-helper-cet-common.c.o
../plugins/cpu/fu-cpu-helper-cet-common.c:18:27: warning: unknown attribute 'noclone' ignored [-Wunknown-attributes]
__attribute__ ((noinline, noclone))
^
../plugins/cpu/fu-cpu-helper-cet-common.c:25:27: warning: unknown attribute 'noclone' ignored [-Wunknown-attributes]
__attribute__ ((noinline, noclone))
^
2 warnings generated.
[140/266] Generating FwupdPlugin-1.0.gir with a custom command
g-ir-scanner: link: cc -pthread -o /usr/home/nkaminski/projects/fwupd/build/tmp-introspectuunfvxp_/FwupdPlugin-1.0 /usr/home/nkaminski/projects/fwupd/build/tmp-introspectuunfvxp_/FwupdPlugin-1.0.o -L. -Wl,-rpath,. -Wl,--no-as-needed -L/usr/home/nkaminski/projects/fwupd/build/libfwupdplugin -Wl,-rpath,/usr/home/nkaminski/projects/fwupd/build/libfwupdplugin -L/usr/home/nkaminski/projects/fwupd/build/libfwupd -Wl,-rpath,/usr/home/nkaminski/projects/fwupd/build/libfwupd -L/usr/home/nkaminski/projects/fwupd/build/libfwupdplugin -Wl,-rpath,/usr/home/nkaminski/projects/fwupd/build/libfwupdplugin -L/usr/local/lib -Wl,-rpath,/usr/local/lib -lfwupd -lfwupdplugin -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lintl -lgmodule-2.0 -ljcat -ljson-glib-1.0 -lcurl -lxmlb -lgusb -lusb -lgirepository-1.0 -L/usr/local/lib -lgio-2.0 -lgobject-2.0 -Wl,--export-dynamic -lgmodule-2.0 -pthread -lglib-2.0 -lglib-2.0 -lintl
../libfwupdplugin/fu-usb-device.h:13: Warning: FwupdPlugin: symbol='GUsbContext': Skipping foreign identifier 'GUsbContext' from namespace GUsb
../libfwupdplugin/fu-usb-device.h:14: Warning: FwupdPlugin: symbol='GUsbDevice': Skipping foreign identifier 'GUsbDevice' from namespace GUsb
../libfwupdplugin/fu-usb-device.h:15: Warning: FwupdPlugin: symbol='G_USB_CHECK_VERSION': Skipping foreign symbol from namespace GUsb
../libfwupdplugin/fu-srec-firmware.c:68: Warning: FwupdPlugin: Unknown container Type(target_giname=FwupdPlugin.SrecFirmwareRecord, ctype=FuSrecFirmwareRecord*) for element-type annotation
../libfwupdplugin/fu-device.c:2630: Warning: FwupdPlugin: fu_device_write_firmware: unknown parameter 'fw' in documentation comment, should be 'firmware'
../libfwupdplugin/fu-firmware-image.c:439: Warning: FwupdPlugin: fu_firmware_image_build: argument n: Unresolved type: 'XbNode*'
../libfwupdplugin/fu-firmware.c:256: Warning: FwupdPlugin: fu_firmware_build: argument n: Unresolved type: 'XbNode*'
[266/266] Linking target plugins/uefi-pk/libfu_plugin_uefi_pk.so
```

Install the fwupd files with the following command:

```
# ninja install
```

## Testing fwupd

As I mentioned earlier, the fwupd uses D-bus daemon to connect with devices.
To enable D-bus in your FreeBSD, you need to add the following option to
`/etc/rc.conf`:

```
dbus_enable="YES"
```

Once it is set up, reboot your OS. The output fwupd binaries are available in
the `build/src` directory. At first, run the fwupd daemon:

```log
# ./fwupd -v
10:11:35:0893 FuDebug              Verbose debugging enabled (on console 1)
10:11:35:0895 FuConfig             loading config values from /usr/local/etc/fwupd/daemon.conf
10:11:35:0896 FuConfig             using autodetected max archive size 18.4?EB
10:11:35:0899 XbSilo               attempting to load /var/local/cache/fwupd/metainfo.xmlb
10:11:35:0899 XbSilo               file: 32096c2e-0eff-33d8-44ee-6d675407ace1, current:32096c2e-0eff-33d8-44ee-6d675407ace1, cached: (null)
10:11:35:0899 XbSilo               loading silo with file contents
10:11:35:0900 FuRemoteList         loading remote from /usr/local/etc/fwupd/remotes.d/lvfs.conf
10:11:35:0902 FuRemoteList         loading remote from /usr/local/etc/fwupd/remotes.d/lvfs-testing.conf
10:11:35:0903 FuRemoteList         loading remote from /usr/local/etc/fwupd/remotes.d/vendor.conf
10:11:35:0904 FuRemoteList         loading remote from /usr/local/etc/fwupd/remotes.d/vendor-directory.conf
10:11:35:0905 FuRemoteList         ignoring unfound remote fwupd
10:11:35:0905 FuRemoteList         ordering lvfs-testing=lvfs+1
10:11:35:0905 Jcat                 ignoring GPG-KEY-Hughski-Limited as not PKCS-7 certificate
10:11:35:0905 Jcat                 ignoring GPG-KEY-Linux-Foundation-Firmware as not PKCS-7 certificate
10:11:35:0905 Jcat                 ignoring GPG-KEY-Linux-Vendor-Firmware-Service as not PKCS-7 certificate
10:11:35:0906 Jcat                 trying to load certificate from /usr/local/etc/pki/fwupd/LVFS-CA.pem
10:11:35:0906 Jcat                 reading /usr/local/etc/pki/fwupd/LVFS-CA.pem with 1679 bytes
10:11:35:0907 Jcat                 loaded 1 certificates
10:11:35:0907 Jcat                 ignoring GPG-KEY-Linux-Foundation-Metadata as not PKCS-7 certificate
10:11:35:0907 Jcat                 ignoring GPG-KEY-Linux-Vendor-Firmware-Service as not PKCS-7 certificate
10:11:35:0907 Jcat                 trying to load certificate from /usr/local/etc/pki/fwupd-metadata/LVFS-CA.pem
10:11:35:0908 Jcat                 reading /usr/local/etc/pki/fwupd-metadata/LVFS-CA.pem with 1679 bytes
10:11:35:0908 Jcat                 loaded 1 certificates
10:11:35:0909 Jcat                 reading /var/local/lib/fwupd/pki/secret.key with 2459 bytes
10:11:35:0909 Jcat                 reading /var/local/lib/fwupd/pki/client.pem with 1383 bytes
10:11:35:0955 FuEngine             client certificate exists and working
10:11:35:0955 FuHistory            trying to open database '/var/local/lib/fwupd/pending.db'
10:11:35:0957 FuHistory            got schema version of 6
10:11:35:0958 FuIdle               setting timeout to 7200s
10:11:35:0958 FuEngine             Failed to load SMBIOS: neither SMBIOS or DT found
10:11:35:0958 FuHwids              ignoring Manufacturer: no structure with type 01
10:11:35:0958 FuHwids              ignoring EnclosureKind: no structure with type 03
10:11:35:0958 FuHwids              ignoring Family: no structure with type 01
10:11:35:0958 FuHwids              ignoring ProductName: no structure with type 01
10:11:35:0958 FuHwids              ignoring ProductSku: no structure with type 01
10:11:35:0958 FuHwids              ignoring BiosVendor: no structure with type 00
10:11:35:0958 FuHwids              ignoring BiosVersion: no structure with type 00
10:11:35:0959 FuHwids              ignoring BiosMajorRelease: no structure with type 00
10:11:35:0959 FuHwids              ignoring BiosMinorRelease: no structure with type 00
10:11:35:0959 FuHwids              ignoring BaseboardManufacturer: no structure with type 02
10:11:35:0959 FuHwids              ignoring BaseboardProduct: no structure with type 02
10:11:35:0959 FuHwids              HardwareID-0 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-1 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-2 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-3 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-4 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-5 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-6 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-7 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-8 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-9 is not available, not available as 'Manufacturer' unknown
10:11:35:0959 FuHwids              HardwareID-10 is not available, not available as 'Manufacturer' unknown
10:11:35:0960 FuHwids              HardwareID-11 is not available, not available as 'Manufacturer' unknown
10:11:35:0965 FuHwids              HardwareID-12 is not available, not available as 'Manufacturer' unknown
10:11:35:0965 FuHwids              HardwareID-13 is not available, not available as 'Manufacturer' unknown
10:11:35:0965 FuHwids              HardwareID-14 is not available, not available as 'Manufacturer' unknown
10:11:35:0981 XbSilo               attempting to load /var/local/cache/fwupd/quirks.xmlb
10:11:35:0981 XbSilo               file: afa80999-27c4-e64b-132a-8a3ee221b912, current:afa80999-27c4-e64b-132a-8a3ee221b912, cached: (null)
10:11:35:0981 XbSilo               loading silo with file contents
10:11:35:0993 XbSilo               attempting to load /var/local/cache/fwupd/metadata.xmlb
10:11:35:0993 XbSilo               file: b15c58ce-f5a6-aad0-838a-5f8106c61656, current:b15c58ce-f5a6-aad0-838a-5f8106c61656, cached: (null)
10:11:35:0993 XbSilo               loading silo with file contents
10:11:36:0000 FuEngine             518 components now in silo
10:11:36:0020 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_acpi_dmar.so)
10:11:36:0020 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_acpi_facp.so)
10:11:36:0023 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_bcm57xx.so)
10:11:36:0023 FuPlugin             added udev subsystem watch of pci
10:11:36:0024 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_cpu.so)
10:11:36:0025 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_ep963x.so)
10:11:36:0026 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_iommu.so)
10:11:36:0026 FuPlugin             added udev subsystem watch of iommu
10:11:36:0026 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_linux_lockdown.so)
10:11:36:0027 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_linux_sleep.so)
10:11:36:0028 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_linux_swap.so)
10:11:36:0029 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_linux_tainted.so)
10:11:36:0034 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_dell_dock.so)
10:11:36:0035 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_nitrokey.so)
10:11:36:0036 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_pci_bcr.so)
10:11:36:0038 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_pci_mei.so)
10:11:36:0039 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_pixart_rf.so)
10:11:36:0039 FuPlugin             added udev subsystem watch of hidraw
10:11:36:0040 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_msr.so)
10:11:36:0040 FuPlugin             added udev subsystem watch of msr
10:11:36:0045 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_ccgx.so)
10:11:36:0046 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_colorhug.so)
10:11:36:0048 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_cros_ec.so)
10:11:36:0050 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_ebitdo.so)
10:11:36:0052 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_fastboot.so)
10:11:36:0054 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_fresco_pd.so)
10:11:36:0055 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_goodixmoc.so)
10:11:36:0058 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_hailuck.so)
10:11:36:0059 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_jabra.so)
10:11:36:0060 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_rts54hid.so)
10:11:36:0062 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_rts54hub.so)
10:11:36:0064 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_solokey.so)
10:11:36:0065 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_steelseries.so)
10:11:36:0068 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_synaptics_cxaudio.so)
10:11:36:0072 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_synaptics_prometheus.so)
10:11:36:0086 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_vli.so)
10:11:36:0091 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_wacom_usb.so)
10:11:36:0092 FuPlugin             init(/usr/local/lib/fwupd-plugins-3/libfu_plugin_uefi_pk.so)
10:11:36:0093 FuPluginList         cpu [0] to be ordered before msr [0] so promoting to [1]
10:11:36:0093 FuPluginList         cannot find plugin 'optionrom' referenced by 'bcm57xx'
10:11:36:0093 FuPluginList         cannot find plugin 'synaptics_mst' referenced by 'dell_dock'
10:11:36:0093 FuEngine             Emitting PropertyChanged('Status'='loading')
10:11:36:0093 FuMain               Emitting PropertyChanged('Status'='loading')
10:11:36:0093 FuPlugin             startup(linux_lockdown)
10:11:36:0094 FuPlugin             startup(linux_swap)
10:11:36:0094 FuPlugin             startup(linux_tainted)
10:11:36:0095 FuPlugin             startup(msr)
10:11:36:0096 FuPlugin             coldplug(cpu)
10:11:36:0101 FuDevice             using 4bde70ba4e39b28f9eab1628f9dd6e6244c03027 for cpu:0
10:11:36:0101 FuPlugin             emit added from cpu: 4bde70ba4e39b28f9eab1628f9dd6e6244c03027
10:11:36:0140 FuPlugin             fu_plugin_device_registered(dell_dock)
10:11:36:0141 FuPlugin             fu_plugin_device_registered(pci_bcr)
10:11:36:0141 FuPlugin             fu_plugin_device_registered(msr)
10:11:36:0141 FuDeviceList         ::added 4bde70ba4e39b28f9eab1628f9dd6e6244c03027
10:11:36:0143 FuPlugin             coldplug(uefi_pk)
10:11:36:0143 FuEngine             disabling plugin because: failed to coldplug using uefi_pk: efivarfs not currently supported on Windows
10:11:36:0144 FuEngine             using plugins: acpi_dmar, acpi_facp, bcm57xx, cpu, ep963x, iommu, linux_lockdown, linux_sleep, linux_swap, linux_tainted, dell_dock, nitrokey, pci_bcr, pci_mei, pixart_rf, ccgx, colorhug, cros_ec, ebitdo, fastboot, fresco_pd, goodixmoc, hailuck, jabra, rts54hid, rts54hub, solokey, steelseries, synaptics_cxaudio, synaptics_prometheus, vli, wacom_usb, msr
10:11:36:0260 FuEngine             Emitting PropertyChanged('Status'='idle')
10:11:36:0260 FuMain               Emitting PropertyChanged('Status'='idle')
10:11:36:0270 GLib-GIO             Failed to initialize portal (GMemoryMonitorPortal) for gio-memory-monitor: Not using portals
10:11:36:0275 GLib-GIO             _g_io_module_get_default: Found default implementation dbus (GMemoryMonitorDBus) for ?gio-memory-monitor?
10:11:36:0282 FuMain               Daemon ready for requests (locale (null))
10:11:36:0295 FuMain               acquired name: org.freedesktop.fwupd
```

Once the fwupd daemon is in the loop, you can test the base functionalities of
the fwupd project.

## fwupdmgr  get-devices

```log
nkaminski@nkaminski:~/projects/fwupd/build/src $ ./fwupdmgr  get-devices
WARNING: This package has not been validated, it may not work properly.
Unknown Product
│
└─ColorHug2:
      Device ID:          003dd5443e411c857e1a6220d9b68ee3136661ec
      Summary:            An open source display colorimeter
      Current version:    2.0.6
      Vendor:             Hughski Ltd. (USB:0x273F)
      Install Duration:   8 seconds
      GUIDs:              2082b5e0-7a64-478a-b1b2-e3404fab6dad
                          aa4b4156-9732-55db-9500-bf6388508ee3
                          101ee86a-7bea-59fb-9f89-6b6297ceed3b
                          2fa8891f-3ece-53a4-adc4-0dd875685f30
      Device Flags:       • Updatable
                          • Supported on remote server
                          • Device can recover flash failures
```

## fwupdmgr --version

```log
nkaminski@nkaminski:~/projects/fwupd/build/src $ ./fwupdmgr  --version
client version: 1.5.5-175-gd6c2fee8
compile-time dependency versions
        gusb:   0.3.6
daemon version: 1.5.5-175-gd6c2fee8
```

## fwupdmgr get-updates

```log
nkaminski@nkaminski:~/projects/fwupd/build/src $ ./fwupdmgr  get-updates
WARNING: This package has not been validated, it may not work properly.
Unknown Product
│
└─ColorHug2:
  │   Device ID:          003dd5443e411c857e1a6220d9b68ee3136661ec
  │   Summary:            An open source display colorimeter
  │   Current version:    2.0.6
  │   Vendor:             Hughski Ltd. (USB:0x273F)
  │   Install Duration:   8 seconds
  │   GUIDs:              2082b5e0-7a64-478a-b1b2-e3404fab6dad
  │                       aa4b4156-9732-55db-9500-bf6388508ee3
  │                       101ee86a-7bea-59fb-9f89-6b6297ceed3b
  │                       2fa8891f-3ece-53a4-adc4-0dd875685f30
  │   Device Flags:       • Updatable
  │                       • Supported on remote server
  │                       • Device can recover flash failures
  │
  └─ColorHug2 Device Update:
    New version:      2.0.7
    Remote ID:        lvfs
    Summary:          Firmware for the Hughski ColorHug2 Colorimeter
    License:          GPL-2.0+
    Size:             16.4 kB
    Created:          2016-12-28
    Urgency:          Medium
    Source:           https://github.com/hughski/colorhug2-firmware
    Vendor:           Hughski Limited
    Duration:         8 seconds
    Flags:            is-upgrade
    Description:
    This release fixes prevents the firmware returning an error when the remote SHA1 hash was never sent.
```

## Summary

If you have any questions, suggestions, or ideas, feel free to share them in
the comment section. If you are interested in similar content, I encourage you
to [sign up for our newsletter](http://eepurl.com/doF8GX).

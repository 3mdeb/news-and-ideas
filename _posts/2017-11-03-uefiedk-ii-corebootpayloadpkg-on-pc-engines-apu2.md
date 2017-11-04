---
ID: 63661
post_title: >
  UEFI/EDK II CorebootPayloadPkg on PC
  Engines apu2
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  http://3mdeb.com/firmware/uefiedk-ii-corebootpayloadpkg-on-pc-engines-apu2/
published: true
post_date: 2017-11-03 00:21:00
tags:
  - coreboot
  - UEFI
  - APU2
  - AMD
categories:
  - Firmware
---
Recently we were reached by person interested in running CoreOS on apu2. CoreOS
is a very interesting system from security point of view. It was created to
support containers and scalability out of the box. Unfortunately it requires firmware
supporting GPT. At that point I was not sure if I can utilize GRUB GPT support
on apu2, but this led to other questions:

- Is it possible to boot UEFI-aware OS on PC Engines apux boards ?
- What level of security can I get with UEFI-aware OS in comparison to coreboot ?

Those questions were much more interesting to firmware developer, because of
that we decided to triage [coreboot UEFI payload](https://github.com/tianocore/tianocore.github.io/wiki/Coreboot_UEFI_payload)
on PC Engines apu2 platform.

For interested ones in that topic I recommend to take look at [video from coreboot conference 2016](https://youtu.be/I08NHJLu6Us?list=PLiWdJ1SEk1_AfMNC6nD_BvUVCIsHq6f0u).

All my modifications of edk2 for the article below can be found in [3mdeb edk2 fork](https://github.com/3mdeb/edk2/tree/apu2-uefi)

For those interested in UEFI-aware OS booting this blog post can be useful, but
I also plan to write something straightforward that can be used and read by
APUx platform users.

**NOTE**: this blog post wait so long for publishing that coreboot community
provided and improved support for tianocore payload. It can be chosen from
`menuconfig` and adds some coreboot specific patches that improve overall
support. Please use option:

```
Payload -&gt; Add a payload -&gt; Tianocore coreboot payload package
```

Manual method still can be useful to try vanilla edk2 and hack with it.

## apu2 firmware with UEFI/EDK2 payload

Let's start with building apu2 mainline. First follow [this instruction](https://github.com/pcengines/release_manifests)
and build mainline version of coreboot. Meanwhile you can take care of EDK2 CorebootPkg build:

```
git clone https://github.com/tianocore/edk2.git
cd edk2
source edksetup.sh
```

On my Debian testing I had to explicitly change compilers to `gcc-5` and `g++-5`:

```
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 10
```

Otherwise build fails. After that I was able to build `UEFIPAYLOAD.fd`:

```
make -c BaseTools
build -a IA32 -p CorebootPayloadPkg/CorebootPayloadPkgIa32.dsc -b DEBUG -t GCC5
```

Build result is located in
`Build/CorebootPayloadPkgIA32/DEBUG_GCC5/FV/UEFIPAYLOAD.fd`. Following [build and integration instructions](https://raw.githubusercontent.com/tianocore/edk2/master/CorebootPayloadPkg/BuildAndIntegrationInstructions.txt)
I added build result as `An ELF executable payload`.

![uefi_payload](http://3mdeb.com/wp-content/uploads/2017/07/uefi_payload.jpeg)

It is important to deselect secondary payloads like `memtest86+` and
`sortbootorder` to avoid compilation issues.

### EDK2 developer's script

For all interested in EDK2 code development I strongly advise to follow [Laszlo's  guide](https://github.com/tianocore/tianocore.github.io/wiki/Laszlo's-unkempt-git-guide-for-edk2-contributors-and-maintainers).

In case of apu2 useful script may be:

```sh
#!/bin/bash
build -a IA32 -p CorebootPayloadPkg/CorebootPayloadPkgIa32.dsc -b DEBUG -t GCC5
cp Build/CorebootPayloadPkgIA32/DEBUG_GCC5/FV/UEFIPAYLOAD.fd ../apu2_fw_rel/apu2/coreboot/
cd ../apu2_fw_rel
./apu2/apu2-documentation/scripts/apu2_fw_rel.sh build-ml
read -n 1 -s -p &quot;Press any key to continue with flashing recent build ...&quot;
./apu2/apu2-documentation/scripts/apu2_fw_rel.sh flash-ml root@192.168.0.105
cd ../edk2
```

## Hacking UEFI payload to boot on apu2

### CbSupportDxe assert

First problem I faced was assert in `CbSupportDxe.c` related to adding 1MB
memory for LAPIC. Reservation happens in CbSupportDxe entry point.

```
Loading driver at 0x000CFC25000 EntryPoint=0x000CFC2595B CbSupportDxe.efi
InstallProtocolInterface: BC62157E-3E33-4FEC-9920-2D3B36D750DF CFC42190
ProtectUefiImageCommon - 0xCFC42928
  - 0x00000000CFC25000 - 0x0000000000002580
PROGRESS CODE: V03040002 I0
Failed to add memory space :0xFEE00000 0x100000

ASSERT_EFI_ERROR (Status = Access Denied)

DXE_ASSERT!: [CbSupportDxe] /home/pietrushnic/storage/wdc/projects/2017/pcengines/apu/src/edk2/CorebootModulePkg/CbSupportDxe/CbSupportDxe.c (57): !EFI_ERROR (Status)
```

Interestingly CbSupportDxe seems to not have problem with finding GUID HOB,
which is right after asserting reservation. It also passes installation of ACPI
and SMBIOS table. I just commented that reservation and moved forward to see
what will happen.

### PcRtcEntry assert

Next problem happens during initialization of RTC:

```
Loading driver at 0x000CFE50000 EntryPoint=0x000CFE507DB PcRtc.efi
InstallProtocolInterface: BC62157E-3E33-4FEC-9920-2D3B36D750DF CFC2AE90
ProtectUefiImageCommon - 0xCFC2AB28
  - 0x00000000CFE50000 - 0x0000000000003980
  PROGRESS CODE: V03040002 I0
  ASSERT_EFI_ERROR (Status = Device Error)

  DXE_ASSERT!: [PcRtc] /home/pietrushnic/storage/wdc/projects/2017/pcengines/apu/src/edk2/PcAtChipsetPkg/PcatRealTimeClockRuntimeDxe/PcRtcEntry.c (143): !EFI_ERROR (Status)
```

Unfortunately Real Time Clock is required architecture protocol and cannot be
omitted.

First problem with this code was an incorrect state of `Valid RAM and Time` (`VRT`) bit in
RTC Date Alarm register (aka Register D).

By checking AMD Bios and Kernel Developer's Guide (BKDG) I was not able to find issue with RTC. Reading all registers was
done correctly and register layout seemed to be standardized for RTC devices.

I faced one very strange situation after leaving apu2 for a night. First boot
passed through above assert and finished booting much further (in BDS).
This was very suspicious like timing or HW initialization issue. Final log
looked like that:

```
[Bds]=============Begin Load Options Dumping ...=============
  Driver Options:
  SysPrep Options:
  Boot Options:
    Boot0000: UiApp              0x0109
    Boot0001: UEFI Shell                 0x0001
  PlatformRecovery Options:
    PlatformRecovery0000: Default PlatformRecovery               0x0001
[Bds]=============End Load Options Dumping=============
[Bds]BdsWait ...Zzzzzzzzzzzz...
[Bds]BdsWait(3)..Zzzz...
[Bds]BdsWait(2)..Zzzz...
[Bds]BdsWait(1)..Zzzz...
[Bds]Exit the waiting!
PROGRESS CODE: V03051007 I0
[Bds]Stop Hotkey Service!
[Bds]UnregisterKeyNotify: 000C/0000 Success
[Bds]UnregisterKeyNotify: 0002/0000 Success
[Bds]UnregisterKeyNotify: 0000/000D Success
Enable SCI bit at 0x804 before boot
PROGRESS CODE: V03051001 I0
Memory  Previous  Current    Next
 Type    Pages     Pages     Pages
======  ========  ========  ========
  09    00000008  00000000  00000008
  0A    00000004  00000000  00000004
  00    00000004  00000001  00000004
  06    000000C0  0000002E  000000C0
  05    00000080  0000001A  00000080
[Bds]Booting UEFI Shell
[Bds] Expand MemoryMapped(0xB,0x830000,0xC0FFFF)/FvFile(C57AD6B7-0515-40A8-9D21-551652854E37) -&gt; MemoryMapped(0xB,0x830000,0xC0FFFF)/FvFile(C57AD6B7-0515-40A8-9D21-551652854E37)
PROGRESS CODE: V03058000 I0
InstallProtocolInterface: 5B1B31A1-9562-11D2-8E3F-00A0C969723B CF954D28
Loading driver at 0x000CF6B8000 EntryPoint=0x000CF718BC1
InstallProtocolInterface: BC62157E-3E33-4FEC-9920-2D3B36D750DF CF96E590
ProtectUefiImageCommon - 0xCF954D28
  - 0x00000000CF6B8000 - 0x00000000000A6FA0
PROGRESS CODE: V03058001 I0
InstallProtocolInterface: 47C7B221-C42A-11D2-8E57-00A0C969723B CF6BCA38
InstallProtocolInterface: 47C7B223-C42A-11D2-8E57-00A0C969723B CF945410
```

In debug logs there was nothing suspicious. Apparently register D of RTC
returned correct value in `VRT` register.

Finally it turned out that `VRT` was incorrectly described in datasheet as
read-only. Register D initialization function caused setting `VRT` bit to 0
what further led to `Device Error` assert. I fixed that problem by removing
initialization from `PcRtcInit`.

### Random unexpected behaviors

One of other behaviors worth to note was unexpected coreboot reset after applying
power:

```
PCEngines apu2
coreboot build 06/30/2017
BIOS version v4.5.8
PCEngines apu2
coreboot build 06/30/2017
BIOS version v4.5.8
4080 MB ECC DRAM

PROGRESS CODE: V03020003 I0
Loading PEIM at 0x000008143C0 EntryPoint=0x00000814600 CbSupportPeim.efi
PROGRESS CODE: V03020002 I0
```

## Booting to UEFI Shell on apu2

I had "freeze" after:

```
InstallProtocolInterface: 47C7B221-C42A-11D2-8E57-00A0C969723B CF6BCA38
InstallProtocolInterface: 47C7B223-C42A-11D2-8E57-00A0C969723B CF945410
```

First is `gEfiShellEnvironment2Guid` and second `gEfiShellInterfaceGuid`, so I
decided to take a look where those GUIDs are used and hook there to see what
may be wrong. After poking around I realized that those came from binary
included in repository. What is included can be modified by changing
`SHELL_TYPE` variable.

When using `BUILD_SHELL` I see little bit different output:

```
InstallProtocolInterface: 387477C2-69C7-11D2-8E39-00A0C969723B CF8DEBA0
InstallProtocolInterface: 752F3136-4E16-4FDC-A22A-E5F46812F4CA CF8DDF98
InstallProtocolInterface: 6302D008-7F9B-4F30-87AC-60C9FEF5DA4E CF5D9800
```

Control is passed in BDS code by calling `StartImage`.

For some reason I couldn't print my logs to `debug by printk`. I verified that
I'm in correct code by placing assert, code was interrupted in correct place
but not serial log.

Trying to change `DebugLib` and provide correct `SerialIoLib` led to reboot.

I fixed that by removing `DebugLib` from libraries section in Ia32X64 DSC:

```
diff --git a/CorebootPayloadPkg/CorebootPayloadPkgIa32X64.dsc b/CorebootPayloadPkg/CorebootPayloadPkgIa32X64.dsc
index 27aba9f59cc9..262ba2b345af 100644
--- a/CorebootPayloadPkg/CorebootPayloadPkgIa32X64.dsc
+++ b/CorebootPayloadPkg/CorebootPayloadPkgIa32X64.dsc
@@ -565,7 +565,6 @@ [Components.X64]
     #------------------------------
 
     &lt;LibraryClasses&gt;
-      DebugLib|MdePkg/Library/UefiDebugLibConOut/UefiDebugLibConOut.inf
       DevicePathLib|MdePkg/Library/UefiDevicePathLib/UefiDevicePathLib.inf
       FileHandleLib|MdePkg/Library/UefiFileHandleLib/UefiFileHandleLib.inf
       HandleParsingLib|ShellPkg/Library/UefiHandleParsingLib/UefiHandleParsingLib.inf
```

However this showed me hang in `DoShellPrompt` on function code:

```
ShellInfoObject.NewEfiShellProtocol-&gt;ReadFile(...)
```

I could not see the prompt and type any input commands.

### Explaining ConIn, ConOut and ErrOut

Big kudos to Laszlo Ersek who is well known from creating and maintaining OVMF.
He pointed me to code in `ArmVirtPkg` where workaround for my problem was
implemented.

I read through code from `ArmVirtPkg/Library/PlatformBootManagerLib/PlatformBm.c` 
and meant that I have to modify `ConIn`, `ConOut` and `ErrOut` variables. It
was because those variables miss device path to UART device.

`ConIn`, `ConOut` and `ErrOut` are global variables defined in UEFI spec. Those
variables are available in boot time, runtime and are non volatile. This means
that those variables are available during boot phase before firmware calls
ExitBootServices and after that during system runtime. Those variables can be
changed, but change takes effect after boot. So in short those variables define
where we can find input, output and std error device.

As described in [mailing thread](https://lists.01.org/pipermail/edk2-devel/2017-July/012352.html) serial
port can be reached through `SerialPortLib` API and it worked for me during
boot phase. Precisely what worked for me was `BaseSerialPortLib16550`. I assume
methods in this library are not available in runtime and that's why switching
to Shell caused no output. Second method is through `EfiSimpleTextOutProtocol`.
Full explanation can be found in mentioned thread, but in short it is required
to add device path of UART to mentioned global variables so those can be used.

My understanding of stack is:

```
|- ShellPkg/Application/Shell/Shell.inf
|- MdeModulePkg/Universal/Console/TerminalDxe/TerminalDxe.inf
|- MdeModulePkg/Universal/SerialDxe/SerialDxe.inf
|-&gt;SerialPortLib|CorebootModulePkg/Library/BaseSerialPortLib16550/BaseSerialPortLib16550.inf
```

`BaseSerialPortLib16550` works on I/O and MMIO level to initialize and provide
read/write capability for 16550 compatible UART device. This lib is utilized
by `SerialDxe` DXE driver. `SerialDxe` produce `gEfiSerialIoProtocolGuid` and
`gEfiDevicePathProtocolGuid`. First abstracts any type of I/O device and
provide communication capability for it. Second gives ability of provides
information about generic path/location information of physical or logical
device (more information in UEFI spec). `gEfiSerialIoProtocolGuid` is consumed
by `TerminalDxe` UEFI driver, which is responsible for producing Simple Text
Input and Output protocols on top of Serial IO protocol. Those protocols give
API like `ReadKeyStroke`, `WaitForKey`, `OutputString`, `ClearScreen`,
`SetCursorPosition` and other that help in handling input and output data.
Those protocols then can be used by Shell application to provide interactive
experience.

## Source code

As I mentioned at beginning code is available on [3mdeb git repo](https://github.com/3mdeb/edk2/tree/apu2-uefi). With it you can build
coreboot.rom that boots to UEFI Shell. There are plenty things to do i.e. `map`
and probably other commands do not work properly. Feel free to contribute.

## Summary

Above steps gave me ability to enable UEFI payload on top of coreboot firmware.
This configuration seems to heavily use AGESA, which is a very similar to Intel
FSP being responsible for big part of hardware initialization as well as
exposing artifacts for UEFI-aware payload, bootloader and operating system.

This blog post can open possibilities to boot UEFI-aware OSes on PC Engines
apu2 platform as well as give ability to research AGESA firmware more
extensively.

If you are interested in enabling UEFI-aware operating system on your platform
that already support coreboot do not hesitate to contact us. If you have any
other questions or comments post those below.
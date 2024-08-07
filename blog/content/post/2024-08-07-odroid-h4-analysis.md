---
title: ODROID H4+ - schematics and logs analysis
abstract: "Now that first steps are already behind us, time for more advanced
           aspects of porting new hardware to open-source firmware. On the
           example of Hardkernel ODROID H4+ the post will introduce you to
           schematics and system logs analysis useful for porting new platform
           to coreboot. Enjoy!"
cover: /covers/image-file.png
author: michal.zygowski
layout: post
published: true
date: 2024-08-07
archives: "2024"

tags:
 - Odroid
 - coreboot
 - firmware
categories:
 - Firmware

---

## Introduction

We recently stumbled upon this interesting piece of hardware from
[Hardkernel](https://www.hardkernel.com/), the [ODROID
H4+](https://www.hardkernel.com/shop/odroid-h4-plus/). It is a nice, compact ,
low-power board with Alder Lake-N SoC. Most importantly, with [public
schematics](https://wiki.odroid.com/_media/odroid-h4/hardware/adln-h4_sch_2024-0306.pdf)!
In this blog post, we will go through each page of the schematics to extract
important information and also look into the system logs from Hardware
Compatibility List (HCL) Report we have made in the [last
post](https://blog.3mdeb.com/2024/2024-07-25-odroid-h4-getting-started/). By
the way, I you haven't read it yet, I encourage you to do so.

## Schematics analysis

Having a public schematics is quite a rarity nowadays. But thanks to
Hardkernel I have an opportunity to openly explain the mysteries of x86
platform design from firmware developer's perspective. So, without further
ado, let's get to the fun part.

After skipping the title page for obvious reasons, the second page represent
the block diagram of the system. It usually does not contain very detailed
information required for firmware porting, just a quick good overview of what
is connected to the SoC/CPU/chipset. So, we will skip that as well. On the
third page we have a table of contents, which is useful to quickly navigate to
the page containing a section we want to find. But at this point, we want to
go through whole schematics, so skip. From now on takes notes what we discover
in the subsequent pages of the schematics.

The fourth page is the first one with something that is interesting for us.
The display lines and Type-C Thunderbolt signals.

![ODROID DDI](/img/odroid/odroid_sch_ddi1.png)

In the above picture we can see that there are two used ports from internal
graphics:

- Port A (`DDIA_*`)
- Port B (`DDIB_*`)

Each of them has An accompanying pair of `DDC_*` (Display Data Channel)
signals and a `HPD` (Hot Plug Detect). DDC is nothing else than I2C to
communicate with displays, read EDID, etc. HPD is rather self explanatory.
Similar lines are used with the Type-C port (`TCP0_*`). The `DDC_*` signals
are coming from GPIOs `GPP_E18` and `GPP_E19`. It is worth taking a note when
we will get to the actual coding.

To verify whether these display lines are really used, check the page that is
written as a number in the square brackets near the `[18] DDI0_TXP3`, the
`[19] DDI1_TXP3` and the `TCP0_3P [20]`. On the page 18 we can see the port A
signals really lead to the HDMI connector:

![ODROID HDMI](/img/odroid/odroid_sch_hdmi1.png)

Besides the HDMI connector, there is also a chip `PS8409A`:

![ODROID HDMI Retimer](/img/odroid/odroid_sch_hdmi2.png)

if you are curious what it is, search it up in the internet. You should be
able to quickly [find it](https://www.paradetech.com/products/ps8409a/). So,
basically it is a HDMI™ 2.0 Jitter Cleaning Repeater / Retimer, which is not
of much importance to us.

Respectively on page 19 the port B signals lead to the Display Port connector:

![ODROID DP1](/img/odroid/odroid_sch_dp1.png)

From the caption `DP_HDMI_CONN1A` we should know it is the Display Port
coupled together with the HDMI connector, which had a similar caption
`DP_HDMI_CONN1B`.

On the page 20 we can see that the Type-C port signals lead to another Display
Port:

![ODROID DP2](/img/odroid/odroid_sch_dp2.png)

It means there will be no USB-C Thunderbolt functionality (no USB, PCIe and DP
in one USB-C receptacle), just a pure Display Port mode.

Let's go back to the page 4 and analyze the rest of its contents. There is a
small block worth our attention:

![ODROID DDI2](/img/odroid/odroid_sch_ddi1.png)

From this fragment we can deduct the following:

- GPIOs: H0, H1, H2, B3, B4, E3, E7, F7 and F10 are not used, and should be
  not connected in the code.
- GPIO B14 is used as a SATA LED

On page 5 we have the RAM memory signals which lead to page 12. On page 12 we
may find the connector for the DDR5 SODIMM slot as the main caption on top of
the page says. And that's all we have to know about the memory in this design.
It is only a single slot (there are no more slots on ODROID board and Alder
Lake N memory controller supports only one DDR4/DDR5 DIMM - see [section 16 of
Alder Lake-N
datasheet](https://www.intel.com/content/www/us/en/content-details/759603/intel-processor-and-intel-core-i3-n-series-datasheet-volume-1-of-2.html)).

On page 6 we have SPI/ESPI/SMBUS block:

![ODROID SPI](/img/odroid/odroid_sch_spi.png)

We can see that SPI0 (the BIOS SPI interface), ESPi and SMBUS are used.
SMLinks (`SML*`), Touch Controller SPIs (THC*) are not used (no page
references in the square brackets), so their GPIOs should also be not
connected in the code. The SPI BIOS interface leads to the two BIOS SPI chips
we talked in the last blog post:

![ODROID BIOS SPI](/img/odroid/odroid_sch_spi2.png)

The `BIOS2_EN` header controls which chip is active at a time by shorting the
chip's `HOLD#` signal to ground. We also have `ESPI_DEBUG1` connector, for
debugging purposes, however tools for accessing ESPI bus are rather rare, so
it is not important for us.

In the middle of the page we also have a block of LPSS UARTs and I2Cs:

![ODROID LPSS](/img/odroid/odroid_sch_lpss.png)

What is worth noting in this block:

- I2C0 and I2C1 are used (reference on page 39)
- GPIO `GPP_B8` is an input to detect the eMMC presence (reference to page 15)

Let's confirm what is really the usage of these pins (sometimes schematics may
have some copy-pasta leftovers and signals references with a page number are
actually not connected). So let's go to page 15 first:

![ODROID EMMC](/img/odroid/odroid_sch_emmc1.png)

AS suspected we have our eMMC module connector, whethere the `EMMC_DET#`
signal is routed to said connector. Judging by the notation of `EMMC_DET#_L`
and `EMMC_DET#`, it is an active low signal (`#` and `_L` suffixes mean that
signal is asserted when shorted to ground). Which means when the module is
plugged, this signal is shorted to ground. BIOS can read GPIO `GPP_B8` at POST
to decide whether the eMMC module is connected and should enable EMMC
controller.

Now let's check page 39 with I2Cs:

![ODROID EXTHEAD I2C](/img/odroid/odroid_sch_exthead.png)

We can see the I2C signals are routed to our 24-pin extension header.
Conclusion: these are general purpose I2C ports for free use. It means we will
enable it permanently in our firmware later on.

Next page on our radar, page 7 contains the EMMC block (which we already know
it routes to EMMC connector, because it references page 15), High Speed I/O
block (USB, SATA, PCIe), audio block and a Camera / CNVi(Connectivity, WiFi)
block. The last one has no pins connected, so all GPIOs in this bock should be
not connected in the code:

![ODROID CNVI](/img/odroid/odroid_sch_cnvi.png)

So we know that CNVi and Camera are not used. Next one is audio:

![ODROID Audio](/img/odroid/odroid_sch_audio.png)

We have only the standard Azalia HD Audio lines routed here, the other ones
(SoundWire, I2S, DMIC) are not routed, so respective GPIOs shall be not
connected in the code. As the HD AUdio liens are routed to page 13, there must
be some codec chip there:

![ODROID CODEC](/img/odroid/odroid_sch_codec.png)

And bingo! An ALC897, which makes our microphone and speaker jack working. We
will get necessary configuratio nfor this coded from system logs, for now we
take a note that there is am external codec on HD Audio bus.

Going back to page 7, we still have High Speed I/O block to analyze:

![ODROID HSIO](/img/odroid/odroid_sch_hsio.png)

This is pretty important, because it is the main I/O block in the system,
where we connect storage, input devices and extension cards (GPUs, WiFis,
Ethernet, etc.). So let's go through each connected signal:

- PCIe root port 9 to 12 is a 4x link for NVMe disk in M.2 slot (page 23)
- PCIe root port 7 expands our board with 4x SATA signals (probably through a
  PCIe to SATA chip, on page 37)
- PCIe root port 3 and 4 are used for LAN/Ethernet (page 21 and 22)
- PCIe root port 1 and 2 are configured for USB 3.x ports (page 16)
- USB2 port 1 through 7 are used (pages 16, 17, and 39, the USB2 port2 also
  has a reference page, but somehow it got blown away to the left)

Let's go through all the referenced pages to verify whether these signals are
really used. Page 23, NVMe:

![ODROID NVME](/img/odroid/odroid_sch_nvme.png)

Without doubt, it is a 4x PCIe NVMe slot. It is also worth taking a note which
PCIe clock and clock request is routed. In this case it is `PCIE_CLKOUT0_*`
(PCIe clock 0) and `PCIE_CLKREQ0_N` (PCIe clock request 0). We will cross
check it with PCIe clock block in a while. We also see there is a `SSD_LED#`
pin connected on page 25 (we will take a look later), `PCIRST1#_SIO` connected
on multiple pages (`SIO` means it is probably connected to Super I/O chip,
which controls resetting of the PCIe devices when whole platform is reset, we
will also get back to it later), `M.2_SSD_PEDET_R` signal routed to page 8
(responsible for selecting between SATA and PCIe, in case SATA SSD in M.2 slot
is plugged) and a mysterious `CPU_GPP_E16` to `NC#67` on the M.2 connector
(not sure what it is used for yet).

Next is page 37 with the PCIe to SATA chip:

![ODROID ASMEDIA](/img/odroid/odroid_sch_asmedia.png)

And, as predicted, we have an ASMedia PCIe to SATA expander chip. Remember to
take not on each PCIe device which clock and clock request signals are used.
So for this device we have a `PCIE_CLKOUT3_*` (PCIe clock 3) and unfortunately
no clock request (`CLKREQN_64A` is routed to a testpoint).

Next we have the pages 21 and 22 with Ethernet ports:

![ODROID LAN1](/img/odroid/odroid_sch_lan1.png)
![ODROID LAN2](/img/odroid/odroid_sch_lan2.png)

And as usual, let's note the PCIe clock and clock request signals for each of
these:

- LAN1 (PCIe root port 3):
  - `LAN1_CLK0_*` (we will have to decipher which clock it is on page 8 later)
  - `PCIE_CLKREQ1_N` (clock request 1)
- LAN2 (PCIe root port 3)
  - `LAN2_CLK*` (we will have to decipher which clock it is on page 8 later)
  - `PCIE_CLKREQ2_N` (clock request 2)

We see these are Intel i226 Ethernet controllers. Additionally we have a
`PCIE_WAKE#` signal connected (so Wake-on-LAN will be possible here), the
`PCIRST1#_SIO` from Super I/O and a `LAN_DISABLE#` (watch out the typo on the
schematics) connected to GPIO `GPP_A8`. Software/BIOS may probably use it to
disable wired networking.

> Speaking of typos, have you noticed whom the design was made for?
> `HARDKNERNAL` &#128514;

At last the pages 16, 17 and 39 with USB ports. Let's see what we have here on
page 16:

![ODROID USB3](/img/odroid/odroid_sch_usb1.png)

- USB3 port 1 paired with USB2 port 1 in Type-A connector
- USB3 port 2 paired with USB2 port 2 in Type-A connector

But what's this? There seem to be some switches which can cut off the power
from USB ports depending on the `USB3_EN` signal state. It is crucial for
noting. If we miss this fact when coding USB port enabling code, we may end up
in the devices not being detected in those ports. The `USB3_EN` signal leads
to page 24, we will take a look at it later. Now let's see page 17:

![ODROID USB2](/img/odroid/odroid_sch_usb2.png)

- USB2 port 5 in Type-A connector
- USB2 port 7 in Type-A connector

And yet another signal to control power in these USB ports, the `USB2_EN`,
also routed to page 24. ANd last but not least, the page 39. We already
visited this page, and it is our 24-pin extension header:

![ODROID USB EXTHEAD](/img/odroid/odroid_sch_usb3.png)

Conclusion: USB2 port 3, 4 and 6 are general purpose ports for free use.

Now that we have went through all of the contents of page 7 (and related
pages), time to go to page 8 with PCIe clock block and system power management
block. Let's start with PCIe clocks:

![ODROID PCIe clocks](/img/odroid/odroid_sch_pcie_clk.png)

Now we can decipher the LAN clock request:

- `LAN1_CLK0*` is really the clock request 1 signal (`CLKOUT_PCIE_*1`)
- `LAN2_CLK*` is really the clock request 2 signal (`CLKOUT_PCIE_*2`)

We also see all the clock requests we previously discovered. But there is one
clock request, that is permanently grounded, the `SRCCLKREQ3#` (although I am
not 100% sure, because there is a dummy resistor between the pin and ground).
I suspect it was supposed to be the clock request signal for ASMedia chip
(remember the clock request connected to a test point?). If it is grounded, it
means it is supposed to be active all the time (which is also fine for
on-board chips and devices, i.e. they are always present). We also have a
couple of GPIOs here:

- `M.2_SSD_PEDET_R` connected to `GPP_A12/SATAXPCIE1/SATAGP1` (most likely it
  will be `SATAXPCIE1` pin function to switch between SATA and PCIe NVMe
  disks, like I said earlier)
- the mysterious `CPU_GPP_E16`
- `CPU_GPP_A8` aka `LAN_DISABLE#`
- GPIOs E0, H19, H23, A7 and E15 not connected

Below the PCIe clock block we have system power management block:

![ODROID power management](/img/odroid/odroid_sch_pwrmgt.png)

From this fragment we may only note which GPIOs and signals are used and which
not. Unused GPIOs are: GPD10, GPD6, GPD9, B12, GPD2, GPD7, GPD11, H3 and E8.
Optionally GPD10, GPD6, GPD9 and B12 may be programmed to their native
functions, because they are routed to the test points. It can be useful to
debug power state transitions using a multimeter for example.

On page 9 we have nothing interesting for use. Similarly on page 10, except
for a few GPIOs:

- `GPP_B2/VRALERT#` - better leave it as connected, `VRALERT#` is important
  from power supply perspective
- `GPP_B0` and `GPP_B1` are the SVID bus for communication with CPU voltage
  regulator
- GPIO F22 and F23 are not connected

Page 11 is just the chip grounding. The next page we haven't yet looked at is
page 24. We already saw a few references to it, so let's demystify them.

![ODROID SIO1](/img/odroid/odroid_sch_sio1.png)

And as suspected earlier by `PCIRST1#_SIO` signal, it is a Super I/O chip from
ITE Tech., the IT8613. Luckily, it is already [supported in
coreboot](https://github.com/coreboot/coreboot/tree/master/src/superio/ite/it8613e)
so we will have much less work to do when porting. The only referenced pins on
the SIO block are ESPI signals and `PM_PLTRST_N` (platform reset). but it
doesn't mean they are not used. If there is no reference to another page, it
may mean the signal is on the same page. And this is the case here. For
example, let's see the USB power signals we mentioned earlier (see left bottom
corner of the schematics page):

![ODROID SIO2](/img/odroid/odroid_sch_sio2.png)

Now we finally see what controls the USB port power, these are `SIO_GP21` and
`SIO_GP23` connected to IT8613. So our firmware will have to drive these GPIOs
to get USB devices powered in the USB slots. This is actually convenient,
because we may control whether the USB wake should work in platform is powered
off and we may also control the power consumption if we cut off the USB port
power before putting the board to sleep state. Speaking of power management,
on the left side of the page we have many signals related to resets and power
management:

![ODROID SIO3](/img/odroid/odroid_sch_sio3.png)

Super I/O chips often assist in the power sequencing of x86 machines, i.e.
help driving the power signals in the correct order and timing to start the
CPU and chipset properly. For example, the `SIO_PSW#` is routed to page 25,
where power button is located:

![ODROID buttons](/img/odroid/odroid_sch_buttons.png)

On the right side of the page 24 we have a connections of Super I/O chip pins
to the rest of the system with page references. This is where we can decode
what is connected and where:

![ODROID SIO4](/img/odroid/odroid_sch_sio4.png)

Here we can see that we have an UART connected to page 39, which we saw
earlier connects to the 24-pin extension header (it will be very useful for
debugging and console, I already mentioned it in the previous post). There are
also hardware monitoring signals, like voltages (`VIN*`), `PECI` (one wire
signal from CPU to read its temperature) and even some fan. The fan PWM
(`FANOUT0`) and tachometer (`FANTACH0`) are routed to page 25, where we can
find the CPU fan connector:

![ODROID FAN and LEDs](/img/odroid/odroid_sch_fan_led.png)

And besides the fan we also have the LEDs indicating disk activity:

- yellow for `SATA_LED#` signal from PCH and 4 SATA ports from ASMedia chip
  (`LED_S*_64A`)
- green for M.2 disk activity

From page 26 to page 36 are power delivery circuits, which are not important
from firmware development perspective, so I will skip these. Page 38 contains
the 4 SATA port connectors from ASMedia chip with their power connectors.
Not much to explain. On page 39 we haven't covered yet the `HDMI_CEC` signal:

![ODROID HDMI CEC](/img/odroid/odroid_sch_hdmi_cec.png)

The `HDMI_CEC` signal connects the 24-pin extension header with HDMI CEC
signal in the HDMI connector itself. CEC (Consumer Electronics Control) signal
is used for remote control of devices connected by HDMI. It is a single wire
bidirectional serial bus, so it would have to be driven by some
microcontroller implementing CEC protocol. Just for your information.

Page 40 contains an empty change list, so this concludes our schematics
analysis. Hope you were taking notes, because those will be crucial when it
comes to porting open-source firmware for that platform. Now we can go through
the system logs from HCL Report.

### HCL Report log analysis

HCL Report is useful in many ways. In this section I will explain why. Among
other things, the HCL Report gathers system logs as well as does the firmware
image backup (if the chipset is supported by flashrom utility, which is used
to read the flash). Backup is always good, because we may need to extract some
blobs from it, like:

- Management Engine
- Flash Descriptor
- Video BIOS Tables (for graphics initialization)

But from system logs, we may extract helpful information for firmware porting.
I will now explain what each file contains and how it may be used. So let's
take a look at our dump ([here is a link if you would like to follow what I am
doing](https://cloud.3mdeb.com/index.php/s/f4fkdWsPQ3TR6PN)):

- `acpi` directory and `acpidump` - contains all ACPI table extracted from
  system running on original firmware, sometimes very useful to check how
  certain board specific things were described in ACPI. There is a lot of text
  to parse here, so we won't go through it. For simple boards like ODROID, it
  is probably not necessary to look into ACPI.
- `amt-check` - for security and privacy-conscious people, who dislike AMT,
  spying etc. These files provides only information about AMT and are not used
  for porting.
- `biosdecode` - biosdecode parses the BIOS memory and prints information
  about all structures (or entry points) it knows of. THere is not much it can
  extract from UEFI BIOS, it probably would work on legacy BIOSes. Currently
  useless.
- `cbmem` - these are only useful if you run coreboot already.
- `codec*/pin_hw*` - these are very useful to extract the codec configuration.
  Unfortunately DTS does not have drivers for all possible codecs, so these
  logs are often empty. One may read the codec information from sysfs when
  running a live Ubuntu. I will show you how it is done when we get to the
  coding phase.
- `cpuinfo` - just the contents of `/proc/cpuinfo`, useful to get the
  information about the processor you have and its features
- `decode-dimms` - extract information about DRAM modules from their SPD
  memory. Unfortunately the utility does not support DDR5 SPD yet, thus it
  could not parse anything.
- `dmesg` - very useful to locate some errors or any other information about
  the system, enabled features, etc. If I have already a bootable Linux with
  open-source firmware, I compare the dmesg and check for some problems or
  differences.
- `dmidecode` - very important. Contains parsed SMBIOS structures. This is
  where we will take the system strings and put them into open-source firmware.
  I will elaborate on it a little bit later.
- `ectool` - utility which interacts with Embedded Controller and reads it
  memory. Rather useful on laptops, but not here. There is no Embedded
  Controller on ODROID.
- `flashrom/rom.bin` - logs from flashrom process reading the flash chip, if
  something goes wrong, e.g. `rom.bin` is missing, the log will tell you what
  failed
- `inteltool/intelp2m/gpio*.h` - these files are the results of running
  coreboot utilities: `inteltool` and `intelp2m`. The `gpio*.h` files are
  ready-to-include source files containing macros for GPIO initialization.
  Very crucial files. I will be elaborating on their verification in later
  section.
- `i2cdetect` - these logs contain possible dumps of I2C devices found on I2C
  buses in the system. There often may be some controllers like Voltage
  Controller, USB-PD, TouchPads, etc. One must know what their address is to
  properly implement support for them.
- `inputbustypes` - these files represent the content of
  `/sys/class/input/input*/id/bustype`. not sure what it is used for. It was
  originally included in [coreboot's mainboard porting
  guide](https://www.coreboot.org/Motherboard_Porting_Guide)
- `intelmetool` - queries information about ME and BootGuard, if ME device is
  supported by the utility, it may give useful information whether Boot Guard
  is fused or not. This coreboot's utility is not updated often and worked
  well on rather older platforms, like 7th gen Intel Core and older.
- `ioports` - very useful to get information about I/O port usage. One may
  find out which port ranges are used and by which devices, for example, which
  I/O port ranges are used by Super I/O.
- `lspci` - also very useful file containing a complete dump of PCI
  configuration space of the system. I often used it to compare the PCI/PCIe
  capabilities of devices, differences in PCI configuration space to look for
  mistakes in open-source firmware settings for PCIe initialization or simply
  to get the PCI Subsystem IDs used by the platforms.
- `lsusb` - useful to map the USB ports, plugged and on-board devices. WHen
  you don't have the schematics invoking `usb -t` and plugging devices in all
  ports helps to map the used USB ports. But we have a schematics here, so it
  usefulness is not that big.
- `msrtool` - another coreboot's utility which was implemented for older
  platforms, for modern ones it does not dump anything. Rather unmaintained.
- `nvramtool` - dumps the CMOS NVRAM space and can modify the CMOS NVRAM
  options if CMOS option backed is enabled in coreboot. Sometimes it may be
  useful if the firmware stores some information in CMOS. Dumping it across
  boots may reveal some BIOS implementation details.
- `result` - a file with results of dumping each information type from the
  system, integral part of HCL Report, not used for porting
- `superiotool` - another crucial file. If you system has a Super I/O chip,
  like ODROID, it dumps the configuration registers of said chip. If you don;t
  have schematics for the platform, you are probably doomed without the log
  from superiotool.
- `touchpad` - it is a result of a
  [script](https://github.com/Dasharo/meta-dts/blob/main/meta-dts-distro/recipes-dts/reports/touchpad-info/touchpad-info),
  which tries to probe information about touchpads connected to I2C. Rather
  useful on laptops, not board like ODROID.
- `tpm_version` - contains information about TPM module read from
  `/sys/class/tpm/tpm*`. Tell us if any TPM module is connected/used on the
  board. ODROID has no discrete TPM module, but it can still use fTPM.

I will now go through the most important files and explain why we need it and
how to use it,

### SMBIOS information

TBD

### GPIO configuration

TBD

### Super I/O configuration

TBD

## Summary

Summary of the post.

OPTIONAL ending (may be based on post content):

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help.
[Schedule a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to
[sign up for our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

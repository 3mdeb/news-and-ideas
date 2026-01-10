---
title: Porting Gigabyte MZ33-AR1 server board with AMD Turin CPU to coreboot
abstract: 'The blog post describes effort made to port a modern AMD server
           board to coreboot. The target is Gigabyte MZ33-AR1 supporting
           newest AMD EPYC server processor family Turin and OpenSIL.'
cover: /covers/gigabyte_mz33_ar1.webp
author: michal.zygowski
layout: post
private: false
published: true
date: 2025-08-07
archives: "2025"

tags:
  - coreboot
  - firmware
  - AMD
  - Turin
  - MZ33-AR1
  - open-source
categories:
  - Firmware

---
## Introduction

This blog post describes the progress of the first phase of enabling AMD Turin
support in coreboot and porting Gigabyte MZ33-AR1 board. The project is funded
by [NLnet Foundation](https://nlnet.nl/project/Coreboot-Phoenix/).

The project was inspired by AMD's efforts to bring open-source firmware for
their most recent CPUs. Couple months ago AMD published their CPU
initialization code for AMD Turin server processor family on
[GitHub](https://github.com/openSIL/openSIL/tree/turin_poc). The OpenSIL is a
new initiative to unify the silicon initialization for AMD platform across
multiple firmware frameworks, like EDK2 and coreboot. Following the successful
integration of Genoa (Turin's predecessor) Proof of Concept in coreboot, we
are striving for a brand new Turin processor family.

The first phase of the project consisted of couple milestones:

* Milestone a. Turin PSP firmware package

   Extract APCB from the reference MZ33-AR1 image and add them to mainboard
   code in coreboot. Integrate support for stitching public Turin PSP blobs in
   coreboot.

* Milestone b. Turin SoC skeleton in coreboot

  Create soc/amd/turin_poc in coreboot, port minimal OpenSIL integration and
  make sure the tree compiles.

* Milestone c. MZ33-AR1 mainboard skeleton

  Add mainboard/gigabyte/mz33-ar1, wire it to the new SoC, enable serial
  console, and confirm the bootblock executes on hardware.

Let's run through each of them and explain what was done to fulfill the goals.

## Turin SoC skeleton in coreboot

SoC structure is the base of the "world" for building coreboot images for
board. It binds the mainboard code with silicon specific drivers and glues all
other pieces together. It is usually necessary to have a separate `soc`
directory with relevant source for each new microarchitecture/processor
family, as the differences between them may be too significant for reuse.

In our case we created the `turin_poc` SoC based on `genoa_poc` SoC, as it is
the closest SoC to Turin (architecture-wise) and it already integrates OpenSIL
drivers. So the easiest way is to simply copy the directory and rename `genoa`
to `turin` everywhere.

The relevant patch can be found [here](https://review.coreboot.org/c/coreboot/+/88707/1).

Before it compiles though, we will need a couple more modifications in other
places and a board target to build it. So let's move forward to the next
relevant patch, which is modification of the SoC structure to reflect the
architectural changes introduce in Turin.

It is not trivial to describe what should be changed and how. One must simply
run through all the source file added in previous patch, all drivers selected
by `src/soc/amd/turin_poc/Kconfig` file and compare it against Processor
Programming Reference from AMD. But let's run through the modification in the
[patch](https://review.coreboot.org/c/coreboot/+/88708/1) and briefly explain it.

1. Turin CPU has less USB ports than Genoa, so the chip structure has to
   reflect that. The number of ports has been reduced to match the hardware
   capabilities.
2. `src/soc/amd/turin_poc/early_fch.c` has been updated to match what other
   AMD SoCs do, e.g. Mendocino or Phoenix. it is very basic chipset
   initialization required for basic operation of coreboot in the very early
   stage. It set's up mostly legacy ISA devices, eSPI, I/O decoding, UARTs,
   SMBus and SPI.
3. Small differences in registers bits for AOAC (Always on Always Connected)
   which are used to enable internal CPU devices not visible on PCI bus.
4. Adjusted MMIO and I/O base addresses for CPU internal devices and ACPI.
   Proper MMIO is required to initialize the hardware properly.
5. `src/soc/amd/turin_poc/root_complex.c` is the file I had most struggles
   with. It describes how PCI domains are laid out on the SoC. I had a long
   chat with Felix Held (fellow coreboot developer), who worked on Genoa POC,
   and helped me understand how the domain map to fabric IDs and the SMN
   (System Management Network) base addresses. As a result of this fruitful
   discussion a [patch](https://review.coreboot.org/c/coreboot/+/88369) has
   been created. Thank you again Felix!
6. `src/soc/amd/turin_poc/chipset.cb` is the second file which gave me some
   trouble. The AMD's Processor Programming Reference (PPR) for Turin is not
   so clear about the layout of the PCI devices. It has an enigmatic table
   describing which device is present on which domain, however these domains
   are divided into A,B,C,D without clear explanation which domain map to
   which IOHC (I/O Hub Controller). After a very long deep dives into PPR and
   `lspci` logs from the actual Gigabyte MZ33-AR1 board, I figured out which
   devices should correspond to which domain.
7. `src/soc/amd/turin_poc/Makefile.mk` is updated to include non-volatile APOB
   (AGESA PSP Output Block) and microcode files in the PSP firmware structure.
   On most recent system microcode is loaded onto the CPU by PSP, so it has to
   be provided in the PSP-understandable way. APOBs are just pointers to the
   flash where the memory training results are stored. It can be used for
   fastboot purposes, like MRC cache on Intel platforms.

Once the SOC tree was ready, it was time to integrate the actual OpenSIL.
Again it was based on the `genoa_poc` OpenSIL driver for easier integration.
Here is the relevant
[patch](https://review.coreboot.org/c/coreboot/+/88711/1). Unfortunately, the
OpenSIL did not build out of the box, so it was necessary to add a fork
temporarily, until the [build
fixes](https://github.com/openSIL/openSIL/pull/26) are merged.

That concludes the effort for creating `soc` structure for Turin processors.

## Turin PSP firmware package

PSP (Platform Security Processor), nowadays known as ASP (AMD Security
Processor) is a privileged coprocessor embedded into AMD CPUs, similar to
Intel's ME in Intel chipsets. It is responsible for early silicon and memory
initialization before the BIOS/firmware runs.

Preparing PSP blobs for AMD platform can be divided into 2 steps:

* mainboard-agnostic blobs, specific for the CPU silicon
* mainboard-specific blobs.

These blobs are consumed by PSP (and other IP blocks) before the main CPU
starts. We will be providing a more detailed analysis of these blobs in
subsequent project phases.

The first group consists of blobs that are delivered by AMD to initialize the
PSP and CPU before the BIOS/firmware kicks in and all boards should include
them. These blobs have been published by AMD too on
[GitHub](https://github.com/openSIL/amd_firmwares/tree/turin_poc/Firmwares/Turin).
So the task is pretty simple, add the repository as a submodule in coreboot,
and hook these blobs into the build system. Here is the
[patch](https://review.coreboot.org/c/coreboot/+/88710/1) that accomplishes
this.

The CPU-specific blobs are included in the build by defining a `fw.cfg` file
and pointing to it with `AMDFW_CONFIG_FILE` Kconfig option. The `fw.cfg` file
is pretty simple, it points to the directory where blobs are located and
defines name of the SoC:

```txt
FIRMWARE_LOCATION          3rdparty/amd_firmwares/Firmwares/Turin
SOC_NAME                   Turin
```

and then lists the file names (second column) to be included under specific
blob type (first column):

```txt
AMD_PUBKEY_FILE            TypeId0x00_AmdPubKey_BRH.tkn
...
```

It is worth noting that Genoa had less blobs than Turin. Some blobs are new
and not yet known to coreboot's utility, `amdfwtool`, that glues them
together. To get all those blobs stitched together, a modification `amdfwtool`
was necessary. The relevant changes can be found in this
[patch](https://review.coreboot.org/c/coreboot/+/88709/1). The patch is still
in work in progress state, because despite including all blobs, the board does
not boot with the image created by coreboot build system. There might be some
new requirements for stitching the PSP blobs for Turin, that was not present
earlier in Genoa. Solving this problem has been planned for the next project
phases.

Next are the board-specific blobs. There aren't many of them, just one type:
APCB (AGESA PSP Configuration Block). APCB blobs are configuration data blobs
for PSP AGESA to configure memory for the board. They are board-specific and
must be prepared for each board separately. They are needed to build a working
coreboot image. The easiest way to obtain them is to extract them from vendor
image. To do so we will need [PSPTool](https://github.com/PSPReverse/PSPTool),
an utility to parse and dump PSP structures in AMD firmware images.

To quickly build the utility simply do:

```bash
git clone https://github.com/PSPReverse/PSPTool
cd PSPTool
git checkout zen5
python3 -m virtualenv venv
source venv/bin/activate
pip install -e .
```

We checking out zen5 branch, because Turin CPU is Zen5 architecture.

To know which blobs we have to extract or take we need to list the entries
present in the images first:

```bash
psptool -E <image>
```

The `<image>` is a firmware dump taken from the board itself or the image
taken from vendor BIOS update. Below process uses [vendors firmware image
R05_F04](https://web.archive.org/web/*/https://download.gigabyte.com/FileList/BIOS/mb_bios_MZ33-AR1_R05_F04.zip?v=d053b6d21709ed9e2b373b304fe820f6)
(not available anymore for download from official website). Once the update
package is downloaded and unzipped, listing the image can be done with

```bash
psptool -E mb_bios_MZ33-AR1_R05_F04/SPI_UPD/image.bin
```

However, this command results in a failure. The current state of PSPTool does
not parse the images properly yet. So to fix the problem, necessary
modifications were made and a [Pull
Request](https://github.com/PSPReverse/PSPTool/pull/67) uploaded. Rebuilding
the utility using the modified code and listing the entries again results in
success. A full output for reference is available
[here](https://paste.dasharo.com/?9377346c575f4f6d#J9fK6Z6HzDvVH3CYheToPTTmvoKCiF2oAxxWpQ81aDVK).

> The linked pull request already fulfills half of work planned for the other
> milestone for this project. That is the `Upstream PSPTool parsing
> improvements` (task 7 milestone B). More changes to PSPTool will follow
> later, that expose even more information about the PSP firmware structures,
> like subprogram and instance fields, which are also useful to determine what
> blobs are applicable for given platform. The improved PSPTool will be also
> included in the Dasharo HCL reports to improve dumping data on AMD platforms
> (task 7 milestone A). We also have another tool incoming, which is similar
> to [coreboot's
> inteltool](https://github.com/coreboot/coreboot/tree/main/util/inteltool),
> that will help dumping AMD CPU registers relevant for coreboot porting (task
> 7, milestones C and D).

The image may have multiple ROMs inside it, 16MB each for modern platforms. Be
careful to take the blobs from the right directory. For example Gigabyte
MZ33-AR1 has a dual ROM with Genoa and Turin firmware:

```txt
+-----+------+-----------+---------+------------------------------+
| ROM | Addr |    Size   |   FET   |            AGESA             |
+-----+------+-----------+---------+------------------------------+
|  0  | 0x0  | 0x1000000 | 0x20000 | AGESA!V9 GenoaPI-SP5 1.0.0.C |
+-----+------+-----------+---------+------------------------------+
...
+-----+-----------+-----------+-----------+------------------------------+
| ROM |    Addr   |    Size   |    FET    |            AGESA             |
+-----+-----------+-----------+-----------+------------------------------+
|  1  | 0x1000000 | 0x1000000 | 0x1020000 | AGESA!V9 TurinPI-SP5 1.0.0.0 |
+-----+-----------+-----------+-----------+------------------------------+
```

Each ROM have two types of directories: PSP and BIOS. E.g.

```txt
+--+-----------+---------+------------+-------+---------------------+
|  | Directory |   Addr  | Generation | Magic | Secondary Directory |
+--+-----------+---------+------------+-------+---------------------+
|  |     0     | 0x41000 |    None    |  $PSP |       0x311000      |
+--+-----------+---------+------------+-------+---------------------+
...
+--+-----------+----------+------------+-------+---------------------+
|  | Directory |   Addr   | Generation | Magic | Secondary Directory |
+--+-----------+----------+------------+-------+---------------------+
|  |     2     | 0x2d1000 |    None    |  $BHD |       0x691000      |
+--+-----------+----------+------------+-------+---------------------+
```

Each of the directory types may have two levels of directories. Second level
directories are marked as `$PL2` and `$BL2`. The main difference is that the
main directories marked as `$PSP` and `$BHD` are considered recovery and have
a limited set of blobs in it. Also the APCB blobs may be configured
differently for recovery and normal boot. That is why it is important to
extract the APCBs from second level directory.

APCB blobs always live in the BIOS directories. For example, if we want to
extract the APCB from Turin image, we will have to look at directory 3 in the
second ROM:

```txt
+-----+-----------+-----------+-----------+------------------------------+
| ROM |    Addr   |    Size   |    FET    |            AGESA             |
+-----+-----------+-----------+-----------+------------------------------+
|  1  | 0x1000000 | 0x1000000 | 0x1020000 | AGESA!V9 TurinPI-SP5 1.0.0.0 |
+-----+-----------+-----------+-----------+------------------------------+
...
+--+-----------+-----------+------------+-------+---------------------+
|  | Directory |    Addr   | Generation | Magic | Secondary Directory |
+--+-----------+-----------+------------+-------+---------------------+
|  |     3     | 0x1662000 |    None    |  $BL2 |                     |
+--+-----------+-----------+------------+-------+---------------------+
+--+---+-------+-----------+----------+----------------------+ ...
|  |   | Entry |   Address |     Size |                 Type | ...
+--+---+-------+-----------+----------+----------------------+ ...
|  |   |     0 | 0x1662400 |   0xb6a6 | EARLY_VGA_IMAGE~0x69 | ...
|  |   |     1 | 0x166db00 |   0x7900 |       APCB_COPY~0x68 | ...
|  |   |     2 | 0x1675400 |    0xcb8 |       APCB_COPY~0x68 | ...
|  |   |     3 | 0x1676100 |    0x5a0 |       APCB_COPY~0x68 | ...
|  |   |     4 | 0x1677000 |   0x1000 |            APCB~0x60 | ...
|  |   |     5 | 0x1678000 |   0x1000 |            APCB~0x60 | ...
|  |   |     6 |       0x0 |      0x0 |            APOB~0x61 | ...
|  |   |     7 | 0x1cc0000 | 0x340000 |                 BIOS | ...
```

We can see that there are 2 APCBs and 3 ACPB_COPY's. We will need all of them.
Since we located the APCBs we want, it is time to extract the blobs. Blobs can
be extracted from the first ROM with the following command:

```bash
psptool -X mb_bios_MZ33-AR1_R05_F04/SPI_UPD/image.bin
```

The command will extract all blobs to the
`mb_bios_MZ33-AR1_R05_F04/SPI_UPD/image.bin_extracted` directory where the
image was located. However, we are interested in the second ROM with Turin
blobs, so we need to pass additional parameter:

```bash
psptool -X -r 1 mb_bios_MZ33-AR1_R05_F04/SPI_UPD/image.bin
```

The files will have a a prefixes consisting of `dXX_eYY` where `XX` is the
directory number in the ROM and `YY` is the entry number in given directory.
So in our case we should look for `d03_e01*` up to `d03_e05*`. And these are
the files we will need when creating mainboard structure:

```txt
d03_e01_APCB_COPY~0x68
d03_e02_APCB_COPY~0x68
d03_e03_APCB_COPY~0x68
d03_e04_APCB~0x60
d03_e05_APCB~0x60
```

This concludes the PSP firmware package milestone.

## MZ33-AR1 mainboard skeleton

Finally it is time for the last piece of the puzzle, the mainboard code. We
only want the minimum required to run bootblock and have some signs of life on
the serial console. The servers board often have the serial port exposed over
network via BMC Serial over LAN (SOL) feature and sometimes as a physical DB9
connector for RS232 on rear panel.

But, let's go back to the main topic. The patch adding initial board support
can be found [here](https://review.coreboot.org/c/coreboot/+/88712/2). The
current board's code consists of a couple source files:

* Kconfigs (with the name and configuration options)
* `Makefile.mk` which adds mainboard source file to be compiled
* `bootblock.c` the early board specific code that sets up the debug interface
* `mainboard.c` mainboard code for ramstage, currently has only interrupt
  configuration
* `dsdt.asl` from which the DSDT ACPI table is built
* `devicetree.cb` with the devices enabled and used by the board and board's
  configuration
* `*apcb` files, which we extracted just moments ago
* And couple other necessary files not really relevant for this story

The `bootblock.c` is very basic and does the following things:

* Sets up eSPI. eSPI is the interface used to communicate with BMC. It has to
  be configured to route serial port access on port 0x3f8 and the BMC's Super
  I/O on port 0x2e/0x2f. Part of the configuration is done in `devicetree.cb`
  an eSPI interface GPIOs are set in `bootblock.c`.
* Configures BMC serial port. The BMC is AST2600, but the generic AST2050 and
  AST2400 driver will suffice here to set up the serial port for debugging. So
  we simply call the generic function that initialize serial port and that's
  about it.

`mainboard.c` and `dsdt.asl` have pretty much similar content to Genoa POC
reference board, Onyx. not much will happen here, until later phases of the
project. The files add just enough source code to compile.

`devicetree.cb` defines very basic configuration of the board and enables
crucial devices for the early booting phase, mainly the `lpc_bridge` (eSPI)
with the ASPEED BMC Super I/O and TPM. Some additional settings are already
defined as well, like USB, SATA, but they are subject to change in later
phases.

`Makefile.mk` mainly defines the APCB files that are going to be used by the
board. The APCB files should reside in mainboard directory and are defined as
follows:

```Makefile
ifneq ($(wildcard $(src)/mainboard/$(MAINBOARDDIR)/data.apcb),)
APCB_SOURCES = $(src)/mainboard/$(MAINBOARDDIR)/data.apcb
APCB_SOURCES1 = $(src)/mainboard/$(MAINBOARDDIR)/data1.apcb
APCB_SOURCES_RECOVERY = $(src)/mainboard/$(MAINBOARDDIR)/data_rec.apcb
APCB_SOURCES_RECOVERY1 = $(src)/mainboard/$(MAINBOARDDIR)/data_rec1.apcb
APCB_SOURCES_RECOVERY2 = $(src)/mainboard/$(MAINBOARDDIR)/data_rec2.apcb
else
show_notices:: warn_no_apcb
endif
```

The APCB files we extracted earlier map as follows:

* `APCB_SOURCES` - first APCB (type 0x60) from the second level BIOS directory
   with. In our case it will be `d03_e04_APCB~0x60` file.
* `APCB_SOURCES1` - second APCB (type 0x60) from the second level BIOS
  directory. In our case it will be `d03_e05_APCB~0x60` file.
* `APCB_SOURCES_RECOVERY` - first APCB_COPY (type 0x68) from the second level
  BIOS directory. In our case it will be `d03_e01_APCB_COPY~0x68` file.
* `APCB_SOURCES_RECOVERY1` - second APCB_COPY (type 0x68) from the second
  level BIOS directory. In our case it will be `d03_e02_APCB_COPY~0x68` file.
* `APCB_SOURCES_RECOVERY2` - third APCB_COPY (type 0x68) from the second level
  BIOS directory. In our case it will be `d03_e03_APCB_COPY~0x68` file.

They are simply renamed to `*.apcb` files to match the convention used in
coreboot.

The patch also adds a couple of configs to be used to build an image quickly:

* `configs/config.gigabyte_mz33-ar1` regular config file using PSP blobs and
  supposed to produce a full working image
* `configs/config.gigabyte_mz33-ar1_no_psp` - config file not using PSP blobs
  to workaround booting problem when public PSP blobs are used. I will explain
  why we have such config soon.

This concludes the mainboard code milestone. Time to build some images!

## Building and running

To build a bootable coreboot image, we had to go for certain workarounds and
omit stichting PSP blobs. Thankfully, the vendor image copies enough flash to
memory for the BIOS to execute and this flash region is not compressed. Now,
how did we discover it? Again, the PSPTool comes with the help together with
[UEFITool](https://github.com/LongSoft/UEFITool):

```txt
|  |   |     6 |       0x0 |      0x0 |            APOB~0x61 | ...
|  |   |     7 | 0x1cc0000 | 0x340000 |                 BIOS | ...
```

The 7th entry indicates where the early BIOS boot code resides in flash. It
says that it is 0x340000 bytes at offset 0x1cc0000. When the vendor image is
opened in the `UEFITool` we can see that it point to uncompressed SEC and PEI
Firmware Volume:

![img](/img/gigabyte_uefitool.png)

So it means we can inject our coreboot image there. However, to make it work
properly, we will need to peek into the BIOS and APOB (AGESA PSP Output Block)
entry bytes with hex editor to obtain the destination address in DRAM where
the BIOS and APOB contents are copied. APOB is necessary for BIOS to be
consumed and parsed to obtain crucial information about memory configuration
from PSP. A quick peek into the hexdump of the image right at the beginning of
the BIOS directory (`$BL2` marker) from which we extracted the APCBs:

```txt
01662000  24 42 4c 32 c3 cc 8c 73  22 00 00 00 80 05 00 20  |$BL2...s"...... |
01662010  69 00 00 00 a6 b6 00 00  00 24 66 00 00 00 00 00  |i........$f.....|
01662020  ff ff ff ff ff ff ff ff  68 00 00 00 00 79 00 00  |........h....y..|
01662030  00 db 66 00 00 00 00 00  ff ff ff ff ff ff ff ff  |..f.............|
01662040  68 00 80 00 b8 0c 00 00  00 54 67 00 00 00 00 00  |h........Tg.....|
01662050  ff ff ff ff ff ff ff ff  68 00 90 00 a0 05 00 00  |........h.......|
01662060  00 61 67 00 00 00 00 00  ff ff ff ff ff ff ff ff  |.ag.............|
01662070  60 00 00 00 00 10 00 00  00 70 67 00 00 00 00 00  |`........pg.....|
01662080  ff ff ff ff ff ff ff ff  60 00 10 00 00 10 00 00  |........`.......|
01662090  00 80 67 00 00 00 00 00  ff ff ff ff ff ff ff ff  |..g.............|
016620a0  61 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |a...............|
016620b0  00 00 bc 75 00 00 00 00  62 00 03 00 00 00 34 00  |...u....b.....4.|
016620c0  00 00 cc 00 00 00 00 00  00 00 cc 75 00 00 00 00  |...........u....|
016620d0  63 00 00 00 00 00 0d 00  00 90 67 00 00 00 00 00  |c.........g.....|
```

The APOB entry is at offset `0x016620a0` and its destination address at
`0x016620b0` (64bit address) and we see it is equal to `0x75bc0000`. Similarly
for BIOS entry is at offset `0x016620b8`, because each entry is 0x18 bytes and
BIOS is right after APOB. The destination address would the be at offset
`0x016620c8` a is equal to `0x75cc0000`. Having this data we could fabricate
the same memory map for coreboot by defining the following in mainboard's
Kconfig:

```txt
config BUILD_WITHOUT_PSP_BLOBS
 bool "Build without PSP blobs"
 default y
 help
   Build coreboot image without PSP blobs. When selected, the bootblock
   will be put in CBFS as on regular x86 board. The amdfw.rom will not
   be created.

   This is a workaround option for amdfwtool not being able to created
   a working amdfw.rom for this board. Instead, the resulting image
   will be a regular image to be flashed in place of vendor UEFI FVs
   at the last 0x340000 bytes.

if BUILD_WITHOUT_PSP_BLOBS

config BOOTBLOCK_IN_CBFS
 default y

config AMDFW_CONFIG_FILE
 default ""

config CBFS_SIZE
 default 0x340000

# Below addresses match the vendor BIOS R04_F03
# Remove them once the public blobs start working
config EARLY_RESERVED_DRAM_BASE
 default 0x75b90000

config PSP_APOB_DRAM_ADDRESS
 default 0x75bc0000

config PSP_APOB_DRAM_SIZE
 default 0x100000

config ROMSTAGE_ADDR
 default 0x76000000

config ROMSTAGE_SIZE
 default 0x80000

endif
```

When user selects `BUILD_WITHOUT_PSP_BLOBS` option, coreboot will configure
the memory map so that the bootblock is linked at the right address after PSP
copies it to DRAM from flash. `PSP_APOB_DRAM_ADDRESS` is the APOB destination
address. The `PSP_APOB_DRAM_SIZE` is simply the space between BIOS and APOB
destinations: `0x75cc0000 - 0x75bc0000 = 0x100000`. `CBFS_SIZE` must be equal
to the BIOS region in flash that is being copied, so `0x340000`. At last
`ROMSTAGE_ADDR` must be simply the first address after the BIOS flash region
that is copied: `0x75cc0000 + 0x340000 = 0x76000000`.
`EARLY_RESERVED_DRAM_BASE` just needs to be lower then APOB with some space to
fit the CPU stack. A lot of hacking and maths, but it works.

And as a proof, let's built the image without PSP blobs:

```bash
git clone https://review.coreboot.org/coreboot.git
cd coreboot
git fetch https://review.coreboot.org/coreboot refs/changes/12/88712/1 && git checkout FETCH_HEAD
```

Assuming you have docker installed, run the container and start build process:

```bash
docker run --rm -it -v $PWD:/home/coreboot/coreboot \
     -w /home/coreboot/coreboot coreboot/coreboot-sdk:2024-12-21_306660c2de \
     /bin/bash

(docker)$ cp configs/config.gigabyte_mz33-ar1_no_psp .config
(docker)$ make olddefconfig
(docker)$ make
```

The resulting image will be present in `build/coreboot.rom`. To flash it on
the board an external programmer is required. More convenient options are
probably available with BMC, but the methodology was not yet discovered.

Follow the instructions on [Dasharo
documentation](https://docs.dasharo.com/variants/gigabyte_mz33-ar1/recovery/#external-flashing)
to flash the image.

Once flashed, power on the board and observer the serial output. it can be
done with USB to RS232 adapter and a DB9 null modem cable, or the BMC SOL
feature.

Sample output:

```txt
[NOTE ]  coreboot-25.06-332-gddc10428152e Thu Aug 07 11:04:15 UTC 2025 x86_64 bootblock starting
[DEBUG]  Family_Model: 00b00f21
[INFO ]  Set power off after power failure.
[DEBUG]  PMxC0 STATUS: 0x800 BIT11
[DEBUG]  SPI normal read speed: 800 KHz
[DEBUG]  SPI fast read speed: 66.66 Mhz
[DEBUG]  SPI alt read speed: 66.66 Mhz
[DEBUG]  SPI TPM read speed: Invalid
[DEBUG]  SPI100: Disabled
[DEBUG]  SPI Read Mode: Reserved
[DEBUG]  SPI ROM mapping: 3-2-1-0
[ERROR]  Invalid FMAP at 0x1cc0000
[EMERG]  Cannot locate primary CBFS
```

This concludes the first phase of the project.

## Summary

Turin OpenSIL is still in the **Proof of Concept** stage and is **not intended
for production use** - proceed at your own risk. All current patches for Turin
and Gigabyte MZ33-AR1 support are available under the [turin_poc
topic](https://review.coreboot.org/q/topic:turin_poc) topic on coreboot’s
Gerrit. The subsequent phases of the project will bring even more exciting
developments, so stay tuned for updates.

<!-- markdownlint-disable-next-line MD001 -->
#### Acknowledgements

We would like to thank the creators and contributors of
[PSPTool](https://github.com/PSPReverse/PSPTool) and
[UEFITool](https://github.com/LongSoft/UEFITool), whose excellent work played a
key role in achieving the results presented here.

#### Vertical Application Roadmap

We’re also excited to share our longer‑term vision for vertical applications
powered by the Dasharo Pro Package on the Gigabyte MZ33‑AR1 platform. As
previewed in our Qubes OS Summit 2025 presentation, [Qubes Air: Hardware,
Firmware, and Architectural
Foundations](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/XAWYSA/) our
roadmap includes secure integration of Dasharo firmware (coreboot+UEFI), AMD’s
OpenSIL, and OpenBMC as a trusted root, aimed at delivering server‑grade Qubes
OS deployments. In the follow‑up session, [Qubes Air: Opinionated Value
Proposition for Security‑Conscious Technical
Professionals](https://cfp.3mdeb.com/qubes-os-summit-2025/talk/CRK7EM/) we
expanded on this vision by highlighting vertical integration scenarios using
Qubes OS with Dasharo, secure thin clients and servers, and advanced
capabilities such as RemoteVM, attestation via TrenchBoot, and early
Proof‑of‑Concepts tailored for highly sensitive technical workflows. Stay
tuned: we're working toward solutions that deliver secure, vertically
integrated, real-world applications for privacy-focused environments using the
Dasharo Pro Package.

If you plan to attend there are still some tickets to grab [here](https://events.dasharo.com/event/2/qubes-os-summit-2025).

#### For OEMs & ODMs

If you are an OEM or ODM and see the value in AMD OpenSIL support for your
products, our team can help make it a reality. Reach out to us via our [contact
form](https://3mdeb.com/contact/#form) or email us at
`contact<at>3mdeb<dot>com` to start the conversation.

#### Stay Updated

If you’re following the Gigabyte MZ33-AR1 journey, we invite you to join our
Dasharo Community Release mailing list for this platform. Subscribers will
receive public announcements about project progress, including the Dasharo
Product Package (DPP) release when it’s ready.

{{< subscribe_form
    "54954349-8626-4c32-836f-90e9738c0510"
    "Subscribe to Gigabyte MZ33-AR1 Dasharo Release Newsletter"
>}}

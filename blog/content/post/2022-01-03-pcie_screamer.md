---
title: PCIe Screamer first look
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/PCIExpress.jpg
author: igor.bagnucki
layout: post
published: true
date: 2022-01-03
archives: "2022"

tags:
  - pcie
  - pciescreamer
  - screamer
  - lambda
  - lambdaconcept
  - sniffer
  - sniff
  - sniffing
  - pci
  - fpga
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

## Why test PCIe sniffing

Information security is a complicated topic. It needs to be considered in
every step of system design. Additionally, for every system, the threat model
may be different.
As a system includes multiple PCIe devices, that, i.e., can use the system's
memory and be shared to an untrusted virtual machine or can themself be
malicious there is a need to protect the memory from DMA attacks executed from
the PCIe bus.

To avoid this risk, there is an option to enable [IOMMU](https://blog.3mdeb.com/2021/2021-01-13-iommu/)
what should fix the problem, but does it?

To verify that IOMMU protects from DMA attacks, this functionality should
be tested, or in other words, it should be tried to make such an attack on a
system.

## What is PCIeScreamer

LambdaConcept's PCIeScreamer is an FPGA board based on Xilinx 7 Series XC7A35T.
The board has a PCIe connector, and it can be connected as the typical PCIe
device but remains under our complete control.

## FPGA development environment

The first step in using the FPGA was to prepare a development environment
for it. There are two significant toolchains. One of them is
[Intel® Quartus® Prime](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/overview.html)
designed for Intel's FPGA's, the other is
[Vivado Design Suite](https://www.xilinx.com/products/design-tools/vivado.html)
produced by Xilinx and designed for Xilinx FPGA's.

Because PCIeScreamer uses Xilinx FPGA, it needs the second one. There is one more
important factor related to the choice of the FPGA synthesis software version, 
the project is based on many IP Cores from Xilinx, many of them are dedicated to
a specific version of `Xilinx Vivado`. The `PCIScreamer` in revision `R01` wich we
have needs FPGA firmware in version `3.2` (2018). This version of firmware had 
been developed in `Xilinx Vivado 2017.4` and for building configuration file for
FPGA this archival version of `Vivado` is required.

## Xilinx Vivado installation 
One can download `Xilinx Vivado 2017.4` for Linux OS from Xilinx(AMD) Website
[Vivado Design Suite](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html) In our opinion, the best choice is 
to download file called `Vivado HLx 2017.4: All OS installer Single-File Download`
 - See screenshot:
![Xilinx Website](/img/Vivado_Browser01.png)
Installing vivado can take a while. At first, there is a need to create free
account at the Xilinx webpage and provide a few of personal details like your
name, company name, job function, and address. Here is step by step tutorial 
regarding the installation of `Xilinx Vivado` 
[Instalation of Vivado Design Suite](https://www.zachpfeffer.com/single-post/installing-20174-vivado-and-sdk-on-linux)

## Building FPGA configuration file (firmware)

Simply having an IDE installed is not enough to program an FPGA. It also needs
a correct design that can be programmed into the device. Although there are several
versions of the firmware for the board PCIScreamer, there is version 3.2 (Tag) from 
this github repository [PCIleech firmware for PCIScreamer](https://github.com/ufrisk/pcileech-fpga)
dedicated to R01 hardware revision.

To build `PCIleech firmware for PCIScreamer`, the following steps were tried:

1. Install Vivado.
2. Add Vivado to the `$PATH` environment variable.

   ```
   export PATH=$PATH:/opt/Xilinx/Vivado/2017.4/bin
   ```
   Your Vivado location may be different depending on options chosen during the
   installation process and installed version.

   You can check if you have done it correctly using the following command:

   ```
   vivado -version
   ```
3. Prepare a separate folder for project files and change your current working 
   directory to it.
4. Clone
   [PCIleech firmware for PCIScreamer](https://github.com/ufrisk/pcileech-fpga)
   and checkout the correct tag (v3.2)

   ```
   git clone https://github.com/ufrisk/pcileech-fpga.git
   cd pcileech-fpga
   git checkout tags/v3.2
   ```
5. After cloning the repository, the rest of the work will be carried out using the
 `Xilinx Vivado 2017.4` software. Luckily for us, the creators of the repository
 provided scripts in TCL that automate work with the project in Vivado. There are
 in subdirectory `pciescreamer` such TCL scripts:

 +  vivado_generate_project.tcl  - this script makes Vivado project
 +  vivado_build.tcl             - this script builds project
 +  vivado_flash_hs2.tcl         - this script writes bitstream in FPGA
  
 We are opening `Xilinx Viavdo` issuing in console command:

 ```bash
   vivado
 ```
 After Vivado main window is open we go to menu `Window` -> `TCL console`. In 
 bottom part of main window `TCL console` window appears - see screens-hot
![Vivado TCL console](/img/Vivado_TCL_Console.png)
In Vivado `TCL console` window we issue command:
```tcl
   source vivado_generate_project.tcl
```
After some time Vivado project will be created.

6. Aftere project has been created we issue second command in Vivado `TCL console`
   ```tcl
      source vivado_build.tcl
   ```
This command will recursively build the entire project, starting with the 
reconstruction of used IP Cores through the synthesis and implementation phase. 
As a result, an FPGA configuration file will be created. Attention! this command
may take up to an hour to execute (depending on the speed of the computer used).

7. The last command is:
   
  ```tcl
   vivado_flash_hs2.tcl 
  ```
  which is writing an configuration file (bitstream) to the FPGA board (using 
  JTAG programmer/debugger)



## Power problem

Programming of the PCIeScreamer in the previous step failed. There could be
several reasons why this could happen. It could be a broken programmer,
misconfigured environment, or nonfunctional FPGA. The third option the problem
with the FPGA seem to be most probable as
[LambdaConcept's instructions](https://docs.lambdaconcept.com/screamer/getting_started.html#boot-the-target-system)
warn about correct power delivery to the board and explain that the green diode
LD3 should be on.

The diode is indeed on, but only if JTAGSerial Programmer is connected to the
power too. When the Programmer is disconnected, the led goes dark too. This LED
behavior may (but not necessarily have to) indicate invalid power of the board.
Another indication that something may be wrong with the PCIe connection is that
no new PCIe device was shown on the tested machine using the `lspci` command.

![](/img/PCIeScreamer_LED.jpg)

The incorrect power delivered to the FPGA could be the result of the faulty PCIe
low-profile riser card used to connect the PCIeScreamer to the motherboard.

![](/img/PCIeScreamer_Adapter.jpg)


## Perspectives on further work

The next step to make PCIe testing work should be to check why programming
FPGA didn't work, and if it is correctly connected.
This work should include checking the FPGA with a different motherboard,
preferably without a low-profile riser card. If that doesn't help, another JTAG
programmer may solve the problem.

## Summary

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

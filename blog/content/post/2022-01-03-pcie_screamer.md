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

The first problem in using the FPGA was to prepare a development environment
for it. There are two significant toolchains. One of them is [Intel® Quartus® Prime](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/overview.html)
designed for Intel's FPGA's, the other is [Vivado Design Suite](https://www.xilinx.com/products/design-tools/vivado.html)
produced by Xilinx and designed for Xilinx FPGA's.

Because PCIeScreamer uses Xilinx FPGA, it needs the later one.

## Vavado installation problem

Instaling Vivado may be quite problematic. At first, there is a need to create
an account at the Xilinx webpage and provide a lot of personal details like your
name, company name, job function, and address.

After downloading an installer and starting it, there is another problem.
The software requires a lot of disk space. Selecting the least options possible
requires 107.88 GB during installation. Complete installation may need even
259.99 GB. Some of that space is freed after installation, but that doesn't
change that you need a big enough HDD and free space.

Installing that gargantuan pack of software takes a few hours too, but luckily
it is a minuscule problem.

## Script tested

Simply having an IDE installed is not enough to program an FPGA. It also needs
a correct design that can be programmed into the device. There are several
projects that implement example designs for PCIeScreamer that can be later
modified to meet our needs.

For this usage, the [enjoy-digital/pcie_screamer](https://github.com/enjoy-digital/pcie_screamer)
project was chosen. However, despite the simple instruction on the project
[README](https://github.com/enjoy-digital/pcie_screamer) page, it is not very straightforward for first use.

To prepare `enjoy-digital/pcie_screamer`, follow these steps:

1. Install Vivado.
2. Add Vivado to the `$PATH` environment variable.

   ```
   export PATH=$PATH:~/Xilinx/Vivado/2021.2/bin
   ```

   Your Vivado location may be different depending on options chosen during the
   installation process and installed version.
3. Prepare a separate folder for files so the scripts won't mess inside your
   important directory and change your current working directory to it.
4. Clone [enjoy-digital/pcie_screamer](https://github.com/enjoy-digital/pcie_screamer)

   `git clone git@github.com:enjoy-digital/pcie_screamer.git`

5. Prepare [enjoy-digital/litex](https://github.com/enjoy-digital/litex)
   environment

   ```
   $ wget https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
   $ chmod +x litex_setup.py
   $ ./litex_setup.py --init --install --user
   ```

   > This step will extract plenty of files in the directory.

6. Because at the time of writing this article, the
   `enjoy-digital/pcie_screamer` scripts are broken. Checkout the working
   version.

   ```
   git checkout 4debf92c747ce19e7f56025ed9e140e6201d3581
   ```

7. However, the checkouted version has a compatibility problem with `litex`.
   Download the [patch]() and apply it:

   ```
   git apply fix_imports.patch
   ```

8. Now, the building of `Xilinx BIT data` should be working

   ```
   ./pcie_screamer.py --build
   ```

9. However, for now, the loading fails

   ```
   $ ./pcie_screamer.py --load

   <output truncated>

   failed loading file build/gateware/top.bit to pld device 0
   Traceback (most recent call last):
     File "./pcie_screamer.py", line 160, in <module>
       main()
     File "./pcie_screamer.py", line 150, in main
       prog.load_bitstream("build/gateware/top.bit")
     File "/home/ibagnucki/git/pcie_screamer/litex/litex/litex/build/openocd.py", line 27, in load_bitstream
       self.call(["openocd", "-f", config, "-c", script])
     File "/home/ibagnucki/git/pcie_screamer/litex/litex/litex/build/generic_programmer.py", line 100, in call
       raise OSError(msg)
   OSError: Error occured during OpenOCD's call, please check:
   - OpenOCD installation.
   - access permissions.
   - hardware and cable.
   ```

## Power problem

## Summary

Summary of the post.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](https://newsletter.3mdeb.com/subscription/PW6XnCeK6)

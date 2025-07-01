---
title: Booting EDK2 on Odroid M2
abstract: EDK II is quickly becoming a big player in the ARM firmware space. In
          this blog post I will be exploring the process of porting EDK II to a
          new platform and the current state of this UEFI implementation on
          ARM based platforms.
cover: /img/tianocore_logo.jpg
author: michal.kopec
layout: post
published: true
date: 2025-07-17
archives: "2025"

tags:
  - uefi
categories:
  - Firmware

---

This post describes the process of booting TianoCore EDK II on an
[Odroid M2](https://wiki.odroid.com/odroid-m2/odroid-m2) platform (ARM64,
RK3588 based) to give an overview of the status of Rockchip platforms in EDK II.

## Introduction

[TianoCore EDK II](https://www.tianocore.org/) is the reference implementation
of UEFI and is the de facto standard boot firmware in the x86 space. In the ARM
world, especially in the embedded Linux space, that role is typically served by
[U-Boot](https://u-boot.org/). With the rise of high performance ARM computing,
however, EDK II is becoming an increasingly popular option for system builders.
In this blog post I'll be checking out the process of booting EDK II and an UEFI
OS on an ARM platform with pre-existing SoC support.

## The platform

![img](/img/odroid_m2_board.jpg)

I picked an Odroid M2, which is a single-board computer (SBC) with a Rockchip
RK3588 system on a chip (SoC). I wanted that SoC in particular, because there is
already some open-source EDK II support for it, in the form of
[edk2-porting/edk2-rk3588](https://github.com/edk2-porting/edk2-rk3588),
maintained by edk2-porting.

[edk2-porting](https://github.com/edk2-porting), or Renegade Project, is a
community dedicated to porting EDK2 to various ARM platforms. They maintain edk2
ports for Rockchip and Qualcomm platforms and have gotten Windows to run on ARM
platforms that have never been designed for it, including smartphones.

The M2 is a pretty neat little board that can run Ubuntu 25.04 smoothly, has an
NPU for users who want it, and most of the Linux support code is already merged.
It also has a 40-pin Raspberry Pi-like GPIO header as well as an extra 2x7 GPIO
header with extra features. The SBC also features an HDMI port, USB-C with
DisplayPort, a debug serial console port, MIPI DSI, and a gigabit Ethernet port.

## The port

I started off by cloning the [edk2-rk3588](https://github.com/edk2-porting/edk2-rk3588)
repo and taking a look at the mainboard specific code. To make my job easier, I
took [the existing OrangePi 5 port](https://github.com/edk2-porting/edk2-rk3588/tree/d4627ada037c53834463023bac229ace10a7fcad/edk2-rockchip/Platform/OrangePi/OrangePi5)
and started modifying it for my purposes. These were the most important parts I
needed to modify:

### Voltage regulators

The first thing I would set were the voltage regulator parameters, as I figured
these would be the most important for safe functioning of the board. Supplying
wrong voltage to sensitive components can cause irreversible damage, so this is
usually what I look at first.

This is the voltage setting code in the OrangePI 5 board code:

```c
static struct regulator_init_data  rk806_init_data[] = {
  /* Master PMIC */
  RK8XX_VOLTAGE_INIT (MASTER_BUCK1,  850000),
  RK8XX_VOLTAGE_INIT (MASTER_BUCK3,  750000),
  RK8XX_VOLTAGE_INIT (MASTER_BUCK4,  750000),
  RK8XX_VOLTAGE_INIT (MASTER_BUCK5,  850000),

  /* This is not configured in the OrangePi5's Linux device tree
  RK8XX_VOLTAGE_INIT(MASTER_BUCK6, 1100000), */
  RK8XX_VOLTAGE_INIT (MASTER_BUCK7,  2000000),
  RK8XX_VOLTAGE_INIT (MASTER_BUCK8,  3300000),
  RK8XX_VOLTAGE_INIT (MASTER_BUCK10, 1800000),

  RK8XX_VOLTAGE_INIT (MASTER_NLDO1,  750000),
  RK8XX_VOLTAGE_INIT (MASTER_NLDO2,  850000),
  /* The OPi is officially configured for the 837500 voltage, but is still marked as avdd_0v75_s0 in the schematic and Linux device tree. rockchip says this voltage is set to improve HDMI stability. */
  RK8XX_VOLTAGE_INIT (MASTER_NLDO3,  837500),
  RK8XX_VOLTAGE_INIT (MASTER_NLDO4,  850000),
  RK8XX_VOLTAGE_INIT (MASTER_NLDO5,  750000),

  RK8XX_VOLTAGE_INIT (MASTER_PLDO1,  1800000),
  RK8XX_VOLTAGE_INIT (MASTER_PLDO2,  1800000),
  RK8XX_VOLTAGE_INIT (MASTER_PLDO3,  1200000),
  RK8XX_VOLTAGE_INIT (MASTER_PLDO4,  3300000),
  RK8XX_VOLTAGE_INIT (MASTER_PLDO5,  3300000),
  RK8XX_VOLTAGE_INIT (MASTER_PLDO6,  1800000),
  /* No dual PMICs on this platform */
};
```

Let's take a look at Odroid M2's
[devicetree](https://github.com/torvalds/linux/blob/155a3c003e555a7300d156a5252c004c392ec6b0/arch/arm64/boot/dts/rockchip/rk3588s-odroid-m2.dts)
and grep for `nldo` to see if we can find the corresponding settings for our
platform:

```dts
vdd_0v75_s3: nldo-reg1 {
  regulator-name = "vdd_0v75_s3";
  regulator-always-on;
  regulator-boot-on;
  regulator-min-microvolt = <750000>;
  regulator-max-microvolt = <750000>;

  regulator-state-mem {
    regulator-on-in-suspend;
    regulator-suspend-microvolt = <750000>;
  };
};
```

According to this snippet, the NLDO1 regulator is powering the vdd_0v75_s3
plane, and the voltage is 0.75V.

Repeat this for every voltage regulator in the devicetree and we get this:

```c
static struct regulator_init_data rk806_init_data[] = {
    /* Master PMIC */
    RK8XX_VOLTAGE_INIT(MASTER_BUCK1, 950000),
    RK8XX_VOLTAGE_INIT(MASTER_BUCK2, 950000),
    RK8XX_VOLTAGE_INIT(MASTER_BUCK3, 750000),
    RK8XX_VOLTAGE_INIT(MASTER_BUCK4, 950000),
    RK8XX_VOLTAGE_INIT(MASTER_BUCK5, 900000),
    /* This is not configured in the M2's Linux device tree
    RK8XX_VOLTAGE_INIT(MASTER_BUCK6, 1100000), */
    RK8XX_VOLTAGE_INIT(MASTER_BUCK7, 2000000),
    RK8XX_VOLTAGE_INIT(MASTER_BUCK8, 3300000),
    RK8XX_VOLTAGE_INIT(MASTER_BUCK10, 1800000),

    RK8XX_VOLTAGE_INIT(MASTER_NLDO1, 750000),
    RK8XX_VOLTAGE_INIT(MASTER_NLDO2, 900000),
    RK8XX_VOLTAGE_INIT(MASTER_NLDO3, 837500),
    RK8XX_VOLTAGE_INIT(MASTER_NLDO4, 850000),
    /* RK8XX_VOLTAGE_INIT(MASTER_NLDO5, 750000),*/

    RK8XX_VOLTAGE_INIT(MASTER_PLDO1, 1800000),
    RK8XX_VOLTAGE_INIT(MASTER_PLDO2, 1800000),
    RK8XX_VOLTAGE_INIT(MASTER_PLDO3, 1200000),
    RK8XX_VOLTAGE_INIT(MASTER_PLDO4, 3300000),
    RK8XX_VOLTAGE_INIT(MASTER_PLDO5, 3300000),
    RK8XX_VOLTAGE_INIT(MASTER_PLDO6, 1800000),
    /* No dual PMICs on this platform */
};
```

### PCI Express Initialization

Here's OrangePi's PCIe initialization code:

```c
PcieIoInit (
  UINT32  Segment
  )
{
  /* Set reset to gpio output mode */
  if (Segment == PCIE_SEGMENT_PCIE20L2) {
    // M.2 M Key
    GpioPinSetDirection (3, GPIO_PIN_PD1, GPIO_PIN_OUTPUT);
  }
}

VOID
EFIAPI
PciePowerEn (
  UINT32   Segment,
  BOOLEAN  Enable
  )
{
  /* nothing to power on */
}

VOID
EFIAPI
PciePeReset (
  UINT32   Segment,
  BOOLEAN  Enable
  )
{
  if (Segment == PCIE_SEGMENT_PCIE20L2) {
    GpioPinWrite (3, GPIO_PIN_PD1, !Enable);
  }
}
```

From this we can gather a couple of things:

- There is a M.2 slot on the board
- There is no Power Enable signal for PCIe on this board
- There is a PCIe Reset signal, connected to GPIO_PIN_PD1 on GPIO controller 3

We need to understand how all this relates to the Odroid M2 we're working with.
Thankfully, Hardkernel provides us with schematics for this board:
[link](https://wiki.odroid.com/odroid-m2/hardware/start)

![M2 PCIe](/img/m2_schematic_pcie_1.png)

Here, we can tell that there is a reset signal on GPIO1_PA7.

![M2 PCIe](/img/m2_schematic_pcie_4.png)

From this fragment we can tell that the PCIe power enable signal corresponds to
pin GPIO0_PC6.

To summarize, we can see that on this board:

- There is an M.2 slot on the board
- There is a Power Enable signal, connected to GPIO_PIN_PC6 on GPIO controller 0
- There is a PCIe reset signal, connected to GPIO_PIN_PA7 on GPIO controller 1

So the code for our board should look like this:

```c
    EFIAPI
    PcieIoInit(
        UINT32 Segment)
{
  /* Set power enable and reset to gpio output mode */
  if (Segment == PCIE_SEGMENT_PCIE20L2)
  {
    // M.2 M Key
    GpioPinSetDirection(1, GPIO_PIN_PA7, GPIO_PIN_OUTPUT);
    GpioPinSetDirection(0, GPIO_PIN_PC6, GPIO_PIN_OUTPUT);
  }
}

VOID
    EFIAPI
    PciePowerEn(
        UINT32 Segment,
        BOOLEAN Enable)
{
  if (Segment == PCIE_SEGMENT_PCIE20L2)
  {
    GpioPinWrite(0, GPIO_PIN_PC6, Enable);
  }
}

VOID
    EFIAPI
    PciePeReset(
        UINT32 Segment,
        BOOLEAN Enable)
{
  if (Segment == PCIE_SEGMENT_PCIE20L2)
  {
    GpioPinWrite(1, GPIO_PIN_PA7, !Enable);
  }
}
```

### Fan control

The Odroid has a small fan installed on the CPU heatsink that helps remove
excess heat from the SoC. We should configure it properly to ensure the
processor doesn't overheat.

Let's take a look at the schematic to see how the fan is connected:

![FAN_PWM signal](/img/m2_schematic_pwm.png)

The PWM signal that controls fan speed is connected to pin GPIO1_PA2, which
should be configured in PWM0_M2 alternate mode. PWM0_M2 corresponds to PWM
controller 0, channel 0. Because the fan is small and has a small rotational
mass, I had to set a low PWM period and duty (50 microseconds). This helps
ensure that the fan doesn't make a lot of noise at lower PWM duty cycles.

Here's the code snippet.

```c
PWM_DATA pwm_data = {
    .ControllerID = PWM_CONTROLLER0,
    .ChannelID = PWM_CHANNEL0,
    .PeriodNs = 50000,
    .DutyNs = 50000,
    .Polarity = FALSE,
}; // PWM0_CH0

VOID
    EFIAPI
    PwmFanIoSetup(
        VOID)
{
  GpioPinSetFunction(1, GPIO_PIN_PA2, 0xB); // PWM0_M2
  RkPwmSetConfig(&pwm_data);
  RkPwmEnable(&pwm_data);
}
```

## Building

To build the board, simply execute the build.sh script from the root of the
edk2-rk3588 repo:

```bash
./build.sh --device odroid-m2
```

This produces a binary that we can flash to hardware:

```bash
~/Development/Dasharo/edk2-rk3588
 => FIT build done
 => Building 8MB NOR FLASH IMAGE
34+0 records in
34+0 records out
17408 bytes (17 kB, 17 KiB) copied, 0.000452301 s, 38.5 MB/s
300+0 records in
300+0 records out
307200 bytes (307 kB, 300 KiB) copied, 0.000979615 s, 314 MB/s
5745+1 records in
5745+1 records out
5883392 bytes (5.9 MB, 5.6 MiB) copied, 0.012152 s, 484 MB/s
Build done: RK3588_NOR_FLASH.img
```

## Flashing

The Odroid can boot from microSD cards, so let's write the image to a card:

```bash
sudo dd if=RK3588_NOR_FLASH.img of=/dev/sdb
```

Now, let's insert the card into the SBC and power it on.

![img](/img/odroid_edk2.jpg)

Success!

## Summary

While the port is still incomplete and many things aren't working as expected
yet (booting Windows, USB3 storage in firmware, LEDs etc), the port is already
capable of installing and booting Ubuntu 25.04 with most things just working.
We are still far from a fully-fledged Dasharo release for an ARM-based platform,
but this experiment gives us some experience and brings us that much closer to
supporting this architecture.

The pull request to edk2-rk3588 adding the Odroid M2 port is available
[here](https://github.com/edk2-porting/edk2-rk3588/pull/218).

Huge thanks to the edk2-porting people for maintaining the edk2-rk3588
repository and providing a solid base to build on. Check out their repository:
[link](https://github.com/edk2-porting/edk2-rk3588).

[Dasharo User Group Community Call (DUG) & Developers vPub](https://events.dasharo.com/event/8/dasharo-user-group-11)
on September 18th at 4 PM UTC! During the call, you'll have the opportunity to
hear more about this adventure, as well as connect with Dasharo community
members, ask questions, and provide feedback on our current activities.

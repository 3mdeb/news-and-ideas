---
title: "Launching Wi-Fi DHCP client Zephyr application on top of the the
CROSSCON Hypervisor"
abstract: "This blog post will show off CROSSCON Hypervisor virtualization on
ARM MCU's byt diving deep into the process of launching Zephyr application
inside CROSSCON Hypervisor's virtual machine."
cover: /covers/zephyr-logo.jpg
author: daniil.klimuk
layout: post
published: true
date: 2025-07-30
archives: "2025"

tags:
  - crosscon
  - hypervisor
  - arm
  - wifi
  - mcu
categories:
  - Virtualization
  - Security

---

## Introduction

The concept of virtualization has been well-known for a while. There are a lot
of hypervisors that serve different purposes and can be launched on different
architectures. But there is a critical requirement for that: the target hardware
architecture should support virtualization.

The requirement limits the hypervisor implementation only to so-called high-end
architectures, for example, ARMv8-A. These architectures, while having excellent
computing performance and an extensive list of features, do not have the best
power consumption and are expensive, and therefore not suitable for some
applications. The other part of the embedded market is covered by MCUs. The
MCUs' architectures are simple, power-efficient, and have lower costs, but they
do not have most of the high-end features, including those needed for the
hypervisor.

But what if one wants to run a hypervisor on an MCU? There are a few solutions
on how to implement a hypervisor in such a constrained environment, and the
CROSSCON Hypervisor is one of them. This blog post will show off CROSSCON
Hypervisor virtualization on ARM MCUs by diving deep into the process of
launching a Zephyr application inside the CROSSCON Hypervisor's virtual machine.

## The CROSSCON Hypervisor

The [CROSSCON Hypervisor][crosscon-hyp] is **a static partitioning hypervisor**
that uses the [Bao Hypervisor][bao-hypervisor] as its base (this blog post will
use the Bao Hypervisor at the beginning, but then switch to the CROSSCON
Hypervisor). Several popular embedded architectures are supported, including ARM
and RISC-V. There is a list of demos [on QEMU][qemu-demos] as well as [on RPi
4][rpi-demos]. This blog post focuses only on the LPCXpresso55S69 demo, but feel
free to check out other platforms.

Generally, the virtualization concept covers three topics:

1. Context separation: an additional scheduler on the hypervisor level for
  platforms with one CPU core, or a static assignment of the cores per virtual
  machine.
2. Memory separation: every virtual machine lives in its own memory.
3. Interrupt separation: every virtual machine handles interrupts assigned to it
  by the hypervisor.

While CROSSCON Hypervisor is a static partitioning hypervisor and should assign
CPU cores statically to every virtual machine, it implements a scheduler for
the platforms that have only one core. The demo described in this blog post uses
the LPCXpresso55S69 board that is equipped with an MCU based on one ARM
Cortex-M33 core. Hence, a scheduler is needed for running more than one virtual
machine.

There is no MMU or GIC on ARM Cortex-M architectures. So the CROSSCON Hypervisor
does not use them for the last two virtualization points: the memory separation
and the interrupt separation. Instead of this, CROSSCON Hypervisor utilizes ARM
TrustZone technologies that are available on ARMv8-M architecture by placing the
hypervisor under the protection of SAU and IDAU units.

![crosscon-zdm](/img/crosscon/crosscon-zdm.png)

For the curious ones, check the [ARMv8-M TrustZone
documentation][trustzone-docs]. But let's focus on the demo now.

[crosscon-hyp]: https://github.com/crosscon/CROSSCON-Hypervisor
[qemu-demos]: https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos
[rpi-demos]: https://github.com/3mdeb/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws
[trustzone-docs]: https://developer.arm.com/documentation/100690/0201

## The demo goal

Here is the demo architecture:

![dhcp-crosscon-zdm](/img/crosscon/dhcp-crosscon-zdm.png)

The demo had two goals:

1. To run a Zephyr RTOS application with some network device access inside the
  CROSSCON Hypervisor virtual machine on LPCXpresso55S69 (the `VM1` from the
  diagram above).
2. To run two CROSSCON Hypervisor virtual machines side-by-side on
  LPCXpresso55S69, where one virtual machine runs some bare-metal application
  (the `VM0` from the diagram above) and the second one runs the application
  from the first goal.

All these goals were preparations for further development in the CROSSCON
Project.

The inputs for the demo were:

* [LPCXpresso55S69 board][board] with additional UART converters.
* [MIKROE-2542 Wi-FI module][wifi-module].
* [Zephyr RTOS DHCP client demo][dhcp-demo].
* Some Zephyr RTOS development experience.

Note that this blog post is not a step-by-step instruction on how to reproduce
the final results. It is more like a story with some tips and insights for the
future CROSSCON Hypervisor developers. For the step-by-step reproduction guides,
check out [this repository][lpc-demos]. Note that this demo was a preparation
for further CROSSCON Project development, hence the repository may not contain
this demo, but another more advanced demo that will use some of the changes
described here.

[board]: https://www.nxp.com/design/design-center/software/development-software/mcuxpresso-software-and-tools-/lpcxpresso-boards/lpcxpresso55s69-development-board:LPC55S69-EVK
[wifi-module]: https://www.mikroe.com/wifi-esp-click
[dhcp-demo]: https://docs.zephyrproject.org/latest/samples/net/dhcpv4_client/README.html
[lpc-demos]: https://github.com/crosscon/uc1-integration

## Implementation

The CROSSCON Hypervisor is a static partitioning hypervisor, that receives the
configuration during the compilation process via C language structures defined
in [a specific configuration file][config-example]. Hence, launching an
application in the CROSSCON Hypervisor virtual machine consists of the following
steps:

1. Set the application entry and load addresses.
2. Assign memory to the virtual machine in which the application will be
  running.
3. Assign memory and interrupts to the memory-mapped peripherals.

In theory, providing this information and compiling the final image will suffice
to launch any application. But in reality, it depends. So, let's get deeper into
the development process.

[config-example]: https://github.com/crosscon/uc1-integration/blob/main/resources/building-bao-hypervisor/config.c

### Just copy the application and see what will happen

The first idea was to build the needed DHCP client application, adjust the
application entry point and memory access in the hypervisor configuration and
try to boot it. The expected result was at least the `main` function entry and
then a fail, because of the unassigned network peripherals. After that, the plan
was to fix the problems step by step using GDB.

The entry address can be extracted from the Zephyr RTOS ELF file:

```bash
readelf -aW zephyr.elf  | grep __start
  4942: 00045b15     0 FUNC    GLOBAL DEFAULT    2 __start
```

And then the extracted address **was decreased** by `1` and added to the
CROSSCON Hypervisor configuration file to the `.entry` field.

```c
(...)
.entry = 0x00045b14,
(...)
```

Then the RAM and FLASH addresses were corrected in the hypervisor configuration
by checking the Zephyr RTOS application devicetree and editing the `.regions`
structure, e.g., (where `regions[0]` is SRAM and `regions[1]` is FLASH):

```c
(...)
.regions =  (struct vm_mem_region[]) {
    {
        .base = 0x20020000, //SRAM1
        .size = 0x10000
    },
    {
        .base = 0x00040000,
        .size = 0x10000
    }
},
(...)
```

But after every boot, the hypervisor jumped to the fault exception handler
during the virtual machine initialization:

```text
fault_exception_handler () at /workdir/bao-hypervisor/src/arch/armv8m/fault_exceptions.c:10
10          while (1) { };
```

And the debugging with three context layers present (the hypervisor, Zephyr
RTOS, and the application) was too complicated to continue with this path.

### Turning "Hello world" into the Wi-Fi application strategy

Another approach was to use some working setup, and then add the needed code and
configuration to the virtual machine piece by piece. So the working setup with
a `Hello world` application was used as a template.

The first thing to add were the drivers, that will not be used immediately and
will only increase the final image size and add some hardware probing. This
allowed to focus on the correct devices assignment and initialization before
debugging complex DHCP demo application code. Each Zephyr application defines
its own configuration in a file named `prj.conf`. The file is simply a Kconfig
fragment, which enables some Zephyr RTOS drivers and functionalities. Those
values are then merged with other settings to produce the final configuration.

The `Hello world` application was simple enough to have an empty `prj.config`.
The target application, though, was much more complex - it used, among others,
network drivers that needed to be enabled in Zephyr. The content of the
`prj.conf` for the Wi-Fi application is shown below:

```text
CONFIG_NETWORKING=y
CONFIG_NET_IPV6=nhttps://git.3mdeb.com/3mdeb/offers/pulls/200
CONFIG_NET_IPV4=y
CONFIG_NET_ARP=y
CONFIG_NET_UDP=y
CONFIG_NET_DHCPV4=y
CONFIG_NET_DHCPV4_OPTION_CALLBACKS=y
CONFIG_DNS_RESOLVER=y

CONFIG_TEST_RANDOM_GENERATOR=y

CONFIG_INIT_STACKS=y

CONFIG_NET_MGMT=y
CONFIG_NET_MGMT_EVENT=y
CONFIG_NET_MGMT_EVENT_INFO=y

CONFIG_NET_LOG=y
CONFIG_LOG=y

CONFIG_SLIP_STATISTICS=n
CONFIG_NET_SHELL=y

CONFIG_WIFI=y

CONFIG_NET_L2_WIFI_MGMT=y
```

The first step of the new strategy was to simply copy those settings into
`Hello world`'s `prj.conf` and build it. This was enough to trigger a build
error:

```text
zephyr/zephyr-sdk-0.17.0/arm-zephyr-eabi/bin/../lib/gcc/arm-zephyr-eabi/12.2.0/../../../../arm-zephyr-eabi/bin/ld.bfd: zephyr/zephyr_pre0.elf section `text' will not fit in region `FLASH'
zephyr/zephyr-sdk-0.17.0/arm-zephyr-eabi/bin/../lib/gcc/arm-zephyr-eabi/12.2.0/../../../../arm-zephyr-eabi/bin/ld.bfd: region `FLASH' overflowed by 35820 bytes
collect2: error: ld returned 1 exit status
ninja: build stopped: subcommand failed.
```

Something was off. The memory configuration, which worked fine for the original
Wi-Fi application, produced a flash memory overflow after the first step.

The problem was caused by the fact that the initial DHCP demo application was
configured to run without the hypervisor's memory constraints. More precisely,
it used [upstream Zephyr][zephyr-upstream], which had less strict constraints on
the flash size. The [fork][3mdeb-zephyr] on which the `Hello world` template
application was prepared sets a lower flash size limit to fit the memory
allocated to the virtual machine by the hypervisor.

The easiest way to decrease the memory usage is to disable any unused code. The
`CONFIG_NET_SHELL` is an option that turns on a shell module that provides
network commands. It was not needed, therefore it was turned off. Disabling
this option alone allowed to build the application, but it kept throwing the
same hard-to-debug runtime exceptions. This indicates that some driver was not
able to initialize the hardware. So, the next step was to add options to
`prj.conf` one by one to see which hardware cause the problems and fix it.

The first configuration option - `CONFIG_NETWORKING=y` - was enough to cause an
exception. The question is why? After comparing configuration files from before
and after enabling `CONFIG_NETWORKING`, some interesting dependencies that were
added to the image showed up:

```diff
1301a1505,1506
> CONFIG_ENTROPY_DEVICE_RANDOM_GENERATOR=y
> # CONFIG_XOSHIRO_RANDOM_GENERATOR is not set
1302a1508,1510
> CONFIG_CSPRNG_ENABLED=y
> CONFIG_HARDWARE_DEVICE_CS_GENERATOR=y
> # CONFIG_CTR_DRBG_CSPRNG_GENERATOR is not set
```

Zephyr RTOS networking module requires access to the random number generator
(i.e., RNG), which was not granted to the virtual machine by the hypervisor.

Hardware access can be configured in the hypervisor configuration. The CROSSCON
Hypervisor virtual machine can be assigned the device by modifying the `devs`
field via a new `vm_dev_region` structure:

```c
.dev_num = 4,
.devs =  (struct vm_dev_region[]) {
{
    /* Flexcomm Interface 2 (USART2) */
    .pa = 0x40088000,
    .va = 0x40088000,
    .size = 0x1000,
    .interrupt_num = 1,
    .interrupts = (irqid_t[]) {16+16}
},
{
    /* SYSCON + IOCON + PINT + SPINT */
    .pa = 0x40000000,
    .va = 0x40000000,
    .size = 0x5000,
},

(...)
```

The memory map of the board can be found in the board [user
manual][board-manual]. The address of the RNG that was found in the manual is
shown below.

![img](/img/crosscon/lpcxpresso-rng.png)

A quick look at the Zephyr RTOS device tree showed that the size of RNG's memory
region is `0x1000`:

```dts
 rng: rng@3a000 {
  compatible = "nxp,lpc-rng";
  reg = <0x3a000 0x1000>;
  status = "okay";
 };
```

Access was granted by modifying the previously mentioned hypervisor
configuration:

```diff
@@ -74,7 +74,7 @@ struct config config = {
                         .size = 0x10000
                     }
                 },
-                .dev_num = 4,
+                .dev_num = 5,
                 .devs =  (struct vm_dev_region[]) {
                     {
                         /* Flexcomm Interface 2 (USART2) */
@@ -102,6 +102,12 @@ struct config config = {
                         .va = 0x40020000,
                         .size = 0x1000,https://git.3mdeb.com/3mdeb/offers/pulls/200
                     },
+                    {
+                        /* RNG */
+                        .pa = 0x4003a000,
+                        .va = 0x4003a000,
+                        .size = 0x1000,
+                    },
                 },
                 .ipc_num = 1,
                 .ipcs = (struct ipc[]) {
```

This, however, did not initially work. The program terminated with an error:

```text
    at bao-hypervisor/src/arch/armv8m/mem.c:32
32                  ERROR("failed to register sau entry");
```

After discussing the issue with [the CROSSCON Hypervisor maintainers][issue-17],
it turned out that the limit on SAU entries for this TrustZone implementation
was exceeded. The solution was simple - merge some of the `vm_dev_region`
structures in the hypervisor configuration:

```diff
                         .size = 0x10000
                     }
                 },
-                .dev_num = 5,
+                .dev_num = 4,
                 .devs =  (struct vm_dev_region[]) {
                     {
                         /* Flexcomm Interface 2 (USART2) */
@@ -90,18 +90,12 @@ struct config config = {
                         .va = 0x40000000,
                         .size = 0x5000,
                     },
-                    {
-                        /* ANALOG */
+                    {
+                        /* ANALOG + POWER MGM  */
                         .pa = 0x40013000,
                         .va = 0x40013000,
-                        .size = 0x1000,
-                    },
-                    {
-                        /* POWER MGM */
-                        .pa = 0x40020000,
-                        .va = 0x40020000,
-                        .size = 0x1000,
-                    },
+                        .size = 0xE000,
+                    },
                     {
```

After these changes, the `Hello world` application with `CONFIG_NETWORK` enabled
booted up without issues. It was time to add the rest. Further development
resulted in finding out that there were 2 more options that stopped the DHCP
application configuration from working - `CONFIG_NET_LOG` and `CONFIG_LOG`. This
time, the problem was in the UART configuration. The Wi-Fi module communicates
with the board using UART in the Microelectronica Click LPCXpresso55S69 header.
The same UART had previously been used for serial communication between the
virtual machine and host PC. This caused conflicts that resulted in a crash.
Luckily, the goal was to run the modified `Hello world` application on the
CROSSCON Hypervisor, and there was no need for the serial logs for that. With
those two configs disabled, the `Hello world` application with the entire
`prj.conf` from the DHCP application booted up correctly. It was time to run the
DHCP application.

[issue-17]: https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/issues/17

### Back to the DHCP application

Unfortunately, running the DHCP application after the corrections in the
previous chapter caused another jump to `fault_exception_handler`. A quick
debugging with GDB pointed out a problem with `memset` function:

```text
Breakpoint 1, z_early_memset (dst=0x20023690 <z_interrupt_stacks>, c=170, n=2048)
    at zephyr/kernel/init.c:197
197             (void) memset(dst, c, n);

(gdb) stepi
0x0005082a in memset ()
(gdb)
_exception_handler ()
    at bao-hypervisor/src/arch/armv8m/exceptions.S:156
156         b   fault_exception_handler
```

Further debugging allowed to track the addresses that the `memset` was using:

```text
(gdb) p memset
$1 = {void *(void *, int, size_t)} 0x100015a6 <memset>
(gdb) p dst
$2 = (void *) 0x20023690 <z_interrupt_stacks>
(gdb) p c
$3 = 170
(gdb) p n
$4 = 2048
```

The addresses were correctly passed to the Zephyr RTOS devicetree. The problem
was elsewhere - the second entry in `regions` defines FLASH memory addresses
available to the virtual machine:

```c
.regions =  (struct vm_mem_region[]) {
    {
        .base = 0x20020000, //SRAM1
        .size = 0x10000
    },
    {
        .base = 0x00040000,
        .size = 0x10000
    }
},
```

The address used by the `memset` was `0x0005082a` - that was outside of the
range. The issue was fixed by increasing the range size to `0x20000`.

With this configuration, no exceptions were thrown. This was, however, not the
end of the problems.

The hypervisor [refused to run][issue-20] code inside `VM1` while `VM0` was
running correctly. It seemed like only the application from VM0 was executing,
and the hypervisor scheduler never switched to executing the application from
`VM1`. The system uses the TrustZone system clock that generates periodic
`SysTick` interrupts inside TrustZone. These interrupts trigger the hypervisor's
scheduler. This is a classical implementation of the Round Robin scheduling
policy, which makes sure that every virtual machine gets its slice of the CPU
time periodically. The scheduler's dispatcher might be another problem here.
Without it working correctly, the next-to-execute virtual machine context can be
restored incorrectly.

First things first - a breakpoint inside the `SysTick` handler was set to verify
that both the scheduling policy and the dispatcher are working correctly:

```text
175         mov r0, #SYSTICK_INT_N
(gdb) n
176         bl interrupts_handle
(gdb) p $r0
$9 = 15
(...)
interrupts_handle (int_id=15)
    at bao-hypervisor/src/core/interrupts.c:110
110             return HANDLED_BY_HYP;
```

After examining the Armv8-M Architectural Reference Manual, it turned out that
ID 15 corresponds to the `SysTick` interrupt. It means that the context
switch between virtual machines was actually happening. A breakpoint just before
switching to the virtual machine context was set to confirm this:

```text
Breakpoint 1, excep_return ()
    at bao-hypervisor/src/arch/armv8m/exceptions.S:188
188         bx lr
(gdb) si
main ()
    at bao-baremetal-guest/src/main.c:101
101         while(1) wfi();
(gdb) c
Continuing.
INFO: [stub (3333)] Xw:
INFO: [stub (3333)] Xc:

Breakpoint 1, excep_return ()
    at bao-hypervisor/src/arch/armv8m/exceptions.S:188
188         bx lr
(gdb) si
    at modules/hal/cmsis/CMSIS/Core/Include/cmsis_gcc.h:951
951       __ASM volatile ("cpsie i" : : : "memory");
(gdb) n
arch_cpu_idle ()
    at zephyr/arch/arm/core/cortex_m/cpu_idle.c:105
105             __ISB();
(gdb) n
idle (unused1=<optimized out>, unused2=<optimized out>, unused3=<optimized out>)
    at zephyr/kernel/idle.c:51
51                      (void) arch_irq_lock();
(gdb) n
75                      k_cpu_idle();
```

Code from Zephyr RTOS was being executed, which confirmed that the switch was
happening. For some reason, however, Zephyr RTOS executed the `idle` task
instead of the DHCP application's task.

The problem was caused by a conflict in the UART interfaces configuration - the
same UART was once again set up to be used for both the serial console and the
Wi-Fi module, that caused initialization fail in the DHCP application's task.
This time, the logs from the DHCP application were needed. Therefore, the device
tree was modified so that two different interfaces were used.

```diff
--- a/boards/nxp/lpcxpresso55s69/lpcxpresso55s69_lpc55s69_cpu0_ns.dts
+++ b/boards/nxp/lpcxpresso55s69/lpcxpresso55s69_lpc55s69_cpu0_ns.dts
@@ -30,9 +30,9 @@
                zephyr,sram = &non_secure_ram;
                zephyr,flash = &flash0;
                zephyr,code-partition = &slot0_ns_partition;
-               zephyr,uart-mcumgr = &flexcomm2;
-               zephyr,console = &flexcomm2;
-               zephyr,shell-uart = &flexcomm2;
+               zephyr,uart-mcumgr = &flexcomm3;
+               zephyr,console = &flexcomm3;
+               zephyr,shell-uart = &flexcomm3;
                zephyr,entropy = &rng;
        };

@@ -84,6 +84,10 @@
        status = "okay";
 };

+&flexcomm3 {
+       status = "okay";
+};
+
 &flexcomm4 {
        status = "okay";
 };
--- a/boards/nxp/lpcxpresso55s69/lpcxpresso55s69.dtsi
+++ b/boards/nxp/lpcxpresso55s69/lpcxpresso55s69.dtsi
@@ -12,7 +12,7 @@
                led1 = &green_led;
                led2 = &blue_led;
                spi-8 = &hs_lspi;
-               usart-0 = &flexcomm2;
+               usart-0 = &flexcomm3;
        };

        leds {
@@ -104,7 +104,7 @@
        };
 };

-&flexcomm2 {
+&flexcomm3 {
        compatible = "nxp,lpc-usart";
        current-speed = <115200>;
 };
@@ -188,6 +188,11 @@ mikrobus_spi: &hs_lspi {
        pinctrl-names = "default";
 };

+&flexcomm3 {
+       pinctrl-0 = <&pinmux_flexcomm3_usart>;
+       pinctrl-names = "default";
+};
+
 &flexcomm4 {
        pinctrl-0 = <&pinmux_flexcomm4_i2c>;
        pinctrl-names = "default";
--- a/boards/nxp/lpcxpresso55s69/lpcxpresso55s69-pinctrl.dtsi
+++ b/boards/nxp/lpcxpresso55s69/lpcxpresso55s69-pinctrl.dtsi
@@ -27,6 +27,14 @@
                };
        };

+       pinmux_flexcomm3_usart: pinmux_flexcomm3_usart {
+               group0 {
+                       pinmux = <FC3_TXD_SCL_MISO_WS_PIO0_2>,
+                               <FC3_RXD_SDA_MOSI_DATA_PIO0_3>;
+                       slew-rate = "standard";
+               };
+       };
+
        pinmux_flexcomm4_i2c: pinmux_flexcomm4_i2c {
                group0 {
                        pinmux = <FC4_TXD_SCL_MISO_WS_PIO1_20>,
```

Now the main thread was executed. However, the Wi-Fi module was not being
correctly initialized:

```text
[00:00:00.000,000] <inf> wifi_esp_at: DT has external_reset
[00:00:00.000,000] <inf> wifi_esp_at: Waiting for interface to come up by itself...
[00:00:03.000,000] <inf> wifi_esp_at: Result: -11
[00:00:03.000,000] <inf> wifi_esp_at: ESP_AT: sending RST CMD
[00:00:06.000,000] <inf> wifi_esp_at: ESP_AT: sending RST CMD
[00:00:09.000,000] <inf> wifi_esp_at: ESP_AT: sending RST CMD
[00:00:12.001,000] <err> wifi_esp_at: Failed to reset device: -116
*** Booting Zephyr OS build v4.1.0-1219-g584f2f86f905 ***
[00:00:12.001,000] <inf> MAIN: Hello in WiFi App!
[00:00:12.001,000] <inf> MAIN: Connecting to Wi-Fi network rpi3-hotspot...
[00:00:12.001,000] <err> MAIN: Failed to connect to Wi-Fi network: -115
[00:00:12.001,000] <inf> MAIN: Run dhcpv4 client
[00:00:12.001,000] <inf> MAIN: Start on mikroe_wifi_bt_click: index=1          ```
```

Further diagnosis showed an interesting bug: The elapsed time within Zephyr
RTOS, was 16 times slower than real time:

```text
[2025-04-29 21:17:07.740] *** Booting Zephyr OS build v4.1.0-1220-gf352f026f154 ***
[2025-04-29 21:17:07.740] Hello World from Zephyr VM running on CROSSCON HV!
[2025-04-29 21:17:07.740] Uptime: 1 ms
[2025-04-29 21:17:15.734] Uptime: 1001 ms
[2025-04-29 21:17:23.730] Uptime: 2001 ms
[2025-04-29 21:17:31.725] Uptime: 3001 ms
[2025-04-29 21:17:39.720] Uptime: 4002 ms
[2025-04-29 21:17:47.716] Uptime: 5002 ms
[2025-04-29 21:17:55.712] Uptime: 6002 ms
[2025-04-29 21:18:03.708] Uptime: 7002 ms
[2025-04-29 21:18:11.703] Uptime: 8002 ms
[2025-04-29 21:18:19.699] Uptime: 9003 ms
[2025-04-29 21:18:27.694] Timer test end
```

The timer was divided by the hypervisor depending on the number of virtual
machines (by two in this case). Additionally, within Zephyr RTOS it was 8 times
slower. The CROSSCON Hypervisor problem [was fixed][issue-22] by its
maintainers. Zephyr's time division was easy to fix - it required proper system
timer configuration:

```defconfig
# must be equal to the PLAT_TIMER_FREQ as set by the CROSSCON HV
CONFIG_SYS_CLOCK_HW_CYCLES_PER_SEC=12000000
```

[The final problem][issue-29] was again related to UART - the RX callback was
not being triggered. It was suggested by the hypervisor maintainers that instead
of looking for the solution within the Bao Hypervisor, it is better to switch to
the CROSSCON Hypervisor, where the issue no longer appeared. The CROSSCON
hypervisor configuration followed a slightly different format. It was modified
to use a single virtual machine with the Zephyr RTOS DHCP demo application.

```c
#include <config.h>

struct vm_config zephyr = {
    .image = VM_IMAGE_LOADED(0x00040000, 0x00040000, 0xF000),
    .entry = @@ZEPHYR_VM_ENTRY@@,
    .platform = {
        .cpu_num = 1,
        .region_num = 2,
        .regions =  (struct vm_mem_region[]) {
            {
                .base = 0x20020000, //SRAM1
                .size = 0x10000
            },
            {
                .base = 0x00040000,
                .size = 0x18000
            }
        },
        .dev_num = 4,
        .devs =  (struct vm_dev_region[]) {
            {
                /* Flexcomm Interface 2 (USART2) */
                /* AND */
                /* Flexcomm Interface 3 (USART3) */
                .pa = 0x40088000,
                .va = 0x40088000,
                .size = 0x2000,
                .interrupt_num = 2,
                .interrupts = (irqid_t[]) {16+16, 17+16}
            },
            {
                /* SYSCON + IOCON + PINT + SPINT */
                .pa = 0x40000000,
                .va = 0x40000000,
                .size = 0x5000,
            },
            {
                /* ANALOG + POWER MGM  */
                .pa = 0x40013000,
                .va = 0x40013000,
                .size = 0xE000,
            },
            {
                /* RNG */
                .pa = 0x4003a000,
                .va = 0x4003a000,
                .size = 0x1000,
            },
        },
        .ipc_num = 1,
        .ipcs = (struct ipc[]) {
            {
                .base = 0x20017000,
                .size = 0x1000,
                .shmem_id = 0,
                .interrupt_num = 1,
                .interrupts = (irqid_t[]) {79}
            }
        },
    }
};

struct config config = {

    CONFIG_HEADER
    .shmemlist_size = 1,
    .shmemlist = (struct shmem[]) {
        [0] = {.base = 0x20017000, .size = 0x1000,},
    },
    .vmlist_size = 1,
    .vmlist = (struct vm_config*[]) {
        &zephyr
    }
};
```

This was the final step required to get the DHCP application to work. The Wi-Fi
module was initialized correctly, and the board managed to establish a
connection with the Wi-Fi access point:

![img](/img/hv-wifi-app.png)

[issue-22]: https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/issues/22
[issue-20]: https://github.com/Dasharo/open-source-firmware-validation/blob/dede9f71ad8ae53faec26996a0455d3a90e27c92/dts/dts-e2e.robot#L28
[issue-29]: https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/issues/29

## Summary

Running a Zephyr application on top of the the CROSSCON Hypervisor is a task
that comes with many challenges. Despite having a working application, many
issues arose along the way, from enabling devices used internally by libraries
to fixing hypervisor bugs. But it is important to remember that the CROSSCON
project is still in development, and many of the problems will be solved in
further releases.

For any questions or feedback, feel free to contact us at <contact@3mdeb.com>
or hop on our community channels:

* [Zarhus Matrix Workspace](https://matrix.to/#/#zarhus:matrix.3mdeb.com)
* [Zarhus Developers Meetup](https://vpub.dasharo.com/e/22/zarhus-developers-meetup-0x1)

[zephyr-upstream]: https://github.com/zephyrproject-rtos/zephyr
[3mdeb-zephyr]: https://github.com/3mdeb/zephyr
[board-manual]: https://www.mouser.com/pdfDocs/NXP_LPC55S6x_UM.pdf
[bao-hypervisor]: https://github.com/bao-project/bao-hypervisor

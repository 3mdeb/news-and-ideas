---
title: "Deploying a Zephyr Wi-Fi DHCP client application on the CROSSCON
Hypervisor"
abstract: "This blog post will show off CROSSCON Hypervisor virtualization on
ARM MCU's by diving deep into the process of launching Zephyr application
inside CROSSCON Hypervisor's virtual machine."
cover: /covers/mcu-virt.png
author:
  - mateusz.kusiak
  - daniil.klimuk
  - pawel.langowski
layout: post
private: false
published: true
date: 2025-10-02
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

Virtualization traditionally relies on high-end architectures with hardware
support, but what about low-cost, power-efficient MCUs? Can devices like that
use the benefits of virtualization? The CROSSCON Hypervisor tackles this
challenge by enabling virtualization on ARM MCUs. In this post, we’ll explore
how CROSSCON runs a Zephyr application inside its virtual machine and what
makes this approach possible.

## The CROSSCON Hypervisor

The [CROSSCON Hypervisor][crosscon-hyp] is a **static partitioning hypervisor**
that originated as a fork of the [Bao Hypervisor][bao-hypervisor]. Over time,
CROSSCON has grown into an independent project with its own features and
direction, while keeping the same core principles of simplicity and minimalism
that Bao is known for.

Like other hypervisors, CROSSCON implements three key aspects of virtualization:

1. **Context separation** – either through static assignment of CPU cores to
   virtual machines or, on single-core platforms, through a scheduler.
1. **Memory separation** – each virtual machine is isolated in its own memory
   region, with optional shared regions defined for communication.
1. **Interrupt separation** – interrupts are delivered only to the virtual
   machine assigned to handle them.

This blog post demonstrates CROSSCON running on the
[LPCXpresso55S69 board][lpcxpresso55s69], which features an ARM Cortex-M33 core
and a secondary Cortex-M33 co-processor. While the co-processor is present, it
lacks critical features such as an MPU, FPU, DSP, ETM, and TrustZone, so
CROSSCON relies only on the primary core.

For a hypervisor, features like an MPU or TrustZone are crucial because they
provide hardware-based memory protection and isolation, while an FPU or DSP can
boost performance for specific workloads. Since these are not available on the
co-processor, CROSSCON leverages the primary Cortex-M33 core and uses its own
scheduler to run multiple virtual machines. Unlike high-end architectures that
include an MMU or GIC, CROSSCON instead depends on the TrustZone-related
SAU and IDAU units of ARMv8-M to enforce memory and interrupt separation.

![crosscon-zdm](/img/crosscon/crosscon-zdm.png)

For the curious ones, check the [ARMv8-M TrustZone
documentation][trustzone-docs]. But let's focus on the demo now.

[crosscon-hyp]: https://github.com/crosscon/CROSSCON-Hypervisor
[trustzone-docs]: https://developer.arm.com/documentation/100690/0201
[lpcxpresso55s69]: https://www.nxp.com/design/design-center/software/development-software/mcuxpresso-software-and-tools-/lpcxpresso-boards/lpcxpresso55s69-development-board:LPC55S69-EVK

## The demo goal

Here is the demo architecture:

![dhcp-crosscon-zdm](/img/crosscon/dhcp-crosscon-zdm.png)

The demo had two goals:

1. Run a Zephyr RTOS application with network device access inside a CROSSCON
   Hypervisor virtual machine on LPCXpresso55S69 (`VM1` in the diagram).
1. Run two CROSSCON virtual machines side-by-side on LPCXpresso55S69, where one
   VM runs a bare-metal application (`VM0`) and the other runs the Zephyr
   application from goal 1.

To achieve this demo, we used:

* [LPCXpresso55S69 board][board] with additional UART converters
* [MIKROE-2542 Wi-FI module][wifi-module]
* [Zephyr RTOS DHCP client demo][dhcp-demo]
* Basic Zephyr RTOS development experience

This post is not a step-by-step guide, but rather a walkthrough of how the demo
was built and the lessons learned along the way. If you’d like to reproduce the
setup, check out the [demo repository][lpc-demos].

[board]: https://www.nxp.com/design/design-center/software/development-software/mcuxpresso-software-and-tools-/lpcxpresso-boards/lpcxpresso55s69-development-board:LPC55S69-EVK
[wifi-module]: https://www.mikroe.com/wifi-esp-click
[dhcp-demo]: https://docs.zephyrproject.org/latest/samples/net/dhcpv4_client/README.html
[lpc-demos]: https://github.com/crosscon/uc1-integration

## Implementation

The CROSSCON Hypervisor is a static partitioning hypervisor that receives the
configuration during the compilation process via C language structures defined
in [a specific configuration file][config-example]. Hence, launching an
application in the CROSSCON Hypervisor virtual machine consists of the following
steps:

1. Set the application entry and load addresses.
2. Assign memory to the virtual machine in which the application will be
  running.
3. Assign memory and interrupts to the memory-mapped peripherals.

In theory, providing this information and compiling the final image should be
enough to launch any application. In practice, it’s not that straightforward.
If something is misconfigured, the hypervisor does not provide clear error
feedback, so diagnosing issues often requires deeper insight. Let’s take a
closer look.

[config-example]: https://github.com/crosscon/uc1-integration/blob/main/resources/building-bao-hypervisor/config.c

### Attempt 1: Just copy the application and see what happens

The initial plan was simple: build the DHCP client application, configure its
entry point and memory in the hypervisor, and try to boot it. We didn’t expect
it to run flawlessly on the first attempt; the assumption was that it would at
least reach the `main` function and then fail due to unassigned network
peripherals. The idea was to fix such issues step by step with GDB. What we
didn’t anticipate was that the first obstacles would come from the hypervisor
itself rather than the application. But let's start from the beginning, this is
how we've done it.

To launch a Zephyr application inside CROSSCON, the hypervisor needs to know
two things:

1. **Where execution should begin** (the entry address).
2. **How the application’s memory is laid out** (RAM and FLASH regions).

The entry point can be extracted from the Zephyr ELF file:

```bash
readelf -aW zephyr.elf  | grep __start
  4942: 00045b15     0 FUNC    GLOBAL DEFAULT    2 __start
```

On ARM Cortex-M architectures, function addresses use the least significant bit
to indicate Thumb mode. This means the actual entry address in the hypervisor's
configuration must be the extracted value with that bit cleared (hence the `-1`).

```c
(...)
.entry = 0x00045b14,
(...)
```

Next, the RAM and FLASH layout must match what Zephyr expects. These regions are
described in the application’s devicetree, so the `.regions` structure in the
hypervisor configuration needs to be updated accordingly (e.g., `regions[0]` for
SRAM, `regions[1]` for FLASH).

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

...and the debugging with three context layers present (the hypervisor, Zephyr
RTOS, and the application) was too complicated to continue with this path.
As stated earlier, the hypervisor does not provide any feedback about a
configuration mismatch. We needed good-known configuration, thus we did the
following...

### Attempt 2: Turning "Hello world" into the Wi-Fi application

Another approach was to start from a known working configuration demo and
gradually adapt it. We used a simple `Hello world` application as a template and
then added the target application piece by piece.

The first step was to enable the necessary device drivers in the Zephyr
configuration, even if they were not immediately used. Doing this allowed us to
verify correct device assignment and initialization before tackling the more
complex DHCP application logic. The aim was simple, and it was all about
"booting" anything.

In Zephyr, each application defines its configuration in a `prj.conf` file,
which is a Kconfig fragment that enables drivers and features. These settings
are merged with other defaults to produce the final build configuration. While
the `Hello world` application could run with an empty `prj.conf`, the Wi-Fi demo
required additional drivers, which were added incrementally to the
configuration.

```text
CONFIG_NETWORKING=y
CONFIG_NET_IPV6=n
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

After the first step, the Wi-Fi application produced a flash memory overflow.
The root cause was that the original DHCP demo was configured without the
hypervisor's memory limits, using [upstream Zephyr][zephyr-upstream] with a
larger allowed flash size. In contrast, the [fork][3mdeb-zephyr] used for the
`Hello world` template enforces stricter flash limits to fit the memory
allocated to the virtual machine.

To reduce memory usage, we first disabled unnecessary features, such as
`CONFIG_NET_SHELL`, which provides network commands that were not needed. This
made it possible to build the application, but runtime exceptions persisted,
indicating that some drivers were failing to initialize the hardware. The next
step was to enable drivers in `prj.conf` incrementally, identifying and fixing
the ones causing the issues.

The first configuration option - `CONFIG_NETWORKING=y` - was enough to cause a
hypervisor exception. The question is why? After comparing configuration files
from before and after enabling `CONFIG_NETWORKING`, some interesting
dependencies that were automatically added to the configuration image showed up:

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
(RNG), which was not initially available to the virtual machine.

Hardware access needs to be configured in the hypervisor `config` file. In
CROSSCON, a virtual machine is granted access to a device by adding a
corresponding entry to the `devs` field using a `vm_dev_region` structure:

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

The memory map of the board can be found in the
[board user manual][board-manual]. The address of the RNG that was found in the
manual is shown below.

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
we discovered that the number of SAU entries for TrustZone had exceeded.
Each `vm_dev_region` in the hypervisor configuration consumes one or more SAU
entries, and the original setup had more regions than the hardware could handle.

The solution was to **merge some of the `vm_dev_region` structures** into larger
contiguous regions, reducing the total number of SAU entries while still
covering the same devices and memory areas:

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

This adjustment brought the configuration within the SAU limit, allowing the
virtual machine to access all required devices properly. Without this change,
the hypervisor could not map all devices, which would have caused hardware
access failures in the VM.

During testing, the DHCP application failed to run correctly, even after the
previous configuration fixes. The root cause was a conflict on the UART used by
the Wi-Fi module: the same UART had previously been assigned for serial
communication between the virtual machine and the host PC, leading to crashes.
Additionally, enabling `CONFIG_NET_LOG` and `CONFIG_LOG` triggered logging over
that same UART, which exacerbated the problem.

The solution was straightforward: disable the conflicting options. After turning
off `CONFIG_NET_LOG` and `CONFIG_LOG`, the modified `Hello world` application,
now using the full `prj.conf` from the DHCP application, booted successfully.
With this setup working correctly, it was finally time to run the DHCP
application itself.

[issue-17]: https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/issues/17

### Back to the DHCP application

Unfortunately, running the DHCP application after the corrections in the
previous chapter caused another jump to `fault_exception_handler`. A quick
debugging with GDB pointed out a problem with `memset` the function:

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

Further debugging allowed us to track the addresses that the `memset` was using:

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

The addresses were correctly passed to the Zephyr RTOS Devicetree. The problem
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

The address used by the `memset` was `0x0005082a`, which lay outside the virtual
machine's assigned memory range. The issue was fixed by increasing the VM's
RAM allocation to `0x20000`, ensuring that the memory accessed by the
application fell within the allowed range.

With this updated configuration, no exceptions were thrown. This, however,
was not the end of the problems.

The hypervisor [refused to run][issue-20] code inside `VM1` while `VM0` was
running correctly. Since the hypervisor executed successfully, yet only one of
the VMs provided output, we suspected the issue might be related to the
scheduler. The whole case of how we verified that is described later in this
section; for now, let's focus on the theory. The system uses the TrustZone
system clock that generates periodic `SysTick` interrupts inside TrustZone.
These interrupts trigger the hypervisor's scheduler. This is a classical
implementation of the Round Robin scheduling policy, which makes sure that every
virtual machine gets its slice of the CPU time periodically. The scheduler's
dispatcher might be another problem here. Without it working correctly, the
next-to-execute virtual machine context can be restored incorrectly.

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

After examining the ARMv8-M Architectural Reference Manual, it turned out that
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
Wi-Fi module, which caused initialization failure in the DHCP application's
task. This time, the logs from the DHCP application were needed. Therefore, the
Devicetree was modified so that two different interfaces were used.

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
machines (by two in this case). Additionally, within Zephyr RTOS it ran
8 times slower. The CROSSCON Hypervisor issue [was fixed][issue-22] by its
maintainers. Zephyr's time division was easy to correct with a proper system
timer configuration, though we did not investigate why the slowdown was
exactly by this factor.

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

Running a Zephyr application on top of the CROSSCON Hypervisor is a task
that comes with many challenges. Despite having a working application, many
issues arose along the way, from enabling devices used internally by libraries
to fixing hypervisor bugs.

For any questions or feedback, feel free to contact us at <contact@3mdeb.com>
or hop on our community channels:

* [Zarhus Matrix Workspace](https://matrix.to/#/#zarhus:matrix.3mdeb.com)
* [Zarhus Developers Meetup](https://vpub.dasharo.com/e/22/zarhus-developers-meetup-0x1)

[zephyr-upstream]: https://github.com/zephyrproject-rtos/zephyr
[3mdeb-zephyr]: https://github.com/3mdeb/zephyr
[board-manual]: https://www.mouser.com/pdfDocs/NXP_LPC55S6x_UM.pdf
[bao-hypervisor]: https://github.com/bao-project/bao-hypervisor

---
title: Running demo Wi-Fi Zephyr application inside the CROSSCON Hypervisor
abstract: "Dive deep into the process of running your Zephyr application inside
CROSSCON Hypervisor's virtual machine. This post goes into elaborate details of
configuring the Hypervisor to handle a VM with access to hardware required to
run an application that uses Wi-FI."
cover: /covers/image-file.png
author: pawel.langowski
layout: post
published: true
date: 2025-04-18
archives: "2025"

tags:
  - crosscon
  - hypervisor
  - arm
  - wifi
categories:
  - Virtualization
  - Security

---

## Introduction

CROSSCON is a project that focuses on cutting-edge security features for IoT
devices. You can find out more about the project in our recent
[blog post][crosscon-hv-post].

As explained in the aforementioned post, the CROSSCON Hypervisor (HV) is
responsible for managing access to hardware resources for virtual machines
(VMs), in which software is executed. This means that in order to run an
application inside a VM, the HV needs to configured so that every device used in
the app is available to the VM. This may post a significant challenge,
especially when dealing with libraries that do not explicitly list all the
required hardware. This post will explain how we dealt with those problems in
order to run a Zephyr application that connects to a specified Wi-Fi network.

The hardware used for this task was [LPCXPRESSO55S69][lpcxpresso] - a
development board with the `LPC55S6x` MCU based on the Arm Cortex-M33
architecture.

## Preparation

Before we got around to the task, much of the environment had already been
prepared. We had a working `Hello, world` Zephyr application that could be
deployed inside the Hypervisor. The Wi-Fi application had also been developed as
a baremetal application. Our task was to run it in the HV.

## First try - running the baremetal app inside a VM

The very first thing we tried was to simply flash the Hypervisor and Wi-Fi
application on the board and see if it works. The HV config defines the entry
points of virtual machines. The desired application needs to be flashed at the
address equal to the VM entry plus 1.

After building the application, you can check the address, where it will be
flashed by examining the `ELF` file:

```bash
readelf -aW zephyr.elf  | grep __start
  4942: 00045b15     0 FUNC    GLOBAL DEFAULT    2 __start
```

In this case, the VM entry point needed to be changed to `0x00045b14`:

```c
/* ZEPHYR VM */
.image = VM_IMAGE_LOADED(0x00040000, 0x00040000, 0x30000),
.entry = 0x00045b14,
(...)
```

The process of building the Hypervisor as well as flashing and debugging
software was performed inside a docker container. We used the
[LinkServer][linkserver] utility for flashing and debugging.

The Hypervisor configuration defined 2 VMs, labeled as `VM0` and `VM1`. `VM0`
ran an example application, which was not the object of our concern. Our
applications were executed in `VM1`. In order to flash it, `zephyr.elf` was
provided to the docker container under the name `vm1.elf`. Flashing the HV and 2
VMs was performed using the following commands:

```bash
LinkServer flash LPC55S69:LPCXpresso55S69 load bao.elf
LinkServer flash LPC55S69:LPCXpresso55S69 load vm0.elf
LinkServer flash LPC55S69:LPCXpresso55S69 load vm1.elf
```

The Hypervisor was executed by `gdb` with the help of `LinkServer`:

```bash
LinkServer gdbserver LPC55S69:LPCXpresso55S69 &
arm-none-eabi-gdb
(gdb) target remote :3333
(gdb) file bao.elf
(gdb) set $pc=_reset_handler
(gdb) c
```

The first attempt failed - the Hypervisor jumped into the exception handler:

```text
fault_exception_handler () at /workdir/bao-hypervisor/src/arch/armv8m/fault_exceptions.c:10
10          while (1) { };
```

## Strategy: Turning "Hello, world" into the Wi-Fi app

Without many leads, we tried a simple solution - the `Hello, world` application
mentioned before was working perfectly with the Hypervisor. The new strategy was
to transform the working code into our target application. The transition had to
be done with small steps to see what exactly causes the system to crash.

### Modifying the project configuration

Each Zephyr application defines its own configuration in a file named
`prj.conf`. The file is simply a Kconfig fragment, which defines
application-specific values for Kconfig options. Those values are then merged
with other settings to produce the final configuration. You can read more about
Zephyr application development [here][zephyr-app-development]

The `Hello, world` app was simple enough to have an empty `prj.config`. The
target application, though, was much more complex - it used, among others,
network drivers that needed to be enabled in Zephyr. The contents of `prj.conf`
for the Wi-Fi application are shown below:

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
`Helllo, world`'s `prj.conf` and build it. This was enough to trigger a build
error:

```text
zephyr/zephyr-sdk-0.17.0/arm-zephyr-eabi/bin/../lib/gcc/arm-zephyr-eabi/12.2.0/../../../../arm-zephyr-eabi/bin/ld.bfd: zephyr/zephyr_pre0.elf section `text' will not fit in region `FLASH'
zephyr/zephyr-sdk-0.17.0/arm-zephyr-eabi/bin/../lib/gcc/arm-zephyr-eabi/12.2.0/../../../../arm-zephyr-eabi/bin/ld.bfd: region `FLASH' overflowed by 35820 bytes
collect2: error: ld returned 1 exit status
ninja: build stopped: subcommand failed.
```

Something was off. The configuration, which worked fine for the original Wi-Fi
application, produced a flash memory overflow.

To understand the cause of the problem, we need to remember that the initial
application was configured to run without the Hypervisor. More precisely, it
used [upstream Zephyr][zephyr-upstream], which had less strict constraints on
the flash size.
<!--TODO: What exactly restricts the flash size on our/bao fork-->

The [fork][3mdeb-zephyr] on which we worked sets a lower flash size limit
because it also has to fit the Hypervisor.

We found a solution to this problem by disabling `CONFIG_NET_SHELL` - a shell
module that provides network commands. It was not needed in our application.

The application was built successfully, but it kept throwing runtime exceptions.
Our next goal was to add options to `prj.conf` one by one to see which one
breaks the execution.

The very first config - `CONFIG_NETWORKING=y` - was enough to cause an
exception. With that information we could start investigating. After comparing
config files from before and after enabling `CONFIG_NETWORKING`, we noticed the
some interesting configs that got enabled:

```diff
1301a1505,1506
> CONFIG_ENTROPY_DEVICE_RANDOM_GENERATOR=y
> # CONFIG_XOSHIRO_RANDOM_GENERATOR is not set
1302a1508,1510
> CONFIG_CSPRNG_ENABLED=y
> CONFIG_HARDWARE_DEVICE_CS_GENERATOR=y
> # CONFIG_CTR_DRBG_CSPRNG_GENERATOR is not set
```

Networking required access to the random number generator (RNG), which was not
granted to the VM by the Hypervisor.

Hardware access can be configured in the HV configuration. You can allow a VM to
use a device by modifying the `devs` field:

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

The memory map of the board can be found in the [user manual][board-manual].
The address of the RNG is shown below.

![img](/img/lpcxpresso-rng.png)

A quick look at the [device tree][dts] shows that the size of RNG's memory
region is `0x1000`:

```dts
	rng: rng@3a000 {
		compatible = "nxp,lpc-rng";
		reg = <0x3a000 0x1000>;
		status = "okay";
	};
```

Access was granted by modifying the HV config:

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
                         .size = 0x1000,
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

```
    at bao-hypervisor/src/arch/armv8m/mem.c:32
32                  ERROR("failed to register sau entry");
```

After discussing this with Bao, it turned out that there is a limit on SAU
entries, meaning that we had to many defined devices in the HV config. The
solution was simple - merge some of the `devs` in the config.

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

After these changes, we managed to run the `Hello, world` application with
`CONFIG_NETWORK` enabled. It was time to add the rest. After several tests we
determined that there was 2 more options that stopped the app from working -
`CONFIG_NET_LOG` and `CONFIG_LOG`. This time we had an idea why: The Wi-Fi
module communicates with the board using UART. The same UART header had
previously been used for serial communication with the VM. This may have caused
some conflicts that resulted in a crash. Luckily, we did not need to worry about
them, because the point of our task was to prove that we can run the application
in the Hypervisor. We didn't need serial logs for that - a simple GDB breakpoint
inside the application would have been enough. Therefore, we decided to disable
those configs. The `Hello. world` application was running correctly. It was time
to run the Wi-Fi app after our fixes.


## Back to Wi-Fi app

Disabling log configs meant modifying the code to make sure that there
are no calls to related libraries. After doing that, we were hoping to have a
working application. Unfortunately, we were not so lucky. The Hypervisor failed
to initialize the virtual machine.

```
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

We debugged the program to find the values of parameters passed to `memset`:

```
(gdb) p memset
$1 = {void *(void *, int, size_t)} 0x100015a6 <memset> 
(gdb) p dst 
$2 = (void *) 0x20023690 <z_interrupt_stacks> 
(gdb) p c 
$3 = 170 
(gdb) p n 
$4 = 2048 
```

We thought that perhaps the VM did not have access to memory under `dst`,
however a quick look at the HV config proved otherwise:

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

The address was within range. The problem lay elsewhere - the second entry in
`regions` defines flash memory addresses available to the VM. `memset`'s address
was `0x0005082a` - outside the range. After increasing the size to `0x20000`,
the issue was fixed.

With this config, no exceptions were being thrown. This was, however, not the
end of our problems. This time it seemed like the Hypervisor refused to run code
inside `VM1`. The application from `VM0` kept being executed and the HV never
switched to the Zephyr VM. The problem may have been related to the scheduler.
LPC uses `SysTick` to generate periodic interrupts. The Hypervisor uses those
interrputs to switch execution between virtual machines.

We tried setting a breakpoint inside the SysTick handler to diagnose the
problem.


```
175         mov r0, #SYSTICK_INT_N
(gdb) n
176         bl interrupts_handle
(gdb) p $r0
$9 = 15
(...)
interrupts_handle (int_id=15)
    at bao-hypervisor/src/core/interrupts.c:110
110             return HANDLED_BY_HYP;
(gdb)
113             ERROR("received unknown interrupt id = %d", int_id);
```

After examining the Armv8-M Architectural Reference Manual, it turned out that
ID 15 corresponds to the SysTick interrupt. It indicated that the context switch
between VMs was actually happening. To confirm this, we set a hardware
breakpoint at the last line before the HV switches to another VM.


```
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

Code from Zephyr was being executed, which confirmed that the switch was
happening. For some reason however, Zephyr executed the `idle` task instead of
our application.

```bash
author: pawel.langowski
```

> remove unused categories
> remember about newlines before lists, tables, quotes blocks (>) and blocks of
> text (\`\`\`)
> copy all post images to `blog/static/img` directory. Example usage:

![alt-text](/img/file-name.jpg)

> example usage of asciinema videos:

[![asciicast](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO.svg)](https://asciinema.org/a/xJC0QaKuHrMAPhhj5KMZUhMEO?speed=1)

> embed responsive YouTube player (copy the address after `v=`):

{{< youtube UQ-6rUPhBQQ >}}

> embed vimeo player (extract the `ID` from the video’s URL):

{{< vimeo 146022717 >}}

> embed Instagram post (you only need the photo’s `ID`):

{{< instagram BWNjjyYFxVx >}}

> embed Twitter post (you need the `URL` of the tweet):

{{< tweet user="3mdeb_com" id="1247072310324080640" >}}

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
[sign up for our newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html).
Don't let your hardware hold you back, work with 3mdeb to achieve more!

[crosscon-hv-post]: TODO
[lpcxpresso]: https://docs.zephyrproject.org/latest/boards/nxp/lpcxpresso55s69/doc/index.html
[linkserver]: https://www.nxp.com/design/design-center/software/development-software/mcuxpresso-software-and-tools-/linkserver-for-microcontrollers:LINKERSERVER
[zephyr-app-development]: https://docs.zephyrproject.org/latest/develop/application/index.html#overview
[zephyr-upstream]: https://github.com/zephyrproject-rtos/zephyr
[3mdeb-zephyr]: https://github.com/3mdeb/zephyr
[dts]: https://github.com/3mdeb/zephyr/blob/main/dts/arm/nxp/nxp_lpc55S6x_common.dtsi#L282

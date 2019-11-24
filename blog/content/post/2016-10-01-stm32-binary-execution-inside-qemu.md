---
layout: post
title: "STM32 binary execution inside QEMU"
date: 2016-10-01 14:01:37 +0200
comments: true
categories: stm32 qemu embedded
---

## Execution from STM32 side

1. Copy data segment initializers from flash to SRAM

```
Reset_Handler () at lib/startup_stm32f4xx.s:69
LoopCopyDataInit () at lib/startup_stm32f4xx.s:79
Reset_Handler () at lib/startup_stm32f4xx.s:73
LoopCopyDataInit () at lib/startup_stm32f4xx.s:79
(...)
```

2. Zero fill the bss segment
3. System initialization:
  * System clock source
  * PLL Multiplier
  * Divider factors
  * AHB/APBx prescalers 
  * Flash settings

  From code `src/system_stm32f4xx.c`:
    * Reset the RCC clock configuration to the default reset state
    * SetSysClock
5. main
## GDB notes

https://github.com/gdbinit/Gdbinit

set $ARMOPCODES = 0

```
arm
target remote :1234
```

Printing enum:

```
(gdb) p VERBOSITY_COMMON
$2 = VERBOSITY_COMMON
(gdb) p/d
$3 = 1
```

## TODO:

1. compile without optimization

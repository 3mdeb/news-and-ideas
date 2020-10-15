---
title: 'Trenchboot: Xen hypervisor support for the TrenchBoot'
abstract: 'In this blog post, we will describe the
           development of the Xen hypervisor support for TrenchBoot.'
cover: /covers/trenchboot-logo.png
author:
    - norbert.kaminski
    - marek.kasiewicz

layout: post
published: true
date: 2020-10-13
archives: "2020"

tags:
  - Trenchboot
  - Xen
  - firmware
  - AMD64
categories:
  - Firmware
  - Security

---

If you haven’t read previous blog posts from the TrenchBoot series, we strongly
encourage you to catch up on it. The best way is to search under the 
[TrenchBoot tag](https://blog.3mdeb.com/tags/trenchboot/). In this blog
post, we will describe the development of the Xen hypervisor support for
TrenchBoot.

## Global interrupt flag reinitialization

As we have mentioned in the previous 
[blog post](https://blog.3mdeb.com/2020/2020-09-07-trenchboot-multiboot2-support/),
until now the Landing Zone (LZ) has re-enabled the interrupts during the
multiboot. But why it has to be done?

`SKINIT` (Secure Init and Jump with Attestation) instruction securely
reinitializes the CPU and it allows startup of the trusted software such as
TrenchBoot. During the execution, the `SKINIT` clears the global interrupts flag
(GIF). The GIF is a bit that controls whether interrupts and other events can be
taken by the processor. During the boot, the Xen hypervisor tests non-maskable
interrupts (NMI). Disabled GIF causes the a panic error because the test could not
be performed:

```
(XEN) Platform timer is 14.318MHz HPET
(XEN) Detected 998.204 MHz processor.
(XEN)
(XEN) ****************************************
(XEN) Panic on CPU 0:
(XEN) Timed out waiting for alternatives self-NMI to hit
(XEN) ****************************************
```

[![asciicast](https://asciinema.org/a/onfFSMflnvwTyG1qguueyXCd8.svg)](https://asciinema.org/a/onfFSMflnvwTyG1qguueyXCd8)

The solution to this problem is to set again the GIF before the self-NMI
test. We used `STGI` (Set Global Interrupt Flag) instruction for this
purpose. We created the function in the secure virtual machine (SVM) header
file (`svm.h`):

```C
static inline void svm_stgi_pa(void)
{
    asm volatile (
        ".byte 0x0f,0x01,0xdc" /* STGI */
        : : : "memory" );
}
```

It calls `STGI` instruction that sets `GIF`. The function is called before the
self-NMI test in the `alternative.c`:

```C
    /* Set GIF flag */
    svm_stgi_pa(svm->vmcb_pa);
    printk(KERN_INFO "GIF is set \n");
```

As the result, the Xen hypervisor sets `GIF` and prints the debug information:

```
(XEN) Platform timer is 14.318MHz HPET
(XEN) Detected 998.144 MHz processor.
(XEN) GIF is set
```

With that change Xen hypervisor boots correctly:

[![asciicast](https://asciinema.org/a/B0STg9ldReLWdGucOgLW5R9ao.svg)](https://asciinema.org/a/B0STg9ldReLWdGucOgLW5R9ao)

## Checking if Xen was started by SKINIT

Following GIF reinitialization should be done only when the CPU was started with
SKINIT instruction. At first, we are checking if the CPU supports `SKINIT`
and `STGI` instruction. To this purpose, we are using the Processor
Identification (CPUID). `CPUID` functions provide information about the CPU
and its feature set. Every `CPUID` function consists of the function number and
the output register(s). For example, this is the function that holds information
about `SKINIT` support:

```
Fn8000_0001_ECX[SKINIT]
```

The number `8000_0001h` is the hexadecimal input value that is loaded to the `EAX`
register. `ECX` register is the output register. The 12th bit in the `ECX` contains
information about the `SKINIT` support. In the Xen source, `CPUID` instruction
is implemented in the `processor.h` file:

```C
static always_inline unsigned int cpuid_ecx(unsigned int op)
{
    unsigned int eax, ecx;

    asm volatile ( "cpuid"
          : "=a" (eax), "=c" (ecx)
          : "0" (op)
          : "bx", "dx" );
    return ecx;
}
```

The function takes the `CPUID` function number as an input. It calls `CPUID`
instruction and returns the `ECX` register. The following function is called in
the `alternative.c`. We are checking if the 12th bit of the `ECX` output
register is set:

```C
    if (cpuid_ecx(0x80000001) & 0x1000)
```

When we know that CPU supports `SKINIT`, we can safely determine
whether the Xen was started by this instruction. That fact is indicated by
the `R_INIT` bit in the `VM_CR MSR` register. This bit is set by the `SKINIT` 
and should be cleared after reading.

In code `VM_CR MSR` can be read by `rdmsrl` function which is a just wrap of the
assembly instruction `rdmsrl`. It reads the content of model specific registers.

```C
    /* Check is R_INIT bit set to determinate if xen was run by SKINIT */
    rdmsrl(MSR_K8_VM_CR, msr_content);
    if (msr_content & K8_VMCR_R_INIT)
    {
```

The R_INIT bit can be cleared with the following instructions:

```C
    if (msr_content & K8_VMCR_R_INIT)
    {
        printk(KERN_INFO "K8_VMCR_R_INIT is set \n");

        /* Clear INIT_R*/
        msr_content &= ~K8_VMCR_R_INIT;
        wrmsrl(MSR_K8_VM_CR, msr_content);
```

Before, the `R_INIT` bit was reset by LZ, but now it is cleared by Xen.
The following checks are shown in the previous
[asciinema](https://asciinema.org/a/B0STg9ldReLWdGucOgLW5R9ao).
Here are presented the Xen prints that indicate `SKINIT` check, and
reinitialization of the GIF:

```
(XEN) K8_VMCR_R_INIT is set
(XEN) GIF is set
```

The modified source code could be found in the
[3mdeb Xen fork](https://github.com/3mdeb/xen/tree/stable-4.14).
The changes are specified in the following
[pull request](https://github.com/3mdeb/xen/pull/2).

## Summary

In the next blog post, we will present the remote attestation system using
IETF RATS. So I encourage you to check our blog regularly.
If you have any questions, suggestions, or ideas, feel free to share them in
the comment section. If you are interested in similar content, I encourage you
to [sign up for our newsletter](http://eepurl.com/doF8GX).

---
title: 'Trenchboot: Xen hypervisor support for the TrenchBoot'
abstract: 'In this blog post, we will describe the
           development of the Xen hypervisor support for TrenchBoot.'
cover: /covers/trenchboot-logo.png
author:
    - norbert.kaminski
    - marek.kasiewicz

layout: post
private: false
published: true
date: 2020-10-15
archives: "2020"

tags:
  - Trenchboot
  - Xen
  - AMD
categories:
  - Firmware
  - Security

---

**EDIT 02.2021**: The blog post refers to the development stage of adding
Trenchboot support for the Xen hypervisor. The upstream changes are available in
the following commit:
<https://xenbits.xen.org/gitweb/?p=xen.git;a=commit;h=e4283bf38aae6c2f88cdbdaeef0f005a1a5f6c78>

If you haven’t read previous blog posts from the TrenchBoot series, we strongly
encourage you to catch up on it. The best way is to search under the
[TrenchBoot tag](https://blog.3mdeb.com/tags/trenchboot/). In this blog post, we
will describe the development of the Xen hypervisor support for TrenchBoot.

## Global interrupt flag reinitialization

As we have mentioned in the previous
[blog post](https://blog.3mdeb.com/2020/2020-09-07-trenchboot-multiboot2-support/),
until now the Landing Zone (LZ) has re-enabled the interrupts during the
multiboot. But why it has to be done?

`SKINIT` (Secure Init and Jump with Attestation) instruction securely
reinitializes the CPU and it allows startup of the trusted software such as
TrenchBoot. During the execution, the `SKINIT` clears the global interrupts flag
(GIF). The GIF is a bit that controls whether interrupts and other events can be
taken by the processor. Disabled GIF causes the a panic error, because the CPU
is not able to drop into NMI context. The CPU uses the NMI context to prevent
crashes during sensitive operations. The logs presented below shows the panic
error caused by cleared GIF bit:

```bash
(XEN) Platform timer is 14.318MHz HPET
(XEN) Detected 998.204 MHz processor.
(XEN)
(XEN) ****************************************
(XEN) Panic on CPU 0:
(XEN) Timed out waiting for alternatives self-NMI to hit
(XEN) ****************************************
```

[![asciicast](https://asciinema.org/a/liXmx7NmjsUqJrMiY4kriXaPy.svg)](https://asciinema.org/a/liXmx7NmjsUqJrMiY4kriXaPy)

The solution to this problem is to set again the GIF after execution of
`SKINIT`. We used `STGI` (Set Global Interrupt Flag) instruction for this
purpose. We created the function in the secure virtual machine (SVM) header file
(`svm.h`):

```bashC
static inline void svm_stgi(void)
{
    asm volatile (
        ".byte 0x0f,0x01,0xdc" /* STGI */
        : : : "memory" );
}
```

It calls `STGI` instruction this sets `GIF`. The function is called during the
CPU initialization, before the enabling NMIs in
[`common.c`](https://github.com/3mdeb/xen/pull/4/files#diff-1bebd72d2d87eeadb3d0df2d5448f3b3270f47245efd63a6a4c97a627be23ab5R912):

```bashC
    /* Set GIF flag */
    svm_stgi();
```

With this change Xen hypervisor boots correctly:

[![asciicast](https://asciinema.org/a/lLeQntnMKGudN5t8gOyT1wTv1.svg)](https://asciinema.org/a/lLeQntnMKGudN5t8gOyT1wTv1)

## Checking if Xen was started by SKINIT

Following GIF reinitialization should be done only when the CPU was started with
`SKINIT` instruction. The `SKINIT` is a specific instruction for AMD CPUs, so
first we check if the processor is AMD:

```bashC
    cpuid(0, &eax, (uint32_t *)&id[0], (uint32_t *)&id[8],
        (uint32_t *)&id[4]);
    if ((memcmp(id, "AuthenticAMD", 12) == 0) &&
```

To this purpose, we are using the Processor Identification (CPUID). `CPUID`
functions provide information about the CPU and its feature set. Every `CPUID`
function consists of the function number and the output register(s). We will
explain `CPUID` function at the example. When we are sure that processor is AMD,
we can check if the CPU supports `SKINIT` and `STGI` instruction. Following
`CPUID` function holds information about `SKINIT` support:

```bash
Fn8000_0001_ECX[SKINIT]
```

The number `8000_0001h` is the hexadecimal input value that is loaded to the
`EAX` register. `ECX` register is the output register. The 12th bit in the `ECX`
contains information about the `SKINIT` support. In the Xen source, `CPUID`
instruction is implemented in the `processor.h` file:

```bashC
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
instruction and returns the `ECX` register. The following function is called
during validation. We are checking if the 12th bit of the `ECX` output register
is set:

```bashC
    if ((memcmp(id, "AuthenticAMD", 12) == 0)
            && (cpuid_ecx(0x80000001) & 0x1000))
    {
```

When we know that CPU supports `SKINIT`, we can safely determine whether the Xen
was started by this instruction. That fact is indicated by the `R_INIT` bit in
the `VM_CR MSR` register. This bit is set by the `SKINIT` and should be cleared
after reading.

In code `VM_CR MSR` can be read by `rdmsrl` function which is a just wrap of the
assembly instruction `rdmsrl`. It reads the content of model specific registers.

```bashC
    /* Check is R_INIT bit set to determinate if xen was run by SKINIT */
    rdmsrl(MSR_K8_VM_CR, msr_content);
    if (msr_content & K8_VMCR_R_INIT)
    {
```

The R_INIT bit can be cleared with the following instructions:

```bashC
        if (msr_content & K8_VMCR_R_INIT)
        {
            printk(KERN_INFO "K8_VMCR_R_INIT is set \n");

            /* Clear INIT_R*/
            __cpu_SKINIT = true;
            msr_content &= ~K8_VMCR_R_INIT;
            wrmsrl(MSR_K8_VM_CR, msr_content);
```

Previously, the `R_INIT` bit was reset by LZ. The `R_INIT` is replaced with
`__cpu_SKINIT` flag.

The changes are specified in the following
[pull request](https://github.com/3mdeb/xen/pull/3).

## Summary

In the next blog post, we will present the remote attestation system using IETF
RATS. So I encourage you to check our blog regularly. If you have any questions,
suggestions, or ideas, feel free to share them in the comment section. If you
are interested in similar content, I encourage you to sign up for our
newsletter:

{{< subscribe_form "3160b3cf-f539-43cf-9be7-46d481358202" "Subscribe" >}}

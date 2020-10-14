---
title: 'Trenchboot: Xen hypervisor support for the TrenchBoot'
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/trenchboot-logo.png
author:
    - marek.kasiewicz
    - norbert.kaminski

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
encourage you to catch up on it. The best way is to search under the TrenchBoot
tag. In this blog post, we will describe the development of the Xen hypervisor
support for TrenchBoot.

## Global interrupt flag reinitialization

As we have mentioned in the previous blog post, since now the LZ has re-enabled
the interrupts during the multiboot. As indicated in the
[documentation](https://www.amd.com/system/files/TechDocs/24593.pdf#G21.1088220)
the global interrupts flag (GIF) is a bit that controls whether interrupts and
other events can be taken by the processor. It is cleared during the SKINIT
boot. When the GIF is not set again, the Xen hypervisor will not able to
perform the self-NMI test:

```
(XEN) Platform timer is 14.318MHz HPET
(XEN) Detected 998.204 MHz processor.
(XEN)
(XEN) ****************************************
(XEN) Panic on CPU 0:
(XEN) Timed out waiting for alternatives self-NMI to hit
(XEN) ****************************************
```

The solution to this problem is to set again the GIF before the self-NMI
test. We have used STGI instruction for this purpose. We have created the
function in the secure virtual machine (SVM) header file (`svm.h`):

```C
static inline void svm_stgi_pa(paddr_t vmcb)
{
    asm volatile (
        ".byte 0x0f,0x01,0xdc" /* STGI */
        : : "a" (vmcb) : "memory" );
}
```

The function takes a virtual machine control block (VMCB) address as the input.
The STGI is called before the self-NMI test in the `alternative.c`.
To obtain the information about the VMCB address, we are creating the pointer
to the SVM structure for the current vcpu:

```C
    struct vcpu *v = current;
    struct svm_vcpu *svm = &v->arch.hvm.svm;
```

And then we are setting the GIF:

```C
    /* Set GIF flag */
    svm_stgi_pa(svm->vmcb_pa);
    printk(KERN_INFO "GIF is set \n");
```

As the result, the Xen hypervisor sets GIF and prints the debug information:

```
(XEN) Platform timer is 14.318MHz HPET
(XEN) Detected 998.144 MHz processor.
(XEN) GIF is set
```

## Checking if Xen was started by SKINIT

To determine whether the Xen was started by the SKINIT instruction the R_INIT
bit in the VM_CR MSR register can be checked. This bit is set by SKINIT command
and should remain set until we read it.

In code VM_CR MSR can be read by rdmsrl function which is a just wrap of the
assembly instruction rdmsr, which reads the content of model specific registers.

```C
    rdmsrl(MSR_K8_VM_CR, msr_content);
    if(msr_content & K8_VMCR_R_INIT)
    {
        /* Xen was started by SKINIT */
    }
```

The R_INIT bit can be reset with usage of following instructions:
```C
    rdmsrl(MSR_K8_VM_CR, msr_content);
    msr_content &= ~K8_VMCR_R_INIT;
    wrmsrl(MSR_K8_VM_CR, msr_content);
```
Before, this bit was reset by LZ, but now it is reset in `alternative.c`,
right after setting GIF. The exact place if the reset could be moved, but it will
remain in Xen.

## Summary

If you have any questions, suggestions, or ideas, feel free to share them in
the comment section. If you are interested in similar content, I encourage you
to [sign up for our newsletter](http://eepurl.com/doF8GX).

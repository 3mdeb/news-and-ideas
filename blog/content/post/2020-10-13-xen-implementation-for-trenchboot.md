---
title: Trenchboot: Xen hypervisor support for the TrenchBoot
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

If you haven’t read previous blog posts from TrenchBoot series, we strongly
encourage to catch up on it. Best way, is to search under TrenchBoot tag.
In this blog posts we will describe development of the Xen hypervisor support
for TrenchBoot.

## Global interrupt flag reinitialization

As we have mentioned in the previous blog post, since now the LZ has re-enable
the interrupts during the multiboot. As it is referred in the
[documentation](https://www.amd.com/system/files/TechDocs/24593.pdf#G21.1088220)
the global interrupts flag (GIF) is a bit that control whether interrupts and
other events can be taken by the processor. It is cleared during the SKINIT
boot. When the GIF is not set again, the Xen hypervisor will not able to
preform self-NMI test:

```
(XEN) Platform timer is 14.318MHz HPET
(XEN) Detected 998.204 MHz processor.
(XEN)
(XEN) ****************************************
(XEN) Panic on CPU 0:
(XEN) Timed out waiting for alternatives self-NMI to hit
(XEN) ****************************************
```

The solution of this problem is to set again the GIF before the self-NMI
test. We have used the STGI instruction to this purpose. We have created the
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
to SVM structure for current vcpu:

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

As the result the Xen hypervisor sets GIF and prints the debug information:

```
(XEN) Platform timer is 14.318MHz HPET
(XEN) Detected 998.144 MHz processor.
(XEN) GIF is set
```

## Checking if Xen is started with SKINIT

## SIPI initialization of Application Processor


## Summary

If you have any questions, suggestions, or ideas, feel free to share them in
the comment section. If you are interested in similar content, I encourage you
to [sign up for our newsletter](http://eepurl.com/doF8GX).
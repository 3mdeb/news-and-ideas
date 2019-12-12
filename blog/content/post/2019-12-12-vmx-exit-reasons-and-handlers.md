---
title: 'VMX exit reasons and handlers'
abstract: 'After long break, this is the third post in the hypervisor series.
          We will see how VMX helps with virtualization of restricted
          instructions and how Bareflank allows for implementation of handlers
          for them. At the end we will show how to write and add our own
          handler.'
cover: /covers/hypervisors.png
author: krystian.hebel
layout: post
published: true
date: 2019-12-12
archives: "2019"

tags:
  - hypervisor
  - virtualization
  - bare-metal
  - VMX
categories:
  - Firmware

---

This post is split into three sections. The first one is an overview of VMX
support for exiting on events that require hypervisor action, then we will take
a look at the implementation in Bareflank, and last but not least we will write
our own handler.

Previous posts:

1. [5 terms every hypervisor developer should know](https://blog.3mdeb.com/2019/2019-04-30-5-terms-every-hypervisor-developer-should-know/)
   \- very basic theory of VMX
2. [Building and running Bareflank](https://blog.3mdeb.com/2019/2019-05-15-building-bareflank/)
   \- instructions for building and running Bareflank-based hypervisor on a UEFI
   platform

## VMX operation

Virtualization wouldn't be possible without hardware support. The processor must
be able to switch to a privileged mode when code in VM tries to execute an
instruction that can mess up virtualization.

### Exit reasons

Many events and instructions can result in VM exit. Some of them are always
enabled, others can be controlled by control fields of VMCSs. Support for them
vary with processor family, they can be discovered by reading VMX capability
MSRs (index 480h and following).

Unconditional reasons for VM exit include:

* CPUID
* RDMSR and WRMSR unless MSR bitmap is used
* most of VMX instructions
* INIT signal
* SIPI signal - does not result in exit if the processor is not in wait-for-SIPI
  state
* triple fault
* task switches (hardware, including
* VM entry failure

There are too many controllable exit reasons to describe each one separately,
but most of them can be classified as one of:

* interrupts or interrupt windows
* I/O ports access
* memory access - controlled by EPT
* HLT/PAUSE and pre-emption timer - useful for multiple VMs running on one
  physical CPU
* changes to descriptor tables and control registers
* APIC access

Exit reason is reported in VMCS after VM exit, along with exit qualification
when necessary.

An important feature added to improve performance is the virtualization of
interrupts and APIC. As not all accesses to APIC space results in immediate
interrupt, there can be a virtual APIC page. All writes go to this page instead
of resulting in VM exit on every access. Only the interrupt itself needs to be
run from root operation mode unless it is self-IPI - it can also be virtualized
without an exit, as it is limited to one VM. Similarly, not every change in
control registers needs to be processed by VMM so they can be masked in VMCS.

### Handlers

Handlers for various exit reasons are the most important part of hypervisors.
They can emulate some hardware accesses and pass through the rest of them to
the hardware, possibly modifying them along the way.

Almost all VM exits are like faults when compared to normal IA-32 interrupts -
state from **before** exiting instruction is saved, none of the results is
stored and saved RIP points to that instruction. Unlike interrupts, the size of
instruction is also saved so it can be skipped easily if needed.

An example of a trap-like VM exit (when a state **after** exiting instruction
is saved) is APIC write. Usually there are multiple writes to APIC memory (or
MSRs in the case of x2APIC) that only describe an interrupt that will happen
later. It is possible to virtualize APIC accesses - data is written to a
remapped, virtual APIC page without causing VM exits. Trap-like delivery of
this exit reason makes it possible to read all the necessary information from
the virtual APIC page, instead of parsing the last write instruction manually.

VMCS does not have fields for general purpose registers - only RIP, RSP,
control, segment and system table registers are saved. This is done because not
every register will be used by every handler, and saving them takes time, so for
performance reasons hypervisors may choose to save this data only when it is
necessary.

In VMX, there is only one entry point to the VMM. It is up to the VMM code to
read exit reason from VMCS and act accordingly. This entry point is written to
the host-state area of VMCS, along with other host registers (RSP, control,
segment and system table registers - the same set that was saved for guest
state).

After handler finishes, the guest state is restored from VMCS on VMRESUME
instruction. Some sanity checks are performed. Events like interrupts might be
injected at this point to the guest. Note that the state written to the VMCS
might be changed by a handler.

## Bareflank implementation

Once again, Bareflank is an SDK. As such, it sometimes puts ease of use and
ability to tailor hypervisor implementation to one's needs above performance.

All of the CPU general-purpose registers are saved on every VM exit, even if
they are not used. This doesn't result in too big performance impact, taking
into account that higher-level languages (C, C++) can be used thanks to that.

VM exit for every reason follows the same path initially. It is possible to add
handlers for all exit reasons, an option useful for counting exit reasons, but
it can impact performance heavily - do not even think about printing every exit
reason through UART.

Multiple handlers can be added for every exit reason. They return Boolean value
describing whether exit reason was successfully handled by this function or not,
or, in other words, if the next handler in a queue should be run. Handlers are
called in reverse order than that in which they are added. This is important for
at least two reasons: a) more specific handlers must be added after generic one,
and b) most often hit handler should be added as the last one.

Interrupt delivery is another place where ease of implementation won with
performance considerations. Using default API, events are not directly injected.
Instead, they are added to the queue and VM exit on interrupt window (see below)
is enabled. Bareflank does not check if interrupt can be injected at the moment,
so it ends up with an additional trip to the VM and back. Every transition takes
hundreds of clock cycles, some more are required for VMM code. It does,
however, allow for easy queuing of events, and helps with a situation when
multiple events are being injected on one VM entry. For rationale and better
explanation see note in [interrupt_window.cpp](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfvmm/src/hve/arch/intel_x64/vmexit/interrupt_window.cpp#L47).

> Interrupt window is a period in which CPU can receive external interrupts.
> They can be received only when RFLAGS.IF = 1, but they are also inhibited for
> one instruction after STI or MOV/POP SS.

### API

Keep in mind that we are looking at almost a year-old code. It is most likely no
longer valid, but I don't want to change to newer code in the middle of these
series of blog posts to avoid confusion. This isn't a full description of API by
any means, it is just a list of methods from [vcpu.h](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfvmm/include/hve/arch/intel_x64/vcpu.h)
which we will be using, along with some of my personal notes.

```
vcpu::advance()
```

> Advances the vCPU. Always returns true

As said earlier, most of the VM exits are fault-like. Some of them would result
in another VM exit when re-run. This small-but-potent function patches guest RIP
in VMCS by adding the instruction size to it. It is usually used as
`return vcpu->advance()` in handlers, hence the return value.

```
vcpu::dump(const char *str)
```
> Outputs the state of the vCPU with a custom header

Prints general-purpose registers, control registers, guest address (both linear
and physical), exit reason and exit qualification.

```
vcpu::add_exit_handler(const handler_delegate_t &d)
```

> Adds an exit function to the exit list. Exit functions are executed
> right after a vCPU exits for any reason. Use this with care because
> this function will be executed a lot.
>
> Note the return value of the delegate is ignored

More about delegates below.

```
vcpu::add_handler(::intel_x64::vmcs::value_type reason,const handler_delegate_t &d)
```

> Adds an exit handler to the vCPU

Generic way of adding handlers for all defined reasons. Bareflank's names for
exit reasons can be found in [32bit_read_only_data_fields.h](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfintrinsics/include/arch/intel_x64/vmcs/32bit_read_only_data_fields.h#L155).
For most common exit reasons (or those requiring some additional work) there
are specialized `add_*_handler()` methods.


```
vcpu::add_io_instruction_handler(
    vmcs_n::value_type port,
    const io_instruction_handler::handler_delegate_t &in_d,
    const io_instruction_handler::handler_delegate_t &out_d)
```

This method, apart from adding a handler for exit reason, also enables exiting
on given port by setting the appropriate bit in I/O bitmaps. Separate handlers
can be defined for read and write operations. Notice that it uses a different
type for handler delegate - more about it later.

```
vcpu::add_default_io_instruction_handler(const ::handler_delegate_t &d)
```

Nothing special about this particular adder, I just listed it to show that some
exit reasons have default handlers. Those are called if all other handlers
returned `false`.

```
vcpu::trap_on_msr_access(vmcs_n::value_type msr)
```

> Sets a '1' in the MSR bitmap corresponding with the provided msr. All
> attempts made by the guest to read/write from the provided msr will be
> trapped by the hypervisor.

Helper function that enables exiting without installing a new handler. Might be
used along with `pass_through_msr_access()` to toggle exiting. If run without
installing a handler, the default handler is used.

### Handlers, delegates and info

VM exit lands in [exit_handler_entry.asm](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfvmm/src/hve/arch/intel_x64/exit_handler_entry.asm)
initially, where it just saves guest values of registers and calls
`exit_handler::handle()` from [exit_handler.cpp](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfvmm/src/hve/arch/intel_x64/exit_handler.cpp#L727).
At the point of merging EAPIs to the main tree, this was done with some
assumptions about name mangling, it is no longer the case in newer code.

Apart from exception handling and dumping CPU state in case of not handled exit
reason, this function performs two loops:

```
        for (const auto &d : exit_handler->m_exit_handlers) {
            d(exit_handler->m_vcpu);
        }

        const auto &handlers =
            exit_handler->m_exit_handlers_array.at(
                exit_reason::basic_exit_reason::get()
            );

        for (const auto &d : handlers) {
            if (d(exit_handler->m_vcpu)) {
                exit_handler->m_vcpu->run();
            }
        }
```

First one calls **all** of the delegates added with `vcpu::add_exit_handler(const handler_delegate_t &d)`.
The other one goes through the delegates for the appropriate reason. Note that
only the second loop checks for a return value of delegate and calls `vcpu::run()`
when `true` is returned. Without going into too many details, this results in VM
entry.

Most VM exits provide more information than just an exit reason. In such a case,
it makes sense to use that information to reduce the number of delegates called.
For example, on exits due to I/O port accesses, port number and direction of
access (in or out) is saved. So, instead of calling final delegates directly,
another layer is added, and a handler from [io_instruction.cpp](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfvmm/src/hve/arch/intel_x64/vmexit/io_instruction.cpp#L128)
is called. It is responsible for filling `info_t` structure for final handlers,
dealing with string instructions and `rep` prefixes and calling `handle_in()` or
`handle_out()`, depending on the direction. Only then user-implemented handlers
are called in a similar way to the second loop listed above, but only for the
given port number. If there are no valid handlers for that port (i.e. handlers
that return `true`), a default one (added with
`vcpu::add_default_io_instruction_handler()`) is called.

For I/O, user handlers use delegates in form of `bool handler_name(vcpu *, info_t &)`,
where `info_t` is defined in [io_instruction.h](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfvmm/include/hve/arch/intel_x64/vmexit/io_instruction.h#L66)
as (original comments removed for clarity - check them for description and
default values; my warnings added instead):

```
    struct info_t {
        uint64_t port_number;
        uint64_t size_of_access;
        uint64_t address;        // For string instructions only. Remember that
                                 // VMM and VM might use different address space.
        uint64_t val;
        bool ignore_write;
        bool ignore_advance;     // Use this field instead of calling vcpu->advance()
                                 // directly or watch as the world burns after
                                 // rep-prefixed instructions. Learned it the
                                 // hard way.
    };
```

That example was specific for I/O operations, other exit reasons use different
logic in handlers. Internals of them isn't usually important, but for curious,
they can be found in [vmexit](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfvmm/src/hve/arch/intel_x64/vmexit)
directory. What is important, `info_t` and delegate function type is different
for other exit reasons. Both of them can be found in another [vmexit](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfvmm/include/hve/arch/intel_x64/vmexit)
directory, in header files for appropriate exit reasons.

## Our very own handler

Using I/O as an example above wasn't a coincidence. We are going to play with
UART output (port 0x3f8), as it is relatively safe and pretty easy to test. We
will start with some simple modifications to the strings printed, like inverting
case of every printed letter.

### Where to start

Now, the proper way would be to create another directory and showing Cmake that
it should use it. As we are building on top of the EFI target from the
[previous post](https://blog.3mdeb.com/2019/2019-05-15-building-bareflank/),
adding code to [test_efi.cpp](https://github.com/Bareflank/hypervisor/blob/ba613e2c687f7042bac6886858cf6da3132a61d6/bfvmm/integration/arch/intel_x64/efi/test_efi.cpp)
is much easier, especially for someone who is not experienced in Cmake.

This file contains a minimal constructor for vCPU. Those two calls are used to
set up EPT, suffice it to say EPT is required for Bareflank on top of UEFI (more
about it in the next posts). This is where we are going to add our own handlers:

```
explicit vcpu(vcpuid::type id) :
        bfvmm::intel_x64::vcpu{id}
    {
        bfn::call_once(flag, [&] {
            ept::identity_map(
                g_guest_map,
                MAX_PHYS_ADDR
            );
        });

        this->set_eptp(g_guest_map);

        this->add_io_instruction_handler(
            0x3f8,  // port number
            io_instruction_handler::handler_delegate_t::create<vcpu, &vcpu::in_handler>(this), // read handler
            io_instruction_handler::handler_delegate_t::create<vcpu, &vcpu::out_handler>(this) // write handler
        );
    }
```

That wasn't too hard, right? Now, let's move to implementing those delegates,
starting with the read handler. We need to do so even though we won't do
anything in this handler, as there is no way to enable exiting on writes, but
not on reads for the given port. Delegates can be private members of vcpu class:

```
private:
    bool in_handler(gsl::not_null<bfvmm::intel_x64::vcpu *> vcpu,
                    io_instruction_handler::info_t &info)
    {
        return true;
    }

```

That's it, thanks to sane default values of `info_t` - neither read nor advance
is ignored, so the instruction behaves as expected.

### First modification - no output

This one is also easy. Remember `write_value` in `info_t`? Just set it to `true`
and we're done. The value will not be sent through this port anymore from the VM
(Bareflank can still print its messages with e.g. `bfdebug_info()`).

```
    bool out_handler(gsl::not_null<bfvmm::intel_x64::vcpu *> vcpu,
                    io_instruction_handler::info_t &info)
    {
        info.ignore_write = true;
        return true;
    }
```

To test it, follow instructions from the [previous post](https://blog.3mdeb.com/2019/2019-05-15-building-bareflank/).
Compare output from VGA and serial.

### Second modification - case swap

This one seems easier than it is, actually. Starting with a naive approach:

```
    bool out_handler(gsl::not_null<bfvmm::intel_x64::vcpu *> vcpu,
                    io_instruction_handler::info_t &info)
    {
        if (info.val >= 'A' && info.val <= 'Z') {
            info.val += 'a' - 'A';
        }
        else if (info.val >= 'a' && info.val <= 'z') {
            info.val -= 'a' - 'A';
        }
        return true;
    }
```

This kinda works, everything we type is case-swapped, but after pressing the
return key Bad Things™ happen...

#### Second modification - revised

The issue is that UEFI uses [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code)
to move around the screen. From table with [terminal output sequences](https://en.wikipedia.org/wiki/ANSI_escape_code#Terminal_output_sequences)
we can read that those sequences start with `ESC [`, followed by some non-alpha
sequence (zero or more decimal numbers and possibly a semicolon), followed by a
single letter. This means that we must pass everything from the initial `0x1B`
byte (`ESC`) up to and including first letter character unchanged.

At the very beginning of `out_handler()` add:

```
        static bool is_escape_code = false;

        // escape codes - do not modify them
        if (info.val == 0x1B) {
            is_escape_code = true;
            return true;
        }

        if (is_escape_code) {
            if ((info.val >= 'A' && info.val <= 'Z') ||
                (info.val >= 'a' && info.val <= 'z')) {
                    is_escape_code = false;
            }

            return true;
        }
```

### Other possibilities

We presented some more modifications at Embedded World 2019:

[![asciicast](https://asciinema.org/a/228849.svg)](https://asciinema.org/a/228849?speed=1)

Note that this demo included also a handler for CPUID instruction to enable
changing current modification on-the-fly, as well as custom UEFI application for
performing those instructions. There is also a video from booting Ubuntu with
all of its output ROT13-ed:

[![asciicast](https://asciinema.org/a/228858.svg)](https://asciinema.org/a/228858?speed=1)

Those and possibly more handlers are left as an exercise for the readers :)

## Summary

We just scratched the surface of possibilities given by a bare-metal hypervisor.
While our hypervisor doesn't give the ability to run multiple VMs (yet), it
gives us control over what can or cannot be done on a hardware level.

Even such basic handlers can be useful. Imagine that you have a closed-source
driver and you want to discover how it initializes hardware. Installing simple
handlers with debug output for each I/O port access can be faster than
disassembling a binary.

I hope that it will encourage at least some people to follow this subject
further. Even though this is the longest post in series so far, I'm far from
explaining everything I promised in the summary previously. Hopefully, next
posts will be more regular.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD).

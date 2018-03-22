---
post_title: The art of disassembly
author: Bartek Pastudzki
post_excerpt: ""
layout: post
published: true

---
# The art of disassembly

Probably there was never a programming language that would
fascinate me as much as assembly. In fact, it was my second
"real language" (after Pascal/Delphi and DOS batch) and the
first one I would really understand. Of course, the internals of
protected mode initialization was too much for 15-year-old
and I finally moved to C and *nix shell. Anyway, I always
liked the feeling that I know what I'm really doing but more
complex languages are needed nowadays.

Having tried almost any popular language out there I enjoy
getting to very foundations of software and working with
disassembly every now and then. Reverse engineering and low
level debugging are pretty obvious applications for
disassembly, but having worked with it a little bit more
I came to the conclusion that power of working on that level is
much more. 

# What can we get?

I've noticed that with good knowledge of environment we are
working with and right tools assembly code might be much
handier than getting through spaghetti code. There are
two reasons for that.

The first reason is that when we've got binary, we've got
everything explicitly specified inconsistent address space.
While working with multi-platform code (like coreboot, Linux
kernel or EDK2) it's sometimes hard to tell which
implementation of the same function would be actually used,
because it's decided inbuilt system, based on distributed
configuration. In disassembly, we usually have only code
actually used and every reference is quite clear.

Of course, in most cases, we have some sort of external code —
dynamic libraries, system calls, UEFI services. They are
external for a reason though. Also, their meaning is clearly
specified so we may treat those calls as the black box. Another
time we may use it to reason where data come in and out.

The second reason is that assembly language is very simple. It
makes it very hard to code in, but very easy to interpret
automatically. One line per instruction. Most of the instructions
follow the same pattern — one operand read-only, the other
is modified according to it. It took me some 350 LOC in AWK
to take disassembly and tell for a jumpless piece of code how
data in registers and memory changes. Where possible, actual
values appear, where value depends on initial value, the complete
transformation is recorded. Of course, it's only prototype and
more advanced instructions are not yet supported, but it's
already promising. With proper jump support, we could reduce
multiple control switches into a minimal set of transformations
for given goal, even separate it from the rest of code.
However far it would go, doing a similar thing with higher
level language seems many times more complex.

For fuller and more reliable and efficient implementation
Capstone-Keystone-Unicorn tools could be used. We may also
consider QEMU (which allows us to dump all ongoing operations
and changing state) and GDB integration. When something
simpler is needed we may consider `mprotect()` Linux call
for runtime code rebuilding and analysis.

# How to start?

Actually, this concept is based on very simple things. They
may seem distant and abstract because nowadays they are
typically covered with multiple layers of abstraction but
machine code execution and organization are quite
straightforward. I believe that knowing their principles can
help in navigating through modern overly complex systems
and getting a broader understanding of computing.

Of course, x86 instruction set is quite broad and sometimes
introduce very complex mechanisms. However for understanding
how computations are divided into independent pieces and how
do they communicate we need just to scratch the surface. Same
with memory and process management — there is the complex theory
behind them, but interface we get from the OS is relatively
easy.

We have CPU — computation unit and RAM for temporary data
storage. We are usually separated from all other devices but
we use OS interface, which reuses concepts we use for
those two. Generally speaking, everything that happens in 
a computer is series of passing data between components and
transforming them in between.

For example, when we display a web page we can think of it:

1. we have given an address in memory.
2. transform it into request conforming standard.
3. pass a request to the networking device
4. accept response
5. transform text into an image
6. pass the image to graphics card

The job of application is just to transform the data and
inform OS where is the product, what it is and where to pass
it. RAM is a medium for that exchange as well as storage for
middle products. RAM also store instructions how to perform
those transformations. Assembly language is a textual
representation of codes understood by CPU.

# Memory

We can think of RAM as a function. Every byte in memory has
its ordinal number. We use it to read or change its value.
Bytes are usually accessed in groups of 4(32bit) or 8(64-bit).

X86 CPU never two such groups at a time, that's why it has
own memory called registers. In modern x86 architecture, there
are 16 64-bit general purpose registers called: RAX, RBX,
RCX, RDX, RDI (destination index), RSI (source index),
RBP (base pointer), RSP (stack pointer), R8-R15. Despite
meaningful names of some, only RSP preserved special
meaning (it was important when it was usual to code directly
in assembly). "R" letter in beginning denote its 64-bits as
during 40 years of x86 evolution registers grown from 16-bit
(AX, BX, etc), to 32-bit (EAX, EBX, etc). Among special
registers, we have RIP (instruction pointer) stores pointer
(= ordinal number in memory) of next instruction to run and
EFLAGS which register special situations (like zeroing
register or overflow while adding). Those special registers
are never accessed directly.

To move data between registers and memory is called `MOV`.
Example:

```assembly
	mov $0xff, %rax
```

which load constant value 0xff to RAX register. This form of
assembly language is called AT&T and mainly widespread in
GNU world. Other popular is Intel Syntax. The most important
difference is argument order and lack of sigils:

```assembly
	mov rax, 0xff
```

In this document, I use AT&T syntax. Other variants:

```assembly
	mov %rax, %rbx    # RAX -> RBX
	mov %rbx, (%rax)  # RBX -> memory pointed in RAX
	mov 3(%rcx), %rax # RAX <- memory pointed in RCX+3
	movb $0xde, (%rdx) # 0xde-> memory pointed in RDX
	movq $0xde, (%rdx) # same, but zeroes other 7 bytes
	mov %ax, my_val   # 16-bit from AX to labeled memory
	mov my_val, %ebx  # 32-bits from my_val to EBX
	move 0xfffe, (%rax, %rbx) # 0xfffe - RAX+RBX mem
```

Note that labels in machine code are just constants. Labels
are for programmers convenience. Remembering addresses for
every little thing would be hard, but it's not the only
reason. In modern OS controlled code must not access any
address without OSs permission. Labels mark places allocated
at program loading. It has initial value:

```assembly
my_val: .asciz "Hello World!" # C-like string
another: .ascii "What's up?" # without '\0' ending
.comm buff, 64 # 64-byte 0-initialized buffer
```

For pointer loading, there is other set instruction: `LEA`
(Load Effective Address):

```assembly
    lea my_val, %rax      # myval -> RAX
    lea 5(%rbx), %rax     # RBX+5 -> RAX
    lea (%rax,%rsi), %rcx # RAX+RSI -> RCX
```

# Transformations

There are many instructions for data transformations.
Among the most popular:

```assembly
    add $5, %rax      # RAX = RAX + 5
    add (%rbx), %rdi  # RDI = mem(RBX) + RDI
    sub 2(%rax), %rbp # RBP = RBP - mem(RAX+2)
    xor 0xff00, %rax  # RAX = bitwise_xor(RAX, 0xff00)
    and 0xf000, %rbp  # RBP = bitwize_and(RBP, 0xf000)
    xor %rax, %rax    # optimized RAX = 0
```

There are many more of them, but most common of them follow
the same pattern. That's why it's quite easy to automatically
trace value changes. Some instructions have implicit
parameters, however still, we need just encode exception.
Example:

```assembly
	mul %rcx # RDX:RAX = RAX * RCX
	div %rbx # RAX = RDX:RAX / RCX# RDX = reminder
```

`RDX:RAX` means 128-bit value with higher 64-bits in `RDX`
and other in `RAX`. Such a solution let us never lose data
due to overflow. On the other hand, cause a pitfall of `DIV`
instruction — if the operand is not enough to make result 64-bit
or operand is 0 — CPU exception is issued (mentioned later).

There are also special instructions and registers for floating
point arithmetics, for matrix operations, and some reserved
ones only for OS/firmware code, among others to communicate
with other devices. And configure protection mechanisms.

# Jumps

Of course, we can execute an instruction not in an order using
jumps.

```assembly
	jmp foo    # RIP = foo (label position)
	jmp (%rax) # RIP = RAX
```

Most of the jumps are relative to current RIP position. Thanks
to this OS can load our program at any point in memory.
Similarly, once compiled function can be placed at any point
of program binary.

```assembly
loop:
	add $5, %rax
	jmp loop     # while(1) RAX+=5
```

will disassemble as:

```assembly
  40007b:	48 83 c0 05          	add    $0x5,%rax
  40007f:	eb fa                	jmp    40007b <loop>
```

Disassembly shows whole address, but when we look at the machine
codes, jump takes only two bytes so it can't be absolute
address. 0xEB encodes relative jump and another byte is 8-bit
signed offset coded so that highest bit means -0x81 instead
of 0x80 so 0xfa = -0x80 + 0x8a = -0x06, which is length of
both instructions.

# Conditionals

We can also make conditional jumps. `EFLAGS` register is
used for that. For example, if we call

```assembly
	sub $5, %rax
```

except substracting `RAX`, specific bit of `EFLAGS` will
be set to 1 if %rax will become 0 (ie. was 5 in the first
place) and other if it becomes negative. There are
instructions that make jump according to `EFLAGS` bits
and special `CMP` instruction which sets `EFLAGS` like `SUB`
but doesn't store the result. Similarly `TEST` does `AND`
without storing the result (usually used for bit fields).

```assembly
cmp $5, %rax
je  equals   # jmp equals if RAX == 5
jl  lower    # jmp lower if (signed)RAX < 5
jb  below    # jmp below is (unsigned)RAX < 5

test %rax, %rax # optimized cmp $0, %rax
jz   zero       # jmp zero if RAX == 0
je   never      # WARNING: JE & JZ is the same instruction
```

Note that it's totally valid to put many conditional jumps
one by one, because they don't affect `EFLAGS` register.

# Stack

For very temporary storage of values, there is special memory
range that implements stack structure. `RSP` register points
at last pushed value. There are two special instructions for
that:

```assembly
	push %rax   # %rsp -= 8; (%rsp) = %rax
	push (%rax) # %rsp -= 8; (%rsp) = (%rax)
	push 5      # %rsp -= 8; (%rsp) = 5
	pop %rax    # %rax = (%rsp); %rsp += 8
```

There is no popping in memory. Of course, they are faster and
smaller than add/sub + mov combination. As you can see, the stack
is growing backwards. There is no standard way to determine
boundaries for the stack.

As RSP is general purpose register, there's nothing wrong
with using it in normal operations. In fact, it's how local
variables are compiled in C (unless they are in register).

```assembly
	sub $0x10, %rsp   # allocate two local variables
	mov $0xf0, (%rsp) # set one of them to 0xf0
	mov %rax, 8(%rsp) # put RAX value to the other
	add $0x10, %rsp   # not freeing it will crash program
			# in most cases
```

BTW. stack overflow is kind of attack that exploits stack
so that stack overlaps with a global variable. Originally it
could overwrite code to, but modern OSs prevent writing code
section and executing data section. Note that on 32-bit OSs
stack cells are only 4-bytes long.

# Calls

For calling functions there are 2 other commands:

```assembly
	call    my_fun
	#...

my_fun:
	#...
	ret
```

`CALL` works just like `JMP`, but pushes `RIP` first. In the
end of the function we put `RET` which simply pops that value
back, so that execution continues after last `CALL`. Of course,
if you don't return `RSP` value to the initial value, `RET`
takes `(%rsp)` anyway, so in most cases, it would cause a crash.

The stack is also used to pass function parameters. In 32-bit
architecture all of them are put on the stack (the first argument
pushed as last). Depending on convention caller al callee
was responsible for freeing parameters. That's why there is
such variant of `RET` with a parameter which indicates how much
would be added to `RSP` after popping to `RIP`.

The original purpose of `EBP` was to store `ESP` value before
allocating local variables. So that you can allocate
variables in the middle of function not caring how much
because you would use `EBP`, that's why Base Pointer. In the
end, you would just reset `ESP` to `RBP` before `RET`. There
were (and still are) instructions for that: `ENTER` and
`LEAVE`. However as those are clearly coding oriented features
it's no longer convention in 64-bit architecture, but still
may be found. For instance, `gcc` without optimization still
does it:

```assembly
$ echo 'int main(void) { return 5; }' > /tmp/x.c
$ gcc -S /tmp/x.c -o /tmp/x.s
$ grep -vP '^\s*\.' /tmp/x.s
main:
	pushq	%rbp
	movq	%rsp, %rbp
	movl	$5, %eax
	popq	%rbp
	ret
```

The reason why I grep out lines starting with a dot is
additional directives which are information for compiler
rather than actual instructions. 'l' and 'q' at the end of
instructions marks operand size. It is required only one
constant->mem write is performed (because there's no way to
deduce it).

In 64-bit architecture convention changed a little, because
first 5 parameters (except structures bigger than 8 bytes)
are passed through registers: `RDI`, `RSI`, `RDX`, `RCX`,
`R8` and R9. As you can see on above code, the return value is put
into %rax register (unless it's too big), but as the main return
32-bit value, `EAX` register is actually used.

RBX, RBP, and R12-R15 are considered callee-save, which
means, that all functions should provide that their values
will be the same after returning.

# Interrupts and syscalls

Very similar thing are interrupts — they are also kind of
functions implemented by OS or boot firmware, but they are
usually called by hardware. When CPU get such interrupt,
normal execution is stopped and restored when the interrupt is
handled. Also, CPU itself can generate the interrupt, that's how
CPU exceptions work (they are issued when some illegal
instruction is called). There is also `INT` instruction to
generate the interrupt.

For a long time, this feature was used to provide runtime
services in BIOS and DOS. In *nix 32-bit OSs (Linux, *BSD)
it's still used: `int 0x80`. EAX (or it's part) was
typically specifying system function and other registers
contained parameters. In 64-bit architecture, there is
`syscall` instruction instead, which works very similar.
For example for `read()` function:

```assembly
	xor %rax,  %rax #sys_read
	xor %rdi,  %rdi #fd = stdin
	lea .buff, %rsi #buffer
	mov $0xff, %rdi #bytes to read
	syscall
```

However, those calls are usually called using C wrapper calls
so the most likely place to find them are shared libraries.

This brief explanation is probably not enough to code in
assembly language but will let you understand most of 
the disassembly of userspace programs. As modern programs make
much use of shared libraries, those calls used most of the
time. The good thing is that unless you deal with
OS/firmware calls you don't need to care about multitasking,
caching and stuff. You will probably face strange constructs
like `call (%rip)`, which doesn't make functional sense, but
turns out to help CPU execute code faster. Another good news
is that userspace program is written as though it was only 
processed running on the machine which simplifies it a lot.

# Binary organization

Machine code is usually packed in some sort of file type.
In old times `COM` files used to contained raw machine code
and the only assumption was that the code would be placed at
0x100. However, nowadays we use more sophisticated formats
because modern CPUs offer access rights for memory regions
so that we can disable write access for code and constants
and execution for data regions. Another reason is that often
we want to load shared libraries — the code that can be
shared between processes. Of course, it's possible to load
them using dedicated system calls, but it's much more
convenient to let executable loader do it for us. Except
that we want to attach debugging symbols for convenient
execution analysis. Moreover modern executable formats
contain information about target architecture, checksums
and other information about the code.

Except that producing binaries directly from source code
would be very impractical and inefficient for big projects.
That's why in modern systems we have at least 4 file types
for code:

   1. Object files — usually generated per module,
   containing functions with their data. At this point, no 
   function dependencies are checked so that we may take
   care of later. Thanks to this we can separate compilation 
   process from resolving dependencies. Extension *.o in
   *nix and *.obj in Windows.
   2. Static libraries — set of functions to be incorporated
   into executable. Unlike object files, they must contain
   all dependencies. Extension *.a in *nix and *.lib in
   Windows.
   3. Dynamic libraries — a special type of library which is
   suitable to be loaded once for many programs at the same
   time. In such case, no their code is incorporated into
   binary but only references to them. Such code doesn't have
   to be duplicated in RAM too. However, each process has
   separate space for data. Unlike static libraries, they 
   have also initialization code that is run when the library is
   loaded. They may be loaded at the same time as whole
   binary or during runtime using the system call. The second
   option is often used to deploy plugins. However this
   approach is convenient it may cause problems with
   dependencies, because of many versions of the same library.
   That's why many (especially closed source) are
   distributed with libraries incorporated into the binary
   (ie. statically linked). Extension *.so in Linux, *.dll
   in Windows,  *.dylib in *BSD (including Mac). In *nix
   systems they are usually stored in /lib /usr/lib (this
   can be reconfigured per system or per binary). Windows
   usually store them in Windows and Windows\System32
   directory, but the directory with binary is checked by
   default.
   4. Executables — binaries intended to be run as
   standalone programs. They usually accept command line
   parameters and environment variables as an input. In
   *nix system they usually have no extension, in Windows
   *.exe.

Very often, for RELEASE builds debug symbols are built in 
a separate file (*.debug). If you load it you can debug your
program as though it had debug symbols. You can also
disassemble it and examine as normal binary. Another use
case for them is remote debugging. When you enable GDB
server in QEMU or expose one from the embedded device (e.g. via
serial port) you must have a local copy of the debugged code.

In modern PC platforms, we have 2 most common executable
formats: PE (Windows, UEFI) and ELF (*nix, coreboot).
Raw executable code still can be found in legacy BIOS boot
records (MBR). PE and ELF are different but share most
important concepts. For instance, they both divide contents
into sections. Generally, both formats can be examined in
 a very similar way (but tools differ a little bit).
Among others, PE files can be examined using pev package
(available also for *nix systems), for ELF objdump from
binutils is probably the most popular choice. In Reverse
Engineering IDA is kind of the standard, but it's much more
complex solution.

# Binary examination

Usually, we start by examining how binary is organized,
that is sections and entry point (for executables). As this
is very similar for both formats, so I'll focus on ELF.

Executable may have only one section with code (usually
called .text), but it's rare that there are no .data
(initialized data section), .rodata (initialized read-only
data) or .bss (zero-initialized data). Still, such a
minimalistic layout is typical for programs coded in
assembly language. GCC usually create about 20 of them,
however the most interesting for us would be .plt or .got
which contains references to dynamically linked libraries.
Typical C program loads at least standard library this way.

We can find entry point using:
```assembly
$ objdump -f /tmp/x

/tmp/x:     file format elf64-x86-64
architecture: i386:x86-64, flags 0x00000150:
HAS_SYMS, DYNAMIC, D_PAGED
start address 0x00000000000004f0
```

The start address is so-called RVA — Relative Virtual Address,
so it's offset from the place in memory, where binary would
be placed. To list sections we can call:

```assembly
objdump -h /tmp/x

/tmp/x:     file format elf64-x86-64

Sections:
Idx Name          Size      VMA               LMA               File off  Algn
  0 .interp       0000001c  0000000000000238  0000000000000238  00000238  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  1 .note.ABI-tag 00000020  0000000000000254  0000000000000254  00000254  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .note.gnu.build-id 00000024  0000000000000274  0000000000000274  00000274  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  3 .gnu.hash     0000001c  0000000000000298  0000000000000298  00000298  2**3
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  4 .dynsym       00000090  00000000000002b8  00000000000002b8  000002b8  2**3
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  5 .dynstr       0000007d  0000000000000348  0000000000000348  00000348  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  6 .gnu.version  0000000c  00000000000003c6  00000000000003c6  000003c6  2**1
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  7 .gnu.version_r 00000020  00000000000003d8  00000000000003d8  000003d8  2**3
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  8 .rela.dyn     000000d8  00000000000003f8  00000000000003f8  000003f8  2**3
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  9 .init         00000017  00000000000004d0  00000000000004d0  000004d0  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
 10 .text         00000192  00000000000004f0  00000000000004f0  000004f0  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
 11 .fini         00000009  0000000000000684  0000000000000684  00000684  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
 12 .rodata       00000004  0000000000000690  0000000000000690  00000690  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 13 .eh_frame_hdr 0000002c  0000000000000694  0000000000000694  00000694  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 14 .eh_frame     000000c8  00000000000006c0  00000000000006c0  000006c0  2**3
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 15 .init_array   00000008  0000000000200e20  0000000000200e20  00000e20  2**3
                  CONTENTS, ALLOC, LOAD, DATA
 16 .fini_array   00000008  0000000000200e28  0000000000200e28  00000e28  2**3
                  CONTENTS, ALLOC, LOAD, DATA
 17 .dynamic      000001a0  0000000000200e30  0000000000200e30  00000e30  2**3
                  CONTENTS, ALLOC, LOAD, DATA
 18 .got          00000030  0000000000200fd0  0000000000200fd0  00000fd0  2**3
                  CONTENTS, ALLOC, LOAD, DATA
 19 .got.plt      00000018  0000000000201000  0000000000201000  00001000  2**3
                  CONTENTS, ALLOC, LOAD, DATA
 20 .data         00000010  0000000000201018  0000000000201018  00001018  2**3
                  CONTENTS, ALLOC, LOAD, DATA
 21 .bss          00000008  0000000000201028  0000000000201028  00001028  2**0
                  ALLOC
 22 .comment      00000034  0000000000000000  0000000000000000  00001028  2**0
                  CONTENTS, READONLY
```

The most important for us is of course name, VMA (base
address), size and offset in the file. LMA is rarely different
than VMA so usually not relevant. As we see, names are
arbitrary and the flags are defining section features, but
it's rather relevant in security analysis. In most cases, 
initialized data sections are most interesting to us here,
so that we can translate pre-initialized data RVA to the location
in the file so that we can peek it (e.g. using hexdump). That's
because for each address based instruction some meaningful
name would be printed (usually label + offset, for calls
to dynamic libraries the name of call and library name).
Note that all addresses here are noted in hexadecimal.

Calling `objdump -d` will print disassembly of whole binary
So it's better to limit output. You may use
`--start-address=offset` parameter or `less` and start from 
looking for function name (function labels are usually
included even in RELEASE binaries). For debug binaries, you
may consider `-s` option to mix disassembly with source
code.

```assembly
# excerpt of some disassembly using objdump

00000000000109e0 <main@@Base-0xb90>:
   109e0:       55                      push   %rbp
   109e1:       53                      push   %rbx
   109e2:       48 89 f5                mov    %rsi,%rbp
   109e5:       48 89 fb                mov    %rdi,%rbx
   109e8:       48 83 ec 08             sub    $0x8,%rsp
   109ec:       48 8b 15 7d db 29 00    mov    0x29db7d(%rip),%rdx        # 2ae570 <source@@Base>
   109f3:       48 85 d2                test   %rdx,%rdx
   109f6:       74 2d                   je     10a25 <_init@@Base+0x65>
   109f8:       80 3a 2e                cmpb   $0x2e,(%rdx)
   109fb:       74 1c                   je     10a19 <_init@@Base+0x59>
   109fd:       8b 0d 75 db 29 00       mov    0x29db75(%rip),%ecx        # 2ae578 <sourceline@@Base>
   10a03:       48 8d 35 9b 74 07 00    lea    0x7749b(%rip),%rsi        # 87ea5 <_IO_stdin_used@@Base+0x5a5>
```

As you see we have complete disassembly with RVA and hex
representation of machine code for each instruction. As you
see most addresses are relative to RSP or RIP, but as second
one is given, there is also RVA and label given.

Note that if you prefer Intel syntax it can be changed, just
as in pev you can switch from default Intel to AT&T.

# Initial state

The last thing we must be aware of is the initial state of 
the process and this is platform dependent, but surely some
details are common. Most likely we get fully initialized
address space with all dynamically linked libraries already
loaded (except those loaded in the code of course), RSP in 
the rightlocation, etc. Command parameters are likely 
to be placed on the stack, however, it's arrangement may differ.

For example in 64-bit Linux RSP would initially point at
parameters count, and then 8 bytes pointer to each argument
starting from an executable name. This may be little confusing
as it's not what you see in `main()` function which conforms
to C's parameter format. The trick is that `main()` is not
the entry point even if it seems so when you run `gcc -S`.
The entry point is usually referred as `_start` and for C program
it is automatically added in linking process. _start calls
special libc call which loads main from given address.

This is a typical _start function. It looks the same for
C programs.

```assembly
0000000000013050 <_start@@Base>:
   13050:       31 ed                   xor    %ebp,%ebp
   13052:       49 89 d1                mov    %rdx,%r9
   13055:       5e                      pop    %rsi
   13056:       48 89 e2                mov    %rsp,%rdx
   13059:       48 83 e4 f0             and    $0xfffffffffffffff0,%rsp
   1305d:       50                      push   %rax
   1305e:       54                      push   %rsp
   1305f:       4c 8d 05 7a 48 07 00    lea    0x7487a(%rip),%r8        # 878e0 <__libc_csu_fini@@Base>
   13066:       48 8d 0d 03 48 07 00    lea    0x74803(%rip),%rcx        # 87870 <__libc_csu_init@@Base>
   1306d:       48 8d 3d fc e4 ff ff    lea    -0x1b04(%rip),%rdi        # 11570 <main@@Base>
   13074:       ff 15 f6 4a 29 00       callq  *0x294af6(%rip)        # 2a7b70 <__libc_start_main@GLIBC_2.2.5>
   1307a:       f4                      hlt
```

# Further steps

That's all you need to know in the beginning. As you see
it's not complex at all. The problem here is the amount of code
to get through, but each instruction itself is not complex.
Provided interface separate us from most of CPU and OS
magic. Of course interface of presented tools are
not very good for more sophisticated analysis, but its 
output is very regular so it's easy to transform it so that
your favourite language can understand it and process.

Meaning of most instruction is trivial and library calls
are the points which we can consider points where the program
communicate with outside world. So we can decide, which of
those points seem relevant to us so that we eliminate
information noise.

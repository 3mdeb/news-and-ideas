---
title: Meltdown and spectre. What are they and what they are not?
cover: /img/spectre.png
author: michal.zygowski
layout: post
published: true
date: 2019-03-20
archives: "2019"

tags:
    - meltdown-spectre
categories:
    - Security

---
## Meltdown and Spectre

At the turn of the year 2017 and 2018, the world of security and computing has
shaken. It was the time when we first heard about vulnerabilities that affect
almost every modern processor (mainly x86 architecture) manufactured during the
last 20 years. They have been named as Meltdown and Spectre and belong to one
family of flaws caused by speculative execution. In this post, I will describe
what they are and how they are threatening the users of modern machines.

### Spectre

![Spectre](/img/spectre.png)

Meltdown and Spectre refer to the vulnerabilities which break the isolation
between different applications. In other words, it allows an attacker to trick
error-free programs, which follow best practices, into leaking their secrets.
Basically, they are divided into few variants:

- \[CVE-2017-5753\] **Spectre Variant 1** - bounds check bypass.
- \[CVE-2017-5715\] **Spectre Variant 2** - branch target injection
- \[CVE-2017-5754\] **Variant 3, Meltdown** - rogue data cache load
- \[CVE-2018-3640\] **Variant 3a** - rogue system register read
- \[CVE-2018-3639\] **Variant 4** - speculative store bypass

### Spectre Variant 1 - bounds check bypass

Variant 1 relies on misleading the processor to do illegal actions (premature).
How was it achieved?

Firstly, on the initial phase of the attack, the processor is trained with valid
inputs in an arbitrary attack program. To clarify, we prepare the processor to
be "cheated". For example, let's say it is an IF statement which during training
phase evaluates to true:

```bash
if (x &amp;lt; array1_size)
    y = array2[array1[x] * 4096];
```

Next, during the exploit phase, the attacker invokes the code with a value of
`x` outside the bounds of `array1`. What happens now?

Due to the training phase, which task was to teach the branch predictor that the
IF statement will be true, the processor will mispredict the next instruction.
That is to say, the processor will think that the IF statement still will be
true (what?!), thus executing wrong instruction. This is the source of spectre
vulnerability.

> To clarify, the branch means execution flow. If we have an IF statement, we
> divide the execution flow into two branches: when the condition is true or
> when the condition is false. The execution result will be different based on
> condition evaluation.

In short, that is how speculative execution works. Rather than waiting for
determination of the branch result, the CPU guesses that the bounds check will
be true. Given that, processor already speculatively executes instructions that
evaluate `array2[array1[x]*4096]` using the malicious `x`. In other words, the
process accesses data it is not permitted to. `x` is chosen by the attacker and
the read from `array2` is dependent on `array1[x]`. Even if the CPU discovers
its error and reverts the changes, the secret data still exists in the cache.
The data can be then retrieved by analyzing the cache by an attacker.

### Spectre Variant 2 - branch target injection

Variant 2 is very similar to the first variant. In the previous example, the
malicious code resided in attackers address space. While in the second variant,
the attacker chooses a specific "gadget" from the victim's address space.
Similarly, the processor is trained to mispredict a branch and to execute the
"gadget" lying in the victim's address space. As a result, information revealed
by the "gadget" remains in the cache. Again, the attacker can analyze it to
retrieve the information.

### Variant 3 - Meltdown, rogue data cache load

![Meltdown](/img/meltdown.png)

Meltdown is a little bit different than the first two variants of Spectre.
Meltdown uses the out-of-order instruction execution instead of branch
prediction in the attack. How does it work?

First and foremost, we have to know what out-of-order execution is. In other
words, out-of-order execution is an architectural feature that increases the
utilization of the processor's components. The processor allows instructions
further down the instruction stream of a program to be executed in parallel
with, and sometimes before, preceding instructions. How does it apply to
meltdown attacks?

Meltdown attack focuses on memory protection bypassing. For example, when trying
to access kernel memory space from user-space a trap is caused. But before the
trap occurs the out-of-order execution takes place. As a result, instructions
that follow the illegal access (causing the trap) are executed before being
terminated. As a result, these instructions leak the contents of the accessed
memory to the cache. The rest of the story is already known.

### Variant 3a - rogue system register read

This variant is also very similar to variant 3, but the target is different. On
the contrary of the variant 3, when attacker wanted to obtain kernel memory
space, variant3a focuses on hardware registers access by a normal user.
Typically, accessing hardware registers is restricted to root or even kernel
itself. In other words, it is not possible to read some registers by a normal
user. However, exploiting the out-of-order execution allow leaking the
register's information disclosing system parameters to an attacker with local
user access.

### Variant 4 - speculative store bypass

Variant 4, when exploited, allows an attacker to read older memory values in a
processor's stack or other memory locations. The trick is to make the storing of
a value dependent on the results of previous instructions. To clarify, this
means that the processor has to wait before it knows where to store the value.
The second step (the value load), is, in contrast, constructed in such a way
that the address can be determined quickly, without waiting. In this situation,
the processor's speculative execution will "ignore" or "bypass" the store.
Because it doesn't yet know where the value is actually being stored. It will
make an assumption that the data currently held at the memory location is valid
(but it's not!).

The processor will figure out its error, discard the results and perform correct
calculations. But at this point, the microarchitectural state of the processor
has already been changed. These changes can be detected, and an attacker can use
those changes to figure out which value was read.

## Summary

For the past decades, we observed the increase in the processor's speed.
Performance advancement has been achieved not only by the frequency itself but
also by introducing speculative execution. Rather than wasting clock cycles to
access memory or determine a value, CPU tries to predict the execution flow or
value and executes instruction prematurely. This gave birth to Meltdown and
Spectre. If the instruction prediction is correct, the performance is increased.
Otherwise, the CPU has to revert all changes to the last checkpoint (before
incorrect execution) resulting in a performance drop.

In the next post, I will show You whether Meltdown and Spectre vulnerabilities
are exploitable on PC Engines apu2 platform and how to mitigate. So stay tuned.

If you think we can help in improving the security of your firmware or you
looking for someone who can boot your product by leveraging advanced features of
used hardware platform, feel free to
[book a call with us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter.](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

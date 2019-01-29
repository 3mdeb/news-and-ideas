---
post_title: Meltdown spectre vulnerabilities
author: Michał Żygowski
layout: post
published: false
post_date: 2019-01-DD HH:MM:SS

tags:
    - spectre
    - meltdown
categories:
    - Security


---

# Meltdown spectre

At the turn of the year 2017 and 2018 the world of security and computing has
shaken. It was the time when we first heard about vulnerabilities that affect
almost every modern processor (mainly x86 architecture) manufactured during the
last 20 years. They have been named as Spectre and Meltdown and belong to one
family of flaws caused by speculative execution. In this post, I will describe
what they are and how they are threatening the users of modern machines.

# Spectre

![Spectre](https://3mdeb.com/wp-content/uploads/2017/07/spectre.png)

Spectre refers to a vulnerability which breaks the isolation between different
applications. It allows an attacker to trick error-free programs, which follow
best practices, into leaking their secrets.

It is basically divided into few variants:

- [CVE-2017-5753] Spectre Variant 1 - bounds check bypass.
- [CVE-2017-5715] Spectre Variant 2 - branch target injection
- [CVE-2017-5754] Variant 3, Meltdown - rogue data cache load
- [CVE-2018-3640] Variant 3a - rogue system register read
- [CVE-2018-3639] Variant 4 - speculative store bypass

## Spectre Variant 1 - bounds check bypass

Variant 1 relies on misleading the processor to do illegal actions. How was it
achieved?

On the initial phase of the attack, the processor is trained with valid inputs
in arbitrary attack program. Basically, we prepare processor to be cheated.
Let's say it is an if statement which during training phase evaluates to true:

```
if (x < array1_size)
    y = array2[array1[x] * 4096];
```

Next, during the exploit phase, the attacker invokes the code with a value of
`x` outside the bounds of `array1`. What happens now?

Due to the training phase, which task was to teach the branch predictor (which
is the source of the vulnerability variant) that the if statement will be true,
the processor will think that the if statement still will be true (what?!).

> The branch means execution flow. If we have if statement, we divide the
> execution flow into two branches: condition is true or condition is false.

That is how speculative execution works. Rather than waiting for determination
of the branch result, the CPU guesses that the bounds check will be true and
already speculatively executes instructions that evaluate
`array2[array1[x]*4096]` using the malicious `x`. Given that, the process
accesses data it is not permitted to. `x` is chosen by the attacker and the
read from `array2` is dependent on `arrray1[x]`. Even if the CPU discovers
its error and reverts the changes, the secret data still exists in the cache
and can be retrieved by analyzing the cache by an attacker.

## Spectre Variant 2 - branch target injection

Variant 2 is very similar to the first variant. In the previous example, the
malicious code resided in attackers address space. While in the second variant,
the attacker chooses a specific "gadget" from victim's address space. The
processor is trained to mispredict a branch and to execute the "gadget" lying
in the victim's address space. Information revealed by the "gadget" remains in
the cache like before and the attacker can analyze it to retrieve the
information.

## Variant 3 - Meltdown, rogue data cache load

![Meltdown](https://3mdeb.com/wp-content/uploads/2017/07/meltdown.png)

Meltdown is a little bit different than Spectre first two variants. It uses
out-of-order instruction execution instead of branch prediction in the attack.
How does it work?

First and foremost, we have to know what out-of-order execution is. It
increases the utilization of the processor's components by allowing
instructions further down the instruction stream of a program to be executed in
parallel with, and sometimes before, preceding instructions.

Meltdown attack focuses on memory protection bypassing. For example, when
trying to access kernel memory space from user-space a trap is caused, but
before the trap occurs the out-of-order execution takes place. As a result,
instructions that follow the illegal access (causing the trap) are executed
before being terminated. These instructions leak the contents of the accessed
memory to the cache.

## Variant 3a - rogue system register read

This variant is also very similar to variant 3, but the target is different.
In the variant 3 attacker wanted to obtain kernel memory space, but in this
variant, hardware registers are accessed from user-space. Typically accessing
hardware registers is restricted to root or even kernel itself. It is not
possible to read some registers from user-space. However, exploiting the
out-of-order execution allow leaking the register's information disclosing
system parameters to an attacker with local user access.

## Variant 4 - speculative store bypass

Variant 4, when exploited, allows an attacker to read older memory values in a
processor's stack or other memory locations. The trick is to make storing a
value dependent on the results of previous instructions. This means that the
processor has to wait before it knows where to store the value. The second
step, the load, is, in contrast, constructed in such a way that the address
can be determined quickly, without waiting. In this situation, the processor's
speculative execution will "ignore" or "bypass" the store (because it doesn't
yet know where the value is actually being stored) and just assume that the
data currently held at the memory location is valid (but it's not).

The processor will figure out its error, discard the results and perform
correct calculations. But at this point, the microarchitectural state of the
processor has already been changed. These changes can be detected, and an
attacker can use those changes to figure out which value was read.

# Summary

For the past decades, we observed the increase in the processor's speed.
Performance advancement has been achieved not only by the frequency itself but
also by introducing speculative execution. Rather than wasting clock cycles to
access memory or determine a value, CPU tries to predict the flow or value and
executes instruction prematurely. If the guess was correct, the performance
is increased, but if it was not correct, the CPU has to revert all changes to
the last checkpoint (before incorrect execution) resulting in performance drop.

In the next post, I will show You whether these vulnerabilities are exploitable
on PC Engines apu2 platform and how to mitigate. So stay tuned.

I hope this post was useful for you. Please feel free to share your opinion and
if you think there is value, then share with friends.

If you think we can help in improving the security of your firmware or you
looking for someone who can boot your product by leveraging advanced features
of used hardware platform, feel free to [boot a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sing up to our newsletter](http://eepurl.com/gfoekD)

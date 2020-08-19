---
author: jakub.lecki
title: Latency - The most crucial aspect of real-time systems.
abstract: "What in reality is RT system? This post will explain what to expect from Real-Time systems and how can we test performance in this kind of builds."
tags:
  - yocto
  - testing
  - latencies
  - i.mx8
categories:
  - Real-Time
  - Testing
---

# Latency - The most crucial aspect of real-time systems

## Intro

Many words have been spoken about RT systems and their supremacy over typical systems in specific fields. But should we trust their name? Real-Time?\
As usual, the answer is no. RT system just trying to be what they're called, that means, react to triggers like interruptions and response immediately. More often it's just not later than the strictly defined time, called latency.

## Strategy

So how can we measure the 'quality' of our rt system? Let's say we want a task to be weaken up after 200 us. To this task, we can use a timer which will generate interruption when the time runs out and wake up the task.
Before we put the task to sleep lets remember current time

1. The start point of measuring kernel latencies is when the interrupt occurs.
2. The First thing kernel must do is observe it and while there is a lot to do and to observe even that part can take some time.
3. After that, relevant ISR is called to handle interruption(in our case to wake up the task)
4. Next goes the kernel scheduler whose job is to manage all of the processes working in the system. When our task has been woken up, it was placed on the CPU queue indeed. So now it's the scheduler thing to handle the task ASAP.
5. When it's time come, CPU starts to process the task and we can end measuring the latency.

After that, we can subtract the current time from the time before we put the task to sleep and get the latency by subtracting time difference with the time given to timer.

The given example is the exact methodology of the [`cyclictest`](http://manpages.ubuntu.com/manpages/cosmic/man8/cyclictest.8.html) test program for testing system latencies which will be using here by us.

### Additional load

To simulate a stressful environment for the system we're testing tools like [`hackbench`](http://manpages.ubuntu.com/manpages/xenial/man8/hackbench.8.html) and [`stressapptest`](http://manpages.ubuntu.com/manpages/trusty/man1/stressapptest.1.html) can be used.

* [`Hackbench`](http://manpages.ubuntu.com/manpages/xenial/man8/hackbench.8.html) - tool for stressing kernel scheduler by creating pairs of threads communicating with each other via sockets

* [`Stressapptest`](http://manpages.ubuntu.com/manpages/trusty/man1/stressapptest.1.html) - program for generating a realistic load of memory, CPU, and I/O by creating a specified amount of threads writing to memory, to file, or communicate with given IP server

## Testing platform

Tests will be performed on an i.mx8 platform with two builds of yocto-linux. A Regular version and a specially configured as RT using rt patch.

## Tests cases

To get a complete system's characteristic at least a couple of tests with a different load must be performed. To get fully reliable results, a test's time must take as least a couple of hours.
Although in our case to demonstrate results each test will take around 1 hour

Test sheet:

* **_CASE 1:_** `cyclictest` with no load

* **_CASE 2:_** `cyclictest` with `hackbench` sending 128B data packages

* **_CASE 3:_** `cyclictest` with `stressapptest` on 2 memory threads testing 256MB of memory

* **_CASE 4:_** `cyclictest` with `stressapptest` on 4 memory threads testing 256MB of memory

* **_CASE 5:_** `cyclictest` with `stressapptest` on 8 memory threads testing 256MB of memory, 4 I/O threads and 4 network threads

## Results

* **_CASE 1:_**(No load)
_Regular Build_
        <img src='../../static/img/system_latency_plots/normal/cyclic_alone.png' width=80%>
_RT Build_
        <img src='../../static/img/system_latency_plots/rt/cyclic_alone.png' width=80%>

* **_CASE 2:_**(with hackbench)
_Regular Build_
        <img src='../../static/img/system_latency_plots/normal/hack.png' width=80%>
_RT Build_
        <img src='../../static/img/system_latency_plots/rt/hack.png' width=80%>

* **_CASE 3:_**(light stresstest)
_Regular Build_
        <img src='../../static/img/system_latency_plots/normal/cyc_stress_plots/stress_case_1.png' width=80%>
_RT Build_
        <img src='../../static/img/system_latency_plots/rt/stress_plots/stress_case_1.png' width=80%>

* **_CASE 4:_**(medium stresstest)
_Regular Build_
        <img src='../../static/img/system_latency_plots/normal/cyc_stress_plots/stress_case_2.png' width=80%>
_RT Build_
        <img src='../../static/img/system_latency_plots/rt/stress_plots/stress_case_2.png' width=80%>

* **_CASE 5:_**(hard stresstest)
_Regular Build_
        <img src='../../static/img/system_latency_plots/normal/cyc_stress_plots/stress_case_3.png' width=80%>
_RT Build_
        <img src='../../static/img/system_latency_plots/rt/stress_plots/stress_case_3.png' width=80%>

<table style="border: 1px solid black; width:100%">
    <tr style="align:center">
   <b>Maximum latency</b>
    </tr>
    <tr>
        <th style="border: 1px solid black">
        <b>Build</b>
        </th>
        <th style="border: 1px solid black">
        <b>Case 1</b>
        </th>
        <th style="border: 1px solid black">
        <b>Case 2</b>
        </th>
        <th style="border: 1px solid black">
        <b>Case 3</b>
        </th>
        <th style="border: 1px solid black">
        <b>Case 4</b>
        </th>
        <th style="border: 1px solid black">
        <b>Case 5</b>
        </th>
    </tr>
    <tr>
        <th style="border: 1px solid black">
        <b>RT</b>
        </th>
        <th style="border: 1px solid black">
        71us
        </th>
        <th style="border: 1px solid black">
        97us
        </th>
        <th style="border: 1px solid black">
        172us
        </th>
        <th style="border: 1px solid black">
        157us
        </th>
        <th style="border: 1px solid black">
        176us
        </th>
    </tr>
    <tr>
        <th style="border: 1px solid black">
        <b>Actual</b>
        </th>
        <th style="border: 1px solid black">
        5959us
        </th>
         <th style="border: 1px solid black">
        6167us
        </th>
         <th style="border: 1px solid black">
        6195us
        </th>
         <th style="border: 1px solid black">
        6153us
        </th>
         <th style="border: 1px solid black">
        7937us
        </th>
    </tr>
</table>

### Conclusions

As expected differences in these builds are huge. Even with no load regular build seems to not care about such thing as latency. Delays around 6ms of processing are almost visible to a human eye so there is no talking about considering regular build in rt-requiring projects.
On the other hand, RT build yocto despite much better results, may also cause problems.
Let's say in our project we use an external device that collecting data samples, save them, and sending an interrupt to our main board to collect with 8KHz frequency or higher, that means every 125 us. If interrupt handling latency will be bigger than 125 us data on the external device will be overwritten by next and lost.

## Summary

RT systems are a blessing for some projects, but we shouldn't take for granted that they will solve our problems. We must verify if that exact system meets our needs. I hope that after this post you will be aware of latencies and always have in mind to be a little obtrusive about testing everything you can.

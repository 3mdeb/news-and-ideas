---
title: Containerization of the test environment for embedded systems
abstract: 'Using Docker makes life much easier for developers. It allows us to
          build lightweight and portable software containers that simplify
          application development. In this article, we present the advantages of
          using Docker for embedded testing'
cover: /covers/docker_testing.jpg
author: mateusz.grzelak
layout: post
published: true
date: 2020-12-17
archives: "2020"

tags:
  - docker
  - testing
categories:
  - Firmware

---

## Introduction

Docker is an open-source tool used for creating, deploying, and running
applications using containers. It performs operating-system-level
virtualization, also known as “containerization”. A container is a standard unit
of code with libraries, dependencies and other configuration and binaries needed
to run it.

Containers allow applications to run independently of the system they are
running on. It is handy when creating an application that runs on our computer
but not on another programmer's computer. A program that uses many dependencies
and libraries may not run on another computer due to incorrect versions. In this
case, we only need to define necessary dependencies and pack our application in
a container. Regardless of the operating system, it should run on each computer
with an installed Docker.

Another great advantage is that the containers are isolated from the environment
so it is very unlikely that we could destroy our environment or other
containers. You can read more about Docker basics
[here](https://blog.3mdeb.com/2020/2020-09-23-raspberrypi_docker/).

## Why Docker

We could create virtual machines for testing embedded systems, but such a
solution would have many disadventages. One of the biggest advantage of Docker
is its portability and performance. A virtual machine acts as a physical
computer and uses the physical resources of the device it is operating on to
replicate the environment of a physical device. A fully virtualized system has
its own resources. Containers are lightweight because they don't boot a separate
operating system per virtual machine. They also share a kernel and common layers
across images.

Let's say that we have a hundred of tests that need a database, and each test
needs the same copy of a database. In case each test modifies a database we need
to reset a database after each test. With Docker we can create the image of our
database and run one instance per test. Additionally, the simplicity of creating
images using Dockerfile makes it much easier to transfer them to another
computer. But there are pros and cons. Fully virtualized systems are more
isolated than containers but for embedded testing, we don't need this advantage.

But there are other ways to create virtual environments, for example, using
Python virtualenv so why not use it? Of course we can, with the difference that
virtualenv only encapsulates Python dependencies. A container encapsulates an
entire operating system and gives much more power. We can even run virtualenv on
Ubuntu, Debian or Linux Mint inside Docker container.

## Project description and execution

Let's assume that we produce firmware for microcontrollers with 2 GPIO pins and
allowing for serial data exchange. Our goal is to write automatic tests that
check whether we are able to correctly change the state of these two pins and
whether data is correctly sent through the serial port. In our case, we write
tests that anyone, regardless of the operating system, could run on their
computer with Docker installed.

To simulate our case, we use an Arduino UNO, which serves as the device under
test (DUT), and Raspberry Pi, which tests our DUT. On the Arduino we check 4th
and 8th pin. Unfortunately, the Raspberry can only read voltage not exceeding
3.3V. The range of GPIO pins of the Arduino is 0-5V so we have to use here a
level shifter or voltage divider. In our case, we use six 1K resistors connected
in the following way:

![voltage_divider](/img/voltage_divider.jpg)

![voltage_divider](/img/rpi_arduino_diagram.jpg)

We need to know how to program Arduino. Usually, the Arduino IDE is used for
this purpose, but in our case, we need to learn how to program Arduino from the
command line so that it can be used in automatic tests. One solution is to
compile Arduino sketches using Makefile. To do that we use package `arduino-mk`
which allows us to compile the code and upload it to the Arduino. On Linux based
system we can download this package by typing:

```bash
sudo apt install arduino-mk
```

After downloading, typing:

```bash
pi@raspberrypi:~ $ ls /usr/share/arduino/
Arduino.mk          chipKIT.mk  examples  lib        reference      Teensy.mk
arduino-mk-vars.md  Common.mk   hardware  libraries  revisions.txt  tools
```

will show the location of `arduino-mk` file set that we downloaded. The most
important file in this folder is `Arduino.mk`. To be able to compile a program
that we are going to write, we need to reference this file, so it's important to
know where that file is located.

Our tests use 5 files that are uploaded to the Arduino:

- pin 4 on/off
- pin 8 on/off
- serial connection

`pin4_off.ino`

```bash
void setup(){
    pinMode(4, OUTPUT);
}

void loop(){
    digitalWrite(4, LOW);
}
```

`pin4_on.ino`

```bash
void setup(){
    pinMode(4, OUTPUT);
}

void loop(){
    digitalWrite(4, HIGH);
}
```

`serial.ino`

```bash
void setup(){
    Serial.begin(9600);
}

void loop(){
    Serial.println("Hello world!");
    delay(1000);
}
```

The `pin8_<on/off>.ino` files look similar to the `pin4_<on/off>.ino` files with
the difference that we change the digit 4 to 8. Each created file is in separate
folder and for each file we create Makefile that references to the downloaded
from arduino-mk Makefile:

`Makefile`

```bash
ARDUINO_DIR = /usr/share/arduino
ARDUINO_PORT = /dev/ttyACM*

BOARD_TAG = uno

include /usr/share/arduino/Arduino.mk
```

where `ARDUINO_PORT` specifies the Arduino device file that appears after
connecting to the Raspberry via USB A/B cable and `BOARD_TAG` is a type of
Arduino board. On Linux based system Arudino always shows up as ACM0 or ACM1
depending on how many devices we have connected so this works only if we have
one Arduino connected to RPi.

To convert our code into the files that can be uploaded to Arduino we go to a
specific folder and type `make`. This creates a new folder that contains all the
necessary files. We can upload them by typing `make upload`. If we also want to
remove this folder after uploading files to Arduino, we can simply add
`make upload clean`.

Now we have all the necessary files for our DUT. It's time to write automatic
tests. To do that we use [RobotFramework](https://robotframework.org/) which is
a great tool for writing tests. To download it, we also need Python installed.
We can download `RobotFramework` by typing `pip install robotframework`.

`arduino.robot`

```bash
*** Settings ***
Library     SSHLibrary    timeout=90 seconds

Suite Setup    Connect And Upload Arduino Files
Suite Teardown    Remove Arduino Files And Close Connection

*** Variables ***
${rte_ip}    192.168.0.11
${username}    pi
${password}    onetwothree
${prompt}    pi@raspberrypi

*** Keywords ***
Connect And Upload Arduino Files
    SSHLibrary.Set Default Configuration    timeout=60 seconds
    SSHLibrary.Open Connection    ${rte_ip}    prompt=${prompt}
    SSHLibrary.Login    ${USERNAME}    ${PASSWORD}
    SSHLibrary.Put Directory    ./arduino    mode=777    recursive=TRUE

Exit From Monitor
    SSHLibrary.Write Bare    \x01    #ctrl+a
    SSHLibrary.Write Bare    \x04    #ctrl+d

Remove Arduino Files And Close Connection
    SSHLibrary.Execute Command    rm -rf ./arduino
    SSHLibrary.Close All Connections

*** Test Cases ***
ARD1.0 Serial Connection
    SSHLibrary.Write    cd ./arduino/serial && make upload monitor clean
    SSHLibrary.Read Until    Hello world!
    Exit From Monitor
    SSHLibrary.Execute Command    screen -X quit
    ${result}=    SSHLibrary.Execute Command    screen -list
    Should Contain    ${result}    No Sockets found

ARD1.1 Pin 4 on
    SSHLibrary.Execute Command    cd ./arduino/pin4_on && make upload clean
    ${status}=    SSHLibrary.Execute Command    cat /sys/class/gpio/gpio14/value
    Should Be True    ${status}==1

ARD1.2 Pin 4 off
    SSHLibrary.Execute Command    cd ./arduino/pin4_off && make upload clean
    ${status}=    SSHLibrary.Execute Command    cat /sys/class/gpio/gpio14/value
    Should Be True    ${status}==0

ARD1.3 Pin 8 on
    SSHLibrary.Execute Command    cd ./arduino/pin8_on && make upload clean
    ${status}=    SSHLibrary.Execute Command    cat /sys/class/gpio/gpio15/value
    Should Be True    ${status}==1

ARD1.4 Pin 8 off
    SSHLibrary.Execute Command    cd ./arduino/pin8_off && make upload clean
    ${status}=    SSHLibrary.Execute Command    cat /sys/class/gpio/gpio15/value
    Should Be True    ${status}==0
```

To run the ARD1.0 test, we also need to download on RPi the `screen` program:

```bash
sudo apt install screen
```

The file structure on our PC should be as follows:

```bash
blog_rf/
├── arduino
│   ├── pin4_off
│   │   ├── Makefile
│   │   └── pin4_off.ino
│   ├── pin4_on
│   │   ├── Makefile
│   │   └── pin4_on.ino
│   ├── pin8_off
│   │   ├── Makefile
│   │   └── pin8_off.ino
│   ├── pin8_on
│   │   ├── Makefile
│   │   └── pin8_on.ino
│   └── serial
│       ├── Makefile
│       └── serial.ino
├── arduino.robot
```

Before running the tests, we need to export pins 14 and 15 and set their
direction to `in`:

```bash
pi@raspberrypi:~ $ echo 14 > /sys/class/gpio/export
pi@raspberrypi:~ $ echo 15 > /sys/class/gpio/export
pi@raspberrypi:~ $ echo in > /sys/class/gpio/gpio14/direction
pi@raspberrypi:~ $ echo in > /sys/class/gpio/gpio15/direction
```

To run the tests, we enter in the terminal in `blog_rf` directory:

`robot -L TRACE arduino.robot`

After running this command, in `blog_rf` directory we should have file
`log.html`, which gives a detailed description of our tests:

![log_test](/img/arduino_test_log.png)

As mentioned before, we need `robotframework` and `python` to run these tests.
My version of `python` is 3.8.5 and `robotframework` is 3.2.2. Depending on the
version of the `robotframework`, the code may differ. This is a great
opportunity to use Docker. We can create a Dockerfile that will contain all the
necessary information about the version of the programs that our code uses.
Thanks to this, everyone will be able to run it regardless of whether they use
python 2 or 3 on their computer. Dockerfile might look like this:

`Dockerfile`

```bash
FROM python:3.7-slim-stretch

RUN  pip install robotframework==3.2.2 && \
     pip install robotframework-sshlibrary==3.5.1

ENTRYPOINT ["robot"]
```

- the first line specifies the parent image from which we are building our
  image. More python image names can be found
  [here](https://hub.docker.com/_/python)
- `RUN` runs given commands in a shell inside the container
- `ENTRYPOINT` specifies a command that will always be executed when the
  container starts

In the same directory where Dockerfile is located, let's enter:

```bash
mateusz@mateusz:~/blog_rf$ docker build -t blog/docker:latest .
```

When we type `docker images` we should see our image:

```bash
mateusz@mateusz:~/blog_rf$ docker images
REPOSITORY               TAG                 IMAGE ID            CREATED             SIZE
blog/docker              latest              61da82a7b715        35 minutes ago      129MB
python                   3.7-slim-stretch    b72f35c13f06        3 weeks ago         96.9MB
```

Now we can run the tests again but this time from the container.

```bash
mateusz@mateusz:~/blog_rf$ docker run --rm -it -v ${PWD}:${PWD} -w ${PWD} blog/docker arduino.robot
==============================================================================
Arduino
==============================================================================
ARD1.0 Serial Connection                                              | PASS |
------------------------------------------------------------------------------
ARD1.1 Pin 4 on                                                       | PASS |
------------------------------------------------------------------------------
ARD1.2 Pin 4 off                                                      | PASS |
------------------------------------------------------------------------------
ARD1.3 Pin 8 on                                                       | PASS |
------------------------------------------------------------------------------
ARD1.4 Pin 8 off                                                      | PASS |
------------------------------------------------------------------------------
Arduino                                                               | PASS |
5 critical tests, 5 passed, 0 failed
5 tests total, 5 passed, 0 failed
==============================================================================
Output:  /home/mateusz/blog_rf/output.xml
Log:     /home/mateusz/blog_rf/log.html
Report:  /home/mateusz/blog_rf/report.html
```

As we can see, the test results are the same except that now anyone can run our
tests.

## Summary

Thanks for getting here, If you have found Docker handy and worthy to use, check
[this source](https://containers.3mdeb.com/) of docker containers maintained by
our team or forked from Open Source projects with additional useful adjustments.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to
[book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting) or
drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up for our newsletter](https://3mdeb.com/subscribe/3mdeb_newsletter.html)

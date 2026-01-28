---
ID: 63772
title: Robot Framework? using Request library for control RPI GPIO's
cover: /covers/robot-framework-logo.png
author: daniel.konopski
post_excerpt: ""
layout: post
private: false
published: true
date: 2018-01-18 14:31:00
archives: "2018"
---

Requests library is one of the most popular libraries implemented for Robot
Framework. It is very important for testing distributed applications, so this is
the first library I got to know in the Robot Framework.

To test `Request` library we can install Pi-GPIO-Server on Raspberry Pi. The
server is able to control the state of input and output of GPIOs using REST API.

The project is available on the link: [Project weekend - GPIO Server][1]

In the REST API we used following methods:

- Delete
- Get
- Options
- Post
- Put
- Patch

To control GPIOs on the RPI we need only `Get` and `Patch` methods, other
methods are used in the same way - `Options` is used for exceptions.

I assume you have already installed Robot Framework. If the response is "NO", I
would encourage you to read the [Installation paragraph][2] It is official
documentation for Robot Framework. Next, we can install requests libraries.
`Collections` library is a standard built-in library. Use below commands to
install libs.

```bash
apt-get install python-pip
pip install -U requests
pip install -U robotframework-requests
Now we can prepare RPI image. Install
```

`RASPBIAN STRETCH WITH DESKTOP` from [download link][3]. It is a very good
solution because we can control also GPIOs using buttons.

![img](/img/web_browser_control.png)

I hope that instruction of installation process is sufficient, so I will not
duplicate the description. Take a few minutes to prepare the pin configuration
and restart gpio server:

```bash
sudo service gpio-server restart
```

For running server go to Pi-GPIO-Server and type:

```bash
python pi_gpio_server.py
```

Now, we can start writing code for GPIO control using REST API and Robot
Framework.

```bash
*** Settings ***

*** Variables ***

*** Test Cases ***

*** Keywords ***
```

Run RPi and check for its IP address. We will use IP for connection with API
server. My RPI has IP: 192.168.0.46. The documentation says that server runs on
`5000` port. So we can prepare URL variable. On `Variables` section type:

```bash
${URL} http://192.168.0.46:5000
```

Let's run the first test

`Get signals`. Firstly we should create a session for request control in Robot
Framework. To create the session we use the keyword `Create session` with
parameters `alias`, `URL` and optional `verify`. [How to create session][5]

```bash
*** Test Cases ***

Get signal
Create Session gpio_server ${URL} verify=True
```

We will use `alias` for all keywords which work on URL. All sessions should be
closed using the keyword `Delete All Sessions`. Next, we need a header, which
should be sent with the request. One of the methods for creating header looks
like:

```bash
Create Dictionary Content-Type=application/json Accept=application/json
```

A good trick is assigning headers to the variable. To check the value of GPIO,
special GET method is prepared. [Documentation][6] tells:

```bash
Read a single pin

GET: /api/v1/pin/:num
```

Let's implement it in another way:

```bash
${pin}= Get Request gpio_server /api/v1/pin/18 ${headers}
```

As I said, `alias` is very important because it defines on which session we send
requests. For observing results Robot Framework has special keyword. Its name is
`Log`.

Whole test look like this:

```bash
*** Settings ***
Library RequestsLibrary
Library Collections


*** Variables ***
${URL} http://192.168.0.46:5000


*** Test Cases ***

Get signal
Create Session gpio_server ${URL} verify=True
${headers}= Create Dictionary Content-Type=application/json Accept=application/json
${pin}= Get Request gpio_server /api/v1/pin/18 ${headers}
Log  ${pin.json()}
Delete All Sessions
```

To get all signals you can only type hyperlink without the pin number. Example:

```bash
Get signals
Create Session gpio_server ${URL} verify=True
${headers}= Create Dictionary Content-Type=application/json Accept=application/json
${pinout}= Get Request gpio_server /api/v1/pin ${headers}
Log ${pinout.json()}
```

That was the easier part of our script.

To set a high or low state for GPIOs you should use `patch` method. The first
step is creating a dictionary with value to send. It is not difficult:

```bash
${message}= Create Dictionary value 0
```

`Patch` request requires message data to send.

```bash
Set 0 signals
Create Session gpio_server ${URL} verify=True
${headers}= Create Dictionary Content-Type=application/json Accept=application/json
${message}= Create Dictionary value 0
${pin}= Patch Request gpio_server /api/v1/pin/18 ${message} headers=${headers}
Log ${pin.json()}
Delete All Sessions
```

We can use the same test to set the high state on GPIO. As an indicator, I used
LED diodes and resistors in series connection.

The full version of my code:

```bash
*** Settings ***
Library RequestsLibrary
Library Collections


*** Variables ***
${URL} http://192.168.0.100:5000

*** Test Cases ***

Get signal
Create Session gpio_server ${URL} verify=True
${headers}= Create Dictionary Content-Type=application/json Accept=application/json
${pinout}= Get Request gpio_server /api/v1/pin/18 ${headers}
Log ${pinout.json()}

Set value 1
Create Session gpio_server ${URL} verify=True
${headers}= Create Dictionary Content-Type=application/json Accept=application/json
${message}= Create Dictionary value 1
${pinout}= Patch Request gpio_server /api/v1/pin/18 ${message} headers=${headers}
Log ${pinout.json()}
Sleep 3 seconds

Set value 0
Create Session gpio_server ${URL} verify=True
${headers}= Create Dictionary Content-Type=application/json Accept=application/json
${message}= Create Dictionary value 0
${pinout}= Patch Request gpio_server /api/v1/pin/18 ${message} headers=${headers}
Log ${pinout.json()}

Get all signals
Create Session gpio_server ${URL} verify=True
${headers}= Create Dictionary Content-Type=application/json Accept=application/json
${pinout}= Get Request gpio_server /api/v1/pin ${headers}
Log ${pinout.json()}
```

This code is not in perfect form, but it's not the subject of this article. So
polishing is left to the reader. RF generates very readable reports after all
tests are done.

Reports look like this:

![img](/img/report.png)

You can see that Robot Framework is very easy to use environment for testing
REST API. All methods (e.g. POST and Patch) are the same in use. If you need
help with implementing tests you can ask me or chat with users on Slack
-`requests` channel on the robot-framework group. I help new users, whenever I
can, and also sometimes I'm the one looking for help.

[1]: https://github.com/projectweekend/Pi-GPIO-Server
[2]: http://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#installation-instructions
[3]: https://www.raspberrypi.org/downloads/
[5]: https://marketsquare.github.io/robotframework-requests/doc/RequestsLibrary.html#Create%20Custom%20Session
[6]: https://github.com/projectweekend/Pi-GPIO-Server#read-a-single-pin

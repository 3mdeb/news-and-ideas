---
ID: 63772
post_title: 'Robot Framework &#8211; using Request library for control RPI GPIO&#8217;s'
author: Piotr Król
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/app-dev/robot-framework-using-request-library-for-control-rpi-gpios/
published: true
post_date: 2018-01-18 14:31:00
tags:
  - RTE
categories:
  - App Dev
---
Requests library is one of the most popular libraries implemented for Robot
Framework. It is very important for testing distributed applications, so this is
the first library I got to know in the Robot Framework. 

To test `Request` library we can install Pi-GPIO-Server on Raspberry Pi.
Server is able to control state of input and output of GPIOs using REST API.

Project is availiable on link: [Project weekend - GPIO Server](https://github.com/projectweekend/Pi-GPIO-Server)

In the REST Api we used following methods:
- Delete
- Get
- Options
- Post
- Put
- Patch

To control GPIOs on the RPI we need only `Get` and `Patch` methods, other 
methods are used in the same way - `Options` is used for exceptions.

I assume you have already installed Robot Framework. If response is "NO",
I would like to invite you to read the [Installation paragraph](http://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#installation-instructions)
It is official documentation for Robot Framework. Next we can install requests 
libraries. `Collections` library is a standard built-in library.
Use below commands to install libs:

```
apt-get install python-pip
pip install -U requests
pip install -U robotframework-requests
```

Now we can prepare RPI image. Install `RASPBIAN STRETCH WITH DESKTOP` from 
[download link](https://www.raspberrypi.org/downloads/).
It is very good solution, because we can control also GPIOs using buttons.

![](https://3mdeb.com/wp-content/uploads/2017/10/web_browser_control.png)

I hope that instruction of installation process is sufficient, so I will not 
duplicate the description. Take a few minutes to prepare the pin configuration
and restart gpio server:

```
sudo service gpio-server restart
```

For running server go to Pi-GPIO-Server and type:

```
python pi_gpio_server.py
```

Now, we can start writing code for GPIO control using REST API and Robot 
Framework.

```
*** Settings ***

*** Variables ***

*** Test Cases ***

*** Keywords ***
```

Run RPi and check for its IP address. We will use IP for connection with API 
server. My RPI has IP: 192.168.0.46. Documentation says that server runs on 
`5000` port. So we can prepare URL variable. On `Variables` section type:

```
${URL} http://192.168.0.46:5000
```

Let's run the first test `Get signals`. Firstly we should create session 
for request control in Robot Framework. To create a session we use keyword 
`Create session` with parameters `alias`, `URL ` and optional `verify`. 
[How to create session](http://bulkan.github.io/robotframework-requests/#Create%20Session)

```
*** Test Cases ***

Get signal
Create Session gpio_server ${URL} verify=True
```

We will use `alias` for all keywords which work on URL. All sessions should be
closed using keyword `Delete All Sessions`.
Next we need a header, which should be sent with request. One of the methods for
creating header looks like:

```
Create Dictionary Content-Type=application/json Accept=application/json
```

Good trick is assigning headers to variable. To check the value of GPIO, special
GET method is prepared. [Documentation](https://github.com/projectweekend/Pi-GPIO-Server#read-a-single-pin)
tells:

```
Read a single pin

GET: /api/v1/pin/:num
```

Let's implement it in another way:

```
${pin}= Get Request gpio_server /api/v1/pin/18 ${headers}
```

As I said, `alias` is very important because it defines on which session we send 
requests. For observing results Robot Framework has special keyword. Its name is
`Log`.

Whole test look like this:

```
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

To get all signals you can only type hiperlink without pin number. Example:

```
Get signals
Create Session gpio_server ${URL} verify=True
${headers}= Create Dictionary Content-Type=application/json Accept=application/json
${pinout}= Get Request gpio_server /api/v1/pin ${headers}
Log ${pinout.json()}
```

That was easier part of our script.

To set high or low state for GPIOs you should use `patch` method.
First step is creating dictionary with value to send. It is not difficult:

```
${message}= Create Dictionary value 0
```

`Patch` request requires message data to send.

```
Set 0 signals
Create Session gpio_server ${URL} verify=True
${headers}= Create Dictionary Content-Type=application/json Accept=application/json
${message}= Create Dictionary value 0
${pin}= Patch Request gpio_server /api/v1/pin/18 ${message} headers=${headers}
Log ${pin.json()}
Delete All Sessions
```

We can use the same test to set the high state on GPIO. As an indicator I used 
LED diodes and resistors in series connection.

Full version of my code:

```
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

This code is not in perfect form, but it's not the subject of this article.
So polishing is left to the reader.
RF generates very readable reports after all tests are done.

Reports look like this:
![](https://3mdeb.com/wp-content/uploads/2017/10/report.png)

You can see that Robot Framework is very easy to use environment for testing REST
API. All methods (e.g. POST and Patch) are the same in use. If you need
help with implementing tests you can ask me or chat with users on Slack 
-`requests` channel on robot-framework group. I help new users, whenever I can, 
and also sometime I'm the one looking for help.
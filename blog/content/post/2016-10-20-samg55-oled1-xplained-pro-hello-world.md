---
ID: 62976
title: SAMG55 + OLED1 Xplained Pro Hello World!
author: piotr.krol
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/samg55-oled1-xplained-pro-hello-world/
published: true
date: 2016-10-20 00:00:00
archives: "2016"
tags:
  - embedded
  - Atmel
  - SAMG55
categories:
  - Firmware
  - IoT
---
AMG55 - recognition in the field
---------------------------------

If you are considering working on SAMG55 Xplained Pro board here you will find
some basic know-how to quickly get you started.

#### What you will need?

In this example I will be using SAMG55 Xplained Pro with OLED1 extension board,
and Atmel Studio 7.0 with Data Visualizer addon, wich requires Windows to work.
This however should be similar for other board with EDBG debugger.

![](https://3mdeb.com/wp-content/uploads/2017/07/IMG_0805.jpg)

### Word of explanation

Before we start taking any action:

  * `EDBG` - on board debugger, that will simplify debugging process,
  and allow us to easily program chip without any external tools.
  * `ASF` - Atmel Studio Framework, used for downloading and installing
  useful stuff, like libraries and APIs for specific extensions.

### Getting started

To get to know the code, and typical project setup check out example projects,
you can find there samples for many boards, their extensions and their usages.
e.g. getting MAC address from WIPC1500 or finding avalaible AP using same
board.

Adding Support for extensions
-----------------------------

Get some extension to work with your code may be tricky, and not always will
work out of the box. Let's follow the process of enabling OLED1 Xplained Pro on
SAMG55 Xplained Pro, using ASF Wizard.  As a starting point, im going to use
example project `Getting-Started Application on SAM - SAMG55` wich gives us
simple code that will blink on-board led (LED0). This action however can be
disabled using on-board button (SW0). Our goal is to print on OLED1 display
whether function is currently on, or off.  To do that, we will need to add
OLED1 libraries first. You could add them by hand, but there is a tool that
will do that for you. Open ASF Wizard, and find there

```
SSD1306 OLED controller (component)
```

select it, and apply changes.

![](/img/Capture.png)

 Now your Solution Explorer got few more files.  You may add simple chunk of
code in the main function:

```
ssd1306_init();
ssd1306_display_on();
ssd1306_clear();
ssd1306_set_column_address(40);
ssd1306_set_page_address(2);
ssd1306_write_text("Hello World");
```

But this will not work yet, you sill need to do some configuration.  Both files
to change you can find in `config/` folder first one is `conf_board.h` In there
you have to add these lines:

```
#define BOARD_FLEXCOM_SPI FLEXCOM5
#define CONF_BOARD_OLED_UG_2832HSWEG04
#define CONF_BOARD_SPI
#define CONF_BOARD_SPI_NPCS1
```

Second one is `conf_ssd1306.h` In which you have to change:

```
# define SSD1306_SPI SPI5
# define SSD1306_DC_PIN UG_2832HSWEG04_DATA_CMD_GPIO
# define SSD1306_RES_PIN UG_2832HSWEG04_RESET_GPIO
# define SSD1306_CS_PIN UG_2832HSWEG04_SS
```

Note, that these values are there twice, one time in `if`, that check whether
your board is XMEGA_C3_XPLAINED or XMEGA_E5_XPLAINED, if it is, then change
these values. For every other board, values can be found at the end of the
file.  In the same place you will find comment explaining their meaning.
comment.  After these changes, all you have to do is connect the board, using
microUSB and connecting it to EDBG USB port, wait for Atmel Studio to find
board, select tool `EDBG`, interface `SWD` and program the chip. After short
amount of time, you will see "Hello World" on display, and blinking led.  To
make it show whether function is active or inactive, change last while loop in
main.c to something like this

```
while (1) {
    if (g_b_led0_active) {
        ioport_toggle_pin_level(LED0_GPIO);
        ssd1306_clear();
        ssd1306_set_column_address(40);
        ssd1306_set_page_address(2);
        ssd1306_write_text("Function is active!");
        printf("1 ");
    }else {
        ssd1306_clear();
        ssd1306_set_column_address(40);
        ssd1306_set_page_address(2);
        ssd1306_write_text("Function is inactive!");
    }
    mdelay(500);
}
```

You might have noticed that `printf("1 ");`, and was wondering where you can
find it's output? Serial console can be opened using Data Visualizer wich is in
tools menu (if you have it installed), on the left side of it is
`configuration` option, that will open panel, with several options to chose
terminal can be opened selecting `External Connection` and `Serial Port`.
Before connecting, remember to change baudrate to `115200`.  Now you are all
set up, and ready to code.

Sources
-------

SAMG55 Xplained Pro documentation

* [Data Gateway Interface](http://www.atmel.com/Images/Atmel-32223-Data-Gateway-Interface_UserGuide.pdf)
* [DGILIB for DGI](http://www.atmel.com/Images/Atmel-42771-DGILib_UserGuide.pdf)
* [EDBG](http://www.atmel.com/Images/Atmel-42096-Microcontrollers-Embedded-Debugger_User-Guide.pdf)
* [SAMG55 Xplained Pro](http://www.atmel.com/Images/Atmel-42389-SAM-G55-Xplained-Pro_User-Guide.pdf)
* [SAMG55 Xplained Pro Datasheet](http://www.atmel.com/Images/Atmel-11289-32-bit-Cortex-M4-Microcontroller-SAM-G55_Datasheet.pdf)
* [SAMG55 Xplained Pro Datasheet summary](http://www.atmel.com/Images/Atmel-11289-32-bit-Cortex-M4-Microcontroller-SAM-G55_Summary-Datasheet.pdf)
* [All SAMG55 Documents](http://www.atmel.com/devices/ATSAMG55.aspx?tab=documents)

OLED1 Xplained Pro Documentation

* [OLED1 Xplained Pro](http://www.atmel.com/Images/Atmel-42077-OLED1-Xplained-Pro_User-Guide.pdf)
* [SSD1306 controller API](http://asf.atmel.com/docs/latest/samg/html/group__ssd1306__oled__controller__group.html)

Summary
-------

![](/img/helloworld_0.jpg)

As you can see, starting with `Atmel SAMG55 Xplained Pro` can be easy. I hope
that provided information are easy to read, and useful. If they are not,
please leave a comment. Thanks for reading.

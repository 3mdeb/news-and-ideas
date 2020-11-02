---
title: GRUB mini–summit opening
abstract: 'GRUB mini–summit 2020. This year we cannot miss this opportunity to meet again
and face the new challenges of GRUB/GRUB2. So,dear reader, feel invited to look
at GRUB2 with a magnifying glass.'
cover: /covers/GRUB.jpeg
author: kamila.banecka
layout: post
published: true
date: 2020-11-02
archives: "2020"

tags:
  - grub2
  - bootloader
  - trenchboot
categories:
  - Firmware
  - OS Dev
  - Security

---
#Intro

 Sometimes we should to stop and look at the tools without which it would be
 difficult to even imagine everyday work. Some of them are so essential, that to
 avoid them means to develop a wheel once again in the history. Such a tool in
 the world of firmware – along with keyboard, fridge and linux – is a dwarf that
 became synonymous with the word bootloader. And by dwarf I mean of course GRUB.
 Last December, we've met with our friend, Daniel Kiper, GRUB upstream
 maintainer and TrenchBoot technical leader inside Oracle. This meeting resulted
 in organization of GRUB minisummit 2019, because we wanted to understand a
 vision of both, GRUB/GRUB2 community and commercial perspective. All the event
 was fruitful and grounded some common path that will be slightly summarized
 below. This year we cannot miss this opportunity to meet again and face the
 new challenges of GRUB/GRUB2. So,dear reader, feel invited to look at GRUB2
 with a magnifying glass.

  **We are starting tommorow**. No axe needed.

![tommorow schedule](/img/Grub.jpg)

Piotr Król, founder of 3mdeb will open the event introducing guests,
contributors, the history of mini-summit and the main goals of the meeting.
After the introduction Michał Żygowski, TrenchBoot contributor from 3mdeb, will
start the first talk dedicated to the GRUB network stack. It will be compared
with other solutions (such as iPXE in terms of performance), because sometimes
in order to recover used operating system we need to boot another operating
system, ().e.g live image to perform recovery operations), where the easiest
method to do so is to boot from network. The last talk, performed by our guest,
Daniel Kiper will bring the inner view for the current GRUB2 project status.
Daniel will tell more about what was done during the recent year, what is
performed now and what are planned priorities for the nearest future. Talks will
end with the opening questions for the Ask Me Anything session, during which the
participants can question related topics and foster discussion.

### Where to link the event?

You will find us on our YouTube 3mdeb channel. All you need to do is joining our
live [here](https://www.youtube.com/channel/UC_djHbyjuJvhVjfT18nyqmQ/live ) in
an appropriate time presented above. **We are starting GRUB mini-summit tommorow
at 04:00 PM CET (UTC+1:00)**.

The next mini-summit days will gather interesting topics concerned on AMD
TrenchBoot, RISC-V support in GRUB2, the Firmware and Bootloader log
specification, license issues and more. Next Tuesday, our special guest from
9elements will introduce us with the XHCI Support in GRUB2. Worthy to wait for,
the full agenda of the next meetings will be updated here and on our SM.

### Whom will you meet?
Prelections will be held by the team of experts and GRUB contributors from
3mdeb, Oracle and 9elements who are happy to answer intriguing questions and
share their passion without creating any marketing pitch.

> The GRUB bootloader is the most common bootloader in the Linux based operating
systems. So, its further development requires close cooperation between
upstream maintainers, OS distributions and other users. The GRUB mini-summit is
a very good place to tighten it. We are going to discuss there current and
future GRUB developments but also challenges facing the project. The topics not
only cover technical aspects but also organizational and legal issues. If you
are interested in the bootloaders and firmware and you want to hear what is
happening in the GRUB world please join us. And we are also interested in
hearing what you expect from the project...

> -- <cite>Daniel Kiper, GRUB maintainer,
TrenchBoot technical leader at Oracle</cite>

> There are no enough evets discussing interfaces between firmware, bootloaders,
and operating systems, especially in the light of recent vulnerabilities and
evolution of firmware interfaces. 3mdeb co-organizing this event with Daniel
Kiper (GRUB maintainer), we would like to raise awareness about the value
produced in the effect of community and business collaboration. We also would
like to build a platform to discuss the interface between firmware and
bootloader, bootloader feature set and issues, and the interface between
bootloader and OS. We hope this activity will convince silicon vendors, their
OEMs/ODMs, and system developers that supporting the GRUB2 community can speed
up the adoption of advanced security and hardware features.

> -- <cite>Piotr Król, founder of 3mdeb</cite>

### GRUB mini-summit 2019

Last year we have decided to talk over some key issues:
    * Redundant GRUB2 env file
    * TPM support in GRUB2 for legacy boot mode
    * overview of GRUB2 security features
    * Python 3 support in GRUB2
    * AMD TrenchBoot support in GRUB2

Thank you community for being there with us, for raising your voices and
fostering discussion that has it's reflection in GRUB2 contributions of 2020.
All the summary of raised issues you will find in our previous GRUB blogpost
[here](https://blog.3mdeb.com/2020/2020-02-19-grub2_and_3mdeb_minisummit/). We
are waiting tommorow, once again for your prespective, ideas and voice. Let's
meet and talk over the important issues with GRUB/GRUB2 contributors. GRUB will
always be the core axe of 3mdeb toolbox.

![grubin3mdeb](/img/GRUBin3mdeb.png)

## Summary

If you need bootloader support or you think we can help in improving the
security of your firmware or you looking for someone who can boost your product
by leveraging advanced features of used hardware platform, feel free to book a
call with us or drop us email to contact<at>3mdeb<dot>com. If you are interested
in similar content feel free to sign up to our newsletter.

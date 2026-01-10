---
ID: 63031
title: Failure of ECC508A crypto coprocessor initial triage with SAM G55
       Xplained Pro Evaluation Kit
author: piotr.krol
post_excerpt: ""
layout: post
private: false
published: true
date: 2016-11-24 15:37:26
archives: "2016"
tags:
  - embedded
  - Atmel
categories:
  - Firmware
  - Security
  - IoT
---

Some time ago (around August 2016) embedded community media were hit with hype
around simplified flow for AWS IoT provisioning
([1](http://www.embedded.com/electronics-products/electronic-product-reviews/safety-and-security/4442551/Crypto-chip-simplifies-AWS-IoT-security),
[2](http://www.embedded.com/electronics-blogs/max-unleashed-and-unfettered/4442574/Single-chip-end-to-end-security-for-IoT-devices-connected-to-Amazon-cloud),
[3](http://www.embedded.com/electronics-news/4423245/Microchip-goes-to-the-Cloud-for-IoT-design)).
I'm personally very interested in all categories related to those news:

- IoT - is 3mdeb business core and despite this term was largely abused these
  days, we just love to build connected embedded devices. Building this kind of
  devices is inherently related with firmware deployment, provisioning and
  update problems.

- AWS - truly it is had to find similar level of quality and feature-richness
  and because I was lucky to invest my time and work with grandfather of AWS IoT
  (namely 2lemetry ThingFabric) I naturally try to follow this trend and make
  sure 3mdeb customers use best in class product in IoT cloud segment. To
  provide that service we try to be on track with all news related to AWS IoT.

- Security - there will be not so much work for Embedded System Consultants if
  IoT will be rejected because of security issues. I'm sure I don't have to
  convince anyone about important of security. Key is to see typical flow that
  we face in technology (especially in security area):

```bash
mathematics ->
proof of concept software ->
mature software ->
hardware acceleration ->
hardware implementation
```

AWS IoT cryptography is not trivial and doing it right is even more complex.
Using crypt chips like ECC508A should simplify whole workflow.

Initial idea for this blog post was to triage ECC508A with some Linux or mbed OS
enabled platform. Atmel SAM G55 seem to have support in mbed OS
[here](https://github.com/ARMmbed/target-atmel-samg55j19-gcc), but diving into
[CryptoAuthentication](http://www.atmel.com/products/security-ics/cryptoauthentication/default.aspx)
with development stack that I'm not sure work fine is not best choice. That's
why I had to try stuff on Windows 10 and then after understanding things better
I move to something more convenient.

I mostly relied on
[ATECC508A Node Authentication Example Using Asymmetric PKI](http://www.atmel.com/applications/iot/aws-zero-touch-secure-provisioning-platform/default.aspx?tab=documents)
Application Note.

What we need to start is:

- [Atmel Studio](http://www.atmel.com/tools/atmelstudio.aspx#download)
- [AT88CKECC-AWS-XSTK](http://www.atmel.com/tools/at88ckecc-aws-xstk.aspx)

## Atmel Studio

Welcome in the world of M$ Windows. I wonder who get idea of excluding Mac and
Linux users from Atmel SAM developers community, but this decision was really
wrong. Of course there are options like
[ASF](http://www.atmel.com/tools/AVRSOFTWAREFRAMEWORK.aspx) but this requires
much more work for setup and is probably not feasible for initial triage post.
Unfortunately number of examples in ASF is limited and I can't find anything
related to crypt or i2c.

Atmel Studio is obviously inspired or even build on Visual Studio engine.

### CryptoAuthentication Node Basic Example Solution

To make things simple `CryptoAuthentication Node Basic Example Solution.zip`,
which you can be downloaded
[here](http://www.atmel.com/applications/iot/aws-zero-touch-secure-provisioning-platform/default.aspx?tab=documents)
is 15MB and contain almost 2k of files. Download and unpack archive.

After starting Atmel Studio choose `Open Project...`, navigate to
CryptoAuthentication example and choose `node-auth-basic` you should get funny
pop-up that tells you to watch out for malicious Atmel Studio projects:

{% img center /assets/images/atmel_studio_02.png 640 400 'image' 'images' %}

Then you have window with info `Please select your project`, so choose
`node-auth-basic`, then try `Build -> Rebuild Solution`, of course this doesn't
work out of the box.

One of problems that I faced was described
[here](https://web.archive.org/web/20170724192734/asf.atmel.com/bugzilla/show_bug.cgi?id=3715)
this is just incorrect `OPTIMIZE_HIGH` macro. After fixing that both examples
compile fine.

I realized that Atmel Studio use older ASF (3.28.1) then what is available
(3.32.0), but upgrading ASF leads to upgrading whole project and take time.
After upgrade you get report if everything went fine for your 2k files.

The problem with `node-auth-basic` is that it is not prepared for SAM G55. Whole
code in `AT88CKECC-AWS-XSTK` documents target SAM D21. So you have to change
target device and this is possible only after update. To change device enter
`node-auth-basic` project properties and got to `Device` tab, then use
`Change Device` find `SAMG` family and use `SAMG55J19`. Please note that SAM G55
devices are not visible if not change `Show devices` to `All Parts`. Result
should look like this:

{% img center /assets/images/atmel_studio_01.png 640 400 'image' 'images' %}

I can only imagine how outdated this post will be with next version of Atmel
Studio.

Now we get more compilation errors:

```bash
Error       sam/sleepmgr.h: No such file or directory   node-auth-basic \
C:\(...)\cryptoauth-node-auth-basic\node-auth-basic\src\ASF\common\services\sleepmgr\sleepmgr.h 53
```

With above problem I started to think I'm getting really useless expertise. The
issue was pretty clear - we compile for SAMG not for SAMD and we need different
header.

### ASF installation madness

Moreover when I tried to reinstall ASF I had to register on Atmel page which
complained on LastPass and identify my location as Russian Federation (despite
I'm in Poland). Of course Atmel Studio open Edge to login me into their website.
This whole IDE sucks and do a lot of damage to Atmel - how I can recommend them
after all that hassle ? Then after going through password/login Windows 10
detect that something is wrong with Atmel Studio and decided that it have to be
restarted. What I finally started installation I get this:

```bash
2016-11-26 23:46:10 - Microsoft VSIX Installer
2016-11-26 23:46:10 - -------------------------------------------
2016-11-26 23:46:10 - Initializing Install...
2016-11-26 23:46:10 - Extension Details...
2016-11-26 23:46:10 -   Identifier      : 4CE20911-D794-4550-8B94-6C66A93228B8
2016-11-26 23:46:10 -   Name            : Atmel Software Framework
2016-11-26 23:46:10 -   Author          : Atmel
2016-11-26 23:46:10 -   Version         : 3.33.0.640
2016-11-26 23:46:10 -   Description     : Provides software drivers and libraries to build applications for Atmel devices. The minimum supported ASF version is 3.24.2.
2016-11-26 23:46:10 -   Locale          : en-US
2016-11-26 23:46:10 -   MoreInfoURL     : http://asf.atmel.com/docs/latest/
2016-11-26 23:46:10 -   InstalledByMSI  : False
2016-11-26 23:46:10 -   SupportedFrameworkVersionRange : [4.0,4.5]
2016-11-26 23:46:10 -
2016-11-26 23:46:10 -   Supported Products :
2016-11-26 23:46:10 -           AtmelStudio
2016-11-26 23:46:10 -                   Version : [7.0]
2016-11-26 23:46:10 -
2016-11-26 23:46:10 -   References      :
2016-11-26 23:46:10 -
2016-11-26 23:46:14 - The extension with ID '4CE20911-D794-4550-8B94-6C66A93228B8' is not installed to AtmelStudio.
2016-11-26 23:46:28 - The following target products have been selected...
2016-11-26 23:46:28 -   AtmelStudio
2016-11-26 23:46:28 -
2016-11-26 23:46:28 - Beginning to install extension to AtmelStudio...
2016-11-26 23:46:29 - Install Error : System.IO.IOException: There is not enough space on the disk.

   at System.IO.__Error.WinIOError(Int32 errorCode, String maybeFullPath)
   at System.IO.FileStream.WriteCore(Byte[] buffer, Int32 offset, Int32 count)
   at System.IO.FileStream.Write(Byte[] array, Int32 offset, Int32 count)
   at Microsoft.VisualStudio.ExtensionManager.ExtensionManagerService.WriteFilesToInstallDirectory(InstallableExtensionImpl extension, String installPath, ZipPackage vsixPackage, IDictionary`2 extensionsInstalledSoFar, AsyncOperation asyncOp, UInt64 totalBytesToWrite, UInt64& totalBytesWritten)
   at Microsoft.VisualStudio.ExtensionManager.ExtensionManagerService.InstallInternal(InstallableExtensionImpl extension, Boolean perMachine, Boolean isNestedExtension, IDictionary`2 extensionsInstalledSoFar, List`1 extensionsUninstalledSoFar, IInstalledExtensionList modifiedInstalledExtensionsList, AsyncOperation asyncOp, UInt64 totalBytesToWrite, UInt64& totalBytesWritten)
   at Microsoft.VisualStudio.ExtensionManager.ExtensionManagerService.BeginInstall(IInstallableExtension installableExtension, Boolean perMachine, AsyncOperation asyncOp)
   at Microsoft.VisualStudio.ExtensionManager.ExtensionManagerService.InstallWorker(IInstallableExtension extension, Boolean perMachine, AsyncOperation asyncOp)
```

This should be enough to throw it away. Of course I have ~500MB on disk, but
this is not enough. I assume that MS way in Windows 10 of providing information
to user is throwing exceptions or this was method of handling lack of free space
in Atmel Studio.

## I gave up

Couple more things that I found:

- There is no easy way to convert examples for ECC508A to make them work with
  SAMG55 as those examples are mostly created for SAMD21. Clearly Atmel do a lot
  noise about 250USD kit for which you don't have examples.
- CryptoAuthentication library doesn't have HAL for SAMG55
- Atmel engagement in process of supporting community is poor, what can be found
  here
  [1](https://web.archive.org/web/20200812204110/https://community.atmel.com/forum/provisioning-and-accessing-atecc508a),
  [2](https://web.archive.org/web/20200812213157/https://community.atmel.com/forum/atecc508a-i2c-input-capacitance-ci)
- Full datasheet is available only under NDA

## Summary

I waste lot of time to figure out that evaluation of well advertised product is
terribly difficult. I'm sure that lack of knowledge of Atmel ecosystem probably
added to my problems. I also didn't bother to contact community, which is not
fair to judge from my side.

Key idea behind this triage was to check ECC508A in environment suggested by
manufacturer. It happens that manufacturer didn't prepare infrastructure and
documentation to be able to evaluate product in advertised way. Initial triage
was needed for implementation in more complex system with Embedded Linux on
board. Luckily during whole this process I found
[cryptoauth-openssl-engine](https://github.com/AtmelCSO/cryptoauth-openssl-engine)
Github repository. Which I will evaluate in next posts.

If you will struggle with similar problems and pass through some mentioned above
or you successfully triaged `ECC508A` on `AT88CKECC-AWS-XSTK` please let me
know. Other comments as always welcome.

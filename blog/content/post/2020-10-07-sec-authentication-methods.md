---
title: Secure ways for user authentication
abstract: 'This is an introductory article for people that want to learn how to
be secure in the modern digital world. You will be presented with a description
of common practices and ways to enhance your safety.'
cover: /covers/sec-ways-authentication.jpg
author: pawel.czaplewski
layout: post
published: true
date: 2020-10-07
archives: "2020"

tags:
  - Password managers
  - Multi Factor Authentication
  - Security Tokens
  - MFA
  - OTP
  - FIDO
categories:
  - Security

---

# Secure ways for user authentication

_In the article:_

*   _Password managers, Multi Factor Authentication, Security Tokens, FIDO_

This is an introductory article for people that want to learn how to
be secure in the modern digital world. You will be presented with a description
of common practices and ways to enhance your safety

## Introduction

Password is the most popular security mechanism to prevent unwanted access to
private resources. Services requiring password authentication are ubiquitous
therefore a lot of people are using similar passwords for each. This is because
remembering a lot of **safe** passwords is very inconvenient. One possible
solution is to have a password manager that keeps track of your passwords. 

→ zdj/ tabela przykładowe managery haseł

Password manager (e.g. LastPass) work in a way that it automatically fills up
previously entered credentials to the services you want to log in. To use such
a password manager the user must remember only one master password. Password
manager is a very versatile tool that enhances the user's safety - it may be a
browser extension, desktop application or a mobile app. If you are still
struggling with remembering passwords for your services, employing the password
manager is an easy first step you should take in order to enhance your security. 

I, personally, use LastPass ([https://www.lastpass.com/](https://www.lastpass.com/))
as a browser extension - features I like the most are storing secure notes on
the online account and password generator - I don’t even have to make passwords
up! Brilliant.

### What if you feel like you need more security?

Password managers are a good alternative for remembering passwords, but they
still require a password - in case of the master password leakage it may have
even worse consequences. A countermeasure to address this issue is
**Multi-Factor Authentication**. The main idea behind it is that the service
requires from you proving that you are truly the person you claim to be in more
than one way.

MFA generally refers to five types of authentication factors which are expressed
as:

1. **Knowledge**: Something the user knows, like username, password, or a PIN.
2. **Possession**: Something the user has, like a safety token.
3. **Heritage**: Something the user is, which can be demonstrated with
   fingerprint, retina verification, or voice recognition.
4. **Place**: Based on the user’s physical position.
5. **Time**: A time-based window of opportunity to authenticate like One-Time
   Password. An example of this may be Google Authenticator app, or a physical
   device displaying OTP on demand.

### What if you need to secure your assets to the extent?

Security token is considered to be one of the best authentication factors, based
on the fact that you have to possess a unique token - one and only device that
is binded to a service using MFA. In simple words usually it is a physical
device that stores cryptographic secret keys. How does it work? The device has
to have a way to **provision** the secret key (saving relevant entry on the
device while registering), additionally it must somehow interface with other
devices requiring authentication - this may be done via USB, NFC or BLE. The
process of validation and issuing the requested secret is called **attestation**.

Another reason speaking for the security tokens is that they do not store any
personal data, hence in case you lose your token you don’t have to worry about
it too much - the only thing you have to do is to disable the device from your
services’ authentication methods. Doing so is similar to putting your credit
card on hold. Obviously to login to the service to disable it will require from
you an emergency authentication method.
Having an backup authentication is a wise thing to consider.

Based on the Google Authenticator comments a lot of the people who have used the
app for a longer time have permanently lost access to some accounts - I've also
learned it the hard way - I restored factory settings on the phone **and**, as
it later turned out, lost the backup codes...

_Sidenote: Google Authenticator is the only application (or one of the few)_
_where you cannot interact with your google account e.g. you can’t make a_
_backup. It works offline._


## Summary


Stay tuned for the next part that will present you with practical use of a
security token and more of technical analysis of FIDO protocol and hardware used.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

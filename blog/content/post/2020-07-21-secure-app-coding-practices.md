---
title: Secure Application – Best coding practices
abstract: "When building an application, we must assume that it will be exposed to hackers at all times and may be misused by ordinary recipients. The danger of the first group seems obvious, but what kind of risk bring standard users?"
cover: /covers/secure-app.jpg
author: malwina.mika
layout: post
published: true
date: 2020-07-22
archives: "2020"

tags:
  - security
  - snyk
  - helmet
  - hackers
  - vulnerability
categories:
  - Development
  - App Dev
  - Security
---

When building an application, we must assume that it will be exposed to hackers at all times and may be misused by ordinary recipients. The danger of the first group seems obvious, but what kind of risk bring standard users? You must know that attempts to "cheat the system" are quite common, especially in the e-commerce industry. There is a group of users who count, for example, on errors in calculating discounts or the number of elements. You can expect that if you have an online store, there will be at least a few people who will try to use your site in such a way to find a vulnerability. Therefore, we must be really careful when building an application. We cannot count on everyone to act according to our plan. A secure application is the one in which the author assumes the opposite scenario - such that everyone wants to find a vulnerability in our system. Only such an approach, and then appropriate protection, can give us at least a substitute of security.

We will try to approach the topic from a slightly easier side - what are the best practices for writing secure web applications?
There are many of them, but here we'll cover some very basic rules to keep in mind.

### Hide sensitive data

This may seem obvious to you but the passwords for our accounts are so important that we should protect them as tightly as possible.
If you make a test app and keep it in your repository you can say it doesn't matter. However, have you really not used this password somewhere? Hackers know very well that most internet users often use the exact same combination of characters. So you can expose yourself to the fact that someone will try to use the login data found, e.g. on Twitter or Google account. So instead of setting the password directly in the configuration files in your codebase, you can use a reference to an [environment variable](https://docs.microsoft.com/en-us/aspnet/core/security/app-secrets?view=aspnetcore-3.1&tabs=windows/)

However, when others can look into the code, they are able to point out those security issues, maybe even fix it. That's why hiding the code makes it harder to fix than to break. Moreover, though that keeping your server code on the repository, even without passwords, can be risky. If your script has any vulnerabilities, the hacker will be able to easily detect them, and then attack the application published, for example to download data from the database using it.

### Strong password

Hiding your password won't do anything if it's just weak. It worth to remember that hackers often operate on powerful hardware that makes code-cracking applications extremely efficient. How can we protect ourselves against it? The attack called "Dictionary Attack" tries the most popular combinations from words that already exist. That can be phrases or words from the dictionary.
The most efficient way to fight against this attack is to use a password containing at least 14 characters that includes special characters, numbers, letters lower and upper cases. It is also very important to not use the same password for everything, they must be all different. It can be useful to use a password manager, such as [LastPass](https://blog.lastpass.com/2018/01/sites-protect-password-manager.html/). However, this is the minimum that we should stick to. It is difficult to create an exact list of requirements, as these often change, e.g. until recently it was a very popular practice to force users to periodically change their password. Meanwhile, Microsoft says, based on its experience, that this approach does more harm than good. Out of laziness, users choose almost identical passwords anyway, changing only one of the last characters, which is why, for example, in their [new guidelines](https://docs.microsoft.com/en-us/microsoft-365/admin/misc/password-policy-recommendations?view=o365-worldwide/) for Office 365, the technological giant recommends abandoning this idea.


### Always validate the data also on the server

The validation written on a frontend side (like give attribute "requied" to the text input), we are able to turn off these items in the development tools. Validations written in JavaScript can also be modified on the fly, or you can simply turn off JavaScript.
After setting the "E-mail" and "Password" fields as required in HTML, validation is very easy to bypass. It is enough to enter the inspector, change a few elements and the form can be sent even if the validation conditions are not met. Therefore, treat the frontend validation as an improvement to UX, which is to be a help for the user. In terms of security, server-side validation is much more important. The user is not able to turn it off and at best can look for vulnerabilities to somehow cheat it. There is a technique that allows an adversary to insert arbitrary SQL commands in the queries that a web application makes to its database. It can work on vulnerable webpages and apps that use a backend database like MySQL, Oracle, and MSSQL. We are talking here about SQL Injection.  

### Try… catch mistakes

Working with external libraries, these may have different error notification systems. Some just "throw" Error, others print exact messages, and some let us decide ourselves how to behave in case of a problem. However, we do not want JavaScript throwing the default error content to the user, because it is often incomprehensible and can expose us to leakage of sensitive data. It is therefore important to use the Try… catch block to control the errors.

### Keep your web app updated

It is better to use popular and valued packages. Pay attention to the number of editions, downloads and the date of the last update. It is very important that the package is still supported. Then, even if any gaps are found, they should be patched quickly.

Avoid packages that the author himself describes as deprecated. Even if you think a package is perfect for your needs, it's quite possible that in many cases it won't work properly with your code. In addition, there is a good chance that it has some security flaws. Remember that IT is an extremely dynamic industry.
Also to avoid vulnerabilities that are present in any framework or library, you should make sure you actually use all the libraries integrated into your software and use the latest version of each library, if it’s stable.

### Security Tools that may be useful to you

If any gaps are found, the authors of the packages try to patch them. In order for your app to take advantage of these changes (fixes), you need to update them as needed. Unfortunately, we often have so many of them that checking each of them manually would be quite a breakneck task. So a good solution may be to use a tool called **Snyk**. It automatically checks the GitHub repository and reports on possible dangers. You can use it online at [this link](https://snyk.io/test/).

In addition to the above good practices, the use of the **helmet** package is standard. Its task is to properly set the HTTP headers so that our server is less vulnerable to attacks. A description of all functionalities can be found at [here](https://helmetjs.github.io/). Take this package as a basis and something that will as much as possible hamper attacks that could take advantage of the weaknesses of the header settings.

## Summary

The more extensive and complex the application, the more vulnerabilities is in it. If its role is sensitive (e.g. creating a bank's website), we will be exposed to more attacks, and these can often be extremely sophisticated. So we are not able to prepare ourselves for a threat in 100%.  Nevertheless, we must try to minimize the danger. Securing your applications is very important and the industry is constantly evolving. Important systems must be analyzed on an on going basis and, if necessary, adjusted to deal with new forms of attacks. Only this approach gives us a relatively large guarantee as to safety.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/gfoekD)

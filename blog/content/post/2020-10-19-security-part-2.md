---
title: Application Security as an Every Developer's Responsibility
abstract: "The issue of web application security is becoming more and more popular. Currently, not only large organizations and corporations but also smaller businesses are forced by progress to transfer some of their activities to the Internet."
cover: /covers/image-file.png
author: piotr.nowoslawski
layout: post
published: true
date: 2020-10-19
archives: "2020"

tags:
  - security
  - application security
categories:
  - Development
  - App Dev
  - Security
---

The issue of web application security is a topic that is becoming more and more popular. Currently, not only large organizations and corporations, but also smaller and smaller businesses are forced by progress to transfer some of their activities to the Internet. This process has accelerated even more because of the current popularity of all electronic devices and changes in the way people communicate remotely.

While large business entities have been operating in the realities of application security for a long time, smaller entities have very little or no knowledge of how to adapt to these new, demanding conditions without exposing themselves to business risk. Unfortunately, the risk of operating in digital markets only increases. Due to increasingly stringent regulations, the loss or disclosure of data has very serious consequences. These can be financial penalties, loss of reputation or customer trust, which ultimately translates into a bad financial result, and in the worst case it will lead to the collapse of the company.

In this situation, it should be emphasized that we, developers, should be responsible for the security of the provided solutions.

### Why should we care?

Let's focus on the risk in more detail. At the beginning, we need to be aware of what can happen if a data leak occurs in the company.

The first noticeable effect may be financial penalties related to violation of the law or non-compliance with the industry certification. We operate in an environment of data processing regulations such as [GDPR (General Data Protection Regulation)](https://eugdpr.org/) in the European Union, [HIPAA (Health Insurance Portability and Liability Act)](https://www.hhs.gov/hipaa/for-professionals/privacy/laws-regulations/index.html) in the USA and [PCI DSS (data security standard in the payment card industry)](https://www.pcisecuritystandards.org/pci_security/) around the world. On the Internet, we can find a lot of cases where the amount of fines in relation to violations of these regulations is described. Penalties are counted in thousands of euros, which affects the imagination how they can affect the company. It is also worth adding that the imposed penalties are not the end of costs. Incidental costs such as legal services, courts, etc. must be taken into account.

Let's say we have already paid the penalty costs. As a next step, we have to make up for these losses somehow, but our application still earns for itself? If the leak was serious and third parties have suffered, we may loose the reputation along with the regular and new customers. The situation may be enhanced by competitors, to emphasize the favorable situation for them, as our clients will also learn.

Finally, there will be problems such as our ranking in Google, which will have a negative impact on sales very quickly.
Google is constantly investigating whether we use best security practices such as TLS / SSL, which are used to encrypt traffic and ensure the confidentiality and integrity of data transmission, as well as server and sometimes customer authentication.

The bottom line is that there is no argument that would challenge making security a priority. Disregarding it does not pay off, and the seemingly saved costs may bring about the opposite result than intended.

### How to deal with security challenges?

The first step is the right approach to the software development process.

There are some rules to follow:

- continuous improvement through own development and training in the organization,
- sharing knowledge about safety in the team,
- taking responsibility for not releasing an underdeveloped product under time pressure,
- good understanding of the impact of risk on the business aspects of operations,
- following external guidelines such a OWASP,
- primarily treating safety as priority, not a necessary evil

The rules are obvious, but how many cases do we really stick to them? In how many cases are we not looking for the best solutions or we do not pay enough attention to tests due to the race against time?

We have to answer these questions ourselves. Being aware of your own approach is the beginning of the road to trying to combine speed and security when developing software.

### What's next? Know your enemy.

Fortunately, the problems we face are similar for all developers and there are organizations that work to describe most of them and teach others how to protect themselves from outside threats. Therefore, we do not have to reinvent the wheel.

##### OWASP (Open Web Application Security Project)

is a nonprofit foundation that works to improve the security of software. [OWASP page](https://owasp.org/)

This organization publishes a list of the most common errors in web applications. This list was established in 2017 and is based on real data obtained from companies, organizations and professionals involved in security testing.

##### The current list for 2020:

- Injection

Code injection occurs when an attacker sends invalid data to a web application with the intent to do something the application was not designed to do.

- Broken Authentication

Broken authentication vulnerability could allow an attacker to use manual or automated methods to take control of any account on the system or worse, to gain complete control of the system.

- Sensitive Data Exposure

Exposure of sensitive data is one of the most common vulnerabilities on the OWASP list. It involves the disclosure of data that should be protected.

- XML External Entities (XXE)

An XML External Entity attack is a type of attack against an application that parses XML input. This attack occurs when XML input containing a reference to an external entity is processed by a weakly configured XML parser.

- Broken Access control

Broken access control means limiting which sections or pages visitors can reach, depending on their needs.

- Security misconfigurations

The problem may be related to, for example, keeping the default CMS configurations. There are settings you can adjust to control comments, users, and visibility of user information. File permissions are another example of a default that can be strengthened.

- Cross Site Scripting (XSS)

XSS is a widespread vulnerability that affects many web applications. XSS attacks involve injecting malicious client-side scripts into a website and using that website as a propagation method.

- Insecure Deserialization

An example of this type of security risk is a super cookie that contains serialized information about a logged in user. This cookie defines the role of the user and could be a vulnerability that may endanger the entire web application.

- Using Components with known vulnerabilities

Today, even simple websites like personal blogs have many dependencies.
We can all agree that not updating every software on the backend and front end of the website will no doubt introduce serious security threats sooner rather than later.

- Insufficient logging and monitoring

The importance of website security cannot be underestimated. There are ways to monitor your site regularly so that you can take immediate action when something happens. Lack of an efficient login and monitoring process can increase the damage caused by a website hack.

[Official website of the organization](https://owasp.org/www-project-top-ten/)

The list is periodically published and importantly, consists only 10 points. This makes it easy to analyze and understand, making it a good start to taking a serious approach to security in your organization.

OWASP list should be included in every software development project.
It is the best set of security requirements and best practices, and most importantly, it works!
Following and implementing the OWASP recommendations has only positive consequences and teaches you to apply the best available practices.


### 3mdeb role in the security world:

As a company, we specialize in developing embedded software, embedded operating systems and applications. We work with an emphasis on solutions based on open source code. Due to the area of operation, security is one of the most important factors taken into account in the solutions we implement.

[Here You can find projects we have participated in and our commits to open repositories.](https://opensource.3mdeb.com/)
Seek for an inspiiration in our [blog](https://blog.3mdeb.com/) or check how we present our solutions [to the world](https://3mdeb.com/events/)

### Summary

In summary, the software company and developers have the greatest impact on online security. It is determined by the right approach and emphasis on security in the produced software, the use of the latest tools, as well as making clients aware of the dangers. Developers must prioritize security, because this is the only way to protect the interests of customers and their own. The amount of regulations imposed on companies operating in the field of IT and e-commerce will only increase. So is the number of attacks and attempts to get into the systems of unauthorized persons.

The sooner we implement the appropriate processes, the sooner we will be ready for future threats and the same our value in the eyes of customers will pay off.

If you think we can help in improving the security of your firmware or you
looking for someone who can boost your product by leveraging advanced features
of used hardware platform, feel free to [book a call with us](https://calendly.com/3mdeb/consulting-remote-meeting)
or drop us email to `contact<at>3mdeb<dot>com`. If you are interested in similar
content feel free to [sign up to our newsletter](http://eepurl.com/doF8GX)

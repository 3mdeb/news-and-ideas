---
author: Piotr Król
layout: post
title: "AWS as IoT cloud provider of choice"
date: 2016-12-06 23:30:12 +0100
comments: true
categories: aws iot embedded cloud linux
---

First 2 words about history. At the beginning of my consulting career (end of
2014) I was lucky to provide analysis of existing IoT cloud providers for one
of my first customers. We considered lot of various options starting from Xively, IBM
Bluemix, Spark.io, Sensor Cloud, Weaved, Thingsquare, Axeda, Temboo and 2lemetry.

Our requirements were:
* support for TI CC3200 platform
* MQTT as protocol of choice
* clear documentation that can be understood by senior embedded system
  developer
* reasonable pricing model and free access for evaluation

Some option were dropped at beginning other during communication or evaluation.
There was really one reasonable option for us to start work with and it was
2lemetry with its Thing Fabric product.

What was unique for Thing Fabric was shadow concept. It aimed to mimic behavior
of device in cloud to make sure that device will have correct state even if it
is offline at point of setting it. High quality support and API explorer added
to rapid triage and approval of Thing Fabric as our IoT platform.

After some time (November 2015) 2lemetry IoT was acquired by Amazon and
corporate level architects and developers improved service and made it one of
the best IoT cloud platform that exist these days.

## Theory of operation

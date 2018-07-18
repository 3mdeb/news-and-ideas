---
ID: 63076
post_title: >
  How to handle a DHT22 sensor using ARM
  mbed OS?
author: Michał Żygowski
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/firmware/how-to-handle-a-dht22-sensor-using-arm-mbed-os/
published: true
post_date: 2017-08-01 14:14:55
tags:
  - Mbed
  - STM32
  - Sensors
  - Measurements
  - DHT22
  - 1-wire
  - STMicroelectronics
categories:
  - Firmware
  - IoT
---
Recently I have encountered with temperature and humidity measurements using DHT22 sensor. I was developing a driver source code in ARM mbed OS SDK on particular STM32 NUCLEO L432KC platform. Thorough analysis of DHT22 [documentation][1] led me to the following questions: 
*   Is it possible to accurately measure voltage-level durations during read process?
*   What duration time values should be considered as timeout or/and error?
*   Should I weaken the time restrictions in order to avoid random delays in voltage level transitions be considered as failure? For ARM mbed OS documentation please refer to 

[mbed API documentation][2] 
### Configuration Let's start with a little bit of configuration and statistics. The STM32 NUCLEO L432KC is clocked with up to 80MHz frequency which gives a period of 125 nanoseconds, so basically 8 periods sums to 1 microsecond. The 1-Wire pin is configured as an 

`DigitalInOut`, it is necessary to operate both directions, due to communication protocol defined in DHT22 datasheet. Also a timer is enabled to measure voltage level duration. The DHT22 sensor is connected as proposed in section 5 of DHT22 [documentation][1], but I used a 4.7kOhm pull-up resistor between data line and VDD, because 10kOhm resistor was producing too much noise. I also added a 100nF capacitor between GND and VDD for wave filtering. 
### Read process Each read operation can be divided into main 2 steps: 1. Host start signal and sensor response 2. Pure data transfer 

#### Start signal and sensor response Initially the data line should be in high state (high voltage), in this particular case it is 3.3V. High state on the data line is considered as idle. To begin transmission the host must pull the data line down for at least 1 milisecond, it is called a start signal. Then host should pull it up and wait for sensor response. The response should be acquired after 20-40 microseconds. Procedure described above can be basically carried out like that: 

<pre><code class="c">/* Define the data line pin first and a timer*/
DigitalInOut dht_data(DATA_PIN);
Timer timer;

dht_data.output();  //sets the pin in output mode
dht_data.write(0);
wait_ms(2);
timer.reset();
dht_data.write(1);
timer.start();
</code></pre>

**Important** Notice that timer's state is set to 0 before the line is pulled up and then started. Now is the time for sensor's response. After 20-40 microseconds the sensor should pull the line down for 80 microseconds and then pull it up again for 80 microseconds. To detect it, a do-while loop can be used: 
<pre><code class="c">&lt;br />do {
    n = timer.read_us();
    if(n &gt; TIMEOUT) {
        timer.stop();
        return DHT_RESPONSE_TIMEOUT;
    }
    // measure the voltage level duration as long 
    // as data line's state does not change
} while(dht_data.read() == 1);

// reset the timer as soon as data line changes state
// to ensure continuity and validity of voltage level measurement 
timer.reset();
// check
if((n &lt; 20) || (n &gt; 40)) {
    timer.stop();
    return DHT_RESPONSE_ERROR;
}

do {
    n = timer.read_us();
    if(n &gt; TIMEOUT) {
        timer.stop();
        return DHT_RESPONSE_TIMEOUT;
    }
} while(dht_data.read() == 0);

timer.reset();
if(n != 80) {
    timer.stop();
    return DHT_RESPONSE_ERROR;
}

do {
    n = timer.read_us();
    if(n &gt; TIMEOUT) {
        timer.stop();
        return DHT_RESPONSE_TIMEOUT;
    }
} while(dht_data.read() == 1);

timer.reset();
if(n != 80) {
    timer.stop();
    return DHT_RESPONSE_ERROR;
}
</code></pre> At this point we can deliberate about the 

`TIMEOUT` value and the time restrictions provided in the `if` expressions. 100 microseconds seems to be reasonable value for `TIMEOUT`, because there is no voltage level duration longer than 80 microseconds defined by the protocol. Running this code will certainly lead to returning `DHT_RESPONSE_ERROR`. Why? The timer restriction provided in `if` expressions are too strict. Tests conducted by me showed, that `timer` does not always read the same amount of microseconds passed each time I ran this code. The values fluctuated between 70 and even 90 microseconds. This dispersion is unacceptable considering 125 nanoseconds clock period in STM32 NUCLEO L432KC. It inspired me to investigate the hardware layer for possible faults. I have used the logic analyzer to monitor the sensor's data line. The result occurred to be little surprising. The data line waveform I captured is showed below. The sampling frequency was set to 12MHz. ![dht22-response][3] The sensor pulled the line down after ca. 22 microseconds, which is appropriate. But then the voltage level durations differ slightly, they are 1.5 microseconds far from 80. In few cases I observed also a 90 microseconds long low voltage level. To confirm the reliability of this measurement I have additionally connected the data line to oscilloscope. The results were the same as on logic analyzer. These measurements have been taken with two different wiring lengths. With the shorter wiring, voltage level durations were much more repeatable and closer to the sensor's read protocol. So the time restrictions should be provided as follows: 
<pre><code class="c">if((n &lt; 70) || (n &gt; 100)) {
    timer.stop();
    return DHT_RESPONSE_ERROR;
}
</code></pre>

#### Data transfer After sent response, the sensor is transmitting 40 bits of data containing measured temperature, humidity and a checksum. Each bit transfer begins with a 50 microseconds long low voltage level. Then the data line pulls up for 26-28 microseconds or 70 microseconds. The duration of high voltage level determines the bit value: 

*   26-68 microseconds - logic '0'
*   70 microseconds - logic '1' Most significant bit goes first. Reading and storing entire data can be done like this: 

<pre><code class="c">for(int i = 0; i &lt; N_BYTES; i++) {
    for (int b = 0; b &lt; N_BITS; b++) {
        do {
            n = timer.read_us();
            if(n &gt; TIMEOUT) {
                timer.stop();
                return DHT_READ_BIT_TIMEOUT;
            }
        } while(dht_data.read() == 0);

        timer.reset();
        if(n == 50) {
            timer.stop();
            return DHT_READ_BIT_ERROR;
        }

        do {
            n = timer.read_us();
            if(n &gt; TIMEOUT) {
                timer.stop();
                return DHT_READ_BIT_TIMEOUT;
            }
        } while(dht_data.read() == 1);
        timer.reset();

        if((n &gt; 26) && (n &lt; 28)) {
            /* Received '0' */
            buffer[i] &lt;&lt;= 1;
        } else if (n == 70) {
            /* Received '1' */
            buffer[i] = ((buffer[i] &lt;&lt; 1) | 1);
        }
    }
}
</code></pre> As expected, the time restrictions provided in 

`if` expressions lead to returning `DHT_READ_BIT_ERROR`. The reason is the same as mentioned previously in [Start signal and sensor response][4]. Checking the waveform of data line leads to following results: ![dht22-datatransfer][5] Picture above shows a fragment of data bits transfer. The voltage level durations are clearly going beyond the acceptable scope. For example, the 64.42 and 73.58 microseconds long voltage level duration are corresponding to logic '1' sent by the sensor, where it should be 50 and 70 microseconds. On the other hand, next bit sequence is 53.92 and 73.58 microseconds, which is little bit more accurate, but still far away from sensor's specification. Only logic '0' high voltage duration lasts properly long - 26 microseconds. To ensure reading all bytes without returning an error, I have adjusted the time restrictions in `if` expressions with following values: 
<pre><code class="c">if((n &lt; 45) || (n &gt; 70)) {
    timer.stop();
    return DHT_READ_BIT_ERROR;
}

// ...

if((n &gt; 15) && (n &lt; 35)) {
    /* Received '0' */
    buffer[i] &lt;&lt;= 1;
} else if ((n &gt; 65) && (n &lt; 80)) {
    /* Received '1' */
    buffer[i] = ((buffer[i] &lt;&lt; 1) | 1);
}

</code></pre>

> I also have included possible timer inaccuracy to ensure transmission without error returning.  After these changes I was finally able to gather correct measurements repeatedly without failure. To end the transmission, the data line should be pulled up by the host to leave it in an idle state. 
<pre><code class="c">timer.stop();
dht_data.output(); // switch back to output mode
dht_data.write(1);
</code></pre> It is also necessary to implement an interval mechanism to prevent polling the sensor sooner than 2 seconds since last poll. 

## Summary Above steps gave me ability to take temperature and humidity measurements by DHT22. This particular sensor has its pros as well as cons. Its advantage certainly is simplicity in hardware design. Only a pull up resistor, filtering capacitor and 3 wire connections are needed. Its disadvantage is specially designed 1-Wire bus communication. It prevents the usage of common Maxim/Dallas 1-Wire bus standard and forces the developer to implement software driver for handling data reading. Although it is not that difficult, many other problems can occur. As I proved, timing issues are the source of accidental misinterpretation of data and developer confusion. It is recommended to use as short wiring as possible. The tests i have conducted showed, that longer wires have significant influence on the data line waveform and voltage transition timings. The reason of STM32 L432KC timer inaccuracy still remains unknown to me. Despite very high frequency clock (80 MHz), the counted microseconds were different each time I was debugging the code. Taking into consideration the relatively low price and pretty high popularity, dht22 is undoubtedly a good choice, but I have found many versions of documentation which made me a little confused. A standardized one should be provided to eliminate different approaches to handling this sensor. Better datasheet with acceptable timing deviations ought to be published to avoid problems mentioned by me. It took me a significant amount of time to investigate these issues. Hope that this article will help further developers implementing DHT22 sensors in their projects. We are always open for discussion about issues you faced during embedded system development, so please do not hesitate to leave comment below. DHT22 is just one case where do-not-trust-datasheet and read-between-lines rules apply. Malfunction and unexpected behaviour is bread and butter for us. Small problem in prototype may be huge on mass market. If you think we provide valuable information please share this post, also if you are interested in commercial level support we are always open for new challenges. There are many ways to contact us, but easiest would be to drop us email 

`contact<at>3mdeb<dot>com`.

 [1]: https://cdn-shop.adafruit.com/datasheets/Digital+humidity+and+temperature+sensor+AM2302.pdf
 [2]: https://developer.mbed.org/users/screamer/code/mbed/docs/tip/
 [3]: https://3mdeb.com/wp-content/uploads/2017/07/dht22-response.png
 [4]: #start-signal-and-sensor-response
 [5]: https://3mdeb.com/wp-content/uploads/2017/07/dht22-datatransfer.png
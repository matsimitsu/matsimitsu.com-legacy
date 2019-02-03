---
title: How to control an RC car with arduino
date: 2011/05/21
summary: I thought it would be fun to control an RC car with an arduino.
---

A while ago me, [@thijsc](https://www.twitter.com/thijsc) and [@jkreeftmeijer](http://www.twitter.com/jkreeftmeijer)
each bought an arduino starters kit and after the first blinking light it ended up somewhere on my desk.
Today i thought it would be fun to actually do something with it, so i went to the local Intertoys and bought a cheap RC car.

### Requirements

If you want to do the same i suggest you first try it with the cheapest RC car you can find that has:


* 7 way control (forward - left & right, backwards - left & right and stop)
* Runs on 6 volts
* Is big enough to house the arduino and board.
* Doesn't go to fast (it gets really hard to control movement)
* See if the steering wheels return to the center automatically

I ended up with the "Wild Hopper", an offroad buggy.

![Wild hopper](https://d3khpbv2gxh34v.cloudfront.net/p/blog/control_an_rc_car/wild_hopper.jpg)

### Insides

Next step was to take the damn thing apart!

![Wild hopper no more](https://d3khpbv2gxh34v.cloudfront.net/p/blog/control_an_rc_car/wild_hopper_hops_no_more.jpg)

Inside i unscrewed the PCB to see if i could recognize anything. (Click for larger image with pin layout)

![PCB print](https://d3khpbv2gxh34v.cloudfront.net/p/blog/control_an_rc_car/print.jpg)

### Wiring


I Googled for the numbers on the PCB (SW188 top right on the PCB) and it turns out
there is a Chinese (i'm assuming this by the look of the signs) document with the pin layout of the chip!
[Download the pdf here.](https://d3khpbv2gxh34v.cloudfront.net/p/blog/control_an_rc_car/pin_layout.pdf)



Now i had the pin layout it was just a matter of putting current on the pins and the wheels started moving!
I also found out the front weels return to the center position after i disconnected the current. This is really great and saves me a lot of code.
Next i soldered wires to the right pins and a wire to the ground. I added LEDs to all the channels so i could see if the right action was triggered.

![Wiring complete](https://d3khpbv2gxh34v.cloudfront.net/p/blog/control_an_rc_car/wiring_complete.jpg)


As you can see from the photo, I used digital pin 3 to 6 for the four channels (forwards, backwards, left, right)


With everything connected it was time to write the code. I wanted to achieve a simple 3 point turn,
this would require all actions (forward, left, right backwards and stop) so i could see that everything was working ok.

### The code

The code is really simple, I initialize the pins for output and use that and delays to move the car around.

<script src="https://gist.github.com/984611.js"> </script>

### Result

The end result of the day

<object width="425" height="344"><param name="movie" value="https://www.youtube.com/v/oP2s1giB86I?hl=en&fs=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="https://www.youtube.com/v/oP2s1giB86I?hl=en&fs=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="680" height="500"></embed></object>

### What's next?

The next step will be adding sensors so it doesn't crash into every object in the room. More about that in another post!

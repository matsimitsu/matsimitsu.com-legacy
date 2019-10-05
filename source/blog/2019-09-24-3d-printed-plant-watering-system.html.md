---
title: "Automatically water your plants with this 3d-printed system."
date: 2019-09-24 10:00:00 UTC
tags:
published: false
summary: After getting back from a 3-week trip my plants were not in a good mood, there was a heatwave when I was gone and not all plants survived. Time to think of a solution.
---

## Parts
I had most of these parts laying around and it took suprisingly few parts to make this project work. There are probably better options for each part and an ESP8266 might be a bit overkill for what we're doing here, but at less than 2 dollars I am not going to bother with other options.

![IMG_20190924_144612.jpg](https://d3khpbv2gxh34v.cloudfront.net/r/blog/plantr/IMG_20190924_144612.jpg "1.333")

Above you can see the following parts:

* **ESP8266 NodeMCU** ([AliExpress](https://nl.aliexpress.com/item/32647690484.html)). The brains of the operation, easy to use with the Arduino IDE and the surrounding print makes it easy to flash without having to solder certain pins and do other tricks.
* **3v-5v Air pump** ([AliExpress](https://nl.aliexpress.com/item/32815282155.html)). I chose an over-pressure system in favor of a water pump, as I wanted everything enclosed and I'd like to keep water as far away from electronics as possible.
* **Capacitive soil sensor** ([AliExpress](nl.aliexpress.com/item/32829003131.html)). Most projects involving measuring soil water levels use a cheaper double-pronged circut board with metal. It corrodes quite fast, which this Capacitive soil sensor does not.
* **STP16NF06L MOSFET** ([AliExpress](https://nl.aliexpress.com/item/32953020855.html)). The air pump works at 3volt, but not when connected directly to the NodeMCU digital out pin. Instead I hooked it up to the 5V VIN pin and use this mosfet with a digital out pin to trigger the air pump. There are probably better ways to do this, but it was the only thing I had laying around :).
* **4X6 cm Prototype Circut board** ([AliExpress](nl.aliexpress.com/item/1625000537.html)). To solder the wires/Mosfet onto.


## Housing

I didn't want to have some electronics hanging around my plants so it's time to put that 3d printer to good use. I fired up Fusion360 and came up with this design for an enclosure.

It just fits the pump and electronics and "only" takes about 4 hours to print.

![IMG_20190924_145858.jpg](https://d3khpbv2gxh34v.cloudfront.net/r/blog/plantr/IMG_20190924_145858.jpg "1.333")
![IMG_20190924_144650.jpg](https://d3khpbv2gxh34v.cloudfront.net/r/blog/plantr/IMG_20190924_144650.jpg "1.333")


The soil sensor has to go into the plant pot and I'd like to hang the enclosure on the side of the plant pot. This means we need some way for the sensor to connect to the circut board inside the enclosure and ideally without having wires outside of the pot. With a bit of measuring I figured out a place to solder 3 male header pins on the bottom of the circut board and line up a hole in the enclosure. The hole also lets the air in for the pump to function.

![IMG_20190924_144806.jpg](https://d3khpbv2gxh34v.cloudfront.net/r/blog/plantr/IMG_20190924_144806.jpg "1.333")
![IMG_20190924_144820.jpg](https://d3khpbv2gxh34v.cloudfront.net/r/blog/plantr/IMG_20190924_144820.jpg "1.333")

After glue-ing in the circut board and the motor we end up with a nice filled-out enclosure.

![IMG_20190924_144941.jpg](https://d3khpbv2gxh34v.cloudfront.net/r/blog/plantr/IMG_20190924_144941.jpg "1.131")


## Software

Time to load some code onto the NodeMCU.

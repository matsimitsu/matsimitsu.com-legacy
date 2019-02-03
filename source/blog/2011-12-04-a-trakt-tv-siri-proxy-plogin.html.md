---
title: A trakt.tv siri proxy plugin
date: 2011-12-04
tags:
summary: Siri tells you your upcoming tv shows for the night.
---

## Hi, Siri

With the siri proxy gem ([https://github.com/plamoni/SiriProxy](https://github.com/plamoni/SiriProxy)) creating your own fun stuff for iPhone 4s's Siri is pretty straight forward.

## Hi, Trakt

[Trakt.tv](https://trakt.tv) has an amazing API and I wrote a small wrapper (see [lib/trakt.tv](https://github.com/matsimitsu/SiritTrakt/blob/master/lib/trakt.rb)) in the project) to fetch a users's calendar for that night.

## How i did it.


First off make sure you read all the documentation on the proxy github page, setting up the DNS server can be tricky if you don't follow all the steps in the video.

### Naming

Naming is very important for the siri proxy so make sure you do it right! The name you set in the siri proxy config should be the classname you extend the plugin from.
The name downcased should be the gem name (with siriproxy prepended)
It took me a while to figure out and get everything up and running.

### Code

<script src="https://gist.github.com/1428788.js?file=gistfile1.rb"></script>

The listen_for tells the proxy what words to match with the response from apple, the code in the block gets executed when the words match

In the generate_calendar_response i create a new view and add every episode i get from trakt to it. The whole thing gets returned to your iPhone and siri tells you the results :)


## The result

The video below shows the result.

<iframe width="560" height="315" src="https://www.youtube.com/embed/Utu9o5WG1d0" frameborder="0" allowfullscreen></iframe>

As always the code can be found on [GitHub](https://github.com/matsimitsu/SiritTrakt)

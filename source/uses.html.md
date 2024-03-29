---
title: "The tech I use"
subtitle: Inspired by Wes Bos's project <a href="https://uses.tech" class="c-bold-link">uses.tech</a>, here's a list with my (tech) stack.
summary: "Inspired by Wes Bos's project uses.tech, this page is about my (tech) stack."
layout: about
---

## Hardware

* **[Macbook Pro 2020 13"](https://www.apple.com/macbook-pro-13/).** One of the worst MacBooks I've ever had the pleasure of owning. It gets hot and drains the battery at random moments (nothing in activity monitor). USB-C stops working at random moments (won't charge, nor detect new devices plugged in) and the touchpad is horrible to use in warm weather/with sweatty hands. I wish I'd never given away my 2013 MacBook Pro 13".
* **[Keychron K1](https://www.keychron.com/products/keychron-k1-wireless-mechanical-keyboard) keyboard.** A good replacement for the legacy Apple keyboard that stopped working after one too many coffee spills. It's mechanical, but low profile.
* **[Logitech G502](https://www.logitechg.com/en-us/products/gaming-mice/g502-hero-gaming-mouse.html) mouse.** A gamer mouse with weights you can add... Don't really care about that, but it fits nicely in my hand.
* **[LG 34wn80c](https://www.lg.com/us/monitors/lg-34wn80c-b-ultrawide-monitor) curved 34" wide-screen monitor.** Uses USB-C and can charge my MacBook, only one cable is connected to my MacBook and I have power, screen and a USB hub that connects my mouse and keyboard. It has room for many terminal splits which is amazing.
* **[Herman Miller Mirra (V1)](https://www.hermanmiller.com/en_eur/products/seating/office-chairs/mirra-2-chairs/) office chair.** Bought the (refurbished V1's) from my old job and now have 2, one at home and one at the office. One of the best chairs I've owned and they are still as new, while being more than eight years old.
* **[Xiaomi Mi4i](https://www.mi.com/in/mi4i/) phone.** It's cheap (150 euro's), it still lasts two days on a single charge after two years and still gets updates, because of Android One.
* **[Boundary Supply Prima System](https://www.boundarysupply.com/products/prima-system) backpack to carry it all.** A nice backpack that has a camera insert for photograpy gear that can be removed if it isn't needed. Plenty of space for daily groceries and a separate sleeve compartment for the laptop and documents.


## Software

* **[VS Code](https://code.visualstudio.com) is my text editor of choice.** It all started with [Textmate](https://macromates.com) (first seen by me in the famous [15 minute blog video](https://www.youtube.com/watch?v=Gzj723LkRJY&feature=youtu.be) by DHH and the reason for buying Mac). Next was [Sublime text 2](https://www.sublimetext.com/2) and finally VS code with the [RailsCasts](https://marketplace.visualstudio.com/items?itemName=PaulOlteanu.theme-railscasts) color theme that I've been using since Textmate times.
* **[Iterm2](https://iterm2.com).** The terminal that had tabs before the native OSX terminal had them. Never stopped using it. I use the default zsh "robbyrussell" theme.
* **[iA Writer](https://ia.net/writer).** For taking notes in Markdown and writing blogposts / documentation and work/personal todo's.
* **Backups go to [BackBlaze](http://backblaze.com).**. (Raw) photos from my trips, important files etc, all of it goes to Backblaze B2 (their AWS clone, I'm not using the consumer backup service), synced with [Rclone](https://rclone.org).
* For work I mostly have the [Basecamp](https://basecamp.com) and [Slack](https://slack.com/intl/en-nl/) apps open. [Whatsapp](https://www.whatsapp.com) is used for personal communication with friends and family. Other tools used for work are [Docker](https://www.docker.com), [Figma](https://www.figma.com) and [CocoaRestClient](https://mmattozzi.github.io/cocoa-rest-client/). Suprisingly how few apps I have on this MacBook now that I think of it.


## Website

* **[Middleman](https://middlemanapp.com) has been the static site generator for this site for many years now.** Back when it was just released it was a great alternative to [Jekyll](https://jekyllrb.com). It worked with haml/sass out-of-the-box which was all the rage back then. With version 4 they did away with the built-in asset pipeline in favor of webpack. With this change I'm thinking about switching to [11ty/Eleventy](http://11ty.dev), since I'm already pulling in hundreds of `node_modules`, for Webpack/Tailwind etc.
* **I'm using the [Tailwind](http://tailwindcss.com) CSS framework.** I'm not a designer (and it shows ;)) and Tailwind allows me to make everything look somewhat consistent without a lot of effort.
* **Speaking about frameworks, [Stimulus](http://stimulusjs.org) powers the few front-end features on this site.** Things such as the lightbox functionality on the [travel](/travel) part of this site.
* **The only other library used in the front-end right now is [Photoswipe](http://photoswipe.com).** Called by Stimulus to render the fancy lightbox.
* **This site is hosted on [Netlify](https://netlify.com).** A great platform to host your static sites.
* **[GitHub](https://github.com) hosts the code.** You can view the source of this site on [github.com/matsimitsu/matsimitsu.com](https://github.com/matsimitsu/matsimitsu.com).
* **I recently implemented webmentions with [webmention.io](https://webmention.io).** This allows me to show likes for articles and other places where my articles are mentioned.
* **For the few "dynamic" parts of this site, I use [Netlify functions](https://www.netlify.com/products/functions/).** A couple of uses are generating pre-signed AWS upload urls for easy image uploading and a [micropub endpoint](/blog/2020-08-27-iawriter-micropub-netlify-static-site/) to publish notes directly from ia Writer.
* **[AWS S3](https://aws.amazon.com) hosts all photos/videos you can see here.** Cached by cloudfront for improved speed (and reduced costs ;)). The very first versions of this site used to contain the images in the GIT repo, but as more travel pages were added, the amount of photos began to grow steadily. With my requirement to use resized images for mobile/tablets, the size began to grow even more. It quickly became aparent, that storing photos in GIT wasn't working anymore (The amount of photo's generated is now above 10 Gigabytes). I decided to move the photo's to S3 to keep the Git repo workable and wrote a [Rust binary](/blog/2019-03-09-resize-images-from-s3-with-aws-lambda-and-rust/) to resize any image I upload to S3 automatically.

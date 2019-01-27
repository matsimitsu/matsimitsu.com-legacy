---
title: "Blog update: from dynamic app to a static site"
date: 2019-01-27 10:00:00 UTC
tags:
summary: Moving (again) from Rails API + React to a static Middleman
---

## From a static site to a webapp.

A little over a year ago I moved from a (static) Middleman hosted blog to a project called [Daybreakers](https://github.com/daybreakers-co). A Rails API + React App that was focused on creating a platform where you can create "travel blogs". The idea behind it was that it's kind of annoying to create a good looking "photoset" app on a static site platform. As they all dance around the issue on what to do with the photo's.

Most static site generators are meant for blogpost, where the main content is text and not images. Since most people commit their content to Git(Hub), there's also a limit on how many photo's you can add on your blog.

Then there's the issue of hosting, Netlify for example doesn't like to host a ton of photo's. And having a ton of photo's in your static site project doesn't make the build times any faster.

My blog consisted of many photosets, tallying up to around 6 Gigabyte of photos, a nightmare to have in version control and to build a static site with.

## To maintain a webapp.

As is usual with a new project, in the beginning progress was fast and I quickly had a simple app that granted all my wishes. A nice UI to create photosets, a 3rd party that took care of resizing photo's on the fly in great quality and within a few weeks I had transferred over all my posts to this new platform.

But then the attention dropped, as it was doing everything I wanted, and every time I tried to add a new feature I had to make changes in the Rails models, the GraphQL API and in the frontend, making it quite tedious to work on.

After not really touching it for nearly a year, packages started to get outdated and GitHub was notifying me of security issues.

Finally there was the monthly bill to run this entire setup, hosting and the 3rd party costs for storing the photos and the dynamic resize were adding up quickly.

So while this platform did everything I wanted and was a joy to use on trips to create new photosets, it was too costly and too complex to continue, so I made the switch back to Middleman

## From a webapp back to a static site.

I learned a lot from creating Daybreakers and a most of it has gone into this Middleman project, for example resizing is done automatically with AWS Lambda, every time a photo is added to an S3 bucket.

I've also created my own custom markdown extension that adds modifies the standard markdown output regarding images, so my photo's are automatically added to a `<figure>` tag with all kinds of responsive features.

The Daybreakers React frontend did a lot of magic to get the best image for a certain space in the layout, and I managed to replicate most of it with CSS and FlexBox and a sniff of Javascript.

While Daybreakers was really fast (the frontend was hosted on Netlify) it wasn't pre-rendered and with a React App that meant that none of the pages could be indexed. It also took a couple of hundred of milliseconds to get the GraphQL and render it into a page. With this Middleman app it's back to a few milliseconds for a page load.

### Was it worth it?

I'm not sure yet how I'll handle creating a photoset while traveling, as I'm back from a really simple drag-and-drop UI to editing Markdown by hand, but realistically this only happens a few days a year and still takes up a lot less time than to maintain Daybreakers.

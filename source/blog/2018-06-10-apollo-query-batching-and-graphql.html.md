---
title: Apollo Query Batching and graphql-ruby
date: 2018-06-10
summary: Query batching is a way to speed up your application. Instead of waiting on multiple client-server roundtrips to load data, everything is loaded at once.
---
Query batching is a way to speed up your application. Instead of waiting on multiple client-server roundtrips to load data, everything is loaded at once.

Enabling query batching in Apollo is as easy as using another network provider:

<script src="https://gist.github.com/matsimitsu/12a360aae30025b0a1b0415ece32b8d2.js"></script>

On the Ruby you need to make a few more changes, but all can be done in your GraphQL Controller. You need to map the array of given queries to a format that graphql-ruby understands. The gist below handles both batched and non-batched queries.

<script src="https://gist.github.com/matsimitsu/e419cb4c565c5edce12f18768f576f12.js"></script>

Batching queries can reduce the time your app is loading by a large amount, making for a more pleasant user experience.


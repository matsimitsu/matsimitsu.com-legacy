---
title: Upload a file to an AWS pre-signed S3 url with RestClient.
date: 2020-08-29 10:00:00 UTC
summary: "Or, how something so simple cost me so much time."
---

Upload a file to a pre-signed url with Rest-Client.

You'd think that's an easy task, just call:

```ruby
RestClient.post(url, File.new(path, "rb"))
```

And call it a day, but this will leave you with cryptic error messages such as:

```
The request signature we calculated does not match the signature you provided.
Check your key and signing method.
```

There are two things we need to change, first is that Amazon taks the term `putObject` very literal, upload a file with the `POST` method will generate the error above.

```ruby
RestClient.put(url, File.new(path, "rb"))
```

Changing the method to put will clear the cryptic signature error, but you'll notice that any file uploaded will be corrupt. This because RestClient uploads the file as `multipart/form-data`, which is not recognised as a binary file by AWS.

To fix this provide a `content-type` header to RestClient, for example.

```ruby
  RestClient.put(
    url,
    File.new(path, "rb"),
    :headers => {:content_type => "application/octet-stream"}
  )
```

In my case I was uploading images and this worked for me:

```ruby
  RestClient.put(
    url,
    File.new(path, "rb"),
    :headers => {:content_type => "image/jpeg"}
  )
```

Hopefully this will save someone else an hour of debugging AWS request signature calculations :)

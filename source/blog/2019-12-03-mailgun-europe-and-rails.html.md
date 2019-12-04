---
title: "Using MailGun Europe with Rails’s ActionMailer."
date: 2019-12-03 10:00:00 UTC
summary: If you like to use Mailgun's Europe region you need some undocumented settings in the ActionMailer integration to get emails out.
---

You’d think this isn’t worth a blogpost, since Mailgun has a [dedicated `mailgun-ruby` gem](https://github.com/mailgun/mailgun-ruby) for sending emails and it integrates well with Rails’s ActionMailer. However when setting this up last night a couple of errors were thrown my way that took some time to resolve.


## Mailgun::ParseError (765: unexpected token at 'Mailgun Magnificent API')

First, when setting up a new Mailgun domain, it will ask you what language you’re using and shows an API key and a URL to use for sending emails.

In Rails the ActionMailer config in `config/environments/production.rb` looks like this:

```ruby
  config.action_mailer.mailgun_settings = {
    :api_key => <your_api_key>,
    :domain => <your_domain>,
  }
```

If you enter the full url from the Mailgun page in the `domain` field, Mailgun will return a `Mailgun::ParseError (765: unexpected token at 'Mailgun Magnificent API')` error. You have to change the `domain` to your sending domain (e.g. `mg.matsimitsu.com`).


## Mailgun API response 404 (NOT FOUND)

Second if you selected Europe as the region for your new domain, and you fixed the issue above, you’ll get a new error along the lines of `Mailgun API response 404 (NOT FOUND)`.

What’s happening is that the API can’t find your credentials/domain, since it’s hosted in another region.

Now the Gem documentation doesn’t mention this (yet, [multiple](https://github.com/mailgun/mailgun-ruby/pull/175) [pulls](https://github.com/mailgun/mailgun-ruby/pull/174) [have](https://github.com/mailgun/mailgun-ruby/pull/170) [been](https://github.com/mailgun/mailgun-ruby/pull/163) made, but somehow none have been merged yet).

You have to specify a 3rd parameter to the ActionMailer config, `api_url` that points to the Europe region API.

Your `config/environments/production.rb` should contain something like:

```ruby
  config.action_mailer.delivery_method = :mailgun
  config.action_mailer.mailgun_settings = {
    :api_key => <your_api_key>,
    :domain => <your_domain>, # e.g. mg.matsimitsu.com
    :api_host => "api.eu.mailgun.net"
  }
```

And of course we use ENV vars in production:

```ruby
  config.action_mailer.delivery_method = :mailgun
  config.action_mailer.mailgun_settings = {
    :api_key => ENV["MAILGUN_API_KEY"],
    :domain => ENV["MAILGUN_DOMAIN"],
    :api_host => "api.eu.mailgun.net"
  }
```


With these two fixes applied and deployed, emails were flowing again \o/.


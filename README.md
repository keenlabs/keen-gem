# Keen IO Official Ruby Client Library

[![Build Status](https://secure.travis-ci.org/keenlabs/keen-gem.png?branch=master)](http://travis-ci.org/keenlabs/keen-gem)

keen-gem is the official Ruby Client for the [Keen IO](https://keen.io/) API. The
Keen IO API lets developers build analytics features directly into their apps.

### Installation

Add to your Gemfile:

    gem 'keen'

or install from Rubygems:

    gem install keen

keen is tested with Ruby 1.8 and 1.9 on:

* MRI
* Rubinius
* jRuby (except for asynchronous methods - no TLS support for EM on jRuby)

### Usage

Before making any API calls, you must supply keen-gem with a Project ID and an API Key.
(If you need a Keen IO account, [sign up here](https://keen.io/) - it's free.)

The recommended way to do this is to set `KEEN_PROJECT_ID` and `KEEN_API_KEY` in your
environment. If you're using [foreman](http://ddollar.github.com/foreman/), add this to your `.env` file:

    KEEN_PROJECT_ID=your-project-id
    KEEN_API_KEY=your-api-key

When you deploy, make sure your production environment variables are also set. For example,
set [config vars](https://devcenter.heroku.com/articles/config-vars) on Heroku. (We recommend this
environment-based approach because it keeps sensitive credentials out of the codebase. If you can't do this, see the alternatives below.)

If your environment is set up property, `Keen` is ready go immediately. Publish an event like this:

    Keen.publish("sign_ups", { :username => "lloyd", :referred_by => "harry" })

This will publish an event to the 'sign_ups' collection with the `username` and `referred_by` properties set.

The event properties are arbitrary JSON, and the event collection need not exist in advance.
If it doesn't exist, Keen IO will create it on the first request.

You can learn more about data modeling with Keen IO with the [Data Modeling Guide](https://keen.io/docs/event-data-modeling/event-data-intro/).

### Asynchronous publishing

Publishing events shouldn't slow your application down. It shouldn't make your
users wait longer for their request to finish.

The Keen IO API is fast, but any synchronous network call you make will
negatively impact response times. For this reason, we recommend you use the `publish_async`
method to send events.

To compare asychronous vs. synchronous performance, check out the [keen-gem-example](http://keen-gem-example.herokuapp.com/) app.

To publish asynchronously, first add
[em-http-request](https://github.com/igrigorik/em-http-request) to your Gemfile.

Next, run an instance of EventMachine. If you're using an EventMachine-based web server like
thin or goliath you're already doing this. Otherwise, you'll need to start an EventMachine loop manually as follows:

    Thread.new { EventMachine.run }

The best place for this is in an initializer, or anywhere that runs when your app boots up.
Here's a good blog article that explains more about this approach - [EventMachine and Passenger](http://railstips.org/blog/archives/2011/05/04/eventmachine-and-passenger/).

Now, in your code, replace `publish` with `publish_async`. Bind callbacks if you require them.

    http = Keen.publish_async("sign_ups", { :username => "lloyd", :referred_by => "harry" })
    http.callback { |response| puts "Success: #{response}"}
    http.errback { puts "was a failurrr :,(" }

This will schedule the network call into the event loop and allow your request thread
to resume processing immediately.

### Other code examples

#### Authentication

To configure keen-gem credentials in code, do as follows:

    Keen.project_id = 'your-project-id'
    Keen.api_key = 'your-api-key'

You can also configure individual client instances as follows:

    keen = Keen::Client.new(:project_id => 'your-project-id', :api_key => 'your-api-key')

#### em-synchrony
keen-gem can be used with [em-synchrony](https://github.com/igrigorik/em-synchrony).
If you call `publish_async` and `EM::Synchrony` is defined the method will return the response
directly. (It does not return the deferrable on which to register callbacks.) Likewise, it will raise
exceptions 'synchronously' should they happen.

#### Beacon URL's

It's possible to publish events to your Keen IO project using the HTTP GET method.
This is useful for situations like tracking email opens using [image beacons](http://en.wikipedia.org/wiki/Web_bug).

In this situation, the JSON event data is passed by encoding it base-64 and adding it as a request parameter called `data`.
The `beacon_url` method found on the `Keen::Client` does this for you. Here's an example:

    keen = Keen::Client.new(:project_id => '12345', :api_key => 'abcde')

    keen.beacon_url("sign_ups", :recipient => "foo@foo.com")
    # => "https://api.keen.io/3.0/projects/12345/events/email_opens?api_key=abcde&data=eyJyZWNpcGllbnQiOiJmb29AZm9vLmNvbSJ9"

To track email opens, simply add an image to your email template that points to this URL.

### Changelog

##### 0.4.4
+ Event collections are URI escaped to account for spaces.
+ User agent of API calls made more granular to aid in support cases.
+ Throw arguments error for nil event_collection and properties arguments.

##### 0.4.3
+ Added beacon_url support
+ Add support for using em-synchrony with asynchronous calls

### Questions & Support

If you have any questions, bugs, or suggestions, please
report them via Github Issues. Or, come chat with us anytime
at [users.keen.io](http://users.keen.io). We'd love to hear your feedback and ideas!

### Contributing
keen-gem is an open source project and we welcome your contributions.
Fire away with issues and pull requests!

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

Before making any API calls, you must supply keen-gem with a Project ID and one or both of your Write and Read Keys.
(If you need a Keen IO account, [sign up here](https://keen.io/) - it's free.) The Write key is required for publishing
events, and the Read key is required for running queries.

The recommended way to do this is to set `KEEN_PROJECT_ID`, `KEEN_WRITE_KEY`, `KEEN_READ_KEY`, and/or 'KEEN_MASTER_KEY'
in your environment. You only need to specify the keys you plan to use. If you're using
[foreman](http://ddollar.github.com/foreman/), add this to your `.env` file:

    KEEN_PROJECT_ID=xxxxxxxxxxxxxxxx KEEN_WRITE_KEY=yyyyyyyyyyyyy KEEN_READ_KEY=zzzzzzzzzzzzz KEEN_MASTER_KEY=aaaaaaaaaaaaa

If not, make to to export the variable into your shell or put it before the command you use to start your server.

When you deploy, make sure your production environment variables are set. For example,
set [config vars](https://devcenter.heroku.com/articles/config-vars) on Heroku. (We recommend this
environment-based approach because it keeps sensitive information out of the codebase. If you can't do this, see the alternatives below.)

If your environment is set up property, `Keen` is ready to go immediately. Publish an event like this:

```ruby
Keen.publish("sign_ups", { :username => "lloyd", :referred_by => "harry" })
```

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
[em-http-request](https://github.com/igrigorik/em-http-request) to your Gemfile. Make sure it's version 1.0 or above.

```ruby
gem "em-http-request", "~> 1.0"
```

Next, run an instance of EventMachine. If you're using an EventMachine-based web server like
thin or goliath you're already doing this. Otherwise, you'll need to start an EventMachine loop manually as follows:

```ruby
Thread.new { EventMachine.run }
```

The best place for this is in an initializer, or anywhere that runs when your app boots up.
Here's a good blog article that explains more about this approach - [EventMachine and Passenger](http://railstips.org/blog/archives/2011/05/04/eventmachine-and-passenger/).

And here's a gist that shows an example of [Eventmachine with Unicorn](https://gist.github.com/jonkgrimes/5103321). Thanks to [jonkgrimes](https://github.com/jonkgrimes) for sharing this with us!

Now, in your code, replace `publish` with `publish_async`. Bind callbacks if you require them.

```ruby
http = Keen.publish_async("sign_ups", { :username => "lloyd", :referred_by => "harry" })
http.callback { |response| puts "Success: #{response}"}
http.errback { puts "was a failurrr :,(" }
```

This will schedule the network call into the event loop and allow your request thread
to resume processing immediately.

### Running queries

The Keen IO API provides rich querying capabilities against your event data set. For more information, see the [Data Analysis API Guide](https://keen.io/docs/data-analysis/).

Queries require that a Read Key is provided. Just like project ID, we encourage that you set this as an environment variable:

    KEEN_READ_KEY=yyyyyyyyyyyyyyyy

Here's are some examples of querying with keen-gem. Let's assume you've added some events to the "purchases" collection.

```ruby
Keen.count("purchases") # => 100
Keen.sum("purchases", :target_property => "price")  # => 10000
Keen.minimum("purchases", :target_property => "price")  # => 20
Keen.maximum("purchases", :target_property => "price")  # => 100
Keen.average("purchases", :target_property => "price")  # => 60

Keen.sum("purchases", :target_property => "price", :group_by => "item.id")  # => [{ "item.id": 123, "result": 240 }, { ... }]

Keen.count_unique("purchases", :target_property => "username")  # => 3
Keen.select_unique("purchases", :target_property => "username")  # => ["bob", "linda", "travis"]

Keen.extraction("purchases")  # => [{ "price" => 20, ... }, { ... }]

Keen.funnel(:steps => [
  { :actor_property => "username", :event_collection => "purchases" },
  { :actor_property => "username", :event_collection => "referrals" },
  { ... }])  # => [20, 15 ...]

Keen.multi_analysis("purchases", analyses: {
  :gross =>      { :analysis_type => "sum", :target_property => "price" },
  :customers =>  { :analysis_type => "count_unique", :target_property => "username" } },
  :timeframe => 'today', :group_by => "item.id") # => [{"item.id"=>2, "gross"=>314.49, "customers"=> 8}, { ... }]
```

Many of there queries can be performed with group by, filters, series and intervals. The API response for these is converted directly into Ruby Hash or Array.

Detailed information on available parameters for each API resource can be found on the [API Technical Reference](https://keen.io/docs/api/reference/).

### Other code examples

#### Batch publishing

The keen-gem supports publishing events in batches via the `publish_batch` method. Here's an example usage:

```ruby
Keen.publish_batch(
  :signups => [
    { :name => "Bob" },
    { :name => "Mary" }
  ],
  :purchases => [
    { :price => 10 },
    { :price => 20 }
  ]
)
```

This call would publish 2 `signups` events and 2 `purchases` events - all in just one API call.
Batch publishing is ideal for loading historical events into Keen IO.

#### Authentication

To configure keen-gem in code, do as follows:

```ruby
Keen.project_id = 'xxxxxxxxxxxxxxx'
Keen.write_key = 'yyyyyyyyyyyyyyy'
Keen.read_key = 'zzzzzzzzzzzzzzz'
Keen.master_key = 'aaaaaaaaaaaaaaa'
```

You can also configure individual client instances as follows:

```ruby
keen = Keen::Client.new(:project_id => 'xxxxxxxxxxxxxxx',
                        :write_key  => 'yyyyyyyyyyyyyyy',
                        :read_key   => 'zzzzzzzzzzzzzzz',
                        :master_key => 'aaaaaaaaaaaaaaa')
```

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

```ruby
Keen.project_id = 'xxxxxx';
Keen.write_key = 'yyyyyy';
Keen.beacon_url("sign_ups", :recipient => "foo@foo.com")
  # => "https://api.keen.io/3.0/projects/xxxxxx/events/email_opens?api_key=yyyyyy&data=eyJyZWNpcGllbnQiOiJmb29AZm9vLmNvbSJ9"
```

To track email opens, simply add an image to your email template that points to this URL.

### Changelog

##### 0.7.3
+ Add batch publishing support
+ Allow event collection names for querying methods to be symbols. Thanks to [cbartlett](https://github.com/cbartlett).

##### 0.7.2
+ Fix support for non-https API URL testing

##### 0.7.1
+ Allow configuration of the base API URL via the KEEN_API_URL environment variable. Useful for local testing and proxies.

##### 0.7.0
+ BREAKING CHANGE! Added support for read and write scoped keys to reflect the new Keen IO security architecture.
The advantage of scoped keys is finer grained permission control. Public clients that
publish events (like a web browser) require a key that can write but not read. On the other hand, private dashboards and
server-side querying processes require a Read key that should not be made public.

##### 0.6.1
+ Improved logging and exception handling.

##### 0.6.0
+ Added querying capabilities. A big thanks to [ifeelgoods](http://www.ifeelgoods.com/) for contributing!

##### 0.5.0
+ Removed API Key as a required field on Keen::Client. Only the Project ID is required to publish events.
+ You can continue to provide the API Key. Future features planned for this gem will require it. But for now,
  there is no keen-gem functionality that uses it.

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

### Community Contributors
+ [alexkwolfe](https://github.com/alexkwolfe)
+ [peteygao](https://github.com/peteygao)
+ [obieq](https://github.com/obieq)
+ [cbartlett](https://github.com/cbartlett)

Thanks everyone, you rock!

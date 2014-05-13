# Keen IO Official Ruby Client Library

[![Build Status](https://secure.travis-ci.org/keenlabs/keen-gem.png?branch=master)](http://travis-ci.org/keenlabs/keen-gem) [![Code Climate](https://codeclimate.com/github/keenlabs/keen-gem.png)](https://codeclimate.com/github/keenlabs/keen-gem)

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

Before making any API calls, you must supply keen-gem with a Project ID and one or more authentication keys.
(If you need a Keen IO account, [sign up here](https://keen.io/signup) - it's free.) 

Setting a write key is required for publishing events. Setting a read key is required for running queries. 
Setting a master key is required for performing deletes. You can find keys for all of your projects
on [keen.io](https://keen.io).

The recommended way to set keys is via the environment. The keys you can set are 
`KEEN_PROJECT_ID`, `KEEN_WRITE_KEY`, `KEEN_READ_KEY`, and `KEEN_MASTER_KEY`.
You only need to specify the keys that correspond to the API calls you'll be performing. 
If you're using [foreman](http://ddollar.github.com/foreman/), add this to your `.env` file:

    KEEN_PROJECT_ID=aaaaaaaaaaaaaaa
    KEEN_MASTER_KEY=xxxxxxxxxxxxxxx
    KEEN_WRITE_KEY=yyyyyyyyyyyyyyy
    KEEN_READ_KEY=zzzzzzzzzzzzzzz

If not, make a script to export the variables into your shell or put it before the command you use to start your server.

When you deploy, make sure your production environment variables are set. For example,
set [config vars](https://devcenter.heroku.com/articles/config-vars) on Heroku. (We recommend this
environment-based approach because it keeps sensitive information out of the codebase. If you can't do this, see the alternatives below.)

Once your environment is properly configured, the `Keen` object is ready to go immediately.

### Publishing events

Publishing events requires that `KEEN_WRITE_KEY` is set. Publish an event like this:

```ruby
Keen.publish(:sign_ups, { :username => "lloyd", :referred_by => "harry" })
```

This will publish an event to the `sign_ups` collection with the `username` and `referred_by` properties set. 
The event properties can be any valid Ruby hash and nested properties are allowed. You can learn more about data modeling with Keen IO with the [Data Modeling Guide](https://keen.io/docs/event-data-modeling/event-data-intro/).

The event collection need not exist in advance. If it doesn't exist, Keen IO will create it on the first request.

### Asynchronous publishing

Publishing events shouldn't slow your application down or make
users wait longer for page loads & server requests.

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
require 'em-http-request'

Thread.new { EventMachine.run }
```

The best place for this is in an initializer, or anywhere that runs when your app boots up.
Here's a useful blog article that explains more about this approach - [EventMachine and Passenger](http://railstips.org/blog/archives/2011/05/04/eventmachine-and-passenger/).

And here's an example repository that shows an example of [Eventmachine with Unicorn](https://github.com/dzello/em-unicorn/blob/master/unicorn.rb), specifically the Unicorn config for starting and stopping EventMachine after forking.

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

Running queries requires that `KEEN_READ_KEY` is set.

Here are some examples of querying with keen-gem. Let's assume you've added some events to the "purchases" collection.

```ruby
Keen.count("purchases") # => 100
Keen.sum("purchases", :target_property => "price")  # => 10000
Keen.minimum("purchases", :target_property => "price")  # => 20
Keen.maximum("purchases", :target_property => "price")  # => 100
Keen.average("purchases", :target_property => "price")  # => 60
Keen.median("purchases", :target_property => "price")  # => 60
Keen.percentile("purchases", :target_property => "price", :percentile => 90)  # => 100

Keen.sum("purchases", :target_property => "price", :group_by => "item.id")  # => [{ "item.id": 123, "result": 240 }, { ... }]

Keen.count_unique("purchases", :target_property => "username")  # => 3
Keen.select_unique("purchases", :target_property => "username")  # => ["Bob", "Linda", "Travis"]

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

Many of there queries can be performed with group by, filters, series and intervals. The response is returned as a Ruby Hash or Array.

Detailed information on available parameters for each API resource can be found on the [API Technical Reference](https://keen.io/docs/api/reference/).

### Deleting events

The Keen IO API allows you to [delete events](https://keen.io/docs/maintenance/#deleting-event-collections)
from event collections, optionally supplying a filter to narrow the scope of what you would like to delete.

Deleting events requires that the `KEEN_MASTER_KEY` is set.

```ruby
# Assume some events in the 'signups' collection

# We can delete them all
Keen.delete(:signups)  # => true

# Or just delete an event corresponding to a particular user
Keen.delete(:signups, filters: [{
  :property_name => 'username', :operator => 'eq', :property_value => "Bob"
}])  # => true
```

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

#### Asynchronous batch publishing 

Ensuring the above guidance is followed for asynchronous publishing, batch publishing logic can used asynchronously with `publish_batch_async`:

```ruby
Keen.publish_batch_async(
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

#### Configurable and per-client authentication

To configure keen-gem in code, do as follows:

```ruby
Keen.project_id = 'xxxxxxxxxxxxxxx'
Keen.write_key = 'yyyyyyyyyyyyyyy'
Keen.read_key = 'zzzzzzzzzzzzzzz'
Keen.master_key = 'aaaaaaaaaaaaaaa'
```

You can also configure unique client instances as follows:

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

#### Beacon URLs

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

To track email opens, simply add an image to your email template that points to this URL. For further information on how to do this, see the [image beacon documentation](https://keen.io/docs/data-collection/image-beacon/).

#### Redirect URLs
Redirect URLs are just like image beacon URLs with the addition of a `redirect` query parameter. This parameter is used
to issue a redirect to a certain URL after an event is recorded.

```
Keen.redirect_url("sign_ups", { :recipient => "foo@foo.com" }, "http://foo.com")
  # => "https://api.keen.io/3.0/projects/xxxxxx/events/email_opens?api_key=yyyyyy&data=eyJyZWNpcGllbnQiOiJmb29AZm9vLmNvbSJ9&redirect=http://foo.com"
```

This is helpful for tracking email clickthroughs. See the [redirect documentation](https://keen.io/docs/data-collection/redirect/) for further information.

#### Generating scoped keys

A [scoped key](https://keen.io/docs/security/#scoped-key) is a string, generated with your API Key, that represents some encrypted authentication and query options.
Use them to control what data queries have access to.

``` ruby
# "my-api-key" should be your MASTER API key
scoped_key = Keen::ScopedKey.new("my-api-key", { "filters" => [{
  "property_name" => "accountId",
  "operator" => "eq",
  "property_value" => "123456"
}]}).encrypt! # "4d1982fe601b359a5cab7ac7845d3bf27026936cdbf8ce0ab4ebcb6930d6cf7f139e..."
```

You can use the scoped key created in Ruby for API requests from any client. Scoped keys are commonly used in JavaScript, where credentials are visible and need to be protected.

### Troubleshooting

##### EventMachine

If you run into `Keen::Error: Keen IO Exception: An EventMachine loop must be running to use publish_async calls` or 
`Uncaught RuntimeError: eventmachine not initialized: evma_set_pending_connect_timeout`, this means that the EventMachine
loop has died. This can happen for a variety of reasons, and every app is different. [Issue #22](https://github.com/keenlabs/keen-gem/issues/22) shows how to add some extra protection to avoid this situation.

##### publish_async in a script or worker

If you write a script that uses `publish_async`, you need to keep the script alive long enough for the call(s) to complete.
EventMachine itself won't do this because it runs in a different thread. Here's an [example gist](https://gist.github.com/dzello/7472823) that shows how to exit the process after the event has been recorded.

### Changelog

##### 0.8.2
+ Add support for `median` and `percentile` analysis
+ Support arrays for extraction `property_names` option

##### 0.8.1
+ Add support for asynchronous batch publishing

##### 0.8.0
+ **UPGRADE WARNING** Do you use spaces in collection names? Or other special characters? Read [this post](https://groups.google.com/forum/?fromgroups#!topic/keen-io-devs/VtCgPuNKrgY) from the mailing list to make sure your collection names don't change.
+ Add support for generating [scoped keys](https://keen.io/docs/security/#scoped-key).
+ Make collection name encoding more robust. Make sure collection names are encoded identically for publishing events, running queries, and performing deletes.
+ Add support for [grouping by multiple properties](https://keen.io/docs/data-analysis/group-by/#grouping-by-multiple-properties).

##### 0.7.8
+ Add support for redirect URL creation.

##### 0.7.7
+ Add support for HTTP and SOCKS proxies. Set `KEEN_PROXY_URL` to the proxy URL and `KEEN_PROXY_TYPE` to 'socks5' if you need to. These
properties can also be set on the client instances as `proxy_url` and `proxy_type`.

+ Delegate the `master_key` fields from the Keen object.

##### 0.7.6
+ Explicitly require `CGI`.

##### 0.7.5
+ Use `CGI.escape` instead of `URI.escape` to get accurate URL encoding for certain characters

##### 0.7.4
+ Add support for deletes (thanks again [cbartlett](https://github.com/cbartlett)!)
+ Allow event collection names for publishing/deleting methods to be symbols

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

#### Running Tests

`bundle exec rake spec` - Run unit specs. HTTP is mocked.

`bundle exec rake integration` - Run integration specs with the real API. Requires env variables. See [.travis.yml](https://github.com/keenlabs/keen-gem/blob/master/.travis.yml).

`bundle exec rake synchrony` - Run async publishing specs with `EM::Synchrony`.

Similarly, you can use guard to listen for changes to files and run specs.

`bundle exec guard -g unit`

`bundle exec guard -g integration`

`bundle exec guard -g synchrony`

### Community Contributors
+ [alexkwolfe](https://github.com/alexkwolfe)
+ [peteygao](https://github.com/peteygao)
+ [obieq](https://github.com/obieq)
+ [cbartlett](https://github.com/cbartlett)

Thanks everyone, you rock!

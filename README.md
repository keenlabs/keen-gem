# Keen IO Official Ruby Client Library

[![Build Status](https://secure.travis-ci.org/keenlabs/keen-gem.png?branch=master)](http://travis-ci.org/keenlabs/keen-gem) [![Code Climate](https://codeclimate.com/github/keenlabs/keen-gem.png)](https://codeclimate.com/github/keenlabs/keen-gem)
[![Gem Version](https://badge.fury.io/rb/keen.svg)](http://badge.fury.io/rb/keen)

keen-gem is the official Ruby Client for the [Keen IO](https://keen.io/?s=gh-gem) API. The
Keen IO API lets developers build analytics features directly into their apps.

### Installation

Add to your Gemfile:

    gem 'keen'

or install from Rubygems:

    gem install keen

keen is tested with Ruby 1.9.3 + and on:

* MRI
* Rubinius
* jRuby (except for asynchronous methods - no TLS support for EM on jRuby)

### Usage

Before making any API calls, you must supply keen-gem with a Project ID and one or more authentication keys.
(If you need a Keen IO account, [sign up here](https://keen.io/signup?s=gh-gem) - it's free.)

Setting a write key is required for publishing events. Setting a read key is required for running queries.
Setting a master key is required for performing deletes. You can find keys for all of your projects
on [keen.io](https://keen.io?s=gh-gem).

The recommended way to set keys is via the environment. The keys you can set are
`KEEN_PROJECT_ID`, `KEEN_WRITE_KEY`, `KEEN_READ_KEY` and `KEEN_MASTER_KEY`.
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

### Data Enrichment

A data enrichment is a powerful add-on to enrich the data you're already streaming to Keen IO by pre-processing the data and adding helpful data properties. To activate add-ons, you simply add some new properties within the "keen" namespace in your events. Detailed documentation for the configuration of our add-ons is available [here](https://keen.io/docs/api/ruby#data-enrichment).

Here is an example of using the [URL parser](https://keen.io/docs/streams/data-enrichment-overview/#addon-url-parser):

```ruby
    Keen.publish(:requests, {
        :page_url => "http://my-website.com/cool/link?source=twitter&foo=bar/#title",
        :keen => {
            :addons => [
              {
                :name => "keen:url_parser",
                :input => {
                    :url => "page_url"
                },
                :output => "parsed_page_url"
              }
            ]
        }
    })
```

Keen IO will parse the URL for you and that would equivalent to:

```ruby
    Keen.publish(:request, {
        :page_url => "http://my-website.com/cool/link?source=twitter&foo=bar/#title",
        :parsed_page_url => {
            :protocol => "http",
            :domain => "my-website.com",
            :path => "/cool/link",
            :anchor => "title",
            :query_string => {
                :source => "twitter",
                :foo => "bar"
            }
        }
    })
```

Here is another example of using the [Datetime parser](https://keen.io/docs/api/?shell#datetime-parser).
Let's assume you want to do a deeper analysis on the "purchases" event by day of the week (Monday, Tuesday, Wednesday, etc.) and other interesting Datetime components. You can use "keen.timestamp" property that is included in your event automatically.

```ruby
    Keen.publish(:purchases, {
        :keen => {
            :addons => [
              {
                :name => "keen:date_time_parser",
                :input => {
                    :date_time => "keen.timestamp"
                },
                :output => "timestamp_info"
              }
            ]
        },
        :price => 500
    })
```

Other Data Enrichment add-ons are located in the [API reference docs](https://keen.io/docs/api/ruby#data-enrichment).

### Synchronous Publishing

Publishing events requires that `KEEN_WRITE_KEY` is set. Publish an event like this:

```ruby
Keen.publish(:sign_ups, { :username => "lloyd", :referred_by => "harry" })
```

This will publish an event to the `sign_ups` collection with the `username` and `referred_by` properties set.
The event properties can be any valid Ruby hash. Nested properties are allowed. Lists of objects are also allowed, but not recommended because they can be difficult to query over. See alternatives to lists of objects [here](http://stackoverflow.com/questions/24620330/nested-json-objects-in-keen-io). You can learn more about data modeling with Keen IO with the [Data Modeling Guide](https://keen.io/docs/event-data-modeling/event-data-intro/?s=gh-gem).

Protip: Marshalling gems like [Blockhead](https://github.com/vinniefranco/blockhead) make converting structs or objects to hashes easier.

The event collection need not exist in advance. If it doesn't exist, Keen IO will create it on the first request.

### Asynchronous publishing

Publishing events shouldn't slow your application down or make users wait longer for page loads & server requests.

The Keen IO API is fast, but any synchronous network call you make will negatively impact response times. For this reason, we recommend you use the `publish_async` method to send events when latency is a concern. Alternatively, you can drop events into a background queue e.g. Delayed Jobs and publish synchronously from there.

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

And here's a gist that shows an example of [Eventmachine with Unicorn](https://gist.github.com/jonkgrimes/5103321), specifically the Unicorn config for starting and stopping EventMachine after forking.

Now, in your code, replace `publish` with `publish_async`. Bind callbacks if you require them.

```ruby
http = Keen.publish_async("sign_ups", { :username => "lloyd", :referred_by => "harry" })
http.callback { |response| puts "Success: #{response}"}
http.errback { puts "was a failurrr :,(" }
```

This will schedule the network call into the event loop and allow your request thread
to resume processing immediately.

### Running queries

The Keen IO API provides rich querying capabilities against your event data set. For more information, see the [Data Analysis API Guide](https://keen.io/docs/data-analysis/?s=gh-gem).

Running queries requires that `KEEN_READ_KEY` is set.

Here are some examples of querying with keen-gem. Let's assume you've added some events to the "purchases" collection.

```ruby
# Various analysis types
Keen.count("purchases") # => 100
Keen.sum("purchases", :target_property => "price", :timeframe => "today")  # => 10000
Keen.minimum("purchases", :target_property => "price", :timeframe => "today")  # => 20
Keen.maximum("purchases", :target_property => "price", :timeframe => "today")  # => 100
Keen.average("purchases", :target_property => "price", :timeframe => "today")  # => 60
Keen.median("purchases", :target_property => "price", :timeframe => "today")  # => 60
Keen.percentile("purchases", :target_property => "price", :percentile => 90, :timeframe => "today")  # => 100
Keen.count_unique("purchases", :target_property => "username", :timeframe => "today")  # => 3
Keen.select_unique("purchases", :target_property => "username", :timeframe => "today")  # => ["Bob", "Linda", "Travis"]

# Group by's and filters
Keen.sum("purchases", :target_property => "price", :group_by => "item.id", :timeframe => "this_14_days")  # => [{ "item.id": 123, "result": 240 }]
Keen.count("purchases", :timeframe => "today", :filters => [{
    "property_name" => "referred_by",
    "operator" => "eq",
    "property_value" => "harry"
  }]) # => 2

# Relative timeframes
Keen.count("purchases", :timeframe => "today") # => 10

# Absolute timeframes
Keen.count("purchases", :timeframe => {
  :start => "2015-01-01T00:00:00Z",
  :end => "2015-31-01T00:00:00Z"
}) # => 5

# Extractions
Keen.extraction("purchases", :timeframe => "today")  # => [{ "keen" => { "timestamp" => "2014-01-01T00:00:00Z" }, "price" => 20 }]

# Funnels
Keen.funnel(:steps => [{
  :actor_property => "username", :event_collection => "purchases", :timeframe => "yesterday" }, {
  :actor_property => "username", :event_collection => "referrals", :timeframe => "yesterday" }]) # => [20, 15]

# Multi-analysis
Keen.multi_analysis("purchases", analyses: {
  :gross =>      { :analysis_type => "sum", :target_property => "price" },
  :customers =>  { :analysis_type => "count_unique", :target_property => "username" } },
  :timeframe => 'today', :group_by => "item.id") # => [{ "item.id" => 2, "gross" => 314.49, "customers" => 8 } }]
```

Many of these queries can be performed with group by, filters, series and intervals. The response is returned as a Ruby Hash or Array.

Detailed information on available parameters for each API resource can be found on the [API Technical Reference](https://keen.io/docs/api/reference/?s=gh-gem).

##### The Query Method

You can also specify the analysis type as a parameter to a method called `query`:

``` ruby
Keen.query("median", "purchases", :target_property => "price")  # => 60
```

This simplifes querying code where the analysis type is dynamic.

##### Query Options

Each query method or alias takes an optional hash of options as an additional parameter. Possible keys are:

`:response` – Set to `:all_keys` to return the full API response (usually only the value of the `"result"` key is returned).
`:method` - Set to `:post` to enable post body based query (https://keen.io/docs/data-analysis/post-queries/).

##### Query Logging

You can log all GET and POST queries automatically by setting the `log_queries` option.

``` ruby
Keen.log_queries = true
Keen.count('purchases')
# I, [2016-10-30T11:45:24.678745 #9978]  INFO -- : [KEEN] Send GET query to https://api.keen.io/3.0/projects/<YOUR_PROJECT_ID>/queries/count?event_collection=purchases with options {}
```

### Saved and Cached Queries

You can manage your saved queries from the Keen ruby client.

##### Create a saved query
```ruby
saved_query_attributes = {
    # NOTE : For now, refresh_rate must explicitly be set to 0 unless you
    # intend to create a Cached Query.
    refresh_rate: 0,
    query: {
        analysis_type: 'count',
        event_collection: 'purchases',
        timeframe: 'this_2_weeks',
        filters: [{
            property_name: 'price',
            operator: 'gte',
            property_value: 1.00
        }]
    }
}

Keen.saved_queries.create 'saved-query-name', saved_query_attributes
```

##### Get all saved queries
```ruby
Keen.saved_queries.all
```

##### Get one saved query
```ruby
Keen.saved_queries.get 'saved-query-name'
```

##### Get saved query with results
```ruby
query_body = Keen.saved_queries.get('saved-query-name', true)
query_body['result']
```

##### Updating a saved query

NOTE : Updating Saved Queries through the API requires sending the entire query
definition. Any attribute not sent is interpreted as being cleared/removed. This
means that properties set via another client, including the Projects Explorer
Web UI, would be lost this way.

The `update` function makes this easier by allowing client code to just specify
the properties that need updating. To do this, it will retrieve the existing
query definition first, which means there will be two HTTP requests. Use
`update_full` in code that already has a full query definition that can
reasonably be expected to be current.

Update a saved query to now be a cached query with the minimum refresh rate of 4 hrs
```ruby
# using partial update:
Keen.saved_queries.update 'saved-query-name', refresh_rate: 14400

# using full update, if we've already fetched the query definition:
saved_query_attributes['refresh_rate'] = 14400
Keen.saved_queries.update_full('saved-query-name', update_attributes)
```

Update a saved query to a new resource name
```ruby
# using partial update:
Keen.saved_queries.update 'saved-query-name', query_name: 'cached-query-name'

# using full update, if we've already fetched the query definition or have it lying around
# for whatever reason. We send 'refresh_rate' again, along with the entire definition, or else
# it would be reset:
saved_query_attributes['query_name'] = 'cached-query-name'
Keen.saved_queries.update_full('saved-query-name', saved_query_attributes)
```

Cache a query
```ruby
Keen.saved_queries.cache 'saved-query-name', 14400
```

Uncache a query
```ruby
Keen.saved_queries.uncache 'saved-query-name'
```

Delete a saved query (use the new resource name since we just changed it)
```ruby
Keen.saved_queries.delete 'cached-query-name'
```

##### Getting Query URLs

Sometimes you just want the URL for a query, but don't actually need to run it. Maybe to paste into a dashboard, or open in your browser. In that case, use the `query_url` method:

``` ruby
Keen.query_url("median", "purchases", :target_property => "price", { :timeframe => "today" })
# => "https://api.keen.io/3.0/projects/<project-id>/queries/median?target_property=price&event_collection=purchases&api_key=<api-key>"
```

If you don't want the API key included, pass the `:exclude_api_key` option:

``` ruby
Keen.query_url("median", "purchases", { :target_property => "price", :timeframe => "today" }, :exclude_api_key => true)
# => "https://api.keen.io/3.0/projects/<project-id>/queries/median?target_property=price&event_collection=purchases"
```

### Cached Datasets

You can manage your cached datasets from the Keen ruby client.

##### Create a cached dataset
```ruby
index_by = 'userId'
query = {
  "project_id" => "PROJECT ID",
  "analysis_type" => "count",
  "event_collection" => "purchases",
  "filters" =>  [
    {
      "property_name" => "price",
      "operator" => "gte",
      "property_value" => 100
    }
  ],
  "timeframe" => "this_500_days",
  "interval" => "daily",
  "group_by" => ["ip_geo_info.country"]
}

Keen.cached_datasets.create 'cached-dataset-name', index_by, query, 'My Dataset Display Name'
```

##### Query cached dataset's results
```ruby
response_json = Keen.cached_datasets.get_results('a-dataset-name', {
  start: "2012-08-13T19:00:00.000Z",
  end: "2013-09-20T19:00:00.000Z"
 }, index_by_value)
response_json['result']
```

##### Retrieve definitions of cached datasets
```ruby
Keen.cached_datasets.list
Keen.cached_datasets.list(limit: 5, after_name: 'some-dataset')
```

##### Get a cached dataset's definition
```ruby
Keen.cached_datasets.get_definition 'a-dataset-name'
```

##### Delete a cached dataset
```ruby
Keen.cached_datasets.delete 'a-dataset-name'
```

### Listing collections

The Keen IO API let you get the event collections for the project set, it includes properties and their type. It also returns links to the collection resource.

```ruby
Keen.event_collections # => [{ "name": "purchases", "properties": { "item.id": "num", ... }, ... }]
```

Getting the list of event collections requires that the `KEEN_MASTER_KEY` is set.

### Deleting events

The Keen IO API allows you to [delete events](https://keen.io/docs/maintenance/#deleting-event-collections?s=gh-gem)
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

#### Overwriting event timestamps

Two time-related properties are included in your event automatically. The properties “keen.timestamp” and “keen.created_at” are set at the time your event is recorded. You have the ability to overwrite the keen.timestamp property. This could be useful, for example, if you are backfilling historical data. Be sure to use [ISO-8601 Format](https://keen.io/docs/event-data-modeling/event-data-intro/#iso-8601-format?s=gh-gem).

Keen stores all date and time information in UTC!

```ruby
Keen.publish(:sign_ups, {
  :keen => { :timestamp => "2012-12-14T20:24:01.123000+00:00" },
  :username => "lloyd",
  :referred_by => "harry"
})
```

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

To track email opens, simply add an image to your email template that points to this URL. For further information on how to do this, see the [image beacon documentation](https://keen.io/docs/data-collection/image-beacon/?s=gh-gem).

#### Redirect URLs
Redirect URLs are just like image beacon URLs with the addition of a `redirect` query parameter. This parameter is used
to issue a redirect to a certain URL after an event is recorded.

``` ruby
Keen.redirect_url("sign_ups", { :recipient => "foo@foo.com" }, "http://foo.com")
  # => "https://api.keen.io/3.0/projects/xxxxxx/events/email_opens?api_key=yyyyyy&data=eyJyZWNpcGllbnQiOiJmb29AZm9vLmNvbSJ9&redirect=http://foo.com"
```

This is helpful for tracking email clickthroughs. See the [redirect documentation](https://keen.io/docs/data-collection/redirect/?s=gh-gem) for further information.

#### Generating scoped keys

Note, Scoped Keys are now *deprecated* in favor of [Access Keys](https://keen.io/docs/api/#access-keys?s=gh-gem).

A [scoped key](https://keen.io/docs/security/#scoped-key?s=gh-gem) is a string, generated with your API Key, that represents some encrypted authentication and query options.
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

#### Access Keys

You can use [Access Keys](https://keen.io/docs/api/?ruby#access-keys) to restrict the functionality of a key you use with the Keen API. Access Keys can also enrich events that you send.

[Create](https://keen.io/docs/api/?ruby#creating-an-access-key) a key that automatically adds information to each event published with that key:

``` ruby
key_body = {
  "name" => "autofill foo",
  "is_active" => true,
  "permitted" => ["writes"],
  "options" => {
    "writes" => {
      "autofill": {
        "foo": "bar"
      }
    }
  }
}

new_key = Keen.access_keys.create(key_body)
autofill_write_key = new_key["key"]
```

[List all](https://keen.io/docs/api/#list-all-access-keys) keys associated with a project.

```
Keen.access_keys.all
```

[Get info](https://keen.io/docs/api/#get-an-access-key) associated with a given key
```
access_key = '0000000000000000000000000000000000000000000000000000000000000000'
Keen.access_keys.get(access_key)
```

[Update](https://keen.io/docs/api/#updating-an-access-key) a key. Information passed to this method will overwrite existing properties.

```
access_key = '0000000000000000000000000000000000000000000000000000000000000000'
update_body = {
  name: 'updated key',
  is_active: false,
  permitted: ['reads']
}
Keen.access_keys.update(access_key, update_body)
```

[Revoke](https://keen.io/docs/api/#revoking-an-access-key) a key. This will set the key's active flag to false, but keep it available to be unrevoked. If you want to permanently remove a key, use `delete`.

```
access_key = '0000000000000000000000000000000000000000000000000000000000000000'
Keen.access_keys.revoke(access_key)
```

[Unrevoke](https://keen.io/docs/api/#un-revoking-an-access-key) a key. This will set a previously revoked key's active flag to true.

```
access_key = '0000000000000000000000000000000000000000000000000000000000000000'
Keen.access_keys.unrevoke(access_key)
```

[Delete](https://keen.io/docs/api/#delete) a key. Once deleted, a key cannot be recovered. Consider `revoke` if you want to keep the key around but deactivate it.

```
access_key = '0000000000000000000000000000000000000000000000000000000000000000'
Keen.access_keys.delete(access_key)
```

### Additional options

##### HTTP Read Timeout

The default `Net::HTTP` timeout is 60 seconds. That's usually enough, but if you're querying over a large collection you may need to increase it. The timeout on the API side is 300 seconds, so that's as far as you'd want to go. You can configure a read timeout (in seconds) by setting a `KEEN_READ_TIMEOUT` environment variable, or by passing in a `read_timeout` option to the client constructor as follows:

``` ruby
keen = Keen::Client.new(:read_timeout => 300)
```

You can also configure the `NET::HTTP` open timeout, default is 60 seconds. To configure the timeout (in seconds) either set `KEEN_OPEN_TIMEOUT` environment variable, or by passing in a `open_timeout` option to the client constructor as follows:

``` ruby
keen = Keen::Client.new(:open_timeout => 30)
```


##### HTTP Proxy

You can set the `KEEN_PROXY_TYPE` and `KEEN_PROXY_URL` environment variables to enable HTTP proxying. `KEEN_PROXY_TYPE` should be set to `socks5`. You can also configure this on client instances by passing in `proxy_type` and `proxy_url` keys.

``` ruby
keen = Keen::Client.new(:proxy_type => 'socks5', :proxy_url => 'http://localhost:8888')
```

### Troubleshooting

##### EventMachine

If you run into `Keen::Error: Keen IO Exception: An EventMachine loop must be running to use publish_async calls` or
`Uncaught RuntimeError: eventmachine not initialized: evma_set_pending_connect_timeout`, this means that the EventMachine
loop has died. This can happen for a variety of reasons, and every app is different. [Issue #22](https://github.com/keenlabs/keen-gem/issues/22) shows how to add some extra protection to avoid this situation.

##### publish_async in a script or worker

If you write a script that uses `publish_async`, you need to keep the script alive long enough for the call(s) to complete.
EventMachine itself won't do this because it runs in a different thread. Here's an [example gist](https://gist.github.com/dzello/7472823) that shows how to exit the process after the event has been recorded.

### Additional Considerations

##### Bots

It's not just us humans that browse the web. Spiders, crawlers, and bots share the pipes too. When it comes to analytics, this can cause a mild headache. Events generated by bots can inflate your metrics and eat up your event quota.

If you want some bot protection, check out the [Voight-Kampff](https://github.com/biola/Voight-Kampff) gem. Use the gem's `request.bot?` method to detect bots and avoid logging events.

### Changelog

##### 1.1.1
+ Added an option to log queries
+ Added a cli option that includes the Keen code

##### 1.1.0
+ Add support for Access Keys
+ Move saved queries into the Keen namespace
+ Deprecate scoped keys in favor of Access Keys

##### 1.0.0
+ Remove support for ruby 1.9.3
+ Update a few dependencies

##### 0.9.10
+ Add ability to set the `open_time` setting for the http client.

##### 0.9.9
+ Added the ability to send additional optional headers.

##### 0.9.7
+ Added a new header `Keen-Sdk` that sends the SDK version information on all requests.

##### 0.9.6
+ Updated behavior of saved queries to allow fetching results using the READ KEY as opposed to requiring the MASTER KEY, making the gem consistent with https://keen.io/docs/api/#getting-saved-query-results

##### 0.9.5
+ Fix bug with scoped key generation not working with newer Keen projects.

##### 0.9.4
+ Add SDK support for Saved Queries
+ Removed support for Ruby MRI 1.8.7

##### 0.9.2
+ Added support for max_age as an integer.

##### 0.9.1
+ Added support for setting an IV for scoped keys. Thanks [@anatolydwnld](https://github.com/anatolydwnld)

##### 0.8.10
+ Added support for posting queries. Thanks [@soloman1124](https://github.com/soloman1124).

##### 0.8.9
+ Fix proxy support for sync client. Thanks [@nvieirafelipe](https://github.com/nvieirafelipe)!

##### 0.8.8
+ Add support for a configurable read timeout

##### 0.8.7
+ Add support for returning all keys back from query API responses

##### 0.8.6
+ Add support for getting [query URLs](https://github.com/keenlabs/keen-gem/pull/47)
+ Make the `query` method public so code supporting dynamic analysis types is easier to write

##### 0.8.4
+ Add support for getting [project details](https://keen.io/docs/api/reference/#project-row-resource?s=gh-gem)

##### 0.8.3
+ Add support for getting a list of a [project's collections](https://keen.io/docs/api/reference/#event-resource?s=gh-gem)

##### 0.8.2
+ Add support for `median` and `percentile` analysis
+ Support arrays for extraction `property_names` option

##### 0.8.1
+ Add support for asynchronous batch publishing

##### 0.8.0
+ **UPGRADE WARNING** Do you use spaces in collection names? Or other special characters? Read [this post](https://groups.google.com/forum/?fromgroups#!topic/keen-io-devs/VtCgPuNKrgY) from the mailing list to make sure your collection names don't change.
+ Add support for generating [scoped keys](https://keen.io/docs/security/#scoped-key?s=gh-gem).
+ Make collection name encoding more robust. Make sure collection names are encoded identically for publishing events, running queries, and performing deletes.
+ Add support for [grouping by multiple properties](https://keen.io/docs/data-analysis/group-by/#grouping-by-multiple-properties?s=gh-gem).

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

For questions, bugs, or suggestions about this gem:
[File a Github Issue](https://github.com/keenlabs/keen-gem/issues).

For other Keen-IO related technical questions:
['keen-io' on Stack Overflow](http://stackoverflow.com/questions/tagged/keen-io)

For general Keen IO discussion & feedback:
['keen-io-devs' Google Group](https://groups.google.com/forum/#!forum/keen-io-devs)

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

#### Running a Local Console

You can spawn an `irb` session with the local files already loaded for debugging
or experimentation.

```
$ bundle exec rake console
2.2.6 :001 > Keen
 => Keen
```
### Community Contributors
+ [alexkwolfe](https://github.com/alexkwolfe)
+ [peteygao](https://github.com/peteygao)
+ [obieq](https://github.com/obieq)
+ [cbartlett](https://github.com/cbartlett)
+ [myrridin](https://github.com/myrridin)

Thanks everyone, you rock!

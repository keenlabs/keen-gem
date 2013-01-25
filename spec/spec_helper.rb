begin
  require 'bundler/setup'
rescue LoadError
  puts 'Use of Bundler is recommended'
end

require 'rspec'
require 'net/https'
require 'em-http'

require File.expand_path("../../lib/keen", __FILE__)

module Keen::SpecHelpers
  def stub_api(url, status, json_body)
    stub_request(:post, url).to_return(
      :status => status,
      :body => MultiJson.encode(json_body))
  end

  def expect_post(url, event_properties, api_key, sync_or_async_ua)
    user_agent = "keen-gem, v#{Keen::VERSION}, #{sync_or_async_ua}"
    user_agent += ", #{RUBY_VERSION}, #{RUBY_PLATFORM}, #{RUBY_PATCHLEVEL}"
    if defined?(RUBY_ENGINE)
      user_agent += ", #{RUBY_ENGINE}"
    end

    WebMock.should have_requested(:post, url).with(
      :body => MultiJson.encode(event_properties),
      :headers => { "Content-Type" => "application/json",
                    "User-Agent" => user_agent,
                    "Authorization" => api_key })
  end

  def api_url(collection)
    "https://api.keen.io/3.0/projects/#{project_id}/events/#{collection}"
  end
end

RSpec.configure do |config|
  config.include(Keen::SpecHelpers)
end


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
  def stub_keen_request(method, url, status, response_body)
    stub_request(method, url).to_return(:status => status, :body => response_body)
  end

  def stub_keen_post(url, status, response_body)
    stub_keen_request(:post, url, status, MultiJson.encode(response_body))
  end

  def stub_keen_put(url, status, response_body)
    stub_keen_request(:put, url, status, MultiJson.encode(response_body))
  end

  def stub_keen_get(url, status, response_body)
    stub_keen_request(:get, url, status, MultiJson.encode(response_body))
  end

  def stub_keen_delete(url, status)
    stub_keen_request(:delete, url, status, "")
  end

  def expect_keen_request(method, url, body, sync_or_async_ua, read_or_write_key, extra_headers={})
    user_agent = "keen-gem, v#{Keen::VERSION}, #{sync_or_async_ua}"
    user_agent += ", #{RUBY_VERSION}, #{RUBY_PLATFORM}, #{RUBY_PATCHLEVEL}"
    if defined?(RUBY_ENGINE)
      user_agent += ", #{RUBY_ENGINE}"
    end

    headers = { "Content-Type" => "application/json",
                "User-Agent" => user_agent,
                "Authorization" => read_or_write_key,
                "Keen-Sdk" => "ruby-#{Keen::VERSION}" }

    headers = headers.merge(extra_headers) if not extra_headers.empty?

    expect(WebMock).to have_requested(method, url).with(
      :body => body,
      :headers => headers)

  end

  def expect_keen_get(url, sync_or_async_ua, read_key, extra_headers={})
    expect_keen_request(:get, url, "", sync_or_async_ua, read_key, extra_headers)
  end

  def expect_keen_post(url, event_properties, sync_or_async_ua, write_key, extra_headers={})
    expect_keen_request(:post, url, MultiJson.encode(event_properties), sync_or_async_ua, write_key, extra_headers)
  end

  def expect_keen_delete(url, sync_or_async_ua, master_key, extra_headers={})
    expect_keen_request(:delete, url, "", sync_or_async_ua, master_key, extra_headers)
  end

  def api_event_collection_resource_url(base_url, collection)
    "#{base_url}/3.0/projects/#{project_id}/events/#{collection}"
  end

  def api_event_resource_url(base_url)
    "#{base_url}/3.0/projects/#{project_id}/events"
  end
end

RSpec.configure do |config|
  config.include(Keen::SpecHelpers)

  config.color      = true
  config.tty        = true
  config.formatter  = :progress # :progress, :documentation, :html, :textmate
end

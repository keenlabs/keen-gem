require File.expand_path("../../spec_helper", __FILE__)

require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    WebMock.disable_net_connect!
    WebMock.reset!
  end
end

module Keen::SpecHelpers
  def stub_api(url, status, json_body)
    stub_request(:post, url).to_return(
      :status => status,
      :body => MultiJson.encode(json_body))
  end

  def expect_post(url, event_properties, api_key)
    WebMock.should have_requested(:post, url).with(
      :body => MultiJson.encode(event_properties),
      :headers => { "Content-Type" => "application/json",
                    "User-Agent" => "keen-gem v#{Keen::VERSION}",
                    "Authorization" => api_key })
  end

  def api_url(collection)
    "https://api.keen.io/3.0/projects/#{project_id}/events/#{collection}"
  end
end

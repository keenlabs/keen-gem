require File.expand_path("../../spec_helper", __FILE__)

require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    WebMock.disable_net_connect!
    WebMock.reset!
  end
end

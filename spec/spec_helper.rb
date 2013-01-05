begin
  require 'bundler/setup'
rescue LoadError
  puts 'Use of Bundler is recommended'
end

require 'rspec'
require 'net/https'
require 'em-http'

require File.expand_path("../../lib/keen", __FILE__)

RSpec.configure do |config|
  config.before(:all) do
    unless EventMachine.reactor_running?
      Thread.new { EventMachine.run }
    end
  end
end

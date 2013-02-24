require File.expand_path("../../spec_helper", __FILE__)

RSpec.configure do |config|
  unless ENV['KEEN_PROJECT_ID']
    raise "Please set a KEEN_PROJECT_ID on the environment
           before running the integration specs."
  end
end

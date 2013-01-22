require 'em-synchrony'
require 'em-synchrony/em-http'

require File.expand_path("../../keen/spec_helper", __FILE__)

describe Keen::HTTP::Async do
  include Keen::SpecHelpers

  let(:project_id) { "12345" }
  let(:api_key) { "abcde" }
  let(:collection) { "users" }
  let(:event_properties) { { "name" => "Bob" } }
  let(:api_success) { { "created" => true } }

  describe "synchrony" do
    before do
      @client = Keen::Client.new(
        :project_id => project_id,
        :api_key => api_key)
    end

    it "should post the event data" do
      stub_api(api_url(collection), 201, api_success)
      EM.synchrony {
        @client.publish_async(collection, event_properties)
        expect_post(api_url(collection), event_properties, api_key)
        EM.stop
      }
    end
  end
end

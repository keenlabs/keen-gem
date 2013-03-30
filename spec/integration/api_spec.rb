require File.expand_path("../spec_helper", __FILE__)

describe "Keen IO API" do
  let(:project_id) { ENV['KEEN_PROJECT_ID'] }

  let(:collection) { "users" }
  let(:event_properties) { { "name" => "Bob" } }
  let(:api_success) { { "created" => true } }

  describe "success" do

    it "should return a created status for a valid post" do
      Keen.publish(collection, event_properties).should == api_success
    end
  end

  describe "failure" do
    it "should raise a not found error if an invalid project id" do
      client = Keen::Client.new(:project_id => "riker")
      expect {
        client.publish(collection, event_properties)
      }.to raise_error(Keen::NotFoundError)
    end

    it "should succeed if a non-url-safe event collection is specified" do
      Keen.publish("infinite possibilities", event_properties).should == api_success
    end
  end

  describe "async" do
    # no TLS support in EventMachine on jRuby
    unless defined?(JRUBY_VERSION)

      it "should publish the event and trigger callbacks" do
        EM.run {
          Keen.publish_async(collection, event_properties).callback { |response|
            response.should == api_success
            EM.stop
          }
        }
      end

      it "should publish to non-url-safe collections" do
        EM.run {
          Keen.publish_async("foo bar", event_properties).callback { |response|
            response.should == api_success
            EM.stop
          }
        }
      end
    end
  end
end

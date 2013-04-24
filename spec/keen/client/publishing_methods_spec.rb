require File.expand_path("../../spec_helper", __FILE__)

describe Keen::Client::PublishingMethods do
  let(:project_id) { "12345" }
  let(:api_host) { "api.keen.io" }
  let(:collection) { "users" }
  let(:event_properties) { { "name" => "Bob" } }
  let(:api_success) { { "created" => true } }
  let(:client) { Keen::Client.new(:project_id => project_id) }

  describe "publish" do
    it "should post using the collection and properties" do
      stub_keen_post(api_event_resource_url(collection), 201, "")
      client.publish(collection, event_properties)
      expect_keen_post(api_event_resource_url(collection), event_properties, "sync")
    end

    it "should return the proper response" do
      api_response = { "created" => true }
      stub_keen_post(api_event_resource_url(collection), 201, api_response)
      client.publish(collection, event_properties).should == api_response
    end

    it "should raise an argument error if no event collection is specified" do
      expect {
        client.publish(nil, {})
      }.to raise_error(ArgumentError)
    end

    it "should raise an argument error if no properties are specified" do
      expect {
        client.publish(collection, nil)
      }.to raise_error(ArgumentError)
    end

    it "should url encode the event collection" do
      stub_keen_post(api_event_resource_url("foo%20bar"), 201, "")
      client.publish("foo bar", event_properties)
      expect_keen_post(api_event_resource_url("foo%20bar"), event_properties, "sync")
    end

    it "should wrap exceptions" do
      stub_request(:post, api_event_resource_url(collection)).to_timeout
      e = nil
      begin
        client.publish(collection, event_properties)
      rescue Exception => exception
        e = exception
      end

      e.class.should == Keen::HttpError
      e.original_error.class.should == Timeout::Error
      e.message.should == "Keen IO Exception: HTTP publish failure: execution expired"
    end

    it "should raise an exception if client has no project_id" do
      expect {
        Keen::Client.new.publish(collection, event_properties)
      }.to raise_error(Keen::ConfigurationError)
    end
  end

  describe "publish_async" do
    # no TLS support in EventMachine on jRuby
    unless defined?(JRUBY_VERSION)
      it "should require a running event loop" do
        expect {
          client.publish_async(collection, event_properties)
        }.to raise_error(Keen::Error)
      end

      it "should post the event data" do
        stub_keen_post(api_event_resource_url(collection), 201, api_success)
        EM.run {
          client.publish_async(collection, event_properties).callback {
            begin
              expect_keen_post(api_event_resource_url(collection), event_properties, "async")
            ensure
              EM.stop
            end
          }
        }
      end

      it "should uri encode the event collection" do
        stub_keen_post(api_event_resource_url("foo%20bar"), 201, api_success)
        EM.run {
          client.publish_async("foo bar", event_properties).callback {
            begin
              expect_keen_post(api_event_resource_url("foo%20bar"), event_properties, "async")
            ensure
              EM.stop
            end
          }
        }
      end

      it "should raise an argument error if no event collection is specified" do
        expect {
          client.publish_async(nil, {})
        }.to raise_error(ArgumentError)
      end

      it "should raise an argument error if no properties are specified" do
        expect {
          client.publish_async(collection, nil)
        }.to raise_error(ArgumentError)
      end

      describe "deferrable callbacks" do
        it "should trigger callbacks" do
          stub_keen_post(api_event_resource_url(collection), 201, api_success)
          EM.run {
            client.publish_async(collection, event_properties).callback { |response|
              begin
                response.should == api_success
              ensure
                EM.stop
              end
            }
          }
        end

        it "should trigger errbacks" do
          stub_request(:post, api_event_resource_url(collection)).to_timeout
          EM.run {
            client.publish_async(collection, event_properties).errback { |error|
              begin
                error.should_not be_nil
                error.message.should == "Keen IO Exception: HTTP publish_async failure: WebMock timeout error"
              ensure
                EM.stop
              end
            }
          }
        end

        it "should not trap exceptions in the client callback" do
          stub_keen_post(api_event_resource_url("foo%20bar"), 201, api_success)
          expect {
            EM.run {
              client.publish_async("foo bar", event_properties).callback {
                begin
                  blowup
                ensure
                  EM.stop
                end
              }
            }
          }.to raise_error
        end
      end
    end
  end

  it "should raise an exception if client has no project_id" do
    expect {
      Keen::Client.new.publish_async(collection, event_properties)
    }.to raise_error(Keen::ConfigurationError)
  end

  describe "#add_event" do
    it "should alias to publish" do
      client.should_receive(:publish).with("users", {:a => 1}, {:b => 2})
      client.add_event("users", {:a => 1}, {:b => 2})
    end
  end

  describe "beacon_url" do
    it "should return a url with a base-64 encoded json param" do
      client = Keen::Client.new(project_id)
      client.beacon_url("sign_ups", { :name => "Bob" }).should ==
        "https://api.keen.io/3.0/projects/12345/events/sign_ups?data=eyJuYW1lIjoiQm9iIn0="
    end
  end
end

require File.expand_path("../../spec_helper", __FILE__)

describe Keen::Client::PublishingMethods do
  let(:project_id) { "12345" }
  let(:write_key) { "abcde" }
  let(:api_url) { "https://unreal.keen.io" }
  let(:collection) { "users" }
  let(:event_properties) { { "name" => "Bob" } }
  let(:api_success) { { "created" => true } }
  let(:client) { Keen::Client.new(
    :project_id => project_id, :write_key => write_key,
    :api_url => api_url) }

  describe "publish" do
    it "should post using the collection and properties" do
      stub_keen_post(api_event_collection_resource_url(api_url, collection), 201, "")
      client.publish(collection, event_properties)
      expect_keen_post(api_event_collection_resource_url(api_url, collection), event_properties, "sync", write_key)
    end

    it "should return the proper response" do
      api_response = { "created" => true }
      stub_keen_post(api_event_collection_resource_url(api_url, collection), 201, api_response)
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
      stub_keen_post(api_event_collection_resource_url(api_url, "foo+bar"), 201, "")
      client.publish("foo bar", event_properties)
      expect_keen_post(api_event_collection_resource_url(api_url, "foo+bar"), event_properties, "sync", write_key)
    end

    it "should wrap exceptions" do
      stub_request(:post, api_event_collection_resource_url(api_url, collection)).to_timeout
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
        Keen::Client.new(
          :write_key => "abcde"
        ).publish(collection, event_properties)
      }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Project ID must be set")
    end

    it "should raise an exception if client has no write_key" do
      expect {
        Keen::Client.new(
          :project_id => "12345"
        ).publish(collection, event_properties)
      }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Write Key must be set for sending events")
    end
  end

  describe "publish_batch" do
    let(:events) {
      {
        :purchases => [
          { :price => 10 },
          { :price => 11 }
        ],
        :signups => [
          { :name => "bob" },
          { :name => "bill" }
        ]
      }
    }

    it "should raise an exception if client has no project_id" do
      expect {
        Keen::Client.new(
          :write_key => "abcde"
        ).publish_batch(events)
      }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Project ID must be set")
    end

    it "should raise an exception if client has no write_key" do
      expect {
        Keen::Client.new(
          :project_id => "12345"
        ).publish_batch(events)
      }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Write Key must be set for sending events")
    end

    it "should publish a batch of events" do
      stub_keen_post(api_event_resource_url(api_url), 201, "")
      client.publish_batch(events)
      expect_keen_post(
        api_event_resource_url(api_url),
                       events, "sync", write_key)
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
        stub_keen_post(api_event_collection_resource_url(api_url, collection), 201, api_success)
        EM.run {
          client.publish_async(collection, event_properties).callback {
            begin
              expect_keen_post(api_event_collection_resource_url(api_url, collection), event_properties, "async", write_key)
            ensure
              EM.stop
            end
          }.errback { 
            EM.stop
            fail
          }
        }
      end

      it "should url encode the event collection" do
        stub_keen_post(api_event_collection_resource_url(api_url, "foo+bar"), 201, api_success)
        EM.run {
          client.publish_async("foo bar", event_properties).callback {
            begin
              expect_keen_post(api_event_collection_resource_url(api_url, "foo+bar"), event_properties, "async", write_key)
            ensure
              EM.stop
            end
          }.errback {
            EM.stop
            fail
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
          stub_keen_post(api_event_collection_resource_url(api_url, collection), 201, api_success)
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
          stub_request(:post, api_event_collection_resource_url(api_url, collection)).to_timeout
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
          stub_keen_post(api_event_collection_resource_url(api_url, "foo%20bar"), 201, api_success)
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
      client.beacon_url("sign_ups", { :name => "Bob" }).should ==
        "#{api_url}/3.0/projects/12345/events/sign_ups?api_key=#{write_key}&data=eyJuYW1lIjoiQm9iIn0="
    end
  end

  describe "redirect_url" do
    it "should return a url with a base-64 encoded json param" do
      client.beacon_url("sign_ups", { :name => "Bob" }, "http://www.keenio.com").should ==
        "#{api_url}/3.0/projects/12345/events/sign_ups?api_key=#{write_key}&data=eyJuYW1lIjoiQm9iIn0=&redirect=http://www.keenio.com"
    end
  end
end

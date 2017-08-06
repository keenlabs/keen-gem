require File.expand_path("../../spec_helper", __FILE__)

describe Keen::Client::PublishingMethods do
  let(:project_id) { "12345" }
  let(:write_key) { "abcde" }
  let(:api_url) { "https://unreal.keen.io" }
  let(:collection) { "some :actions_to.record" }
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
      expect(client.publish(collection, event_properties)).to eq(api_response)
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
      stub_keen_post(api_event_collection_resource_url(api_url, "User%20posts.new%20)(*%26%5E%25%40!)%3A%3A%2520%2520"), 201, "")
      client.publish("User posts.new )(*&^%@!)::%20%20", event_properties)
      expect_keen_post(api_event_collection_resource_url(api_url, "User%20posts.new%20)(*%26%5E%25%40!)%3A%3A%2520%2520"), event_properties, "sync", write_key)
    end

    it "should wrap exceptions" do
      stub_request(:post, api_event_collection_resource_url(api_url, collection)).to_timeout
      e = nil
      begin
        client.publish(collection, event_properties)
      rescue Exception => exception
        e = exception
      end

      expect(e.class).to eq(Keen::HttpError)
      expect(e.original_error).to be_kind_of(Timeout::Error)
      expect(e.message).to eq("Keen IO Exception: HTTP publish failure: execution expired")
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
      }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Write Key must be set for this operation")
    end

    context "when using proxy" do
      let(:client) do
        Keen::Client.new(:project_id => project_id,
                         :write_key => write_key,
                         :api_url => api_url,
                         :proxy_url => "http://localhost:8888",
                         :proxy_type => "socks5")
      end

      it "should return the proper response" do
        api_response = { "created" => true }
        stub_keen_post(api_event_collection_resource_url(api_url, collection), 201, api_response)
        expect(client.publish(collection, event_properties)).to eq(api_response)
      end
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
      }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Write Key must be set for this operation")
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
        stub_keen_post(api_event_collection_resource_url(api_url, 'User%20posts.new%20)(*%26%5E%25%40!)%3A%3A%2520%2520'), 201, api_success)
        EM.run {
          client.publish_async('User posts.new )(*&^%@!)::%20%20', event_properties).callback {
            begin
              expect_keen_post(api_event_collection_resource_url(api_url, 'User%20posts.new%20)(*%26%5E%25%40!)%3A%3A%2520%2520'), event_properties, "async", write_key)
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
                expect(response).to eq(api_success)
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
                expect(error).to_not be_nil
                expect(error.message).to eq("Keen IO Exception: HTTP publish_async failure: WebMock timeout error")
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
          }.to raise_error(NameError)
        end
      end
    end
  end

  describe "publish_batch_async" do
    unless defined?(JRUBY_VERSION)
      let(:multi) { EventMachine::MultiRequest.new }
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
          ).publish_batch_async(events)
        }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Project ID must be set")
      end

      it "should raise an exception if client has no write_key" do
        expect {
          Keen::Client.new(
            :project_id => "12345"
          ).publish_batch_async(events)
        }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Write Key must be set for this operation")
      end

      describe "deferrable callbacks" do
        it "should trigger callbacks" do
          stub_keen_post(api_event_resource_url(api_url), 201, api_success)
          EM.run {
            client.publish_batch_async(events).callback { |response|
              begin
                expect(response).to eq(api_success)
              ensure
                EM.stop
              end
            }
          }
        end

        it "should trigger errbacks" do
          stub_request(:post, api_event_resource_url(api_url)).to_timeout
          EM.run {
            client.publish_batch_async(events).errback { |error|
              begin
                expect(error).to_not be_nil
                expect(error.message).to eq("Keen IO Exception: HTTP publish_async failure: WebMock timeout error")
              ensure
                EM.stop
              end
            }
          }
        end

        it "should not trap exceptions in the client callback" do
          stub_keen_post(api_event_resource_url(api_url), 201, api_success)
          expect {
            EM.run {
              client.publish_batch_async(events).callback {
                begin
                  blowup
                ensure
                  EM.stop
                end
              }
            }
          }.to raise_error(NameError)
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
      expect(client).to receive(:publish).with(collection, {:a => 1})
      client.add_event(collection, {:a => 1}, {:b => 2})
    end
  end

  describe "beacon_url" do
    it "should return a url with a base-64 encoded json param" do
      expect(client.beacon_url("sign_ups", { :name => "Bob" })).to eq("#{api_url}/3.0/projects/12345/events/sign_ups?api_key=#{write_key}&data=eyJuYW1lIjoiQm9iIn0=")
    end
  end

  describe "redirect_url" do
    it "should return a url with a base-64 encoded json param and an encoded redirect url" do
      expect(client.redirect_url("sign_ups", { :name => "Bob" }, "http://keen.io/?foo=bar&bar=baz")).to eq("#{api_url}/3.0/projects/12345/events/sign_ups?api_key=#{write_key}&data=eyJuYW1lIjoiQm9iIn0=&redirect=http%3A%2F%2Fkeen.io%2F%3Ffoo%3Dbar%26bar%3Dbaz")
    end
  end

end

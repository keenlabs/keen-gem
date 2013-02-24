require File.expand_path("../spec_helper", __FILE__)

describe Keen::Client do
  let(:project_id) { "12345" }
  let(:api_key) { "abcde" }
  let(:collection) { "users" }
  let(:event_properties) { { "name" => "Bob" } }
  let(:api_success) { { "created" => true } }

  describe "#initialize" do
    context "deprecated" do
      it "should allow created via project_id and api_key args" do
        client = Keen::Client.new(project_id, api_key)
        client.api_key.should == api_key
        client.project_id.should == project_id
      end
    end

    it "should initialize with options" do
      client = Keen::Client.new(
        :project_id => project_id,
        :api_key => api_key)
      client.api_key.should == api_key
      client.project_id.should == project_id
    end
  end

  describe "with a unconfigured client" do
    [:publish, :publish_async].each do |_method|
      describe "##{_method}" do
        it "should raise an exception if no project_id" do
          expect {
            Keen::Client.new(:api_key => api_key).
              send(_method, collection, event_properties)
          }.to raise_error(Keen::ConfigurationError)
        end
      end
    end
  end

  describe "with a configured client" do
    before do
      @client = Keen::Client.new(:project_id => project_id)
    end

    describe "#publish" do
      it "should post using the collection and properties" do
        stub_api(api_url(collection), 201, "")
        @client.publish(collection, event_properties)
        expect_post(api_url(collection), event_properties, "sync")
      end

      it "should return the proper response" do
        api_response = { "created" => true }
        stub_api(api_url(collection), 201, api_response)
        @client.publish(collection, event_properties).should == api_response
      end

      it "should raise an argument error if no event collection is specified" do
        expect {
          @client.publish(nil, {})
        }.to raise_error(ArgumentError)
      end

      it "should raise an argument error if no properties are specified" do
        expect {
          @client.publish(collection, nil)
        }.to raise_error(ArgumentError)
      end

      it "should url encode the event collection" do
        stub_api(api_url("foo%20bar"), 201, "")
        @client.publish("foo bar", event_properties)
        expect_post(api_url("foo%20bar"), event_properties, "sync")
      end

      it "should wrap exceptions" do
        stub_request(:post, api_url(collection)).to_timeout
        e = nil
        begin
          @client.publish(collection, event_properties)
        rescue Exception => exception
          e = exception
        end

        e.class.should == Keen::HttpError
        e.original_error.class.should == Timeout::Error
        e.message.should == "Couldn't connect to Keen IO: execution expired"
      end
    end

    describe "#publish_async" do

      # no TLS support in EventMachine on jRuby
      unless defined?(JRUBY_VERSION)
        it "should require a running event loop" do
          expect {
            @client.publish_async(collection, event_properties)
          }.to raise_error(Keen::Error)
        end

        it "should post the event data" do
          stub_api(api_url(collection), 201, api_success)
          EM.run {
            @client.publish_async(collection, event_properties).callback {
              begin
                expect_post(api_url(collection), event_properties, "async")
              ensure
                EM.stop
              end
            }
          }
        end

        it "should uri encode the event collection" do
          stub_api(api_url("foo%20bar"), 201, api_success)
          EM.run {
            @client.publish_async("foo bar", event_properties).callback {
              begin
                expect_post(api_url("foo%20bar"), event_properties, "async")
              ensure
                EM.stop
              end
            }
          }
        end

        it "should raise an argument error if no event collection is specified" do
          expect {
            @client.publish_async(nil, {})
          }.to raise_error(ArgumentError)
        end

        it "should raise an argument error if no properties are specified" do
          expect {
            @client.publish_async(collection, nil)
          }.to raise_error(ArgumentError)
        end

        describe "deferrable callbacks" do
          it "should trigger callbacks" do
            stub_api(api_url(collection), 201, api_success)
            EM.run {
              @client.publish_async(collection, event_properties).callback { |response|
                begin
                  response.should == api_success
                ensure
                  EM.stop
                end
              }
            }
          end

          it "should trigger errbacks" do
            stub_request(:post, api_url(collection)).to_timeout
            EM.run {
              @client.publish_async(collection, event_properties).errback { |error|
                begin
                  error.should_not be_nil
                  error.message.should == "Couldn't connect to Keen IO: WebMock timeout error"
                ensure
                  EM.stop
                end
              }
            }
          end
        end
      end

    end

    describe "response handling" do
      def stub_status_and_publish(code, api_response=nil)
        stub_api(api_url(collection), code, api_response)
        @client.publish(collection, event_properties)
      end

      it "should return the json body for a 200-201" do
        api_response = { "created" => "true" }
        stub_status_and_publish(200, api_response).should == api_response
        stub_status_and_publish(201, api_response).should == api_response
      end

      it "should raise a bad request error for a 400" do
        expect {
          stub_status_and_publish(400)
        }.to raise_error(Keen::BadRequestError)
      end

      it "should raise a authentication error for a 401" do
        expect {
          stub_status_and_publish(401)
        }.to raise_error(Keen::AuthenticationError)
      end

      it "should raise a not found error for a 404" do
        expect {
          stub_status_and_publish(404)
        }.to raise_error(Keen::NotFoundError)
      end

      it "should raise an http error otherwise" do
        expect {
          stub_status_and_publish(420)
        }.to raise_error(Keen::HttpError)
      end
    end

    describe "#add_event" do
      it "should alias to publish" do
        @client.should_receive(:publish).with("users", {:a => 1}, {:b => 2})
        @client.add_event("users", {:a => 1}, {:b => 2})
      end
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

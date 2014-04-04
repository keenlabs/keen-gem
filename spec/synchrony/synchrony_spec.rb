require File.expand_path("../spec_helper", __FILE__)

describe Keen::HTTP::Async do
  let(:project_id) { "12345" }
  let(:write_key) { "abcdewrite" }
  let(:collection) { "users" }
  let(:api_url) { "https://fake.keen.io" }
  let(:event_properties) { { "name" => "Bob" } }
  let(:api_success) { { "created" => true } }
  let(:batch_api_success) { { "created" => true } }
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

  describe "synchrony" do
    before do
      @client = Keen::Client.new(
        :project_id => project_id, :write_key => write_key,
        :api_url => api_url)
    end

    describe "success" do
      it "should post the event data" do
        stub_keen_post(api_event_collection_resource_url(api_url, collection), 201, api_success)
        EM.synchrony {
          @client.publish_async(collection, event_properties)
          expect_keen_post(api_event_collection_resource_url(api_url, collection), event_properties, "async", write_key)
          EM.stop
        }
      end

      it "should receive the right response 'synchronously'" do
        stub_keen_post(api_event_collection_resource_url(api_url, collection), 201, api_success)
        EM.synchrony {
          @client.publish_async(collection, event_properties).should == api_success
          EM.stop
        }
      end
    end

    describe "batch success" do
      it "should post the event data" do
        stub_keen_post(api_event_resource_url(api_url), 201, api_success)
        EM.synchrony {
          @client.publish_batch_async(events)
          expect_keen_post(api_event_resource_url(api_url), events, "async", write_key)
          EM.stop
        }
      end

      it "should receive the right response 'synchronously'" do
        stub_keen_post(api_event_resource_url(api_url), 201, api_success)
        EM.synchrony {
          @client.publish_batch_async(events).should == api_success
          EM.stop
        }
      end
    end

    describe "failure" do
      it "should raise an exception" do
        stub_request(:post, api_event_collection_resource_url(api_url, collection)).to_timeout
        e = nil
        EM.synchrony {
          begin
            @client.publish_async(collection, event_properties).should == api_success
          rescue Exception => exception
            e = exception
          end
          e.class.should == Keen::HttpError
          e.message.should == "Keen IO Exception: HTTP em-synchrony publish_async error: WebMock timeout error"
          EM.stop
        }
      end
    end

    describe "batch failure" do
      it "should raise an exception" do
        stub_request(:post, api_event_resource_url(api_url)).to_timeout
        e = nil
        EM.synchrony {
          begin
            @client.publish_batch_async(events).should == api_success
          rescue Exception => exception
            e = exception
          end
          e.class.should == Keen::HttpError
          e.message.should == "Keen IO Exception: HTTP em-synchrony publish_async error: WebMock timeout error"
          EM.stop
        }
      end
    end
  end
end

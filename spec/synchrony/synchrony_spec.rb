require File.expand_path("../spec_helper", __FILE__)

describe Keen::HTTP::Async do
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

    describe "success" do
      it "should post the event data" do
        stub_api(api_url(collection), 201, api_success)
        EM.synchrony {
          @client.publish_async(collection, event_properties)
          expect_post(api_url(collection), event_properties, api_key)
          EM.stop
        }
      end

      it "should recieve the right response 'synchronously'" do
        stub_api(api_url(collection), 201, api_success)
        EM.synchrony {
          @client.publish_async(collection, event_properties).should == api_success
          EM.stop
        }
      end
    end

    describe "failure" do
      it "should raise an exception" do
        stub_request(:post, api_url(collection)).to_timeout
        e = nil
        EM.synchrony {
          begin
            @client.publish_async(collection, event_properties).should == api_success
          rescue Exception => exception
            e = exception
          end
          e.class.should == Keen::HttpError
          e.message.should == "Couldn't connect to Keen IO: WebMock timeout error"
          EM.stop
        }
      end
    end
  end
end

require File.expand_path("../spec_helper", __FILE__)

describe "Keen IO API" do
  let(:project_id) { ENV['KEEN_PROJECT_ID'] }
  let(:api_key) { ENV['KEEN_API_KEY'] }

  let(:collection) { "users" }
  let(:event_properties) { { "name" => "Bob" } }

  describe "success" do
    let(:expected_api_response) { { "created" => true } }

    it "should return a created status for a valid post" do
      Keen.publish(collection, event_properties).should ==
        expected_api_response
    end
  end

  describe "failure" do
    it "should raise a not found error if an invalid project id" do
      client = Keen::Client.new(
        :api_key => api_key, :project_id => "riker")
      expect {
        client.publish(collection, event_properties)
      }.to raise_error(Keen::NotFoundError)
    end

    it "should raise authentication error if invalid API Key" do
      client = Keen::Client.new(
        :api_key => "wrong", :project_id => project_id)
      expect {
        client.publish(collection, event_properties)
      }.to raise_error(Keen::AuthenticationError)
    end

    it "should raise bad request if no JSON is supplied" do
      expect {
        Keen.publish(collection, nil)
      }.to raise_error(Keen::BadRequestError)
    end

    it "should return not found for an invalid collection name" do
      expect {
        Keen.publish(nil, event_properties)
      }.to raise_error(Keen::NotFoundError)
    end
  end

  describe "async" do
    it "should work" do
      deferrable = Keen.publish_async(collection, event_properties)
      callback = double("callback")
      callback.should_receive("hit")
      deferrable.callback {
        callback.hit
      }
      sleep 2
    end
  end
end

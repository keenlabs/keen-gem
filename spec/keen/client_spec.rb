require File.expand_path("../spec_helper", __FILE__)

describe Keen::Client do
  let(:project_id) { "12345" }
  let(:api_key) { "abcde" }
  let(:client) { Keen::Client.new(:project_id => project_id) }

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

  describe "process_response" do
    let (:body) { "{ \"wazzup\": 1 }" }
    let (:process_response) { client.method(:process_response) }

    it "should raise a bad request error for a 400" do
      process_response.call(200, body).should == { "wazzup" => 1 }
    end

    it "should raise a bad request error for a 400" do
      expect {
        process_response.call(400, body)
      }.to raise_error(Keen::BadRequestError)
    end

    it "should raise a authentication error for a 401" do
      expect {
        process_response.call(401, body)
      }.to raise_error(Keen::AuthenticationError)
    end

    it "should raise a not found error for a 404" do
      expect {
        process_response.call(404, body)
      }.to raise_error(Keen::NotFoundError)
    end

    it "should raise an http error otherwise" do
      expect {
        process_response.call(420, body)
      }.to raise_error(Keen::HttpError)
    end
  end
end

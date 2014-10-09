require File.expand_path("../spec_helper", __FILE__)

describe Keen::Client do
  let(:project_id) { "12345" }
  let(:write_key) { "abcdewrite" }
  let(:read_key) { "abcderead" }
  let(:api_url) { "http://fake.keen.io:fakeport" }
  let(:client) { Keen::Client.new(:project_id => project_id) }

  before do
    ENV["KEEN_PROJECT_ID"] = nil
    ENV["KEEN_WRITE_KEY"] = nil
    ENV["KEEN_READ_KEY"] = nil
    ENV["KEEN_API_URL"] = nil
  end

  describe "#initialize" do
    context "deprecated" do
      it "should allow created via project_id and key args" do
        client = Keen::Client.new(project_id, write_key, read_key)
        client.write_key.should == write_key
        client.read_key.should == read_key
        client.project_id.should == project_id
      end
    end

    it "should initialize with options" do
      client = Keen::Client.new(
        :project_id => project_id,
        :write_key => write_key,
        :read_key => read_key,
        :api_url => api_url)
      client.write_key.should == write_key
      client.read_key.should == read_key
      client.project_id.should == project_id
      client.api_url.should == api_url
    end

    it "should set a default api_url" do
      Keen::Client.new.api_url.should == "https://api.keen.io"
    end
  end

  describe "process_response" do
    let (:body) { "{ \"wazzup\": 1 }" }
    let (:exception_body) { "Keen IO Exception: { \"wazzup\": 1 }" }
    let (:process_response) { client.method(:process_response) }

    it "should return encoded json for a 200" do
      process_response.call(200, body).should == { "wazzup" => 1 }
    end

    it "should return encoded json for a 201" do
      process_response.call(201, body).should == { "wazzup" => 1 }
    end

    it "should return empty for bad json on a 200/201" do
      process_response.call(200, "invalid json").should == {}
    end

    it "should raise a bad request error for a 400" do
      expect {
        process_response.call(400, body)
      }.to raise_error(Keen::BadRequestError, exception_body)
    end

    it "should raise a authentication error for a 401" do
      expect {
        process_response.call(401, body)
      }.to raise_error(Keen::AuthenticationError, exception_body)
    end

    it "should raise a not found error for a 404" do
      expect {
        process_response.call(404, body)
      }.to raise_error(Keen::NotFoundError, exception_body)
    end

    it "should raise an http error otherwise" do
      expect {
        process_response.call(420, body)
      }.to raise_error(Keen::HttpError, exception_body)
    end
  end

  describe "preprocess_params" do
    it "returns an empty string with no parameters" do
      params = {}
      expect(
        client.instance_eval{preprocess_params(params)}
      ).to eq("")
    end

    it "strips out nil parameters" do
      params = { :timeframe => nil, :group_by => "foo.bar" }
      expect(
        client.instance_eval{preprocess_params(params)}
      ).to eq("group_by=foo.bar")
    end
  end

  describe "preprocess_timeframe" do
    it "does nothing for string values" do
      params = { :timeframe => 'this_3_days' }
      expect {
        client.instance_eval{preprocess_timeframe(params)}
      }.to_not change { params }
    end

    it "multi encodes for hash values" do
      params = {:timeframe => {:start => '2012-08-13T19:00:00.000Z', :end => '2013-09-20T19:00:00.000Z'} }
      expect {
        client.instance_eval{preprocess_timeframe(params)}
      }.to change {params}.to({:timeframe => "{\"start\":\"2012-08-13T19:00:00.000Z\",\"end\":\"2013-09-20T19:00:00.000Z\"}"})
    end
  end
end

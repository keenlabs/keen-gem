require File.expand_path("../../spec_helper", __FILE__)

describe Keen::Client do
  let(:project_id) { "12345" }
  let(:read_key) { "abcde" }
  let(:api_url) { "https://notreal.keen.io" }
  let(:api_version) { "3.0" }
  let(:event_collection) { "users" }
  let(:client) { Keen::Client.new(
    :project_id => project_id, :read_key => read_key,
    :api_url => api_url ) }

  def query_url(query_name, query_params)
    "#{api_url}/#{api_version}/projects/#{project_id}/queries/#{query_name}#{query_params}"
  end

  describe "querying names" do
    let(:params) { { :event_collection => "signups" } }

    ["minimum", "maximum", "sum", "average", "count", "count_unique", "select_unique", "extraction", "multi_analysis"].each do |query_name|
      it "should call keen query passing the query name" do
        client.should_receive(:query).with(query_name.to_sym, event_collection, params)
        client.send(query_name, event_collection, params)
      end
    end

    describe "funnel" do
      it "should call keen query w/o event collection" do
        client.should_receive(:query).with(:funnel, nil, params)
        client.funnel(params)
      end
    end
  end

  describe "#query" do
    describe "with an improperly configured client" do
      it "should require a project id" do
        expect {
          Keen::Client.new(:read_key => read_key).count("users", {})
        }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Project ID must be set")
      end

      it "should require a read key" do
        expect {
          Keen::Client.new(:project_id => project_id).count("users", {})
        }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Read Key must be set for queries")
      end
    end

    describe "with a valid client" do
      let(:query) { client.method(:query) }
      let(:query_name) { "count" }
      let(:api_response) { { "result" => 1 } }

      def test_query(extra_query_params="", extra_query_hash={})
        expected_query_params = "?event_collection=#{event_collection}"
        expected_query_params += extra_query_params
        expected_url = query_url(query_name, expected_query_params)
        stub_keen_get(expected_url, 200, :result => 1)
        response = query.call(query_name, event_collection, extra_query_hash)
        response.should == api_response["result"]
        expect_keen_get(expected_url, "sync", read_key)
      end

      it "should call the API w/ proper headers and return the processed json response" do
        test_query
      end

      it "should encode filters properly" do
        filters = [{
          :property_name => "the+animal",
          :operator => "eq",
          :property_value => "dogs"
        }]
        filter_str = CGI.escape(MultiJson.encode(filters))
        test_query("&filters=#{filter_str}", :filters => filters)
      end

      it "should encode absolute timeframes properly" do
        timeframe = {
          :start => "2012-08-13T19:00Z+00:00",
          :end => "2012-08-13T19:00Z+00:00",
        }
        timeframe_str = CGI.escape(MultiJson.encode(timeframe))
        test_query("&timeframe=#{timeframe_str}", :timeframe => timeframe)
      end

      it "should encode steps properly" do
        steps = [{
          :event_collection => "sign ups",
          :actor_property => "user.id"
        }]
        steps_str = CGI.escape(MultiJson.encode(steps))
        test_query("&steps=#{steps_str}", :steps => steps)
      end

      it "should not encode relative timeframes" do
        timeframe = "last_10_days"
        test_query("&timeframe=#{timeframe}", :timeframe => timeframe)
      end

      it "should raise a failed responses" do
        query_params = "?event_collection=#{event_collection}"
        url = query_url(query_name, query_params)

        stub_keen_get(url, 401, :error => {})
        expect {
          query.call(query_name, event_collection, {})
        }.to raise_error(Keen::AuthenticationError)
        expect_keen_get(url, "sync", read_key)
      end
    end
  end

  describe "#count" do
    let(:query_params) { "?event_collection=#{event_collection}" }
    let(:url) { query_url("count", query_params) }
    before do
      stub_keen_get(url, 200, :result => 10)
    end

    it "should not require params" do
      client.count(event_collection).should == 10
      expect_keen_get(url, "sync", read_key)
    end

    context "with event collection as symbol" do
      let(:event_collection) { :users }
      it "should not require a string" do
        client.count(event_collection).should == 10
      end
    end
  end

  describe "#extraction" do
    it "should not require params" do
      query_params = "?event_collection=#{event_collection}"
      url = query_url("extraction", query_params)
      stub_keen_get(url, 200, :result => { "a" => 1 } )
      client.extraction(event_collection).should == { "a" => 1 }
      expect_keen_get(url, "sync", read_key)
    end
  end
end

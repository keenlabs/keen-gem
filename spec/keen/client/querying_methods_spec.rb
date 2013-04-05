require File.expand_path("../../spec_helper", __FILE__)

describe Keen::Client do
  let(:project_id) { "12345" }
  let(:api_key) { "abcde" }
  let(:api_host) { "api.keen.io" }
  let(:api_version) { "3.0" }
  let(:event_collection) { "users" }
  let(:client) { Keen::Client.new(:project_id => project_id, :api_key => api_key) }

  def query_url(query_name, query_params)
    "https://#{api_host}/#{api_version}/projects/#{project_id}/queries/#{query_name}#{query_params}"
  end

  describe "querying names" do
    let(:params) { { :event_collection => "signups" } }
    ["minimum", "maximum", "sum", "average", "count", "count_unique", "select_unique", "extraction", "funnel"].each do |query_name|
      it "should call keen query passing the query name" do
        client.should_receive(:query).with(query_name.to_sym, params)
        client.send(query_name, params)
      end
    end
  end

  describe "#query" do
    describe "with an improperly configured client" do
      it "should require a project id" do
        expect {
          Keen::Client.new(:api_key => api_key).count({})
        }.to raise_error(Keen::ConfigurationError)
      end

      it "should require an api key" do
        expect {
          Keen::Client.new(:project_id => project_id).count({})
        }.to raise_error(Keen::ConfigurationError)
      end
    end

    describe "with a valid client" do
      let(:query) { client.method(:query) }
      let(:query_name) { "count" }
      let(:api_response) { { "result" => 1 } }

      def test_query(extra_query_params="", extra_query_hash={})
        expected_query_params = "?api_key=#{api_key}&event_collection=#{event_collection}"
        expected_query_params += extra_query_params
        expected_url = query_url(query_name, expected_query_params)
        stub_keen_get(expected_url, 200, :result => 1)
        response = query.call(query_name, { :event_collection => event_collection }.merge(extra_query_hash))
        response.should == api_response
        expect_keen_get(expected_url, "sync")
      end

      it "should call the API w/ proper headers and return the processed json response" do
        test_query
      end

      it "should encode filters properly" do
        filters = [{
          :property_name => "animal",
          :operator => "eq",
          :property_value => "dogs"
        }]
        filter_str = MultiJson.encode(filters)
        test_query("&filters=#{filter_str}", :filters => filters)
      end

      it "should encode absolute timeframes properly" do
        timeframe = {
          :start => "2012-08-13T19:00Z",
          :end => "2012-08-13T19:00Z",
        }
        timeframe_str = MultiJson.encode(timeframe)
        test_query("&timeframe=#{timeframe_str}", :timeframe => timeframe)
      end

      it "should encode steps properly" do
        steps = [{
          :event_collection => "signups",
          :actor_property => "user.id"
        }]
        steps_str = MultiJson.encode(steps)
        test_query("&steps=#{steps_str}", :steps => steps)
      end

      it "should not encode relative timeframes" do
        timeframe = "last_10_days"
        test_query("&timeframe=#{timeframe}", :timeframe => timeframe)
      end

      it "should raise a failed responses" do
        query_params = "?api_key=#{api_key}&event_collection=#{event_collection}"
        url = query_url(query_name, query_params)

        stub_keen_get(url, 401, :error => {})
        expect {
          query.call(query_name, :event_collection => event_collection)
        }.to raise_error(Keen::AuthenticationError)
        expect_keen_get(url, "sync")
      end
    end
  end
end

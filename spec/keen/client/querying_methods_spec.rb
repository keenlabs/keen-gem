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

  def query_url(query_name, query_params = "")
    "#{api_url}/#{api_version}/projects/#{project_id}/queries/#{query_name}#{query_params}"
  end

  describe "querying names" do
    let(:params) { { :event_collection => "signups" } }

    ["minimum", "maximum", "sum", "average", "count", "count_unique", "select_unique", "extraction", "multi_analysis", "median", "percentile"].each do |query_name|
      it "should call keen query passing the query name" do
        expect(client).to receive(:query).with(query_name.to_sym, event_collection, params, {})
        client.send(query_name, event_collection, params)
      end
    end

    describe "funnel" do
      it "should call keen query w/o event collection" do
        expect(client).to receive(:query).with(:funnel, nil, params, {})
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
        }.to raise_error(Keen::ConfigurationError, "Keen IO Exception: Read Key must be set for this operation")
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
        expect(response).to eq(api_response["result"])
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

      it "should encode a single group by property" do
        test_query("&group_by=one%20foo", :group_by => "one foo")
      end

      it "should encode multi-group by properly" do
        group_by = ["one", "two"]
        group_by_str = CGI.escape(MultiJson.encode(group_by))
        test_query("&group_by=#{group_by_str}", :group_by => group_by)
      end

      it "should encode an array of property names property" do
        property_names = ["one", "two"]
        property_names_str = CGI.escape(MultiJson.encode(property_names))
        test_query("&property_names=#{property_names_str}", :property_names => property_names)
      end

      it "should encode a percentile decimal properly" do
        test_query("&percentile=99.99", :percentile => 99.99)
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

      it "should not change the extra params" do
        timeframe = {
          :start => "2012-08-13T19:00Z+00:00",
          :end => "2012-08-13T19:00Z+00:00",
        }
        timeframe_str =  CGI.escape(MultiJson.encode(timeframe))

        test_query("&timeframe=#{timeframe_str}", options = {:timeframe => timeframe})
        expect(options).to eq({:timeframe => timeframe})
      end

      it "should return the full API response if the response option is set to all_keys" do
        expected_url = query_url("funnel", "?steps=#{MultiJson.encode([])}")
        stub_keen_get(expected_url, 200, :result => [1])
        api_response = query.call("funnel", nil, { :steps => [] }, { :response => :all_keys })
        expect(api_response).to eq({ "result" => [1] })
      end

      context "if log_queries is true" do
        before(:each) { client.log_queries = true }

        it "logs the query" do
          expect(client).to receive(:log_query).with(query_url("count", "?event_collection=users"))
          test_query
        end

        after(:each) { client.log_queries = false }
      end

      context "if method option is set to post" do
        let(:steps) do
          [{
            :event_collection => "sign ups",
            :actor_property => "user.id"
          }]
        end
        let(:expected_url) { query_url("funnel") }
        before(:each) { stub_keen_post(expected_url, 200, :result => 1) }

        it "should call API with post body" do
          response = query.call("funnel", nil, { :steps => steps }, { :method => :post })

          expect_keen_post(expected_url, { :steps => steps }, "sync", read_key)
          expect(response).to eq(api_response["result"])
        end

        context "if log_queries is true" do
          before(:each) { client.log_queries = true }

          it "logs the query" do
            expected_params = {:steps=>[{:event_collection=>"sign ups", :actor_property=>"user.id"}]}
            expect(client).to receive(:log_query).with(expected_url, 'POST', expected_params)
            query.call("funnel", nil, { :steps => steps }, { :method => :post })
          end

          after(:each) { client.log_queries = false }
        end
      end

      it "should add extra headers if you supply them as an option" do
        url = query_url("count", "?event_collection=#{event_collection}")
        extra_headers = {
          "Keen-Flibbity-Flabbidy" => "foobar"
        }

        options = {
          :headers => extra_headers
        }

        stub_keen_get(url, 200, :result => 10)
        client.count(event_collection, {}, options)
        expect_keen_get(url, "sync", read_key, extra_headers)
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
      expect(client.count(event_collection)).to eq(10)
      expect_keen_get(url, "sync", read_key)
    end

    context "with event collection as symbol" do
      let(:event_collection) { :users }
      it "should not require a string" do
        expect(client.count(event_collection)).to eq(10)
      end
    end
  end

  describe "#extraction" do
    it "should not require params" do
      query_params = "?event_collection=#{event_collection}"
      url = query_url("extraction", query_params)
      stub_keen_get(url, 200, :result => { "a" => 1 } )
      expect(client.extraction(event_collection)).to eq({ "a" => 1 })
      expect_keen_get(url, "sync", read_key)
    end
  end

  describe "#query_url" do
    let(:expected) {  }

    it "should returns the URL for a query" do
      response = client.query_url('count', event_collection)
      expect(response).to eq 'https://notreal.keen.io/3.0/projects/12345/queries/count?event_collection=users&api_key=abcde'
    end

    it "should exclude the api key if option is passed" do
      response = client.query_url('count', event_collection, {}, :exclude_api_key => true)
      expect(response).to eq 'https://notreal.keen.io/3.0/projects/12345/queries/count?event_collection=users'
    end

    it "should not run the query" do
      expect(Keen::HTTP::Sync).to_not receive(:new)
    end
  end
end

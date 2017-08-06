require File.expand_path("../spec_helper", __FILE__)

describe Keen do
  let(:client) do
    Keen::Client.new(
      project_id: "12341234",
      master_key: "abcdef",
      api_url: "https://notreal.keen.io"
    )
  end

  describe "#saved_queries" do
    describe "#all" do

      it "returns all saved queries" do
        all_saved_queries = [ {
          "refresh_rate" => 0,
          "last_modified_date" => "2015-10-19T20:14:29.797000+00:00",
          "query_name" => "Analysis-API-Calls-this-1-day",
          "query" => {
            "filters" => [],
            "analysis_type" => "count",
            "timezone" => "UTC",
            "timeframe" => "this_1_days",
            "event_collection" => "analysis_api_call"
          },
          "metadata" => {
            "visualization" => { "chart_type" => "metric"}
          }
        } ]
        stub_keen_get(saved_query_endpoint, 200, all_saved_queries)

        all_saved_queries_response = client.saved_queries.all

        expect(all_saved_queries_response).to eq(all_saved_queries)
      end
    end

    describe "#get" do
      it "returns a specific saved query given a query id" do
        saved_query = {
          "refresh_rate" => 0,
          "last_modified_date" => "2015-10-19T20:14:29.797000+00:00",
          "query_name" => "Analysis-API-Calls-this-1-day",
          "query" => {
            "filters" => [],
            "analysis_type" => "count",
            "timezone" => "UTC",
            "timeframe" => "this_1_days",
            "event_collection" => "analysis_api_call"
          },
          "metadata" => {
            "visualization" => { "chart_type" => "metric"}
          }
        }
        stub_keen_get(
          saved_query_endpoint + "/#{saved_query["query_name"]}",
          200,
          saved_query
        )

        saved_query_response = client.saved_queries.get("Analysis-API-Calls-this-1-day")

        expect(saved_query_response).to eq(saved_query)
      end

      it "throws an exception if service can't find saved query" do
        saved_query = {
          message: "Resource not found",
          error_code: "ResourceNotFoundError"
        }
        stub_keen_get(
          saved_query_endpoint + "/missing-query",
          404,
          saved_query
        )

        expect {
          client.saved_queries.get("missing-query")
        }.to raise_error(Keen::NotFoundError)
      end
    end

    describe "#create" do
      it "returns the created saved query when creation is successful" do
        saved_query = {
          "refresh_rate" => 0,
          "last_modified_date" => "2015-10-19T20:14:29.797000+00:00",
          "query_name" => "new-query",
          "query" => {
            "filters" => [],
            "analysis_type" => "count",
            "timezone" => "UTC",
            "timeframe" => "this_1_days",
            "event_collection" => "analysis_api_call"
          },
          "metadata" => {
            "visualization" => { "chart_type" => "metric"}
          }
        }
        stub_keen_put(
          saved_query_endpoint + "/#{saved_query[:query_name]}", 201, saved_query
        )

        saved_query_response = client.saved_queries.create(saved_query[:query_name], saved_query)

        expect(saved_query_response).to eq(saved_query)
      end

      it "raises an error when creation is unsuccessful" do
        stub_keen_put(
          saved_query_endpoint + "/saved-query-name", 400, {}
        )

        expect {
          client.saved_queries.create("saved-query-name", {})
        }.to raise_error(Keen::BadRequestError)
      end
    end

    describe "#update" do
      it "returns the created saved query when update is successful" do
        saved_query = {
          "refresh_rate" => 0,
          "last_modified_date" => "2015-10-19T20:14:29.797000+00:00",
          "query_name" => "new-query",
          "query" => {
            "filters" => [],
            "analysis_type" => "count",
            "timezone" => "UTC",
            "timeframe" => "this_1_days",
            "event_collection" => "analysis_api_call"
          },
          "metadata" => {
            "visualization" => { "chart_type" => "metric"}
          }
        }
        stub_keen_put(
          saved_query_endpoint + "/#{saved_query[:query_name]}", 200, saved_query
        )

        saved_query_response = client.saved_queries.update(saved_query[:query_name], saved_query)

        expect(saved_query_response).to eq(saved_query)
      end
    end

    describe "#delete" do
      it "returns true with deletion is successful" do
        query_name = "query-to-be-deleted"
        stub_keen_delete(
          saved_query_endpoint + "/#{query_name}", 204
        )

        saved_query_response = client.saved_queries.delete(query_name)

        expect(saved_query_response).to eq(true)
      end
    end
  end

  def saved_query_endpoint
    client.api_url + "/#{client.api_version}/projects/#{client.project_id}/queries/saved"
  end
end

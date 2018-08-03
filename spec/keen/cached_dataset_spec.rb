require File.expand_path("../spec_helper", __FILE__)

describe Keen do
  let(:client) do
    Keen::Client.new(
      project_id: "12341234",
      master_key: "abcdef",
      read_key: "ghijkl",
      api_url: "https://notreal.keen.io"
    )
  end

  describe "#cached_datasets" do
    describe "#list" do

      it "returns cached dataset definitions" do
        example_result = {
          "datasets" => [{
            "project_id" => "PROJECT_ID",
            "organization_id" => "ORGANIZATION_ID",
            "dataset_name" => "DATASET_NAME_1",
            "display_name" => "a first dataset wee",
            "query" => {
              "project_id" => "PROJECT_ID",
              "analysis_type" => "count",
              "event_collection" => "best collection",
              "filters" => [{
                "property_name" => "request.foo",
                "operator" => "lt",
                "property_value" => 300
              }],
              "timeframe" => "this_500_hours",
              "timezone" => "US/Pacific",
              "interval" => "hourly",
              "group_by" => [
                "exception.name"
              ]
            },
            "index_by" => [
              "project.id"
            ],
            "last_scheduled_date" => "2016-11-04T18:03:38.430Z",
            "latest_subtimeframe_available" => "2016-11-04T19:00:00.000Z",
            "milliseconds_behind" => 3600000
          }, {
            "project_id" => "PROJECT_ID",
            "organization_id" => "ORGANIZATION_ID",
            "dataset_name" => "DATASET_NAME_10",
            "display_name" => "tenth dataset wee",
            "query" => {
              "project_id" => "PROJECT_ID",
              "analysis_type" => "count",
              "event_collection" => "tenth best collection",
              "filters" => [],
              "timeframe" => "this_500_days",
              "timezone" => "UTC",
              "interval" => "daily",
              "group_by" => [
                "analysis_type"
              ]
            },
            "index_by" => [
              "project.organization.id"
            ],
            "last_scheduled_date" => "2016-11-04T19:28:36.639Z",
            "latest_subtimeframe_available" => "2016-11-05T00:00:00.000Z",
            "milliseconds_behind" => 3600000
          }],
          "next_page_url" => nil
        }

        stub_keen_get(datasets_endpoint, 200, example_result)

        listed_cached_datasets_response = client.cached_datasets.list

        expect(listed_cached_datasets_response).to eq(example_result)
      end

      it 'accepts params for pagination' do
        example_result = {
          "datasets" => [{
            "project_id" => "PROJECT_ID",
            "organization_id" => "ORGANIZATION_ID",
            "dataset_name" => "DATASET_NAME_10",
            "display_name" => "tenth dataset wee",
            "query" => {
              "project_id" => "PROJECT_ID",
              "analysis_type" => "count",
              "event_collection" => "tenth best collection",
              "filters" => [],
              "timeframe" => "this_500_days",
              "timezone" => "UTC",
              "interval" => "daily",
              "group_by" => [
                "analysis_type"
              ]
            },
            "index_by" => [
              "project.organization.id"
            ],
            "last_scheduled_date" => "2016-11-04T19:28:36.639Z",
            "latest_subtimeframe_available" => "2016-11-05T00:00:00.000Z",
            "milliseconds_behind" => 3600000
          }],
          "next_page_url" => "https://api.keen.io/3.0/projects/PROJECT_ID/datasets?limit=1&after_name=DATASET_NAME_1"
        }

        stub_keen_get(datasets_endpoint + "?limit=1&after_name=DATASET_NAME_1", 200, example_result)

        listed_cached_datasets_response = client.cached_datasets.list(limit: 1, after_name: 'DATASET_NAME_1')

        expect(listed_cached_datasets_response).to eq(example_result)
      end
    end

    describe "#get_definition" do

      it "returns a cached dataset definition" do
        example_result = {
          "project_id" => "PROJECT_ID",
          "organization_id" => "ORGANIZATION_ID",
          "dataset_name" => "DATASET_NAME_1",
          "display_name" => "Count Daily Product Purchases Over $100 by Country",
          "query" =>  {
            "project_id" => "5011efa95f546f2ce2000000",
            "analysis_type" => "count",
            "event_collection" => "purchases",
            "filters" =>  [
              {
                "property_name" => "price",
                "operator" => "gte",
                "property_value" => 100
              }
            ],
            "timeframe" => "this_500_days",
            "timezone" => nil,
            "interval" => "daily",
            "group_by" => ["ip_geo_info.country"]
          },
          "index_by" => ["product.id"],
          "last_scheduled_date" => "2016-11-04T18:52:36.323Z",
          "latest_subtimeframe_available" => "2016-11-05T00:00:00.000Z",
          "milliseconds_behind" =>  3600000
        }


        stub_keen_get(datasets_endpoint + '/DATASET_NAME_1', 200, example_result)

        cached_dataset_response = client.cached_datasets.get_definition('DATASET_NAME_1')

        expect(cached_dataset_response).to eq(example_result)
      end
    end

    describe "#get_results" do

      it "returns results for a cached dataset" do
        example_result = {
          "result" => [
            {
              "timeframe" => {
                "start" => "2016-11-02T00:00:00.000Z",
                "end" => "2016-11-03T00:00:00.000Z"
              },
              "value" => [
                {
                  "item.name" => "Golden Widget",
                  "result" => 0
                },
                {
                  "item.name" => "Silver Widget",
                  "result" => 18
                },
                {
                  "item.name" => "Bronze Widget",
                  "result" => 1
                },
                {
                  "item.name" => "Platinum Widget",
                  "result" => 9
                }
              ]
            },
            {
              "timeframe" => {
                "start" => "2016-11-03T00:00:00.000Z",
                "end" => "2016-11-04T00:00:00.000Z"
              },
              "value" => [
                {
                  "item.name" => "Golden Widget",
                  "result" => 1
                },
                {
                  "item.name" => "Silver Widget",
                  "result" => 13
                },
                {
                  "item.name" => "Bronze Widget",
                  "result" => 0
                },
                {
                  "item.name" => "Platinum Widget",
                  "result" => 3
                }
              ]
            }
          ]
        }

        stub_keen_get(
          datasets_endpoint + '/DATASET_NAME_1/results?index_by=some-user-id&timeframe=%7B%22start%22:%222012-08-13T19:00:00.000Z%22,%22end%22:%222013-09-20T19:00:00.000Z%22%7D',
          200,
          example_result
        )

        cached_dataset_response = client.cached_datasets.get_results('DATASET_NAME_1', {
          start: "2012-08-13T19:00:00.000Z",
          end: "2013-09-20T19:00:00.000Z"
        }, 'some-user-id')
        expect(cached_dataset_response).to eq(example_result)
      end

      it 'raises an error if cached dataset is not defined' do
        example_result = {
          message: "Resource not found",
          error_code: "ResourceNotFoundError"
        }
        stub_keen_get(
          datasets_endpoint + "/missing-dataset/results?index_by=some-user-id&timeframe=%7B%22start%22:%222012-08-13T19:00:00.000Z%22,%22end%22:%222013-09-20T19:00:00.000Z%22%7D",
          404,
          example_result
        )

        expect {
          cached_dataset_response = client.cached_datasets.get_results('missing-dataset', {
            start: "2012-08-13T19:00:00.000Z",
            end: "2013-09-20T19:00:00.000Z"
          }, 'some-user-id')
        }.to raise_error(Keen::NotFoundError)
      end
    end

    describe "#create" do
      it "returns the created dataset when creation is successful" do
        example_result = {
          "project_id" => "PROJECT ID",
          "organization_id" => "ORGANIZATION",
          "dataset_name" => "DATASET_NAME_1",
          "display_name" => "DS Display Name",
          "query" =>  {
            "project_id" => "PROJECT ID",
            "analysis_type" => "count",
            "event_collection" => "purchases",
            "filters" =>  [
              {
                "property_name" => "price",
                "operator" => "gte",
                "property_value" => 100
              }
            ],
            "timeframe" => "this_500_days",
            "interval" => "daily",
            "group_by" => ["ip_geo_info.country"]
          },
          "index_by" =>  "product.id",
          "last_scheduled_date" => "1970-01-01T00:00:00.000Z",
          "latest_subtimeframe_available" => "1970-01-01T00:00:00.000Z",
          "milliseconds_behind" =>  3600000
        }
        stub_keen_put(
          datasets_endpoint + "/DATASET_NAME_1", 201, example_result
        )

        create_response = client.cached_datasets.create('DATASET_NAME_1', 'product.id', example_result['query'], 'DS Display Name')

        expect(create_response).to eq(example_result)
      end

      it "raises an error when creation is unsuccessful" do
        stub_keen_put(
          datasets_endpoint + "/DATASET_NAME_1", 400, {}
        )

        expect {
          client.cached_datasets.create("DATASET_NAME_1", 'product.id', {}, 'DS Display Name')
        }.to raise_error(Keen::BadRequestError)
      end
    end

    describe "#delete" do
      it "returns true with deletion is successful" do
        dataset_name = "dataset-to-be-deleted"
        stub_keen_delete(
          datasets_endpoint + "/dataset-to-be-deleted", 204
        )

        result = client.cached_datasets.delete(dataset_name)

        expect(result).to eq(true)
      end
    end
  end

  def datasets_endpoint
    client.api_url + "/#{client.api_version}/projects/#{client.project_id}/datasets"
  end
end

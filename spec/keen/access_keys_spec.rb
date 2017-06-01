require File.expand_path("../spec_helper", __FILE__)

describe Keen do
  let(:client) do
    Keen::Client.new(
      project_id: "12341234",
      master_key: "abcdef",
      api_url: "https://notreal.keen.io"
    )
  end

  describe "#access_keys" do
    describe "#all" do

      it "returns all access keys" do
        all_access_keys = [
          key_object()
        ]

        stub_keen_get(access_keys_endpoint, 200, all_access_keys)

        all_access_keys_response = client.access_keys.all

        expect(all_access_keys_response).to eq(all_access_keys)
      end
    end

    describe "#get" do
      it "returns a specific access key given a key" do
        key = key_object()

        stub_keen_get(
          access_keys_endpoint + "/#{key["key"]}",
          200,
          key
        )

        access_key_response = client.access_keys.get(key["key"])

        expect(access_key_response).to eq(key)
      end
		end

    describe "#create" do
      it "returns the created saved query when creation is successful" do
        key = key_object()

        stub_keen_post(
          access_keys_endpoint, 201, key
        )

        access_keys_response = client.access_keys.create(key)

        expect(access_keys_response).to eq(key)
      end
    end

    describe "#update" do
      it "returns the updated access key when update is successful" do
        key = key_object()

        stub_keen_post(
          access_keys_endpoint + "/#{key["key"]}", 200, key
        )

        access_keys_response = client.access_keys.update(key["key"], key)

        expect(access_keys_response).to eq(key)
      end
    end

    describe "#delete" do
      it "returns true with deletion is successful" do
        key = "asdf1234"

        stub_keen_delete(
          access_keys_endpoint + "/#{key}", 204
        )

        access_keys_response = client.access_keys.delete(key)

        expect(access_keys_response).to eq(true)
      end
    end
  end

  def access_keys_endpoint
    client.api_url + "/#{client.api_version}/projects/#{client.project_id}/keys"
  end

  def key_object(name = "Test Access Key")
    {
      "key" => "SDKFJSDKFJSDKFJSDKFJDSK",
      "name" => name,
      "is_active" => true,
      "permitted" => ["queries", "cached_queries"],
      "options" => {
        "queries" => {
          "filters" => [
            {
              "property_name" => "customer.id",
              "operator" => "eq", 
              "property_value" => "asdf12345z"
            }
          ]
        },
        "cached_queries" => {
          "allowed" => ["my_cached_query"]
        }
      }
    }
  end
end

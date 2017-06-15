require File.expand_path("../spec_helper", __FILE__)

describe "Access Keys" do
  let(:project_id) { ENV["KEEN_PROJECT_ID"] }
  let(:master_key) { ENV["KEEN_MASTER_KEY"] }
  let(:client) { Keen::Client.new(project_id: project_id, master_key: master_key) }

  describe "#all" do
    it "gets all access keys" do
      expect(client.access_keys.all).to be_instance_of(Array)
    end
  end

  describe "#create" do
    it "creates a key" do
      key_body = {
        "name" => "integration test key",
        "is_active" => true,
        "permitted" => ["queries"],
        "options" => {}
      }

      create_result = client.access_keys.create(key_body)
      expect(create_result["name"]).to eq(key_body["name"])
    end
  end

  describe "#get" do
    it "gets a single access key" do
      all_keys = client.access_keys.all

      access_key = client.access_keys.get(all_keys.first["key"])

      expect(access_key["name"]).to eq(all_keys.first["name"])
    end
  end

  describe "#revoke" do
    it "sets the is_active to false" do
      all_keys = client.access_keys.all
      key = all_keys.first["key"]

      client.access_keys.revoke(key)
      new_key = client.access_keys.get(key)
      expect(new_key["is_active"]).to be_falsey
    end
  end

  describe "#unrevoke" do
    it "sets the is_active to true" do
      all_keys = client.access_keys.all
      key = all_keys.first["key"]

      client.access_keys.unrevoke(key)
      new_key = client.access_keys.get(key)
      expect(new_key["is_active"]).to be_truthy
    end
  end

  describe "#delete" do
    it "deletes a key" do
      all_keys = client.access_keys.all
      key = all_keys.first["key"]

      client.access_keys.delete(key)
      all_keys = client.access_keys.all
      expect(all_keys).to eq([])
    end
  end
end

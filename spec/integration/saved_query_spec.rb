require File.expand_path("../spec_helper", __FILE__)

describe "Saved Queries" do
  let(:project_id) { ENV["KEEN_PROJECT_ID"] }
  let(:master_key) { ENV["KEEN_MASTER_KEY"] }
  let(:read_key) { ENV["KEEN_READ_KEY"] }
  let(:client) { Keen::Client.new(project_id: project_id, master_key: master_key, read_key: read_key) }

  describe "#all" do
    it "gets all saved_queries" do
      expect(client.saved_queries.all).to be_instance_of(Array)
    end
  end

  describe "#get" do
    it "gets a single saved query" do
      all_queries = client.saved_queries.all

      single_saved_query = client.saved_queries.get(all_queries.first[:query_name])

      expect(single_saved_query[:query_name]).to eq(all_queries.first[:query_name])
      expect(single_saved_query[:results]).to be_nil
    end
  end

  describe "#results" do
    it "gets a single saved query" do
      all_queries = client.saved_queries.all

      single_saved_query = client.saved_queries.get(all_queries.last[:query_name], results: true)

      expect(single_saved_query[:result]).not_to be_nil
    end
  end
end

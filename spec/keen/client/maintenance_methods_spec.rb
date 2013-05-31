require File.expand_path("../../spec_helper", __FILE__)

describe Keen::Client do
  let(:project_id) { "12345" }
  let(:master_key) { 'pastor_of_muppets' }
  let(:api_url) { "https://notreal.keen.io" }
  let(:api_version) { "3.0" }
  let(:client) { Keen::Client.new(
    :project_id => project_id, :master_key => master_key,
    :api_url => api_url ) }

  def delete_url(event_collection, filter_params=nil)
    "#{api_url}/#{api_version}/projects/#{project_id}/events/#{event_collection}#{filter_params ? "?filters=#{URI.escape(MultiJson.encode(filter_params[:filters]))}" : ""}"
  end

  describe '#delete' do
    let(:event_collection) { :foodstuffs }

    it 'should not require filters' do
      url = delete_url(event_collection)
      stub_keen_delete(url, 204)
      client.delete(event_collection).should be_true
      expect_keen_delete(url, "sync", master_key)
    end

    it "should accept and use filters" do
      filters = {
        :filters => [
          { :property_name => "delete", :operator => "eq", :property_value => "me" }
        ]
      }
      url = delete_url(event_collection, filters)
      stub_keen_delete(url, 204).should be_true
      client.delete(event_collection, filters)
      expect_keen_delete(url, "sync", master_key)
    end
  end
end

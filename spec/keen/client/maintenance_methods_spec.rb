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
    "#{api_url}/#{api_version}/projects/#{project_id}/events/#{event_collection}#{filter_params}"
  end

  before do
    stub_keen_delete(url, 200)
  end

  describe '#delete' do
    let(:event_collection) { :foodstuffs }
    let(:url) { delete_url(event_collection) }

    it 'should not require filters' do
      client.delete(event_collection)
      expect_keen_delete(url, "sync", master_key)
    end
  end
end

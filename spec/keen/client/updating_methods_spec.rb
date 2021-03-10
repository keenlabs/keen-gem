# frozen_string_literal: true

require File.expand_path('../spec_helper', __dir__)

describe Keen::Client::UpdatingMethods do
  let(:project_id) { '12345' }
  let(:master_key) { 'abcde' }
  let(:api_url) { 'https://unreal.keen.io' }
  let(:collection) { 'logins' }
  let(:event_properties) do
    {
      property_updates: [
        {
          property_name: 'user.age',
          property_value: 55
        }
      ],
      filters: [
        {
          property_name: 'user.age',
          operator: 'lt',
          property_value: 55
        }
      ],
      timeframe: {
        start: '2020-03-01T00:00:00.000Z'
      }
    }
  end
  let(:client) { Keen::Client.new(project_id: project_id, master_key: master_key, api_url: api_url) }

  describe 'updating' do
    it 'should put using the collection and params' do
      stub_keen_put(api_event_collection_resource_url(api_url, collection), 200, {})
      client.update(collection, event_properties)
      expect_keen_put(api_event_collection_resource_url(api_url, collection), event_properties, 'update', master_key)
    end

    it 'should return the proper response' do
      stub_keen_put(api_event_collection_resource_url(api_url, collection), 200, {})
      expect(client.update(collection, event_properties)).to eq({})
    end

    it 'should raise an argument error if no event collection is specified' do
      expect do
        client.update(nil, {})
      end.to raise_error(ArgumentError)
    end

    it 'should raise an argument error if no properties are specified' do
      expect do
        client.update(collection, nil)
      end.to raise_error(ArgumentError)
    end

    it 'should wrap exceptions' do
      stub_request(:put, api_event_collection_resource_url(api_url, collection)).to_timeout
      e = nil
      begin
        client.update(collection, event_properties)
      rescue Exception => e
        e = e
      end

      expect(e.class).to eq(Keen::HttpError)
      expect(e.original_error).to be_kind_of(Timeout::Error)
      expect(e.message).to eq('Keen IO Exception: HTTP update failure: execution expired')
    end

    it 'should raise an exception if client has no project_id' do
      expect do
        Keen::Client.new(
          master_key: 'abcde'
        ).update(collection, event_properties)
      end.to raise_error(Keen::ConfigurationError, 'Keen IO Exception: Project ID must be set')
    end

    it 'should raise an exception if client has no master_key' do
      expect do
        Keen::Client.new(
          project_id: '12345'
        ).update(collection, event_properties)
      end.to raise_error(Keen::ConfigurationError, 'Keen IO Exception: Master Key must be set for this operation')
    end

    context 'when using proxy' do
      let(:client) do
        Keen::Client.new(project_id: project_id,
                         master_key: master_key,
                         api_url: api_url,
                         proxy_url: 'http://localhost:8888',
                         proxy_type: 'socks5')
      end

      it 'should return the proper response' do
        stub_keen_put(api_event_collection_resource_url(api_url, collection), 200, {})
        expect(client.update(collection, event_properties)).to eq({})
      end
    end
  end
end

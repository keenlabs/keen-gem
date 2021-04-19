# frozen_string_literal: true

require File.expand_path('../spec_helper', __dir__)

describe Keen::Client::UpdatingMethods do
  let(:project_id) { '12345' }
  let(:master_key) { 'abcde' }
  let(:api_url) { 'https://unreal.keen.io' }
  let(:collection) { 'logins' }
  let(:params) do
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
      client.update(collection, params)
      expect_keen_put(api_event_collection_resource_url(api_url, collection), params, 'update', master_key)
    end

    it 'should return the proper response' do
      stub_keen_put(api_event_collection_resource_url(api_url, collection), 200, {})
      expect(client.update(collection, params)).to eq({})
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
      error = nil
      begin
        client.update(collection, params)
      rescue StandardError => e
        error = e
      end

      expect(error.class).to eq(Keen::HttpError)
      expect(error.original_error).to be_kind_of(Timeout::Error)
      expect(error.message).to eq('Keen IO Exception: HTTP update failure: execution expired')
    end

    it 'should raise an exception if client has no project_id' do
      expect do
        Keen::Client.new(
          master_key: 'abcde'
        ).update(collection, params)
      end.to raise_error(Keen::ConfigurationError, 'Keen IO Exception: Project ID must be set')
    end

    it 'should raise an exception if client has no master_key' do
      expect do
        Keen::Client.new(
          project_id: '12345'
        ).update(collection, params)
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
        expect(client.update(collection, params)).to eq({})
      end
    end
  end

  describe 'batch_updating' do
    let(:params) do
      {
        batch_update: [
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
          },
          {
            property_updates: [
              {
                property_name: 'user.name',
                property_value: 'John'
              }
            ],
            filters: [
              {
                property_name: 'user.name',
                operator: 'eq',
                property_value: 'George'
              }
            ],
            timeframe: {
              start: '2020-03-01T00:00:00.000Z',
              end: '2020-04-01T00:00:00.000Z'
            }
          }
        ]
      }
    end

    it 'should put using the collection and params' do
      stub_keen_put(api_event_collection_resource_url(api_url, collection), 200, {})
      client.update_batch(collection, params)
      expect_keen_put(api_event_collection_resource_url(api_url, collection), params, 'update', master_key)
    end

    it 'should return the proper response' do
      stub_keen_put(api_event_collection_resource_url(api_url, collection), 200, {})
      expect(client.update_batch(collection, params)).to eq({})
    end

    it 'should raise an argument error if no event collection is specified' do
      expect do
        client.update_batch(nil, {})
      end.to raise_error(ArgumentError)
    end

    it 'should raise an argument error if no properties are specified' do
      expect do
        client.update_batch(collection, nil)
      end.to raise_error(ArgumentError)
    end

    it 'should wrap exceptions' do
      stub_request(:put, api_event_collection_resource_url(api_url, collection)).to_timeout
      error = nil
      begin
        client.update_batch(collection, params)
      rescue StandardError => e
        error = e
      end

      expect(error.class).to eq(Keen::HttpError)
      expect(error.original_error).to be_kind_of(Timeout::Error)
      expect(error.message).to eq('Keen IO Exception: HTTP update_batch failure: execution expired')
    end

    it 'should raise an exception if client has no project_id' do
      expect do
        Keen::Client.new(
          master_key: 'abcde'
        ).update_batch(collection, params)
      end.to raise_error(Keen::ConfigurationError, 'Keen IO Exception: Project ID must be set')
    end

    it 'should raise an exception if client has no master_key' do
      expect do
        Keen::Client.new(
          project_id: '12345'
        ).update_batch(collection, params)
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
        expect(client.update_batch(collection, params)).to eq({})
      end
    end
  end
end

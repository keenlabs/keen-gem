require 'keen/version'
require "json"
require 'uri'

module Keen
  class CachedDatasets
    def initialize(client)
      @client = client
    end

    def list(limit: nil, after_name: nil)
      client.ensure_master_key!

      query_params = clear_nil_attributes(limit: limit, after_name: after_name)
      response = _http_get("", query_params)
      client.process_response(response.code.to_i, response.body)
    end

    def get_definition(dataset_name)
      client.ensure_master_key!
      response = _http_get("/#{dataset_name}")
      client.process_response(response.code.to_i, response.body)
    end

    def get_results(dataset_name, timeframe, index_by, api_key = nil)
      api_key || client.ensure_read_key!
      api_key = api_key || client.read_key
      path = "/#{dataset_name}/results"

      params = {
        timeframe: timeframe.is_a?(Hash) ? MultiJson.encode(timeframe) : timeframe,
        index_by: index_by
      }
      response = _http_get(path, params, api_key)
      client.process_response(response.code.to_i, response.body)
    end

    def create(name, index_by, query, display_name)
      client.ensure_master_key!

      request_body = {
        'query' => clear_nil_attributes(query),
        'index_by' => index_by,
        'display_name' => display_name
      }

      response = Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).put(
        path: "#{datasets_base_url}/#{name}",
        headers: api_headers(client.master_key, "sync"),
        body: MultiJson.encode(request_body)
      )
      client.process_response(response.code.to_i, response.body)
    end

    def delete(dataset_name)
      client.ensure_master_key!

      response = Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).delete(
        path: "#{datasets_base_url}/#{dataset_name}",
        headers: api_headers(client.master_key, "sync")
      )
      client.process_response(response.code.to_i, response.body)
    end

    private

    attr_reader :client

    def _http_get(path = "", query_params = {}, api_key = nil)
      Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).get(
        path: [datasets_base_url + path, URI.encode_www_form(query_params)].compact.join('?'),
        headers: api_headers(api_key || client.master_key, "sync")
      )
    end

    def datasets_base_url
      client.ensure_project_id!
      "/#{client.api_version}/projects/#{client.project_id}/datasets"
    end

    def api_headers(authorization, sync_type)
      user_agent = "keen-gem, v#{Keen::VERSION}, #{sync_type}"
      user_agent += ", #{RUBY_VERSION}, #{RUBY_PLATFORM}, #{RUBY_PATCHLEVEL}"
      if defined?(RUBY_ENGINE)
        user_agent += ", #{RUBY_ENGINE}"
      end
      { "Content-Type" => "application/json",
        "User-Agent" => user_agent,
        "Authorization" => authorization,
        "Keen-Sdk" => "ruby-#{Keen::VERSION}" }
    end

    # Remove any attributes with nil values in a saved query hash. The API will
    # already assume missing attributes are nil
    def clear_nil_attributes(hash)
      hash.reject! do |key, value|
        if value.nil?
          true
        elsif value.is_a? Hash
          value.reject! { |inner_key, inner_value| inner_value.nil? }
        else
          false
        end
      end

      hash
    end
  end
end

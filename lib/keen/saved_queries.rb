require 'keen/version'
require "json"

module Keen
  class SavedQueries
    def initialize(client)
      @client = client
    end

    def all
      client.ensure_master_key!

      response = saved_query_response(client.master_key)
      client.process_response(response.code.to_i, response.body)
    end

    def get(saved_query_name, results = false)
      saved_query_path = "/#{saved_query_name}"
      if results
        client.ensure_read_key!
        saved_query_path += "/result"
        # The results path should use the READ KEY
        api_key = client.read_key
      else
        client.ensure_master_key!
        api_key = client.master_key
      end

      response = saved_query_response(api_key, saved_query_path)
      client.process_response(response.code.to_i, response.body)
    end

    def create(saved_query_name, saved_query_body)
      client.ensure_master_key!

      saved_query_body = clear_nil_attributes(saved_query_body)

      response = Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).put(
        path: "#{saved_query_base_url}/#{saved_query_name}",
        headers: api_headers(client.master_key, "sync"),
        body: MultiJson.encode(saved_query_body)
      )
      client.process_response(response.code.to_i, response.body)
    end
    alias_method :update_full, :create

    def update(saved_query_name, update_body)
      current_query = get saved_query_name
      new_query = current_query.select { |key, val| %w(query_name refresh_rate query).include? key }
      update_full saved_query_name, new_query.merge(update_body)
    end

    def cache(saved_query_name, cache_rate)
      update saved_query_name, refresh_rate: cache_rate
    end

    def uncache(saved_query_name)
      update saved_query_name, refresh_rate: 0
    end

    def delete(saved_query_name)
      client.ensure_master_key!

      response = Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).delete(
        path: "#{saved_query_base_url}/#{saved_query_name}",
        headers: api_headers(client.master_key, "sync")
      )
      client.process_response(response.code.to_i, response.body)
    end

    private

    attr_reader :client

    def saved_query_response(api_key, path = "")
      Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).get(
        path: saved_query_base_url + path,
        headers: api_headers(api_key, "sync")
      )
    end

    def saved_query_base_url
      client.ensure_project_id!
      "/#{client.api_version}/projects/#{client.project_id}/queries/saved"
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
          return true
        elsif value.is_a? Hash
          value.reject! { |inner_key, inner_value| inner_value.nil? }
        end

        false
      end

      hash
    end
  end
end

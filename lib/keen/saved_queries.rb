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

      response = Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).put(
        path: "#{saved_query_base_url}/#{saved_query_name}",
        headers: api_headers(client.master_key, "sync"),
        body: saved_query_body
      )
      client.process_response(response.code.to_i, response.body)
    end
    alias_method :update, :create

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
  end
end

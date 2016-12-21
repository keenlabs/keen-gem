require "json"

module Keen
  class SavedQueries
    def initialize(client)
      @client = client
    end

    def all
      process_response(saved_query_response(client.master_key))
    end

    def get(saved_query_name, results = false)
      saved_query_path = "/#{saved_query_name}"
      api_key = client.master_key
      if results
        saved_query_path += "/result"
        # The results path should use the READ KEY
        api_key = client.read_key
      end
      response = saved_query_response(api_key, saved_query_path)
      response_body = JSON.parse(response.body, symbolize_names: true)
      process_response(response)
    end

    def create(saved_query_name, saved_query_body)
      response = Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout).put(
        path: "#{saved_query_base_url}/#{saved_query_name}",
        headers: api_headers(client.master_key, "sync"),
        body: saved_query_body
      )
      process_response(response)
    end
    alias_method :update, :create

    def delete(saved_query_name)
      response = Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout).delete(
        path: "#{saved_query_base_url}/#{saved_query_name}",
        headers: api_headers(client.master_key, "sync")
      )
      process_response(response)
    end

    private

    attr_reader :client

    def saved_query_response(api_key, path = "")
      Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout).get(
        path: saved_query_base_url + path,
        headers: api_headers(api_key, "sync")
      )
    end

    def saved_query_base_url
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
        "Authorization" => authorization }
    end

    def process_response(response)
      case response.code.to_i
      when 204
        true
      when 200..299
        JSON.parse(response.body, symbolize_names: true)
      when 400
        raise Keen::BadRequestError.new(response.body)
      when 401
        raise Keen::AuthenticationError.new(response.body)
      when 404
        raise Keen::NotFoundError.new(response.body)
      else
        raise Keen::HttpError.new(response.body)
      end
    end
  end
end

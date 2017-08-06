require 'multi_json'

module Keen
  class AccessKeys
    def initialize(client)
      @client = client
    end

    def get(key)
      client.ensure_master_key!
      path = "/#{key}"

      response = access_keys_get(client.master_key, path)
      client.process_response(response.code.to_i, response.body)
    end

    def all()
      client.ensure_master_key!

      response = access_keys_get(client.master_key)
      client.process_response(response.code.to_i, response.body)
    end

    # For information on the format of the key_body, see
    # https://keen.io/docs/api/#access-keys
    def create(key_body)
      client.ensure_master_key!

      path = ""
      response = access_keys_post(client.master_key, path, key_body)
      client.process_response(response.code.to_i, response.body)
    end

    def update(key, key_body)
      client.ensure_master_key!

      path = "/#{key}"
      response = access_keys_post(client.master_key, path, key_body)
      client.process_response(response.code.to_i, response.body)
    end

    def revoke(key)
      client.ensure_master_key!

      path = "/#{key}/revoke"
      response = access_keys_post(client.master_key, path)
      client.process_response(response.code.to_i, response.body)
    end

    def unrevoke(key)
      client.ensure_master_key!

      path = "/#{key}/unrevoke"
      response = access_keys_post(client.master_key, path)
      client.process_response(response.code.to_i, response.body)
    end

    def delete(key)
      client.ensure_master_key!

      response = Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).delete(
        path: access_keys_base_url + "/#{key}",
        headers: client.api_headers(client.master_key, "sync")
      )

      client.process_response(response.code.to_i, response.body)
    end

    def access_keys_base_url
      client.ensure_project_id!
      "/#{client.api_version}/projects/#{client.project_id}/keys"
    end

    private

    attr_reader :client

    def access_keys_get(api_key, path = "")
      Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).get(
        path: access_keys_base_url + path,
        headers: client.api_headers(api_key, "sync")
      )
    end

    def access_keys_post(api_key, path = "", body = "")
      Keen::HTTP::Sync.new(client.api_url, client.proxy_url, client.read_timeout, client.open_timeout).post(
        path: access_keys_base_url + path,
        headers: client.api_headers(api_key, "sync"),
        body: MultiJson.dump(body)
      )
    end
  end
end

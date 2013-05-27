module Keen
  module HTTP
    class Sync
      def initialize(base_url)
        require 'uri'
        require 'net/http'

        uri = URI.parse(base_url)
        @http = Net::HTTP.new(uri.host, uri.port)

        if uri.scheme == "https"
          require 'net/https'
          @http.use_ssl = true;
          @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          @http.verify_depth = 5
          @http.ca_file = File.expand_path("../../../config/cacert.pem", __FILE__)
        end
      end

      def post(options)
        path, headers, body = options.values_at(
          :path, :headers, :body)
        @http.post(path, body, headers)
      end

      def get(options)
        path, headers = options.values_at(
          :path, :headers)
        @http.get(path, headers)
      end

      def delete(options)
        path, headers = options.values_at(
          :path, :headers)
        @http.delete(path, headers)
      end
    end

    class Async
      def initialize(base_url)
        if defined?(EventMachine) && EventMachine.reactor_running?
          require 'em-http-request'
        else
          raise Error, "An EventMachine loop must be running to use publish_async calls"
        end

        @base_url = base_url
      end

      def post(options)
        path, headers, body = options.values_at(
          :path, :headers, :body)
        uri = "#{@base_url}#{path}"
        http_client = EventMachine::HttpRequest.new(uri)
        http_client.post(
          :body => body,
          :head => headers
        )
      end
    end
  end
end

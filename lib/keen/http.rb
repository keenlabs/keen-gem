module Keen
  module HTTP
    class Sync
      def initialize(base_url, options={})
        require 'uri'
        require 'net/https'

        uri = URI.parse(base_url)
        @http = Net::HTTP.new(uri.host, uri.port)
        options.each_pair { |key, value| @http.send "#{key}=", value }
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
    end

    class Async
      def initialize(base_url, options={})
        if defined?(EventMachine) && EventMachine.reactor_running?
          require 'em-http-request'
        else
          raise Error, "An EventMachine loop must be running to use publish_async calls"
        end

        @base_url, @http_options = base_url, options
      end

      def post(options)
        path, headers, body = options.values_at(
          :path, :headers, :body)
        uri = "#{@base_url}#{path}"
        http_client = EventMachine::HttpRequest.new(uri, @http_options)
        http_client.post(
          :body => body,
          :head => headers
        )
      end
    end
  end
end

module Keen
  class Client
    module QueryingMethods

      # Returns the number of resources in the event collection matching the given criteria.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#count-resource
      #
      # @param params [Hash] params is a hash take takes in:
      #   event_collection (required) [String]
      #   filters (optional) [Hash] - The hash will be transformed into JSON string
      #   timeframe (optional)
      #   timezone (optional)
      #   group_by (optional) [Array]
      #
      # @return [Hash] Returns a Hash of the decoded JSON string.
      def count(event_collection, params={})
        query(__method__, event_collection, params)
      end

      # Returns the number of UNIQUE resources in the event collection matching the given criteria.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#count-unique-resource
      #
      # @param params [Hash] params is a hash that takes in:
      #   event_collection (required) [String]
      #   target_property (required) [String] - The property that needs to be counted
      #   filters (optional) [Hash] - The hash will be transformed into JSON string
      #   timeframe (optional)
      #   timezone (optional)
      #   group_by (optional) [Array]
      #
      # @return [Hash] Returns a Hash of the decoded JSON string.
      def count_unique(event_collection, params)
        query(__method__, event_collection, params)
      end

      # Returns the minimum numeric value for the target property in the event collection matching the given criteria. Non-numeric values are ignored.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#minimum-resource
      #
      # @param params [Hash] params is a hash that takes in:
      #   event_collection (required) [String]
      #   target_property (required) [String] - The property to find the minimum value for
      #   filters (optional) [Hash] - The hash will be transformed into JSON string
      #   timeframe (optional)
      #   timezone (optional)
      #   group_by (optional) [Array]
      #
      # @return [Hash] Returns a Hash of the decoded JSON string.
      def minimum(event_collection, params)
        query(__method__, event_collection, params)
      end

      def maximum(event_collection, params)
        query(__method__, event_collection, params)
      end

      def sum(event_collection, params)
        query(__method__, event_collection, params)
      end

      def average(event_collection, params)
        query(__method__, event_collection, params)
      end

      def select_unique(event_collection, params)
        query(__method__, event_collection, params)
      end

      def extraction(event_collection, params={})
        query(__method__, event_collection, params)
      end

      def funnel(params)
        query(__method__, nil, params)
      end

      private

      def query(query_name, event_collection, params)
        ensure_project_id!
        ensure_api_key!

        params[:api_key] = self.api_key

        if event_collection
          params[:event_collection] = event_collection
        end

        query_params = preprocess_params(params)

        begin
          response = Keen::HTTP::Sync.new(
            api_host, api_port, api_sync_http_options).get(
              :path => "#{api_query_resource_path(query_name)}?#{query_params}",
              :headers => api_headers("sync"))
        rescue Exception => http_error
          raise HttpError.new("Couldn't perform #{query_name} on Keen IO: #{http_error.message}", http_error)
        end

        response_body = response.body.chomp
        process_response(response.code, response_body)["result"]
      end

      def preprocess_params(params)
        if params.key?(:filters)
          params[:filters] = MultiJson.encode(params[:filters])
        end

        if params.key?(:steps)
          params[:steps] = MultiJson.encode(params[:steps])
        end

        if params.key?(:timeframe) && params[:timeframe].is_a?(Hash)
          params[:timeframe] = MultiJson.encode(params[:timeframe])
        end

        query_params = ""
        params.each do |param, value|
          query_params << "#{param}=#{URI.escape(value)}&"
        end

        query_params.chop!
        query_params
      end

      def api_query_resource_path(analysis_type)
        "/#{self.api_version}/projects/#{self.project_id}/queries/#{analysis_type}"
      end
    end
  end
end


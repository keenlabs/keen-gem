module Keen
  class Client
    module QueryingMethods

      # Runs a count query.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#count-resource
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   group_by (optional)
      #   timeframe (optional)
      #   interval (optional)
      #   filters (optional) [Array]
      #   timezone (optional)
      def count(event_collection, params={})
        query(__method__, event_collection, params)
      end

      # Runs a count unique query.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#count-unique-resource
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   target_property (required)
      #   group_by (optional)
      #   timeframe (optional)
      #   interval (optional)
      #   filters (optional) [Array]
      #   timezone (optional)
      def count_unique(event_collection, params)
        query(__method__, event_collection, params)
      end

      # Runs a minimum query.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#minimum-resource
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   target_property (required)
      #   group_by (optional)
      #   timeframe (optional)
      #   interval (optional)
      #   filters (optional) [Array]
      #   timezone (optional)
      def minimum(event_collection, params)
        query(__method__, event_collection, params)
      end

      # Runs a maximum query.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#maximum-resource
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   target_property (required)
      #   group_by (optional)
      #   timeframe (optional)
      #   interval (optional)
      #   filters (optional) [Array]
      #   timezone (optional)
      def maximum(event_collection, params)
        query(__method__, event_collection, params)
      end

      # Runs a sum query.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#sum-resource
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   target_property (required)
      #   group_by (optional)
      #   timeframe (optional)
      #   interval (optional)
      #   filters (optional) [Array]
      #   timezone (optional)
      def sum(event_collection, params)
        query(__method__, event_collection, params)
      end

      # Runs a average query.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#average-resource
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   target_property (required)
      #   group_by (optional)
      #   timeframe (optional)
      #   interval (optional)
      #   filters (optional) [Array]
      #   timezone (optional)
      def average(event_collection, params)
        query(__method__, event_collection, params)
      end

      # Runs a select_unique query.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#select-unique-resource
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   target_property (required)
      #   group_by (optional)
      #   timeframe (optional)
      #   interval (optional)
      #   filters (optional) [Array]
      #   timezone (optional)
      def select_unique(event_collection, params)
        query(__method__, event_collection, params)
      end

      # Runs a extraction query.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#extraction-resource
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   target_property (required)
      #   group_by (optional)
      #   timeframe (optional)
      #   interval (optional)
      #   filters (optional) [Array]
      #   timezone (optional)
      #   latest (optional)
      def extraction(event_collection, params={})
        query(__method__, event_collection, params)
      end

      # Runs a funnel query.
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#funnel-resource
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   steps (required)
      def funnel(params)
        query(__method__, nil, params)
      end

      # Runs a multi-analysis query
      # See detailed documentation here:
      # https://keen.io/docs/data-analysis/multi-analysis/
      #
      # NOTE: why isn't multi-analysis listed in the
      #       API Technical Reference?
      #
      # @param event_collection
      # @param params [Hash]
      #   analyses [Hash] (required)
      #     label (required)
      #     analysis_type (required)
      #     target_property (optional)
      def multi_analysis(event_collection, params)
        query(__method__, event_collection, params)
      end

      private

      def query(query_name, event_collection, params)
        ensure_project_id!
        ensure_read_key!

        if event_collection
          params[:event_collection] = event_collection
        end

        query_params = preprocess_params(params)

        begin
          response = Keen::HTTP::Sync.new(
            api_host, api_port, api_sync_http_options).get(
              :path => "#{api_query_resource_path(query_name)}?#{query_params}",
              :headers => api_headers(self.read_key, "sync"))
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

        if params.key?(:analyses)
          params[:analyses] = MultiJson.encode(params[:analyses])
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

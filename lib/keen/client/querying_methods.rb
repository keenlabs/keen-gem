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
        Keen::Query.new(query_name, event_collection, params, config).execute
      end

    end
  end
end

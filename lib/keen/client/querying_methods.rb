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
      def count(params)
        keen_query(__method__, params)
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
      def count_unique(params)
        keen_query(__method__, params)
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
      def minimum(params)
        keen_query(__method__, params)
      end

      def maximum(params)
        keen_query(__method__, params)
      end

      def sum(params)
        keen_query(__method__, params)
      end

      def average(params)
        keen_query(__method__, params)
      end

      def select_unique(params)
        keen_query(__method__, params)
      end

      def funnel(params)
        keen_query(__method__, params)
      end

      # The underlying private method that all querying methods call to perform the query.
      #
      # @param query_name [String] The name of the query to perform, this will be passed in by the public query method itself.
      # @param params [Hash] The parameters for the particular given query.
      #
      # @return [Hash] Returns a Hash of the decoded JSON string.
      def keen_query(query_name, params)
        ensure_project_id!
        ensure_api_key!

        params[:api_key] = self.api_key
        query_params = preprocess_params(params)

        begin
          response = Keen::HTTP::Sync.new(
            api_host, api_port, api_sync_http_options).get(
              :path => "#{api_query_resource_path(query_name)}#{query_params}",
              :headers => api_headers_with_auth("sync"))
        rescue Exception => http_error
          raise HttpError.new("Couldn't perform #{query_name} on Keen IO: #{http_error.message}", http_error)
        end
        response_body = response.body.chomp
        processed_response = process_response(response.code, response_body)

        return processed_response
      end

      # This transform some parameters into json as required by Keen
      # @param params [Hash] all the parameters
      def preprocess_params(params)
        # JSON encode filter hash if it exists
        if params.key? :filters
          params[:filters] = MultiJson.encode(params[:filters])
        end

        if params.key? :timeframe and not params[:timeframe].class == String
          params[:timeframe] = MultiJson.encode(params[:timeframe])
        end

        if params.key? :group_by and not params[:group_by].class == String
          params[:group_by] = MultiJson.encode(params[:group_by])
        end
        query_params = "?"
        if URI.respond_to?(:encode_www_form)
          query_params << URI.encode_www_form(params).gsub('%5B%5D','')
        else
          params.each do |param, value|
            query_params << param.to_s << '=' << value.to_s << '&'
          end
          query_params.chop! # Get rid of the extra '&' at the end
        end
        return query_params
      end

      def api_query_resource_path(analysis_type)
        "/#{self.api_version}/projects/#{self.project_id}/queries/#{analysis_type}"
      end
    end
  end
end


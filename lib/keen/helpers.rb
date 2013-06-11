module Keen
  module Helpers

    private

    def process_response(status_code, response_body)
      case status_code.to_i
        when 200..201
          begin
            return MultiJson.decode(response_body)
          rescue
            Keen.logger.warn("Invalid JSON for response code #{status_code}: #{response_body}")
            return {}
          end
        when 204
          return true
        when 400
          raise BadRequestError.new(response_body)
        when 401
          raise AuthenticationError.new(response_body)
        when 404
          raise NotFoundError.new(response_body)
        else
          raise HttpError.new(response_body)
      end
    end

    def ensure_project_id!
      raise ConfigurationError, "Project ID must be set" unless config.project_id
    end

    def ensure_write_key!
      raise ConfigurationError, "Write Key must be set for sending events" unless config.write_key
    end

    def ensure_master_key!
      raise ConfigurationError, "Master Key must be set for delete event collections" unless config.master_key
    end

    def ensure_read_key!
      raise ConfigurationError, "Read Key must be set for queries" unless config.read_key
    end

    def api_event_collection_resource_path(event_collection)
      "/#{api_version}/projects/#{project_id}/events/#{CGI.escape(event_collection.to_s)}"
    end

    def api_query_resource_path(analysis_type)
      "#{common_api}/queries/#{analysis_type}"
    end

    def api_saved_queries_resource_path(name)
      "#{common_api}/saved_queries/#{name}"
    end

    def common_api
      "/#{config.api_version}/projects/#{config.project_id}"
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

    def config
      @config ? @config : Keen.config
    end

  end
end

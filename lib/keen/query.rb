require 'keen/helpers'
require 'keen/saved_query'
module Keen
  class Query
    include Keen::Helpers
    attr_reader :params, :analysis_type

    def initialize(analysis_type=nil, event_collection=nil, params={}, config=Keen.config)
      @config = config

      if event_collection
        params[:event_collection] = event_collection.to_s
      end

      @params = params
      @analysis_type = analysis_type

    end

    # return a saved query from this query
    def saved_query(name)
      saved = Keen::SavedQuery.new(name, @config)
      saved.put(@analysis_type, nil, @params) ? saved : false
    end

    # Execute a query and return the result
    def execute
      ensure_project_id!
      ensure_read_key!

      param_query = preprocess_params(@params)

      begin
        response = Keen::HTTP::Sync.new(@config.api_url).get(
            :path => "#{api_query_resource_path(@analysis_type)}?#{param_query}",
            :headers => @config.api_headers(@config.read_key, "sync"))
      rescue Exception => http_error
        raise HttpError.new("Couldn't perform #{@analysis_type} on Keen IO: #{http_error.message}", http_error)
      end

      response_body = response.body.chomp
      process_response(response.code, response_body)["result"]

    end

  end
end

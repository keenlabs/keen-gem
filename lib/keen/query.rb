require 'keen/helpers'

module Keen
  class Query
    include Keen::Helpers
    attr_reader :params, :query_name

    def initialize(query_name=nil, event_collection=nil, params={}, config=Keen.config)
      @config = config

      ensure_project_id!

      if event_collection
        params[:event_collection] = event_collection.to_s
      end

      @params = params
      @query_name = query_name

    end

    # Save a query in Keen
    def save(name)
      ensure_master_key!

      @params[:analysis_type] = @query_name
      @params[:query_name] = name

      body = @params.to_json

      begin
        response = Keen::HTTP::Sync.new(@config.api_url).put(
            :path => api_saved_queries_resource_path(name),
            :headers => @config.api_headers(@config.master_key, 'sync'),
            :body => body)
      rescue Exception => http_error
        raise HttpError.new("Couldn't save #{@query_name} on Keen IO: #{http_error.message}", http_error)
      end

      response.code == "201" ? true : false
    end

    def self.execute(name)
      self.new.execute_saved(name)
    end

    # Return the result of a saved query
    def execute_saved(name)
      ensure_read_key!

      begin
        response = Keen::HTTP::Sync.new(@config.api_url).get(
            :path => "#{api_saved_queries_resource_path(name)}/result",
            :headers => @config.api_headers(@config.read_key, "sync"))
      rescue Exception => http_error
        raise HttpError.new("Couldn't perform #{name} on Keen IO: #{http_error.message}", http_error)
      end

      response_body = response.body.chomp
      process_response(response.code, response_body)["result"]
    end

    def self.delete(name)
      self.new.delete(name)
    end

    # Delete a saved query
    def delete(name)
      ensure_master_key!

      begin
        response = Keen::HTTP::Sync.new(@config.api_url).delete(
            :path => api_saved_queries_resource_path(name),
            :headers => @config.api_headers(@config.master_key, 'sync'))
      rescue Exception => http_error
        raise HttpError.new("Couldn't delete #{name} on Keen IO: #{http_error.message}", http_error)
      end

      response.code == "204" ? true : false

    end

    # Execute a query and return the result
    def execute
      ensure_read_key!

      param_query = preprocess_params(@params)

      begin
        response = Keen::HTTP::Sync.new(@config.api_url).get(
            :path => "#{api_query_resource_path(@query_name)}?#{param_query}",
            :headers => @config.api_headers(@config.read_key, "sync"))
      rescue Exception => http_error
        raise HttpError.new("Couldn't perform #{@query_name} on Keen IO: #{http_error.message}", http_error)
      end

      response_body = response.body.chomp
      process_response(response.code, response_body)["result"]

    end

  end
end

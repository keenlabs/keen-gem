require 'keen/helpers'

module Keen
  class SavedQuery
    include Keen::Helpers
    attr_reader :params, :analysis_type, :name

    def initialize(name, config=Keen.config)
      @config = config
      @name = name
    end

    # Save a query in Keen
    def put(analysis_type=nil, event_collection=nil, params={})
      ensure_project_id!
      ensure_master_key!

      @params = params
      @analysis_type = analysis_type

      if event_collection
        params[:event_collection] = event_collection.to_s
      end

      @params[:analysis_type] = @analysis_type
      @params[:query_name] = name

      body = @params.to_json

      begin
        response = Keen::HTTP::Sync.new(@config.api_url).put(
            :path => api_saved_queries_resource_path(name),
            :headers => @config.api_headers(@config.master_key, 'sync'),
            :body => body)
      rescue Exception => http_error
        raise HttpError.new("Couldn't save #{@name} on Keen IO: #{http_error.message}", http_error)
      end

      response_body = response.body.chomp
      process_response(response.code, response_body)
    end

    def self.result(name)
      self.new(name).result
    end

    # Return the result of a saved query
    def result
      ensure_project_id!
      ensure_read_key!

      begin
        response = Keen::HTTP::Sync.new(@config.api_url).get(
            :path => "#{api_saved_queries_resource_path(@name)}/result",
            :headers => @config.api_headers(@config.read_key, "sync"))
      rescue Exception => http_error
        raise HttpError.new("Couldn't perform #{@name} on Keen IO: #{http_error.message}", http_error)
      end

      response_body = response.body.chomp
      process_response(response.code, response_body)["result"]
    end

    def self.delete(name)
      self.new(name).delete
    end

    # Delete a saved query
    def delete
      ensure_project_id!
      ensure_master_key!

      begin
        response = Keen::HTTP::Sync.new(@config.api_url).delete(
            :path => api_saved_queries_resource_path(@name),
            :headers => @config.api_headers(@config.master_key, 'sync'))
      rescue Exception => http_error
        raise HttpError.new("Couldn't delete #{@name} on Keen IO: #{http_error.message}", http_error)
      end

      response_body = response.body.chomp
      process_response(response.code, response_body)
    end


  end
end

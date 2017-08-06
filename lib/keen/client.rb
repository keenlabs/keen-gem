require 'keen/http'
require 'keen/version'
require 'keen/client/publishing_methods'
require 'keen/client/querying_methods'
require 'keen/client/maintenance_methods'
require 'keen/version'
require 'openssl'
require 'multi_json'
require 'base64'
require 'cgi'
require 'addressable/uri'

module Keen
  class Client
    include Keen::Client::PublishingMethods
    include Keen::Client::QueryingMethods
    include Keen::Client::MaintenanceMethods

    attr_accessor :project_id, :write_key, :read_key, :master_key, :api_url, :proxy_url, :proxy_type, :read_timeout, :log_queries, :open_timeout

    CONFIG = {
      :api_url => "https://api.keen.io",
      :api_version => "3.0",
      :api_headers => lambda { |authorization, sync_or_async|
        user_agent = "keen-gem, v#{Keen::VERSION}, #{sync_or_async}"
        user_agent += ", #{RUBY_VERSION}, #{RUBY_PLATFORM}, #{RUBY_PATCHLEVEL}"
        if defined?(RUBY_ENGINE)
          user_agent += ", #{RUBY_ENGINE}"
        end
        { "Content-Type" => "application/json",
          "User-Agent" => user_agent,
          "Authorization" => authorization,
          "Keen-Sdk" => "ruby-#{Keen::VERSION}" }
      }
    }

    def initialize(*args)
      options = args[0]
      unless options.is_a?(Hash)
        # deprecated, pass a hash of options instead
        options = {
          :project_id => args[0],
          :write_key => args[1],
          :read_key => args[2],
        }.merge(args[3] || {})
      end

      self.project_id, self.write_key, self.read_key, self.master_key = options.values_at(
        :project_id, :write_key, :read_key, :master_key)

      self.api_url = options[:api_url] || CONFIG[:api_url]

      self.proxy_url, self.proxy_type = options.values_at(:proxy_url, :proxy_type)

      self.read_timeout = options[:read_timeout].to_f unless options[:read_timeout].nil?

      self.open_timeout = options[:open_timeout].to_f unless options[:open_timeout].nil?
    end

    def saved_queries
      @saved_queries ||= SavedQueries.new(self)
    end

    def access_keys
      @access_keys ||= AccessKeys.new(self)
    end

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
      raise ConfigurationError, "Project ID must be set" unless self.project_id
    end

    def ensure_write_key!
      raise ConfigurationError, "Write Key must be set for this operation" unless self.write_key
    end

    def ensure_master_key!
      raise ConfigurationError, "Master Key must be set for this operation" unless self.master_key
    end

    def ensure_read_key!
      raise ConfigurationError, "Read Key must be set for this operation" unless self.read_key
    end

    private

    def api_event_collection_resource_path(event_collection)
      encoded_collection_name = Addressable::URI.encode_component(event_collection.to_s)
      encoded_collection_name.gsub! '/', '%2F'
      "/#{api_version}/projects/#{project_id}/events/#{encoded_collection_name}"
    end

    def preprocess_params(params)
      params = params.delete_if {|key, val| val.nil?}

      preprocess_encodables(params)
      preprocess_timeframe(params)
      preprocess_max_age(params)
      preprocess_group_by(params)
      preprocess_percentile(params)
      preprocess_property_names(params)

      params.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join('&')
    end

    def preprocess_encodables(params)
      [:filters, :steps, :analyses].each do |key|
        if params.key?(key)
          params[key] = MultiJson.encode(params[key])
        end
      end
    end

    def preprocess_timeframe(params)
      timeframe = params[:timeframe]
      if timeframe.is_a?(Hash)
        params[:timeframe] = MultiJson.encode(timeframe)
      end
    end

    def preprocess_group_by(params)
      group_by = params[:group_by]
      if group_by.is_a?(Array)
        params[:group_by] = MultiJson.encode(group_by)
      end
    end

    def preprocess_max_age(params)
      max_age = params[:max_age]
      if max_age.is_a? Numeric
        params[:max_age] = params[:max_age].to_s
      else
        params.delete(:max_age)
      end
    end

    def preprocess_percentile(params)
      if params.key?(:percentile)
        params[:percentile] = params[:percentile].to_s
      end
    end

    def preprocess_property_names(params)
      property_names = params[:property_names]
      if property_names.is_a?(Array)
        params[:property_names] = MultiJson.encode(property_names)
      end
    end

    def method_missing(_method, *args, &block)
      if config = CONFIG[_method.to_sym]
        if config.is_a?(Proc)
          config.call(*args)
        else
          config
        end
      else
        super
      end
    end
  end
end

require 'keen/http'
require 'keen/version'
require 'keen/client/publishing_methods'
require 'keen/client/querying_methods'

require 'openssl'
require 'multi_json'
require 'base64'
require 'uri'

module Keen
  class Client
    include Keen::Client::PublishingMethods
    include Keen::Client::QueryingMethods

    attr_accessor :project_id, :write_key, :read_key

    CONFIG = {
      :api_host => "api.keen.io",
      :api_port => 443,
      :api_version => "3.0",
      :api_sync_http_options => {
        :use_ssl => true,
        :verify_mode => OpenSSL::SSL::VERIFY_PEER,
        :verify_depth => 5,
        :ca_file => File.expand_path("../../../config/cacert.pem", __FILE__) },
      :api_async_http_options => {},
      :api_headers => lambda { |sync_or_async|
        user_agent = "keen-gem, v#{Keen::VERSION}, #{sync_or_async}"
        user_agent += ", #{RUBY_VERSION}, #{RUBY_PLATFORM}, #{RUBY_PATCHLEVEL}"
        if defined?(RUBY_ENGINE)
          user_agent += ", #{RUBY_ENGINE}"
        end
        { "Content-Type" => "application/json",
          "User-Agent" => user_agent }
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

      @project_id, @write_key, @read_key = options.values_at(
        :project_id, :write_key, :read_key)
    end

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
      raise ConfigurationError, "Write Key must be set for sending events" unless self.write_key
    end

    def ensure_read_key!
      raise ConfigurationError, "Read Key must be set for queries" unless self.read_key
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

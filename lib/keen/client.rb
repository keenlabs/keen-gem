require 'keen/http'

module Keen
  class Client
    attr_accessor :project_id, :api_key

    CONFIG = {
      :api_host => "api.keen.io",
      :api_port => 443,
      :api_sync_http_options => {
        :use_ssl => true,
        :verify_mode => OpenSSL::SSL::VERIFY_PEER,
        :verify_depth => 5,
        :ca_file => File.expand_path("../../../config/cacert.pem", __FILE__) },
      :api_async_http_options => {},
      :api_headers => {
        "Content-Type" => "application/json",
        "User-Agent" => "keen-gem v#{Keen::VERSION}"
      }
    }

    def initialize(*args)
      options = args[0]
      unless options.is_a?(Hash)
        # deprecated, pass a hash of options instead
        options = {
          :project_id => args[0],
          :api_key => args[1],
        }.merge(args[2] || {})
      end

      @project_id, @api_key = options.values_at(
        :project_id, :api_key)
    end

    def publish(event_name, properties)
      check_configuration!
      begin
        response = Keen::HTTP::Sync.new(
          api_host, api_port, api_sync_http_options).post(
            :path => api_path(event_name),
            :headers => api_headers_with_auth,
            :body => MultiJson.encode(properties))
      rescue Exception => http_error
        raise HttpError.new("Couldn't connect to Keen IO: #{http_error.message}", http_error)
      end
      process_response(response.code, response.body.chomp)
    end

    def publish_async(event_name, properties)
      check_configuration!

      deferrable = EventMachine::DefaultDeferrable.new

      http_client = Keen::HTTP::Async.new(api_host, api_port, api_async_http_options)
      http = http_client.post({
        :path => api_path(event_name),
        :headers => api_headers_with_auth,
        :body => MultiJson.encode(properties)
      })

      if defined?(EM::Synchrony)
        if http.error
          Keen.logger.warn("Couldn't connect to Keen IO: #{http.error}")
          raise HttpError.new("Couldn't connect to Keen IO: #{http.error}")
        else
          process_response(http.response_header.status, http.response.chomp)
        end
      else
        http.callback {
          begin
            response = process_response(http.response_header.status, http.response.chomp)
            deferrable.succeed(response)
          rescue Exception => e
            deferrable.fail(e)
          end
        }
        http.errback {
          Keen.logger.warn("Couldn't connect to Keen IO: #{http.error}")
          deferrable.fail(Error.new("Couldn't connect to Keen IO: #{http.error}"))
        }
        deferrable
      end
    end

    # deprecated
    def add_event(event_name, properties, options={})
      self.publish(event_name, properties, options)
    end

    private

    def process_response(status_code, response_body)
      body = MultiJson.decode(response_body)
      case status_code.to_i
      when 200..201
        return body
      when 400
        raise BadRequestError.new(body)
      when 401
        raise AuthenticationError.new(body)
      when 404
        raise NotFoundError.new(body)
      else
        raise HttpError.new(body)
      end
    end

    def api_path(collection)
      "/3.0/projects/#{project_id}/events/#{collection}"
    end

    def api_headers_with_auth
      api_headers.merge("Authorization" => api_key)
    end

    def check_configuration!
      raise ConfigurationError, "Project ID must be set" unless project_id
      raise ConfigurationError, "API Key must be set" unless api_key
    end

    def method_missing(_method, *args, &block)
      CONFIG[_method.to_sym] || super
    end
  end
end

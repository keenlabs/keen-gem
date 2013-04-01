require 'keen/http'
require 'keen/version'
require 'openssl'
require 'multi_json'
require 'base64'
require 'uri'

module Keen
  class Client
    attr_accessor :project_id, :api_key

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

    def beacon_url(event_collection, properties)
      json = MultiJson.encode(properties)
      data = [json].pack("m0").tr("+/", "-_").gsub("\n", "")
      "https://#{api_host}#{api_path(event_collection)}?data=#{data}"
    end

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

    def publish(event_collection, properties)
      check_configuration!
      check_event_data!(event_collection, properties)

      begin
        response = Keen::HTTP::Sync.new(
          api_host, api_port, api_sync_http_options).post(
            :path => api_path(event_collection),
            :headers => api_headers_with_auth("sync"),
            :body => MultiJson.encode(properties))
      rescue Exception => http_error
        raise HttpError.new("Couldn't connect to Keen IO: #{http_error.message}", http_error)
      end
      process_response(response.code, response.body.chomp)
    end

    def publish_async(event_collection, properties)
      check_configuration!
      check_event_data!(event_collection, properties)

      deferrable = EventMachine::DefaultDeferrable.new

      http_client = Keen::HTTP::Async.new(api_host, api_port, api_async_http_options)
      http = http_client.post({
        :path => api_path(event_collection),
        :headers => api_headers_with_auth("async"),
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
    # @param cache [Object] (Optional) See description on #keen_query.
    # @param from_cache [Boolean] (Optional) See description on #keen_query. 
    #   from_cache defaults to true. When false, it will still save results to cache.
    # @param cache_expiration [Integer] (Optional) See descripton on #keen_query.
    #
    # @return [Hash] Returns a Hash of the decoded JSON string.
    def count(params, cache=nil, from_cache=true, cache_expiration=nil)
      keen_query(__method__, params, cache, from_cache)
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
    # @param cache [Object] (Optional) See description on #keen_query.
    # @param from_cache [Boolean] (Optional) See description on #keen_query. 
    #   from_cache defaults to true. When false, it will still save results to cache.
    # @param cache_expiration [Integer] (Optional) See descripton on #keen_query.
    #
    # @return [Hash] Returns a Hash of the decoded JSON string.
    def count_unique(params, cache=nil, from_cache=true, cache_expiration=nil)
      keen_query(__method__, params, cache, from_cache)
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
    # @param cache [Object] (Optional) See description on #keen_query.
    # @param from_cache [Boolean] (Optional) See description on #keen_query. 
    #   from_cache defaults to true. When false, it will still save results to cache.
    # @param cache_expiration [Integer] (Optional) See descripton on #keen_query.
    #
    # @return [Hash] Returns a Hash of the decoded JSON string.
    def minimum(params, cache=nil, from_cache=true, cache_expiration=nil)
      keen_query(__method__, params, cache, from_cache)
    end

    def maximum(params, cache=nil, from_cache=true, cache_expiration=nil)
      keen_query(__method__, params, cache, from_cache)
    end

    def sum(params, cache=nil, from_cache=true, cache_expiration=nil)
      keen_query(__method__, params, cache, from_cache)
    end

    def average(params, cache=nil, from_cache=true, cache_expiration=nil)
      keen_query(__method__, params, cache, from_cache)
    end

    def select_unique(params, cache=nil, from_cache=true, cache_expiration=nil)
      keen_query(__method__, params, cache, from_cache)
    end

    def funnel(params, cache=nil, from_cache=true, cache_expiration=nil)
      keen_query(__method__, params, cache, from_cache)
    end

    # deprecated
    def add_event(event_collection, properties, options={})
      self.publish(event_collection, properties, options)
    end

    private

    # @param query_name [String] The name of the query to perform, this will be passed in by the public query method itself.
    # @param cache [Object] (Optional) The caching backend handle. It must support the methods 'set' and 'get'.
    # @param from_cache [Boolean] (Optional) Whether or not you want to return the value from cache.
    #   from_cache defaults to true. When false, it will still save results to cache.
    # @param cache_expiration [Integer] (Optional) The amount of time in seconds to cache this data. To use this parameter, your cache handler must support the #expire method. Defaults to nil (therefore you'll have to manually clear the cache)
    #
    # @return [Hash] Returns a Hash of the decoded JSON string.
    def keen_query(query_name, params, cache=nil, from_cache=true, cache_expiration=nil)
      check_configuration!
      if cache && from_cache
        key = "keen_api_cache::" + query_name.to_s + params.sort_by{|k,v|k}.flatten.join
        cached_data = cache.get(key)
        unless cached_data.nil && cached_data.empty
          return MultiJson.decode(cached_data)
        end
      else
        params[:api_key] = @api_key
        query_params = preprocess_params(params)

        begin
          response = Keen::HTTP::Sync.new(
            api_host, api_port, api_sync_http_options).get(
              :path => "#{api_path}#{query_name}#{query_params}",
              :headers => api_headers_with_auth("sync"))
        rescue Exception => http_error
          raise HttpError.new("Couldn't perform #{query_name} on Keen IO: #{http_error.message}", http_error)
        end
        response_body = response.body.chomp
        processed_response = process_response(response.code, response_body)

        if cache
          key = "keen_api_cache::" + query_name.to_s + params.sort_by{|k,v|k}.flatten.join
          cache.set(key, response_body)
          if cache.responds_to?("expire") and cache_expiration
            cache.expire(cache_expiration)
          end
        end
        return processed_response
      end
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

    def api_path(event_collection = nil)
      if event_collection
        "/#{api_version}/projects/#{project_id}/events/#{URI.escape(event_collection)}"
      else
        "/#{api_version}/projects/#{project_id}/queries/"
      end
    end

    def api_headers_with_auth(sync_or_async)
      api_headers(sync_or_async)
    end

    def check_configuration!
      raise ConfigurationError, "Project ID must be set" unless project_id
    end

    def check_event_data!(event_collection, properties)
      raise ArgumentError, "Event collection can not be nil" unless event_collection
      raise ArgumentError, "Event properties can not be nil" unless properties
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

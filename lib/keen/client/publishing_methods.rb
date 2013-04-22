module Keen
  class Client
    module PublishingMethods

      # @deprecated
      #
      # Publishes a synchronous event
      # @param event_collection
      # @param [Hash] event properties
      #
      # @return the JSON response from the API
      def add_event(event_collection, properties, options={})
        self.publish(event_collection, properties, options)
      end

      # Publishes a synchronous event
      # See detailed documentation here
      # https://keen.io/docs/api/reference/#event-collection-resource
      #
      # @param event_collection
      # @param [Hash] event properties
      #
      # @return the JSON response from the API
      def publish(event_collection, properties)
        ensure_project_id!
        ensure_write_key!
        check_event_data!(event_collection, properties)

        headers = api_headers("sync")
        headers.merge({:Authorization => self.write_key})

        begin
          response = Keen::HTTP::Sync.new(
            api_host, api_port, api_sync_http_options).post(
              :path => api_event_resource_path(event_collection),
              :headers => headers,
              :body => MultiJson.encode(properties))
        rescue Exception => http_error
          raise HttpError.new("HTTP publish failure: #{http_error.message}", http_error)
        end
        process_response(response.code, response.body.chomp)
      end

      # Publishes an asynchronous event
      # See detailed documentation here
      # https://keen.io/docs/api/reference/#event-collection-resource
      #
      # @param event_collection
      # @param [Hash] event properties
      #
      # @return a deferrable to apply callbacks to
      def publish_async(event_collection, properties)
        ensure_project_id!
        ensure_write_key!
        check_event_data!(event_collection, properties)

        headers = api_headers("async")
        headers.merge({:Authorization => self.write_key})

        deferrable = EventMachine::DefaultDeferrable.new

        http_client = Keen::HTTP::Async.new(api_host, api_port, api_async_http_options)
        http = http_client.post({
          :path => api_event_resource_path(event_collection),
          :headers => headers,
          :body => MultiJson.encode(properties)
        })

        if defined?(EM::Synchrony)
          if http.error
            error = HttpError.new("HTTP em-synchrony publish_async error: #{http.error}")
            Keen.logger.error(error)
            raise error
          else
            process_response(http.response_header.status, http.response.chomp)
          end
        else
          http.callback {
            begin
              response = process_response(http.response_header.status, http.response.chomp)
            rescue Exception => e
              Keen.logger.error(e)
              deferrable.fail(e)
            end
            deferrable.succeed(response) if response
          }
          http.errback {
            error = Error.new("HTTP publish_async failure: #{http.error}")
            Keen.logger.error(error)
            deferrable.fail(error)
          }
          deferrable
        end
      end

      # Returns an encoded URL that will record an event. Useful in email situations.
      # See detailed documentation here
      # https://keen.io/docs/api/reference/#event-collection-resource
      #
      # @param event_collection
      # @param [Hash] event properties
      #
      # @return a URL that will track an event when hit
      def beacon_url(event_collection, properties)
        json = MultiJson.encode(properties)
        data = [json].pack("m0").tr("+/", "-_").gsub("\n", "")
        "https://#{api_host}#{api_event_resource_path(event_collection)}?api_key=#{self.write_key}&data=#{data}"
      end

      private

      def api_event_resource_path(event_collection)
        "/#{api_version}/projects/#{project_id}/events/#{URI.escape(event_collection)}"
      end

      def check_event_data!(event_collection, properties)
        raise ArgumentError, "Event collection can not be nil" unless event_collection
        raise ArgumentError, "Event properties can not be nil" unless properties
      end
    end
  end
end

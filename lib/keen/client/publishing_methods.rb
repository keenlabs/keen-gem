module Keen
  class Client
    module PublishingMethods

      # deprecated
      def add_event(event_collection, properties, options={})
        self.publish(event_collection, properties, options)
      end

      def publish(event_collection, properties)
        ensure_project_id!
        check_event_data!(event_collection, properties)

        begin
          response = Keen::HTTP::Sync.new(
            api_host, api_port, api_sync_http_options).post(
              :path => api_event_resource_path(event_collection),
              :headers => api_headers_with_auth("sync"),
              :body => MultiJson.encode(properties))
        rescue Exception => http_error
          raise HttpError.new("Couldn't connect to Keen IO: #{http_error.message}", http_error)
        end
        process_response(response.code, response.body.chomp)
      end

      def publish_async(event_collection, properties)
        ensure_project_id!
        check_event_data!(event_collection, properties)

        deferrable = EventMachine::DefaultDeferrable.new

        http_client = Keen::HTTP::Async.new(api_host, api_port, api_async_http_options)
        http = http_client.post({
          :path => api_event_resource_path(event_collection),
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

      def beacon_url(event_collection, properties)
        json = MultiJson.encode(properties)
        data = [json].pack("m0").tr("+/", "-_").gsub("\n", "")
        "https://#{api_host}#{api_event_resource_path(event_collection)}?data=#{data}"
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

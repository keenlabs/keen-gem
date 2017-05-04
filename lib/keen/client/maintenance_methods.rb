module Keen
  class Client
    module MaintenanceMethods

      # Runs a delete query.
      # See detailed documentation here:
      # https://keen.io/docs/maintenance/#deleting-event-collections
      #
      # @param event_collection
      # @param params [Hash] (optional)
      #   filters (optional) [Array]
      def delete(event_collection, params={})
        ensure_project_id!
        ensure_master_key!

        query_params = preprocess_params(params) if params != {}

        begin
          response = http_sync.delete(
              :path => [api_event_collection_resource_path(event_collection), query_params].compact.join('?'),
              :headers => api_headers(self.master_key, "sync"))
        rescue Exception => http_error
          raise HttpError.new("Couldn't perform delete of #{event_collection} on Keen IO: #{http_error.message}", http_error)
        end

        response_body = response.body ? response.body.chomp : ''
        process_response(response.code, response_body)
      end

      # Return list of collections for the configured project
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#event-resource
      def event_collections
        ensure_project_id!
        ensure_master_key!

        begin
          response = http_sync.get(
              :path => "/#{api_version}/projects/#{project_id}/events",
              :headers => api_headers(self.master_key, "sync"))
        rescue Exception => http_error
          raise HttpError.new("Couldn't perform events on Keen IO: #{http_error.message}", http_error)
        end

        response_body = response.body ? response.body.chomp : ''
        process_response(response.code, response_body)
      end

      # Return details for the current project
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#project-resource
      def project_info
        ensure_project_id!
        ensure_master_key!

        begin
          response = http_sync.get(
              :path => "/#{api_version}/projects/#{project_id}",
              :headers => api_headers(self.master_key, "sync"))
        rescue Exception => http_error
          raise HttpError.new("Couldn't perform project info on Keen IO: #{http_error.message}", http_error)
        end

        response_body = response.body ? response.body.chomp : ''
        process_response(response.code, response_body)
      end

      # Return the named collection for the configured project
      # See detailed documentation here:
      # https://keen.io/docs/api/reference/#event-collection-resource
      def event_collection(event_collection)
        ensure_project_id!
        ensure_master_key!

        begin
          response = http_sync.get(
              :path => "/#{api_version}/projects/#{project_id}/events/#{event_collection}",
              :headers => api_headers(self.master_key, "sync"))
        rescue Exception => http_error
          raise HttpError.new("Couldn't perform events on Keen IO: #{http_error.message}", http_error)
        end

        response_body = response.body ? response.body.chomp : ''
        process_response(response.code, response_body)
      end

      private

      def http_sync
        @http_sync ||= Keen::HTTP::Sync.new(self.api_url, self.proxy_url, self.read_timeout, self.open_timeout)
      end

    end
  end
end

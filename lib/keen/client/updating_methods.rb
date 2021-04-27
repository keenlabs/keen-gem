# frozen_string_literal: true

module Keen
  class Client
    module UpdatingMethods
      # Update events
      #
      # See detailed documentation here
      #  TODO: Put link to documentation
      #
      # @param event_collection
      # @param [Hash] params
      #
      # @return the JSON response from the API

      def update(event_collection, params = {})
        ensure_project_id!
        ensure_master_key!
        check_request_data!(event_collection, params)
        update_body(
          api_event_collection_resource_path(event_collection),
          MultiJson.encode(params),
          'update'
        )
      end

      # Updates a batch of events
      #
      # See detailed documentation here
      #  TODO: Put link to documentation
      #
      # @param event_collection
      # @param [Hash] params
      #
      # @return the JSON response from the API

      def update_batch(event_collection, params = {})
        ensure_project_id!
        ensure_master_key!
        check_batch_request_data!(event_collection, params)
        update_body(
          api_event_collection_resource_path(event_collection),
          MultiJson.encode(params),
          'update_batch'
        )
      end

      private

      def check_batch_request_data!(event_collection, params)
        check_even_collection(event_collection)

        unless params && params[:batch_update]&.is_a?(Array)
          raise ArgumentError, "The specified params are invalid. Missing or invalid 'batch_update' in the body."
        end


        params[:batch_update].each do |update_params|
          check_update_body(update_params)
        end
      end

      def check_request_data!(event_collection, params = {})
        check_even_collection(event_collection)
        check_update_body(params)
      end

      def check_update_body(params)
        %i[property_updates filters timeframe].each do |key|
          unless params && params[key]
            raise ArgumentError, "The specified params are invalid. Missing '#{key}' in the body."
          end
        end
      end

      def check_even_collection(event_collection)
        raise ArgumentError, 'Event collection can not be nil' unless event_collection
      end

      def update_body(path, body, error_method)
        response = Keen::HTTP::Sync.new(
          api_url, proxy_url, read_timeout, open_timeout
        ).put(
          path: path,
          headers: api_headers(master_key, 'update'),
          body: body
        )
        process_response(response.code, response.body&.chomp, true)
      rescue Exception => e
        raise HttpError.new("HTTP #{error_method} failure: #{e.message}", e)
      end
    end
  end
end

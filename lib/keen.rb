require 'logger'
require 'forwardable'

require 'keen/client'

module Keen
  class Error < RuntimeError
    attr_accessor :original_error
    def initialize(message, _original_error=nil)
      self.original_error = _original_error
      super(message)
    end
  end

  class ConfigurationError < Error; end
  class HttpError < Error; end
  class BadRequestError < HttpError; end
  class AuthenticationError < HttpError; end
  class NotFoundError < HttpError; end

  class << self
    extend Forwardable

    def_delegators :default_client, :project_id, :api_key,
                   :project_id=, :api_key=, :publish, :publish_async,
                   :beacon_url, :count, :count_unique, :minimum, :maximum,
                   :sum, :average, :select_unique, :funnel

    attr_writer :logger

    def logger
      @logger ||= lambda {
        logger = Logger.new($stdout)
        logger.level = Logger::INFO
        logger
      }.call
    end

    private

    def default_client
      @default_client ||= Keen::Client.new(
        :project_id => ENV['KEEN_PROJECT_ID'],
        :api_key => ENV['KEEN_API_KEY']
      )
    end
  end
end

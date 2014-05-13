require 'logger'
require 'forwardable'

require 'keen/client'
require 'keen/scoped_key'

module Keen
  class Error < RuntimeError
    attr_accessor :original_error
    def initialize(message, _original_error=nil)
      self.original_error = _original_error
      super(message)
    end

    def to_s
      "Keen IO Exception: #{super}"
    end
  end

  class ConfigurationError < Error; end
  class HttpError < Error; end
  class BadRequestError < HttpError; end
  class AuthenticationError < HttpError; end
  class NotFoundError < HttpError; end

  class << self
    extend Forwardable

    def_delegators :default_client,
                   :project_id, :project_id=,
                   :write_key, :write_key=,
                   :read_key, :read_key=,
                   :master_key, :master_key=,
                   :api_url, :api_url=

    def_delegators :default_client,
                   :proxy_url, :proxy_url=,
                   :proxy_type, :proxy_type=

    def_delegators :default_client,
                   :publish, :publish_async, :publish_batch,
                   :publish_batch_async, :beacon_url, :redirect_url

    def_delegators :default_client,
                   :count, :count_unique, :minimum, :maximum,
                   :sum, :average, :select_unique, :funnel, :extraction,
                   :multi_analysis, :median, :percentile

    def_delegators :default_client,
                   :delete

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
        :write_key => ENV['KEEN_WRITE_KEY'],
        :read_key => ENV['KEEN_READ_KEY'],
        :master_key => ENV['KEEN_MASTER_KEY'],
        :api_url => ENV['KEEN_API_URL'],
        :proxy_url => ENV['KEEN_PROXY_URL'],
        :proxy_type => ENV['KEEN_PROXY_TYPE']
      )
    end
  end
end

require 'keen/http'
require 'keen/version'
require 'keen/client/publishing_methods'
require 'keen/client/querying_methods'
require 'keen/client/maintenance_methods'
require 'keen/helpers'
require 'keen/query'
require 'keen/config'

require 'openssl'
require 'multi_json'
require 'base64'

module Keen
  class Client
    include Keen::Client::PublishingMethods
    include Keen::Client::QueryingMethods
    include Keen::Client::MaintenanceMethods
    include Keen::Helpers

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

      project_id, write_key, read_key, master_key = options.values_at(
        :project_id, :write_key, :read_key, :master_key)

      config.project_id = project_id
      config.write_key = write_key
      config.read_key = read_key
      config.master_key = master_key

      config.api_url = options[:api_url] || config.api_url
    end

    def config
      @config ||= Keen::Config.new
    end

    # able to set and get any keys of the config
    def method_missing(name, *args, &blk)
      config.send name, *args, &blk
    end
  end

end

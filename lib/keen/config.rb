module Keen
  class Config
    attr_accessor :project_id, :write_key, :read_key, :master_key

    CONFIG = {
        :api_url => "https://api.keen.io",
        :api_version => "3.0",
        :api_headers => lambda { |authorization, sync_or_async|
          user_agent = "keen-gem, v#{Keen::VERSION}, #{sync_or_async}"
          user_agent += ", #{RUBY_VERSION}, #{RUBY_PLATFORM}, #{RUBY_PATCHLEVEL}"
          if defined?(RUBY_ENGINE)
            user_agent += ", #{RUBY_ENGINE}"
          end
          { "Content-Type" => "application/json",
            "User-Agent" => user_agent,
            "Authorization" => authorization }
        }
    }

    def initialize
      @options = CONFIG.dup
    end

    # able to set and get any keys of the config
    def method_missing(name, *args, &blk)
      if name.to_s =~ /=$/
        if @options.has_key?($`.to_sym)
          @options[$`.to_sym] = args.first
        else
          super
        end
      elsif config = @options[name.to_sym]
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
module Keen
  class Config
    attr_accessor :project_id, :write_key, :read_key, :master_key

    CONFIG = {
        :api_url => "https://api.keen.io",
        :api_version => "3.0"
    }

    def initialize
      @options = {}
      @options = @options.merge(CONFIG.dup)
    end

    def api_headers(authorization, sync_or_async)
      user_agent = "keen-gem, v#{Keen::VERSION}, #{sync_or_async}"
      user_agent += ", #{RUBY_VERSION}, #{RUBY_PLATFORM}, #{RUBY_PATCHLEVEL}"
      if defined?(RUBY_ENGINE)
        user_agent += ", #{RUBY_ENGINE}"
      end

        { "Content-Type" => "application/json",
          "User-Agent" => user_agent,
          "Authorization" => authorization }
    end

    # able to set and get any keys of the config
    def method_missing(name, *args, &blk)
      if name.to_s =~ /=$/
        if @options.has_key?($`.to_sym)
          @options[$`.to_sym] = args.first
        else
          super
        end
      elsif @options[name.to_sym]
          @options[name.to_sym]
      else
        super
      end
    end

  end
end
module Keen
  module Modeling
    class OptionKey
      attr_reader :default, :options

      def initialize(name, options)
        @default = name
        @options = options
      end

      def key
        if options?
          options[:as]
        else
          default
        end
      end

      private

      def options?
        options.is_a?(Hash)
      end
    end
  end
end

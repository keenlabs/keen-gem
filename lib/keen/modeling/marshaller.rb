module Keen
  module Modeling
    class Marshaller
      attr_reader :output, :object

      def initialize(object)
        @object = object
        @output = {}
      end

      def method_missing(method, *args, &block)
        @arg = args.first
        key = OptionKey.new(method, @arg).key
        output[key] = ValueExtractor.new(_call(method), *args, &block).extract
      end

      private

      def _call(method)
        if @arg == :wrap
          object
        elsif valid_message?(method)
          object.send method
        end
      end

      def valid_message?(msg)
        object.respond_to?(msg) && !object.nil?
      end
    end
  end
end

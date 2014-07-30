module Keen
  module Modeling
    module Extractors
      class Enumerable < Abstract
        def handler?
          @proc && safe_enumerable?
        end

        def extract_value
          object.map { |obj| Block.new(obj, [], @proc).extract_value }
        end

        private

        def safe_enumerable?
          object.is_a?(::Enumerable) && !object.is_a?(::Hash)
        end
      end
    end
  end
end

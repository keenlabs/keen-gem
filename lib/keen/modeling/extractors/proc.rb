module Keen
  module Modeling
    module Extractors
      class Proc < Abstract
        def handler?
          arg.is_a?(::Proc)
        end

        def extract_value
          arg.call
        end

        private

        def arg
          @args.first
        end
      end
    end
  end
end

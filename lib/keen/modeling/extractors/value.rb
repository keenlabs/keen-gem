module Keen
  module Modeling
    module Extractors
      class Value < Abstract
        def handler?
          true
        end

        def extract_value
          object
        end
      end
    end
  end
end

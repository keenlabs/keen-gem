module Keen
  module Modeling
    module Extractors
      class Block < Abstract
        def handler?
          !!@proc
        end

        def extract_value
          Modeler.define(object, &@proc).output
        end
      end
    end
  end
end

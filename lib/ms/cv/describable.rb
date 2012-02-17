require 'cv/describable'
require 'ms/cv/description'

module MS
  module CV
    module Describable
      include ::CV::Describable

      def initialize(*param_objs, &block)
        @description = MS::CV::Description.new( *param_objs )
        @description.instance_eval &block
      end

    end
  end
end

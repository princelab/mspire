require 'ms/cv/description'

module MS
  module CV
    module Describable

      # sets @description by sending arguments to MS::CV::Description[ *args ]
      def initialize(*param_objs)
        @description = MS::CV::Description[ *param_objs ]
      end

      # if description respond_to?(:to_xml) then will call that, otherwise
      # iterates over @description and calls .to_xml on each object.
      def to_xml(xml)
        if @description
          if @description.respond_to?(:to_xml)
            @description.to_xml(xml)
          else
            @description.each do |el|
              el.to_xml(xml)
            end
          end
        end
        xml
      end

    end
  end
end

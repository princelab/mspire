require 'ms/cv/description'

module MS
  module CV
    module Paramable

      attr_accessor :params

      # sets @params by sending arguments to MS::CV::Description[ *args ]
      def initialize(opts={})
        @params = MS::CV::Params[ *opts[:params] ]
      end

      # if params respond_to?(:to_xml) then will call that, otherwise
      # iterates over @params and calls .to_xml on each object.
      def to_xml(xml)
        if @params
          @params.each do |el|
            el.to_xml(xml)
          end
        end
        xml
      end

    end
  end
end

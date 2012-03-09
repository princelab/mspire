require 'ms/cv/param'

module MS
  module CV
    module Paramable

      attr_accessor :params

      def initialize(opts={params: []})
        describe!(*opts[:params])
      end

      # casts each string or array as a Param object (using MS::CV::Param[]),
      # pushes it onto the params attribute and returns the growing params object
      def describe!(*args)
        @params ||= []
        as_params = args.map do |arg|
          if arg.is_a?(Array)
            MS::CV::Param[ *arg ]
          elsif arg.is_a?(String)
            MS::CV::Param[ arg ]
          else
            arg
          end
        end
        @params.push(*as_params)
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

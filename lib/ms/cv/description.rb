require 'ms/cv/param'
require 'cv/description'

module MS
  module CV
    # An MS::Description is a convenient way to specify several mass spec related
    # cvParam objects at once. 
    #
    # examples of usage:
    #
    #     Description.new( <CV::Param> )
    #     Description['MS:1000004', ['MS:1000004'], ['IMS:1000042', 23], param_obj, args]
    #     Description.new do
    #       param MS:1000004
    #       param MS:1000042, 23
    #     end
    class Description < ::CV::Description

      # ensures that each argument is an argument that can be handled by
      # CV::Param. Returns the Description object it creates
      def self.[](*args)
        list = self.new
        args.each do |arg| 
          arg.is_a?(Array) ? list.param(*arg) : list.param(arg) 
        end
        list
      end

      # takes a list of valid CV::Param objects, or they can be set in the block
      # using param
      def initialize(*args, &block)
        args.each {|arg| param(arg) }
        instance_eval &block if block
      end

      # if the first object is a MS::CV::Param it is just pushed onto the list,
      # otherwise the arguments are sent in to initialize a fresh MS::CV::Param,
      # and this object is pushed onto the list.
      def param(*args)
        push args.first.is_a?(::CV::Param) ? args.first : MS::CV::Param.new(*args)
      end
    end

  end
end

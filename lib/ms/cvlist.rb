
require 'cv'
require 'obo/ms'
require 'obo/ims'
require 'obo/unit'

module MS
  module CV
    Obo = {
      'MS' => Obo::MS.id_to_name,
      'IMS' => Obo::IMS.id_to_name,
      'UO' => Obo::Unit.id_to_name,
    }

    class Param < ::CV::Param
      # takes a variety of arguments (acc = accession):
      #
      #     acc#
      #     acc#, value
      #     acc#, unit_acc# or CV::Param object
      #     acc#, value, unit_acc# or CV::Param object
      #     cvref, acc#, name
      #     cvref, acc#, name, value
      #     cvref, acc#, name, unit_acc# or CV::Param object
      #     cvref, acc#, name, value, unit_acc# or CV::Param object
      def initialize(*args)
        @unit = 
          if args.size > 1 && ((args.last.is_a?(::CV::Param) || args.last =~ /[A-Za-z]+:\d+/))
            unit_arg = args.pop
            unit_arg.is_a?(::CV::Param) ? unit_arg : self.class.new(unit_arg)
          end
        (@cv_ref, @accession, @name, @value) = 
          case args.size
          when 1..2  # accession number (maybe with value)
            (obo_type, accnum) = args.first.split(':')
            [obo_type, args.first, MS::CV::Obo[obo_type][args.first], args[1]]
          when 3..4  # they have fully specified the object
            args
          end
      end
    end
  end

  #     CVList.new( <CV::Param> )
  #     CVList['MS:1000004', ['MS:1000004'], ['IMS:1000042', 23], param_obj, args]
  #     CVList.new do
  #       param MS:1000004
  #       param MS:1000042, 23
  #     end
  class CVList < Array

    # ensures that each argument is an argument that can be handled by
    # CV::Param. Returns the CVList object it creates
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

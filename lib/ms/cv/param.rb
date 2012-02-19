require 'ms/cv'

module MS
  module CV

    # a mass spec related CVParam.  It initializes with a variety of obo
    # accession numbers or objects to make writing CV's as easy as possible.
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

end

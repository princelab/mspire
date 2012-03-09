require 'cv/param'
require 'ms/cv'

module MS
  module CV

    # a mass spec related CVParam.  
    class Param < ::CV::Param

      # Takes one of these invocations:
      #
      #     acc_num[, unit_acc_num]
      #     acc_num, value[, unit_acc_num]
      #
      # Where acc_num and unit_acc_num are strings containing valid accession
      # numbers (e.g., 'MS:1000514' or 'UO:0000108').  Note that sometimes units are
      # from obo's other than UO.
      def self.[](*args)
        #puts "param args #{args.inspect}"
        unit = 
          case args.size
          when 1
            nil
          when 2
            MS::CV::Param[args.pop] if args.last.is_a?(String) && args.last =~ /^[A-Za-z]+:/
          when 3
            MS::CV::Param[args.pop]
          end
        obo_type = args[0][/([A-Za-z]+):/,1]
        self.new(obo_type, args[0], MS::CV::Obo[obo_type][args.first], args[1], unit)
      end
    end
  end

end

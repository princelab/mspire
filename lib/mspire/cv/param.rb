require 'mspire/cv/param'
require 'mspire/cv/obo'

module Mspire
  module CV

    # a mass spec related CVParam.  
    module Param

      # Takes one of these invocations:
      #
      #     acc_num[, unit_acc_num]
      #     acc_num, value[, unit_acc_num]
      #
      # Where acc_num and unit_acc_num are strings containing valid accession
      # numbers (e.g., 'MS:1000514' or 'UO:0000108').  Note that sometimes units are
      # from obo's other than UO.
      #
      # returns a CV::Param object
      def self.[](*args)
        #puts "param args #{args.inspect}"
        unit = 
          case args.size
          when 1
            nil
          when 2
            Mspire::CV::Param[args.pop] if args.last.is_a?(String) && args.last =~ /^[A-Za-z]+:/
          when 3
            Mspire::CV::Param[args.pop]
          end
        acc = args[0]
        obo_type = acc[/([A-Za-z]+):/,1]
        val = args[1]
        if val
          cast = Mspire::CV::Obo::CAST[acc]
          (val = val.send(cast)) if cast
        end
        ::CV::Param.new(obo_type, args[0], Mspire::CV::Obo::NAME[acc], val, unit)
      end
    end
  end

end

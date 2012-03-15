
module Mspire

  class UserParam

    # (optional) a CV::Param object
    attr_accessor :unit

    # (required)
    attr_accessor :name

    # (optional)
    attr_accessor :value

    # (optional) e.g. 'xsd:float'
    attr_accessor :type

    # takes a few different incantations:
    #
    #     name, unit_acc# or CV::Param object
    #     name, value, unit_acc# or CV::Param object
    #     name, value, type, unit_acc# or CV::Param object
    def initialize(*args)
      @unit = 
        if args.size > 1 && ((args.last.is_a?(::CV::Param) || args.last =~ /^[A-Za-z]+:\d+$/))
          unit_arg = args.pop
          unit_arg.is_a?(::CV::Param) ? unit_arg : Mspire::CV::Param[unit_arg]
        end
      @name, @value, @type = args
    end

  end
end

# A UserParam
# (has no accession)
# (has no cvRef)
# name (required)
# type
# unitAccession
# unitCvRef
# unitName
# value

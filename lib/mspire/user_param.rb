
module Mspire

  UserParam = Struct.new(:name, :value, :type, :unit)

  class UserParam

    # returns nil
    def accession
      # that way all params can be queried by accession and not raise error
      nil
    end

    # takes a few different incantations:
    #
    #     name, unit_acc# or CV::Param object
    #     name, value, unit_acc# or CV::Param object
    #     name, value, type, unit_acc# or CV::Param object
    def initialize(*args)
      self.unit = 
        if args.size > 1 && ((args.last.is_a?(::CV::Param) || args.last =~ /^[A-Za-z]+:\d+$/))
          unit_arg = args.pop
          unit_arg.is_a?(::CV::Param) ? unit_arg : Mspire::CV::Param[unit_arg]
        end
      self.name, self.value, self.type = args
    end

    def to_xml(xml)
      atts = { name: name, value: value, type: type }
      if unit
        atts.merge!( 
                    { :unitCvRef => unit.cv_ref, 
                      :unitAccession => unit.accession,
                      :unitName => unit.name } 
                   )
      end
      xml.userParam(atts)
      xml
    end

  end
end

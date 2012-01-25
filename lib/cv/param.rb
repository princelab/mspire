
module CV
  class Param
    attr_accessor :cv_ref, :accession, :name, :value
    # A valueless CV::Param object that describes the units being used
    attr_accessor :unit

    def initialize(cv_ref, accession, name, value=nil)
      (@cv_ref, @accession, @name, @value) = [cv_ref, accession, name, value]
    end

    def to_xml(xml, name=:cvParam)
      hash_to_send = {:cvRef => @cvref, :accession => @accession, :name => @name}
      hash_to_send[:value] = @value if @value
      if unit
        hash_to_send.merge!( { :unitCvRef => unit.cv_ref, 
                            :unitAccession => unit.accession,
                            :unitName => unit.name } )
      end
      xml.send(name, hash_to_send)
    end

    def ==(other)
      if !other.nil? && other.is_a?(CV::Param)
        [:cv_ref, :accession, :name, :value, :unit].inject(true) do |bool, mthd|
          bool && (self.send(mthd) == other.send(mthd))
        end
      else ; false
      end
    end
  end
end


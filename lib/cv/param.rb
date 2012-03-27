
module CV

  Param = Struct.new(:cv_ref, :accession, :name, :value, :unit)

  class Param

    # standard struct invocation.  Ensures that value is nil if an empty
    # string is given.
    def initialize(*args)
      args[3] = nil if (args[3] == '')
      super(*args)
    end

    # for now, assumes this is a Builder::XmlMarkup object.  
    # returns the xml builder object
    def to_xml(xml, name=:cvParam)
      hash_to_send = {:cvRef => self.cv_ref, :accession => self.accession, :name => self.name}
      if v=self.value
        hash_to_send[:value] = v
      end
      if unit
        hash_to_send.merge!( 
                            { :unitCvRef => unit.cv_ref, 
                            :unitAccession => unit.accession,
                            :unitName => unit.name } 
                           )
      end

      # xml.send for builder results in tags with 'send' in the front
      xml.tag!(name, hash_to_send)
      # for nokogiri builder
      #xml.send(name, hash_to_send)
      xml
    end

    def ==(other)
      if !other.nil?
        [:cv_ref, :accession, :name, :value, :unit].inject(true) do |bool, mthd|
          bool && (self.send(mthd) == other.send(mthd))
        end
      else 
        false
      end
    end
  end
end



=begin
# if you want to use Nokogiri as the builder, you need something like this
# code:
class XML::Nokogiri::Builder
  def tag!(name, *data)
    send(name, *data)
  end
end
=end


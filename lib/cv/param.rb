
=begin
# if you want to use Nokogiri as the builder, you need something like this
# code:
class XML::Nokogiri::Builder
  def tag!(name, *data)
    send(name, *data)
  end
end
=end


module CV
  # the xml writer is written with the assumption that the object is a
  # Builder::XmlMarkup object.  You can get away with using Nokogiri
  class Param
    attr_accessor :cv_ref, :accession, :name, :value
    # A valueless CV::Param object that describes the units being used
    attr_accessor :unit

    def initialize(cv_ref, accession, name, value=nil)
      (@cv_ref, @accession, @name, @value) = [cv_ref, accession, name, value]
    end

    # for now, assumes this is a Builder::XmlMarkup object.  
    # returns the xml builder object
    def to_xml(xml, name=:cvParam)
      hash_to_send = {:cvRef => @cv_ref, :accession => @accession, :name => @name}
      hash_to_send[:value] = @value if @value
      if unit
        hash_to_send.merge!( { :unitCvRef => unit.cv_ref, 
                            :unitAccession => unit.accession,
                            :unitName => unit.name } )
      end

      # xml.send for builder results in tags with 'send' in the front
      xml.tag!(name, hash_to_send)
      # for nokogiri builder
      #xml.send(name, hash_to_send)
      xml
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


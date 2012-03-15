
module Mspire
  class OBO
    attr_accessor :header
    attr_accessor :elements

    def initialize(file_or_io)
      obo = Obo::Parser.new(file_or_io)
      elements = obo.elements.to_a
      header = elements.shift
    end
    # returns an id to name Hash
    def id_to_name
      @id_to_name ||= build_hash('id', 'name')
    end
    # returns a name to id Hash
    def name_to_id
      @name_to_id ||= build_hash('name', 'id')
    end
    def id_to_element
      @id_to_element ||= build_hash('id', nil)
    end

    protected
    def build_hash(key,val)
      hash = {}
      elements.each do |el| 
        tv = el.tagvalues
        if val.nil?
          hash[tv[key].first] = el
        else
          hash[tv[key].first] = tv[val].first
        end
      end
      hash
    end
  end
end

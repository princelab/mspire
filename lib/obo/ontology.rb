require 'obo' # the gem obo

module Obo
  class Stanza

    def cast_method
      xref = @tagvalues['xref'].first
      @cast_method = 
        if xref.nil? || (@cast_method == false)
          false
        else
          if @cast_method
            @cast_method
          else
            case xref[/value-type:xsd\\:([^\s]+) /, 1]
            when 'float'  ; :to_f
            when 'int'    ; :to_i
            when 'string' ; :to_s
            else          ; false
            end
          end
        end
    end

    # returns the value cast based on rules in first xref
    # no casting performed if there is no xref
    def cast(val)
      @cast_method ? val.send(@cast_method) : val
    end
  end
end

module Obo
  class Ontology
    DIR = File.expand_path(File.dirname(__FILE__) + '/../../obo')
    attr_accessor :header
    attr_accessor :elements

    def initialize(file_or_io)
      obo = Obo::Parser.new(file_or_io)
      @elements = obo.elements.to_a
      @header = elements.shift
    end
    
    # returns an id to name Hash
    def id_to_name
      @id_to_name ||= build_hash('id', 'name')
    end
    
    def id_to_cast
      @id_to_cast ||= Hash[ id_to_element.map {|id,el| [id, el.cast_method] } ]
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
      @elements.each do |el| 
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

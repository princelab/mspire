
module CV
  class Description < Array
    def initialize(*args, &block)
      super(args)
      self.instance_eval &block
    end

    # pushes a CV::Param object onto the description array
    def param(*args)
      if args.first.is_a?(Symbol)
        push CV::ReferenceableParamGroupRef.new(args.first)
      else
        push CV::Param.new(*args)
      end
    end

    # for now, assumes xml is a Nokogiri::XML::Builder object
    def to_xml(xml)
      self.each {|item| item.to_xml(xml) }
      xml
    end
  end
end

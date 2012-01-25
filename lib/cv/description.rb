
module CV
  class Description < Array
    def initialize(*args, &block)
      super(args)
      self.instance_eval &block
    end

    # pushes a CV::Param object onto the description array
    def param(*args)
      push CV::Param.new(*args)
    end

    def to_xml(xml)
      each {|param| param.to_xml(xml) }
    end
  end
end

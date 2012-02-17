
module CV
  class ReferenceableParamGroupRef
    def initialize(ref)
      @ref = ref
    end

    def to_xml(builder)
      builder.referenceableParamGroupRef(ref: @ref)
      builder
    end
  end
end

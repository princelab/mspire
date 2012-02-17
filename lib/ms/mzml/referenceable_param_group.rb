require 'ms/cv/describable'

module MS
  class Mzml
    class ReferenceableParamGroup
      include MS::CV::Describable

      attr_accessor :id

      def initialize(id, *params, &block)
        @id = id
        super(*params, &block)
      end

      def to_xml(builder)
        builder.referenceableParamGroup(id: @id) do |fc_n|
          super(fc_n)
        end
        builder
      end

      # creates the xml for a referenceableParamGroupList
      def self.list_xml(ref_group_objs, builder)
        builder.referenceableParamGroupList(count: ref_group_objs.size) do |ref_group_n|
          ref_group_objs.each {|rg| rg.to_xml(ref_group_n) }
        end
        builder
      end
    end
  end
end

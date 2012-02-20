require 'ms/cv/describable'

module MS
  class Mzml

    # need to call to_xml_definition (or use
    # MS::Mzml::ReferenceableParamGroupList.list_xml) to get the xml for the
    # object itself (and not a reference).  Merely callying #to_xml will
    # result in a referenceableParamGroupRef being created.
    class ReferenceableParamGroup
      include MS::CV::Describable

      attr_accessor :id

      def initialize(id, *params)
        @id = id
        super(*params)
      end

      def to_xml(builder)
        builder.referenceableParamGroupRef(ref: @id)
        builder
      end

      def to_xml_definition
        builder.referenceableParamGroup(id: @id) do |fc_n|
          super(fc_n)
        end
        builder
      end

      def self.list_xml(objs, builder)
        builder.referenceableParamGroupList(count: objs.size) do |rpgl_n|
          objs.each {|obj| obj.to_xml(rpgl_n) }
        end
      end
    end
  end
end

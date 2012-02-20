require 'ms/cv/describable'
require 'ms/mzml/list'

module MS
  class Mzml
    class ReferenceableParamGroup
      include ::MS::CV::Describable

      attr_accessor :id

      def initialize(id, *params)
        @id = id
        super(*params)
      end

      def to_xml(builder)
        builder.referenceableParamGroup(id: @id) do |fc_n|
          super(fc_n)
        end
        builder
      end

      extend(MS::Mzml::List)
    end
  end
end

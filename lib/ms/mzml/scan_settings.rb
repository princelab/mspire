require 'ms/mzml/list'
require 'ms/cv/describable'

module MS
  class Mzml
    class ScanSettings
      include MS::CV::Describable

      attr_accessor :id

      def initialize(id, *params, &block)
        @id = id
        super(*params, &block)
      end

      def to_xml(builder)
        builder.scanSettings( id: @id ) do |ss_n|
          super(ss_n)
        end
        builder
      end

      extend(MS::Mzml::List)

    end
  end
end

require 'ms/mzml/list'
require 'ms/cv/paramable'

module MS
  class Mzml
    class ScanSettings
      include MS::CV::Paramable

      attr_accessor :id

      def initialize(id, opts={params: []}, &block)
        @id = id
        describe!(*opts[:params])
        block.call(self) if block
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

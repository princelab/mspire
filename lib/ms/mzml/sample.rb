require 'ms/cv/paramable'
require 'ms/mzml/list'

module MS
  class Mzml
    class Sample
      include MS::CV::Paramable

      attr_accessor :id, :name

      def initialize(id, name, opts={params: []}, &block)
        @id, @name = id, name
        describe!(*opts[:params])
        block.call(self) if block
      end

      def to_xml(builder)
        builder.sample( id: @id, name: @name ) do |sample_n|
          super(sample_n)
        end
        builder
      end

      extend(MS::Mzml::List)
    end
  end
end

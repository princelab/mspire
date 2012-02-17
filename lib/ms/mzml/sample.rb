require 'ms/cv/describable'

module MS
  class Mzml
    class Sample
      include MS::CV::Describable

      attr_accessor :id, :name

      def initialize(id, name, *params, &block)
        @id, @name = id, name
        super(*params, &block)
      end

      def to_xml(builder)
        builder.sample( id: @id, name: @name ) do |sample_n|
          super(sample_n)
        end
        builder
      end

      def list_xml(samples, builder)
        builder.sampleList(count: samples.size) do |sl_n|
          samples.each do |sample|
            sample.to_xml(sl_n)
          end
        end
        builder
      end
    end
  end
end

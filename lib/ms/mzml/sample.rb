require 'ms/cv/describable'
require 'ms/mzml/list'

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

      extend(MS::Mzml::List)
    end
  end
end

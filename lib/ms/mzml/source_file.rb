require 'ms/cv/describable'

module MS
  class Mzml
    class SourceFile
      include MS::CV::Describable
      def initialize(id, name, location, *params, &block)
        @id, @name, @location = id, name, location
        super(*params, &block)
      end

      def to_xml(builder)
        builder.sourceFile( id: @id, name: @name, location: @location ) do |sf_n|
          super(sf_n)
        end
        builder
      end
    end
  end
end

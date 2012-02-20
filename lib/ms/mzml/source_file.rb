require 'ms/cv/describable'
require 'ms/mzml/list'

module MS
  class Mzml
    class SourceFile
      include MS::CV::Describable

      # (required) An identifier for this file.
      attr_accessor :id
      # (required) Name of the source file, without reference to location
      # (either URI or local path).
      attr_accessor :name
      # (required) URI-formatted location where the file was retrieved.
      attr_accessor :location

      def initialize(id="sourcefile1", name="mspire-simulated", location='file://', &block)
        @id, @name, @location = id, name, location
        block.call(self) if block
      end

      def to_xml(builder)
        builder.sourceFile( id: @id, name: @name, location: @location ) do |sf_n|
          super(sf_n)
        end
        builder
      end

      extend(MS::Mzml::List)
    end
  end
end

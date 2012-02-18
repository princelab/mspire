require 'ms/cv/describable'

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

      def initialize(id, name, location='file://', *params, &block)
        @id, @name, @location = id, name, location
        super(*params, &block)
      end

      def to_xml(builder)
        builder.sourceFile( id: @id, name: @name, location: @location ) do |sf_n|
          super(sf_n)
        end
        builder
      end

      def list_xml(source_files, builder)
        builder.sourceFileList(count: source_files.size) do |sf_n|
          source_files.each do |source_file|
            source_file.to_xml(sf_n)
          end
        end
        builder
      end
    end
  end
end

require 'ms/cv/describable'

module MS
  class Mzml
    class FileContent
      include MS::CV::Describable
      def to_xml(builder)
        builder.fileContent do |fc_n|
          super(fc_n)
        end
        builder
      end
    end
  end
end

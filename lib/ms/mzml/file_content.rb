require 'ms/cv/describable'

module MS
  class Mzml
    # This summarizes the different types of spectra that can be expected in
    # the file. This is expected to aid processing software in skipping files
    # that do not contain appropriate spectrum types for it. It should also
    # describe the nativeID format used in the file by referring to an
    # appropriate CV term.
    class FileContent
      include MS::CV::Paramable

      def to_xml(builder, &block)
        builder.fileContent do |fc_n|
          super(fc_n, &block)
        end
        builder
      end
    end
  end
end

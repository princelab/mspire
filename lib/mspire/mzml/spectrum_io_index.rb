require 'mspire/mzml/io_index'

module Mspire
  class Mzml
    class SpectrumIOIndex < IOIndex

      # SpectrumList necessary to link precursors with spectra in random access mode
      attr_accessor :spectrum_list

      # necessary for properly linking precursors to the SourceFile objects
      # from which they are derived.  Unnecessary if spectra are all local.
      attr_accessor :source_file_hash

      def [](index)
        @object_class.from_xml(fetch_xml_node(index), @ref_hash, @spectrum_list, @data_processing_hash, @default_data_processing, @source_file_hash)
      end

    end
  end
end

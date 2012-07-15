require 'mspire/mzml/io_index'

module Mspire
  class Mzml
    class SpectrumIOIndex < IOIndex

      # SpectrumList necessary to link precursors with spectra in random access mode
      attr_accessor :spectrum_list

      # necessary for properly linking precursors to the SourceFile objects
      # from which they are derived.  Unnecessary if spectra are all local.
      attr_accessor :source_file_hash

      # spectrum_list object is necessary for linking precursors with spectra.
      # The source_file_hash is necessary *only* if external spectra are
      # referenced.
      def initialize(io, byte_index, ref_hash, spectrum_list=nil, source_file_hash=nil)
        @io, @byte_index, @ref_hash, @spectrum_list, @source_file_hash = io, byte_index, ref_hash, spectrum_list, source_file_hash
        @object_class = Mspire::Mzml::Spectrum
        @closetag_regexp = %r{</#{name}>}
      end

      def [](index)
        @object_class.from_xml(fetch_xml_node(index), @ref_hash, @spectrum_list, @source_file_hash)
      end

    end
  end
end

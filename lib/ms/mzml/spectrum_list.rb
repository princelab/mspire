require 'ms/mzml/spectrum'

module MS
  class Mzml
    class SpectrumList < Array

      # a DataProcessing object
      attr_reader :default_data_processing

      def initialize(default_data_processing, spectra=[])
        @default_data_processing = default_data_processing
        super(spectra)
      end

      # This method takes an MS::Spectrum object and transforms it into an
      # MS::Mzml::Spectrum object and puts it in the internal list
      def add_ms_spectrum(spectrum, id)
        mzml_spec = MS::Mzml::Spectrum.new(id)
        mzml_spec.data = spectrum.data
        self << mzml_spec
      end

      # takes an array of spectra and performs add_spectrum on each
      # returns self
      def add_spectra(spectra, ids=[])
        spectra.zip(ids).each_with_index {|(spec,id),i| add_spectrum(spec, "spectrum=#{i+1}") }
        self
      end

      def to_xml(builder)
        builder.spectrumList(count: self.size, defaultDataProcessingRef: @default_data_processing.id) do |spl_n|
          self.each_with_index do |spectrum,i|
            spectrum.index = i unless spectrum.index
            spectrum.to_xml(spl_n)
          end
        end
        builder
      end

    end
  end
end

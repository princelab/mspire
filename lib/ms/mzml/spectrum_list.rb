
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
      def add_spectrum(spectrum)
        MS::Mzml::Spectrum.new
      end

      # takes an array of spectra and performs add_spectrum on each
      def add_spectra(spectra)
        spectra.each {|spec| add_spectrum(spec) }
      end

      def to_xml(builder)
        builder.spectrumList(count: self.size, defaultDataProcessingRef: @default_data_processing.id) do |spl_n|
          self.each do |spectrum|
            spectrum.to_xml(spl_n)
          end
        end
        builder
      end

    end
  end
end


module MS
  class Mzml
    class SpectrumList < Array

      # a DataProcessing object
      attr_reader :default_data_processing

      def initialize(default_data_processing, spectra=[])
        @default_data_processing = default_data_processing
        super(spectra)
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

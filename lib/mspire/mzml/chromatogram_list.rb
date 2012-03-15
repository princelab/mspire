

module Mspire
  class Mzml
    class ChromatogramList < Array

      # a DataProcessing object
      attr_reader :default_data_processing

      def initialize(default_data_processing, chromatograms=[])
        @default_data_processing = default_data_processing
        super(chromatograms)
      end

      def to_xml(builder)
        builder.chromatogramList(count: self.size, defaultDataProcessingRef: @default_data_processing.id) do |chrl_n|
          self.each do |chromatogram|
            chromatogram.to_xml(chrl_n)
          end
        end
        builder
      end

    end
  end
end

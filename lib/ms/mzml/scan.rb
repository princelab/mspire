require 'ms/cv/describable'

module MS
  class Mzml
    class Scan
      include MS::CV::Describable

      # (optional) the MS::Mzml::Spectrum object from which the precursor is
      # derived.  (the sourceFileRef is derived from this spectrum object if
      # from_external_source_file == true)
      attr_accessor :spectrum

      # a boolean indicating the spectrum is from an external source file
      attr_accessor :from_external_source_file

      # an InstrumentConfiguration object
      attr_accessor :instrument_configuration

      # ScanWindow objects
      attr_accessor :scan_windows

      def initialize(&block)
        block.call(self) if block
      end

      def to_xml(builder)
        atts = {}
        if @from_external_source_file
          atts[:sourceFileRef] = @spectrum.source_file.id
          atts[:externalSpectrumRef] = @spectrum.id
        else
          atts[:spectrumRef] = @spectrum.id if @spectrum
        end
        atts[:instrumentConfigurationRef] = @instrument_configuration.id if @instrument_configuration
        builder.scan(atts) do |prec_n|
          super(prec_n) # description
          ScanWindow.list_xml(@scan_windows, prec_n) if @scan_windows
        end
      end

    end
  end
end

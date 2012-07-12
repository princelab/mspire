require 'mspire/cv/paramable'
require 'mspire/mzml/scan_window'

module Mspire
  class Mzml
    class Scan
      include Mspire::CV::Paramable

      # (optional) the Mspire::Mzml::Spectrum object from which the precursor is
      # derived.  (the sourceFileRef is derived from this spectrum object if
      # from_external_source_file == true)
      attr_accessor :spectrum

      # a boolean indicating the spectrum is from an external source file
      attr_accessor :from_external_source_file

      # an InstrumentConfiguration object
      attr_accessor :instrument_configuration

      # ScanWindow objects
      attr_accessor :scan_windows

      def initialize(opts={params: []}, &block)
        super(opts)
        block.call(self) if block
      end

      # takes a nokogiri node
      #def self.from_xml(xml)
      #end

      def self.from_xml(xml, ref_hash)
        obj = super(xml, ref_hash)
        obj.scan_windows = xml.xpath('./scanWindowList/scanWindow').map do |scan_window_n|
          Mspire::Mzml::ScanWindow.from_xml(scan_window_n, ref_hash)
        end
        obj
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

require 'mspire/cv/paramable'
require 'mspire/cv/paramable'
require 'mspire/mzml/scan_window'

module Mspire
  class Mzml
    class Scan
      include Mspire::CV::Paramable
      extend Mspire::CV::ParamableFromXml

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

      def initialize
        super
        yield(self) if block_given?
      end

      # link should have:
      #
      #     :ref_hash
      #     :default_instrument_configuration
      #     :instrument_configuration_hash
      def self.from_xml(xml, link)
        obj = self.new
        obj.instrument_configuration =
          if icf = xml[:instrumentConfigurationRef]
            link[:instrument_configuration_hash][icf]
          else
            link[:default_instrument_configuration]
          end
        scan_window_list_n = obj.describe_from_xml!(xml, link[:ref_hash])
        obj.scan_windows = scan_window_list_n.children.map do |scan_window_n|
          Mspire::Mzml::ScanWindow.from_xml(scan_window_n, ref_hash)
        end
        obj
      end

      def to_xml(builder, link)
        atts = {}
        if @from_external_source_file
          atts[:sourceFileRef] = @spectrum.source_file.id
          atts[:externalSpectrumRef] = @spectrum.id
        else
          atts[:spectrumRef] = @spectrum.id if @spectrum
        end
        if @instrument_configuration
          unless @instrument_configuration.id == link[:default_instrument_configuration].id
            atts[:instrumentConfigurationRef] = @instrument_configuration.id 
          end
        end
        builder.scan(atts) do |prec_n|
          super(prec_n) # description
          ScanWindow.list_xml(@scan_windows, prec_n) if @scan_windows
        end
      end

    end
  end
end

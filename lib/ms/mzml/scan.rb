require 'ms/cv/describable'

module MS
  class Mzml
    class Scan
      include MS::CV::Describable
      # (optional) the MS::Mzml::Spectrum object from which the precursor is
      # derived
      attr_accessor :spectrum

      # (optional)
      attr_accessor :isolation_window 

      # (optional) An array of ions that were selected.
      attr_accessor :selected_ions

      # (required) The type and energy level used for activation.
      attr_accessor :activation

      # a boolean indicating the spectrum is from an external source file
      attr_accessor :from_external_source_file

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
        builder.precursor(atts) do |prec_n|
          @isolation_window.to_xml(prec_n) if @isolation_window
          MS::Mzml::SelectedIonList.list_xml(@selected_ions, prec_n) if @selected_ions
          @activation.to_xml(prec_n)
        end
      end

    end
  end
end

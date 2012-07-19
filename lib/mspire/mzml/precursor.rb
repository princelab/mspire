require 'mspire/mzml/list'
require 'mspire/mzml/selected_ion'
require 'mspire/mzml/isolation_window'
require 'mspire/mzml/activation'

module Mspire
  class Mzml
    # The method of precursor ion selection and activation
    class Precursor

      # (optional) the id of the Spectrum object, whether internal or
      # externally derived.
      attr_accessor :spectrum_id

      # (optional)
      attr_accessor :isolation_window 

      # (optional) An array of ions that were selected.
      attr_accessor :selected_ions

      # (required) The type and energy level used for activation.
      attr_accessor :activation

      # This is an *EXTERNAL* source file *ONLY*.  It should NOT be set if the
      # spectrum is internal.
      attr_accessor :source_file

      # the spectrum list object which enables the spectrum to be accessed directly
      attr_accessor :spectrum_list

      # provide the SpectrumList object for #spectrum access
      def initialize(spectrum_id=nil, spectrum_list=nil)
        @spectrum_id, @spectrum_list = spectrum_id, spectrum_list
      end

      def spectrum
        @spectrum_list[@spectrum_id]
      end

      def self.from_xml(xml, link)
        ref_hash = link[:ref_hash]
        obj = self.new
        obj.spectrum_id = xml[:spectrumRef] || xml[:externalSpectrumID]
        if source_file_ref = xml[:sourceFileRef]
          obj.source_file = link[:source_file_hash][ source_file_ref ]
        end

        xml.children.each do |child_n|
          case child_n.name
          when 'activation' # the only one required
            obj.activation = Mspire::Mzml::Activation.new.describe_self_from_xml!(child_n, ref_hash)
          when 'isolationWindow'
            obj.isolation_window = Mspire::Mzml::IsolationWindow.new.describe_self_from_xml!(child_n, ref_hash)
          when 'selectedIonList'
            obj.selected_ions = child_n.children.map do |si_n|
              Mspire::Mzml::SelectedIon.new.describe_self_from_xml!(si_n, ref_hash)
            end
          end
        end
        
        obj
      end

      def to_xml(builder)
        atts = {}
        if @source_file
          atts[:sourceFileRef] = @source_file.id
          atts[:externalSpectrumRef] = @spectrum_id
        elsif @spectrum_id
          atts[:spectrumRef] = @spectrum_id
        end

        builder.precursor(atts) do |prec_n|
          @isolation_window.to_xml(prec_n) if @isolation_window
          Mspire::Mzml::SelectedIon.list_xml(@selected_ions, prec_n) if @selected_ions
          @activation.to_xml(prec_n) if @activation
        end
      end

      extend(Mspire::Mzml::List)

    end
  end
end


require 'mspire/spectrum_like'
require 'mspire/mzml/data_array'
require 'mspire/mzml/data_array_container_like'
require 'mspire/mzml/scan_list'
require 'mspire/mzml/precursor'
require 'mspire/mzml/product'

require 'andand'

module Mspire
  class Mzml

    #     MAY supply a *child* term of MS:1000465 (scan polarity) only once
    #       e.g.: MS:1000129 (negative scan)
    #       e.g.: MS:1000130 (positive scan)
    #     MUST supply a *child* term of MS:1000559 (spectrum type) only once
    #       e.g.: MS:1000322 (charge inversion mass spectrum)
    #       e.g.: MS:1000325 (constant neutral gain spectrum)
    #       e.g.: MS:1000326 (constant neutral loss spectrum)
    #       e.g.: MS:1000328 (e/2 mass spectrum)
    #       e.g.: MS:1000341 (precursor ion spectrum)
    #       e.g.: MS:1000581 (CRM spectrum)
    #       e.g.: MS:1000582 (SIM spectrum)
    #       e.g.: MS:1000583 (SRM spectrum)
    #       e.g.: MS:1000789 (enhanced multiply charged spectrum)
    #       e.g.: MS:1000790 (time-delayed fragmentation spectrum)
    #       et al.
    #     MUST supply term MS:1000525 (spectrum representation) or any of its children only once
    #       e.g.: MS:1000127 (centroid spectrum)
    #       e.g.: MS:1000128 (profile spectrum)
    #     MAY supply a *child* term of MS:1000499 (spectrum attribute) one or more times
    #       e.g.: MS:1000285 (total ion current)
    #       e.g.: MS:1000497 (zoom scan)
    #       e.g.: MS:1000504 (base peak m/z)
    #       e.g.: MS:1000505 (base peak intensity)
    #       e.g.: MS:1000511 (ms level)
    #       e.g.: MS:1000527 (highest observed m/z)
    #       e.g.: MS:1000528 (lowest observed m/z)
    #       e.g.: MS:1000618 (highest observed wavelength)
    #       e.g.: MS:1000619 (lowest observed wavelength)
    #       e.g.: MS:1000796 (spectrum title)
    #       et al.
    class Spectrum
      include Mspire::SpectrumLike
      include Mspire::Mzml::DataArrayContainerLike
      alias_method :params_initialize, :initialize

      # (optional) an Mspire::Mzml::SourceFile object
      attr_accessor :source_file

      # data_processing is included with DataArrayContainerLike

      # (optional) The identifier for the spot from which this spectrum was derived, if a
      # MALDI or similar run.
      attr_accessor :spot_id

      ###########################################
      # SUBELEMENTS
      ###########################################

      # (optional) a ScanList object
      attr_accessor :scan_list

      # (optional) List and descriptions of precursor isolations to the spectrum
      # currently being described, ordered.
      attr_accessor :precursors

      # (optional) List and descriptions of product isolations to the spectrum
      # currently being described, ordered.
      attr_accessor :products

      # returns the retention time of the first scan object in the scan list
      # *in seconds*!
      def retention_time
        rt_param = scan_list.first.param_by_acc('MS:1000016')
        if rt_param
          multiplier = 
            case rt_param.unit.accession
            when 'UO:0000010' ; 1  # second
            when 'UO:0000031' ; 60 # minute
            when 'UO:0000032' ; 3600 # hour
            when 'UO:0000028' ; 0.001 # millisecond
            else raise 'unsupported units'
            end
          rt_param.value.to_f * multiplier
        end
      end

      # returns the ms_level as an Integer
      def ms_level
        fetch_by_acc('MS:1000511')
      end

      def centroided?
        fetch_by_acc('MS:1000127')
      end

      def profile?
        fetch_by_acc('MS:1000128')
      end

      # returns the charge state of the first precursor as an integer
      def precursor_charge
        precursors.andand.first.andand.selected_ions.andand.first.andand.fetch_by_acc('MS:1000041')
      end

      def precursor_mz
        precursors.andand.first.andand.selected_ions.andand.first.andand.fetch_by_acc('MS:1000744')
      end

      # takes a Nokogiri node and sets relevant properties
      # 
      # link is a hash that should contain the following keys and associated
      # objects (some are required by downstream objects, like Scan):
      #
      #     :ref_hash                         id -> ReferenceableParamGroup
      #     :spectrum_list                    SpectrumList object
      #     :data_processing_hash             id -> DataProcessing object
      #     :default_data_processing          DataProcessing object
      #     :instrument_configuration_hash    id -> InstrumentConfiguration object
      #     :default_instrument_configuration InstrumentConfiguration object
      #     :source_file_hash                 id -> SourceFile object
      def self.from_xml(xml, link)
        obj = self.new(xml[:id])
        obj.spot_id = xml[:spotID]

        obj.data_processing = link[:data_processing_hash][xml[:dataProcessingRef]] || link[:spectrum_default_data_processing]

        if source_file_ref=xml[:sourceFileRef]
          obj.source_file = link[:source_file_hash][source_file_ref]
        end

        xml_n = obj.describe_from_xml!(xml, link[:ref_hash])
        return obj unless xml_n

        loop do
          case xml_n.name
          when 'scanList'
            obj.scan_list = Mspire::Mzml::ScanList.from_xml(xml_n, link)
          when 'precursorList'
            obj.precursors = xml_n.children.map do |prec_n|
              Mspire::Mzml::Precursor.from_xml(prec_n, link)
            end
          when 'productList'
            obj.products = xml_n.children.map do |product_n|
              Mspire::Mzml::Product.from_xml(product_n, link)
            end
          when 'binaryDataArrayList'
            obj.data_arrays = Mspire::Mzml::DataArray.data_arrays_from_xml(xml_n, link)
          end
          break unless xml_n = xml_n.next
        end
        unless obj.data_arrays
          obj.data_arrays = Mspire::Mzml::DataArray.empty_data_arrays
        end

        obj
      end

      # the most common param to pass in would be ms level: 'MS:1000511'
      #
      # This would generate a spectrum of ms_level 2 :
      #
      #     spec = Mspire::Mzml::Spectrum.new("scan=1").describe!('MS:1000511')
      #
      def initialize(id)
        @id = id
        params_initialize
        yield(self) if block_given?
      end

      # see SpectrumList for generating the entire list
      def to_xml(builder, default_ids)
        atts = data_array_xml_atts
        if @data_processing && default_ids[:spectrum_data_processing] != @data_processing.id 
          atts[:dataProcessingRef] = @data_processing.id 
        end
        atts[:sourceFileRef] = @source_file.id if @source_file
        atts[:spotID] = @spot_id if @spot_id

        builder.spectrum(atts) do |sp_n|
          super(sp_n)
          @scan_list.list_xml( sp_n, default_ids ) if @scan_list
          Mspire::Mzml::Precursor.list_xml(@precursors, sp_n) if @precursors
          Mspire::Mzml::Product.list_xml(@products, sp_n) if @products
          Mspire::Mzml::DataArray.list_xml(@data_arrays, sp_n) if @data_arrays
        end
      end

    end
  end
end

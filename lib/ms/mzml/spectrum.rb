require 'ms/mzml/data_array_container_like'
require 'ms/spectrum_like'
require 'ms/mzml/data_array'
require 'ms/mzml/scan_list'
require 'ms/mzml/precursor'
require 'ms/mzml/product'

module MS
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
      include MS::SpectrumLike
      include MS::Mzml::DataArrayContainerLike

      # (optional) an MS::Mzml::SourceFile object
      attr_accessor :source_file

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

      attr_accessor :retention_time
      # when properly implemented, this will access the first scan and the
      # 'scan start time' cv element.

      # takes a Nokogiri node and sets relevant properties
      def self.from_xml(xml)
        spec = MS::Mzml::Spectrum.new(xml[:id])

        params = {}
        xml.xpath("./cvParam").each do |cvparam|
          params[cvparam[:accession]] = cvparam[:value]
        end
        spec.ms_level = params['MS:1000511'].to_i
        # we assume centroid if they don't tell us profile
        spec.centroided = !params.key?("MS:1000128") # profile spectrum 
        # centroid -> "MS:1000127"

        # this is a quick hack to get retention time, implement fully as shown
        # below!
        cv_param = xml.xpath("./scanList/scan/cvParam[@accession='MS:1000016']").first
        retention_time = cv_param && cv_param['value'].to_f

        # this is roughly how the scan list stuff should be implemented:
=begin
        sl_obj = MS::Mzml::ScanList.new

        # TODO: need to slot in all the other info in reasonable ways
        # TODO: need to make sure we deal with referencable params
        scan_list = xml.xpath('.scanList/scan').each do |scan_n|
          sl_obj << MS::Mzml::Scan.from_xml(scan_n)
        end
=end

        data_arrays = xml.xpath('./binaryDataArrayList/binaryDataArray').map do |binary_data_array_n|
          accessions = binary_data_array_n.xpath('./cvParam').map {|node| node['accession'] }
          base64 = binary_data_array_n.xpath('./binary').text
          MS::Mzml::DataArray.from_binary(base64, accessions)
        end
        # if there is no spectrum, we will still return a spectrum object, it
        # just has no mzs or intensities
        data_arrays = [MS::Mzml::DataArray.new, MS::Mzml::DataArray.new] if data_arrays.size == 0
        spec.data_arrays = data_arrays
        spec.retention_time = retention_time
        spec
      end

      # the most common param to pass in would be ms level: 'MS:1000511'
      #
      # This would generate a spectrum of ms_level=2 :
      #
      #     MS::Mzml::Spectrum.new(0, "scan=1", 'MS:1000511')
      #
      def initialize(id, opts={params: []}, &block)
        @id = id
        describe! *opts[:params]
        block.call(self) if block
      end


      # see SpectrumList for generating the entire list
      def to_xml(builder)
        atts = {}
        atts[:sourceFile] = @source_file.id if @source_file
        atts[:spotID] = @spot_id if @spot_id
        super(builder, atts) do |node|
          @scan_list.list_xml( node ) if @scan_list
          MS::Mzml::Precursor.list_xml(@precursors, node) if @precursors
          MS::Mzml::Product.list_xml(@products, node) if @products
        end
      end

    end
  end
end

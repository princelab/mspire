require 'mspire/mzml/data_array_container_like'

module Mspire
  class Mzml
    class Chromatogram
      include Mspire::Mzml::DataArrayContainerLike

      # (optional) precursor isolations to the chromatogram currently being
      # described
      attr_accessor :precursor

      # (optional) Description of product isolation to the chromatogram
      attr_accessor :product

      def initialize(*args, &block)
        super(*args)
        block.call(self) if block
      end

      def self.from_xml(xml)
        chrom = Mspire::Mzml::Chromatogram.new(xml[:id])

        [:cvParam, :userParam].each {|v| chrom.describe! xml.xpath("./#{v}") }

        scan_list = Mspire::Mzml::ScanList.new
        xml.xpath('./scanList/scan').each do |scan_n|
          scan_list << Mspire::Mzml::Scan.from_xml(scan_n)
        end
        chrom.scan_list = scan_list

        precursor = Mspire::Mzml::Precursor.from_xml(xml.xpath('./precursor').first)
        product = Mspire::Mzml::Product.from_xml(xml.xpath('./product').first)

        data_arrays = xml.xpath('./binaryDataArrayList/binaryDataArray').map do |binary_data_array_n|
          accessions = binary_data_array_n.xpath('./cvParam').map {|node| node['accession'] }
          base64 = binary_data_array_n.xpath('./binary').text
          Mspire::Mzml::DataArray.from_binary(base64, accessions)
        end

        # if there is no chromatogram, we will still return a chromatogram object, it
        # just has no values
        data_arrays = [Mspire::Mzml::DataArray.new, Mspire::Mzml::DataArray.new] if data_arrays.size == 0
        chrom.data_arrays = data_arrays
        chrom
      end

      def times
        data_arrays[0]
      end

      def intensities
        data_arrays[1]
      end

      # see SpectrumList for generating the entire list
      def to_xml(builder, opts={})
        super(builder) do |node|
          @precursor.to_xml(node) if @precursor
          @product.to_xml(node) if @product
        end
      end
    end
  end
end

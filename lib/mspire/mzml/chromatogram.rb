require 'mspire/mzml/data_array_container_like'

module Mspire
  class Mzml
    class Chromatogram
      include Mspire::Mzml::DataArrayContainerLike
      alias_method :params_initialize, :initialize

      # (optional) precursor isolations to the chromatogram currently being
      # described
      attr_accessor :precursor

      # (optional) Description of product isolation to the chromatogram
      attr_accessor :product

      def initialize(id)
        @id = id
        params_initialize
        yield(self) if block_given?
      end

      def self.from_xml(xml, link)
        chrom = Mspire::Mzml::Chromatogram.new(xml[:id])
        obj.data_processing = data_processing_hash[xml[:dataProcessingRef]] || default_data_processing

        [:cvParam, :userParam].each {|v| chrom.describe! xml.xpath("./#{v}") }

        precursor_n = xml.xpath('./precursor').first
        precursor = Mspire::Mzml::Precursor.from_xml(precursor_n, ref_hash) if precursor_n

        product_n = xml.xpath('./product').first
        product = Mspire::Mzml::Product.from_xml(product_n, ref_hash) if product_n

        chrom.data_arrays = Mspire::Mzml::DataArray.data_arrays_from_xml(xml, ref_hash)

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

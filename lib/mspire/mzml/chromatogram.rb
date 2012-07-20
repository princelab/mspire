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
        obj = self.new(xml[:id])

        obj.data_processing = link[:data_processing_hash][xml[:dataProcessingRef]] || link[:spectrum_default_data_processing]

        xml_n = obj.describe_from_xml!(xml, link[:ref_hash])

        loop do
          case xml_n.name
          when 'precursor'
            obj.precursor = Mspire::Mzml::Precursor.from_xml(xml_n, link)
          when 'product'
            obj.product = Mspire::Mzml::Product.from_xml(xml_n, link)
          when 'binaryDataArrayList'
            obj.data_arrays = Mspire::Mzml::DataArray.data_arrays_from_xml(xml_n, link)
            break
          end
          break unless xml_n = xml_n.next
        end
        obj
      end

      def times
        data_arrays[0]
      end

      def intensities
        data_arrays[1]
      end

      # see SpectrumList for generating the entire list
      def to_xml(builder, opts={})
        atts = data_array_xml_atts(default_ids)
        builder.chromatogram(atts) do |chrom_n|
          super(chrom_n)
          @precursor.to_xml(chrom_n) if @precursor
          @product.to_xml(chrom_n) if @product
          Mspire::Mzml::DataArray.list_xml(@data_arrays, chrom_n) if @data_arrays
        end
      end
    end
  end
end

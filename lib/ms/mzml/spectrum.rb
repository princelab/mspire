require 'ms/mzml/data_array_container_like'
require 'ms/mzml/data_array'
require 'ms/mzml/scan_list'
require 'ms/mzml/precursor'
require 'ms/mzml/product'

module MS
  class Mzml
    class Spectrum
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

      # the most common param to pass in would be ms level: 'MS:1000511'
      #
      # This would generate a spectrum of ms_level=2 :
      #
      #     MS::Mzml::Spectrum.new(0, "scan=1", 'MS:1000511')
      def initialize(*args, &block)
        super(*args)
        block.call(self) if block
      end

      # see SpectrumList for generating the entire list
      def to_xml(builder)
        atts = {}
        atts[:sourceFile] = @source_file.id if @source_file
        atts[:spotID] = @spot_id if @spot_id
        super(builder, atts) do |node|
          @scan_list.list_xml( node ) if @scan_list
          MS::Mzml::Precursor.list_xml(@precursors, node)
          MS::Mzml::Product.list_xml(@products, node)
        end
      end

    end
  end
end

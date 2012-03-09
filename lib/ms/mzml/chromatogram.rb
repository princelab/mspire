require 'ms/mzml/data_array_container_like'

module MS
  class Mzml
    class Chromatogram
      include MS::Mzml::DataArrayContainerLike

      # (optional) precursor isolations to the chromatogram currently being
      # described
      attr_accessor :precursor

      # (optional) Description of product isolation to the chromatogram
      attr_accessor :product

      def initialize(*args, &block)
        super(*args)
        block.call(self) if block
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

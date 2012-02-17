require 'ms/cv/describable'

module MS
  class Mzml
    class ProcessingMethod
      include MS::CV::Describable

      attr_accessor :order, :software

      def initialize(order, software, *params, &block)
        @order, @software = order, software
        super(*params, &block)
      end

      def to_xml(builder)
        builder.processingMethod( order: @order, softwareRef: software.id) do |pm_n|
          super(pm_n)
        end
        builder
      end
    end
  end
end

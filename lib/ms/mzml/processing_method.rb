require 'ms/cv/paramable'

module MS
  class Mzml
    class ProcessingMethod
      include MS::CV::Paramable

      attr_accessor :order, :software

      def initialize(order, software, opts={params: []}, &block)
        @order, @software = order, software
        describe!(*opts[:params])
        block.call(self) if block
      end

      def to_xml(builder)
        builder.processingMethod(order: @order, softwareRef: software.id) do |pm_n|
          super(pm_n) # params
        end
        builder
      end
    end
  end
end

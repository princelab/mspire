require 'mspire/cv/paramable'

module Mspire
  class Mzml
    class ProcessingMethod
      include Mspire::CV::Paramable
      extend Mspire::CV::ParamableFromXml

      attr_accessor :order, :software

      def initialize(order, software, opts={params: []}, &block)
        @order, @software = order, software
        super(opts)
        block.call(self) if block
      end

      def to_xml(builder)
        builder.processingMethod(order: @order, softwareRef: software.id) do |pm_n|
          super(pm_n) # params
        end
        builder
      end

      def self.from_xml(xml, ref_hash, software_hash)
        obj = self.new(xml[:order], software_hash[xml[:softwareRef]])
        super(xml, ref_hash, obj)
      end
    end
  end
end

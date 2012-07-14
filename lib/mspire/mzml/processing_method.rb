require 'mspire/cv/paramable'

module Mspire
  class Mzml
    # The order attribute is *not* intrinsic to the ProcessingMethod (and thus
    # cannot be queried from within the object.  It can be determined easily
    # by asking for the index of the method in the array of processing
    # methods.  (zero based indexing is fine)
    class ProcessingMethod
      include Mspire::CV::Paramable
      extend Mspire::CV::ParamableFromXml

      attr_accessor :software

      def initialize(software, opts={params: []}, &block)
        @software = software
        super(opts)
        block.call(self) if block
      end

      def to_xml(builder, order)
        builder.processingMethod(order: order, softwareRef: software.id) do |pm_n|
          super(pm_n) # params
        end
        builder
      end

      def self.from_xml(xml, ref_hash, software_hash)
        obj = self.new(software_hash[xml[:softwareRef]])
        super(xml, ref_hash, obj)
      end
    end
  end
end

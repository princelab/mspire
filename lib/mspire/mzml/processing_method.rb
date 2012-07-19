require 'mspire/cv/paramable'

module Mspire
  class Mzml
    # The order attribute is *not* intrinsic to the ProcessingMethod (and thus
    # cannot be queried from within the object.  It can be determined easily
    # by asking for the index of the method in the array of processing
    # methods.  (zero based indexing is fine)
    class ProcessingMethod
      include Mspire::CV::Paramable

      attr_accessor :software

      def initialize(software)
        @software = software
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder, order)
        builder.processingMethod(order: order, softwareRef: software.id) do |pm_n|
          super(pm_n) # params
        end
        builder
      end
    end
  end
end

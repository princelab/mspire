require 'mspire/cv/paramable'

module Mspire
  class Mzml

    # MAY supply a *child* term of MS:1000630 (data processing parameter) one or more times
    #     e.g.: MS:1000629 (low intensity threshold)
    #     e.g.: MS:1000631 (high intensity threshold)
    #     e.g.: MS:1000747 (completion time)
    #     e.g.: MS:1000787 (inclusive low intensity threshold)
    #     e.g.: MS:1000788 (inclusive high intensity threshold)
    #
    # MUST supply a *child* term of MS:1000452 (data transformation) one or more times
    #     e.g.: MS:1000033 (deisotoping)
    #     e.g.: MS:1000034 (charge deconvolution)
    #     e.g.: MS:1000544 (Conversion to mzML)
    #     e.g.: MS:1000545 (Conversion to mzXML)
    #     e.g.: MS:1000546 (Conversion to mzData)
    #     e.g.: MS:1000593 (baseline reduction)
    #     e.g.: MS:1000594 (low intensity data point removal)
    #     e.g.: MS:1000741 (Conversion to dta)
    #     e.g.: MS:1000745 (retention time alignment)
    #     e.g.: MS:1000746 (high intensity data point removal)
    class ProcessingMethod
      include Mspire::CV::Paramable

      attr_accessor :software

      def initialize(software)
        @software = software
        params_init
        if block_given?
          yield self 
        end
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

# The order attribute is *not* intrinsic to the ProcessingMethod (and thus
# cannot be queried from within the object.  It can be determined easily
# by asking for the index of the method in the array of processing
# methods.  (zero based indexing is fine)


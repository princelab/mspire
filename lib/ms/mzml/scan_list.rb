require 'ms/cv/describable'

module MS
  class Mzml
    # MUST supply a *child* term of MS:1000570 (spectra combination) only once
    #
    #     e.g.: MS:1000571 (sum of spectra)
    #     e.g.: MS:1000573 (median of spectra)
    #     e.g.: MS:1000575 (mean of spectra)
    #     e.g.: MS:1000795 (no combination)
    class ScanList < Array
      include MS::CV::Describable
      def initialize(ar=nil)
        self.replace(ar) if ar
      end

      def list_xml(builder)
        builder.scanList(count: self.size) do |sl_n|
          @description.to_xml(sl_n)
          self.each do |scan|
            scan.to_xml(sl_n)
          end
        end
      end
    end
  end
end

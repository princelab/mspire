require 'mspire/cv/paramable'
require 'mspire/mzml/scan'

module Mspire
  class Mzml

    # MUST supply a *child* term of MS:1000570 (spectra combination) only once
    #
    #     e.g.: MS:1000571 (sum of spectra)
    #     e.g.: MS:1000573 (median of spectra)
    #     e.g.: MS:1000575 (mean of spectra)
    #     e.g.: MS:1000795 (no combination)
    class ScanList < Array
      include Mspire::CV::Paramable

      def initialize
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder)
        builder.scanList(count: self.size) do |sl_n|
          super(sl_n)
          self.each do |scan|
            scan.to_xml(sl_n)
          end
        end
        builder
      end

      def self.from_xml(xml, link)
        scan_list = self.new
        scan_n = scan_list.describe_from_xml!(xml, link[:ref_hash])
        if scan_n
          loop do
            scan_list << Mspire::Mzml::Scan.from_xml(scan_n, link)
            break unless scan_n = scan_n.next
          end
        end
        scan_list
      end

      alias_method :list_xml, :to_xml
    end
  end
end

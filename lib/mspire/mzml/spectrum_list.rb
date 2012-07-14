require 'mspire/mzml/io_indexable_list'

module Mspire
  class Mzml
    class SpectrumList < IOIndexableList

      attr_accessor :scan_to_index

      def fetch_by_scan_num(scan_num)
        __getobj__[@scan_to_index[scan_num]]
      end
    end
  end
end

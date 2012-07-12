
module Mspire
  class Mzml
    # the array holds start bytes
    class Index < Array

      # a hash index pointing from scan number to byte, created by create_scan_to_index!
      attr_accessor :by_scans

      # the name of the index (as a symbol)
      attr_accessor :name

      # a parallel array of ids (idRef's)
      attr_accessor :ids

      def start_byte_and_id(int)
        [self[int], ids[int]]
      end

      # returns hash of id to start_byte
      def create_id_index
        Hash[self.ids.zip(self)]
      end

      # @return [Integer] the start byte of the spectrum
      # @param [Object] an Integer (the index number) or String (an id string)
      def start_byte(arg)
        case arg
        when Integer
          self[arg]
        when String
          @id_index ||= create_id_index
          @id_index[arg]
        end
      end

      # generates a scan to index hash that points from scan number to the
      # spectrum index number.  returns the index, nil if the scan ids
      # are not present and spectra are, or false if they are not unique.
      def create_scan_to_index!
        scan_re = /scan=(\d+)/
          scan_to_index = {}
        ids.each_with_index do |id, index|
          md = id.match(scan_re)
          scan_num = md[1].to_i if md
          if scan_num
            if scan_to_index.key?(scan_num)
              return false
            else
              scan_to_index[scan_num] = index
            end
          end
        end
        if scan_to_index.size > 0
          by_scans = scan_to_index
        elsif ids.size > 0
          nil  # there are scans, but we did not find scan numbers
        else
          scan_to_index
        end
      end
    end
  end
end


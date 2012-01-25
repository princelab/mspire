module MS
  class Mzml
    # A simple array of indices but #[] has been overloaded to find an index
    # by name
    #
    #     index_list[0]  # the first index
    #     index_list.map(&:names) # -> [:spectrum, :chromatogram] 
    #     index_list[:spectrum]  # the spectrum index
    #     index_list[:chromatogram]  # the chromatogram index
    class IndexList < Array
      alias_method :old_bracket_slice, :'[]'

      # @param [Object] an Integer (index number) or a Symbol (:spectrum or
      #   :chromatogram)
      # @return [MS::Mzml::Index] an index object
      def [](int_or_symbol)
        if int_or_symbol.is_a?(Integer)
          old_bracket_slice(int_or_symbol)
        else
          self.find {|index| index.name == int_or_symbol }
        end
      end
    end

    # the array holds start bytes
    class Index < Array

      class << self
        # returns an Integer or nil if not found
        # does a single jump backwards from the tail of the file looking for
        # an xml element based on tag.  If it is not found, returns nil
        def index_offset(io, tag='indexListOffset', bytes_backwards=200)
          tag_re = %r{<#{tag}>([\-\d]+)</#{tag}>}
            io.pos = (io.size - 1) - bytes_backwards
          md = io.readlines("\n").map {|line| line.match(tag_re) }.compact.shift
          md[1].to_i if md
        end
      end

      # an index indexed by scan number
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
      def create_scan_to_index
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


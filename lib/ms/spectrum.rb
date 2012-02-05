require 'bsearch'

module MS
  class Spectrum
    include Enumerable

    # boolean for if the spectrum represents centroided data or not
    attr_accessor :centroided
    # The underlying data store. methods are implemented so that data[0] is
    # the m/z's and data[1] is intensities
    attr_reader :data
    
    # data takes an array: [mzs, intensities]
    # @return [MS::Spectrum]
    # @param [Array] data two element array of mzs and intensities
    def initialize(data)
      @data = data
    end

    def self.from_peaks(ar_of_doublets)
      _mzs = []
      _ints = []
      ar_of_doublets.each do |mz, int|
        _mzs << mz
        _ints << int
      end
      self.new([_mzs, _ints])
    end

    # found by querying the size of the data store.  This should almost always
    # be 2 (m/z and intensities)
    def size
      @data.size
    end

    def ==(other)
      mzs == other.mzs && intensities == other.intensities
    end
      
    # An array of the mz data.
    def mzs
      @data[0]
    end
      
    # An array of the intensities data, corresponding to mzs.
    def intensities
      @data[1]
    end

    def mzs_and_intensities
      [@data[0], @data[1]]
    end

    # retrieve an m/z and intensity doublet at that index
    def [](array_index)
      [@data[0][array_index], @data[1][array_index]]
    end

    # yields(mz, inten) across the spectrum, or array of doublets if no block
    def peaks(&block)
      @data[0].zip(@data[1], &block)
    end

    alias_method :each, :peaks
    alias_method :each_peak, :peaks

    # if the mzs and intensities are the same then the spectra are considered
    # equal
    def ==(other)
      mzs == other.mzs && intensities == other.intensities
    end

    # returns a new spectrum whose intensities have been normalized by the tic
    # of another given value
    def normalize(norm_by=:tic)
      norm_by = tic if norm_by == :tic
      MS::Spectrum.new([self.mzs, self.intensities.map {|v| v / norm_by }])
    end

    def tic
      self.intensities.reduce(:+)
    end

    # ensures that the m/z values are monotonically ascending (some
    # instruments are bad about this)
    # returns self
    def sort!
      _peaks = peaks.to_a
      _peaks.sort!
      _peaks.each_with_index {|(mz,int), i| @data[0][i] = mz ; @data[1][i] = int }
      self
    end

    # returns the m/z that is closest to the value, favoring the lower m/z in
    # the case of a tie. Uses a binary search.
    def find_nearest(val)
      mzs[find_nearest_index(val)]
    end

    # same as find_nearest but returns the index of the peak
    def find_nearest_index(val)
      find_all_nearest_index(val).first
    end

    def find_all_nearest_index(val)
      _mzs = mzs
      index = _mzs.bsearch_lower_boundary {|v| v <=> val }
      if index == _mzs.size
        [_mzs.size-1]
      else
        # if the previous m/z diff is smaller, use it
        if index == 0
          [index]
        else
          case (val - _mzs[index-1]).abs <=> (_mzs[index] - val).abs
          when -1
            [index-1]
          when 0
            [index-1, index]
          when 1
            [index]
          end
        end
      end
    end

    def find_all_nearest(val)
      find_all_nearest_index(val).map {|i| mzs[i] }
    end

    # returns a new spectrum which has been merged with the others.  If the
    # spectra are centroided (just checks the first one and assumes the others
    # are the same) then it will bin the peaks (peak width determined by
    # opts[:resolution]) and then segment according to monotonicity (sharing
    # intensity between abutting peaks).  The  final m/z is the weighted
    # averaged of all the m/z's in each peak.  Valid opts (with default listed
    # first):
    #
    #     :bin_width => 5,
    #     :bin_unit => :ppm | :amu
    #
    # The binning algorithm is the fastest possible algorithm that would allow
    # for arbitrary, non-constant bin widths (a ratcheting algorithm O(n + m))
    def self.merge(spectra, opts={})

    end

  end
end


  


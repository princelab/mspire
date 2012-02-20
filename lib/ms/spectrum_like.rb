module MS
  module SpectrumLike
    include Enumerable

    attr_accessor :products
    attr_accessor :precursors
    attr_accessor :scans
    attr_accessor :ms_level

    # boolean for if the spectrum represents centroided data or not
    attr_accessor :centroided

    # The underlying data store. methods are implemented so that data[0] is
    # the m/z's and data[1] is intensities
    attr_accessor :data

    def centroided?() centroided end

    # data takes an array: [mzs, intensities]
    # @return [MS::Spectrum]
    # @param [Array] data two element array of mzs and intensities
    def initialize(data, centroided=true)
      @data = data
      @centroided = centroided
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
    def points(&block)
      @data[0].zip(@data[1], &block)
    end

    alias_method :each, :points
    alias_method :each_point, :points

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
      _points = points.to_a
      _points.sort!
      _points.each_with_index {|(mz,int), i| @data[0][i] = mz ; @data[1][i] = int }
      self
    end

    # returns the m/z that is closest to the value, favoring the lower m/z in
    # the case of a tie. Uses a binary search.
    def find_nearest(val)
      mzs[find_nearest_index(val)]
    end

    # same as find_nearest but returns the index of the point
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

    # uses MS::Spectrum.merge
    def merge(other_spectra, opts={})
      MS::Spectrum.merge([self, *other_spectra], opts)
    end
  end
end

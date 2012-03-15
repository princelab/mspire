module Mspire
  module SpectrumLike
    include Enumerable

    attr_accessor :products
    attr_accessor :precursors
    attr_accessor :scans
    attr_accessor :ms_level

    # boolean for if the spectrum represents centroided data or not
    attr_accessor :centroided

    # The underlying data store. methods are implemented so that data_arrays[0] is
    # the m/z's and data_arrays[1] is intensities
    attr_accessor :data_arrays


    def centroided?() centroided end

    # @return [Mspire::Spectrum]
    # @param [Array] data two element array of mzs and intensities
    # @param [Boolean] centroided is the spectrum centroided or not
    def initialize(data_arrays, centroided=true)
      @data_arrays = data_arrays
      @centroided = centroided
    end

       # found by querying the size of the data store.  This should almost always
    # be 2 (m/z and intensities)
    def size
      @data_arrays.size
    end

    def ==(other)
      mzs == other.mzs && intensities == other.intensities
    end
      
    # An array of the mz data.
    def mzs
      @data_arrays[0]
    end

    def mzs=(ar)
      @data_arrays[0] = ar
    end
      
    # An array of the intensities data, corresponding to mzs.
    def intensities
      @data_arrays[1]
    end

    def intensities=(ar)
      @data_arrays[1] = ar
    end

    def mzs_and_intensities
      [@data_arrays[0], @data_arrays[1]]
    end

    # retrieve an m/z and intensity doublet at that index
    def [](array_index)
      [@data_arrays[0][array_index], @data_arrays[1][array_index]]
    end

    # yields(mz, inten) across the spectrum, or array of doublets if no block
    def points(&block)
      @data_arrays[0].zip(@data_arrays[1], &block)
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
      Mspire::Spectrum.new([self.mzs, self.intensities.map {|v| v / norm_by }])
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
      _points.each_with_index {|(mz,int), i| @data_arrays[0][i] = mz ; @data_arrays[1][i] = int }
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

    # uses Mspire::Spectrum.merge
    def merge(other_spectra, opts={})
      Mspire::Spectrum.merge([self, *other_spectra], opts)
    end
  end
end

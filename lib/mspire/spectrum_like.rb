require 'bsearch'

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

    # yields(mz, inten) across the spectrum, or array of doublets if no block.
    # Note that each peak is merely an array of m/z and intensity.  For a
    # genuine 
    def peaks(&block)
      @data_arrays[0].zip(@data_arrays[1], &block)
    end

    alias_method :each, :peaks
    alias_method :each_peak, :peaks

    # returns a bonafide Peaklist object (i.e., each peak is cast as a
    # Mspire::Peak object).  If peak_id is defined, each peak will be cast
    # as a TaggedPeak object with the given peak_id
    def to_peaklist(peak_id=nil)
      # realize this isn't dry, but it is in such an inner loop it needs to be
      # as fast as possible.
      pl = Peaklist.new
      if peak_id
        peaks.each_with_index do |peak,i|
          pl[i] = Mspire::Peak.new( peak )
        end
      else
        peaks.each_with_index do |peak,i|
          pl[i] = Mspire::TaggedPeak.new( peak, peak_id )
        end
      end
      pl
    end

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
      _peaks = peaks.to_a
      _peaks.sort!
      _peaks.each_with_index {|(mz,int), i| @data_arrays[0][i] = mz ; @data_arrays[1][i] = int }
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

  end
end

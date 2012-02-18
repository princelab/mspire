require 'bsearch'
require 'bin'
require 'ms/peak'

module MS
  # note that a point is an [m/z, intensity] doublet.
  # A peak is considered a related string of points
  class Spectrum
    include Enumerable

    DEFAULT_MERGE = {
      :bin_width => 5,
      :bin_unit => :ppm,
      :normalize => true,
      :return_data => false,
      :split => :share
    }

    # returns a new spectrum which has been merged with the others.  If the
    # spectra are centroided (just checks the first one and assumes the others
    # are the same) then it will bin the points (bin width determined by
    # opts[:resolution]) and then segment according to monotonicity (sharing
    # intensity between abutting points).  The  final m/z is the weighted
    # averaged of all the m/z's in each peak.  Valid opts (with default listed
    # first):
    #
    #     :bin_width => 5 
    #     :bin_unit => :ppm | :amu        interpret bin_width as ppm or amu
    #     :bins => array of Bin objects   for custom bins (overides other bin options)
    #     :normalize => false             if true, divides total intensity by 
    #                                     number of spectra
    #     :return_data => false           returns a parallel array containing
    #                                     the peaks associated with each returned point
    #     :split => :share | :greedy_y    see MS::Peak#split
    #
    # The binning algorithm is the fastest possible algorithm that would allow
    # for arbitrary, non-constant bin widths (a ratcheting algorithm O(n + m))
    def self.merge(spectra, opts={})
      opt = DEFAULT_MERGE.merge(opts)
      (spectrum, returned_data) =  
        if spectra.first.centroided?
          # find the min and max across all spectra
          first_mzs = spectra.first.mzs
          min = first_mzs.first ; max = first_mzs.last
          spectra.each do |spectrum| 
            mzs = spectrum.mzs
            min = mzs.first if mzs.first < min
            max = mzs.last if mzs.last > max
          end

          # Create Bin objects
          bins = 
            if opt[:bins]
              opt[:bins]
            else
              divisions = []
              bin_width = opt[:bin_width]
              use_ppm = (opt[:bin_unit] == :ppm)
              current_mz = min
              loop do
                if current_mz >= max
                  divisions << max
                  break
                else
                  divisions << current_mz
                  current_mz += ( use_ppm ? current_mz./(1e6).*(bin_width) : bin_width )
                end
              end
              # make each bin exclusive so there is no overlap
              bins = divisions.each_cons(2).map {|pair| Bin.new(*pair, true) }
              # make the last bin *inclusive* of the terminating value
              bins[-1] = Bin.new(bins.last.begin, bins.last.end)
              bins
            end

          spectra.each do |spectrum|
            Bin.bin(bins, spectrum.points, &:first)
          end

          pseudo_points = bins.map do |bin|
            #int = bin.data.reduce(0.0) {|sum,point| sum + point.last }.round(3)   # <- just for info:
            [bin, bin.data.reduce(0.0) {|sum,point| sum + point.last }]
          end

          #p_mzs = [] 
          #p_ints = [] 
          #p_num_points = [] 
          #pseudo_points.each do |psp|
          #  p_mzs << ((psp.first.begin + psp.first.end)/2)
          #  p_ints << psp.last
          #  p_num_points <<  psp.first.data.size
          #end

          #File.write("file_#{opt[:bin_width]}_to_plot.txt", [p_mzs, p_ints, p_num_points].map {|ar| ar.join(' ') }.join("\n"))
          #abort 'here'


          peaks = MS::Peak.new(pseudo_points).split(opt[:split])

          return_data = []
          _mzs = [] ; _ints = []

          #p peaks[97]
          #puts "HIYA"
          #abort 'here'

          peaks.each_with_index do |peak,i|
          #peaks.each do |peak|
            tot_intensity = peak.map(&:last).reduce(:+)
            return_data_per_peak = [] if opt[:return_data]
            weighted_mz = 0.0
            peak.each do |point|
              pre_scaled_intensity = point[0].data.reduce(0.0) {|sum,v| sum + v.last }
              post_scaled_intensity = point[1]
              # some peaks may have been shared.  In this case the intensity
              # for that peak was downweighted.  However, the actually data
              # composing that peak is not altered when the intensity is
              # shared.  So, to calculate a proper weighted avg we need to
              # downweight the intensity of any data point found within a bin
              # whose intensity was scaled.
              correction_factor = 
                if pre_scaled_intensity != post_scaled_intensity
                  post_scaled_intensity / pre_scaled_intensity
                else
                  1.0
                end

              return_data_per_peak.push(*point[0].data) if opt[:return_data]

              point[0].data.each do |lil_point|
                weighted_mz += lil_point[0] * ( (lil_point[1].to_f * correction_factor) / tot_intensity)
              end
            end
            return_data << return_data_per_peak if opt[:return_data]
            _mzs << weighted_mz
            _ints << tot_intensity
          end
          [Spectrum.new([_mzs, _ints]), return_data]
        else
          raise NotImplementedError, "the way to do this is interpolate the profile evenly and sum"
        end

      if opt[:normalize]
        sz = spectra.size
        spectrum.data[1].map! {|v| v.to_f / sz }
      end
      if opt[:return_data]
        $stderr.puts "returning spectrum (#{spectrum.mzs.size}) and data" if $VERBOSE
        [spectrum, return_data]
      else
        $stderr.puts "returning spectrum (#{spectrum.mzs.size})" if $VERBOSE
        spectrum
      end
    end

    attr_accessor :parents
    attr_accessor :precursors
    attr_accessor :scans
    attr_accessor :ms_level

    # boolean for if the spectrum represents centroided data or not
    attr_accessor :centroided

    def centroided?() centroided end

    # The underlying data store. methods are implemented so that data[0] is
    # the m/z's and data[1] is intensities
    attr_reader :data
    



    # data takes an array: [mzs, intensities]
    # @return [MS::Spectrum]
    # @param [Array] data two element array of mzs and intensities
    def initialize(data, centroided=true)
      @data = data
      @centroided = centroided
    end

    def self.from_points(ar_of_doublets)
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


  


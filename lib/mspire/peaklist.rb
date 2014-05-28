require 'mspire/bin'
require 'mspire/peak'

module Mspire
  # a collection of Peak objects.  At a minimum, each peak should respond to
  # :x and :y
  class Peaklist < Array

    def lo_x
      self.first[0] if size > 0
    end

    def hi_x
      self.last[0] if size > 0
    end

    DEFAULT_MERGE = {
      :bin_width => 5,
      :bin_unit => :ppm,
      :normalize => true,
      :return_data => false,
      :split => :share,
      :centroided => true,
    }

    # for spectral peaks, this is the weighted m/z
    def weighted_x
      tot_intensity = self.inject(0.0) {|sum,peak| sum + peak.y }
      _weighted_x = 0.0
      self.each do |peak|
        int = peak.y
        signal_by_sample_index[peak.sample_id] += int
        _weighted_x += (peak.first * (int/tot_intensity))
      end
      _weighted_x
    end

    # class methods
    class << self

      # creates a new Mspire::Peaklist and coerces each peak into an
      # Mspire::Peak.  If your peaks already behave like peaks you should use
      # .new
      def [](*peaks)
        self.new( peaks.map {|peak| Mspire::Peak.new(peak) } )
      end

      def create_bins(peaklists, opts)
        min, max = min_max_x(peaklists)

        divisions = []
        bin_width = opts[:bin_width]
        use_ppm = (opts[:bin_unit] == :ppm)

        puts "using bin width: #{bin_width}" if $VERBOSE
        puts "using ppm for bins: #{use_ppm}" if $VERBOSE

        current_x = min
        loop do
          if current_x >= max
            divisions << max
            break
          else
            divisions << current_x
            current_x += ( use_ppm ? current_x./(1e6).*(bin_width) : bin_width )
          end
        end
        # make each bin exclusive so there is no overlap
        bins = divisions.each_cons(2).map {|pair| Mspire::Bin.new(*pair, true) }
        # make the last bin *inclusive* of the terminating value
        bins[-1] = Mspire::Bin.new(bins.last.begin, bins.last.end)
        bins
      end

      def min_max_x(peaklists)
        # find the min and max across all spectra
        first_peaklist = peaklists.first
        min = first_peaklist.first.x; max = first_peaklist.last.x
        peaklists.each do |peaklist|
          if peaklist.size > 0
            min = peaklist.lo_x if peaklist.lo_x < min
            max = peaklist.hi_x if peaklist.hi_x > max
          end
        end
        [min, max]
      end

      def merge_centroids(peaklists, opts={})
        opts[:return_data] = true if opts[:only_data]

        # Create Mspire::Bin objects
        bins = opts[:bins] ? opts[:bins] : create_bins(peaklists, opts)
        puts "created #{bins.size} bins" if $VERBOSE

        peaklists.each do |peaklist|
          Mspire::Bin.bin(bins, peaklist, &:x)
        end

        pseudo_peaks = bins.map do |bin|
          Mspire::Peak.new( [bin, bin.data.reduce(0.0) {|sum,peak| sum + peak.y }] )
        end

        pseudo_peaklist = Mspire::Peaklist.new(pseudo_peaks)

        separate_peaklists = pseudo_peaklist.split(opts[:split])

        normalize_factor = opts[:normalize] ? peaklists.size : 1

        return_data = []
        final_peaklist = Mspire::Peaklist.new unless opts[:only_data]

        separate_peaklists.each do |pseudo_peaklist|
          data_peaklist = Mspire::Peaklist.new
          weight_x = 0.0
          tot_intensity = pseudo_peaklist.inject(0.0) {|sum, bin_peak| sum + bin_peak.y }
          #puts "TOT INTENSITY:"
          #p tot_intensity
          calc_from_lil_bins = pseudo_peaklist.inject(0.0) {|sum, bin_peak| sum + bin_peak.x.data.map(&:y).reduce(:+) }
          #puts "LILBINS: "
          #p calc_from_lil_bins
          pseudo_peaklist.each do |bin_peak|

            # For the :share method, the psuedo_peak intensity may have been
            # adjusted, but the individual peaks were not.  Correct this.             
            if opts[:split] == :share
              post_scaled_y = bin_peak.y
              pre_scaled_y = bin_peak.x.data.reduce(0.0) {|sum,peak| sum + peak.last }
              #puts "PRESCALED Y:"
              #p pre_scaled_y
              if (post_scaled_y - pre_scaled_y).abs.round(10) != 0.0
                correction = post_scaled_y / pre_scaled_y
                bin_peak.x.data.each {|peak| peak.y = (peak.y * correction) }
              end
            end

            unless opts[:only_data]
              bin_peak.x.data.each do |peak|
                weight_x += peak.x * ( peak.y.to_f / tot_intensity)
              end
            end
            (data_peaklist.push( *bin_peak.x.data )) if opts[:return_data]
          end
          final_peaklist << Mspire::Peak.new([weight_x, tot_intensity / normalize_factor]) unless opts[:only_data]
          return_data << data_peaklist if opts[:return_data]
        end
        [final_peaklist, return_data]
      end

      # returns a new peaklist which has been merged with the others. 
      # opts[:resolution]) and then segment according to monotonicity (sharing
      # intensity between abutting points).  The  final m/z is the weighted
      # averaged of all the m/z's in each peak.  Valid opts (with default listed
      # first):
      #
      #     :bin_width => 5 
      #     :bin_unit => :ppm|:amu        interpret bin_width as ppm or amu
      #     :bins => array of Mspire::Bin objects  for custom bins (overides other bin options)
      #     :normalize => true              if true, divides total intensity by 
      #                                     number of spectra
      #     :return_data => false           returns a parallel array containing
      #                                     the peaks associated with each returned peak
      #     :only_data => false           only returns the binned peaks
      #     :split => :zero|:greedy_y|:share  see Mspire::Peak#split
      #     :centroided => true             treat the data as centroided
      #
      # The binning algorithm is roughly the fastest possible algorithm that
      # would allow for arbitrary, non-constant bin widths (a ratcheting
      # algorithm O(n + m))
      #
      # Assumes the peaklists are already sorted by m/z.
      #
      # Note that the peaks themselves will be altered if using the :share
      # split method.
      def merge(peaklists, opts={})
        opts = DEFAULT_MERGE.merge(opts)

        (peaklist, returned_data) =  
          if opts[:centroided]
            merge_centroids(peaklists, opts.dup)
          else
            raise NotImplementedError, "need to implement profile merging"
          end

        if opts[:only_data]
          returned_data
        elsif opts[:return_data]
          [peaklist, returned_data]
        else
          peaklist
        end
      end

      # takes an array of peaklists, merges them together (like merge), then
      # returns an array of doublets.  Each doublet is an m/z and an array of
      # values (parallel to input) of intensities]
      #
      # If you are already using tagged peak objects, then you should set
      # have_tagged_peaks to false (default is true).  The peaks will be
      # deconvolved based on the sample_id in this case.
      #
      #     :have_tagged_peaks => false|true
      #
      def merge_and_deconvolve(peaklists, opts={})
        unless htp=opts.delete(:have_tagged_peaks)
          peaklists.each_with_index do |peaklist,i|
            peaklist.map! do |peak|
              TaggedPeak.new(peak, i)
            end
          end
        end

        # make sure we get the data back out
        opts[:return_data] = true
        opts[:only_data] = false

        sample_ids = peaklists.map {|pl| pl.first.sample_id }
        peaks, data = merge(peaklists, opts)
        data.zip(peaks).map do |bucket_of_peaks, meta_peak|
          signal_by_sample_id = Hash.new {|h,k| h[k] = 0.0 }
          bucket_of_peaks.each do |peak|
            signal_by_sample_id[peak.sample_id] += peak.y
          end
          [meta_peak.x, sample_ids.map {|sample_id| signal_by_sample_id[sample_id] } ]
        end
      end

    end # end class << self

    # returns an array with the indices outlining each peak.  The first index
    # is the start of the peak, the last index is the last of the peak.
    # Interior indices represent local minima.  So, peaks that have only two
    # indices have no local minima.
    def peak_boundaries(gt=0.0)
      in_peak = false
      prev_y = gt
      prev_prev_y = gt
      peak_inds = []
      self.each_with_index do |peak, index|
        curr_y = peak.y
        if curr_y > gt
          if !in_peak
            in_peak = true
            peak_inds << [index]
          else
            # if on_upslope
            if prev_y < curr_y
              # If we were previously on a downslope and we are now on an upslope
              # then the previous index is a local min
              # on_downslope(prev_previous_y, prev_y)
              if prev_prev_y > prev_y
                # We have found a local min
                peak_inds.last << (index - 1)
              end
            end # end if (upslope)
          end # end if !in_peak
        elsif in_peak
          peak_inds.last << (index - 1)
          in_peak = false
        end 
        prev_prev_y = prev_y
        prev_y = curr_y
      end
      # add the last one to the last peak if it is a boundary
      if self[-1].y > gt
        peak_inds.last << (self.size-1)
      end
      peak_inds
    end

    # returns an array of Peaklist objects
    def split_on_zeros(given_peak_boundaries=nil)
      pk_bounds = given_peak_boundaries || peak_boundaries(0.0)
      pk_bounds.map do |indices|
        self.class.new self[indices.first..indices.last]
      end
    end

    # returns an array of Peaklist objects
    # assumes that this is one connected list of peaks (i.e., no
    # zeros/whitespace on the edges or internally)
    #
    #       /\       
    #      /  \/\
    #     /      \
    #
    # if there are no local minima, just returns self inside the array
    def split_contiguous(methd=:greedy_y, local_min_indices=nil)
      local_min_indices ||= ((pb=peak_boundaries.first) && pb.shift && pb.pop && pb)

      if local_min_indices.size == 0
        self
      else
        peak_class = first.class
        prev_lm_i = 0  # <- don't worry, will be set to bumped to zero
        peaklists = [ self.class.new([self[0]]) ]
        local_min_indices.each do |lm_i|
          peaklists.last.push( *self[(prev_lm_i+1)..(lm_i-1)] )
          case methd
          when :greedy_y
            if self[lm_i-1].y >= self[lm_i+1].y
              peaklists.last << self[lm_i]
              peaklists << self.class.new
            else
              peaklists << self.class.new( [self[lm_i]] )
            end
          when :share
            # for each local min, two new peaks will be created, with
            # intensity shared between adjacent peaklists
            lm = self[lm_i]
            sum = self[lm_i-1].y + self[lm_i+1].y
            # push onto the last peaklist its portion of the local min
            peaklists.last << peak_class.new( [lm.x, lm.y * (self[lm_i-1].y.to_f/sum)] )
            # create a new peaklist that contains its portion of the local min
            peaklists << self.class.new( [peak_class.new([lm.x, lm.y * (self[lm_i+1].y.to_f/sum)])] )
          end
          prev_lm_i = lm_i
        end
        peaklists.last.push(*self[(prev_lm_i+1)...(self.size)] )
        peaklists
      end
    end

    # returns an Array of peaklist objects.  Splits run of 1 or more local
    # minima into multiple peaklists.  When a point is 'shared' between two
    # adjacent hill-ish areas, the choice of how to resolve multi-hills (runs
    # of data above zero) is one of:
    #
    #     :zero = only split on zeros
    #     :share = give each peak its rightful portion of shared peaks, dividing the
    #               intensity based on the intensity of adjacent peaks
    #     :greedy_y = give the point to the peak with highest point next to
    #                  the point in question. tie goes lower.
    #
    # Note that the peak surrounding a local_minima may be altered if using
    # :share
    #
    # assumes that a new peak can be made with an array containing the x
    # value and the y value.
    def split(split_multipeaks_mthd=:zero)
      if split_multipeaks_mthd == :zero
        split_on_zeros
      else
        boundaries = peak_boundaries(0.0)
        no_lm_pklsts = []
        boundaries.each do |indices|
          peak = self[indices.first..indices.last]
          if indices.size == 2
            no_lm_pklsts << peak
          else # have local minima
            multipeak = Peaklist.new(peak)
            local_min_inds = indices[1..-2].map {|i| i-indices.first}
            peaklists = multipeak.split_contiguous(split_multipeaks_mthd, local_min_inds)
            no_lm_pklsts.push *peaklists
          end
        end
        #$stderr.puts "now #{no_lm_pklsts.size} peaks." if $VERBOSE
        no_lm_pklsts 
      end 
    end # def split

    # returns an Mspire::Spectrum object
    def to_spectrum
      Mspire::Spectrum.new(self.transpose)
    end
  end
end



=begin
if !opts[:only_data]
=end


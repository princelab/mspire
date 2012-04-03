require 'mspire/bin'

module Mspire
  # a collection of peak objects.  At a minimum, each peak should respond to
  # :x and :y
  class PeakList < Array

    def lo_x
      self.first[0]
    end

    def hi_x
      self.last[0]
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

    class << self

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
          min = peaklist.lo_x if peaklist.lo_x < min
          max = peaklist.hi_x if peaklist.hi_x > max
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
          [bin, bin.data.reduce(0.0) {|sum,peak| sum + peak.y }]
        end

        pseudo_peaklist = Mspire::PeakList.new(pseudo_peaks)

        separate_peaklists = pseudo_peaklist.split(opts[:split])

        return_data = []
        final_peaklist = []
        separate_peaklists.each_with_index do |peak_list,i|
          #peaks.each do |peak|
          tot_y = peak_list.map(&:last).reduce(:+) unless opts[:only_data]
          return_data_per_peak = [] if opts[:return_data]
          weighted_x = 0.0
          peak_list.each do |peak|
            if !opts[:only_data]
              pre_scaled_y = peak[0].data.reduce(0.0) {|sum,v| sum + v.last }
              post_scaled_y = peak[1]
              # some peaks may have been shared.  In this case the intensity
              # for that peak was downweighted.  However, the actual data
              # composing that peak is not altered when the intensity is
              # shared.  So, to calculate a proper weighted avg we need to
              # downweight the intensity of any data point found within a bin
              # whose intensity was scaled.
              correction_factor = 
                if pre_scaled_y != post_scaled_y
                  post_scaled_y / pre_scaled_y
                else
                  1.0
                end


              peak[0].data.each do |lil_point|
                weighted_x += lil_point[0] * ( (lil_point[1].to_f * correction_factor) / tot_y)
              end
            end
            if opts[:return_data]
              return_data_per_peak.push(*peak[0].data) 
            end
          end
          return_data << return_data_per_peak if opts[:return_data]
          final_peaklist << Mspire::Peak.new([weighted_x, tot_y]) unless opts[:only_data]
        end
        [final_peaklist, return_data]
      end

      # returns a new peak_list which has been merged with the others. 
      # opts[:resolution]) and then segment according to monotonicity (sharing
      # intensity between abutting points).  The  final m/z is the weighted
      # averaged of all the m/z's in each peak.  Valid opts (with default listed
      # first):
      #
      #     :bin_width => 5 
      #     :bin_unit => :ppm | :amu        interpret bin_width as ppm or amu
      #     :bins => array of Mspire::Bin objects  for custom bins (overides other bin options)
      #     :normalize => true              if true, divides total intensity by 
      #                                     number of spectra
      #     :return_data => false           returns a parallel array containing
      #                                     the peaks associated with each returned peak
      #     :split => false | :share | :greedy_y   see Mspire::Peak#split
      #     :centroided => true             treat the data as centroided
      #
      # The binning algorithm is roughly the fastest possible algorithm that
      # would allow for arbitrary, non-constant bin widths (a ratcheting
      # algorithm O(n + m))
      #
      # Assumes the peaklists are already sorted by m/z.
      def merge(peaklists, opts={})
        opts = DEFAULT_MERGE.merge(opts)

        (peaklist, returned_data) =  
          if opts[:centroided]
            merge_centroids(peaklists, opts.dup)
          else
            raise NotImplementedError, "need to implement profile merging"
          end

        if opts[:normalize]
          sz = peaklists.size
          peaklist.each {|peak| peak[1] = peak[1].to_f / sz }
        end
        if opts[:return_data]
          $stderr.puts "returning peaklist (#{peaklist.size}) and data" if $VERBOSE
          [peaklist, returned_data]
        else
          $stderr.puts "returning peaklist (#{peaklist.size})" if $VERBOSE
          peaklist 
        end
        if opts[:only_data]
          returned_data
        elsif opts[:return_data]
          [peaklist, returned_data]
        else
          peaklist
        end
      end
    end


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
      peak_inds
    end

    # returns an array of PeakList objects
    def split_on_zeros(given_peak_boundaries=nil)
      pk_bounds = given_peak_boundaries || peak_boundaries(0.0)
      pk_bounds.map do |indices|
        self.class.new self[indices.first..indices.last]
      end
    end

    # returns an array of PeakList objects
    def split_multipeak(methd=:greedy_y, boundaries=nil)
      boundaries ||= peak_boundaries.first
      p boundaries
      local_minima_indices = boundaries
      zero = local_minima_indices.shift 
      _last = local_minima_indices.pop

      prev_lm_i = -1  # <- don't worry, will be set to bumped to zero
      peak_lists = [self.class.new([self[0]]) ]
      local_minima_indices.each do |lm_i|
        peak_lists.last.push( *self[(prev_lm_i+1)..(lm_i-1)] )
        case methd
        when :greedy_y
          if self[lm_i-1].y >= self[lm_i+1].y
            peak_lists.last << self[lm_i]
            peak_lists << self.class.new
          else
            peak_lists << self.class.new( [self[lm_i]] )
          end
          prev_lm_i = lm_i
        when :share
          abort 'not implemented yet'
        end
      end
      peak_lists
    end

    # returns an Array of peaklist objects.  Splits run of 1 or more local
    # minima into multiple peaklists.  When a point is 'shared' between two
    # adjacent hill-ish areas, the choice of how to resolve multi-hills (runs
    # of data above zero) is one of:
    #
    #     false/nil = only split on zeros
    #     :share = give each peak its rightful portion of shared peaks, dividing the
    #               intensity based on the intensity of adjacent peaks
    #     :greedy_y = give the point to the peak with highest point next to
    #                  the point in question. tie goes lower.
    #
    # Note that local_minima may be altered if using :share
    #
    # assumes that a new peak can be made with an array containing the x
    # value and the y value.
    def split(split_multipeaks_mthd=false)
      if split_multipeaks_mthd
        boundaries = peak_boundaries(0.0)
        no_lm_pklsts = []
        boundaries.each do |indices|
          peak = self[indices.first..indices.last]
          if indices.size == 2
            no_lm_pklsts << peak
          else # have local minima
            multipeak = PeakList.new(peak)
            indices_first = indices.first
            peaklists = multipeak.split_multipeak(split_multipeaks_mthd, indices.map {|i| i-indices_first})
            no_lm_pklsts.push *peaklists
          end
        end
        #$stderr.puts "now #{no_lm_pklsts.size} peaks." if $VERBOSE
        no_lm_pklsts 
      else
        split_on_zeros
      end 
    end # def split
  end
end



=begin

          if lm_indices.size > 0
            prev_lm_i = -1   # <- it's okay, we don't use until it is zero
            lm_indices.each do |lm_i|
              lm = peak[lm_i]
              point_class = lm.class

              # push onto the last peak all the points from right after the previous local min
              # to just before this local min
              new_peaks.last.push( *peak[(prev_lm_i+1)..(lm_i-1)] )
              before_pnt = peak[lm_i-1]
              after_pnt = peak[lm_i+1]

              case split_multipeaks
              when :share
                sum = before_pnt[1] + after_pnt[1]
                # push onto the last peak its portion of the local min
                new_peaks.last << point_class.new( [lm[0], lm[1] * (before_pnt[1].to_f/sum)] )
                # create a new peak that contains its portion of the local min
                new_peaks << self.class.new( [point_class.new([lm[0], lm[1] * (after_pnt[1].to_f/sum)])] )
                prev_lm_i = lm_i
              when :greedy_y
                if before_pnt[1] >= after_pnt[1]
                  new_peaks.last << lm
                  new_peaks << self.class.new
                  prev_lm_i = lm_i
                else
                  new_peaks << self.class.new( [lm] )
                  prev_lm_i = lm_i
                end
              else
                raise ArgumentError, "only recognize :share, :greedy_y, or false for the arg in #split(arg)"
              end
            end
            new_peaks.last.push( *peak[(prev_lm_i+1)...peak.size] )
            new_peaks
          end
        end.flatten(1) # end zip
        $stderr.puts "now #{no_local_minima_peaks.size} peaks." if $VERBOSE
        no_local_minima_peaks 
=end

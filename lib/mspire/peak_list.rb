require 'mspire/bin'

module Mspire
  # a collection of peak objects
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

    class << self

      def create_bins(peaklists, opts)
        min, max = min_max_mz(peaklists)

        divisions = []
        bin_width = opts[:bin_width]
        use_ppm = (opts[:bin_unit] == :ppm)
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
        bins = divisions.each_cons(2).map {|pair| Mspire::Bin.new(*pair, true) }
        # make the last bin *inclusive* of the terminating value
        bins[-1] = Mspire::Bin.new(bins.last.begin, bins.last.end)
        bins
      end

      def min_max_mz(peaklists)
        # find the min and max across all spectra
        first_peaklist = peaklists.first
        min = first_peaklist.first[0]; max = first_peaklist.last[0]
        peaklists.each do |peaklist|
          min = peaklist.lo_x if peaklist.lo_x < min
          max = peaklist.hi_x if peaklist.hi_x > max
        end
        [min, max]
      end

      def merge_centroids(peaklists, opts={})

        # Create Mspire::Bin objects
        bins = opts[:bins] ? opts[:bins] : create_bins(peaklists, opts)

        peaklists.each do |peaklist|
          Mspire::Bin.bin(bins, peaklist, &:first)
        end

        pseudo_peaks = bins.map do |bin|
          [bin, bin.data.reduce(0.0) {|sum,peak| sum + peak[1] }]
        end

        pseudo_peaklist = Mspire::PeakList.new(pseudo_peaks)

        peak_lists = pseudo_peaklist.split(opts[:split])

        return_data = []
        final_peaklist = []
        peak_lists.each_with_index do |peak_list,i|
          #peaks.each do |peak|
          tot_intensity = peak_list.map(&:last).reduce(:+)
          return_data_per_peak = [] if opts[:return_data]
          weighted_mz = 0.0
          peak_list.each do |peak|
            pre_scaled_intensity = peak[0].data.reduce(0.0) {|sum,v| sum + v.last }
            post_scaled_intensity = peak[1]
            # some peaks may have been shared.  In this case the intensity
            # for that peak was downweighted.  However, the actual data
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

            return_data_per_peak.push(*peak[0].data) if opts[:return_data]

            peak[0].data.each do |lil_point|
              weighted_mz += lil_point[0] * ( (lil_point[1].to_f * correction_factor) / tot_intensity)
            end
          end
          return_data << return_data_per_peak if opts[:return_data]
          final_peaklist << Mspire::Peak.new([weighted_mz, tot_intensity])
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
            merge_centroids(peaklists, opts)
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
      end
    end


    # returns an Array of peaklist objects.  Splits run of 1 or more local
    # minima into multiple peaklists.  When a point is 'shared' between two
    # adjacent hill-ish areas, the choice of how to resolve multi-hills (runs
    # of data above zero) is one of:
    #
    #     false/nil => only split on zeros
    #     :share => give each peak its rightful portion of shared peaks, dividing the
    #               intensity based on the intensity of adjacent peaks
    #     :greedy_y => give the point to the peak with highest point next to
    #                  the point in question. tie goes lower.
    #
    # if return_local_minima is true, a parallel array of local minima indices is
    # returned (only makes sense if split_multipeaks is false)
    # 
    # assumes that a new peak can be made with an array containing the x
    # value and the y value.
    def split(split_multipeaks=false, return_local_minima=false)
      if split_multipeaks
        (zeroed_peaks, local_min_ind_ar) = self.split(false, true)
        $stderr.print "splitting on local minima ..." if $VERBOSE
        no_local_minima_peaks = zeroed_peaks.zip(local_min_ind_ar).map do |peak, lm_indices|
          new_peaks = [ peak.class.new ]
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
          else
            [peak]
          end
        end.flatten(1) # end zip
        $stderr.puts "now #{no_local_minima_peaks.size} peaks." if $VERBOSE
        no_local_minima_peaks 
      else
        $stderr.print "splitting on zeros..." if $VERBOSE
        # first, split the peaks based on zero intensity values 
        # and simultaneously keep track of the local minima within each
        # resulting peak
        peak_lists = []
        local_min_ind_ar = []
        in_peak = false
        self.each_with_index do |peak, index|
          previous_y = self[index - 1][1]
          if peak[1] > 0
            if !in_peak
              in_peak = 0
              peak_lists << self.class.new([peak])
              local_min_ind_ar << []
            else
              peak_lists.last << peak
              # if on_upslope(previous_y, point[1])
              if previous_y < peak[1]
                # If we were previously on a downslope and we are now on an upslope
                # then the previous index is a local min
                prev_previous_y = self[index - 2][1]
                # on_downslope(prev_previous_y, previous_y)
                if prev_previous_y > previous_y
                  # We have found a local min
                  local_min_ind_ar.last << (in_peak-1)
                end
              end # end if (upslope)
            end # end if !in_peak
            in_peak += 1
          elsif in_peak
            in_peak = false
          end # end if point[1] > 0
        end
        $stderr.puts "#{peak_lists.size} no-whitespace-inside peak_lists." if $VERBOSE
        return_local_minima ? [peak_lists, local_min_ind_ar] : peak_lists
      end # 
    end # def split
  end
end

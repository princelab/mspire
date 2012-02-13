
module MS ; end
# an MS::Peak instance is an array of contiguous points (where each point is
# a doublet: an x coordinate and a y coordinate)
class MS::Peak < Array

  # returns an Array of peaks.  Splits peak with 1 or more local minima into
  # multiple peaks.  When a point is 'shared' between two adjacent peak-ish
  # areas, the choice of how to resolve multi-peaks (runs of data above
  # zero) is one of:
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
  # assumes that a new point can be made with an array containing the x
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
      peaks = []
      local_min_ind_ar = []
      in_peak = false
      self.each_with_index do |point, index|
        previous_y = self[index - 1][1]
        if point[1] > 0
          if !in_peak
            in_peak = 0
            peaks << self.class.new([point])
            local_min_ind_ar << []
          else
            peaks.last << point
            # if on_upslope(previous_y, point[1])
            if previous_y < point[1]
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
      $stderr.puts "#{peaks.size} no-whitespace-inside peaks." if $VERBOSE
      return_local_minima ? [peaks, local_min_ind_ar] : peaks
    end # 
  end # def split
end

require 'rsruby'
require 'vec'
require 'vec/r'
require 'enumerator'


module PiZero
  class << self
    # takes a sorted array of p-values (floats between 0 and 1 inclusive)
    # returns [thresholds_ar, instantaneous pi_0 calculations_ar]
    # evenly incremented values will be used by default:
    # :start=>0.0, :stop=>0.9, :step=>0.01
    def pi_zero_hats(sorted_pvals, args={})
      defaults = {:start => 0.0, :stop=>0.9, :step=>0.05 }
      margs = defaults.merge( args )
      (start, stop, step) = margs.values_at(:start, :stop, :step)

      # From Storey et al. PNAS 2003:
      lambdas = []                 # lambda
      pi_zeros = []                # pi_0
      total = sorted_pvals.size  # m 

      # totally inefficient implementation (with correct logic):
      # TODO: implement this efficiently
      start.step(stop, step) do |lam|
        lambdas << lam
        (greater, less) = sorted_pvals.partition {|pval| pval > lam }
        pi_zeros.push( greater.size.to_f / ( total * (1.0 - lam) ) )
      end
      [lambdas, pi_zeros]
    end

=begin
    def plateau_height_with_gsl(x, y)
      require 'gsl'
      x_deltas = (0...(x.size-1)).to_a.map do |i|
        x[i+1] - x[i]
      end
      y_deltas = (0...(y.size-1)).to_a.map do |i|
        y[i+1] - y[i]
      end
      new_xs = x.dup
      new_ys = y.dup
      x_deltas.reverse.each do |delt|
        new_xs.push( new_xs.last + delt )
      end

      y_cnt = y.size
      y_deltas.reverse.each do |delt|
        y_cnt -= 1
        new_ys.push( y[y_cnt] - delt )
      end

      x_vec = GSL::Vector.alloc(new_xs)
      y_vec = GSL::Vector.alloc(new_ys)
      coef, cov, chisq, status = GSL::Poly.fit(x_vec,y_vec, 3)
      coef.eval(x.last)
      #x2 = GSL::Vector::linspace(0,2.4,20)
      #graph([x_vec,y_vec], [x2, coef.eval(x2)], "-C -g 3 -S 4")
    end
=end

    # expecting x and y to make a scatter plot descending to a plateau on the
    # right side (which is assumed to be of increasing noise as it goes to the
    # right)
    # returns the height of the plateau at the right edge
    #
    # *
    #   *
    #     *
    #       **
    #          ** ***         *    *
    #                    ***** **** ***
    def plateau_height(x, y)
      r = RSRuby.instance
      answ = r.smooth_spline(x,y, :df => 3)
      ## to plot it!
      r.plot(x,y, :ylab=>"pi_zeros or frit")
      r.lines(answ['x'], answ['y'])
      r.points(answ['x'], answ['y'])
      sleep(4)

      answ['y'].last
    end

    def plateau_exponential(x,y)
      require 'gsl'
      xvec = GSL::Vector.alloc(x)
      yvec = GSL::Vector.alloc(y)
      a2, b2, = GSL::Fit.linear(xvec, GSL::Sf::log(yvec))
      x2 = GSL::Vector.linspace(0, 1.2, 20)
      exp_a = GSL::Sf::exp(a2)
      out_y = exp_a*GSL::Sf::exp(b2*x2)
      raise NotImplementedError, "need to grab out the answer"
      #graph([xvec, yvec], [x2, exp_a*GSL::Sf::exp(b2*x2)], "-C -g 3 -S 4")

    end

    # returns a conservative (but close) estimate of pi_0 given sorted p-values
    # following Storey et al. 2003, PNAS.
    def pi_zero(sorted_pvals)
      plateau_height( *(pi_zero_hats(sorted_pvals)) )
    end

    # returns an array where the left values have been filled in using the
    # similar values on the right side of the distribution.  These values are
    # pushed onto the end of the array in no guaranteed order.
    # extends a distribution on the left side where it is missing since
    # xcorr values <= 0.0 are not reported
    #     **
    #    *  *
    #   *    *
    #          *
    #            *
    #                   *
    #  Grabs the right tail from above and inverts it to the left side (less
    #  than zero), creating a more full distribution.  raises an ArgumentError
    #  if values_chopped_at_zero.size == 0
    #  this method would be more robust with some smoothing.
    #  Method currently only meant for large amounts of data.
    #  input data does not need to be sorted
    def extend_distribution_left_of_zero(values_chopped_at_zero)
      sz = values_chopped_at_zero.size
      raise ArgumentError, "array.size must be > 0" if sz == 0 
      num_bins = (Math.log10(sz) * 100).round
      vec = VecD.new(values_chopped_at_zero)
      (bins, freqs) = vec.histogram(num_bins)
      start_i = 0
      freqs.each_with_index do |f,i|
        if f.is_a?(Numeric) && f > 0
          start_i = i 
          break
        end
      end
      match_it = freqs[start_i]
      # get the index of the first frequency value less than the zero frequency
      index_to_chop_at = -1
      rev_freqs = freqs.reverse
      rev_freqs.each_with_index do |freq,rev_i|
        if match_it - rev_freqs[rev_i+1] <= 0
          index_to_chop_at = freqs.size - 1 - rev_i
          break
        end
      end
      cut_point = bins[index_to_chop_at]
      values_chopped_at_zero + values_chopped_at_zero.select {|v| v >= cut_point }.map {|v| cut_point - v }
    end

    # assumes the decoy_vals follows a normal distribution
    def p_values(target_vals, decoy_vals)
      (mean, stdev) = VecD.new(decoy_vals).sample_stats
      r = RSRuby.instance
      vec = VecD.new(target_vals)
      right_tailed = true
      vec.p_value_normal(mean, stdev, right_tailed)
    end

    def p_values_for_sequest(target_hits, decoy_hits)
      dh_vals = decoy_hits.map {|v| v.xcorr }
      new_decoy_vals = PiZero.extend_distribution_left_of_zero(dh_vals)
      #File.open("target.yml", 'w') {|out| out.puts new_decoy_vals.join(" ") }
      #File.open("decoy.yml", 'w') {|out| out.puts target_hits.map {|v| v.xcorr }.join(" ") }
      #abort 'checking'
      p_values(target_hits.map {|v| v.xcorr}, new_decoy_vals )
    end

#### NEED TO VERIFY if this is PIT or PI_ZERO!
=begin
    # takes a list of booleans with true being a target hit and false being a
    # decoy hit and returns the pi_zero using the smooth method
    # Should be ordered from best to worst (i.e., one expects more true values
    # at the beginning of the list)
    def pi_zero_from_booleans(booleans)
      targets = 0
      decoys = 0
      xs = []
      ys = []
      booleans.reverse.each_with_index do |v,index|
        if v
          targets += 1
        else
          decoys += 1
        end
        if decoys > 0
          xs << index
          ys << targets.to_f / decoys
        end
      end
      ys.reverse!
      plateau_height(xs, ys)
    end
=end

    # returns fraction of incorrect target hits (frit) (this is the percent
    # incorrect targets [PIT] expressed as a fraction rather than percent)
    # takes two parallel arrays consisting of the total number of hits (this
    # will typically be the total # target hits) at that point and the
    # precision (ranging from: [0,1]) (typically determined by counting the
    # number of decoy hits).  Expects the number of total hits to be
    # monotonically increasing and the precision to roughly start high and
    # decrease as more hits (of lesser quality) are added.
    def frit_from_precision(total_num_hits_ar, precision_ar)
      instant_pi_zeros = []
      total_num_hits_ar.reverse.zip(precision_ar.reverse).each_cons(2) do |dp1, dp0|
        (x1, y1) = dp1
        (x0, y0) = dp0
        instant_pi_zeros << ((x1 * (1.0 - y1)) - (x0 * (1.0 - y0) )) / (x1 - x0)
      end
      instant_pi_zeros.reverse!
      plateau_height(total_num_hits_ar[1..-1], instant_pi_zeros)
    end

    # Takes an array of doublets ([[int, int], [int, int]...]) where the first
    # value is the number of target hits and the second is the number of decoy
    # hits.  Expects that best hits are at the beginning of the list.  Assumes
    # that each sum is a subset of the following group (shown as actual hits
    # rather than number of hits):
    #
    #    [[target, target, target, decoy], [target, target, target, decoy,
    #    target, decoy, target], [target, target, target, decoy, target,
    #    decoy, target, decoy, target, target]]
    #
    # This assumption may be relaxed somewhat and should still give good
    # results.
    def frit_from_groups(array_of_doublets)
      frits = []
      array_of_doublets.reverse.each_cons(2) do |two_doublets|
        bigger, smaller = two_doublets
        num_targets = bigger[0] - smaller[0] 
        num_decoy = bigger[1] - smaller[1]
        num_targets = 0 if num_targets < 0
        num_decoy = 0 if num_targets < 0
        if num_decoy > 0
          frits << (num_targets.to_f / num_decoy)
        end
      end
      frits.reverse!
      xs = (0...(frits.size)).to_a
      plateau_height(xs, frits)
    end

  end
end

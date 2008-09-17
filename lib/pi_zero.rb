require 'rsruby'
require 'gsl'

module PiZero
  # takes a sorted array of p-values (floats between 0 and 1 inclusive)
  # returns [thresholds_ar, instantaneous pi_0 calculations_ar]
  # evenly incremented values will be used by default:
  # :start=>0.0, :stop=>1.0, :step=>0.01
  def self.pi_zero_hats(sorted_pvals, args={})
    defaults = {:start => 0.0, :stop=>1.0, :step=>0.01 }
    margs = defaults.merge( args )
    (start, stop, step) = margs.values_at(:start, :stop, :step)

    # From Storey et al. PNAS 2003:
    lambdas = []                 # lambda
    pi_zeros = []                # pi_0
    total = sorted_pvals.size  # m 

    # totally retarded implementation with correct logic:
    start.step(stop, step) do |lam|
      lambdas << lam
      (greater, less) = sorted_pvals.partition {|pval| pval > lam }
      pi_zeros.push( greater.size.to_f / ( total * (1.0 - lam) ) )
    end
    [lambdas, pi_zeros]
  end

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
  def self.plateau_height(x, y)
=begin
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
=end

    r = RSRuby.instance
    answ = r.smooth_spline(x,y, :df => 3)
    ## to plot it!
    #r.plot(x,y)
    #r.lines(answ['x'], answ['y'])
    #r.points(answ['x'], answ['y'])
    #sleep(8)

    answ['y'].last
  end

  def self.plateau_exponential(x,y)
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
  def self.pi_zero(sorted_pvals)
    plateau_height( *(pi_zero_hats(sorted_pvals)) )
  end

  def pvalues(target_hits, decoy_hits, 
  end

  # combines all data values, sorts, and ranks them and returns parallel
  # arrays corresponding to the final ranks.
  # ties will split the ranks (i.e., two values tying for 2 and 3 will each be
  # given a rank of 2.5)
  # returns two parallel arrays of ranks
  def rank(ar1,ar2)
  end


end

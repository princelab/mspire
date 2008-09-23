
begin
require 'rsruby'
rescue LoadError
  puts "You must have the rsruby gem installed to use the qvalue module"
  puts $!
  raise LoadError
end
require 'vec'

# Adapted from qvalue.R by Alan Dabney and John Storey which was LGPL licensed

class VecD
  Default_lambdas = []
  0.0.step(0.9,0.05) {|v| Default_lambdas << v }

  Default_smooth_df = 3

  # returns the pi_zero estimate by taking the fraction of all p-values above
  # lambd and dividing by (1-lambd) and gauranteed to be <= 1
  def pi_zero_at_lambda(lambd)
    v = (self.select{|v| v >= lambd}.size.to_f/self.size) / (1 - lambd) 
    [v, 1].min
  end

  # returns a parallel array (VecI) of how many are <= in the array 
  # roughly: VecD[1,8,10,8,9,10].num_le => VecI[1, 3, 6, 3, 4, 6]
  def num_le
    hash = Hash.new {|h,k| h[k] = [] }
    self.each_with_index do |v,i|
      hash[v] << i
    end
    num_le_ar = []
    sorted = self.sort
    count = 0
    sorted.each_with_index do |v,i|
      back = 1
      count += 1
      if v == sorted[i-back]
        while (sorted[i-back] == v)
          num_le_ar[i-back] = count
          back -= 1 
        end
      else
        num_le_ar[i] = count
      end
    end
    ret = VecI.new(self.size)
    num_le_ar.zip(sorted) do |n,v|
      indices = hash[v]
      indices.each do |i|
        ret[i] = n
      end
    end
    ret
  end

  Default_pi_zero_args = {:lambda_vals => Default_lambdas, :method => :smooth, :log_transform => false }

  # returns the Pi_0 for given p-values (the values in self)
  #   lambda_vals = Float or Array of floats of size >= 4.  value(s) within (0,1)
  #   A single value given then the pi_zero is calculated at that point,
  #   superceding the method or log_transform arguments
  #   method = :smooth or :bootstrap
  #   log_transform = true or false
  def pi_zero(lambda_vals=Default_pi_zero_args[:lambda_vals], method=Default_pi_zero_args[:method], log_transform=Default_pi_zero_args[:log_transform])
    if self.min < 0 || self.max > 1
      raise ArgumentError, "p-values must be within [0,1)"
    end

    if lambda_vals.is_a? Numeric
      lambda_vals = [lambda_vals]
    end
    if lambda_vals.size != 1 && lambda_vals.size < 4
      raise ArgumentError, "#{tun_arg} must have 1 or 4 or more values"
    end
    if lambda_vals.any? {|v| v < 0 || v >= 1}
      raise ArgumentError, "#{tun_arg} vals must be within [0,1)"
    end

    pi_zeros = lambda_vals.map {|val| self.pi_zero_at_lambda(val) }
    if lambda_vals.size == 1
      pi_zeros.first
    else
      case method
      when :smooth
        r = RSRuby.instance
        calc_pi_zero = lambda do |_pi_zeros| 
          hash = r.smooth_spline(lambda_vals, _pi_zeros, :df => Default_smooth_df) 
          hash['y'][VecD.new(lambda_vals).max_indices.max]
        end
        if log_transform
          pi_zeros.log_space {|log_vals| calc_pi_zero.call(log_vals) }
        else
          calc_pi_zero.call(pi_zeros)
        end
      when :bootstrap
        min_pi0 = pi_zeros.min
        lsz = lambda_vals.size
        mse = VecD.new(lsz, 0)
        pi0_boot = VecD.new(lsz, 0)
        sz = self.size
        100.times do   #  for(i in 1:100) {
          p_boot = self.shuffle
          (0...lsz).each do |i|
            pi0_boot[i] = ( p_boot.select{|v| v > lambda_vals[i] }.size.to_f/p_boot.size ) / (1-lambda_vals[i])
          end
          mse = mse + ( (pi0_boot-min_pi0)**2 )
        end
        #  pi0 <- min(pi0[mse==min(mse)])
        pi_zero = pi_zeros.values_at(*(mse.min_indices)).min
        [pi_zero,1].min
      else 
        raise ArgumentError, ":pi_zero_method must be :smooth or :bootstrap!"
      end
    end
  end

  # Returns a VecD filled with parallel q-values
  # assumes that vec is filled with p values
  # see pi_zero method for arguments, these should be named as symbols in the
  # pi_zero_args hash.
  #     robust = true or false    an indicator of whether it is desired to make
  #                           the estimate more robust for small p-values and
  #                           a direct finite sample estimate of pFDR
  # A q-value can be thought of as the global positive false discovery rate
  # at a particular p-value
  def qvalues(robust=false, pi_zero_args={})
    sz = self.size
    pi0_args = Default_pi_zero_args.merge(pi_zero_args)
    self.pi_zero(*(pi0_args.values_at(:lambda_vals, :method, :log_transform)))
    raise RuntimeError, "pi0 <= 0 ... check your p-values!!" if pi_zero <= 0
    num_le_ar = self.num_le
    qvalues =
      if robust
        den = self.map {|val| 1 - ((1 - val)**(sz)) }
        self * (pi_zero * sz) / ( num_le_ar * den)
      else
        self * (pi_zero * sz) / num_le_ar
      end

    u_ar = self.order

    qvalues[u_ar[sz-1]] = [qvalues[u_ar[sz-1]],1].min
    (0...sz-1).each do |i|
      qvalues[u_ar[i]] = [qvalues[u_ar[i]],qvalues[u_ar[i+1]],1].min
    end
    qvalues
  end
end



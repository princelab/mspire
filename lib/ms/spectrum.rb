module MS
  class Spectrum
    include Enumerable

    # The underlying data store.
    attr_reader :data
    
    # data takes an array: [mzs, intensities]
    # @return [MS::Spectrum]
    # @param [Array] data two element array of mzs and intensities
    def initialize(data)
      @data = data
    end

    def self.from_peaks(ar_of_doublets)
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
      [mzs[array_index], intensities[array_index]]
    end

    # yields(mz, inten) across the spectrum, or array of doublets if no block
    def peaks(&block)
      (m, i) = mzs_and_intensities
      m.zip(i, &block)
    end

    alias_method :each, :peaks
    alias_method :each_peak, :peaks

    # if the mzs and intensities are the same then the spectra are considered
    # equal
    def ==(other)
      mzs == other.mzs && intensities == other.intensities
    end

    # returns a new spectrum whose intensities have been normalized by the tic
    def normalize
      tic = self.intensities.inject(0.0) {|sum,int| sum += int }
      MS::Spectrum.new([self.mzs, self.intensities.map {|v| v / tic }])
    end

    ## uses index function and returns the intensity at that value
    #def intensity_at_mz(mz)
      #if x = index(mz)
        #intensities[x]
      #else
        #nil
      #end
    #end

    ## index mz, tolerance = :nearest(1), Float, :nearest_within_integer

    ## returns the index of the first value matching that m/z.  the argument m/z
    ## may be less precise than the actual m/z (rounding to the same precision
    ## given) but must be at least integer precision (after rounding)
    ## implemented as binary search (bsearch from the web)
    #def index(mz)
      #mz_ar = mzs
      #return_val = nil
      #ind = mz_ar.bsearch_lower_boundary{|x| x <=> mz }
      #if mz_ar[ind] == mz
        #return_val = ind
      #else 
        ## do a rounding game to see which one is it, or nil
        ## find all the values rounding to the same integer in the locale
        ## test each one fully in turn
        #mz = mz.to_f
        #mz_size = mz_ar.size
        #if ((ind < mz_size) and equal_after_rounding?(mz_ar[ind], mz))
          #return_val = ind
        #else # run the loop
          #up = ind
          #loop do
            #up += 1
            #if up >= mz_size
              #break
            #end
            #mz_up = mz_ar[up]
            #if (mz_up.ceil  - mz.ceil >= 2)
              #break
            #else
              #if equal_after_rounding?(mz_up, mz)
                #return_val = up
                #return return_val
              #end
            #end
          #end
          #dn= ind
          #loop do
            #dn -= 1
            #if dn < 0
              #break
            #end
            #mz_dn = mz_ar[dn]
            #if (mz.floor - mz_dn.floor >= 2)
              #break
            #else
              #if equal_after_rounding?(mz_dn, mz)
                #return_val = dn
                #return return_val
              #end
            #end
          #end
        #end
      #end
      #return_val
    #end

    ## less_precise should be a float
    ## precise should be a float
    #def equal_after_rounding?(precise, less_precise) # :nodoc:
      ## determine the precision of less_precise
      #exp10 = precision_as_neg_int(less_precise)
      ##puts "EXP10: #{exp10}"
      #answ = ((precise*exp10).round == (less_precise*exp10).round)
      ##puts "TESTING FOR EQUAL: #{precise} #{less_precise}"
      ##puts answ
      #(precise*exp10).round == (less_precise*exp10).round
    #end

    ## returns 1 for ones place, 10 for tenths, 100 for hundredths
    ## to a precision exceeding 1e-6
    #def precision_as_neg_int(float) # :nodoc:
      #neg_exp10 = 1
      #loop do
        #over = float * neg_exp10
        #rounded = over.round
        #if (over - rounded).abs <= 1e-6
          #break
        #end
        #neg_exp10 *= 10
      #end
      #neg_exp10
    #end


  end
end

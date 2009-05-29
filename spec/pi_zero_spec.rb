require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )
require 'pi_zero'

describe PiZero do
  before(:all) do
    @bools = "11110010110101010101000001101010101001010010100001001010000010010000010010000010010101010101000001010000000010000000000100001000100000100000100000001000000000000100000000".split('').map do |v| 
      if v.to_i == 1
        true
      else
        false
      end
    end
    increment = 6.0 / @bools.size
    @xcorrs = []
    0.0.step(6.0, increment) {|v| @xcorrs << v }
    @xcorrs.reverse!
                 
    @sorted_pvals = [0.0, 0.1, 0.223, 0.24, 0.55, 0.68, 0.68, 0.90, 0.98, 1.0]
  end

  xit 'calculates instantaneous pi_0 hats' do
    answ = PiZero.pi_zero_hats(@sorted_pvals, :step => 0.1)
    exp_lambdas =       [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
    passing_threshold = [9,   8,   8,   6,   6,   6,   5,   3,   3,   2]
    expected = passing_threshold.zip(exp_lambdas).map {|v,l| v.to_f / (10.0 * (1.0 - l)) }
    (answ_lams, answ_pis) = answ
    answ_lams.zip(exp_lambdas) {|a,e| a.should be_close(e, 0.0000000001) }
    answ_pis.zip(expected) {|a,e| a.should be_close(e, 0.0000000001) }
  end

  xit 'can find a plateau height with exponential' do
    x = [0.0, 0.01, 0.012, 0.13, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2]
    y = [1.0, 0.95, 0.92, 0.8, 0.7, 0.6, 0.55, 0.58, 0.62, 0.53, 0.54, 0.59, 0.4, 0.72]

    z = PiZero.plateau_exponential(x,y)
    # still working on this one
  end

  xit 'can find a plateau height' do
    x = [0.0, 0.01, 0.012, 0.13, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2]
    y = [1.0, 0.95, 0.92, 0.8, 0.7, 0.6, 0.55, 0.58, 0.62, 0.53, 0.54, 0.59, 0.4, 0.72]
    z = PiZero.plateau_height(x,y)
    z.should be_close(0.57, 0.05)
    #require 'rsruby'
    #r = RSRuby.instance
    #r.plot(x,y)
    #sleep(8)
  end

  xit 'can calculate p values for SEQUEST hits' do
    class FakeSequest ; attr_accessor :xcorr ; def initialize(xcorr) ; @xcorr = xcorr ; end ; end

    target = []
    decoy = []
    cnt = 0
    @xcorrs.zip(@bools) do |xcorr, bool|
      if bool
        target << FakeSequest.new(xcorr)
      else
        decoy << FakeSequest.new(xcorr)
      end
    end
    pvalues = PiZero.p_values_for_sequest(target, decoy)
    # frozen:
    exp = [1.71344886775144e-07, 1.91226800512155e-07, 2.1332611415515e-07, 2.37879480495429e-07, 3.29004960353623e-07, 4.07557294032203e-07, 4.5332397295349e-07, 5.60147945165288e-07, 6.90985835582987e-07, 8.50958233458999e-07, 1.04621373866358e-06, 1.28412129273e-06, 2.35075612646546e-06, 2.59621031358335e-06, 3.16272156036349e-06, 3.84642913860656e-06, 4.67014790912829e-06, 5.66082984245324e-06, 7.53093419443452e-06, 9.09058296339405e-06, 1.20185706815653e-05, 1.44474800911154e-05, 2.27242185508328e-05, 2.967213280773e-05, 3.537451312629e-05, 5.93486219583748e-05, 7.64456599577934e-05, 0.000125433021038759, 0.000159783941297163, 0.000256431068540685, 0.000323066395099306, 0.00037608522266194, 0.000437091783629134, 0.000507167844234063, 0.000587522219112902, 0.000679502786805963, 0.00104103901250011, 0.00119624534498457, 0.00219153400681528, 0.00439503742960694, 0.00593498821589879, 0.00749365688957234, 0.0105069659581753, 0.0145259091109191, 0.0218905360424189, 0.0404530419122661]
    pvalues.zip(exp) do |v,e|
      v.should be_close(e, 0.000001)
    end
  end

  xit 'can calculate pi zero for target/decoy booleans' do
    pi_zero = PiZero.pi_zero_from_booleans(@bools)
    # frozen
    pi_zero.should be_close(0.03522869, 0.0001)
  end

  it 'can calculate frit for groups of hits' do
    # setup
    targets = [4,3,8,3,5,3,4,5,4]
    decoys = [0,2,2,3,5,7,8,8,8]
    targets_summed = []
    targets.each_with_index do |ar,i|
      sum = 0
      (0..i).each do |j|
        sum += targets[j]
      end
      targets_summed << sum
    end
    decoys_summed = []
    decoys.each_with_index do |ar,i|
      sum = 0
      (0..i).each do |j|
        sum += decoys[j]
      end
      decoys_summed << sum
    end
    zipped = targets_summed.zip(decoys_summed)
    frit = PiZero.frit_from_groups(zipped)
    # frozen
    frit.should be_close(0.384064, 0.00001)
  end

  xit 'can calcuate pi zero for total number of hits and precision' do
    tot_hits = [1,10,20,30,50,200]
    precision = [1.0, 1.0, 0.85, 0.80, 0.7, 0.5]
    reply = PiZero.frit_from_precision(tot_hits, precision)
    puts "ANSER"
    # frozen
    puts reply
    #reply.should be_close()

  end

end


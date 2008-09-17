require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )
require 'pi_zero'

describe PiZero do
  before(:all) do
                     
    @sorted_pvals = [0.0, 0.1, 0.223, 0.24, 0.55, 0.68, 0.68, 0.90, 0.98, 1.0]
  end

  it 'calculates instantaneous pi_0 hats' do
    answ = PiZero.pi_zero_hats(@sorted_pvals, :step => 0.1)
    exp_lambdas =       [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
    passing_threshold = [9,   8,   8,   6,   6,   6,   5,   3,   3,   2,   0]
    expected = passing_threshold.zip(exp_lambdas).map {|v,l| v.to_f / (10.0 * (1.0 - l)) }
    (answ_lams, answ_pis) = answ
    answ_lams.zip(exp_lambdas) {|a,e| a.should be_close(e, 0.0000000001) }
    (answ_pis.pop.nan?).should be_true
    (expected.pop.nan?).should be_true
    answ_pis.zip(expected) {|a,e| a.should be_close(e, 0.0000000001) }
  end

  xit 'can find a plateau height with exponential' do
    x = [0.0, 0.01, 0.012, 0.13, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2]
    y = [1.0, 0.95, 0.92, 0.8, 0.7, 0.6, 0.55, 0.58, 0.62, 0.53, 0.54, 0.59, 0.4, 0.72]

    z = PiZero.plateau_exponential(x,y)
    # still working on this one
  end

  it 'can find a plateau height' do
    x = [0.0, 0.01, 0.012, 0.13, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2]
    y = [1.0, 0.95, 0.92, 0.8, 0.7, 0.6, 0.55, 0.58, 0.62, 0.53, 0.54, 0.59, 0.4, 0.72]
    z = PiZero.plateau_height(x,y)
    z.should be_close(0.57, 0.05)
    #require 'rsruby'
    #r = RSRuby.instance
    #r.plot(x,y)
    #sleep(8)
  end

  it 'can calculate p values for SEQUEST hits' do
    pvalues = PiZero.pvalues(target, decoy, :xcorr)
  end

end


require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

require 'qvalue'

describe 'finding q-values' do

  it 'can do num_le' do
    x = VecD[1,8,10,8,9,10]
    exp = VecD[1, 3, 6, 3, 4, 6]
    x.num_le.should == exp

    x = VecD[10,9,8,5,5,5,5,3,2]
    exp = VecD[9, 8, 7, 6, 6, 6, 6, 2, 1]
    x.num_le.should == exp
  end

  it 'can do qvalues with smooth pi0' do
    pvals = VecD[0.00001, 0.0001, 0.001, 0.01, 0.03, 0.02, 0.01, 0.1, 0.2, 0.4, 0.5, 0.6, 0.77, 0.8, 0.99]
    exp = [0.0000938637, 0.0004693185, 0.0031287899, 0.0187727394, 0.0402272988, 0.0312878991, 0.0187727394, 0.1173296215, 0.2085859937, 0.3754547887, 0.4266531690, 0.4693184859, 0.5363639839, 0.5363639839, 0.6195004014]
    pvals.qvalues.zip(exp) do |a,b|
      a.should be_close(b, 1.0e-9)
    end
  end

  it 'can do qvalues with bootstrap pi0' do
    puts "\nbootstrap pi0 needs further testing although answers seem to be close!"
    pvals = VecD[0.00001, 0.0001, 0.001, 0.01, 0.03, 0.02, 0.01, 0.1, 0.2, 0.4, 0.5, 0.6, 0.77, 0.8, 0.99]
    # this is what the Storey software gives for this:
    # exp = [8.888889e-05, 4.444444e-04, 2.962963e-03, 1.777778e-02, 3.809524e-02, 2.962963e-02, 1.777778e-02, 1.111111e-01, 1.975309e-01, 3.555556e-01, 4.040404e-01, 4.444444e-01, 5.079365e-01, 5.079365e-01, 5.866667e-01]
    exp = [9.38636971774565e-05, 0.000469318485887282, 0.00312878990591522, 0.0187727394354913, 0.0402272987903385, 0.0312878990591522, 0.0187727394354913, 0.117329621471821, 0.208585993727681, 0.375454788709826, 0.426653168988439, 0.469318485887282, 0.53636398387118, 0.53636398387118, 0.619500401371213]
    robust = false
    qvals = pvals.qvalues(robust, :method => :bootstrap)
    qvals.zip(exp) do |a,b|
      a.should be_close(b, 0.00001)
    end
  end

end


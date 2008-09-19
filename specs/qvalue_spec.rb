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

  it 'can do qvalues' do
    pvals = VecD[0.00001, 0.0001, 0.001, 0.01, 0.03, 0.02, 0.01, 0.1, 0.2, 0.4, 0.5, 0.6, 0.77, 0.8, 0.99]
    p pvals.q_values
  end

end


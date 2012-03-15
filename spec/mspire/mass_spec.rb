require 'spec_helper'

require 'mspire/mass'

describe 'Mspire::Mass' do
  it 'can access elemental masses by string or symbol' do
    {
      'c' => 12.0,  # +
      'br' => 78.9183361,  # +
      'd' => 2.014101779,  # +
      'f' => 18.99840322,  # +
      'n' => 14.003074,  # +
      'o' => 15.99491463,  # +
      'na' => 22.9897677,  # +
      'p' => 30.973762,  # +
      's' => 31.9720707,  # +
      'li' => 7.016003,  # +
      'cl' => 34.96885272,  # +
      'k' => 38.9637074,  # +
      'si' => 27.9769265325, 
      'i' => 126.904473,  # +
      'h+' => 1.00727646677,
      'h' => 1.007825035,  # +
      'h2o' => 18.0105647,
      'oh' => 17.002739665,
      'e' => 0.0005486,
      'se' => 79.9165196
    }.each do |el, mass|
      Mspire::Mass::MONO[el].should_not be_nil
      Mspire::Mass::MONO[el].should == Mspire::Mass::MONO[el.to_sym]
      Mspire::Mass::MONO[el].should be_within(0.00001).of(mass) 
    end


    { h: 1.00794, he: 4.002602, ni: 58.6934 }.each do |el, mass|
      Mspire::Mass::AVG[el].should_not be_nil
      Mspire::Mass::AVG[el].should == Mspire::Mass::AVG[el.to_sym]
      Mspire::Mass::AVG[el].should be_within(0.00001).of(mass) 
    end

  end
end

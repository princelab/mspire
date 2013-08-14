require 'spec_helper'
require 'mspire/mass/all'

describe Mspire::Mass::All do
  it 'accesses elements by lower case and amino acids by upper case' do
    {
      'c' => 12.0,  # carbon
      'C' => 103.00918,  # cysteine
      'br' => 78.9183361,  # bromine
      'd' => 2.014101779,  # deuterium
      'D' => 115.0269430,  # aspartic acid
      'h+' => 1.00727646677, # proton
      'h' => 1.007825035,  # hydrogen
      'h2o' => 18.0105647, # water
      'oh' => 17.002739665, # oh
      'e' => 0.0005486, # electron
    }.each do |el, mass|
      Mspire::Mass::All::MONO[el].should_not be_nil
      Mspire::Mass::All::MONO[el].should == Mspire::Mass::All::MONO[el.to_sym]
      Mspire::Mass::All::MONO[el].should be_within(0.00001).of(mass) 
    end

    { h: 1.00794, he: 4.002602, ni: 58.6934, H: 137.13928 }.each do |el, mass|
      Mspire::Mass::All::AVG[el].should_not be_nil
      Mspire::Mass::All::AVG[el].should == Mspire::Mass::All::AVG[el.to_sym]
      Mspire::Mass::All::AVG[el].should be_within(0.00001).of(mass) 
    end
  end

  it 'mono may be accessed directly' do
    Mspire::Mass::All[:c].should == 12.0
  end
end

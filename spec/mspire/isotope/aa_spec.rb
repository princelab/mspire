require 'spec_helper'

require 'mspire/isotope/aa'

describe 'accessing an amino acid atom count' do
  before do
    @alanine = {:C=>3, :H=>5, :O=>1, :N=>1, :S=>0, :P=>0, :Se=>0}
  end

  it 'residue can be accessed with a symbol' do
    hash = Mspire::Isotope::AA::FORMULAS[:A]
    [:C, :H, :O, :N, :S].each {|key| hash[key].should == @alanine[key] }
  end
    
  it 'residue can be accessed with a string' do
    hash = Mspire::Isotope::AA::FORMULAS['A']
    [:C, :H, :O, :N, :S].each {|key| hash[key].should == @alanine[key] }
  end

end

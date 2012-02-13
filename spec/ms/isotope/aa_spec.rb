require 'spec_helper'

require 'ms/isotope/aa'

describe 'accessing an amino acid atom count' do
  before do
    @alanine = {:c=>3, :h=>5, :o=>1, :n=>1, :s=>0, :p=>0, :se=>0}
  end

  it 'residue can be accessed with a symbol' do
    hash = MS::Isotope::AA::ATOM_COUNTS[:A]
    [:c, :h, :o, :n, :s].each {|key| hash[key].should == @alanine[key] }
  end
    
  it 'residue can be accessed with a string' do
    hash = MS::Isotope::AA::ATOM_COUNTS['A']
    [:c, :h, :o, :n, :s].each {|key| hash[key].should == @alanine[key] }
  end

end

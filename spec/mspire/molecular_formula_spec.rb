require 'spec_helper'

require 'mspire/molecular_formula'

describe Mspire::MolecularFormula do

  it 'can be initialized with a String or Hash' do
    data = {h: 22, c: 12, n: 1, o: 3, s: 2}
    mf = Mspire::MolecularFormula.new "H22BeC12N1O3S2Li2"
    mf.should == {:h=>22, :be=>1, :c=>12, :n=>1, :o=>3, :s=>2, :li=>2}
    mf = Mspire::MolecularFormula.new(data)
    mf.should == data
  end

  it 'expects properly capitalized abbreviations' do
    Mspire::MolecularFormula.new('Ni7Se3').should == {:ni=>7, :se=>3}
    # there is no such thing as the E element, so this is going to get the
    # user in trouble.  However, this is the proper interpretation of the
    # formula.
    Mspire::MolecularFormula.new('Ni7SE3').should == {:ni=>7, :s=>1, :e=>3}
  end

end

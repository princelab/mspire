require 'spec_helper'

require 'mspire/molecular_formula'

describe Mspire::MolecularFormula do

  it 'can be initialized with a String or Hash' do
    data = {h: 22, c: 12, n: 1, o: 3, s: 2}
    mf = Mspire::MolecularFormula.new "H22BeC12N1O3S2Li2"
    mf.to_hash.should == {:h=>22, :be=>1, :c=>12, :n=>1, :o=>3, :s=>2, :li=>2}
    mf = Mspire::MolecularFormula.new(data)
    mf.to_hash.should == data
  end

  it 'can be initialized with charge, too' do
    mf = Mspire::MolecularFormula.new "H22BeC12N1O3S2Li2", 2
    mf.to_hash.should == {:h=>22, :be=>1, :c=>12, :n=>1, :o=>3, :s=>2, :li=>2}
    mf.charge.should == 2
  end

  it 'expects properly capitalized abbreviations' do
    Mspire::MolecularFormula.new('Ni7Se3').to_hash.should == {:ni=>7, :se=>3}
    # there is no such thing as the E element, so this is going to get the
    # user in trouble.  However, this is the proper interpretation of the
    # formula.
    Mspire::MolecularFormula.new('Ni7SE3').to_hash.should == {:ni=>7, :s=>1, :e=>3}
  end

  describe 'an object' do
    
    subject {
      data = {h: 22, c: 12, n: 1, o: 3, s: 2, be: 1}
      Mspire::MolecularFormula.new(data)
    }

    it 'the string output is a standard molecular formula' do
      subject.to_s.should == "BeC12H22NO3S2"
    end

    it 'can be converted to a hash' do
      subject.to_hash.should == {h: 22, c: 12, n: 1, o: 3, s: 2, be: 1}
    end

    it 'is only equal if the charge is equal' do
      another = subject.dup
      another.should == subject
      another.charge = 2
      another.should_not == subject
    end

  end

end

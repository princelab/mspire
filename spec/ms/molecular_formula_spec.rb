require 'spec_helper'

require 'ms/molecular_formula'

describe MS::MolecularFormula do

  it 'can be initialized with a String or Hash' do
    data = {h: 22, c: 12, n: 1, o: 3, s: 2}
    mf = MS::MolecularFormula.new "H22BeC12N1O3S2Li2"
    mf.should == {:h=>22, :be=>1, :c=>12, :n=>1, :o=>3, :s=>2, :li=>2}
    mf = MS::MolecularFormula.new(data)
    mf.should == data
  end

end

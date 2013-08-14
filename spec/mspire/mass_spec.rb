require 'spec_helper'

require 'mspire/mass'

describe Mspire::Mass do
  it 'calculates formula masses' do
    Mspire::Mass.formula('CHCl3').should be_within(0.00001).of(117.91439)
  end

  it 'calculates peptide/protein (AA) masses' do
    Mspire::Mass.aa('ADALL').should be_within(0.00001).of(501.27986)
  end
end

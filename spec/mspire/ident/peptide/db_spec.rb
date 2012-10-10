require 'spec_helper'

require 'yaml'
path = 'mspire/ident/peptide/db'
require path 

describe 'reading a peptide centric db' do
  before do
    @pepcentric = TESTFILES + "/mspire/ident/peptide/db/uni_11_sp_tr.PEPTIDE_CENTRIC.yml"
  end

  it 'creates a hash that can retrieve peptides as an array' do
    hash = Mspire::Ident::Peptide::Db.new(@pepcentric)
    hash["AVTEQGHELSNEER"].should == ["sp|P31946|1433B_HUMAN", "sp|P31946-2|1433B_HUMAN"]
    hash["VRAAR"].should == ["tr|D3DX18|D3DX18_HUMAN"]
    hash["BANNANA"].should == nil
  end
end

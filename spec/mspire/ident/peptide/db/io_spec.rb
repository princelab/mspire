require 'spec_helper'

require 'mspire/ident/peptide/db/io'

describe 'reading a peptide centric DB' do
  before do
    @pepcentric = TESTFILES + "/mspire/ident/peptide/db/uni_11_sp_tr.PEPTIDE_CENTRIC.yml"
  end

  it 'reads the file on disk with random access or is enumerable' do
    Mspire::Ident::Peptide::Db::IO.open(@pepcentric) do |io|
      io["AVTEQGHELSNEER"].should == %w(sp|P31946|1433B_HUMAN	sp|P31946-2|1433B_HUMAN)
      io["VRAAR"].should == ["tr|D3DX18|D3DX18_HUMAN"]
      io["SILLY WILLY"].should be_nil
      io.each_with_index do |key_prots, i|
        key_prots.first.should be_an_instance_of String
        key_prots.last.should be_a_kind_of Array
      end
    end
  end
end

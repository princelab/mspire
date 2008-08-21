require 'set'

require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require 'spec_id/digestor'
require 'spec_id/sequest/params'
require 'fasta'


describe 'selecting peptides based on size' do
  before(:each) do 
    # (M+H)+ PEPTIDE
    # http://db.systemsbiology.net:8080/proteomicsToolkit/FragIonServlet.html
    mono = { 
      'AACK' => 392.19681,
      'PEPTIDE' => 800.36783, 
      'TTTYW' => 671.72767,
      'AGGGGGGLKNADEEEP' => 1457.65088,
      'IMNDR' => 648.31396
      
    }
    avg = {
      'AACK' => 392.49375,
      'PEPTIDE' => 800.84071,
      'TTTYW' => 671.30411,
      'AGGGGGGLKNADEEEP' => 1458.48147,
      'IMNDR' => 648.75518,  #  648.76,  thermo
    }
    @pepseqs = [%w(AACK PEPTIDE TTTYW), %w(AGGGGGGLKNADEEEP IMNDR)]
    # basically the protein sequence ONLY matters if the peptide is n or c
    # terminal and there is an n or c terminal modification for ONLY the
    # protein.
    @protseqs = %w(LLLLAACKLLLLLLLPEPTIDELLLLLLTTTYWLLL LLLLAGGGGGGLKNADEEEPLLLLLLIMNDRLLL)
  end

  it 'is sensitive to mono/avg' do
    h_plus = false

    expect = [%w(PEPTIDE TTTYW), %w(IMNDR)]
    masses_hash = Mass::MONO
    answ = Digestor.new.limit_sizes(@protseqs, @pepseqs, 400.0, 800.38, masses_hash, h_plus)
    answ.to_set.should == expect.to_set
    masses_hash = Mass::AVG
    expect = [%w(TTTYW), %w(IMNDR)]
    answ = Digestor.new.limit_sizes(@protseqs, @pepseqs, 400.0, 800.38, masses_hash, h_plus)
    answ.to_set.should == expect.to_set
  end

  it 'is sensitive to static mass changes' do
    expect_before = [%w(PEPTIDE TTTYW), %w(IMNDR)]
    h_plus = false
    masses_hash = Mass::MONO
    answ = Digestor.new.limit_sizes(@protseqs, @pepseqs, 400.0, 800.38, Mass::MONO, h_plus)
    answ.to_set.should == expect_before.to_set

    static = {:C => 20.0}
    expect_after = [%w(AACK PEPTIDE TTTYW), %w(IMNDR)]
    masses_hash = Mass::MONO.dup
    masses_hash[:C] = masses_hash[:C] + 20.0
    answ = Digestor.new.limit_sizes(@protseqs, @pepseqs, 400.0, 800.38, masses_hash, h_plus)
    #answ.to_set.should == expect_before.to_set
    answ.to_set.should == expect_after.to_set
  end

  it 'returns peptides linked to their proteins given fasta and params' do
    fasta_obj = Fasta.new(Tfiles + '/small.fasta')
    params_obj = Sequest::Params.new(Tfiles + '/bioworks32.params')
    peps = Digestor.digest(fasta_obj, params_obj)
    peps.first.is_a?(SpecID::Pep).should be_true
    # frozen
    peps.size.should == 2843
    # frozen
    peps.select {|v| v.prots.size > 1 }.size.should == 10
  end
  
end

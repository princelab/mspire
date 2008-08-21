require File.expand_path( File.dirname(__FILE__) + '/../../spec_helper' )

require 'spec_id/proph/pep_summary'

ToCheck = {
  :spectrum_query => {:first => {:spectrum => "020.42.42.3", :start_scan=>42, :end_scan=>42, :precursor_neutral_mass=>1015.77285654469, :assumed_charge=>3, :index=>1 },
    :last => {:spectrum=>"020.344.344.3", :start_scan=>344, :end_scan=>344, :precursor_neutral_mass=>1447.6040333025, :assumed_charge=>3, :index=>18 },
},

:search_hit => {:first => {:hit_rank=>1, :peptide=>"GTGVSVTR", :peptide_prev_aa=>"R", :peptide_next_aa=>"S", :protein=>"gi|49176370|ref|YP_026228.1|", :num_tot_proteins=>1, :num_matched_ions=>10, :tot_num_ions=>70, :calc_neutral_pep_mass=>1015.79382542, :massdiff=>-0.0209688753124055, :num_tol_term=>2, :num_missed_cleavages=>0, :is_rejected=>0, :xcorr=>1.06543827056885, :deltacn => 0.192325830459595, :deltacnstar=>0, :spscore=>77.8397979736328, :sprank=>3, :probability=>0.07881571, :fval=>0.1592, :ntt=>2, :nmc=> 0, :massd=>-0.021}, 
  :last => { :hit_rank=>1, :peptide=>"VAALRVPGGASLTR", :peptide_prev_aa=>"R", :peptide_next_aa=>"K", :protein=>"gi|16129819|ref|NP_416380.1|", :num_tot_proteins=>1, :num_matched_ions=>16, :tot_num_ions=>78, :calc_neutral_pep_mass=>1447.58289842, :massdiff=> 0.0211348825000641, :num_tol_term=>2, :num_missed_cleavages=>1, :is_rejected=>0, :xcorr=>1.3090912103653, :deltacn => 0.259967535734177, :deltacnstar => 0, :spscore => 118.513412475586, :sprank => 4, :probability=>0.27738378, :fval=>1.3810, :ntt=>2, :nmc=>1, :massd=>0.021 },
}
}


describe Proph::PepSummary, "reading a small .xml file" do
  before(:each) do
    file = Tfiles + '/opd1_2runs_2mods/interact-opd1_mods__small.xml'
    @obj = Proph::PepSummary.new(file)
  end

  it 'should raise an error if not a peptide prophet file' do
    lambda { Proph::PepSummary.new(Tfiles + '/opd1/000.tpp_2.9.2.first10.xml')}.should raise_error(ArgumentError)
  end

  it 'has msms_run_summary objects with spectrum_queries' do
    @obj.msms_run_summaries.size.should == 1
    sqs = @obj.msms_run_summaries.first.spectrum_queries
    sqs.size.should == 18

    [:first, :last].each do |mth|
      ToCheck[:spectrum_query][mth].each do |k,v|
        if v.is_a? Float
          sqs.send(mth).send(k).should be_close(v, 0.0000000001)
        else
          sqs.send(mth).send(k).should == v
        end
      end
      ToCheck[:search_hit][mth].each do |k,v|
        if v.is_a? Float
          sqs.send(mth).search_results.first.search_hits.first.send(k).should be_close(v, 0.0000000001)
        else
          sqs.send(mth).search_results.first.search_hits.first.send(k).should == v
        end
      end
    end
  end

  it 'has pephits (which are descended from SearchHit)' do
    @obj.peps.size.should == 18
    [:hit_rank, :probability, :fval, :ntt, :nmc, :massd].each do |guy|
      @obj.peps.first.should respond_to(guy)
    end

    [:first, :last].each do |mth|
      ToCheck[:search_hit][mth].each do |k,v|
        if v.is_a? Float
          @obj.peps.send(mth).send(k).should be_close(v, 0.0000000001)
        else
          @obj.peps.send(mth).send(k).should == v
        end
      end
    end

  end

end

describe Proph::PepSummary, 'reading a large .xml file' do 
  spec_large do 
    before(:all) do 
      file = Tfiles_l + '/opd1_2runs_2mods/prophet/interact-opd1_mods.xml'
      @obj = Proph::PepSummary.new(file) 
    end

    it 'has peps of class Proph::PepSummary::Pep' do
      @obj.peps.first.class.to_s.should == 'Proph::PepSummary::Pep'
      @obj.peps.size.should == 1643
    end

    it 'contains peps that respond_to :aaseq' do
      @obj.peps.first.should respond_to(:aaseq)
    end

    it 'has prots (also callable from peps)' do
      (@obj.prots.size > 0).should be_true
      @obj.peps.all? {|v| v.prots.size > 0 }.should be_true 
      peps_with_prots = @obj.peps.select {|v| v.prots.size > 1 }
      # frozen:
      peps_with_prots.first.prots.size.should == 3
      peps_with_prots.first.prots.first.name.should == "gi|16128676|ref|NP_415229.1|"
      peps_with_prots.first.prots.first.protein_descr.should == "RhsC protein in RhsC element [Escherichia coli K12]"
      peps_with_prots.first.prots.first.reference.should == "gi|16128676|ref|NP_415229.1| RhsC protein in RhsC element [Escherichia coli K12]"
      peps_with_prots.first.prots.last.protein_descr.should == "RhsA protein in RhsA element [Escherichia coli K12]"
    end
  end
end


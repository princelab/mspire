require File.expand_path( File.dirname(__FILE__) + '/../../spec_helper' )
require 'spec_id/srf'
require 'spec_id/precision/filter'

require File.dirname(__FILE__) + '/../../spec_id_helper'

require 'set'
require 'set_from_hash'

describe SpecID::Precision::Filter::Peps do
  it 'does basic top hit filtering with ties=true|false|:as_array' do
    hashes = [
      {:aaseq=> 'A', :first_scan => 1, :xcorr => 1.5, :deltacn => 0.1, :ppm => 40, :charge => 2}, # 0
      {:aaseq=> 'B', :first_scan => 1, :xcorr => 1.5, :deltacn => 0.1, :ppm => 40, :charge => 2}, # 1
      {:aaseq=> 'C', :first_scan => 1, :xcorr => 1.4, :deltacn => 0.1, :ppm => 40, :charge => 2}, # 2
      {:aaseq=> 'D', :first_scan => 1, :xcorr => 1.4, :deltacn => 0.2, :ppm => 25, :charge => 2}, # 3
      {:aaseq=> 'D', :first_scan => 2, :xcorr => 1.9, :deltacn => 0.1, :ppm => 25, :charge => 2}, # 4
    ]
    pep_klass = SRF::OUT::Pep
    @sequest_peps = hashes.map do |hash|
      hash[:prots] = []
      pep = pep_klass.new.set_from_hash(hash) 
    end
    # no tie:
    options = { 
      :per => [:first_scan, :charge], 
      :by => [:xcorr, {:down => [:xcorr]}], 
      :ties => false
    }
    peps = SpecID::Precision::Filter::Peps.new.top_hit(@sequest_peps, options)
    peps.size.should == 2
    set_of_hash_xcorrs = [0,4].map {|i| hashes[i][:xcorr] }.to_set
    peps.map {|v| v.xcorr }.to_set.should == set_of_hash_xcorrs

    # with tie == true:
    options[:ties] = true
    peps = SpecID::Precision::Filter::Peps.new.top_hit(@sequest_peps, options)
    peps.size.should == 3
    set_of_hash_xcorrs = [0,1,4].map {|i| hashes[i][:xcorr] }.to_set
    peps.map{|v| v.xcorr}.to_set.should == set_of_hash_xcorrs

    # with tie == :as_array
    options[:ties] = :as_array
    peps = SpecID::Precision::Filter::Peps.new.top_hit(@sequest_peps, options)
    peps.size.should == 2
    peps.any? {|v| v.class == Array }.should be_true
    peps.select {|v| v.is_a? pep_klass }.first.should equal(@sequest_peps[4])
  end
end


describe 'filtering on a small bioworks file' do
  before(:each) do
    @file = Tfiles + '/bioworks_small.xml'
    @spec_id = SpecID.new(@file)
  end

  it 'filters with basic sequest filters' do
    opts = {:sequest => {:xcorr1 => 1.0, :xcorr2 => 1.0, :xcorr3 => 1.0, :deltacn => 0.1, :ppm => 1000.0, :include_deltacnstar => false} }
    ans = SpecID::Precision::Filter.new.filter_and_validate(@spec_id, opts)
    
  
    ans[:params][:sequest].should == opts[:sequest]
    # FROZEN:
    ans[:pephits].size.should == 4

    ans[:pephits].each do |pephit|
      pephit.pass_filters?(opts[:sequest]).should be_true
      pephit.fail_filters?(opts[:sequest]).should be_false
    end
    before = @spec_id.peps.size
    ans[:pephits].each do |pephit|
      @spec_id.peps.delete(pephit)
    end
    @spec_id.peps.size.should == before - 4
    @spec_id.peps.each do |not_passing_pep|
      not_passing_pep.pass_filters?(opts[:sequest]).should_not be_true
    end
    
    ans[:pephits].map {|v| v.aaseq }.to_set.size == 4
  end

   it 'can exclude deltacnstar' do
    opts = {:sequest => {:xcorr1 => 1.0, :xcorr2 => 1.0, :xcorr3 => 1.0, :deltacn => 0.1, :ppm => 1000.0, :include_deltacnstar => false} }
    # make two hits have the deltacnstar deltacn of 1.1
    sorted = @spec_id.peps.sort_by {|pep| [pep.xcorr, pep.deltacn, 1.0/pep.ppm, pep.first_scan, pep.aaseq] }
    # for two of these indices:
    [286, 287].each do |index| 
      sorted[index].deltacn = 1.1
      sorted[index].deltacn.should == 1.1
    end
    ans = SpecID::Precision::Filter.new.filter_and_validate(@spec_id, opts)
  
    ans[:params][:sequest].should == opts[:sequest]
    # FROZEN:
    ans[:pephits].size.should == 2
  end
 
end

describe 'filtering on small bioworks file with inverse prots' do
  before(:each) do
    @regexp = /^INV_/o
    @file = Tfiles + '/bioworks_with_INV_small.xml'
    @spec_id = SpecID.new(@file)
    vals = [Validator::Decoy.new(:constraint => @regexp)]
    @opts = {:sequest => {:xcorr1 => 1.0, :xcorr2 => 1.0, :xcorr3 => 1.0, :deltacn => 0.1, :ppm => 1000.0, :include_deltacnstar=> false}, :validators => vals}
  end

  it 'gets decoy precision' do
    ans = SpecID::Precision::Filter.new.filter_and_validate(@spec_id, @opts)
    peps = ans[:pephits]
    vals = ans[:pephits_precision]
    # FROZEN:
    peps.size.should == 150
    peps.hash_by(:aaseq).size.should == 74
    vals.first.should == 149.0/150
  end

  it 'gets cys precision with freq' do
    # this does a minimal test to see if this functions properly
    # (not for accuracy, which is done in validator_spec)
    ## WITH FASTA FILE:
    val1 = Validator::AAEst.new('C').set_frequency(Fasta.new(Tfiles + '/small.fasta').prots)
    @opts[:validators] << val1   # obviously this guy is not his
    ans1 = SpecID::Precision::Filter.new.filter_and_validate(@spec_id, @opts)
    peps = ans1[:pephits]
    vals1 = ans1[:pephits_precision]
    # FROZEN:
    vals1.last.should be_close(0.84432189117806, 0.0000000001)

    ## WITH A CYSTEINE BACKGROUND:
    background_cys = 0.0172
    val3 = Validator::AAEst.new('C', :background => background_cys).set_frequency(Fasta.new(Tfiles + '/small.fasta').prots)
    @opts[:validators][1] = val3
    ans3 = SpecID::Precision::Filter.new.filter_and_validate(@spec_id, @opts)
    peps = ans3[:pephits]
    vals3 = ans3[:pephits_precision]
    # FROZEN:
    vals3.last.should be_close(0.944734271368211, 0.00000000001)
  end
end

describe 'filtering on a real srf file' do

  spec_large do
    it 'does tmm with a toppred file on srf' do
      opts = {:sequest => {:xcorr1 => 1.0, :xcorr2 => 1.0, :xcorr3 => 1.0, :deltacn => 0.1, :ppm => 1000.0, :include_deltacnstar => false}}
      dir = Tfiles_l + '/opd1_2runs_2mods/sequest33'
      tmm_file = dir + '/ecoli_K12_ncbi_20060321.toppred.xml'
      fasta_file = dir + '/ecoli_K12_ncbi_20060321.fasta'
      sequest_file = dir + '/ecoli.params'
      srf_file = dir + '/020.srf'
      spec_id = SpecID.new(srf_file)
      #   :tmm   -> [transmembrane file,min_tm_seqs=1,expect_soluble=true,correct_wins=true,no_include_tm_peps=0.8, bkg=0]  # a toppred.out file
      
      regexp = /FAKINGIT_OUT/
      opts[:decoy] = regexp
      decoy_val = Validator::Decoy.new(:constraint => regexp) # this is not real, just to test
      cys_val = Validator::AAEst.new('C').set_frequency(Fasta.new(fasta_file).prots)
      tmm_val = Validator::Transmem::Protein.new(tmm_file, :min_num_tms => 1, :soluble_fraction => true, :correct_wins => true, :no_include_tm_peps => false, :background => 0.0).set_false_to_total_ratio( Digestor.digest( Fasta.new(fasta_file), Sequest::Params.new(sequest_file) ) )
      opts[:validators] = [decoy_val, cys_val, tmm_val]
      ans = SpecID::Precision::Filter.new.filter_and_validate(spec_id, opts)
      peps = ans[:pephits]
      vals = ans[:pephits_precision]

      # frozen:
      vals[0].should == 1.0 
      vals[1].should be_close(0.366612274427855, 0.00000001)
      #vals[2].should be_close(0.396396396396396, 0.00000001)
      # if the srf file is not 'filtered' by proper sequest vals, should give
      # this:
      #vals[2].should be_close(-0.204031426241371, 0.00000001)
      vals[2].should be_close(-0.199538771665843, 0.00000001)
      peps.size.should == 444
    end
  end

    # This is what I was doing before.  I think I may have been forgetting to
    # remove the INV_ peptide from these counts!
    # or more likely, the peptide hits were pep+prot hits!
    #  SpecID::Filterer.run_from_argv([@small_inv].push( *(%w(-1 1.0 -2 1.0 -3 1.0 -c 0.1 --ppm 1000 -f INV_))) )
    ### FROZEN:
    #assert_match(/pep_hits\s+151/, output)
    #assert_match(/uniq_aa_hits\s+75/, output)
    #assert_match(/prot_hits\s+13/, output)

end

describe SpecID::Precision::Filter::Peps do

  before(:all) do
    hashes = [
      {:xcorr => 1.2, :deltacn => 0.1, :ppm => 40, :charge => 2},
      {:xcorr => 1.3, :deltacn => 0.1, :ppm => 50, :charge => 3},
      {:xcorr => 1.4, :deltacn => 0.1, :ppm => 50, :charge => 1},
      {:xcorr => 1.5, :deltacn => 1.1, :ppm => 20, :charge => 2},
      {:xcorr => 1.3, :deltacn => 0.1, :ppm => 20, :charge => 2},
      {:xcorr => 1.3, :deltacn => 0.1, :ppm => 40, :charge => 2},
    ]
    @sequest_peps = hashes.map do |hash|
      pep = SRF::OUT::Pep.new.set_from_hash(hash) 
    end
    #sp = GenericSpecID.new.set_from_hash({:peps => peps})

  end

  it 'filters sequest peptides' do
    args_and_expected = {
      #deltacnstar false
      [1.2, 1.2, 1.2, 0.1, 50, false] => 5, # "all passing"
      [1.6, 1.6, 1.6, 0.1, 50, false] => 0, # "xcorrs too high"
      [1.6, 1.0, 1.0, 0.1, 50, false] => 4, # "one xcorr too high"
      [1.0, 1.6, 1.0, 0.1, 50, false] => 2, # "one xcorr too high"
      [1.0, 1.0, 1.6, 0.1, 50, false] => 4, # "one xcorr too high"
      [1.2, 1.2, 1.2, 0.2, 50, false] => 0, # "high deltacn"

      ## includedeltcnstars :
      [1.2, 1.2, 1.2, 0.1, 50, true] => 6, # "all passing"
      [1.2, 1.2, 1.2, 0.2, 50, true] => 1, # "high deltacn"
      [1.0, 1.0, 1.6, 0.1, 50, true] => 5, # "one xcorr too high"
      ## 
      [1.0, 1.0, 1.0, 0.05, 60, true] => 6,  ## testing ppm filtering:
      [1.0, 1.0, 1.0, 0.05, 10, true] => 0,
    }
    args_and_expected.each do |args,exp|
      filt = SpecID::Precision::Filter::Peps.new(:standard_sequest_filter, *args)
      filt.filter(@sequest_peps).size.should == exp
    end
  end

  it 'can change the pep array permanently' do
    args_and_expected = {[1.2, 1.2, 1.2, 0.2, 50, true] => 1} # "high deltacn"
    array_to_change = @sequest_peps.dup
    array_to_change.size.should == @sequest_peps.size
    args_and_expected.each do |args,exp|
      filt = SpecID::Precision::Filter::Peps.new(:standard_sequest_filter, *args)
      filt.filter!(array_to_change)
    end
    array_to_change.size.should_not == @sequest_peps.size
  end

end




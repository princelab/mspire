require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

require 'spec_id'
require 'spec_id/srf'

# we use this to set the values of generic proteins below
require 'set_from_hash'


describe 'creating a list of proteins from peptides', :shared => true do
  before(:each) do
    # EXPECTS @prots and a @meth proc that takes two args, an array of
    # peptides and the details of the list creation

    hashes = [
      {:aaseq => 'PEP0', :xcorr => 1.2, :deltacn => 0.1, :ppm => 40, :charge => 2, :prots => [prots[0],prots[1]]},
      {:aaseq => 'PEP1', :xcorr => 1.3, :deltacn => 0.1, :ppm => 50, :charge => 3, :prots => [prots[1],prots[2]]},
      {:aaseq => 'PEP2', :xcorr => 1.4, :deltacn => 0.1, :ppm => 50, :charge => 1, :prots => [prots[3]]},
      {:aaseq => 'PEP3', :xcorr => 1.5, :deltacn => 1.1, :ppm => 20, :charge => 2, :prots => [prots[4]]},
      {:aaseq => 'PEP4', :xcorr => 1.3, :deltacn => 0.1, :ppm => 20, :charge => 2, :prots => [prots[0]]},
      {:aaseq => 'PEP5', :xcorr => 1.3, :deltacn => 0.1, :ppm => 40, :charge => 2, :prots => prots[1,2]},
    ]

    @peps = hashes.map do |hash|
      SRF::OUT::Pep.new.set_from_hash(hash) 
    end
  end

  it 'compiles protein lists from peps not touching peps attr (:no_update)' do

    prts = @meth.call(@peps, :no_update)
    exp = (0..4).map do |n|
      "prot_" + n.to_s
    end
    refs = prts.map {|v| v.reference }.sort
    refs.should == exp
    prts.each do |prt|
      prt.peps.should == []
    end
  end

  it 'compiles protein lists with updated peps attribute (:update)' do

    prts = @meth.call(@peps, :update)
    prot_0_before = prts.select {|v| v.reference == 'prot_0'}.first
    protein_match(prts, 'prot_0', %w(PEP0 PEP4))
    protein_match(prts, 'prot_1', %w(PEP0 PEP1 PEP5))
    protein_match(prts, 'prot_2', %w(PEP1 PEP5))
    protein_match(prts, 'prot_3', %w(PEP2))
    protein_match(prts, 'prot_4', %w(PEP3))
    srt_ref = prts.map {|v| v.reference}.sort
    %w(prot_0 prot_1 prot_2 prot_3 prot_4).should == srt_ref  # just the right number of prots
    prot_0 = prts.select {|v| v.reference == 'prot_0'}.first
    prot_0_before.__id__.should ==  prot_0.__id__ # proteins are identical


    prot_0_before = prts.select {|v| v.reference == 'prot_0'}.first.__id__
  end

  it 'compiles protein lists of new proteins (:new)' do
    prts = SpecID.protein_list(@peps, :new)
    prot_0_before = prts.select {|v| v.reference == 'prot_0'}.first
    protein_match(prts, 'prot_0', %w(PEP0 PEP4))
    protein_match(prts, 'prot_1', %w(PEP0 PEP1 PEP5))
    protein_match(prts, 'prot_2', %w(PEP1 PEP5))
    protein_match(prts, 'prot_3', %w(PEP2))
    protein_match(prts, 'prot_4', %w(PEP3))
    srt_ref = prts.map {|v| v.reference}.sort
    #assert_equal(%w(prot_0 prot_1 prot_2 prot_3 prot_4), srt_ref, "just the right number of prots")
    %w(prot_0 prot_1 prot_2 prot_3 prot_4).should == srt_ref # just the right number of prots
    prot_0 = prts.select {|v| v.reference == 'prot_0'}.first
    #assert_not_equal(prot_0_before, prot_0.__id__, "proteins are not identical")
    prot_0_before.should_not == prot_0.__id__ # proteins are not identical
  end

  # checks that among prts, the protein with ref has peptides with pepseqs
  # aaseqs
  def protein_match(prts, ref, pepseqs)
    prt = prts.select{|v| v.reference == ref }.first
    sorted_prt_peps_aaseqs = prt.peps.map {|v| v.aaseq }.sort 
    sorted_pepseqs = pepseqs.sort
    pepseqs.should == sorted_prt_peps_aaseqs
  end

end

describe SpecID, 'with generic proteins' do
  include SpecID
  before(:all) do
    @prots = (0..7).map do |n|
      SpecID::GenericProt.new.set_from_hash({:reference => "prot_"+n.to_s, :peps => []})
    end
    @meth = proc {|peps, kind| SpecID.protein_list(peps, kind) }
  end
  it_should_behave_like 'creating a list of proteins from peptides'
end

describe SpecID, 'with array based proteins' do
  include SpecID
  before(:all) do
    @prots = (0..7).map do |n|
      SRF::OUT::Prot.new.set_from_hash({:reference => "prot_"+n.to_s, :peps => []})
    end
    @meth = proc {|peps, kind| SpecID.protein_list(peps, kind) }
  end
  it_should_behave_like 'creating a list of proteins from peptides'
end

module Boolean ; end
class TrueClass ; include Boolean end
class FalseClass; include Boolean end

describe SpecID, 'being created' do
  include SpecID
  it 'can be from small bioworks.xml' do
    sp = SpecID.new(Tfiles + '/bioworks_small.xml')
    sp.prots.size.should == 106
  end

  it 'can be from small -prot.xml (newer prophet versions)' do
    prot_xml = Tfiles + '/interact-opd1_mods_small-prot.xml'
    sp = SpecID.new(prot_xml)
    sp.is_a?(SpecID).should be_true
    sp.is_a?(Proph::ProtSummary).should be_true
    sp.prots.size.should == 20
    sp.peps.size.should == 31
    types = {
      :protein_name => String,
      :n_indistinguishable_proteins => Integer,
      :probability => Float,
      :percent_coverage => Float,
      :unique_stripped_peptides => Array,
      :group_sibling_id => String,
      :total_number_peptides => Integer,
      :pct_spectrum_ids => Float,
      :peps => Array,
    }
    sp.prots.each do |prot|
      types.each { |cl,tp| prot.send(cl).is_a?(tp).should be_true }
    end
    types = {
      :aaseq => String,
      :peptide_sequence => String,
      :charge => Integer,
      :initial_probability => Float,
      :nsp_adjusted_probability => Float,
      :weight => Float,
      :is_nondegenerate_evidence => Boolean,  # no Boolean class
      :n_enzymatic_termini => Integer,
      :n_sibling_peptides => Float,
      :n_sibling_peptides_bin => Integer,
      :n_instances => Integer,
      :is_contributing_evidence => Boolean,
      :calc_neutral_pep_mass => Float,
      :modification_info => Object,
      :mod_info => Object,
    }
    sp.peps.each do |pep|
      types.each { |cl,tp| pep.send(cl).is_a?(tp).should be_true }
    end
    prot_ars = []
    sp.peps.each do |pep|
      if pep.prots.size > 1
        prot_ars << pep.prots
      end
    end
    prot_ars.each do |prt_ar|
      prt_ar.each do |prt|
        # the nils because this is a small file and their proteins are not
        # found
        ((prt.is_a?(SpecID::Prot) == true) or  prt.nil?).should be_true
        ((prt.is_a?(Proph::Prot) == true) or prt.nil?).should be_true
      end
    end
    mod_objects = []
    sp.peps.each do |pep| 
      if !pep.mod_info.nil? 
        mod_objects << pep.mod_info
      end
    end
    # frozen
    mod_objects.size.should == 23
  end

  spec_large do
    it 'works on a large file' do
      file = Tfiles_l + '/opd1_2runs_2mods/prophet/interact-opd1_mods-prot.xml'
      #file = '/work/john/db_quest/verify_prophet/orbi/prophet_results/orbi_f00-prot.xml'
      start = Time.now
      sp = SpecID.new(file)
      puts "- Took #{Time.now - start} seconds to read"
      prot_ars = []
      sp.peps.each do |pep|
        if pep.prots.size > 1
          prot_ars << pep.prots
        end
      end
      prot_ars.each do |prt_ar|
        prt_ar.each do |prt|
          # the nils because this is a small file and their proteins are not
          # found
          prt.is_a?(SpecID::Prot).should be_true
          prt.is_a?(Proph::Prot).should be_true
        end
      end

    end
  end

  it_should 'can be from -prot.xml (older prophet versions)' do
    prot_xml = Tfiles + '/4-03-03_small-prot.xml'
    prot_xml = Tfiles + '/yeast_gly_small-prot.xml'
  end
end

describe SpecID, 'class methods' do

  it 'determines filetype (small files)' do
    files = {
      :bioworks => Tfiles + "/bioworks_small.xml",
      :protproph => Tfiles + '/opd1/000_020_3prots-prot.xml',
      :pepproph => Tfiles + '/opd1_2runs_2mods/interact-opd1_mods__small.xml',
      :srf => Tfiles + '/head_of_7MIX.srf',
      :srg => 'whatever.srg',
      :sqt => Tfiles + '/small.sqt',
      :sqg => 'whatever.sqg',
    }
    files.each do |key,val|
      SpecID.file_type(val).should == key.to_s
    end
    ## WOULD BE NICE TO GET THIS WORKING, TOO
    # assert_equal('protproph', SpecID.file_type(@old_prot_proph))
  end

  it 'can remove non-standard amino acids' do
    hash = {"K.PEPTIDE.Z" => "K.PEPTIDE.Z", "K.*M" => "K.M", "aI" => 'I', "YI.&" => "YI.", "EI.!@#\$%^&*(){}[]|\\;:'\"<>,?/EI" => 'EI.EI'}
    cl = proc {|v| SpecID::Pep.remove_non_amino_acids(v) }
    hash.each do |k,v|
      cl.call(k).should == v
    end
  end

end

describe SpecID, "determining the minimum set of proteins from pephits" do

  before(:all) do
    class MyProt ; include SpecID::Prot ; end
    class MyPep ; include SpecID::Pep ; attr_accessor :xcorr end
  end

  it 'can do occams razor on small set' do
    
    prots = (0..6).to_a.map do |n|
      prot = MyProt.new
      prot.reference = "ref_#{n}"
      prot
    end

    peps = (0..12).to_a.map {|v| MyPep.new }

    #           0   1   2   3   4   5   6   7   8   9   10  11    12 
    aaseqs = %w(AAA BBB CCC ABC AAA BBB CCC ABC DDD EEE FFF EEEEE DDD)
    xcorrs = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 0.5, 0.6, 0.7, 0.8, 0.5]

    peps.zip(aaseqs, xcorrs) do |pep,aaseq,xcorr|
      pep.aaseq = aaseq
      pep.xcorr = xcorr
    end

    prots[0].peps = peps[0,4]
    prots[1].peps = [peps[2]]  ## should be missing

    test_prots = prots[0,2]
    answ = SpecID.occams_razor(test_prots)
    answ.each do |an|
      an[0].is_a?(SpecID::Prot).should be_true
    end
    first = answ.first
    first[0].should == prots[0]
    equal_array_content( prots[0].peps, first[1])

    require 'pp'
    #pp answ


    prots[0].peps = peps[0,4]
    prots[1].peps = [peps[2]]  ## should be missing
    prots[2].peps = []  ## should be missing

    answ = SpecID.occams_razor(test_prots, true)
    puts '- NEED MORE tests HERE!' if $specdoc
    #pp answ


    #prots[2].peps = [peps[2]]
    #prots[2].peps.push( peps[3] ) ## should be there since it has 2
    #prots[3].peps = [peps[3]] ## should be missing
  end

  def equal_array_content(exp1, ans, message='')
    exp1.each do |item|
      ans.should include(item)
    end
  end


end


require 'fasta'

describe SpecID::Pep, "with a small fasta object" do
  before(:each) do
    @prots = []

    aaseq = ('A'..'Z').to_a.join('')
    header = "prot1"
    @prots << Fasta::Prot.new(header, aaseq)

    aaseq = ('A'..'Z').to_a.reverse.join('')
    header = "prot1_reverse"
    @prots << Fasta::Prot.new(header, aaseq)

    aaseq = ('A'..'Z').to_a.join('')
    header = "prot1_identical"
    @prots << Fasta::Prot.new(header, aaseq)

    aaseq = ('A'..'E').to_a.join('')
    header = "prot1_short"
    @prots << Fasta::Prot.new(header, aaseq)

    aaseq = ('A'..'E').to_a.reverse.join('')
    header = "prot1_reverse_short"
    @prots << Fasta::Prot.new(header, aaseq)

    @fasta = Fasta.new(@prots)

  end
  it "can find protein groups from a fasta object" do
    pep_seqs = %w(ABCD DEFG ABCD DEFG EDCB FEDCB XYZ RANDOM AEABA) 
    arr = SpecID::Pep.protein_groups_by_sequence(pep_seqs, @fasta)

    prots = @prots
    exp = [[prots[0], prots[2], prots[3]], [prots[0], prots[2]], [prots[0], prots[2], prots[3]], [prots[0],prots[2]], [prots[1], prots[4]], [prots[1]], [prots[0], prots[2]], [], []]

    arr.should == exp
  end
end


###########################
# old tests
###########################

=begin
def test_classify_by_false_flag
  file = @tfiles + "bioworks_with_INV_small.xml"
  sp = SpecID.new(file)
  assert_equal(19, sp.prots.size)
  (tp, fp) = sp.classify_by_false_flag(:prots, "INV_", true, true)
  assert_equal(4, fp.size, "num false pos")
  assert_equal(15, tp.size, "num true pos")
end

=end

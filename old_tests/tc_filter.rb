
require 'test/unit'
require 'spec_id/filter'
require 'spec_id/srf'
require 'set_from_hash'
require File.dirname(__FILE__) + '/test_helper'

$VERBOSE = false


class TestFilterer < Test::Unit::TestCase

  def initialize(arg)
    super(arg)
    @tfiles = File.dirname(__FILE__) + '/tfiles/'
    @tfiles_l = File.dirname(__FILE__) + '/tfiles_large/'
    @small_inv = @tfiles + 'bioworks_with_INV_small.xml'
    @small = @tfiles + 'bioworks_small.xml'
    ## SRF:
    @zero_srf = @tfiles_l + 'opd1_cat_inv/000.srf'
    @twenty_srf = @tfiles_l + 'opd1_cat_inv/020.srf'
    @zero_srg = @tfiles_l + 'bioworks_000.srg'
    @both_srg = @tfiles_l + 'bioworks_both.srg'
    ## FASTA:
    @opd1_fasta = @tfiles_l + 'opd1_cat_inv/ecoli_K12_ncbi_20060321.fasta'
    @opd1_correct_fasta = @tfiles_l + 'opd1_cat_inv/correct_fictitious_314.fasta'
    if File.exist? @tfiles_l
      File.open(@zero_srg, 'w') {|fh| fh.puts( File.expand_path(@zero_srf) ) }
      File.open(@both_srg, 'w') {|fh| fh.puts( File.expand_path(@zero_srf) ); fh.puts( File.expand_path(@twenty_srf) ) }
    end
  end

  def setup
    if File.exist? @tfiles_l
      File.open(@zero_srg, 'w') {|fh| fh.puts( File.expand_path(@zero_srf) ) }
      File.open(@both_srg, 'w') {|fh| fh.puts( File.expand_path(@zero_srf) ); fh.puts( File.expand_path(@twenty_srf) ) }
    end
  end

  def teardown
    if File.exist? @tfiles_l
      File.unlink @zero_srg
      File.unlink @both_srg
    end
  end

  def test_protein_fppr
    peps_per_prot = [4,4,3,2,2]
    (num, mean_fppr, std_num, std_fppr) = SpecID::Filterer.new.protein_fppr(peps_per_prot, 1, 10)
    assert_equal(0, mean_fppr, "no prots completely wrong")    
    assert_equal(0, std_fppr, "no prots completely wrong")    
    (num, mean_fppr, std_num, std_fppr) = SpecID::Filterer.new.protein_fppr(peps_per_prot, 14, 10)
    assert_equal(4.0/5, mean_fppr, "only one prot right")    
    assert_equal(0.0, std_fppr, "only one prot right")    
  end

  def test_filter_sequest
    hashes = [
      {:xcorr => 1.2, :deltacn => 0.1, :ppm => 40, :charge => 2},
      {:xcorr => 1.3, :deltacn => 0.1, :ppm => 50, :charge => 3},
      {:xcorr => 1.4, :deltacn => 0.1, :ppm => 50, :charge => 1},
      {:xcorr => 1.5, :deltacn => 1.1, :ppm => 20, :charge => 2},
      {:xcorr => 1.3, :deltacn => 0.1, :ppm => 20, :charge => 2},
      {:xcorr => 1.3, :deltacn => 0.1, :ppm => 40, :charge => 2},
    ]
    peps = hashes.map do |hash|
      pep = SRF::OUT::Pep.new.set_from_hash(hash) 
    end
    sp = GenericSpecID.new.set_from_hash({:peps => peps})
    before_size = sp.peps.size
    assert_filter([1.2, 1.2, 1.2, 0.1, 50], sp, 5, "all passing")
    assert_filter([1.6, 1.6, 1.6, 0.1, 50], sp, 0, "xcorrs too high")
    assert_filter([1.6, 1.0, 1.0, 0.1, 50], sp, 4, "one xcorr too high")
    assert_filter([1.0, 1.6, 1.0, 0.1, 50], sp, 2, "one xcorr too high")
    assert_filter([1.0, 1.0, 1.6, 0.1, 50], sp, 4, "one xcorr too high")
    assert_filter([1.2, 1.2, 1.2, 0.2, 50], sp, 0, "high deltacn")

    ## with deltcnstars:
    assert_filter([1.2, 1.2, 1.2, 0.1, 50], sp, 6, "all passing", true)
    assert_filter([1.2, 1.2, 1.2, 0.2, 50], sp, 1, "high deltacn", true)
    assert_filter([1.0, 1.0, 1.6, 0.1, 50], sp, 5, "one xcorr too high", true)
  end

  def assert_filter(filter_args, spec_id, expected_passing, message, include_deltcn=false)
    npeps = spec_id.filter_sequest(filter_args, include_deltcn)
    assert_equal(expected_passing, npeps.size, message)
  end

  def test_passing_proteins
    hash_prots = (0..7).map do |n|
      SpecID::GenericProt.new.set_from_hash({:reference => "prot_"+n.to_s, :peps => []})
    end
    arr_prots = (0..7).map do |n|
      SRF::OUT::Prot.new.set_from_hash({:reference => "prot_"+n.to_s, :peps => []})
    end
    [hash_prots, arr_prots].each do |prots|

      hashes = [
        {:aaseq => 'PEP0', :xcorr => 1.2, :deltacn => 0.1, :ppm => 40, :charge => 2, :prots => [prots[0],prots[1]]},
        {:aaseq => 'PEP1', :xcorr => 1.3, :deltacn => 0.1, :ppm => 50, :charge => 3, :prots => [prots[1],prots[2]]},
        {:aaseq => 'PEP2', :xcorr => 1.4, :deltacn => 0.1, :ppm => 50, :charge => 1, :prots => [prots[3]]},
        {:aaseq => 'PEP3', :xcorr => 1.5, :deltacn => 1.1, :ppm => 20, :charge => 2, :prots => [prots[4]]},
        {:aaseq => 'PEP4', :xcorr => 1.3, :deltacn => 0.1, :ppm => 20, :charge => 2, :prots => [prots[0]]},
        {:aaseq => 'PEP5', :xcorr => 1.3, :deltacn => 0.1, :ppm => 40, :charge => 2, :prots => prots[1,2]},
      ]

      peps = hashes.map do |hash|
        SRF::OUT::Pep.new.set_from_hash(hash) 
      end


      prts = SpecID.passing_proteins(peps)
      exp = (0..4).map do |n|
      "prot_" + n.to_s
      end
      refs = prts.map { |v| v.reference }.sort
      assert_equal(exp, refs)


      prts = SpecID.passing_proteins(peps, :update)
      prot_0_before = prts.select {|v| v.reference == 'prot_0'}.first
      assert_protein_match(prts, 'prot_0', %w(PEP0 PEP4))
      assert_protein_match(prts, 'prot_1', %w(PEP0 PEP1 PEP5))
      assert_protein_match(prts, 'prot_2', %w(PEP1 PEP5))
      assert_protein_match(prts, 'prot_3', %w(PEP2))
      assert_protein_match(prts, 'prot_4', %w(PEP3))
      srt_ref = prts.map {|v| v.reference}.sort
      assert_equal(%w(prot_0 prot_1 prot_2 prot_3 prot_4), srt_ref, "just the right number of prots")
      prot_0 = prts.select {|v| v.reference == 'prot_0'}.first
      assert_equal(prot_0_before.__id__, prot_0.__id__, "proteins are identical")


      prot_0_before = prts.select {|v| v.reference == 'prot_0'}.first.__id__

      prts = SpecID.passing_proteins(peps, :new)
      assert_protein_match(prts, 'prot_0', %w(PEP0 PEP4))
      assert_protein_match(prts, 'prot_1', %w(PEP0 PEP1 PEP5))
      assert_protein_match(prts, 'prot_2', %w(PEP1 PEP5))
      assert_protein_match(prts, 'prot_3', %w(PEP2))
      assert_protein_match(prts, 'prot_4', %w(PEP3))
      srt_ref = prts.map {|v| v.reference}.sort
      assert_equal(%w(prot_0 prot_1 prot_2 prot_3 prot_4), srt_ref, "just the right number of prots")
      prot_0 = prts.select {|v| v.reference == 'prot_0'}.first
      assert_not_equal(prot_0_before, prot_0.__id__, "proteins are not identical")

    end
  end

  def assert_protein_match(prts, ref, pepseqs, message='') 
    prt = prts.select{|v| v.reference == ref }.first
    sorted_prt_peps_aaseqs = prt.peps.map {|v| v.aaseq }.sort 
    sorted_pepseqs = pepseqs.sort
    assert_equal(pepseqs, sorted_prt_peps_aaseqs, message)
  end

  def test_usage
    output = capture_stdout {
      SpecID::Filterer.run_from_argv([])
    }
    assert_match('usage:', output)
  end

  def test_basic_bioworks_xml

    output = capture_stdout {
      SpecID::Filterer.run_from_argv([@small].push( *(%w(-1 1.0 -2 1.0 -3 1.0 -c 0.1 --ppm 1000))) )
    }
    ## FROZEN:
    assert_match(/pep_hits\s+4/, output)
    assert_match(/uniq_aa_hits\s+4/, output)
    assert_match(/prot_hits\s+4/, output)
    

    output = capture_stdout {
      SpecID::Filterer.run_from_argv([@small_inv].push( *(%w(-1 1.0 -2 1.0 -3 1.0 -c 0.1 --ppm 1000 -f INV_))) )
    }
    #puts ""
    #puts output
    ## FROZEN:
    assert_match(/pep_hits\s+151/, output)
    assert_match(/uniq_aa_hits\s+75/, output)
    assert_match(/prot_hits\s+13/, output)
  end
  
  def test_srf
    if File.exist? @tfiles_l
      ## dcy
      output = capture_stdout {
        SpecID::Filterer.run_from_argv([@zero_srg].push( *(%w(-1 1.0 -2 1.0 -3 1.0 -c 0.1 --ppm 1000 -f INV_))) )
      }
      ## FROZEN:
      #puts ""
      #puts output
      assert_match(/pep_hits\s+2111\s+107\.2/, output)
      assert_match(/uniq_aa_hits\s+2034\s+106\.6/, output)
      assert_match(/prot_hits\s+1454\s+100\.0/, output)

      ## cys tps fps COMBINED
      # tps are fictitious!
      output = capture_stdout {
        # that's the background freq for ecoli that this file's from
        SpecID::Filterer.run_from_argv([@zero_srg].push( *(%w(-1 1.0 -2 1.0 -3 1.0 -c 0.1 --ppm 1000 --occams_razor --cys 0.0115866200193321 --t).push(@opd1_correct_fasta))))
      }
      #puts ""
      #puts output
      ## FROZEN:
      assert_match(/num\s+tps%\s+cys%/, output, "header")
      assert_match(/pep_hits\s+4374\s+9\d\.\d.*\s+83\.7/, output)
      assert_match(/uniq_aa_hits\s+4203\s+9\d\.\d.*\s+82\.8/, output)
      assert_match(/prot_hits\s+2986\s+9\d\..*\s+7\d\./, output)
      assert_match(/occams.*\s+2986\s+8\d\..*\s+7\d\./, output)
    else
      assert_nil( puts("--SKIPPING TEST-- (missing dir: #{@tfiles_l})" ))
    end
  end

end

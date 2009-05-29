require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require File.expand_path( File.dirname(__FILE__) + '/../validator_helper' )

require 'validator/bias'

require File.dirname(__FILE__) + '/fasta_helper'
require 'spec_id'

klass = Validator::Bias

describe klass, "on small mock set" do
  before(:each) do
    @peps =  (0..6).to_a.map {|n| v = SpecID::GenericPep.new; v.aaseq = n.to_s ; v }
    references = %w(YAL002W  YAL001C YAL003W YAL004W YAL007C NOT_EXISTING1 NOT_EXISTING2 NOT_EXISTING3 NOT_EXISTING4)
    # index:        0        1       2       3       4       5             6             7
    # index: 8       
    @prots = references.map do |ref|
      v = SpecID::GenericProt.new
      v.reference = ref + " something else that we don't care about"
      v
    end

    # e=t  we expect to see the fasta proteins in our hit list
    # cw=t a single peptide hit from one of these proteins constitutes a true
    # positive
    # cw=f all peptide hits must come from one of these proteins to be a true
    # positive
    #
    # e=f  we do not expect to see the fasta obj proteins in our hit list
    # cw=t a single peptide hit from *outside* this list constitues a true
    # positive
    # cw=f a single peptide hit from our fasta object constitutes a false
    # positive
    #

    @peps[0].prots = [@prots[0], @prots[5], @prots[8]]  
    @peps[1].prots = [@prots[1], @prots[5], @prots[8]]  
    @peps[2].prots = [@prots[3], @prots[4], @prots[1]]  
    @peps[3].prots = [@prots[7], @prots[8]]             
    @peps[4].prots = [@prots[5], @prots[8]]             
    @peps[5].prots = [@prots[8]]                        
    @peps[6].prots = [@prots[5], @prots[6]]             

    #################################################
    # REFERENCE for small mock set:
    #################################################
    # pep 1inFst? allinFst? cw=t,e=t cw=t,e=f cw=f,e=f cw=f,e=t
    # 0   y       n         t        t        f        f
    # 1   y       n         t        t        f        f
    # 2   y       y         t        f        f        t
    # 3   n       n         f        t        t        f
    # 4   n       n         f        t        t        f
    # 5   n       n         f        t        t        f
    # 6   n       n         f        t        t        f
    # PR:                   3/7      6/7      4/7      1/7
    # tp:fp                 3:4      6:1      4:3      1:6

    @fasta_obj = FastaHelper::FastaObj
    @validator = klass.new(@fasta_obj)
    @validator.false_to_total_ratio = 0.22  # arbitrary
  end

  it_should_behave_like 'a validator'

  it 'creates correct reference hash' do
    expected = {"YAL001C"=>true, "YAL011W"=>true, "YAL010C"=>true,
    "YAL009W"=>true, "YAL008W"=>true, "YAL007C"=>true, "YAL005C"=>true,
    "YAL004W"=>true, "YAL003W"=>true, "YAL014C"=>true, "YAL013W"=>true,
    "YAL002W"=>true, "YAL012W"=>true
    }
    val = klass.new(@fasta_obj)
    val.short_reference_hash.should == expected
  end

  it 'gives correct precision and partitions (across all option combinations)' do
    answ = [[3,4], [6,1], [1,6], [4,3]]
    # cw=t,e=t; cw=t,e=f; cw=f,e=t; cw=f,e=f
    [true, false].each do |correct_wins|
      [true, false].each do |fasta_expected|
        val = klass.new(@fasta_obj, :proteins_expected => fasta_expected, :correct_wins => correct_wins, :false_to_total_ratio => 1.0)
        tp, fp = answ.shift
        exp = calc_precision(tp, fp)
        val.pephit_precision(@peps).should == exp
        act_tp, act_fp = val.partition(@peps)
        act_tp.size.should == tp
        act_fp.size.should == fp
      end
    end
  end

  it 'correctly incorporates background' do
    answ = [[3,4], [6,1], [1,6], [4,3]]
    # cw=t,e=t; cw=t,e=f; cw=f,e=t; cw=f,e=f
    background = 0.24
    [true, false].each do |correct_wins|
      [true, false].each do |fasta_expected|
        val = klass.new(@fasta_obj, :proteins_expected => fasta_expected, :correct_wins => correct_wins, :background => background, :false_to_total_ratio => 1.0)
        peps_size = @peps.size
        exp_tp, exp_fp = answ.shift
        exp = calc_precision(exp_tp, exp_fp)
        val.pephit_precision(@peps).should_not == exp
        actual_precision = val.pephit_precision(@peps)
        act_tp, act_fp = val.partition(@peps)
        act_tp.size.should == exp_tp
        act_fp.size.should == exp_fp
        exp_fp_correctd = exp_fp.to_f - (peps_size.to_f * background)
        expected_precision = calc_precision(peps_size.to_f - exp_fp_correctd, exp_fp_correctd)
        # internally, the num of false hits is controlled so as not to bottom
        # out below zero, here we control the precision (same effect)
        expected_precision = 1.0 if expected_precision > 1.0
        actual_precision.should == expected_precision
      end
    end
  end

  it_should 'work with false_to_total_ratio!'

  def calc_precision(tp, fp)
    prec = tp.to_f / (tp + fp)
  end
end


require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require File.expand_path( File.dirname(__FILE__) + '/../validator_helper' )

require 'validator/transmem'
require 'spec_id/digestor'
require File.dirname(__FILE__) + '/fasta_helper'
require 'spec_id'

klass = Validator::Transmem::Protein

describe klass, "on small mock set" do
  before(:each) do
    @toppred_file = Tfiles + '/toppred.small.out'
    @peps =  (0..7).to_a.map {|n| v = SpecID::GenericPep.new; v.aaseq = n.to_s ; v }
    # certain:      3        0       0       0       2       3       2       1
    references = %w(YAL002W  YAL001C YAL003W YAL004W YAL007C YAL008W YAL009W YAL010C NOTEXISTING1 NOTEXISTING2)
    # index:        0        1       2       3       4       5       6       7
    @prots = references.map do |ref|
      v = SpecID::GenericProt.new
      v.reference = ref
      v
    end

    # TM (? = both)
    # @prots[8] doesn't have a key in the guy (nil)
    # SHOULD NOT change the results
    @peps[0].prots = [@prots[0], @prots[5], @prots[8]]   # y
    @peps[1].prots = [@prots[1], @prots[5], @prots[8]]   # ?
    @peps[2].prots = [@prots[3], @prots[4], @prots[8]]   # ?
    @peps[3].prots = [@prots[2], @prots[8]]             # n
    @peps[4].prots = [@prots[5], @prots[8]]             # y
    @peps[5].prots = [@prots[4], @prots[8]]             # y
    @peps[6].prots = [@prots[8]]            # nil pep
    @peps[7].prots = [@prots[8], @prots[9]] # nil pep

    @validator = klass.new(@toppred_file)
    @validator.false_to_total_ratio = 1.0
  end

  it_should_behave_like 'a validator'

  it 'gives correct precision with false ratio (across all option combinations)' do
    answ = [[2,4], [0,6], [0,6], [-2,8]].map {|v| calc_precision(*v) }
    [true, false].each do |correct_wins|
      [true, false].each do |soluble_fraction|
        val = klass.new(@toppred_file, :min_num_tms => 3, :soluble_fraction => soluble_fraction, :correct_wins => correct_wins)
        val.false_to_total_ratio = 0.5
        val.pephit_precision(@peps).should == answ.shift
        #p val.pephit_precision(@peps)
      end
    end
  end
  
  it 'calculates a correct false to total ratio' do
    val = klass.new(@toppred_file)
    fasta_obj = FastaHelper::FastaObj
    sequest_params_obj = Sequest::Params.new(Tfiles + '/bioworks32.params')
    sequest_params_obj.opts['first_database_name'] = 'not_real'
    val.set_false_to_total_ratio( Digestor.digest(fasta_obj, sequest_params_obj) )
    ratio = val.false_to_total_ratio
    num_tps_soluble_peps = 777
    num_fps_insoluble_peps = 741
    expected_ratio = num_tps_soluble_peps.to_f / (num_tps_soluble_peps + num_fps_insoluble_peps)
    ratio.should == expected_ratio
  end

  it 'can grant transmem status to proteins for speed' do
    val = klass.new(@toppred_file)
    fasta_obj = FastaHelper::FastaObj
    sequest_params_obj = Sequest::Params.new(Tfiles + '/bioworks32.params')
    hash = val.create_transmem_status_hash( Digestor.digest(fasta_obj.prots, sequest_params_obj))
    fasta_obj.prots.each do |prot|
      hash.key?(prot).should be_true
    end
    frozen = [true, true, false, true, false, false, true, false, true, false, true, true, true]
    fasta_obj.prots.map {|prot| hash[prot] }.should == frozen
  end

  def calc_precision(norm, trans)
    prec = norm.to_f / (norm + trans)
  end

  it 'can calculate precision incrementally' do
    val = klass.new(@toppred_file, :min_num_tms => 2, :false_to_total_ratio => 1.0)
    # usually we'd update the false_to_total_ratio, but not bothering for test
    # here we HAVE to set the status hash before hand... (we could redo this
    # section)
    val.transmem_status_hash = val.create_transmem_status_hash(@peps)

    # manually done:
    precisions = [0.0, 1.0/2, 2.0/3, 3.0/4, 3.0/5, 3.0/6, 3.0/6, 3.0/6]

    #frozen:
    calc_bkgs = [1.0, 0.5, 0.333333333333333, 0.25, 0.4, 0.5, 0.5, 0.5]
    #frozen:
    false_to_total_ratios = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

    @peps.zip(precisions, calc_bkgs, false_to_total_ratios) do |pep, exp_prec, calc_bkg, false_to_total_ratio|
      val.increment_pephits_precision(pep).should == exp_prec
      val.calculated_background.should be_close(calc_bkg, 0.00000000000001)
      val.false_to_total_ratio.should == false_to_total_ratio
    end
  end

  it 'creates correct reference hash' do
    val = klass.new(@toppred_file, :min_num_tms => 3, :soluble_fraction => true, :correct_wins => true)
    val.transmem_by_ti_key.should == {"YAL001C"=>false, "YAL011W"=>false, "YAL009W"=>false, "YAL010C"=>false, "YAL008W"=>true, "YAL007C"=>false, "YAL004W"=>false, "YAL005C"=>false, "YAL003W"=>false, "YAL002W"=>true, "YAL013W"=>false, "YAL014C"=>false, "YAL012W"=>false}
  end


end


#################################################
# REFERENCE for small mock set:
#################################################
    #    for mintm >= 3 (T = TP, F = FP, sf = soluble_fraction)
    #        sf=false sf=true
    #    TM  cw fw    cw fw
    # 0  y   T  T     F  F
    # 1  ?   T  F     T  F
    # 2  n   F  F     T  T
    # 3  n   F  F     T  T
    # 4  y   T  T     F  F
    # 5  n   F  F     T  T
    #
    # [tps, fps]
    # cw=true(  sf=true [4,2],  sf=false [3,3] )
    # cw=false( sf=true [3,3],  sf=false [2,4] )
   
    #    for mintm >= 2 (T = TP, F = FP, sf = soluble_fraction)
    #        sf=false sf=true
    #    TM  cw fw    cw fw
    # 0  y   T  T     F  F
    # 1  ?   T  F     T  F
    # 2  ?   T  F     T  F
    # 3  n   F  F     T  T
    # 4  y   T  T     F  F
    # 5  y   T  T     F  F
    #
    # [tps, fps]
    # cw=true(  sf=true [3,3],  sf=false [5,1] )
    # cw=false( sf=true [1,5],  sf=false [3,3] )
    #
    # sf=true(  cw=true [3,3],  cw=false[1,5] )
    # sf=false( cw=true [5,1],  cw=false[3,3] )

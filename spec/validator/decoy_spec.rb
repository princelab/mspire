
require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require File.expand_path( File.dirname(__FILE__) + '/../validator_helper' )

require 'validator/decoy'
require 'spec_id'

klass = Validator::Decoy

describe klass, 'reporting precision on peptides from cat prots' do

  before(:each) do
    peps =  (0..5).to_a.map {|n| v = SpecID::GenericPep.new; v.aaseq = n.to_s ; v }
    prots = %w(gi|1245235|ProteinX gi|987654|ProteinY gi|1111111|ProteinZ FALSE_someOthergi FALSE_AnotherGi FALSE_YetAnotherReference).map do |ref|
      v = SpecID::GenericProt.new
      v.reference = ref
      v
    end
    peps[0].prots = [prots[0], prots[5]]  # TP (only in tp wins)
    peps[1].prots = [prots[1], prots[2]]  # TP always
    peps[2].prots = [prots[3], prots[4]]  # FP 
    peps[3].prots = [prots[2]]            # TP
    peps[4].prots = [prots[5]]            # FP
    peps[5].prots = [prots[4]]            # FP
    @peps = peps
    @validator = klass.new(:constraint => /FAKE/)
  end

  it_should_behave_like 'a validator'

  it 'gives correct precision (across all option combinations)' do 
    answ_arr = [
      [[@peps[0], @peps[1], @peps[3]], [@peps[2], @peps[4], @peps[5]]],
      [[@peps[1], @peps[3]], [@peps[0], @peps[2], @peps[4], @peps[5]]],
      [[@peps[0], @peps[1], @peps[3]], [@peps[2], @peps[4], @peps[5]]],
      [[@peps[1], @peps[3]], [@peps[0], @peps[2], @peps[4], @peps[5]]]
    ]
    protein_matches = [/^FALSE_/, /^FALSE_/, 'Protein', 'Protein']

    [true, false].each do |incorrect_on_match|
      [true, false].each do |correct_wins|
        val = klass.new(:constraint => protein_matches.shift, :decoy_on_match => incorrect_on_match, :correct_wins => correct_wins)
        answ = val.pephit_precision(@peps)
        exp = ValidatorHelper::Decoy.precision_from_partition_array(answ_arr.shift)
        answ.should == exp
      end
    end
  end

end


require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require File.expand_path(File.dirname(__FILE__) + '/../validator_helper')

require 'validator/true_pos'
require 'fasta'
require 'spec_id'

klass = Validator::TruePos
describe klass, 'reporting precision on peptides' do

  before(:each) do
    @myfasta_string =<<END
>gi|1245235|ProteinX
ABCDEFGHIJKLMNOP
>gi|987654|ProteinY
AAAAAABBBBBBBBBBBB
>gi|1111111|ProteinZ
FFFFFFFFFGGGGGGZZZZ
END

    @peps =  (0..5).to_a.map {|n| v = SpecID::GenericPep.new; v.aaseq = n.to_s ; v }
    prots = %w(gi|1245235|ProteinX gi|987654|ProteinY gi|1111111|ProteinZ someOthergi AnotherGi YetAnotherReference).map do |ref|
      v = SpecID::GenericProt.new
      v.reference = ref
      v
    end
    @peps[0].prots = [prots[0], prots[5]]  # TP (only in tp wins)
    @peps[1].prots = [prots[1], prots[2]]  # TP always
    @peps[2].prots = [prots[3], prots[4]]  # FP 
    @peps[3].prots = [prots[2]]            # TP
    @peps[4].prots = [prots[5]]            # FP
    @peps[5].prots = [prots[4]]            # FP
    @myfasta_obj = Fasta.new.load(StringIO.new(@myfasta_string))

    @validator = klass.new(@myfasta_obj)
  end

  it_should_behave_like 'a validator'

  it 'gives correct precision (across all options)' do
    answ_ar = [
      [[@peps[0], @peps[1], @peps[3]], [@peps[2], @peps[4], @peps[5]]],
      [[@peps[1], @peps[3]], [@peps[0], @peps[2], @peps[4], @peps[5]]]
    ]

    [true, false].each do |correct_wins|
      val = klass.new(@myfasta_obj, correct_wins)
      answ = val.pephit_precision(@peps)
      exp = ValidatorHelper.precision_from_partition_array(answ_ar.shift)
      answ.should == exp
    end

  end

end




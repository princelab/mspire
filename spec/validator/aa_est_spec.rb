require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require File.expand_path( File.dirname(__FILE__) + '/../validator_helper' )


require 'validator/aa_est'
require 'spec_id'
require 'spec_id/digestor'

klass = Validator::AAEst

describe klass, "using frequency estimates" do
  before(:each) do
    @small_fasta = Tfiles + '/small.fasta'
    @sequest_params = Tfiles + '/bioworks32.params'
    #         C/D      C/D    J     (7)
    @seqs = %w(ABCDEFGC CCDCCC JJJJJ XYZ WXXXYZ TXXXXXYZ ZZXIIPTYZ ZZXTYZZ ZZZZ YYYYYTL)
    @peps =  @seqs.map {|n| v = SpecID::GenericPep.new; v.aaseq = n ; v }
    val = klass.new('C')
    val.frequency = 0.11
    @validator = val
  end
  #C: 0.0157714433456144
  #D: 0.0526145691939758

  it_should_behave_like 'a validator'

  it 'calculates false_to_total_ratio correctly' do
    obj = klass.new('C', :frequency => 0.0157714433456144)
    obj.set_false_to_total_ratio(@peps)
    exp = 0.949318337979434 / @seqs.size
    obj.false_to_total_ratio.should be_close(exp, 0.0001)  # freeze for consistency
  end

  it 'calculates fttr each time fresh' do
    myar = @peps.map
    obj = klass.new('C', :frequency => 0.0157714433456144)
    obj.pephit_precision(myar)
    fttr1 = obj.false_to_total_ratio
    obj.pephit_precision(myar)
    fttr2 = obj.false_to_total_ratio
    fttr1.should == fttr2
    myar.pop
    obj.pephit_precision(myar)
    fttr3 = obj.false_to_total_ratio
    fttr3.should_not == fttr1
  end

  it 'gives consistent precision of peptides given fastafile and aa (even negative)' do
    aa = 'C'
    val = klass.new(aa).set_frequency(Fasta.new(@small_fasta).prots)
    # I checked this answer out by hand and it is correct
    val.pephit_precision(@peps).should be_close(-1.10677, 0.001)
  end

  it 'gives same precision done at once or incrementally' do
    obj = klass.new('C', :frequency => 0.0157714433456144)

    all_at_once = obj.pephit_precision(@peps)

    precisions = @peps.map do |pep|
      obj.increment_pephits_precision(pep)
    end
    precisions.last.should == all_at_once
  end
end


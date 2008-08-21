require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require File.expand_path( File.dirname(__FILE__) + '/../validator_helper' )


require 'validator/aa'
require 'spec_id'
require 'spec_id/digestor'

klass = Validator::AA

class MyAA < Validator::AA ; def initialize ; end ; end

describe klass, "using digestion data" do

  before(:each) do
    @small_fasta = Tfiles + '/small.fasta'
    @sequest_params = Tfiles + '/bioworks32.params'
    #         C/D      C/D    J     (7)
    @seqs = %w(ABCDEFGC CCDCCC JJJJJ XYZ WXXXYZ TXXXXXYZ ZZXIIPTYZ ZZXTYZZ ZZZZ YYYYYTL)
    @peps =  @seqs.map {|n| v = SpecID::GenericPep.new; v.aaseq = n ; v }

    val = klass.new('C')
    val.false_to_total_ratio = 0.22  # arbitrary
    @validator = val
  end

  it_should_behave_like 'a validator'

  it 'gives correct false to total ratio' do
    aa = 'C'
    val = klass.new(aa)
    peptides = Digestor.digest( Fasta.new(@small_fasta), Sequest::Params.new(@sequest_params))
    val.set_false_to_total_ratio( peptides )
    # frozen (but I checked the peptides by hand to make sure they were
    # correct)
    val.false_to_total_ratio.should be_close(0.177629264861062, 0.0000000000001)
  end
end



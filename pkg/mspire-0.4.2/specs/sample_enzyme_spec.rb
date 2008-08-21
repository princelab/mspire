
require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )
require 'sample_enzyme'
require 'set'

describe SampleEnzyme, "digesting sequences" do
  it 'can digest with no missed cleavages' do
    st = "CRGATKKTAGRPMEK"
    SampleEnzyme.tryptic(st).should == %w(CR GATK K TAGRPMEK)
    st = "CATRP"
    SampleEnzyme.tryptic(st).should == %w(CATRP)
    st = "RCATRP"
    SampleEnzyme.tryptic(st).should == %w(R CATRP)
    st = ""
    SampleEnzyme.tryptic(st).should == []
    st = "R"
    SampleEnzyme.tryptic(st).should == %w(R)
  end

  it 'can digest with missed cleavages' do
    st = "CRGATKKTAGRPMEKLLLERTKY"
    zero = %w(CR GATK K TAGRPMEK LLLER TK Y)
    SampleEnzyme.tryptic(st,0).to_set.should == zero.to_set
    one = %w(CRGATK GATKK KTAGRPMEK TAGRPMEKLLLER LLLERTK TKY)
    SampleEnzyme.tryptic(st,1).to_set.should == (zero+one).to_set
    two = %w(CRGATKK GATKKTAGRPMEK KTAGRPMEKLLLER TAGRPMEKLLLERTK LLLERTKY)
    all = zero + one + two
    SampleEnzyme.tryptic(st,2).to_set.should == all.to_set
  end

  it 'contains duplicates IF there are duplicate tryptic sequences' do
    st = "AAAAKCCCCKDDDDKCCCCK"
    peps = SampleEnzyme.new('trypsin').digest(st, 2)
    peps.select {|aaseq| aaseq == 'CCCCK'}.size.should == 2
  end
  
end

describe SampleEnzyme, 'making enzyme calculations on sequences and aaseqs' do

  before(:each) do
    @full_KRP = SampleEnzyme.new do |se|
      se.name = 'trypsin'
      se.cut = 'KR'
      se.no_cut = 'P'
      se.sense = 'C'
    end
    @just_KR = SampleEnzyme.new do |se|
      se.name = 'trypsin'
      se.cut = 'KR'
      se.no_cut = ''
      se.sense = 'C'
    end
  end

  it 'calculates the number of tolerant termini' do
    exp = [{
      # full KR/P
      'K.EPTIDR.E' => 2,
      'K.PEPTIDR.E' => 1,
      'F.EEPTIDR.E' => 1,
      'F.PEPTIDW.R' => 0,
    },
    {
      # just KR
      'K.EPTIDR.E' => 2,
      'K.PEPTIDR.E' => 2,
      'F.EEPTIDR.E' => 1,
      'F.PEPTIDW.R' => 0,
    }
    ]
    scall = Sequest::PepXML::SearchHit
    sample_enzyme_ar = [@full_KRP, @just_KR]
    sample_enzyme_ar.zip(exp) do |sample_enzyme,hash|
      hash.each do |seq, val|
        sample_enzyme.num_tol_term(seq).should == val
      end
    end
  end

  it 'calculates number of missed cleavages' do
    exp = [{
    "EPTIDR" => 0,
    "PEPTIDR" => 0,
    "EEPTIDR" => 0,
    "PEPTIDW" => 0,
    "PERPTIDW" => 0,
    "PEPKPTIDW" => 0,
    "PEPKTIDW" => 1,
    "RTTIDR" => 1,
    "RTTIKK" => 2,
    "PKEPRTIDW" => 2,
    "PKEPRTIDKP" => 2,
    "PKEPRAALKPEERPTIDKW" => 3,
    },
    {
    "EPTIDR" => 0,
    "PEPTIDR" => 0,
    "EEPTIDR" => 0,
    "PEPTIDW" => 0,
    "PERPTIDW" => 1,
    "PEPKPTIDW" => 1,
    "PEPKTIDW" => 1,
    "RTTIDR" => 1,
    "RTTIKK" => 2,
    "PKEPRTIDW" => 2,
    "PKEPRTIDKP" => 3,
    "PKEPRAALKPEERPTIDKW" => 5,
    }
    ]

    sample_enzyme_ar = [@full_KRP, @just_KR]
    sample_enzyme_ar.zip(exp) do |sample_enzyme, hash|
      hash.each do |aaseq, val|
        #first, middle, last = SpecID::Pep.split_sequence(seq)
        # note that we are only using the middle section!
        sample_enzyme.num_missed_cleavages(aaseq).should == val
      end
    end
  end

end





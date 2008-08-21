require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require 'spec_id/aa_freqs'



describe SpecID::AAFreqs, "given a small fasta file" do
  before(:all) do
    @sf = Tfiles + "/small.fasta"
    @fobj = Fasta.new(@sf)
    @obj = SpecID::AAFreqs.new(@fobj)
  end

  it 'calculates AA freqs properly' do
    expect = {:I=>0.0628918621937819, :S=>0.0539719475147049, :D=>0.0526145691939758, :Z=>0.0, :L=>0.102772929998061, :T=>0.0491888048607071, :E=>0.0609527503070261, :O=>0.0, :C=>0.0157714433456144, :K=>0.0471850559110594, :U=>0.0, :Q=>0.0382651412319824, :W=>0.0137030573330748, :A=>0.101997285243359, :M=>0.0294745006786892, :J=>0.0, :G=>0.0811195139292871, :Y=>0.0254670027793937, :X=>0.0, :F=>0.0418201796910348, :R=>0.0546829552065154, :V=>0.0702604873634542, :H=>0.0213302307543145, :B=>0.0, :N=>0.03471010277293, :P=>0.0418201796910348}
    aaf =  @obj.aafreqs
    expect.each do |k,v|
      #aaf.key?(k).should be_true
      aaf.should have_key(k)
      aaf[k].should be_close(v, 0.00000001)
    end
    sum = 0.0
    aaf.values.each do |v|
      sum += v
    end
    sum.should be_close(1.0, 0.0000000000001)
  end

  it 'gets actual and expected nums for at least 1 amino acid' do
    peptide_aaseqs = @fobj.prots.map do |prot|
      prot.aaseq[0..12]
    end
    peptide_aaseqs.size.should == 50
    (ac,ex) = @obj.actual_and_expected_number(peptide_aaseqs, :C, 1)
    ac.should == 9
    ex.should be_close(9.33530631238985, 0.0000000001)
  end
end

describe SpecID::AAFreqs, "with class methods" do
  it 'creates a probability of length lookup table' do
    expecting = [0.0, 0.01, 0.0199, 0.029701, 0.0394039900000001]
    SpecID::AAFreqs.probability_of_length_table(0.01, 4).zip(expecting) do |answ, exp|
      answ.should be_close(exp, 0.0000000001)
    end
    expecting = [0.0, 0.2, 0.36, 0.488, 0.5904]
    SpecID::AAFreqs.probability_of_length_table(0.2, 4).zip(expecting) do |answ, exp|
      answ.should be_close(exp, 0.0000000001)
    end
  end
end



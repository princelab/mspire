


require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )

require 'validator/prot_from_pep'

klass = Validator::ProtFromPep

describe klass, "on fake, simple prots and peps" do
  before(:each) do
    # create some proteins and peptides linked up
    prots = ('a'..'g').to_a.inject( { } ) do |hash,let|
      prot = OpenStruct.new
      prot.peps = []
      hash[let.to_sym] = prot
      hash
    end
    # prots: a.peps = 0,1,4
    #        b.peps = 1
    #        c.peps = 2
    #        d.peps = 2,5,6
    #        e.peps = 2
    #        f.peps = 3,4
    #        g.peps = 3,4,8,9,10

    #        0    1         2            3        4          5     6     7   
    peps = [[:a], [:a,:b], [:c,:d,:e], [:f,:g], [:a,:f,:g], [:c], [:c], [:d], 
      # 8    9     10
      [:g], [:g], [:g]].map do |belongs_to|
      pep = OpenStruct.new 
      pep.prots = belongs_to.map {|v| prots[v].peps << pep ; prots[v]}
      pep
    end
    @peps = peps
    @prots = prots

    @normal_frozen = [[0.971428571428572, 0.0586273344048647], [0.95, 0.0838775640874857], [0.907142857142857, 0.116103957269609], [0.878571428571428, 0.133328857783819], [0.814285714285714, 0.147299354691691], [0.735714285714286, 0.186982368192933], [0.65, 0.18812775328873], [0.535714285714286, 0.206630166671598], [0.414285714285714, 0.178909454503803], [0.228571428571429, 0.117254668809732]]
    @worstcase_frozen = [0.857142857142857, 0.714285714285714, 0.571428571428571, 0.571428571428571, 0.428571428571429, 0.285714285714286, 0.285714285714286, 0.142857142857143, 0.142857142857143, 0.142857142857143]
  end

  it 'calculates normal precision edge cases' do
    val = klass.new
    all_wrong = @peps.size
    val.normal_prothit_precision( @peps, all_wrong, :num_its => 10 ).should == [0.0,0.0]
    val.normal_prothit_precision( @peps, all_wrong, :num_its => 1).should == 0.0

    val.normal_prothit_precision( @peps, all_wrong+10, :num_its => 10).should == [0.0,0.0]
    val.normal_prothit_precision( @peps, all_wrong+10, :num_its => 1).should == 0.0

    all_right = 0
    val.normal_prothit_precision( @peps, all_right, :num_its => 10).should == [1.0,0.0]
    val.normal_prothit_precision( @peps, all_right, :num_its => 1).should == 1.0
  end

  it 'calculates normal precision that behaves properly' do
    val = klass.new
    prev_mean = 1.0
    (1...(@peps.size)).to_a.zip( @normal_frozen ) do |num_false, expected|
      (mean, stdev) = val.normal_prothit_precision( @peps, num_false, :num_its => 20)
      (mean < prev_mean).should be_true
      (stdev < 0.4 and stdev > 0.0001).should be_true
      mean.should be_close(expected[0], 0.000000001)
      stdev.should be_close(expected[1], 0.000000001)
      val.normal_prothit_precision( @peps, num_false, :num_its => 1).should be_close(mean, 0.25)
    end
  end

  it 'calculates worstcase edge cases' do
    val = klass.new
    all_wrong = @peps.size
    val.worstcase_prothit_precision( @peps, all_wrong, :num_its => 10 ).should == 0.0
    val.worstcase_prothit_precision( @peps, all_wrong, :num_its => 1).should == 0.0

    val.worstcase_prothit_precision( @peps, all_wrong+10, :num_its => 10).should == 0.0
    val.worstcase_prothit_precision( @peps, all_wrong+10, :num_its => 1).should == 0.0

    all_right = 0
    val.worstcase_prothit_precision( @peps, all_right, :num_its => 10).should == 1.0
    val.worstcase_prothit_precision( @peps, all_right, :num_its => 1).should == 1.0
  end

  it 'calculates worstcase precision that behaves properly' do

    val = klass.new
    prev_worst = 1.0
    worsts = []
    (1...(@peps.size)).to_a.zip( @worstcase_frozen ) do |num_false, expected|
      worst = val.worstcase_prothit_precision( @peps, num_false, :num_its => 20)
      (worst <= prev_worst).should be_true
      worst.should be_close(expected, 0.0000000001)
    end

  end

  it 'calculates prothit precision (worstcase + normal)' do
    val = klass.new
    (1...(@peps.size)).to_a.zip( @normal_frozen, @worstcase_frozen ) do |num_false, normal_expected, worstcase_expected|
      (worst, norm_mean, norm_stdev) = val.prothit_precision( @peps, num_false, :num_its_normal => 20, :num_its_worstcase => 10)
      worst.should be_close(worstcase_expected, 0.0000000001)
      norm_mean.should be_close(normal_expected[0], 0.0000000001)
      norm_stdev.should be_close(normal_expected[1], 0.0000000001)
    end
  end

  it 'gives 1.0 precision for no pephits' do
    val = klass.new
    val.prothit_precision( [], 0).should == [1.0, 1.0, 0.0]
  end

end

describe klass, "calculating worstcase prothit precision by numbers" do
  it "calculates precision correctly in easy cases" do
    peps_per_prot = [4,4,3,2,2]
    # no prots completely wrong
    precision = klass.new.worstcase_prothit_precision_by_numbers(peps_per_prot, 1)
    precision.should == 1

    # only one protein partially correct
    precision = klass.new.worstcase_prothit_precision_by_numbers(peps_per_prot, 14)
    precision.should == 0.2
  end

  it 'works correctly on other cases' do
    #      0    1      2      3      4      5      6      7      8     
    expected = [1.0, 5.0/6, 5.0/6, 4.0/6, 4.0/6, 3.0/6, 3.0/6, 3.0/6, 2.0/6, 
    #      9      10     11     12     13     14     15     16     17
           2.0/6, 2.0/6, 2.0/6, 1.0/6, 1.0/6, 1.0/6, 1.0/6, 1.0/6, 0.0]
    num_peps_per_prot = [5,4,3,2,2,1].sort_by { rand }
    total_peps = num_peps_per_prot.inject(0) {|memo,obj| obj + memo }
    val = klass.new
    (0..total_peps).to_a.zip(expected) do |num_wrong, exp|
      val.worstcase_prothit_precision_by_numbers(num_peps_per_prot, num_wrong).should == exp
    end
  end


end



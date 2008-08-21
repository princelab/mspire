require File.expand_path( File.dirname(__FILE__) + '/../../spec_helper' )

require 'spec_id/proph/prot_summary'

describe Proph::ProtSummary, "reading a -prot.xml file" do
  before(:each) do
    file = Tfiles + '/opd1/000_020_3prots-prot.xml'
    @obj = Proph::ProtSummary.new(file)
  end

  it 'extracts protein groups with probabilities' do
    @obj.prot_groups.size.should == 3
    @obj.prot_groups.first.probability.should == 1.0
    @obj.prot_groups[2].probability == 0.98
  end

  it 'extracts protein hit attributes' do
    prot = @obj.prot_groups[1].prots.first
    %w(protein_name n_indistinguishable_proteins probability percent_coverage unique_stripped_peptides group_sibling_id total_number_peptides pct_spectrum_ids).zip(["gi|16132019|ref|NP_418618.1|", 1, 1.0, 13.0, "FRDGLK+AIQFAQDVGIRVIQLAGYDVYYQEANNETRR".split('+'), "a", 2, 0.41]) do |name, val|
      prot.send(name).should == val
    end
  end

  it 'can detect -prot.xml version' do
    answer = ['1.9', '4']
    files = ['/yeast_gly_small-prot.xml', '/interact-opd1_mods_small-prot.xml'].map {|v| Tfiles + v}
    files.zip(answer) do |file,answ|
      Proph::ProtSummary.new.get_version(file).should == answ 
    end
  end

  it 'has prots, peps, and prot_groups ' do
    @obj.peps.should_not be_nil
    @obj.prots.should_not be_nil
    @obj.prot_groups.should_not be_nil
  end

end

####################################################
# OTHER TESTS NOT IMPLEMENTED (do we need these??)
####################################################

=begin

require 'test/unit'
require 'spec_id'
require 'ms/scan'

class ProphTest < Test::Unit::TestCase

  def initialize(arg)
    super(arg)
    @tfiles = File.dirname(__FILE__) + '/tfiles/'
    @pepproph_xml = @tfiles + 'pepproph_small.xml'
  end

  def Xtest_filter_by_min_pep_prob
    obj = Proph::Pep::Parser.new
    new_file = "tfiles/tmp.xml"
    assert_match(/peptideprophet_result probability="0.[0-5]/, IO.read(@pepproph_xml))
    obj.filter_by_min_pep_prob(@pepproph_xml, new_file, 0.50)
    assert_no_match(/peptideprophet_result probability="0.[0-5]/, IO.read(new_file))
    assert_match(/<peptideprophet_result[^>]*probability="0.[6-9][^>]*>/, IO.read(new_file))
    File.unlink new_file
  end

  def Xtest_uniq_by_seqcharge
    cls = Proph::Pep
    p1 = cls.new({ :charge => '2', :sequence => 'PEPTIDE' })
    p2 = cls.new({ :charge => '3', :sequence => 'PEPTIDE' })
    p3 = cls.new({ :charge => '2', :sequence => 'PEPTIDE' })
    p4 = cls.new({ :charge => '2', :sequence => 'APEPTIDE' })
    p5 = cls.new({ :charge => '2', :sequence => 'APEPTIDE' })
    un_peps = cls.uniq_by_seqcharge([p1,p2,p3,p4,p5])
    ## WHY ISn't that working? below!
    ##assert_equal([p1,p2,p4].to_set, un_peps.to_set)
    assert(equal_sets([p1,p2,p4], un_peps))
  end

  def Xequal_sets(arr1, arr2)
    c1 = arr1.dup
    c2 = arr2.dup
    arr1.each do |c|
      arr2.each do |d|
        if c == d
          c1.delete c
          c2.delete d
        end
      end
    end
    if (c1.size == c2.size) && (c1.size == 0)
      true
    else
      false
    end
  end

  def Xtest_arithmetic_avg_scan_by_parent_time
    i1 = 100015.0
    i2 = 30000.0
    i3 = 100.0
    t1 = 0.13
    t2 = 0.23
    t3 = 0.33
    p1 = MS::Scan.new(1,1, t1)
    p2 = MS::Scan.new(2,1, t2)
    p3 = MS::Scan.new(3,1, t3)
    s1 = MS::Scan.new(1,2,0.10, 300.2, i1, p1)
    s2 = MS::Scan.new(2,2,0.20, 301.1, i2, p2)
    s3 = MS::Scan.new(3,2,0.30, 302.0, i3, p3)
    scan = Proph::Pep.new({:scans => [s1,s2,s3]}).arithmetic_avg_scan_by_parent_time
    tot_inten = i1 + i2 + i3
    tm = ( t1 * (i1/tot_inten) + t2 * (i2/tot_inten) + t3 * (i3/tot_inten) )
    {:ms_level => 2, :prec_inten => 130115.0/3, :num => nil, :prec_mz => 301.1.to_f, :time => tm }.each do |k,v|
      if k == :prec_mz  # not sure why this is bugging out, but..
        assert_equal(v.to_s, scan.send(k).to_s)
      else
        assert_equal(v, scan.send(k))
      end
    end

  end


end

=end

require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

require 'align'

describe Align do

  before(:each) do
    @mz1 = Tfiles + '4-03-03_mzXML/000.mzXML.timeIndex'
    @mz2 = Tfiles + '4-03-03_mzXML/020.mzXML.timeIndex'
    @prt = Tfiles + '4-03-03_small-prot.xml'
    @pep = Tfiles + '4-03-03_small.xml'
  end

  it_should 'finds overlapping peptides of same seq+charge' do
    s1 = 'DETTIVEGAGDAEAIQGR'
    c1 = '2'
    s2 = 'TDDVAGDGTTTATVLAQALVR'
    c2 = '2'

    al = Align.new
    pep1 = al.peps_with_scans([@mz1], @prt, @pep, 0.05 ,0.05 ,0.05  )
    pep2 = al.peps_with_scans(@mz2, @prt, @pep,  0.98,0.98,0.98 )
    olap = al.overlapping_peps_by_seqcharge([pep1, pep2])
    olap.each do |peps|
      has_seqcharges = []
      peps.each do |pep|
        if pep.sequence == s1 && pep.charge == c1
          has_seqcharges << true
        elsif pep.sequence == s2 && pep.charge == c2
          has_seqcharges << true
        else
          has_seqcharges << false
        end
      end
      has_seqcharges.each { |c| c.should be_true }
    end
  end

  ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # @TODO: CURRENT WORK!
  it_should 'should find overlapping peptides at a seqcharge with a filter' do
    al = Align.new
    pep1 = al.peps_with_scans([@mz1], @prt, @pep, 0.0 ,0.0 ,0.0  )
    pep2 = al.peps_with_scans(@mz2, @prt, @pep, 0.0, 0.0, 0.0 )
    max_dups = nil
    outlier_cutoff = 0.0
    olap = al.overlapping_peps_by_seqcharge_with_filter([pep1, pep2], max_dups, outlier_cutoff)
    olap.each do |peps|
      p peps
    end
  end

  it_should 'should toss outliers' do

    # Consistency/sanity checks right now (not accuracy)
    x = [-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,10,0 ,1,2,3,4,5,6,7,8,9]
    y = [-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0 ,10,1,2,3,4,5,6,7,8,9]
    expx2 = [-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,1,2,3,4,5,6,7,8,9]
    expy2 = [-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,1,2,3,4,5,6,7,8,9]

    pcls = Proph::Pep
    scls = MS::Scan

    pep_groups = [x,y].collect do |arr|
      arr.collect do |val| 
        pep = pcls.new
        pep.arithmetic_avg_scan_by_parent_time = scls.new(nil,nil,val.to_f)
        pep
      end
    end

    al = Align.new 
    deviations = 3.2
    size_before = pep_groups.first.size
    al.toss_outliers(pep_groups, deviations)
    (size_before - pep_groups.first.size).should == 2
  end

end

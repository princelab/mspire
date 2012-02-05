require 'spec_helper'

require 'ms/spectrum'

describe MS::Spectrum do

  describe 'useful utilities' do
    subject { MS::Spectrum.new [ [10.1, 10.5, 10.7, 11.5], [1, 2, 3, 4] ] }
    it 'finds the nearest m/z or index' do

      queries = {
        10.4 => 1,
        10.5 => 1,
        10.6 => 1,
        10.61 => 2,
        -100.0 => 0,
        200.0 => 3,
      }
      queries.each {|mz, exp_i| subject.find_nearest_index(mz).should == exp_i }

      all = Hash[ queries.map {|k,v| [k,[v]] } ]
      all[10.6] = [1,2]
      all.each {|mz, exp_mz| subject.find_all_nearest_index(mz).should == exp_mz }

      queries = { 
        10.4 => 10.5,
        10.5 => 10.5,
        10.6 => 10.5,
        10.61 => 10.7,
        -100.0 => 10.1,
        200.0 => 11.5,
      }
      queries.each {|mz, exp_mz| subject.find_nearest(mz).should == exp_mz }

      all = Hash[ queries.map {|k,v| [k,[v]] } ]
      all[10.6] = [10.5, 10.7]
      all.each {|mz, exp_mz| subject.find_all_nearest(mz).should == exp_mz }
    end

    it 'can sort itself by m/z' do
      spec = MS::Spectrum.new [[10.5, 10.1, 11.5, 10.7], [2, 1, 4, 3]]
      spec.sort!
      spec.mzs.should == subject.mzs
      spec.intensities.should == subject.intensities
    end
  end

  describe 'merging spectra' do
    subject do  
      data = [ [10.10, 10.5, 10.7, 11.5], [1, 2, 3, 4] ],
        [ [10.11, 10.49, 10.71, 11.48], [5, 6, 7, 8] ],
        [ [10.09, 10.51, 10.72, 11.51], [9, 10, 11, 12] 
      ]
      data.map {|datum| MS::Spectrum.new( datum ) }
    end
    it 'merges, giving exact weighted average m/z values for each cluster' do
      (spec1, data) = MS::Spectrum.merge(subject, :bin_width => 0.08, :bin_unit => :amu, :return_data => true)
      spec2 = MS::Spectrum.merge(subject, :bin_width => 0.08, :bin_unit => :amu)
      spec1.should == spec2
      spec1.should == MS::Spectrum.new([[10.097333333333331, 10.502222222222223, 10.713809523809525, 11.498333333333333], [5.0, 6.0, 7.0, 8.0]])
      data.should == [[[10.1, 1], [10.11, 5], [10.09, 9]], [[10.5, 2], [10.49, 6], [10.51, 10]], [[10.7, 3], [10.71, 7], [10.72, 11]], [[11.5, 4], [11.48, 8], [11.51, 12]]] 
    end
  end

end

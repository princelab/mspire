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

end

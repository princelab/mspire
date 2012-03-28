require 'spec_helper'

require 'mspire/peak_list'
require 'mspire/peak'

describe Mspire::PeakList do

  describe '#split' do

    before do
      # xs could be m/z values or retention times
      simple = [ 0, 3, 8, 9, 7, 2, 0 ]
      multi_large1 = [ 0, 3, 8, 2, 9, 7, 1, 3, 0 ]
      multi_large2 = [ 0, 10, 8, 2, 9, 7, 1, 3, 0 ]
      doublet = [ 0, 10, 8, 0 ]

      start_mz = 50
      @intensities = simple + multi_large1 + multi_large2 + doublet
      @xs = []
      mz = start_mz
      diff = 0.01
      loop do
        @xs << mz
        break if @xs.size == @intensities.size
        mz += diff
      end
      @xs.map! {|mz| mz.round(2) }
      @peaks = @xs.zip(@intensities).map {|pair| Mspire::Peak.new(pair) }
    end

    it 'splits on zeros by default' do
      peak = Mspire::PeakList.new(@peaks) # <- maybe more like a collection of peaks, but PeakList is flexible
      peaks = peak.split
      peaks.size.should == 4
      peaks.should == [
        [[50.01, 3], [50.02, 8], [50.03, 9], [50.04, 7], [50.05, 2]],
        [[50.08, 3], [50.09, 8], [50.1, 2], [50.11, 9], [50.12, 7], [50.13, 1], [50.14, 3]],
        [[50.17, 10], [50.18, 8], [50.19, 2], [50.2, 9], [50.21, 7], [50.22, 1], [50.23, 3]],
        [[50.26, 10], [50.27, 8]]
      ]
      # returns local minima if asked
      (peaks2, local_minima) = peak.split(false, true)
      peaks2.should == peaks
      local_minima.should == [[], [2, 5], [2, 5], []]
    end

    # which it should since zeros are the ultimate local min!
    it 'always cleans up surrounding zeros and does not split non-multipeaks' do
      peak = Mspire::PeakList.new(@peaks[0,7])  # simple
      [:share, :greedy_y].each do |multipeak_split_method|
        peaks = peak.split(multipeak_split_method)
        peaks.first.should be_an_instance_of(Mspire::PeakList)
        peaks.first.to_a.should == [[50.01, 3], [50.02, 8], [50.03, 9], [50.04, 7], [50.05, 2]]
      end
    end

    it 'does #split(:share) and shares the peak proportional to adjacent peaks' do
      data = [[50.07, 0], [50.08, 3], [50.09, 8], [50.1, 2], [50.11, 9], [50.12, 7], [50.13, 1], [50.14, 3], [50.15, 0]]
      multipeak1 = Mspire::PeakList.new( data )

      answer = [
        [[50.08, 3], [50.09, 8], [50.1, (2*8.0/17)]], 
        [[50.1, 2*9.0/17], [50.11, 9], [50.12, 7], [50.13, 0.7]],
        [[50.13, 0.3], [50.14, 3]]
      ]
      multipeak1.split(:share).should == answer

      answer = [
        [[50.08, 3], [50.09, 8]], 
        [[50.1, 2], [50.11, 9], [50.12, 7], [50.13, 1]], 
        [[50.14, 3]]
      ]
      multipeak1.split(:greedy_y).should == answer

      answer = [
        [[50.08, 3], [50.09, 9], [50.1, 2]], 
        [[50.11, 9], [50.12, 7], [50.13, 1]], 
        [[50.14, 3]]
      ] 

      # test a tie -> goes left!
      peaks = @peaks[7,9]
      peaks[2] = Mspire::Peak.new([peaks[2][0], 9])
      multipeak2 = Mspire::PeakList.new( peaks )
      multipeak2.split(:greedy_y).should == answer

    end
  end

  describe '#merge' do

    subject do  

      list1 = [[10.1, 1], [10.5, 2], [10.7, 3], [11.5, 4]]
      list2 = [[10.11, 5], [10.49, 6], [10.71, 7], [11.48, 8]]
      list3 = [[10.09, 9], [10.51, 10], [10.72, 11], [11.51, 12]]

      [list1, list2, list3].map {|peaks| Mspire::PeakList.new( peaks ) }
    end

    it 'merges, giving exact weighted average m/z values for each cluster' do
      (peaklist1, data) = Mspire::PeakList.merge(subject, :bin_width => 0.08, :bin_unit => :amu, :return_data => true)
      peaklist2 = Mspire::PeakList.merge(subject, :bin_width => 0.08, :bin_unit => :amu)
      peaklist1.should == peaklist2
      peaks = [[10.097333333333331, 10.502222222222223, 10.713809523809525, 11.498333333333333], [5.0, 6.0, 7.0, 8.0]].transpose
      peaklist1.should == Mspire::PeakList.new(peaks)
      data.should == [[[10.1, 1], [10.11, 5], [10.09, 9]], [[10.5, 2], [10.49, 6], [10.51, 10]], [[10.7, 3], [10.71, 7], [10.72, 11]], [[11.5, 4], [11.48, 8], [11.51, 12]]] 
    end
  end

end


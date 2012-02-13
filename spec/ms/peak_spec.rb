require 'spec_helper'

require 'ms/peak'
require 'ms/peak/point'

describe MS::Peak do

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
      @points = @xs.zip(@intensities).map {|pair| MS::Peak::Point.new(pair) }
    end

    it 'splits on zeros by default' do
      peak = MS::Peak.new(@points) # <- maybe more like a collection of peaks, but Peak is flexible
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
      peak = MS::Peak.new(@points[0,7])  # simple
      [:share, :greedy_y].each do |multipeak_split_method|
        peaks = peak.split(multipeak_split_method)
        peaks.first.should be_an_instance_of(MS::Peak)
        peaks.first.to_a.should == [[50.01, 3], [50.02, 8], [50.03, 9], [50.04, 7], [50.05, 2]]
      end
    end

    it 'does #split(:share) and shares the peak proportional to adjacent peaks' do
      data = [[50.07, 0], [50.08, 3], [50.09, 8], [50.1, 2], [50.11, 9], [50.12, 7], [50.13, 1], [50.14, 3], [50.15, 0]]
      multipeak1 = MS::Peak.new( data )

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
      points = @points[7,9]
      points[2] = MS::Peak::Point.new([points[2][0], 9])
      multipeak2 = MS::Peak.new( points )
      multipeak2.split(:greedy_y).should == answer

    end
  end

end

require 'spec_helper'

require 'bin'

describe Bin do

  describe 'putting data into bins' do

    def delete_and_confirm_empty(bins, indices)
      indices.sort.reverse.each {|i| bins.delete_at(i) }
      bins.all? {|bin| bin.data.size == 0 }.should be_true
    end

    it 'works for bins lower and higher' do
      bins = (0..9).map {|i| Bin.new(i.to_f, (i+1).to_f, true) }
      peaks = [3.0, 4.4, 11.0].map {|v| [v, 1] }
      rbins = Bin.bin!(bins, peaks, &:first)
      [[3,0], [4,1]].each {|ri, pi| rbins[ri].data.first.should == peaks[pi] }
      delete_and_confirm_empty(rbins, [3,4])
    end

    it 'works for lower values and higher bins' do
      bins = (3..9).map {|i| Bin.new(i.to_f, (i+1).to_f, true) }
      peaks = [1.0, 2.99, 5.2].map {|v| [v, 1] }
      rbins = Bin.bin!(bins, peaks, &:first)
      rbins[2].data.first.should == peaks.last
      delete_and_confirm_empty(rbins, [2])
    end

    it 'works for higher values and lower bins' do
      bins = (3..9).map {|i| Bin.new(i.to_f, (i+1).to_f, true) }
      peaks = [5.2, 11.0].map {|v| [v, 1] }
      rbins = Bin.bin!(bins, peaks, &:first)
      rbins[2].data.first.should == peaks.first
      delete_and_confirm_empty(rbins, [2])
    end

    it 'works for values lower and higher' do
      bins = (2..9).map {|i| Bin.new(i.to_f, (i+1).to_f, true) }
      peaks = [1.0, 2.99, 5.2, 11.0].map {|v| [v, 1] }
      rbins = Bin.bin!(bins, peaks, &:first)
      [[0,1], [3,2]].each {|ri, pi| rbins[ri].data.first.should == peaks[pi] }
      delete_and_confirm_empty(rbins, [0,3])
    end
  end

end

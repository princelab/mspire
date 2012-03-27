require 'spec_helper'

require 'mspire/bin'

describe Mspire::Bin do

  describe 'putting data into bins' do

    def matching(bins, peaks, bin_to_peak_index_pairs)
      bins_dup = bins.dup
      bin_to_peak_index_pairs.sort_by(&:first).reverse.each do |bin_i, peak_i|
        _bin = bins_dup.delete_at(bin_i)
        data = _bin.respond_to?(:data) ? _bin.data[0] : _bin[0]
        data.should == peaks[peak_i]
      end
      bins_dup.map! {|bin| bin.respond_to?(:data) ? bin.data : bin }
      bins_dup.all? {|bin| bin.size == 0 }.should be_true
    end

    def self.make_ranges(range, use_bin=false)
      klass = use_bin ? Mspire::Bin : Range
      range.map {|i| klass.new(i.to_f, (i+1).to_f, true) }
    end

    def self.make_pairs(x_vals)
      x_vals.each_with_index.map {|v,i| [v, i*100] }
    end

    def ranges_to_bins(ranges)
      ranges.map {|range| Mspire::Bin.new(range.begin, range.end, true) }
    end

    data = {
      lower_and_lower: {
      range: 0..9,
      peaks: [3.0, 4.4, 11.0],
      bin_to_peak_index_pairs: [[3,0], [4,1]]
    },
      higher_and_higher: {
      range: 3..9,
      peaks: [1.0, 2.99, 5.2],
      bin_to_peak_index_pairs: [[2,2]]
    },
      lower_and_higher: {
      range: 3..11,
      peaks: [5.2, 11.0],
      bin_to_peak_index_pairs: [[2,0], [8,1]]
    },
      higher_and_lower: {
      range: 2..9,
      peaks: [1.0, 2.99, 5.2, 11.0],
      bin_to_peak_index_pairs: [[0,1],[3,2]]
    }
    }
    data = data.map do |key, hash|
      [ key, { ranges: make_ranges(hash[:range]),
        peaks: make_pairs(hash[:peaks]),
        bin_to_peak_index_pairs: hash[:bin_to_peak_index_pairs]} ]
    end
    data = Hash[data]
    # not really the subject, but it is the data we care about here...

    data.each do |type, init|
      it "works for bins to data #{type.to_s.gsub('_',' ')}" do
        rbins = Mspire::Bin.bin(ranges_to_bins(init[:ranges]), init[:peaks], &:first)
        matching(rbins, init[:peaks], init[:bin_to_peak_index_pairs])
      end
    end

    data.each do |type, init|
      it "works for ranges to data #{type.to_s.gsub('_',' ')}" do
        custom_data_store = (0...init[:ranges].size).map { [] }
        rbins = Mspire::Bin.bin(init[:ranges], init[:peaks], custom_data_store, &:first)
        matching(rbins, init[:peaks], init[:bin_to_peak_index_pairs])
      end
    end
  end
end

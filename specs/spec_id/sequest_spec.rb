require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require 'spec_id'
require 'spec_id/sequest'
require 'set'

class MockPepHit
  attr_accessor :first_scan, :xcorr, :idd
  def initialize(*args)
    (@first_scan, @xcorr, @idd) = args
  end
end

describe Sequest, ": with small mock set" do
  before(:each) do
    index = 0
    hits = [[0, 5.0, 0], [0, 4.0, 1], [0, 3.0, 2], 
      [1, 5.0, 3], [1, 4.0, 4],
      [2, 5.5, 5], 
      [3, 5.5, 6], [3, 5.5, 7], [3, 4.0, 8], [3, 2.4, 9], [3, 2.4, 10]
    ].map do |hit|
      MockPepHit.new(*hit)
    end
    @peps = hits.sort_by {rand}
  end

  it 'returns "other" hits' do
    included = [2, 8, 9, 10]
    first_index = 2
    last_index = 10
    reply = Sequest.other_hits(@peps, first_index,last_index,:first_scan, [:xcorr, {:down => :xcorr}])
    reply.map {|hit| hit.idd }.to_set.should == included.to_set

    # same, but optimized
    reply = Sequest.other_hits_sorted_by_xcorr(@peps, first_index,last_index,:first_scan)
    reply.map {|hit| hit.idd }.to_set.should == included.to_set
  end

end

require 'spec_helper'

require 'ms/error_rate/qvalue'

Hit = Struct.new(:score, :charge)
HitWeird = Struct.new(:some_obscure_score, :charge)

describe 'calculating q-values' do

  before do
    scores = [14,15,13,12,11]
    qvals_expected = [0.5 ,0.0, 2.0/3.0, 3.0/4, 4.0/5]
    @target_hits = scores.zip(Array.new(scores.size, 2)).map {|pair| Hit.new(*pair) } 
    @decoy_hits = scores.zip(Array.new(scores.size, 2)).map {|pair| Hit.new(pair.first-0.5, pair.last) }
    @target_hits_weird = scores.zip(Array.new(scores.size, 2)).map {|pair| HitWeird.new(*pair) } 
    @decoy_hits_weird = scores.zip(Array.new(scores.size, 2)).map {|pair| HitWeird.new(pair.first-0.5, pair.last) }
    @qval_by_hit = {}
    @target_hits.zip(qvals_expected) {|hit, qval|  @qval_by_hit[hit] = qval }
    @target_hits_weird.zip(qvals_expected) {|hit, qval|  @qval_by_hit[hit] = qval }
  end

  it 'can calculate qvalues on target/decoy sets (:score is default)' do
    pairs = MS::ErrorRate::Qvalue.target_decoy_qvalues(@target_hits, @decoy_hits)
    pairs.each do |hit, qval|
      @qval_by_hit[hit].should be_within(0.00000001).of(qval)
    end
  end

  it 'can calculate qvalues on target/decoy sets with custom sorting' do
    pairs = MS::ErrorRate::Qvalue.target_decoy_qvalues(@target_hits_weird, @decoy_hits_weird) {|hit| hit.some_obscure_score }
    pairs.each do |hit, qval|
      @qval_by_hit[hit].should be_within(0.00000001).of(qval)
    end
  end
end

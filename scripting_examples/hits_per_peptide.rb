#!/usr/bin/ruby -w

require 'hash_by'
require 'vec'
require 'spec_id'

peps_per_scan = SpecID.new( ARGV ).peps.hash_by(:base_name, :first_scan).values
top_hit_per_scan = peps_per_scan.map {|peps| peps.max {|a,b| b.xcorr <=> a.xcorr } }
num_pephits_per_aaseq = top_hit_per_scan.hash_by(:aaseq).values.map {|v| v.size }
(mean, stdev) = VecI.new(num_pephits_per_aaseq).sample_stats
max = num_pephits_per_aaseq.max

%w(mean stdev max).zip([mean, stdev, max]) do |cat, val|
  puts "#{cat}: #{val}"
end

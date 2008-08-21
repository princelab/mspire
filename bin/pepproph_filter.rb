#!/usr/bin/ruby -w

require 'spec_id/proph'

if ARGV.size < 1
  puts "usage: #{File.basename(__FILE__)} <prob_cutoff> <pepproph.xml> ..."
  puts "     For each file outputs 'pepproph_min<prob_cutoff>.xml'"
  puts "     deleting all search_hits with peptides less than prob_cutoff"
end

files = ARGV.to_a
cutoff = files.shift
files.each do |file|
  outfile = file.gsub(/\.xml/, "_min#{cutoff}.xml")
  Proph::Pep::Parser.new.filter_by_min_pep_prob(file, outfile, cutoff.to_f)
end

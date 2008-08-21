#!/usr/bin/ruby -w

require 'fasta'
require 'spec_id/aa_freqs'

if ARGV.size < 1
  puts "usage: #{File.basename(__FILE__)} <file>.fasta ..."
  puts "prints the amino acid frequencies of every amino acid in each fasta file"
  exit
end

ARGV.each do |file|
  obj = SpecID::AAFreqs.new(Fasta.new(file))
  puts file
  obj.aafreqs.sort_by{|v| v.to_s }.each do |k,v|
    puts "#{k}: #{v}"
  end
  puts ""
end





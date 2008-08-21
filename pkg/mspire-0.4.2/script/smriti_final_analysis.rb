#!/usr/bin/ruby -w

require 'spec_id'
require 'fasta'
require 'optparse'

$top = false
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} bioworks.xml <file>.fasta|prefix"
  op.separator "outputs stdout (tab del sorted by probability) probability, file:aaseq:charge T/F"
  op.separator "hashes on file+aaseq+charge"
  op.on("-t", "--top", "only top peptide (by prob) per scan+charge") do
    $top = true
  end
end

opts.parse!

if ARGV.size < 2
  puts opts.to_s  
  exit
end

specid_file = ARGV.shift
file_or_prefix = ARGV.shift

specid = SpecID.new(specid_file)

indicator = 
  if File.exist? file_or_prefix
    Fasta.new.read_file(file_or_prefix)
  else
    file_or_prefix
  end


# returns an array containing the min prob peptides (in case of a tie)
def lowest_peps(ar)
  min_prob = ar.min {|a,b| a.probability.to_f <=> b.probability.to_f }.probability.to_f
  ar.select {|v| v.probability.to_f == min_prob }
end

peps = specid.peps
if $top
  top_by_scan = []
  peps.hash_by(:base_name, :first_scan).each do |k,v|
    low_peps = lowest_peps(v)
    top_by_scan.push( *low_peps )
  end
end

results = top_by_scan.hash_by(:base_name, :aaseq, :charge).map do |k,v|
  low_peps = lowest_peps(v)
  #min_pep = v.min {|a,b| a.probability.to_f <=> b.probability.to_f }
  all_prots = []
  low_peps.each do |pep|
    all_prot_references.push( *(pep.prots.map {|v| v.reference }) )
  end
  all_prot_references.uniq!
  is_true =
    if indicator.is_a? Fasta
      all_prot_references.any? do |ref|
        indicator.included_in_header?(ref)
      end
    else
      !(all_prot_references.all? {|ref| ref.include?( indicator )})
    end
  [min_pep.probability.to_f, k, is_true]
end

results.sort.each do |result|
  report = [result[0], result[1].join(':'), (result[2] ? 'T' : 'F')]
  puts report.join("\t")
end

=begin
# ORIGINAL CODE
peps = specid.peps
if $top
  peps = peps.hash_by(:base_name, :first_scan).map do |k,v|
    v.min {|a,b| a.probability.to_f <=> b.probability.to_f } 
  end
end

results = peps.hash_by(:base_name, :aaseq, :charge).map do |k,v|
  min_pep = v.min {|a,b| a.probability.to_f <=> b.probability.to_f }
  references = min_pep.prots.map {|v| v.reference }.uniq
  is_true =
    if indicator.is_a? Fasta
      references.any? do |ref|
        indicator.included_in_header?(ref)
      end
    else
      !(references.all? {|ref| ref.include?( indicator )})
    end
  [min_pep.probability.to_f, k, is_true]
end

results.sort.each do |result|
  report = [result[0], result[1].join(':'), (result[2] ? 'T' : 'F')]
  puts report.join("\t")
end
=end

#!/usr/bin/ruby -w

# Here is what I plotted: take each id'd pep-prot id'd on the tophit scans -- you will likely have the same pep-prot id'd on multiple scans -- plot the top probability of each such pep-prot.
# There are 43 such id'd peptides for Sashimi, whereas SEQUEST id's about 66. So you'll have 66 (1-p-values) to plot, I had 43. Similarly for OMICS. 

require 'spec_id'
require 'fasta'
require 'optparse'
require 'ostruct'

# returns an accession number if available, or the entire reference (less the
# starting '>'
def get_fasta_accession(fasta_prot)
  head = fasta_prot.header
  if head =~ ACC_REGEX
    $1.dup
  else
    head.sub(/^>/, '').rstrip
  end
end

# returns the accession number from a reference, or the complete reference
def accession_from_ref(pep)
  ref = pep.prot.reference 
  if ref =~ ACC_REGEX
    $1.dup
  else
    ref.rstrip
  end
end

def get_pep_prot_accession(pep)
  acc = pep.prot.accession
  if !acc || acc == '0' || acc == 0
    accession_from_ref(pep)
  else
    acc 
  end
end

#####################################################################
# MAIN
#####################################################################

opt = OpenStruct.new
opt.p = 'prob'
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} bioworks.xml true_hits.fasta" 
  op.separator "     [prints to stdout tab delimited table]"
  op.on('-t', '--ties', 'allow ties on best hit') {|v| opt.t = v }
  op.on('-p', '--param <s>', 'param: (xcorr | prob)') {|v| opt.p = v}
end
opts.parse!

if ARGV.size < 2
  puts opts
  exit
end

case opt.p
when 'prob'
  param = :peptide_probability
  best = :first
when 'xcorr'
  param = :xcorr
  best = :last
else
  abort "incorrect param: #{opt.p}"
end

############################
# GLOBALS
DELIM = "\t"
ACC_REGEX = /\|(.*?)\|/o
############################

bioworks = ARGV[0]
fasta_file = ARGV[1]

fprots = Fasta.new.read_file(fasta_file).prots
gi_nums = fprots.map {|prot| get_fasta_accession(prot) }

peptides = SpecID.new(bioworks).peps


## Get the best peptide(s) per scan
top_peps_per_scan = []

peptides.hash_by(:base_name, :first_scan).each do |bn_scan, pep_array|
  sorted_list = pep_array.sort_by {|pep| pep.send(param).to_f }
  
  top_peps = if best == :first ; [sorted_list.shift] ; else [sorted_list.pop] end
  found_another = false
  sorted_list.each do |pep|
    if pep.send(param).to_f == top_peps.send(best).send(param).to_f
      if opt.t
        top_peps << pep
      else
        found_another = true
      end
    end
  end
  unless found_another
    top_peps_per_scan.push( *top_peps )
  end
end


## Get the best scoring peptide per peptide/prot from list of best
## peptides/scan
top_pep_seq_prots = top_peps_per_scan.hash_by {|pep| [pep.sequence, get_pep_prot_accession(pep)] }.map do |k,pep_array|
  pep_array.sort_by {|pep| pep.send(param).to_f }.send(best)
end

## sort the peptides by best score
sorted_top_pep_seq_prots = top_pep_seq_prots.sort_by {|pep| pep.send(param).to_f }
if best == :last ; sorted_top_pep_seq_prots.reverse! end

## plot the probability vs. the number of tps
puts ['#TPs', param, 'sequence', 'protein accession', 'xcorr'].join(DELIM)
tps = 0
sorted_top_pep_seq_prots.each do |pep|
  if gi_nums.include?( get_pep_prot_accession(pep) )
    tps += 1
    puts [tps.to_s, pep.send(param), pep.sequence, get_pep_prot_accession(pep), pep.xcorr].join(DELIM)
  end
end










#!/usr/bin/ruby -w

require 'prot'
require 'pep'

if ARGV.size < 4
  usage = <<HERE
usage: protxml2prots_peps.rb run-prot.xml prot_prob nsp_pep_prob init_pep_prob
       takes all proteins and peptides passing prob cutoffs and
       outputs 'run-prot.xml.<prot_prob>_<nsp_prob>_<init_prob>.protpep' 
       which is a marshalled array of proteins (containing peptides)
HERE
  puts usage
  exit(1);
end

file = ARGV[0]
outfile = file + '.' + ARGV[1] +'_'+ ARGV[2] +'_'+ ARGV[3] + ".protpep"

proteins = Protein.get_prots_and_peps_fast(*ARGV)
#puts "proteins"
#proteins.each do |pr|
#  puts pr
#  pr.peptides.each do |pep|
#    puts "\n\t" + pep.to_s 
#  end
#end
#proteins = Protein.get_prots_and_peps(*ARGV)
File.open(outfile, "w") do |f|
  Marshal.dump(proteins, f)
end


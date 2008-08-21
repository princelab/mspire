#!/usr/bin/ruby -w

###################################################################
cats = %w(base_name sequence xcorr deltacn first_scan last_scan)
###################################################################

require 'spec_id'
require 'hash_by'

extension_top = '.top_per_scan.txt'
extension_all = '.all_peps_per_scan.txt'

if ARGV.size < 1
  puts "usage: #{File.basename(__FILE__)} <file>.xml"
  puts "output: <file>#{extension}"
  puts ""
  puts "Generates top hit (highest xcorr) per scan."
  exit
end

def print_doc(outfile, headers, table_a_of_a)
  document =  table_a_of_a.map do |line|
    line.join("\t")
  end.join("\n")
  File.open(outfile, 'w') do |out|
    out.print headers.join("\t") + "\n"
    out.print document
  end
end


def pep_array_to_table(peps, send_to)
  arr_of_arr = peps.map do |pep|
    arr = send_to.map {|sym| pep.send(sym) }
    arr.unshift( pep.prot.reference )  # hacked on
  end
end

###############################################
# MAIN:
###############################################

file = ARGV[0]
outfile_top = file.sub(/\.xml$/, extension_top)
outfile_all = file.sub(/\.xml$/, extension_all)

sp = SpecID.new(file)

# The old (incorrect version)
# pep_hash = sp.peps.hash_by(:first_scan, :last_scan)
# The correct version:
pep_hash = sp.peps.hash_by(:base_name, :first_scan, :last_scan)
top_per_scan = pep_hash.map {|k,v| v.sort_by {|ob| ob.xcorr.to_f }.last }
top_per_scan = top_per_scan.sort_by {|pep| pep.first_scan.to_i }

all_peps = sp.peps.sort_by do |pep| [pep.first_scan.to_i, -1.0 * pep.xcorr.to_f] end

cats_sym = cats.map {|v| v.to_sym }

a_of_a_top = pep_array_to_table(top_per_scan, cats_sym)
a_of_a_all = pep_array_to_table(all_peps, cats_sym)

cats.unshift "protein_reference"

print_doc(outfile_top, cats, a_of_a_top)
print_doc(outfile_all, cats, a_of_a_all)


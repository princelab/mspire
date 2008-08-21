#!/usr/bin/ruby -w

require 'fasta'
require 'sample_enzyme'

if ARGV.size < 3
  puts "usage: #{File.basename(__FILE__)} min_peptide_length missed_cleavages <file>.fasta ..."
  puts "       returns <file>.min_pep_length_<#>.missed_cleavages_<#>.degenerate_peptides.csv"
  abort
end



min_peptide_length = ARGV.shift.to_i
missed_cleavages = ARGV.shift.to_i

ARGV.each do |file|
  hash = {}

  if file !~ /\.fasta/
    abort "must be a fasta file with extension fasta"
  end
  new_filename = file.sub(/\.fasta$/, '')
  new_filename << ".min_pep_length_#{min_peptide_length}.missed_cleavages_#{missed_cleavages}.degenerate_peptides.csv"
  peptides = []
  Fasta.new.read_file(file).prots.each do |prot|


    SampleEnzyme.tryptic(prot.aaseq, missed_cleavages).each do |aaseq|
      if aaseq.size >= min_peptide_length
        hash[aaseq] ||= []
        hash[aaseq].push( prot.header.sub(/^>/,'') )
      end
    end
    #fh.puts( prot.header.split(/\s+/).first.sub(/^>/,'') + "\t" + SampleEnzyme.tryptic(prot.aaseq, missed_cleavages).join(" ") )
  end

  File.open(new_filename, "w") do |fh|
    hash.keys.sort_by {|pep| hash[pep].size }.reverse.each do |pep|
      fh.puts( [pep, *(hash[pep])].join("\t") )
    end     
  end
end





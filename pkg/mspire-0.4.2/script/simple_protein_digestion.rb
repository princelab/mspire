#!/usr/bin/ruby -w

require 'fasta'
require 'sample_enzyme'

if ARGV.size < 2
  puts "usage: #{File.basename(__FILE__)} missed_cleavages <file>.fasta ..."
  puts "       returns <file>.missed_cleavages_<missed_cleavages>.peptides"
  abort
end

missed_cleavages = ARGV.shift.to_i

ARGV.each do |file|
  
  if file !~ /\.fasta/
    abort "must be a fasta file with extension fasta"
  end
  new_filename = file.sub(/\.fasta$/, '')
  new_filename << ".missed_cleavages_#{missed_cleavages}.peptides"
  File.open(new_filename, "w") do |fh|
    peptides = []
    Fasta.new.read_file(file).prots.each do |prot|
      fh.puts( prot.header.split(/\s+/).first.sub(/^>/,'') + "\t" + SampleEnzyme.tryptic(prot.aaseq, missed_cleavages).join(" ") )
    end
  end
end

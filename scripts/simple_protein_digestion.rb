#!/usr/bin/ruby -w

require 'rubygems'

def require_it(file, gem)
  begin
    require file
  rescue LoadError
    puts "****************************************************"
    puts "  you need to install the '#{gem}' gem:"
    puts "      sudo gem install #{gem}" 
    puts "****************************************************"
    puts $!
    abort "(exiting)"
  end
end

%w(ms/fasta ms/in_silico/digester).zip(%w(ms-fasta ms-in_silico)).each do |file, gem|
  require_it file, gem
end

if ARGV.size < 2
  puts "usage: #{File.basename(__FILE__)} missed_cleavages <file>.fasta ..."
  puts "       returns <file>.missed_cleavages_<missed_cleavages>.peptides"
  abort
end

missed_cleavages = ARGV.shift.to_i

trypsin = Ms::InSilico::Digester::TRYPSIN

ARGV.each do |file|
  base = file.chomp(File.extname(file))
  new_filename = base + ".missed_cleavages_#{missed_cleavages}.peptides"
  File.open(new_filename, "w") do |fh|
    peptides = []
    Ms::Fasta.open(file) do |fasta|
      fasta.each do |prot|
        fh.puts( prot.header.split(/\s+/).first + "\t" + trypsin.digest(prot.sequence, missed_cleavages).join(" ") )
      end
    end
  end
end

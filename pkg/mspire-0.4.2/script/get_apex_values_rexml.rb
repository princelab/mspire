#!/usr/bin/ruby

require 'rexml/document'

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} <file>-prot.xml ..."
  puts "outputs a .csv file"
  exit
end

class Protein
  attr_accessor :name, :pi, :ni
  def initialize(name, pi, ni)
    @name, @pi, @ni = name, pi, ni
  end
end

class Listener
  attr_accessor :proteins

  def initialize
    @proteins = []
  end

  def tag_start(name, attrs)
    if name == "protein" 
      protein = Protein.new( attrs['protein_name'], attrs['probability'].to_f, attrs['total_number_peptides'].to_i) 
      @proteins.push( protein )
    end
  end

  def method_missing(*args) ; end

end

ARGV.each do |file|
  File.open("output.csv", 'w') do |out|
    listener = Listener.new
    REXML::Document.parse_stream(File.new(file), listener)
    listener.proteins.sort_by {|prot| [prot.pi, prot.ni, prot.name] }.reverse.each do |protein|
      out.puts [protein.name, protein.pi, protein.ni].join("\t")
    end
  end
end

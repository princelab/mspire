#!/usr/bin/ruby -w

require 'spec/mzxml/parser'
require 'spec/msrun'
require 'rexml/document'
include REXML

if ARGV.size < 1
  puts "usage: #{File.basename(__FILE__)} file.mzXML ..."
  puts "  outputs 'file.mzXML.timeIndex'"
  puts "  which contains rows of:"
  puts "  level scan_num time (if !msLevel1:) prec_mz prec_intensity"
end

# outputs rows of:
# level scan_num time [precursor_mz precursor_intensity(if !msLevel1)]

ARGV.each do |file|
  puts "READING: " + file
  outfile = file + '.timeIndex'
  obj = MS::MSRunIndex.new(file)
  puts "WRITING: " + outfile
  obj.to_index_file(outfile)
end

